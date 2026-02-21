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
			print("[RRe] failed on load: " .. e)
		end
	end
end
