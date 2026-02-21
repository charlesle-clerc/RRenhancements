local create = loadstring(
	game:HttpGet(
		"https://raw.githubusercontent.com/charlesle-clerc/RRenhancements/refs/heads/main/utilities/library.luau"
	)
)()

--// App bootstrap
local app = create({
	game_key = "project_apex",
	game_file = "games/project_apex.luau",
	version = "v1",
	tabs = {
		{ id = "grav", name = "Gravity" },
		{ id = "a_chassis", name = "A-Chassis" },
		{ id = "ui_settings", name = "UI & Info" },
	},
})

local grav = app.tabs.grav
local a_tab = app.tabs.a_chassis

local players = game:GetService("Players")
local run_service = game:GetService("RunService")
local local_player = players.LocalPlayer

--// Shared helpers
local function bind_changed(ctrl, setter)
	ctrl:OnChanged(function(v)
		setter(v)
	end)
end

local function bind_many(defs)
	for _, item in ipairs(defs) do
		bind_changed(item.ctrl, item.set)
	end
end

local function clone_value(v)
	if type(v) == "table" then
		return table.clone(v)
	end
	return v
end

--// =========================
--// A-Chassis
--// =========================
local a_box = {
	main = a_tab:AddLeftGroupbox("Tune"),
}

local a_state = {
	enabled = true,
}

local a_tune = {
	FCamber = -2.5,
	RCamber = -1.5,
	FToe = 0.1,
	RToe = 0.1,
	Weight = 2080,
	WeightDist = 55,
	CGHeight = 0.45,
	FWheelDensity = 0.25,
	RWheelDensity = 0.4,
	FSusStiffness = 35000,
	FSusDamping = 1100,
	FPreCompress = 0.35,
	FGyroDampening = 130,
	RSusStiffness = 35000,
	RSusDamping = 1150,
	RPreCompress = 0.35,
	RGyroDampening = 130,
	FSusAngle = 75,
	RSusAngle = 75,
	FGyroDamp = 120,
	RGyroDamp = 120,
	SteerRatio = 13,
	Ackerman = 0.9,
	SteerInner = 34,
	SteerOuter = 32,
	SteerSpeed = 0.13,
	ReturnSpeed = 0.15,
	SteerDecay = 500,
	ThrotAccel = 0.06,
	ThrotDecel = 0.7,
	RDiffSlipThres = 65,
	RDiffLockThres = 35,
	RDiffPower = 90,
	RDiffCoast = 45,
	RDiffPreload = 25,
	TCSEnabled = true,
	TCSThreshold = 18,
	TCSGradient = 18,
	BrakeForce = 13500,
	BrakeBias = 0.7,
	Ratios = { 20, 0, 14.077, 9.45, 8.82, 7.29, 6.21, 5.31, 4.68, 4.14 },
	Horsepower = 570,
	E_Torque = 343,
	T_Boost = 16.8,
}

local function apply_tune(car)
	if not a_state.enabled then
		return
	end
	if not car then
		return
	end

	local tune_mod = car:FindFirstChild("A-Chassis Tune") or car:WaitForChild("A-Chassis Tune", 5)
	if not tune_mod then
		return
	end

	local ok, tune = pcall(require, tune_mod)
	if not ok or type(tune) ~= "table" then
		return
	end

	for key, value in pairs(a_tune) do
		tune[key] = clone_value(value)
	end
end

local a_enabled = a_box.main:AddToggle("ach_enabled", {
	Text = "Enabled",
	Default = true,
})

a_box.main:AddLabel("Applies on spawn")

local a_slider_defs = {
	{ name = "Horsepower", key = "Horsepower", min = 300, max = 900, round = 0 },
	{ name = "E-Torque", key = "E_Torque", min = 100, max = 700, round = 0 },
	{ name = "Turbo Boost", key = "T_Boost", min = 0, max = 30, round = 1 },
	{ name = "Weight", key = "Weight", min = 1800, max = 2600, round = 0 },
	{ name = "Weight Dist", key = "WeightDist", min = 40, max = 65, round = 0 },
	{ name = "Brake Force", key = "BrakeForce", min = 6000, max = 20000, round = 0 },
	{ name = "Brake Bias", key = "BrakeBias", min = 0.4, max = 0.9, round = 2 },
	{ name = "Throttle Accel", key = "ThrotAccel", min = 0.01, max = 0.2, round = 2 },
	{ name = "Throttle Decel", key = "ThrotDecel", min = 0.1, max = 1.2, round = 2 },
	{ name = "R Diff Power", key = "RDiffPower", min = 0, max = 100, round = 0 },
	{ name = "R Diff Coast", key = "RDiffCoast", min = 0, max = 100, round = 0 },
}

