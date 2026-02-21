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
		{ id = "ui_settings", name = "UI & Info" },
	},
})

local grav = app.tabs.grav
local players = game:GetService("Players")
local run_service = game:GetService("RunService")
local local_player = players.LocalPlayer

local og_grav = math.floor(workspace.Gravity * 10) / 10
local og_grav_real = workspace.Gravity

--// UI layout
local box = {
	main = grav:AddLeftGroupbox("Main"),
	conds = grav:AddLeftGroupbox("Conditions"),
	hook = grav:AddRightGroupbox("Hook"),
	status = grav:AddRightGroupbox("Status"),
}

--// Runtime state
local state = {
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

local cond = {
	accel = "Accelerating",
	brake = "Braking",
	over = "Speed Above Cutoff",
	under = "Speed Below Cutoff",
}

local cond_values = { cond.accel, cond.brake, cond.over, cond.under }
local up_modes = {}
local down_modes = {}

--// Small helpers
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

--// Main controls
local main_enabled = box.main:AddToggle("grav_main_enabled", {
	Text = "Enabled",
	Default = false,
})

local main_gravity = box.main:AddSlider("grav_main_base", {
	Text = "Base Gravity",
	Default = state.base_grav,
	Min = 1,
	Max = 1000,
	Rounding = 1,
})

bind_changed(main_gravity, function(v)
	state.base_grav = v
end)

bind_changed(main_enabled, function(v)
	if not v then
		workspace.Gravity = og_grav
		state.smooth_grav = og_grav
		state.mode = "Off"
		return
	end

	state.smooth_grav = workspace.Gravity
end)

--// Condition controls
local cond_up = box.conds:AddDropdown("grav_cond_up", {
	Text = "Higher Gravity",
	Values = cond_values,
	Multi = true,
	Default = {},
})

local cond_down = box.conds:AddDropdown("grav_cond_down", {
	Text = "Lower Gravity",
	Values = cond_values,
	Multi = true,
	Default = {},
})

local cond_cutoff = box.conds:AddSlider("grav_cond_cutoff", {
	Text = "Cutoff Speed (studs/s)",
	Default = state.cutoff_speed,
	Min = 50,
	Max = 400,
	Rounding = 1,
})

local cond_up_mult = box.conds:AddSlider("grav_cond_up_mult", {
	Text = "Higher Multiplier",
	Default = state.up_mult,
	Min = 1,
	Max = 3,
	Rounding = 2,
})

local cond_down_mult = box.conds:AddSlider("grav_cond_down_mult", {
	Text = "Lower Multiplier",
	Default = state.down_mult,
	Min = 0.1,
	Max = 1,
	Rounding = 2,
})

local cond_up_on = box.conds:AddToggle("grav_cond_up_on", {
	Text = "Higher Enabled",
	Default = true,
})

local cond_down_on = box.conds:AddToggle("grav_cond_down_on", {
	Text = "Lower Enabled",
	Default = true,
})

local cond_setters = {
	{
		ctrl = cond_up,
		set = function(v)
			up_modes = v
		end,
	},
	{
		ctrl = cond_down,
		set = function(v)
			down_modes = v
		end,
	},
	{
		ctrl = cond_cutoff,
		set = function(v)
			state.cutoff_speed = v
		end,
	},
	{
		ctrl = cond_up_mult,
		set = function(v)
			state.up_mult = v
		end,
	},
	{
		ctrl = cond_down_mult,
		set = function(v)
			state.down_mult = v
		end,
	},
	{
		ctrl = cond_up_on,
		set = function(v)
			state.up_enabled = v
		end,
	},
	{
		ctrl = cond_down_on,
		set = function(v)
			state.down_enabled = v
		end,
	},
}

bind_many(cond_setters)

--// Hook controls
local hook_targets = {
	"Actual Original",
	"Rounded Original",
	"Base Gravity",
	"Target Gravity",
	"Applied Gravity",
	"Custom",
}

local hook_short = {
	["Actual Original"] = "Actual",
	["Rounded Original"] = "Rounded",
	["Base Gravity"] = "Base",
	["Target Gravity"] = "Target",
	["Applied Gravity"] = "Applied",
	["Custom"] = "Custom",
}

local hook_enabled = box.hook:AddToggle("grav_hook_enabled", {
	Text = "Enabled",
	Default = false,
})

local hook_target = box.hook:AddDropdown("grav_hook_target", {
	Text = "Target",
	Values = hook_targets,
	Default = state.hook_target,
})

local hook_custom = box.hook:AddSlider("grav_hook_custom", {
	Text = "Custom Gravity",
	Default = state.hook_custom,
	Min = 1,
	Max = 1000,
	Rounding = 1,
})

local hook_setters = {
	{
		ctrl = hook_enabled,
		set = function(v)
			state.hook_enabled = v
		end,
	},
	{
		ctrl = hook_target,
		set = function(v)
			state.hook_target = v
		end,
	},
	{
		ctrl = hook_custom,
		set = function(v)
			state.hook_custom = v
		end,
	},
}

bind_many(hook_setters)

--// Status labels
local status_rows = {
	mode = box.status:AddLabel("Mode: Off"),
	speed = box.status:AddLabel("Speed: 0.0"),
	delta = box.status:AddLabel("Speed Delta: 0.000"),
	target = box.status:AddLabel("Target Gravity: 0.00"),
	applied = box.status:AddLabel("Applied Gravity: 0.00"),
	hook = box.status:AddLabel("Hook: Off (Actual Original)"),
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

local cond_checks = {
	[cond.accel] = function()
		return state.speed_delta > 0.05
	end,
	[cond.brake] = function()
		return state.speed_delta < -0.05
	end,
	[cond.over] = function()
		return state.speed >= state.cutoff_speed
	end,
	[cond.under] = function()
		return state.speed < state.cutoff_speed
	end,
}

local function condition_hit(mode_key)
	local fn = cond_checks[mode_key]
	return fn and fn() or false
end

local function eval_set(mode_set)
	local has_drive = has_mode(mode_set, cond.accel) or has_mode(mode_set, cond.brake)
	local has_speed = has_mode(mode_set, cond.over) or has_mode(mode_set, cond.under)

	if has_drive then
		return (has_mode(mode_set, cond.accel) and condition_hit(cond.accel))
			or (has_mode(mode_set, cond.brake) and condition_hit(cond.brake))
	end
	if has_speed then
		return (has_mode(mode_set, cond.over) and condition_hit(cond.over))
			or (has_mode(mode_set, cond.under) and condition_hit(cond.under))
	end

	return false
end

local hook_getters = {
	["Actual Original"] = function()
		return og_grav_real
	end,
	["Rounded Original"] = function()
		return og_grav
	end,
	["Base Gravity"] = function()
		return state.base_grav
	end,
	["Target Gravity"] = function()
		return state.target_grav
	end,
	["Applied Gravity"] = function()
		return state.applied_grav
	end,
	["Custom"] = function()
		return state.hook_custom
	end,
}

local function hook_value()
	local fn = hook_getters[state.hook_target]
	return fn and fn() or og_grav_real
end

--// Gravity hook
local mt = getrawmetatable(game)
local old_index = mt.__index

setreadonly(mt, false)
mt.__index = newcclosure(function(self, key)
	if self == workspace and key == "Gravity" and state.hook_enabled then
		return hook_value()
	end

	if type(old_index) == "function" then
		return old_index(self, key)
	end

	return old_index[key]
end)
setreadonly(mt, true)

--// Main update loop
run_service.Heartbeat:Connect(function(dt)
	local speed = read_speed()
	state.speed_delta = speed - state.speed
	state.speed = speed

	if main_enabled.Value then
		local up_hit = state.up_enabled and eval_set(up_modes)
		local down_hit = state.down_enabled and eval_set(down_modes)
		local target = state.base_grav

		if up_hit and not down_hit then
			target = math.clamp(state.base_grav * state.up_mult, 1, 1000)
			state.mode = "Higher"
		elseif down_hit and not up_hit then
			target = math.clamp(state.base_grav * state.down_mult, 1, 1000)
			state.mode = "Lower"
		else
			state.mode = "Base"
		end

		state.target_grav = target
		local alpha = 1 - math.exp(-10 * dt)
		state.smooth_grav = state.smooth_grav + (target - state.smooth_grav) * alpha

		if math.abs(workspace.Gravity - state.smooth_grav) > 0.01 then
			workspace.Gravity = state.smooth_grav
		end
	else
		state.mode = "Off"
		state.target_grav = og_grav
		state.smooth_grav = og_grav
	end

	state.applied_grav = workspace.Gravity
	state.status_dt += dt
	if state.status_dt < 0.1 then
		return
	end

	state.status_dt = 0
	local lines = {
		mode = "Mode: " .. state.mode,
		speed = string.format("Speed: %.1f", state.speed),
		delta = string.format("Speed Delta: %.3f", state.speed_delta),
		target = string.format("Target Gravity: %.2f", state.target_grav),
		applied = string.format("Applied Gravity: %.2f", state.applied_grav),
		hook = string.format(
			"Hook: %s (%s)",
			state.hook_enabled and "On" or "Off",
			hook_short[state.hook_target] or state.hook_target
		),
	}

	for key, text in pairs(lines) do
		set_label(status_rows[key], text)
	end
end)
