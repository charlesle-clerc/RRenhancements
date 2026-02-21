local base = "https://raw.githubusercontent.com/charlesle-clerc/RRenhancements/refs/heads/main/utilities/"

local function loadutil(name)
	return loadstring(game:HttpGet(base .. name .. ".luau"))()
end

local i = {
	lib = loadutil("library"),
	savem = loadutil("savemanager"),
	themem = loadutil("thememanager"),
}

local window = i.lib:CreateWindow({
	Title = "RRenhancements",
	Center = true,
	AutoShow = true,
})
