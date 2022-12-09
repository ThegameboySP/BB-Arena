local CollectionService = game:GetService("CollectionService")

local function defaultForcefields()
	return {
		add = function(data)
			local extraForcefield = Instance.new("ForceField")
			CollectionService:AddTag(extraForcefield, "ForceFieldVisual")
			extraForcefield.Name = "Visual"
			extraForcefield.Parent = data.character
			data.extraForcefield = extraForcefield
		end,
		remove = function(data)
			data.extraForcefield.Parent = nil
		end,
	}
end

return defaultForcefields
