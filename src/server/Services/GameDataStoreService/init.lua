local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

local DataStoreService = require(ServerScriptService.Packages.MockDataStoreService)
local Promise = require(ReplicatedStorage.Packages.Promise)
local Signal = require(ReplicatedStorage.Packages.Signal)

local RoduxFeatures = require(ReplicatedStorage.Common.RoduxFeatures)

local Leaderboard = require(script.Leaderboard)
local updaters = require(script.updaters)
local updateSave = require(script.updateSave)

local GameDataStoreService = {
	Name = "GameDataStoreService",
	Client = {},

	_isLoaded = {},
}

function GameDataStoreService:OnStart()
	local store = self.Root.Store

	self._playerData = DataStoreService:GetDataStore("PlayerData")
	self._leaderboard = Leaderboard.new(store, DataStoreService:GetOrderedDataStore("PlayerKOLeaderboard"), warn)
	self._leaderboard:Schedule()

	local function onPlayerAdded(player)
		local userId = player.UserId

		local promise = Promise.new(function(resolve)
			resolve(self._playerData:GetAsync(userId))
		end):timeout(10)

		local status, returned = promise:awaitStatus()

		if status == Promise.Status.Rejected then
			warn("[GameDataStoreService]", "Failed to fetch player data:", returned)
			store:dispatch(RoduxFeatures.actions.datastoreFetchFailed(userId))
		end

		local isConnected = player:IsDescendantOf(game)

		if isConnected and status == Promise.Status.Resolved then
			if returned then
				local index
				for i, updater in updaters do
					if updater.onVersion == returned.version then
						index = i
						break
					end
				end

				if index then
					for i = index, #updaters do
						local updater = updaters[i]
						returned = updater.step(returned)
					end
				end

				-- Dispatch individual actions instead of one for data successfully fetched.
				-- You can enforce replication rules and there's less redundancy.
				store:dispatch(RoduxFeatures.actions.saveSettings(userId, returned.settings))
				store:dispatch(RoduxFeatures.actions.initializeUserStats(userId, returned.stats))
				store:dispatch(RoduxFeatures.actions.setTimePlayed(userId, { timePlayed = returned.timePlayed }))
			end
		end

		if self._isLoaded[userId] then
			self._isLoaded[userId]:Fire(isConnected)
		end

		self._isLoaded[userId] = isConnected or nil
	end

	Players.PlayerAdded:Connect(onPlayerAdded)
	for _, player in Players:GetPlayers() do
		task.spawn(onPlayerAdded, player)
	end
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

		self._playerData:UpdateAsync(userId, function(data)
			oldData = data
			newData = updateSave({
				version = "0.0.3",
				settings = state.users.userSettingsToSave[userId],
				stats = state.stats.serverStats[userId],
				timePlayed = Workspace:GetServerTimeNow() - state.users.activeUsers[userId].joinedTimestamp,
			}, data)

			return newData
		end)

		return newData, oldData
	end)
		:catch(function(err)
			warn("[GameDataStoreService]", "Failed to update player data:", tostring(err))
		end)
		:andThen(function(newData, oldData)
			-- Don't connect this promise, as we already provide all the info it needs and the data is immutable.
			self._leaderboard:OnUserDisconnecting(userId, newData.stats, if oldData then oldData.stats else nil)
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

return GameDataStoreService
