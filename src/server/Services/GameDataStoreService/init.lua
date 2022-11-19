local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")

local DataStoreService = require(ServerScriptService.Packages.MockDataStoreService)
local Promise = require(ReplicatedStorage.Packages.Promise)
local Signal = require(ReplicatedStorage.Packages.Signal)

local RoduxFeatures = require(ReplicatedStorage.Common.RoduxFeatures)

local updaters = require(script.updaters)
local updateSave = require(script.updateSave)

local GameDataStoreService = {
    Name = "GameDataStoreService";
    Client = {};

    _isLoaded = {};
    _playerSettingsState = {};
    _playerStatsState = {};
}

function GameDataStoreService:_shouldUpdate(userId)
    local state = self.Root.Store:getState()

    return 
        self._isLoaded[userId]
        and (
            self._playerSettingsState[userId] ~= state.users.userSettings[userId]
            or self._playerStatsState[userId] ~= state.stats.serverStats[userId]
        )
end

-- A simple DataStore wrapper. Only handles pushing/pulling and caching.
function GameDataStoreService:OnStart()
    local PlayerData = DataStoreService:GetDataStore("PlayerData")

    local store = self.Root.Store

    local function onPlayerAdded(player)
        local userId = player.UserId

        local promise = Promise.new(function(resolve)
            resolve(PlayerData:GetAsync(userId))
        end):timeout(10)

        local status, returned = promise:awaitStatus()

        if status == Promise.Status.Rejected then
            warn("[GameDataStoreService]", "Failed to fetch player data:", returned)
            store:dispatch(RoduxFeatures.actions.datastoreFetchFailed(userId))
        end

        local isConnected = player:IsDescendantOf(game)

        if isConnected and status == Promise.Status.Resolved then
            local state = store:getState()
            self._playerSettingsState[userId] = state.users.userSettings[userId]
            self._playerStatsState[userId] = state.stats.serverStats[userId]

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

    Players.PlayerRemoving:Connect(function(player)
        local userId = player.UserId
        local state = store:getState()
        local shouldUpdate = self:_shouldUpdate(userId)

        self._isLoaded[userId] = nil
        self._playerSettingsState[userId] = nil
        self._playerStatsState[userId] = nil

        if not shouldUpdate then
            warn("[GameDataStoreService]", "Not updating", player, "data")
            return
        end

        local ok, err = pcall(function()
            PlayerData:UpdateAsync(userId, function(data)
                return updateSave({
                    version = "0.0.3";
                    settings = state.users.userSettings[userId];
                    stats = state.stats.serverStats[userId];
                }, data)
            end)
        end)

        if not ok then
            warn("[GameDataStoreService]", "Failed to update player data:", err)
            return
        end
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
            return
                if isConnected
                then Promise.resolve()
                else Promise.reject()
        end)
    end

    return Promise.reject()
end

return GameDataStoreService