local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Root = require(ReplicatedStorage.Common.Root)
local t = require(ReplicatedStorage.Packages.t)
local EventBus = require(ReplicatedStorage.Common.EventBus)

local PlayerStats = require(script.PlayerStats)

local StatService = {
    Name = "StatService";
    Client = {
        InitStats = Root.remoteEvent();
        StatSet = Root.remoteEvent();
        SetStatVisibility = Root.remoteEvent();
    };

    Stats = PlayerStats.new();

    _statObjects = setmetatable({}, {__mode = "k"});
    _replicatedValues = {};
    _registeredStats = {};
}

local PLAYER_FILTER = function(player)
    return player:GetAttribute("StatsInitialized") == true
end

function StatService:OnInit()
    self._statObjects[self.Stats] = true

    self.Stats.Changed:Connect(function(userId, name, value)
        if not self._registeredStats[name] or not self._replicatedValues[userId] then
            return
        end

        local lastReplicatedValue = self._replicatedValues[userId][name]
        
        if
            type(value) == "number"
            and (type(lastReplicatedValue) ~= "number" or math.floor(value) ~= math.floor(lastReplicatedValue))
        then
            self._replicatedValues[userId][name] = value
            self.Client.StatSet:FireFilter(PLAYER_FILTER, userId, name, value)
        end
    end)

    self:RegisterStat({name = "KOs", default = 0, priority = 1, show = true})
    self:RegisterStat({name = "WOs", default = 0, priority = 0, show = true})

    EventBus.fighterDied:Connect(function(victim, killer)
        self:IncrementStat(victim.UserId, "WOs", 1)

        if killer and killer ~= victim then
            self:IncrementStat(killer.UserId, "KOs", 1)
        end
    end)
end

function StatService:OnStart()
    -- Defer so services can register their stats before initial replication.
    task.defer(function()
        local function onPlayerAdded(player)
            local userId = player.UserId

            self._replicatedValues[userId] = {}
    
            for statName, stat in pairs(self._registeredStats) do
                if not stat.persistent or self:GetStat(statName, userId) == nil then
                    for statObject in pairs(self._statObjects) do
                        statObject:Set(userId, statName, stat.default)
                    end
                end
            end
    
            self.Client.InitStats:FireClient(player, self.Stats:Get(), self._registeredStats)
            player:SetAttribute("StatsInitialized", true)
        end
    
        Players.PlayerAdded:Connect(onPlayerAdded)
        for _, player in pairs(Players:GetPlayers()) do
            onPlayerAdded(player)
        end
    
        Players.PlayerRemoving:Connect(function(player)
            local userId = player.UserId

            self._replicatedValues[userId] = nil

            for statName, stat in pairs(self._registeredStats) do
                if not stat.persistent then
                    for statObject in pairs(self._statObjects) do
                        statObject:Set(userId, statName, nil)
                    end
                end
            end
        end)
    end)
end

function StatService:SetStatVisibility(name, visible)
    local stat = self._registeredStats[name]

    if stat.show ~= visible then
        stat.show = visible
        
        self.Client.SetStatVisibility:FireFilter(PLAYER_FILTER, name, visible)
    end
end

local checkRegisteredStat = t.interface({
    default = t.any;
    name = t.string;
    friendlyName = t.optional(t.string);
    priority = t.optional(t.number);
    domain = t.optional(t.string);
    persistent = t.optional(t.boolean);
    show = t.optional(t.boolean);
})

function StatService:RegisterStat(data)
    if self._registeredStats[data.name] then
        error(string.format("%q is an already registered stat name", data.name))
    end

    self._registeredStats[data.name] = assert(checkRegisteredStat(data)) and data
end

function StatService:GetRegisteredStatsByDomain(domain)
    local registeredStats = {}

    for _, registeredStat in pairs(self._registeredStats) do
        if registeredStat.domain == domain then
            table.insert(registeredStats, registeredStat)
        end
    end

    return registeredStats
end

function StatService:GetRegisteredStats()
    return self._registeredStats
end

function StatService:NewStatScope()
    local playerStats = PlayerStats.new()
    self._statObjects[playerStats] = true

    for _, player in pairs(Players:GetPlayers()) do
        local userId = player.UserId

        for statName, stat in pairs(self._registeredStats) do
            for statObject in pairs(self._statObjects) do
                statObject:Set(userId, statName, stat.default)
            end
        end
    end

    return playerStats
end

function StatService:SetStat(userId, name, value)
    for statObject in pairs(self._statObjects) do
        statObject:Set(userId, name, value)
    end
end

function StatService:IncrementStat(userId, name, amount)
    for statObject in pairs(self._statObjects) do
        statObject:Increment(userId, name, amount)
    end
end

return StatService