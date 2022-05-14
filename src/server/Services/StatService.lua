local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Knit = require(ReplicatedStorage.Packages.Knit)
local t = require(ReplicatedStorage.Packages.t)
local Llama = require(ReplicatedStorage.Packages.Llama)
local Signal = require(ReplicatedStorage.Packages.Signal)
local EventBus = require(ReplicatedStorage.Common.EventBus)

local Dictionary = Llama.Dictionary

local StatService = Knit.CreateService({
    Name = "StatService";
    Client = {
        InitStats = Knit.CreateSignal();
        StatSet = Knit.CreateSignal();
    };

    Changed = Signal.new();

    _stats = {};
    _registeredStats = {};
})

function StatService:KnitInit()
    self:RegisterStat("KOs", {default = 0})
    self:RegisterStat("WOs", {default = 0})

    EventBus.fighterDied:Connect(function(victim, killer)
        self:IncrementStat(victim.UserId, "WOs", 1)

        if killer then
            self:IncrementStat(killer.UserId, "KOs", 1)
        end
    end)
end

function StatService:KnitStart()
    -- Defer so services can register their stats before initial replication.
    task.defer(function()
        local function onPlayerAdded(player)
            local userId = player.UserId
    
            for statName, stat in pairs(self._registeredStats) do
                if not stat.persistent or self:GetStat(statName, userId) == nil then
                    self:SetStat(userId, statName, stat.default)
                end
            end
    
            self.Client.InitStats:Fire(player, self:GetStats())
            player:SetAttribute("StatsInitialized", true)
        end
    
        Players.PlayerAdded:Connect(onPlayerAdded)
        for _, player in pairs(Players:GetPlayers()) do
            onPlayerAdded(player)
        end
    
        Players.PlayerRemoving:Connect(function(player)
            for statName, stat in pairs(self._registeredStats) do
                if not stat.persistent then
                    self:SetStat(player.UserId, statName, nil)
                end
            end
        end)
    end)
end

local checkConfig = t.strictInterface({
    default = t.any;
    domain = t.optional(t.string);
    persistent = t.optional(t.boolean);
})

function StatService:RegisterStat(name, config)
    self._registeredStats[name] = assert(checkConfig(config)) and config
    self._stats = Dictionary.merge(self._stats, {[name] = {}})
end

function StatService:GetStatNamesByDomain(domain)
    local statNames = {}

    for statName, stat in pairs(self._registeredStats) do
        if stat.domain == domain then
            table.insert(statNames, statName)
        end
    end

    return statNames
end

function StatService:GetRegisteredStats()
    return self._registeredStats
end

function StatService:GetStats()
    return self._stats
end

function StatService:SetStat(userId, name, value)
    if not self._registeredStats[name] then
        return
    end

    local old = self._stats
    self._stats = Dictionary.mergeDeep(self._stats, {
        [name] = {[userId] = value}
    })

    self.Client.StatSet:FireFilter(function(player)
        return player:GetAttribute("StatsInitialized") == true
    end, userId, name, value)
    self.Changed:Fire(self._stats, old)
end

function StatService:IncrementStat(userId, name, amount)
    self:SetStat(userId, name, self._stats[name][userId] + amount)
end

return StatService