local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local Component = require(ReplicatedStorage.Common.Component).Component
local General = require(ReplicatedStorage.Common.Utils.General)
local Root = require(ReplicatedStorage.Common.Root)

local S_Medkit = Component:extend("Medkit", {
	realm = "server",
})

function S_Medkit:OnDestroy()
	self._connection:Disconnect()
end

local overlapParams = OverlapParams.new()
function S_Medkit:OnInit()
	local pickedUp = self:RemoteEvent("PickedUp")

	for _, instance in self.Instance:GetDescendants() do
		if instance:IsA("BasePart") then
			instance.CanCollide = false
			instance.CanTouch = false
			instance.CanQuery = false
		end
	end

	local cframe, size = self.Instance:GetBoundingBox()
	local timestamp = 0

	self._connection = RunService.Heartbeat:Connect(function()
		if self.State.Used and (os.clock() - timestamp) < Root.globals.medpacksRespawn:Get() then
			return
		elseif self.State.Used then
			self:SetState({ Used = false })
		end

		overlapParams.FilterDescendantsInstances = { self.Instance }

		local parts = Workspace:GetPartBoundsInBox(cframe, size, overlapParams)
		for _, part in parts do
			local character, humanoid = General.getCharacterFromHitbox(part)
			if character and humanoid.MaxHealth > humanoid.Health and humanoid.Health > 0 then
				humanoid.Health += Root.globals.medpacksHeal:Get()

				pickedUp:FireAllClients(character)

				self:SetState({ Used = true })
				timestamp = os.clock()
			end
		end
	end)
end

return S_Medkit
