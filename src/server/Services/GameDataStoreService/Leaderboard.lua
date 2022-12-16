local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Promise = require(ReplicatedStorage.Packages.Promise)
local RoduxFeatures = require(ReplicatedStorage.Common.RoduxFeatures)
local WebConstants = require(ReplicatedStorage.Common.StaticData.WebConstants)

local function serializeKey(userId, WOs)
	return string.pack("I8I8", userId, WOs)
end

local function deserializeKey(key)
	return string.unpack("I8I8", key)
end

local Leaderboard = {}
Leaderboard.__index = Leaderboard
Leaderboard.serializeKey = serializeKey
Leaderboard.deserializeKey = deserializeKey

function Leaderboard.new(store, leaderboardStore, log)
	return setmetatable({
		_store = store,
		_leaderboard = leaderboardStore,
		_log = log,
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
	for _, entry in top100 do
		local userId, WOs = deserializeKey(entry.key)

		local existingEntry = entryByUserId[userId]
		-- If there are duplicate entries of the same user, be sure to delete the one that has fewer KOs or WOs (oldest).
		-- This shouldn't cause throttling since it's rare. And even if two servers do the same thing, they're setting it to the same value.
		if existingEntry then
			if entry.value >= existingEntry.KOs or WOs >= existingEntry.WOs then
				task.spawn(function()
					self._leaderboard:SetAsync(serializeKey(existingEntry.userId, existingEntry.WOs), nil)
				end)
			else
				task.spawn(function()
					self._leaderboard:RemoveAsync(serializeKey(userId, WOs))
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

		table.insert(leaderboard, entryByUserId[userId])
	end

	self._store:dispatch(RoduxFeatures.actions.leaderboardFetched(leaderboard))
end

function Leaderboard:Schedule()
	task.delay(WebConstants.LEADERBOARD_FETCH, self.Schedule, self)
	self:Update()
end

function Leaderboard:OnUserDisconnecting(userId, newStats, oldStats)
	local alltimeKOs = newStats.KOs
	local alltimeWOs = newStats.WOs
	local oldKOs = if oldStats then oldStats.KOs else 0
	local oldWOs = if oldStats then oldStats.WOs else 0

	-- Don't update anything if there has been no change, or if they never had a KO.
	if (oldKOs == alltimeKOs and oldWOs == alltimeWOs) or alltimeKOs <= 0 then
		return Promise.resolve()
	end

	return Promise.all({
		Promise.try(function()
			if oldStats then
				local oldKey = serializeKey(userId, oldWOs)
				self._leaderboard:RemoveAsync(oldKey)
			end
		end),
		Promise.try(function()
			local newKey = serializeKey(userId, newStats.WOs)
			self._leaderboard:SetAsync(newKey, alltimeKOs)
		end),
	}):catch(function(err)
		self._log("[Leaderboard]", "Failed to update player leaderboard data:", tostring(err))
	end)
end

return Leaderboard
