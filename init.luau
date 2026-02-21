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
		print(n)
	end
end
