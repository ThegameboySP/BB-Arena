local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Sounds = ReplicatedStorage.Assets.Sounds

local Component = require(ReplicatedStorage.Common.Component).Component

local C_Medkit = Component:extend("Medkit", {
    realm = "client";
})

local function playSoundAt(sound, pos)
	local part = Instance.new("Part")
	part.CFrame = CFrame.new(pos)
	part.Transparency = 1
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.Name = "SoundHolder"
	part.Size = Vector3.zero
	
	local clone = sound:Clone()
	clone.Parent = part
	clone.Ended:Connect(function()
		part.Parent = nil
	end)
	clone:Play()

	part.Parent = workspace
end

local SPIN_SPEED = math.pi * 2 * (1/4)

function C_Medkit:OnDestroy()
    self._connection:Disconnect()
end

function C_Medkit:OnStart()
    self.Changed:Connect(function(new, old)
        if new.Used == old.Used then
            return
        end

		for _, descendant in self.Instance:GetDescendants() do
            if descendant:IsA("BasePart") then
                descendant.Transparency = if new.Used then 1 else 0
            end
        end
    end)

    self._connection = RunService.Heartbeat:Connect(function(dt)
        self.Instance:PivotTo(self.Instance:GetPivot() * CFrame.Angles(0, SPIN_SPEED * dt, 0))
    end)

	self:RemoteEvent("PickedUp").OnClientEvent:Connect(function()
		playSoundAt(Sounds.Copy, self.Instance.PrimaryPart.Position)
	end)
end

return C_Medkit