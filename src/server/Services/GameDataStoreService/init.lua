local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

local DataStoreService = require(ServerScriptService.Packages.MockDataStoreService)
local Promise = require(ReplicatedStorage.Packages.Promise)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Llama = require(ReplicatedStorage.Packages.Llama)

local RoduxFeatures = require(ReplicatedStorage.Common.RoduxFeatures)

local Leaderboard = require(script.Leaderboard)
local updaters = require(script.updaters)
local updateSave = require(script.updateSave)

local GameDataStoreService = {
	Name = "GameDataStoreService",
	Client = {},

	_isLoaded = {},
}

local function stepData(data)
	local index
	for i, updater in updaters do
		if updater.onVersion == data.version then
			index = i
			break
		end
	end

	if index then
		for i = index, #updaters do
			local updater = updaters[i]
			data = updater.step(data)
		end
	end

	return data
end

function GameDataStoreService:OnPlayerAdded(player)
	local userId = player.UserId
	local store = self.Root.Store

	return Promise.new(function(resolve)
		resolve(self._playerData:GetAsync(userId))
	end)
		:timeout(10)
		:andThen(function(data)
			if player.Parent and data then
				data = stepData(data)

				-- Dispatch individual actions instead of one for data successfully fetched.
				-- You can enforce replication rules and there's less redundancy.
				store:dispatch(RoduxFeatures.actions.saveSettings(userId, data.settings))
				store:dispatch(RoduxFeatures.actions.initializeUserStats(userId, data.stats))
				store:dispatch(RoduxFeatures.actions.setTimePlayed(userId, data.timePlayed))
			end
		end)
		:catch(function(err)
			warn("[GameDataStoreService]", "Failed to fetch player data:", tostring(err))
			store:dispatch(RoduxFeatures.actions.datastoreFetchFailed(userId))
		end)
		:finally(function()
			local isConnected = player.Parent ~= nil

			if self._isLoaded[userId] then
				self._isLoaded[userId]:Fire(isConnected)
			end

			self._isLoaded[userId] = isConnected or nil
		end)
end

function GameDataStoreService:OnInit()
	self._playerData = DataStoreService:GetDataStore("PlayerData")
	self._leaderboard = Leaderboard.new(
		self.Root.Store,
		DataStoreService:GetOrderedDataStore("PlayerKOLeaderboard"),
		warn,
		function(userId)
			return self._playerData:GetAsync(userId).stats
		end
	)
	self._leaderboard:Schedule()
end

function GameDataStoreService:OnPlayerRemoving(player)
	local userId = player.UserId
	local state = self.Root.Store:getState()

	if not self._isLoaded[userId] then
		warn("[GameDataStoreService]", "Not saving", player, "data")
		return Promise.resolve()
	end

	self._isLoaded[userId] = nil

	return Promise.try(function()
		local newData
		local oldData

		local isNotPrivateServer = game.PrivateServerId == ""

		local ok, err
		self._playerData:UpdateAsync(userId, function(data)
			ok, err = pcall(function()
				oldData = if data then stepData(data) else {}

				newData = updateSave({
					version = "0.0.4",
					settings = state.users.userSettingsToSave[userId],
					stats = if isNotPrivateServer then state.stats.serverStats[userId] else {},
					timePlayed = Workspace:GetServerTimeNow() - state.users.activeUsers[userId].joinedTimestamp,
				}, oldData)
			end)

			if ok then
				return newData
			end

			return nil
		end)

		if not ok then
			error(err)
		end

		return newData, oldData
	end)
		:andThen(function(newData, oldData)
			return self._leaderboard:OnUserDisconnecting(
				userId,
				newData.stats,
				if oldData then oldData.stats else nil,
				player.Name
			)
		end)
		:catch(function(err)
			warn("[GameDataStoreService]", "Failed to update player data:", tostring(err))
		end)
end

function GameDataStoreService:IsPlayerLoaded(userId)
	local player = Players:GetPlayerByUserId(userId)

	if player then
		if self._isLoaded[userId] == true then
			return Promise.resolve()
		end

		if not self._isLoaded[userId] then
			self._isLoaded[userId] = Signal.new()
		end

		return Promise.fromEvent(self._isLoaded[userId]):andThen(function(isConnected)
			return if isConnected then Promise.resolve() else Promise.reject()
		end)
	end

	return Promise.reject()
end

-- If the player's data is being saved on a different server, there are three edge cases:
-- A.) We update first. In which case, the other server will work off our latest value. No problem.
-- B.) We update last. In which case, the stats they accumulated on that server will be removed,
-- and the leaderboard info the other server just set likely will be removed as well, assuming
-- there are no odd Datastore delays.
-- C.) The above, but there was a delay, meaning the old leaderboard value and our new one both
-- exist. If both are in the top 100, the oldest should be cleared next refresh.
function GameDataStoreService:SetLeaderboardData(userId, key, value)
	local oldStats
	local newStats
	Promise.promisify(self._playerData.UpdateAsync)(self._playerData, userId, function(data)
		oldStats = Llama.Dictionary.copyDeep(data.stats)
		newStats = data.stats

		data.stats[key] = value

		return data
	end)
		:andThen(function()
			self.Root.Store:dispatch(RoduxFeatures.actions.initializeUserStats(userId, newStats))
			return self._leaderboard:OnUserDisconnecting(userId, newStats, oldStats, tostring(userId))
		end)
		:andThen(function()
			self._leaderboard:Update()
		end)
end

return GameDataStoreService
