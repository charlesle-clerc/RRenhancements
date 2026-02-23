local http_service = game:GetService("HttpService")
local marketplace_service = game:GetService("MarketplaceService")

local OBSIDIAN_BASE = "https://raw.githubusercontent.com/deividcomsono/Obsidian/refs/heads/main/"
local REPO_BASE = "https://raw.githubusercontent.com/charlesle-clerc/RRenhancements/refs/heads/main/"

local lib = {}

local defaults = {
	title = "RRenhancements",
	version = "v1",
	config_root = "RRenhancements",
	game_key = "default",
	game_file = nil,
	tabs = nil,
	notify_side = "Right",
	logo_name = "rre_white_logo",
	logo_fallback_id = 4155801252,
}

local build_date_cache = {}

local function utc_today()
	return os.date("!%d.%m.%Y")
end

local function http_get(url)
	local ok, body = pcall(game.HttpGet, game, url)
	if not ok then
		error("rre: http request failed: " .. tostring(body))
	end
	return body
end

local function run_remote(url, name)
	local source = http_get(url)
	local chunk, load_err = loadstring(source)
	if not chunk then
		error(string.format("rre: %s loadstring failed: %s", name, tostring(load_err)))
	end

	local ok, out = pcall(chunk)
	if not ok then
		error(string.format("rre: %s runtime failed: %s", name, tostring(out)))
	end

	return out
end

local function get_game_name()
	local ok, info = pcall(marketplace_service.GetProductInfo, marketplace_service, game.PlaceId)
	if ok and type(info) == "table" and type(info.Name) == "string" and info.Name ~= "" then
		return info.Name
	end
	return "Unknown Game"
end

local function get_build_date(game_file)
	if type(game_file) ~= "string" or game_file == "" then
		return utc_today()
	end
	if build_date_cache[game_file] then
		return build_date_cache[game_file]
	end

	local encoded_path = http_service:UrlEncode(game_file)
	local api = string.format(
		"https://api.github.com/repos/charlesle-clerc/RRenhancements/commits?path=%s&per_page=1",
		encoded_path
	)

	local ok_http, json = pcall(game.HttpGet, game, api)
	if not ok_http then
		return utc_today()
	end

	local ok_decode, data = pcall(http_service.JSONDecode, http_service, json)
	if not ok_decode then
		return utc_today()
	end

	local iso = data
		and data[1]
		and data[1].commit
		and data[1].commit.author
		and data[1].commit.author.date

	if type(iso) ~= "string" then
		return utc_today()
	end

	local year, month, day = iso:match("^(%d%d%d%d)%-(%d%d)%-(%d%d)")
	if not (year and month and day) then
		return utc_today()
	end

	local build_date = string.format("%s.%s.%s", day, month, year)
	build_date_cache[game_file] = build_date
	return build_date
end

local function get_logo(ui_lib, opts)
	local ok_add, add_err = pcall(
		ui_lib.ImageManager.AddAsset,
		ui_lib.ImageManager,
		opts.logo_name,
		opts.logo_fallback_id,
		REPO_BASE .. "utilities/assets/white_logo.png"
	)

	if not ok_add and not tostring(add_err):find("already exists", 1, true) then
		warn("rre: logo asset add failed: " .. tostring(add_err))
	end

	local ok_get, icon = pcall(ui_lib.ImageManager.GetAsset, ui_lib.ImageManager, opts.logo_name)
	if ok_get and type(icon) == "string" and icon ~= "" then
		return icon
	end

	return "rbxassetid://" .. tostring(opts.logo_fallback_id)
end

local function to_tab_id(name)
	local id = string.lower(name)
	id = id:gsub("%s+", "_")
	id = id:gsub("[^%w_]", "")
	return id ~= "" and id or "tab"
end

local function get_tab_defs(tab_defs)
	if type(tab_defs) == "table" and #tab_defs > 0 then
		return tab_defs
	end

	return {
		{ id = "main", name = "Main" },
		{ id = "ui_settings", name = "UI Settings" },
	}
end

local function build_tabs(window, tab_defs)
	local tabs = {}
	local tab_list = {}

	for _, raw in ipairs(get_tab_defs(tab_defs)) do
		local tab_name
		local tab_id

		if type(raw) == "string" then
			tab_name = raw
			tab_id = to_tab_id(raw)
		elseif type(raw) == "table" then
			tab_name = raw.name or raw.title or raw.id
			tab_id = raw.id or (type(tab_name) == "string" and to_tab_id(tab_name) or nil)
		end

		if type(tab_name) == "string" and tab_name ~= "" and type(tab_id) == "string" and tab_id ~= "" then
			local tab = window:AddTab(tab_name)
			tabs[tab_id] = tab
			table.insert(tab_list, tab)
		end
	end

	if next(tabs) ~= nil then
		return tabs, tab_list
	end

	local tab = window:AddTab("Main")
	tabs.main = tab
	table.insert(tab_list, tab)
	return tabs, tab_list
end

local function get_ui_tab(window, tabs)
	if tabs.ui_settings then
		return tabs.ui_settings
	end
	if tabs.ui then
		return tabs.ui
	end

	local ui_tab = window:AddTab("UI Settings")
	tabs.ui_settings = ui_tab
	return ui_tab
end

local function merge_options(options)
	local out = table.clone(defaults)
	if type(options) ~= "table" then
		return out
	end

	for key, value in pairs(options) do
		out[key] = value
	end
	return out
end

function lib.create(options)
	local opts = merge_options(options)

	local loaded = {
		ui = run_remote(OBSIDIAN_BASE .. "Library.lua", "library"),
		save = run_remote(OBSIDIAN_BASE .. "addons/SaveManager.lua", "savemanager"),
		theme = run_remote(OBSIDIAN_BASE .. "addons/ThemeManager.lua", "thememanager"),
	}

	local game_name = get_game_name()
	local build_date = get_build_date(opts.game_file)

	local window = loaded.ui:CreateWindow({
		Title = opts.title,
		Footer = string.format("RRe | %s [%s-%s]", game_name, opts.version, build_date),
		NotifySide = opts.notify_side,
		Icon = get_logo(loaded.ui, opts),
		Center = true,
		AutoShow = true,
	})

	local tabs, tab_list = build_tabs(window, opts.tabs)
	local ui_tab = get_ui_tab(window, tabs)

	loaded.theme:SetLibrary(loaded.ui)
	loaded.save:SetLibrary(loaded.ui)
	loaded.theme:SetFolder(opts.config_root)
	loaded.save:SetFolder(string.format("%s/%s", opts.config_root, opts.game_key))
	loaded.save:IgnoreThemeSettings()
	loaded.save:SetIgnoreIndexes({ "MenuKeybind" })
	loaded.theme:ApplyToTab(ui_tab)
	loaded.save:BuildConfigSection(ui_tab)
	loaded.theme:LoadDefault()
	loaded.save:LoadAutoloadConfig()

	return {
		lib = loaded.ui,
		savem = loaded.save,
		themem = loaded.theme,
		window = window,
		tabs = tabs,
		tab_list = tab_list,
		game_name = game_name,
		build_date = build_date,
		version = opts.version,
	}
end

setmetatable(lib, {
	__call = function(_, options)
		return lib.create(options)
	end,
})

return lib
