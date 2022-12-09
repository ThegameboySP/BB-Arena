local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

return function(_, duration)
	ReplicatedStorage:SetAttribute("TimerTimestamp", Workspace:GetServerTimeNow() + duration)
end
