local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Maps = ServerStorage:FindFirstChild("Maps")

local GameEnum = require(ReplicatedStorage.Common.GameEnum)
local RoduxFeatures = require(ReplicatedStorage.Common.RoduxFeatures)
local selectors = RoduxFeatures.selectors

return function(context, mapName)
	local map = Maps:FindFirstChild(mapName)

	if map and map:GetAttribute("LockedMap") then
		local lockedMap = map:GetAttribute("LockedMap")
		local state = context:GetStore("Common").Store:getState()

		if selectors.getAdmin(state, context.Executor.UserId) < GameEnum.AdminTiers.Owner then
			return
				"This map is currently not available and you don't have permission to change to it." .. (type(
				lockedMap
			) == "string" and ("\nReason: %q"):format(lockedMap) or "")
		end
	end

	local _, err = context:GetStore("Common").Root:GetService("MapService"):ChangeMap(mapName)

	return err
end
