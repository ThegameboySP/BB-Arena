local CollectionService = game:GetService("CollectionService")

local function hasForcefield(character)
	for _, child in character:GetChildren() do
		if child:IsA("ForceField") and CollectionService:HasTag(child, "CmdrForceField") then
			return true
		end
	end

	return false
end

return function(_, players)
	for _, player in pairs(players) do
		local char = player.Character
		if not char or hasForcefield(char) then
			continue
		end

		local ff = Instance.new("ForceField")
		CollectionService:AddTag(ff, "CmdrForceField")
		ff.Parent = char
	end
end