local a_pick_values = {}
local a_def_by_name = {}
for _, def in ipairs(a_slider_defs) do
	table.insert(a_pick_values, def.name)
	a_def_by_name[def.name] = def
end

local function call_ctrl(ctrl, name, ...)
	local fn = ctrl and ctrl[name]
	if type(fn) == "function" then
		pcall(fn, ctrl, ...)
	end
end

local function clamp_def(def, value)
	return math.clamp(value, def.min, def.max)
end

local a_pick_name = a_pick_values[1]
local a_pick_def = a_def_by_name[a_pick_name]
local a_pick = a_box.main:AddDropdown("ach_pick", {
	Text = "Tune",
	Values = a_pick_values,
	Default = a_pick_name,
})

local a_value = a_box.main:AddSlider("ach_value", {
	Text = "Value",
	Default = a_tune[a_pick_def.key],
	Min = a_pick_def.min,
	Max = a_pick_def.max,
	Rounding = a_pick_def.round,
})

local a_info = a_box.main:AddLabel("")
local function sync_a_slider()
	local def = a_def_by_name[a_pick_name]
	if not def then
		return
	end

	local current = clamp_def(def, a_tune[def.key] or def.min)
	a_tune[def.key] = current

	call_ctrl(a_value, "SetMin", def.min)
	call_ctrl(a_value, "SetMax", def.max)
	call_ctrl(a_value, "SetRounding", def.round)
	call_ctrl(a_value, "SetValue", current)
	call_ctrl(a_value, "SetText", "Value")

	if a_info and a_info.SetText then
		pcall(a_info.SetText, a_info, string.format("%s (%s - %s)", def.name, tostring(def.min), tostring(def.max)))
	end
end

bind_changed(a_pick, function(v)
	a_pick_name = v
	sync_a_slider()
end)

bind_changed(a_value, function(v)
	local def = a_def_by_name[a_pick_name]
	if not def then
		return
	end

	local next_v = clamp_def(def, v)
	a_tune[def.key] = next_v
	if next_v ~= v then
		call_ctrl(a_value, "SetValue", next_v)
	end
end)

local a_tcs = a_box.main:AddToggle("ach_tcs_enabled", {
	Text = "TCS Enabled",
	Default = a_tune.TCSEnabled,
})

bind_changed(a_tcs, function(v)
	a_tune.TCSEnabled = v
end)

bind_changed(a_enabled, function(v)
	a_state.enabled = v
end)

sync_a_slider()

task.spawn(function()
	while task.wait(0.1) do
		if not a_state.enabled then
			continue
		end

		for _, x in ipairs(game.Players.LocalPlayer:GetChildren()) do
			if x.Name == "ACTune" then
				x:Destroy()
			end
		end

		local events = game.ReplicatedStorage:FindFirstChild("Events")
		if events then
			for _, x in ipairs(events:GetChildren()) do
				if x.Name == "ACTune" then
					x:Destroy()
				end
			end
		end
	end
end)

task.spawn(function()
	local vehicles = game.Workspace:WaitForChild("Vehicles")
	vehicles.ChildAdded:Connect(function(x)
		apply_tune(x)
	end)

	for _, car in ipairs(vehicles:GetChildren()) do
		apply_tune(car)
	end
end)

--// =========================
--// Gravity
--// =========================
local og_grav = math.floor(workspace.Gravity * 10) / 10
local og_grav_real = workspace.Gravity

local g_box = {
	main = grav:AddLeftGroupbox("Main"),
	conds = grav:AddLeftGroupbox("Conditions"),
	hook = grav:AddRightGroupbox("Hook"),
	status = grav:AddRightGroupbox("Status"),
}

local g_state = {
	base_grav = og_grav,
	smooth_grav = og_grav,
	target_grav = og_grav,
	applied_grav = workspace.Gravity,

	speed = 0,
	speed_delta = 0,
	cutoff_speed = 200,

	up_mult = 1.25,
	down_mult = 0.75,
	up_enabled = true,
	down_enabled = true,

	mode = "Off",

	hook_enabled = false,
	hook_target = "Actual Original",
	hook_custom = og_grav,

	status_dt = 0,
}

local g_cond = {
	accel = "Accelerating",
	brake = "Braking",
	over = "Speed Above Cutoff",
	under = "Speed Below Cutoff",
}

local g_cond_values = { g_cond.accel, g_cond.brake, g_cond.over, g_cond.under }
local g_up_modes = {}
local g_down_modes = {}

local g_main_enabled = g_box.main:AddToggle("grav_main_enabled", {
	Text = "Enabled",
	Default = false,
})

