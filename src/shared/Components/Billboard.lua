local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Component = require(ReplicatedStorage.Common.Component).Component
local t = require(ReplicatedStorage.Packages.t)

local Billboard = Component:extend("Billboard", {
	realm = "client",

	checkConfig = t.interface({
		LockY = t.optional(t.boolean),
	}),
})

function Billboard:OnDestroy()
	self._connection:Disconnect()
end

function Billboard:OnStart()
	local parts = {}
	local descendants = self.Instance:GetDescendants()
	table.insert(descendants, self.Instance)

	for _, descendant in descendants do
		if descendant:IsA("BasePart") then
			table.insert(parts, descendant)
		end
	end

	self._connection = RunService.Heartbeat:Connect(function()
		local camPos = Workspace.CurrentCamera.CFrame.Position

		for _, part in parts do
			local CF = part.CFrame

			if self.Config.LockY then
				local lockedPos = Vector3.new(camPos.X, CF.p.Y, camPos.Z)
				self.Instance.CFrame = CFrame.lookAt(CF.p, lockedPos)
			else
				self.Instance.CFrame = CFrame.lookAt(CF.p, camPos)
			end
		end
	end)
end

return Billboard
