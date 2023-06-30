local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RoduxFeatures = require(ReplicatedStorage.Common.RoduxFeatures)
local actions = RoduxFeatures.actions

return function(context, enabled)
	local store = context:GetStore("Common").Store
	local original = store:getState().game.anonymousFighters
	store:dispatch(actions.setAnonymousFighters(enabled))

	return if original == store:getState().game.anonymousFighters
		then "Already " .. tostring(enabled)
		elseif enabled then "Set to true"
		else "Set to false"
end