local g_main_gravity = g_box.main:AddSlider("grav_main_base", {
	Text = "Base Gravity",
	Default = g_state.base_grav,
	Min = 1,
	Max = 1000,
	Rounding = 1,
})

bind_changed(g_main_gravity, function(v)
	g_state.base_grav = v
end)

bind_changed(g_main_enabled, function(v)
	if not v then
		workspace.Gravity = og_grav
		g_state.smooth_grav = og_grav
		g_state.mode = "Off"
		return
	end

	g_state.smooth_grav = workspace.Gravity
end)

local g_cond_up = g_box.conds:AddDropdown("grav_cond_up", {
	Text = "Higher Gravity",
	Values = g_cond_values,
	Multi = true,
	Default = {},
})

local g_cond_down = g_box.conds:AddDropdown("grav_cond_down", {
	Text = "Lower Gravity",
	Values = g_cond_values,
	Multi = true,
	Default = {},
})

local g_cond_cutoff = g_box.conds:AddSlider("grav_cond_cutoff", {
	Text = "Cutoff Speed (studs/s)",
	Default = g_state.cutoff_speed,
	Min = 50,
	Max = 400,
	Rounding = 1,
})

local g_cond_up_mult = g_box.conds:AddSlider("grav_cond_up_mult", {
	Text = "Higher Multiplier",
	Default = g_state.up_mult,
	Min = 1,
	Max = 3,
	Rounding = 2,
})

local g_cond_down_mult = g_box.conds:AddSlider("grav_cond_down_mult", {
	Text = "Lower Multiplier",
	Default = g_state.down_mult,
	Min = 0.1,
	Max = 1,
	Rounding = 2,
})

local g_cond_up_on = g_box.conds:AddToggle("grav_cond_up_on", {
	Text = "Higher Enabled",
	Default = true,
})

local g_cond_down_on = g_box.conds:AddToggle("grav_cond_down_on", {
	Text = "Lower Enabled",
	Default = true,
})

bind_many({
	{
		ctrl = g_cond_up,
		set = function(v)
			g_up_modes = v
		end,
	},
	{
		ctrl = g_cond_down,
		set = function(v)
			g_down_modes = v
		end,
	},
	{
		ctrl = g_cond_cutoff,
		set = function(v)
			g_state.cutoff_speed = v
		end,
	},
	{
		ctrl = g_cond_up_mult,
		set = function(v)
			g_state.up_mult = v
		end,
	},
	{
		ctrl = g_cond_down_mult,
		set = function(v)
			g_state.down_mult = v
		end,
	},
	{
		ctrl = g_cond_up_on,
		set = function(v)
			g_state.up_enabled = v
		end,
	},
	{
		ctrl = g_cond_down_on,
		set = function(v)
			g_state.down_enabled = v
		end,
	},
})

local g_hook_targets = {
	"Actual Original",
	"Rounded Original",
	"Base Gravity",
	"Target Gravity",
	"Applied Gravity",
	"Custom",
}

local g_hook_short = {
	["Actual Original"] = "Actual",
	["Rounded Original"] = "Rounded",
	["Base Gravity"] = "Base",
	["Target Gravity"] = "Target",
	["Applied Gravity"] = "Applied",
	["Custom"] = "Custom",
}

local g_hook_enabled = g_box.hook:AddToggle("grav_hook_enabled", {
	Text = "Enabled",
	Default = false,
})

local g_hook_target = g_box.hook:AddDropdown("grav_hook_target", {
	Text = "Target",
	Values = g_hook_targets,
	Default = g_state.hook_target,
})

local g_hook_custom = g_box.hook:AddSlider("grav_hook_custom", {
	Text = "Custom Gravity",
	Default = g_state.hook_custom,
	Min = 1,
	Max = 1000,
	Rounding = 1,
})

bind_many({
	{
		ctrl = g_hook_enabled,
		set = function(v)
			g_state.hook_enabled = v
		end,
	},
	{
		ctrl = g_hook_target,
		set = function(v)
			g_state.hook_target = v
		end,
	},
	{
		ctrl = g_hook_custom,
		set = function(v)
			g_state.hook_custom = v
		end,
	},
})

local g_status_rows = {
	mode = g_box.status:AddLabel("Mode: Off"),
	speed = g_box.status:AddLabel("Speed: 0.0"),
	delta = g_box.status:AddLabel("Speed Delta: 0.000"),
	target = g_box.status:AddLabel("Target Gravity: 0.00"),
	applied = g_box.status:AddLabel("Applied Gravity: 0.00"),
	hook = g_box.status:AddLabel("Hook: Off (Actual Original)"),
}

local function set_label(label, txt)
	if label and label.SetText then
		pcall(function()
			label:SetText(txt)
		end)
	end
