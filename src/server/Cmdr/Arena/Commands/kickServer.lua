local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RoduxFeatures = require(ReplicatedStorage.Common.RoduxFeatures)
local selectors = RoduxFeatures.selectors

local getFullPlayerName = require(ReplicatedStorage.Common.Utils.getFullPlayerName)
local GameEnum = require(ReplicatedStorage.Common.GameEnum)
local LitUtils = require(ReplicatedStorage.Common.Utils.LitUtils)

return function(context, players)
    local store = context:GetStore("Common").Store

    local executerId = context.Executor.UserId
    local state = store:getState()
    local executorRank = GameEnum.AdminTiersByValue[selectors.getAdmin(state, executerId)]

    for _, player in pairs(players) do
        if selectors.canUserBeKickedBy(state, player.UserId, executerId) then
            context:Reply(string.format("Successfully kicked %s", getFullPlayerName(player)))

            player:Kick(string.format(
                "You've been kicked by %s %s",
                LitUtils.getIndefiniteArticle(executorRank),
                executorRank
            ))
        end
    end

    return ""
end