local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RoduxFeatures = require(ReplicatedStorage.Common.RoduxFeatures)
local actions = RoduxFeatures.actions

local function mapUserIds(items)
    local userIds = {}

    for _, item in items do
        if typeof(item) == "Instance" then
            table.insert(userIds, item.UserId)
        else
            table.insert(userIds, item)
        end
    end

    return userIds
end

return function(context, players)
    local store = context:GetStore("Common").Store
    local root = context:GetStore("Common").Root

    for _, userId in mapUserIds(players) do
        local state = store:getState()
        store:dispatch(actions.setUserBanned(userId, context.Executor.UserId, true))

        if store:getState() ~= state then
            root:GetFullNameByUserId(userId):andThen(function(name)
                context:Reply(string.format("Successfully banned %s", name))
            end)
        end
    end

    return ""
end