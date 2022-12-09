local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RoduxFeatures = require(ReplicatedStorage.Common.RoduxFeatures)
local actions = RoduxFeatures.actions

return function(context)
	local store = context:GetStore("Common").Store
	local state = store:getState()

	store:dispatch(actions.setServerLocked(true, context.Executor.UserId))
	if store:getState() == state then
		return "Server is already locked."
	end

	return "Server successfully locked."
end
