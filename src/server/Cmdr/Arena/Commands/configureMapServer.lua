local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CmdrUtils = require(ReplicatedStorage.Common.Utils.CmdrUtils)

return function(context, key, value)
	local MapService = context:GetStore("Common").Root:GetService("MapService")
	local mapScript = MapService.MapScript

	if mapScript == nil or not mapScript.Options or not mapScript.Options[key] then
		return "Option not found for map"
	end

	local resolvedValue = CmdrUtils.transformType(value)

	local didSet, oldValue = mapScript.Options[key].Set(mapScript, resolvedValue)

	if didSet then
		return string.format("Set map option %s from %s to %s", key, tostring(oldValue), tostring(resolvedValue))
	end

	if oldValue == resolvedValue then
		return string.format("Map option %s is already set at %s", key, tostring(oldValue))
	end

	return string.format("Failed to set map option %s", key)
end
