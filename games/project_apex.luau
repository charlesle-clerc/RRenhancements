local create = loadstring(
	game:HttpGet(
		"https://raw.githubusercontent.com/charlesle-clerc/RRenhancements/refs/heads/main/utilities/library.luau"
	)
)()

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
local og_grav = math.floor(workspace.Gravity * 10) / 10
local grav_boxes = {
	main = grav:AddLeftGroupbox("Main"),
}
local grav_toggle = grav_boxes.main:AddToggle("gravity_main_enabled", {
	Text = "Enable",
	Default = false,
})

local grav_slider = grav_boxes.main:AddSlider("gravity_main_gravity", {
	Text = "Gravity",
	Default = og_grav,
	Min = math.max(og_grav - 1000, 1),
	Max = math.min(og_grav + 1000, 2000),
	Rounding = 1,
})

local grav_slider_v = og_grav
grav_slider.OnChanged(function(v)
	grav_slider_y = v
end)

grav_toggle:OnChanged(function(s)
	if not s then
		workspace.Gravity = og_grav
	elseif s then
		workspace.Gravity = grav_slider_v or og_grav
	end
end)
