local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

local getFullPlayerName = require(ReplicatedStorage.Common.Utils.getFullPlayerName)

local function getName(state, userId)
	local userInfo = state.users.activeUsers[userId]
	return getFullPlayerName(userInfo.displayName, userInfo.name)
end

local function achievementAnnouncer(root)
	local function onChanged(new, old)
		if new.stats.currentKillstreak == old.stats.currentKillstreak then
			return
		end

		local lastKillstreak = old.stats.currentKillstreak
		for userId, killstreak in new.stats.currentKillstreak do
			if lastKillstreak[userId] and lastKillstreak[userId] == killstreak then
				continue
			end

			local message
			if killstreak == 5 then
				message = string.format("%s is on a kill streak: %d kills", getName(new, userId), killstreak)
			elseif killstreak % 5 == 0 and killstreak > 5 then
				message = string.format("%s is on a MONSTER streak: %d kills", getName(new, userId), killstreak)
			end

			if message then
				StarterGui:SetCore("ChatMakeSystemMessage", {
					Text = message,
					Color = Color3.fromRGB(0, 0, 0),
				})
			end
		end
	end

	root.StoreChanged:Connect(onChanged)
end

return achievementAnnouncer
