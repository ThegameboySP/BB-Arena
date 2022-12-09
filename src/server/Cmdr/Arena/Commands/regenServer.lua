return function(context, instances)
	local MapService = context:GetStore("Common").Root:GetService("MapService")

	MapService:Regen(instances and function(instance)
		return table.find(instances, instance)
	end)
end
