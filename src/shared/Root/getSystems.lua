local function getSystems(instance, systems)
	systems = systems or {}

	for _, child in instance:GetChildren() do
		if child:IsA("ModuleScript") and not child.Name:find("%.spec$") then
			table.insert(systems, require(child))
		elseif child:IsA("Folder") then
			getSystems(child, systems)
		end
	end

	return systems
end

return getSystems
