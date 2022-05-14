local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RoduxFeatures = require(ReplicatedStorage.Common.RoduxFeatures)
local actions = RoduxFeatures.actions

return function (context)
	local store = context:GetStore("Common").Store
    local state = store:getState()

	store:dispatch(actions.setServerLocked(context.Executor.UserId, false))
	if store:getState() == state then
		return "Server is already unlocked."
	end

	return "Server successfully unlocked."
end