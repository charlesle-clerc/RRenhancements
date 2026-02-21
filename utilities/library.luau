local http_service = game:GetService("HttpService")
local marketplace_service = game:GetService("MarketplaceService")

local OBSIDIAN = "https://raw.githubusercontent.com/deividcomsono/Obsidian/refs/heads/main/"
local REPO = "https://raw.githubusercontent.com/charlesle-clerc/RRenhancements/refs/heads/main/"

local module = {}

local defaults = {
	title = "RRenhancements",
	version = "v1",
	config_root = "RRenhancements",
	game_key = "default",
	game_file = nil,
	notify_side = "Right",
	logo_name = "rre_white_logo",
	logo_fallback_id = 4155801252,
}

local function get(url)
	local ok, data = pcall(game.HttpGet, game, url)
	if not ok then
		error("rre: http request failed: " .. tostring(data))
	end
	return data
end

local function load_remote(url, name)
	local source = get(url)
	local fn, err = loadstring(source)
	if not fn then
		error(string.format("rre: %s loadstring failed: %s", name, tostring(err)))
	end

	local ok, result = pcall(fn)
	if not ok then
		error(string.format("rre: %s runtime failed: %s", name, tostring(result)))
	end

	return result
end

local function get_game_name()
	local ok, info = pcall(marketplace_service.GetProductInfo, marketplace_service, game.PlaceId)
	if ok and type(info) == "table" and type(info.Name) == "string" and info.Name ~= "" then
		return info.Name
	end
	return "Unknown Game"
end

local function get_build_date(build_file)
	if type(build_file) ~= "string" or build_file == "" then
		return os.date("!%d.%m.%Y")
	end

	local api = string.format(
		"https://api.github.com/repos/charlesle-clerc/RRenhancements/commits?path=%s&per_page=1",
		build_file
	)

	local ok_http, json = pcall(game.HttpGet, game, api)
	if not ok_http then
		return os.date("!%d.%m.%Y")
	end

	local ok_decode, data = pcall(http_service.JSONDecode, http_service, json)
	if not ok_decode then
		return os.date("!%d.%m.%Y")
	end

	local iso = data
		and data[1]
		and data[1].commit
		and data[1].commit.author
		and data[1].commit.author.date

	if type(iso) ~= "string" then
		return os.date("!%d.%m.%Y")
	end

	local y, m, d = iso:match("^(%d%d%d%d)%-(%d%d)%-(%d%d)")
	if y and m and d then
		return string.format("%s.%s.%s", d, m, y)
	end

	return os.date("!%d.%m.%Y")
end

local function get_logo(lib, opts)
	local ok_add, add_err = pcall(function()
		lib.ImageManager.AddAsset(opts.logo_name, opts.logo_fallback_id, REPO .. "utilities/assets/white_logo.png")
	end)

	if not ok_add and not tostring(add_err):find("already exists", 1, true) then
		warn("rre: logo asset add failed: " .. tostring(add_err))
	end

	local ok_get, icon = pcall(function()
		return lib.ImageManager.GetAsset(opts.logo_name)
	end)

	if ok_get and type(icon) == "string" and icon ~= "" then
		return icon
	end

	return "rbxassetid://" .. tostring(opts.logo_fallback_id)
end

function module.create(options)
	local opts = table.clone(defaults)
	if type(options) == "table" then
		for key, value in pairs(options) do
			opts[key] = value
		end
	end

	local i = {
		lib = load_remote(OBSIDIAN .. "Library.lua", "library"),
		savem = load_remote(OBSIDIAN .. "addons/SaveManager.lua", "savemanager"),
		themem = load_remote(OBSIDIAN .. "addons/ThemeManager.lua", "thememanager"),
	}

	local game_name = get_game_name()
	local build_date = get_build_date(opts.game_file)

	local window = i.lib:CreateWindow({
		Title = opts.title,
		Footer = string.format("RRe | %s [%s-%s]", game_name, opts.version, build_date),
		NotifySide = opts.notify_side,
		Icon = get_logo(i.lib, opts),
		Center = true,
		AutoShow = true,
	})

	local tabs = {
		main = window:AddTab("Main"),
		ui = window:AddTab("UI Settings"),
	}

	i.themem:SetLibrary(i.lib)
	i.savem:SetLibrary(i.lib)
	i.themem:SetFolder(opts.config_root)
	i.savem:SetFolder(string.format("%s/%s", opts.config_root, opts.game_key))
	i.savem:IgnoreThemeSettings()
	i.savem:SetIgnoreIndexes({ "MenuKeybind" })
	i.themem:ApplyToTab(tabs.ui)
	i.savem:BuildConfigSection(tabs.ui)
	i.themem:LoadDefault()
	i.savem:LoadAutoloadConfig()

	return {
		lib = i.lib,
		savem = i.savem,
		themem = i.themem,
		window = window,
		tabs = tabs,
		game_name = game_name,
		build_date = build_date,
		version = opts.version,
	}
end

setmetatable(module, {
	__call = function(_, options)
		return module.create(options)
	end,
})

return module
