local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")

local LitUtils = require(ReplicatedStorage.Common.Utils.LitUtils)
local GameEnum = require(ReplicatedStorage.Common.GameEnum)
local RoduxFeatures = require(ReplicatedStorage.Common.RoduxFeatures)
local selectors = RoduxFeatures.selectors

local GatekeepingService = {
	Name = "GatekeepingService",
	Client = {},

	serverLockedBy = nil,
}

local function banMessage(by)
	if by == "server" then
		return "You've been banned from this game permanently."
	end

	local adminTier = GameEnum.AdminTiersByValue[by]
	return string.format(
		"You've been banned from this server by %s %s.",
		LitUtils.getIndefiniteArticle(adminTier),
		adminTier
	)
end

local function lockedServerMessage(adminLevel)
	local adminTier = GameEnum.AdminTiersByValue[adminLevel]
	return string.format("This server is locked by %s %s.", LitUtils.getIndefiniteArticle(adminTier), adminTier)
end

function GatekeepingService:OnPlayerAdded(player: Player): boolean
	local bannedMessage
	local lockedMessage
	local state = self.Root.Store:getState()

	if self.defaultBanList and self.defaultBanList[player.UserId] then
		bannedMessage = banMessage("server")
	end

	if selectors.canUserBeLockKicked(state, player.UserId, state.users.serverLockedBy) then
		lockedMessage = lockedServerMessage(selectors.getAdmin(state, state.users.serverLockedBy))
	end

	local bannedBy = selectors.getUserBannedBy(state, player.UserId)
	if selectors.canUserBeKickedBy(state, player.UserId, bannedBy) then
		bannedMessage = banMessage(selectors.getAdmin(state, bannedBy))
	end

	if bannedMessage and lockedMessage then
		player:Kick(
			string.format(
				"%s...and %s...Wow!",
				bannedMessage,
				lockedMessage:sub(1, 1):lower() .. lockedMessage:sub(2, -1)
			)
		)

		warn("Kicking", player, "due to being banned AND server being locked")
		return false
	elseif bannedMessage then
		player:Kick(bannedMessage)
		warn("Kicking", player, "due to being banned")
		return false
	elseif lockedMessage then
		player:Kick(lockedMessage)
		warn("Kicking", player, "due to the server being locked")
		return false
	else
		return true
	end
end

function GatekeepingService:OnStart()
	self.defaultBanList = ServerScriptService:FindFirstChild("Place"):FindFirstChild("DefaultBanList")
	self.defaultBanList = self.defaultBanList and require(self.defaultBanList)

	self.Root.StoreChanged:Connect(function(new, old)
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
end

return GatekeepingService
