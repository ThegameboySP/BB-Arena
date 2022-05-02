local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)

local LitUtils = require(ReplicatedStorage.Common.Utils.LitUtils)
local permissions = require(ReplicatedStorage.Common.RoduxFeatures.permissions)
local AdminTierByValue = permissions.AdminTierByValue

local GatekeepingService = Knit.CreateService({
    Name = "GatekeepingService";
    Client = {
        ServerLocked = Knit.CreateProperty(false);
    };

    _bannedUserIds = {};
})

local function banMessage(adminLevel)
    local adminTier = AdminTierByValue[adminLevel]

    return string.format(
        "You've been banned from this server by %s %s.",
        LitUtils.getIndefiniteArticle(adminTier),
        adminTier
    )
end

local function lockedServerMessage(adminLevel)
    local adminTier = AdminTierByValue[adminLevel]

    return string.format(
        "This server is locked by %s %s.",
        LitUtils.getIndefiniteArticle(adminTier),
        adminTier
    )
end

local function selectPlayersToBan(state)
    local toBan = {}

    for userId in pairs(state.banned) do
        if not state.whitelisted[userId] then
            table.insert(toBan, userId)
        end
    end

    return toBan
end

local function shouldBan(state, userId, kickerAdmin)
    if state.whitelisted[userId] then
        return false
    end

    local userAdmin = state.admins[userId] or 0
    return kickerAdmin > userAdmin
end

function GatekeepingService:KnitStart()
    Knit.Store.Changed:Connect(function(new, old)
        if new.whitelisted == old.whitelisted and new.banned == old.banned then
            return
        end

        local state = Knit.Store:getState()

        for _, userId in pairs(selectPlayersToBan(state)) do
            local player = Players:GetPlayerByUserId(userId)

            if player then
                local bannedRecord = state.banned[userId]
                local bannerAdmin = state.admins[bannedRecord.bannerId]

                if player and (state.admins[userId] or 0) < bannerAdmin then
                    player:Kick(banMessage(bannerAdmin))
                end
            end
        end
    end)
    
    local function onPlayerAdded(player)
        local bannedMessage
        local lockedMessage

        do
            local lockedPermissionLevel = Knit.Store:getState().serverLockedLevel
            if lockedPermissionLevel then
                lockedMessage = lockedServerMessage(lockedPermissionLevel)
            end

            local bannedPermissionLevel = self._bannedUserIds[player.UserId]
            if bannedPermissionLevel and shouldBan(Knit.Store:getState(), player.UserId, lockedPermissionLevel) then
                bannedMessage = banMessage(lockedPermissionLevel)
            end
        end

        if bannedMessage and lockedMessage then
            player:Kick(string.format("%s\n...and %s\nWow!", lockedMessage, bannedMessage))
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