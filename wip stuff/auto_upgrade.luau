local aero = {
	"Body Strakes",
	"Mirrors",
	"Floor",
	"Front Wing",
	"Rear Wing",
}
local chassis = {
	"Weight reduction",
	"Weight reduction2",
	"Thin nose",
	"Packaging",
}
local engine = {
	"Fuel",
	"ICE",
	"MGU-K",
	"Weight",
	"Turbo",
}

local event = game:GetService("ReplicatedStorage").Events.UpgradeCar
local function upgrade(era, type, manufacturer, part)
	event:InvokeServer(era, type, manufacturer, part)
end

local cars = {
	["2025"] = {
		"BmRacing",
		"Karl-Ringer",
		"Werner",
		"DMB",
		"Bison GP",
		"Ferrucha",
		"Ascolt",
		"Hans",
		"Evans Racing",
		"Pelissier",
		"Montane",
		"Bolting Bisons",
		"Theron Doorn",
		"Schmutzig",
		"EX",
		"Santen",
		"Alten",
		"Saetta GP",
		"Mercury",
	},
}

for n, v in pairs(cars) do
	for n2, v2 in pairs(v) do
		for n3, v3 in pairs(aero) do
			upgrade(n, "Aero", v2, v3)
		end
		for n3, v3 in pairs(chassis) do
			upgrade(n, "Chassis", v2, v3)
		end
		for n3, v3 in pairs(engine) do
			upgrade(n, "Engine", v2, v3)
		end
	end
end
