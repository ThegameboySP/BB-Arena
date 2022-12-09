local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local t = require(ReplicatedStorage.Packages.t)
local General = require(ReplicatedStorage.Common.Utils.General)
local Component = require(ReplicatedStorage.Common.Component).Component

local function calculatePercent(baseTime, length)
	return (baseTime / length) % 1
end

local Spinning = Component:extend("Spinning", {
	realm = "client",
	checkConfig = t.interface({
		FullSpinSeconds = t.number,
		Direction = t.Vector3,
		Reversed = t.optional(t.boolean),
	}),
})

function Spinning:OnDestroy()
	self.connection:Disconnect()
end

function Spinning:OnInit()
	local instance = self.Instance
	instance.Anchored = true

	for _, descendant in self.Instance:GetDescendants() do
		if descendant:IsA("BasePart") then
			General.weld(self.Instance, descendant)
			descendant.Anchored = false
		end
	end
end

function Spinning:OnStart()
	local config = self.Config
	local pivot = self.Instance.CFrame
	local instance = self.Instance

	local mult = config.Reversed and -1 or 1
	local timestamp = os.clock()

	self.connection = RunService.Heartbeat:Connect(function()
		local normalizedTime = calculatePercent(os.clock() - timestamp, config.FullSpinSeconds)
		local rotation = normalizedTime * math.pi * 2 * mult
		instance.CFrame = pivot * CFrame.fromAxisAngle(config.Direction, rotation)
	end)
end

return Spinning
