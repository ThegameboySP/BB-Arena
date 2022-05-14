local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RoduxFeatures = require(ReplicatedStorage.Common.RoduxFeatures)
local getFullPlayerName = require(ReplicatedStorage.Common.Utils.getFullPlayerName)
local actions = RoduxFeatures.actions

return function(context, players)
    local store = context:GetStore("Common").Store

    for _, player in pairs(players) do
        local state = store:getState()
        store:dispatch(actions.setUserBanned(player.UserId, context.Executor.UserId, true))

        if store:getState() ~= state then
            context:Reply(string.format("Successfully banned %s", getFullPlayerName(player)))
        end
    end

    return ""
end