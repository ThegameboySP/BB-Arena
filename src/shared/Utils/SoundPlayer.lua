local Workspace = game:GetService("Workspace")

local SoundPlayer = {}
SoundPlayer.__index = SoundPlayer

function SoundPlayer.new()
	local part = Instance.new("Part")
	part.Name = "SoundRoot"
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.Transparency = 1
	part.CFrame = CFrame.identity
	part.Parent = Workspace

	return setmetatable({
		part = part,
	}, SoundPlayer)
end

function SoundPlayer:Play3DSound(sound, position, soundGroup)
	local attachment = Instance.new("Attachment")
	attachment.Position = position

	local clone = sound:Clone()
	clone.SoundGroup = soundGroup
	clone.Parent = attachment
	attachment.Parent = self.part

	clone.Ended:Once(function()
		attachment.Parent = nil
	end)

	clone:Play()

	return clone
end

return SoundPlayer
