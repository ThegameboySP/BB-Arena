return function(registry, mapInfo)
	local names = {}
	for name in pairs(mapInfo) do
		table.insert(names, name)
	end

	registry:RegisterType("map", registry.Cmdr.Util.MakeEnumType("Map", names))
end
