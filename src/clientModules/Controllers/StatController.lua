local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Llama = require(ReplicatedStorage.Packages.Llama)
local Dictionary = Llama.Dictionary

local StatController = Knit.CreateController({
	Name = "StatController";
    _stats = {};
    _leaderstats = {};

    Changed = Signal.new();
})

local valueClassByType = {
    string = "StringValue";
	number = "NumberValue";
	boolean = "BoolValue";
	Vector3 = "Vector3Value";
	CFrame = "CFrameValue";
	Color3 = "Color3Value";
	Instance = "ObjectValue";
	BrickColor = "BrickColorValue";
}

local function mapToNumber(map)
    local tbl = {}
    for key, value in pairs(map) do
        tbl[tonumber(key)] = value
    end

    return tbl
end

function StatController:KnitInit()
    local StatService = Knit.GetService("StatService")
    StatService.InitStats:Connect(function(stats)
        for key, users in pairs(stats) do
            stats[key] = mapToNumber(users)
        end

        local old = self._stats
        self._stats = stats

        self:_render(stats, old)
        self.Changed:Fire(stats, old)
    end)

    StatService.StatSet:Connect(function(userId, name, value)
        local old = self._stats
        self._stats = Dictionary.mergeDeep(self._stats, {
            [name] = {[userId] = value}
        })

        self:_render(self._stats, old)
        self.Changed:Fire(self._stats, old)
    end)

    local function onPlayerAdded(player)
        local leaderstats = Instance.new("NumberValue")
        leaderstats.Name = "leaderstats"
        leaderstats.Parent = player
        self._leaderstats[player.UserId] = leaderstats
    end

    Players.PlayerAdded:Connect(onPlayerAdded)
    for _, player in pairs(Players:GetPlayers()) do
        onPlayerAdded(player)
    end

    Players.PlayerRemoving:Connect(function(player)
        self._leaderstats[player.UserId] = nil
    end)
end

function StatController:GetStats()
    return self._stats
end

function StatController:_render(new, old)
    for name, newStats in pairs(new) do
        local oldStats = old[name] or {}

        for userId, value in pairs(newStats) do
            local playerStat = self._leaderstats[userId]:FindFirstChild(name)

            if oldStats[userId] and playerStat.ClassName == valueClassByType[typeof(value)] then
                playerStat.Value = value
            else
                if playerStat then
                    playerStat.Parent = nil
                end

                local newPlayerStat = Instance.new(valueClassByType[typeof(value)])
                newPlayerStat.Value = value
                newPlayerStat.Name = name
                newPlayerStat.Parent = self._leaderstats[userId]
            end
        end
    end

    for name, oldStats in pairs(old) do
        local newStats = new[name] or {}

        for userId in pairs(oldStats) do
            if newStats[userId] == nil then
                self._leaderstats[userId]:FindFirstChild(name).Parent = nil
            end
        end
    end
end

return StatController