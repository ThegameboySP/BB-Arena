local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserService = game:GetService("UserService")

local Llama = require(ReplicatedStorage.Packages.Llama)
local Promise = require(ReplicatedStorage.Packages.Promise)
local RoduxFeatures = require(ReplicatedStorage.Common.RoduxFeatures)
local WebConstants = require(ReplicatedStorage.Common.StaticData.WebConstants)
local getFullPlayerName = require(ReplicatedStorage.Common.Utils.getFullPlayerName)
local base64 = require(script.Parent.base64)

local function serializeKey(userId, WOs)
	return base64.encode(string.pack("I8I8", userId, WOs))
end

local function deserializeKey(key)
	return string.unpack("I8I8", base64.decode(key))
end

local Leaderboard = {}
Leaderboard.__index = Leaderboard
Leaderboard.serializeKey = serializeKey
Leaderboard.deserializeKey = deserializeKey

function Leaderboard.new(store, leaderboardStore, log, getStatsForPlayer)
	return setmetatable({
		_store = store,
		_leaderboard = leaderboardStore,
		_log = log,
		_getStatsForPlayer = getStatsForPlayer,
	}, Leaderboard)
end

function Leaderboard:Update()
	local top100
	local _, err = pcall(function()
		local leaderboardPages = self._leaderboard:GetSortedAsync(false, 100)
		top100 = leaderboardPages:GetCurrentPage()
	end)

	if not top100 then
		self._log("[Leaderboard]", "Failed to fetch player KO leaderboard:", err)
		self._store:dispatch(RoduxFeatures.actions.leaderboardFetchFailed())
		return
	end

	local leaderboard = {}
	local entryByUserId = {}
	local userIds = {}
	local authoritativeStatsByUserId = {}

	for _, entry in top100 do
		local userId, WOs = deserializeKey(entry.key)
		local existingEntry = entryByUserId[userId]

		-- If there are duplicate entries of the same user, be sure to delete the ones that are outdated.
		-- This shouldn't cause throttling since it's rare. And even if two servers do the same thing,
		-- they're setting it to the same value (removing it).
		if existingEntry then
			if not authoritativeStatsByUserId[userId] then
				authoritativeStatsByUserId[userId] = self._getStatsForPlayer(userId)
			end

			local authoritativeKey = serializeKey(userId, authoritativeStatsByUserId[userId].WOs)
			local existingKey = serializeKey(userId, existingEntry.WOs)
			local thisKey = serializeKey(userId, WOs)

			if authoritativeKey ~= existingKey then
				self._log(
					string.format(
						"[Leaderboard] Removing old entry %s: KOs: %d WOs: %d",
						tostring(userId),
						existingEntry.KOs,
						existingEntry.WOs
					)
				)

				task.spawn(function()
					self._leaderboard:RemoveAsync(existingKey)
				end)

				-- This entry is older. Don't display it to users.
				table.remove(leaderboard, table.find(leaderboard, userId))
			end

			if authoritativeKey ~= thisKey then
				self._log(
					string.format(
						"[Leaderboard] Removing old entry %s: KOs: %d WOs: %d",
						tostring(userId),
						entry.value,
						WOs
					)
				)

				task.spawn(function()
					self._leaderboard:RemoveAsync(thisKey)
				end)

				-- This entry is older. Don't display it to users.
				continue
			end
		end

		entryByUserId[userId] = {
			userId = userId,
			WOs = WOs,
			KOs = entry.value,
		}

		table.insert(userIds, userId)
		table.insert(leaderboard, entryByUserId[userId])
	end

	return Promise.try(function()
		return UserService:GetUserInfosByUserIdsAsync(userIds)
	end)
		:andThen(function(userInfos)
			local gotUserInfo = {}
			for _, userInfo in userInfos do
				entryByUserId[userInfo.Id].name = getFullPlayerName(userInfo.DisplayName, userInfo.Username)
				gotUserInfo[userInfo.Id] = true
			end

			for i = #leaderboard, 1, -1 do
				local entry = leaderboard[i]
				if not gotUserInfo[entry.userId] then
					self._log("[Leaderboard]", "Removing", entry.userId, entry.WOs, ": UserId is somehow invalid")

					table.remove(leaderboard, i)

					task.spawn(function()
						self._leaderboard:RemoveAsync(serializeKey(entry.userId, entry.WOs))
					end)
				end
			end

			local current = self._store:getState().leaderboard.users
			if not Llama.Dictionary.equalsDeep(current, leaderboard) then
				self._log("[Leaderboard]", "Dispatching leaderboard fetched because it's changed")
				self._store:dispatch(RoduxFeatures.actions.leaderboardFetched(leaderboard))
			end
		end)
		:catch(function(infosErr)
			self._log("[Leaderboard]", "Failed to fetch users info:", tostring(infosErr))
		end)
end

function Leaderboard:Schedule()
	task.delay(WebConstants.LEADERBOARD_FETCH, self.Schedule, self)
	self:Update()
end

function Leaderboard:OnUserDisconnecting(userId, newStats, oldStats, name)
	local alltimeKOs = newStats.KOs
	local alltimeWOs = newStats.WOs
	local oldKOs = if oldStats then oldStats.KOs else 0
	local oldWOs = if oldStats then oldStats.WOs else 0

	-- Don't update anything if there has been no change, or if they never had a KO.
	if oldKOs == alltimeKOs and oldWOs == alltimeWOs then
		self._log("[Leaderboard]", "Not updating", name, "data")
		return Promise.resolve()
	end

	self._log("[Leaderboard]", "Updating", name, "data")

	return Promise.all({
		Promise.try(function()
			if oldStats and alltimeWOs > oldWOs then
				local oldKey = serializeKey(userId, oldWOs)
				self._leaderboard:RemoveAsync(oldKey)
			end
		end),
		Promise.try(function()
			local newKey = serializeKey(userId, alltimeWOs)
			self._leaderboard:SetAsync(newKey, alltimeKOs)
		end),
	}):catch(function(err)
		self._log("[Leaderboard]", "Failed to update player leaderboard data:", tostring(err))
	end)
end

return Leaderboard
