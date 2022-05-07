local Players = game:GetService("Players")

local GameEnum = require(game:GetService("ReplicatedStorage").Common.GameEnum)
local RoduxFeatures = require(game:GetService("ReplicatedStorage").Common.RoduxFeatures)
local actions = RoduxFeatures.actions
local selectors = RoduxFeatures.selectors

return function (context, userId)
    local store = context:GetStore("Common").Store
    local state = store:getState()
    local bannedBy = state.users.banned[userId]

    if bannedBy == nil then
        return string.format("%d isn't currently banned.", userId)
    end

    if selectors.getAdmin(state, bannedBy) > selectors.getAdmin(state, userId) then
        return string.format(
            "%d is banned by %s (%s). You don't have permission to unban them.",
            userId,
            Players:GetNameFromUserIdAsync(bannedBy),
            GameEnum.AdminTiersByValue[selectors.getAdmin(state, bannedBy)] or "unknown"
        )
    end

    store:dispatch(actions.setUserBanned(userId, context.Executor.UserId, false))
    
    return string.format("Successfully unbanned %d.", userId)
end