local base = "https://raw.githubusercontent.com/charlesle-clerc/RRenhancements/refs/heads/main/utilities/"

local function loadutil(name)
	local url = base .. name .. ".luau"
	local okHttp, sourceOrErr = pcall(function()
		return game:HttpGet(url)
	end)
	if not okHttp then
		error(string.format("[RRe] %s HttpGet failed: %s", name, tostring(sourceOrErr)))
	end

	local chunk, loadErr = loadstring(sourceOrErr)
	if not chunk then
		error(string.format("[RRe] %s loadstring failed: %s", name, tostring(loadErr)))
	end

	local okRun, resultOrErr = pcall(chunk)
	if not okRun then
		error(string.format("[RRe] %s runtime failed: %s", name, tostring(resultOrErr)))
	end

	return resultOrErr
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
