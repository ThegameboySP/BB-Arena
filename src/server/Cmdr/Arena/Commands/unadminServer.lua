local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameEnum = require(ReplicatedStorage.Common.GameEnum)
local RoduxFeatures = require(ReplicatedStorage.Common.RoduxFeatures)
local getFullPlayerName = require(ReplicatedStorage.Common.Utils.getFullPlayerName)
local actions = RoduxFeatures.actions

return function(context, players)
    local store = context:GetStore("Common").Store
    
    for _, player in pairs(players) do
        local state = store:getState()
        store:dispatch(actions.setAdmin(player.UserId, GameEnum.AdminTiers.None, context.Executor.UserId))

        if store:getState() ~= state then
            context:Reply(string.format("Successfully unadmined %s", getFullPlayerName(player)))
        end
    end

    return ""
end