local CollectionService = game:GetService("CollectionService")

return function(_, players)
	for _, player in pairs(players) do
		local char = player.Character
		if not char then
			continue
		end

		for _, child in char:GetChildren() do
			if child:IsA("ForceField") and not CollectionService:HasTag(child, "StreamingMapForcefield") then
				child.Parent = nil
			end
		end
	end
end
