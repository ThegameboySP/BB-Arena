local ReplicatedStorage = game:GetService("ReplicatedStorage")

local General = require(ReplicatedStorage.Common.Utils.General)

local function makeForcefield()
	local part = Instance.new("Part")
	part.Material = Enum.Material.ForceField
	part.Size = Vector3.one * 7.5
	part.Color = Color3.fromRGB(0, 16, 176)
	part.Shape = Enum.PartType.Ball
	part.CastShadow = false

	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.Massless = true

	return part
end

local function simpleForcefields()
	return {
		add = function(data)
			local rootPart = data.character:FindFirstChild("HumanoidRootPart")
			if rootPart == nil then
				return false
			end

			local forcefield = makeForcefield()
			forcefield.Parent = data.character
			data.visual = forcefield

			forcefield.CFrame = rootPart.CFrame
			General.weld(forcefield, rootPart)

			return function(transparency)
				forcefield.Transparency = transparency
			end
		end,
		remove = function(data)
			data.visual.Parent = nil
		end,
	}
end

return simpleForcefields
