local Players = game:GetService("Players")

local GameEnum = require(game:GetService("ReplicatedStorage").Common.GameEnum)
local RoduxFeatures = require(game:GetService("ReplicatedStorage").Common.RoduxFeatures)
local actions = RoduxFeatures.actions
local selectors = RoduxFeatures.selectors

return function (context, userIds)
    local store = context:GetStore("Common").Store
    local state = store:getState()

    for _, userId in pairs(userIds) do
        local bannedBy = state.users.banned[userId]

        if bannedBy == nil then
            context:Reply(string.format("%d isn't currently banned.", userId))
            continue
        end

        if selectors.getAdmin(state, bannedBy) > selectors.getAdmin(state, context.Executor.UserId) then
            context:Reply(string.format(
                "%d is banned by %s (%s). You don't have permission to unban them.",
                userId,
                Players:GetNameFromUserIdAsync(bannedBy),
                GameEnum.AdminTiersByValue[selectors.getAdmin(state, bannedBy)] or "unknown"
            ))
            continue
        end

        store:dispatch(actions.setUserBanned(userId, context.Executor.UserId, false))
        
        context:Reply(string.format("Successfully unbanned %d.", userId))
    end

    return ""
end