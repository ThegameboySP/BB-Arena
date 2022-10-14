local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RoduxFeatures = require(ReplicatedStorage.Common.RoduxFeatures)

return function(context, players, name, value)
    local store = context:GetStore("Common").Root.Store

    for _, player in players do
        local userId = player.UserId
        local oldValue = store:getState().stats.visualStats[player.UserId][name]
        store:dispatch(RoduxFeatures.actions.setStatVisual(userId, name, value))

        context:Reply(string.format("%s %q %s -> %s", tostring(player), name, tostring(oldValue), tostring(value)))
    end

    return ""
end