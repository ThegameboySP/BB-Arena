local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")

local DataStoreService = require(ServerScriptService.Packages.MockDataStoreService)
local Llama = require(ReplicatedStorage.Packages.Llama)
local Promise = require(ReplicatedStorage.Packages.Promise)
local Signal = require(ReplicatedStorage.Packages.Signal)

local RoduxFeatures = require(ReplicatedStorage.Common.RoduxFeatures)
local Root = require(ReplicatedStorage.Common.Root)

local GameDataStoreService = {
    Name = "GameDataStoreService";
    Client = {};

    _isLoaded = {};
    _playerSettingsState = {};
}

-- A simple DataStore wrapper. Only handles pushing/pulling and caching.
function GameDataStoreService:OnStart()
    local PlayerData = DataStoreService:GetDataStore("PlayerData")

    local store = Root.Store

    local function onPlayerAdded(player)
        local userId = player.UserId

        local data
        local ok, err = pcall(function()
            data = PlayerData:GetAsync(userId)
        end)

        if not ok then
            warn("[GameDataStoreService]", "Failed to fetch player data:", err)
        end

        local isConnected = player:IsDescendantOf(game)

        if isConnected then
            self._playerSettingsState[userId] = store:getState().users.userSettings[userId]

            if data then
                store:dispatch(RoduxFeatures.actions.saveSettings(userId, data.settings))
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
        local playerSettingsState = self._playerSettingsState[userId]
        local state = store:getState()
        local isLoaded = self._isLoaded[userId]

        self._isLoaded[userId] = nil
        self._playerSettingsState[userId] = nil

        -- If player leaves before data is fetched, don't update.
        -- If no change occurred in user's settings, don't update.
        if
            not isLoaded
            or playerSettingsState == state.users.userSettings[userId]
        then
            warn("[GameDataStoreService]", "Not updating", player, "data")
            return
        end

        local ok, err = pcall(function()
            PlayerData:UpdateAsync(userId, function(data)
                return Llama.Dictionary.mergeDeep(data or {}, {
                    version = "0.0.1";
                    settings = state.users.userSettings[userId];
                })
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