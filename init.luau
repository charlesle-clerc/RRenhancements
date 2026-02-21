local genv = (getgenv and getgenv()) or _G
local g = _G
local s = shared

if (genv and genv.rre_executed) or (g and g.rre_executed) or (s and s.rre_executed) then
	warn(
		"rre is already loaded, please rejoin or execute the code below if you know what you're doing\n\n_G.rre_executed = false"
	)
	return
end

if genv then
	genv.rre_executed = true
end
if g then
	g.rre_executed = true
end
if s then
	s.rre_executed = true
end

local games = {
	project_apex = {
		id = 2153167977,
	},
}

local id = game.GameId

for n, v in pairs(games) do
	if id == v.id then
		local link = "https://raw.githubusercontent.com/charlesle-clerc/RRenhancements/refs/heads/main/games/"
			.. n
			.. ".luau"
		local s, e = pcall(function()
			loadstring(game:HttpGet(link))()
		end)
		if not s then
			print("rre: game load failed: " .. tostring(e))
		end
	end
end
