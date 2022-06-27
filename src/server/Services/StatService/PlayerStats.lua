local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Signal = require(ReplicatedStorage.Packages.Signal)

local PlayerStats = {}
PlayerStats.__index = PlayerStats

function PlayerStats.new()
    return setmetatable({
        Changed = Signal.new();
        _stats = {};
    }, PlayerStats)
end

function PlayerStats:Clear()
    for name, usersStats in pairs(self._stats) do
        for userId, value in pairs(usersStats) do
            usersStats[userId] = nil

            self.Changed:Fire(userId, name, nil, value)
        end
    end
end

function PlayerStats:Set(userId, name, value)
    local oldValue = self:GetUserStat(userId, name)
    if oldValue == value then
        return
    end
    
    local userStats = self._stats[name]
    if userStats == nil then
        userStats = {}
        self._stats[name] = userStats
    end

    userStats[userId] = value

    self.Changed:Fire(userId, name, value, oldValue)
end

function PlayerStats:Increment(userId, name, amount)
    self:Set(userId, name, (self:GetUserStat(userId, name) or 0) + amount)
end

function PlayerStats:GetUserStat(userId, name)
    local userStats = self._stats[name]
    if userStats == nil then
        return nil
    end

    return userStats[userId]
end

function PlayerStats:Get()
    return self._stats
end

return PlayerStats