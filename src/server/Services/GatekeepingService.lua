local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)

local LitUtils = require(ReplicatedStorage.Common.Utils.LitUtils)
local GameEnum = require(ReplicatedStorage.Common.GameEnum)
local RoduxFeatures = require(ReplicatedStorage.Common.RoduxFeatures)
local selectors = RoduxFeatures.selectors

local GatekeepingService = Knit.CreateService({
    Name = "GatekeepingService";
    Client = {};

    serverLockedBy = nil;
})

local function banMessage(adminLevel)
    local adminTier = GameEnum.AdminTiersByValue[adminLevel]
    return string.format(
        "You've been banned from this server by %s %s.", LitUtils.getIndefiniteArticle(adminTier), adminTier
    )
end

local function lockedServerMessage(adminLevel)
    local adminTier = GameEnum.AdminTiersByValue[adminLevel]
    return string.format(
        "This server is locked by %s %s.", LitUtils.getIndefiniteArticle(adminTier), adminTier
    )
end

function GatekeepingService:KnitStart()
    Knit.Store.changed:connect(function(new, old)
        if new.users == old.users then
            return
        end

        local users = new.users

        for _, player in pairs(Players:GetPlayers()) do
            local userId = player.UserId
            local bannedBy = users.banned[userId]
            
            if bannedBy and selectors.canUserBeKickedBy(new, userId, bannedBy) then
                player:Kick(banMessage(selectors.getAdmin(new, bannedBy)))
            end
        end
    end)

    local function onPlayerAdded(player)
        local bannedMessage
        local lockedMessage
        local state = Knit.Store:getState()

        if selectors.canUserBeKickedBy(state, player.UserId, state.users.serverLockedBy or "none") then
            lockedMessage = lockedServerMessage(selectors.getAdmin(state, state.users.serverLockedBy))
        end

        local bannedBy = selectors.getUserBannedBy(state, player.UserId)
        if selectors.canUserBeKickedBy(state, player.UserId, bannedBy or "none") then
            bannedMessage = banMessage(selectors.getAdmin(state, bannedBy))
        end

        if bannedMessage and lockedMessage then
            player:Kick(string.format("%s...and %s...Wow!", bannedMessage, lockedMessage:sub(1, 1):lower() .. lockedMessage:sub(2, -1)))
        elseif bannedMessage then
            player:Kick(bannedMessage)
        elseif lockedMessage then
            player:Kick(lockedMessage)
        end
    end

    Players.PlayerAdded:Connect(onPlayerAdded)
    for _, player in pairs(Players:GetPlayers()) do
        onPlayerAdded(player)
    end
end

return GatekeepingService