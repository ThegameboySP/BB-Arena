local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local DataStoreService = require(ServerScriptService.Packages.MockDataStoreService)
local Knit = require(ReplicatedStorage.Packages.Knit)

local mergeStats = require(script.mergeStats)

local BBLService = Knit.CreateService({
    Name = "BBLService";
    Client = {};

    _statsToFlush = {};
    _isOfficial = false;
    _tracking = false;
})

function BBLService:KnitInit()
    self.StatService = Knit.GetService("StatService")
    self.GamemodeService = Knit.GetService("GamemodeService")
    self.StatsStore = DataStoreService:GetDataStore("_bbl-stats")

    self.stats = self.StatService:NewStatScope()

    self.GamemodeService.GamemodeStarted:Connect(function(definition)
        self.stats:Clear()

        if definition.nameId == "ControlPoints" then
            self._tracking = true
        end
    end)

    self.GamemodeService.GamemodeOver:Connect(function(event)
        if event.cancelled or not self._tracking or not self._isOfficial then
            return
        end

        self:_flushStatsToDataStore(self.stats:Get())

        self._isOfficial = false
        self._tracking = false
    end)
end

function BBLService:_flushStatsToDataStore(stats)
    if stats then
        table.insert(self._statsToFlush, stats)
    end

    local ok, err = pcall(function()
        self.StatsStore:UpdateAsync("data", function(data)
            local resolvedStats = data and data.stats

            for _, statPatch in ipairs(self._statsToFlush) do
                resolvedStats = mergeStats(resolvedStats, statPatch)
            end

            local clonedData = data and table.clone(data) or {}
            clonedData.stats = resolvedStats

            return clonedData
        end)
    end)

    if ok then
        warn("[BBL]", "Successfully saved stats to DataStore")
        table.clear(self._statsToFlush)

        return true
    else
        warn("[BBL Critical]", "Stats couldn't save to DataStore!\n", err)

        return false
    end
end

function BBLService:SetGamemodeOfficial(_isOfficial)
    self._isOfficial = _isOfficial
end

return BBLService