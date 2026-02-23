if _G.rre_executed then
	warn("rre: already executed")
	return
end

local BASE_URL = "https://raw.githubusercontent.com/charlesle-clerc/RRenhancements/refs/heads/main/games/"

local game_files = {
	[2153167977] = "project_apex",
}

local game_file = game_files[game.GameId]
if game_file then
	local url = BASE_URL .. game_file .. ".luau"
	local ok, err = pcall(function()
		local source = game:HttpGet(url)
		local chunk, load_err = loadstring(source)
		if not chunk then
			error("loadstring failed: " .. tostring(load_err))
		end
		chunk()
	end)

	if not ok then
		warn("rre: game load failed: " .. tostring(err))
	end
end

_G.rre_executed = true
