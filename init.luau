local games = {
	project_apex = {
		id = 2153167977,
		name = "Formula Apex",
		places = {},
	},
}

local id = game.GameId

for n, v in pairs(games) do
	if id == v.id then
		local link = "https://raw.githubusercontent.com/charlesle-clerc/RRenhancements/refs/heads/main/games/"
			.. n
			.. ".luau"
		loadstring(game:HttpGet(link))()
	end
end