end

local function has_mode(mode_set, mode_key)
	if type(mode_set) ~= "table" then
		return false
	end
	if type(mode_set[mode_key]) == "boolean" then
		return mode_set[mode_key]
	end

	for _, value in pairs(mode_set) do
		if value == mode_key then
			return true
		end
	end

	return false
end

local function read_speed()
	local character = local_player.Character
	if not character then
		return 0
	end

	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then
		return 0
	end

	return root.AssemblyLinearVelocity.Magnitude
end

local g_cond_checks = {
	[g_cond.accel] = function()
		return g_state.speed_delta > 0.05
	end,
	[g_cond.brake] = function()
		return g_state.speed_delta < -0.05
	end,
	[g_cond.over] = function()
		return g_state.speed >= g_state.cutoff_speed
	end,
	[g_cond.under] = function()
		return g_state.speed < g_state.cutoff_speed
	end,
}

local function condition_hit(mode_key)
	local fn = g_cond_checks[mode_key]
	return fn and fn() or false
end

local function eval_set(mode_set)
	local has_drive = has_mode(mode_set, g_cond.accel) or has_mode(mode_set, g_cond.brake)
	local has_speed = has_mode(mode_set, g_cond.over) or has_mode(mode_set, g_cond.under)

	if has_drive then
		return (has_mode(mode_set, g_cond.accel) and condition_hit(g_cond.accel))
			or (has_mode(mode_set, g_cond.brake) and condition_hit(g_cond.brake))
	end
	if has_speed then
		return (has_mode(mode_set, g_cond.over) and condition_hit(g_cond.over))
			or (has_mode(mode_set, g_cond.under) and condition_hit(g_cond.under))
	end

	return false
end

local g_hook_getters = {
	["Actual Original"] = function()
		return og_grav_real
	end,
	["Rounded Original"] = function()
		return og_grav
	end,
	["Base Gravity"] = function()
		return g_state.base_grav
	end,
	["Target Gravity"] = function()
		return g_state.target_grav
	end,
	["Applied Gravity"] = function()
		return g_state.applied_grav
	end,
	["Custom"] = function()
		return g_state.hook_custom
	end,
}

local function hook_value()
	local fn = g_hook_getters[g_state.hook_target]
	return fn and fn() or og_grav_real
end

local mt = getrawmetatable(game)
local old_index = mt.__index

setreadonly(mt, false)
mt.__index = newcclosure(function(self, key)
	if self == workspace and key == "Gravity" and g_state.hook_enabled then
		return hook_value()
	end

	if type(old_index) == "function" then
		return old_index(self, key)
	end

	return old_index[key]
end)
setreadonly(mt, true)

run_service.Heartbeat:Connect(function(dt)
	local speed = read_speed()
	g_state.speed_delta = speed - g_state.speed
	g_state.speed = speed

	if g_main_enabled.Value then
		local up_hit = g_state.up_enabled and eval_set(g_up_modes)
		local down_hit = g_state.down_enabled and eval_set(g_down_modes)
		local target = g_state.base_grav

		if up_hit and not down_hit then
			target = math.clamp(g_state.base_grav * g_state.up_mult, 1, 1000)
			g_state.mode = "Higher"
		elseif down_hit and not up_hit then
			target = math.clamp(g_state.base_grav * g_state.down_mult, 1, 1000)
			g_state.mode = "Lower"
		else
			g_state.mode = "Base"
		end

		g_state.target_grav = target
		local alpha = 1 - math.exp(-10 * dt)
		g_state.smooth_grav = g_state.smooth_grav + (target - g_state.smooth_grav) * alpha

		if math.abs(workspace.Gravity - g_state.smooth_grav) > 0.01 then
			workspace.Gravity = g_state.smooth_grav
		end
	else
		g_state.mode = "Off"
		g_state.target_grav = og_grav
		g_state.smooth_grav = og_grav
	end

	g_state.applied_grav = workspace.Gravity
	g_state.status_dt += dt
	if g_state.status_dt < 0.1 then
		return
	end

	g_state.status_dt = 0
	local lines = {
		mode = "Mode: " .. g_state.mode,
		speed = string.format("Speed: %.1f", g_state.speed),
		delta = string.format("Speed Delta: %.3f", g_state.speed_delta),
		target = string.format("Target Gravity: %.2f", g_state.target_grav),
		applied = string.format("Applied Gravity: %.2f", g_state.applied_grav),
		hook = string.format(
			"Hook: %s (%s)",
			g_state.hook_enabled and "On" or "Off",
			g_hook_short[g_state.hook_target]
		),
	}

	for key, text in pairs(lines) do
		set_label(g_status_rows[key], text)
	end
end)
