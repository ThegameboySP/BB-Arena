local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RoduxFeatures = require(ReplicatedStorage.Common.RoduxFeatures)
local actions = RoduxFeatures.actions

return function(context, userIds)
    local store = context:GetStore("Common").Store

    for _, userId in pairs(userIds) do
        local state = store:getState()
        store:dispatch(actions.setUserWhitelisted(userId, false, context.Executor.UserId))

        if store:getState() ~= state then
            context:Reply(string.format("Successfully unwhitelisted %s", userId))
        end
    end

    return ""
end