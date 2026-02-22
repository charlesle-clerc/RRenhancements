local function set_lap(s1, s2, s3)
	local tt = s1 + s2 + s3
	local event = game:GetService("ReplicatedStorage").Events.Timer
	event:FireServer(1, s1)
	event:FireServer(2, s2)
	event:FireServer(3, s3)
	event:FireServer(4, tt)
end

local function convert_t(val)
	local min, sec = string.match(val, "(%d+):(%d+)")
	min = tonumber(min) or 0
	sec = tonumber(sec) or 0
	return (min * 60) + sec
end

local avg_s1, avg_s2, avg_s3 = 27, 33, 23
local current_time = game:GetService("ReplicatedStorage").Values.TimerInfo.Value

while task.wait(0.5) do
	if getgenv().stop_autofarm == true then
		break
	end
	if convert_t(current_time.Value) < 780 - (avg_s1 + avg_s2 + avg_s3) then
		local s1 = avg_s1 + (math.random(1, 1000) / 1000)
		local s2 = avg_s2 + (math.random(1, 1000) / 1000)
		local s3 = avg_s3 + (math.random(1, 1000) / 1000)
		print("set laptime: " .. s1 + s2 + s3)
		set_lap(s1, s2, s3)
	end
end
