local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Root = require(ReplicatedStorage.Common.Root)
local Signal = require(ReplicatedStorage.Packages.Signal)

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

local StatController = {
	Name = "StatController";
    _stats = {};
    _leaderstats = {};
    _loggedIn = {};

    Changed = Signal.new();
}

local function mapToNumber(map)
    local tbl = {}
    for key, value in pairs(map) do
        tbl[tonumber(key)] = value
    end

    return tbl
end

function StatController:OnInit()
    local function onPlayerAdded(player)
        self._loggedIn[player.UserId] = true
    end

    Players.PlayerAdded:Connect(onPlayerAdded)
    for _, player in pairs(Players:GetPlayers()) do
        onPlayerAdded(player)
    end

    Players.PlayerRemoving:Connect(function(player)
        self._loggedIn[player.UserId] = nil
        self._leaderstats[player.UserId] = nil
    end)

    local StatService = Root:GetServerService("StatService")
    
    StatService.InitStats:Connect(function(stats, registeredStats)
        self._registeredStats = registeredStats

        for key, value in pairs(stats) do
            stats[key] = mapToNumber(value)
        end

        self._stats = stats

        self:_updateInit(stats)
    end)

    StatService.StatSet:Connect(function(userId, name, value)
        local oldValue = self._stats[name][userId]
        self._stats[name][userId] = value

        self:_update(userId, name, value)
        self.Changed:Fire(name, userId, value, oldValue)
    end)

    StatService.SetStatVisibility:Connect(function(name, visible)
        self._registeredStats[name].show = visible
        self:_setStatVisibility(name, visible)
    end)
end

function StatController:GetStats()
    return self._stats
end

function StatController:_getOrMakeLeaderstats(userId)
    if not self._loggedIn[userId] then
        return
    end
    
    local leaderstats = self._leaderstats[userId]
    
    if not leaderstats then
        leaderstats = Instance.new("NumberValue")
        leaderstats.Name = "leaderstats"
        leaderstats.Parent = Players:GetPlayerByUserId(userId)
        self._leaderstats[userId] = leaderstats
    end

    return leaderstats
end

-- Priority TODO
function StatController:_update(userId, name, value)
    local registeredStat = self._registeredStats[name]

    if registeredStat.show then
        local resolvedName = registeredStat.friendlyName or name
        local leaderstats = self:_getOrMakeLeaderstats(userId)
        local stat = leaderstats:FindFirstChild(resolvedName)

        if not stat or stat.ClassName ~= valueClassByType[typeof(value)] then
            if stat then
                stat.Parent = nil
            end

            stat = Instance.new(valueClassByType[typeof(value)])
            stat.Name = resolvedName
            stat:SetAttribute("InternalName", name)

            stat.Parent = leaderstats
        end

        stat.Value = value
    end
end

function StatController:_setStatVisibility(name, visible)
    if visible then
        for userId, value in pairs(self._stats[name]) do
            self:_update(userId, name, value)
        end
    else
        for _, leaderstat in pairs(self._leaderstats) do
            for _, stat in pairs(leaderstat:GetChildren()) do
                if stat:GetAttribute("InternalName") == name then
                    stat.Parent = nil
                end
            end
        end
    end
end

function StatController:_updateInit(stats)
    for name, users in pairs(stats) do
        if not self._registeredStats[name].show then
            continue
        end

        for userId, value in pairs(users) do
            self:_update(userId, name, value)
        end
    end
end

return StatController