local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Root = require(ReplicatedStorage.Common.Root)

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
    _leaderstats = {};
    _loggedIn = {};
    _stats = {};
}

function StatController:OnInit()
    local function onPlayerAdded(player)
        self._loggedIn[player.UserId] = true
    end

    Players.PlayerAdded:Connect(onPlayerAdded)
    for _, player in Players:GetPlayers() do
        onPlayerAdded(player)
    end

    Players.PlayerRemoving:Connect(function(player)
        self._loggedIn[player.UserId] = nil
        self._leaderstats[player.UserId] = nil
    end)

    self:_updateInit(Root.Store:getState().stats)

    Root.Store.changed:connect(function(new, old)
        if new.stats.visualStats ~= old.stats.visualStats then
            for userId, stats in new.stats.visualStats do
                local oldStats = old.stats.visualStats[userId]
    
                for name, value in stats do
                    if not oldStats or oldStats[name] ~= value then
                        self:_update(userId, name, value)
                    end
                end
            end
        end

        if new.stats.visibleRegisteredStats ~= old.stats.visibleRegisteredStats then
            for id in new.stats.visibleRegisteredStats do
                if not old.stats.visibleRegisteredStats[id] then
                    self:_setStatVisibility(id, true)
                end
            end

            for id in old.stats.visibleRegisteredStats do
                if not new.stats.visibleRegisteredStats[id] then
                    self:_setStatVisibility(id, false)
                end
            end
        end
    end)
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

function StatController:_update(userId, name, value)
    local stats = Root.Store:getState().stats

    if stats.visibleRegisteredStats[name] then
        local registeredStat = stats.registeredStats[name]

        local resolvedName = registeredStat.friendlyName or name
        local leaderstats = self:_getOrMakeLeaderstats(userId)
        if leaderstats == nil then
            return
        end

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
        for userId, values in Root.Store:getState().stats.visualStats do
            for statName, value in values do
                if statName == name then
                    self:_update(userId, name, value)
                end
            end
        end
    else
        for _, leaderstat in self._leaderstats do
            for _, stat in leaderstat:GetChildren() do
                if stat:GetAttribute("InternalName") == name then
                    stat.Parent = nil
                end
            end
        end
    end
end

function StatController:_updateInit(stats)
    local statsToAdd = {}

    for _, stat in stats.registeredStats do
        if stats.visibleRegisteredStats[stat.name] then
            table.insert(statsToAdd, stat)
        end
    end
    
    table.sort(statsToAdd, function(a, b)
        return a.priority > b.priority
    end)

    for _, stat in statsToAdd do
        for userId, values in stats.visualStats do
            for name, value in values do
                if name == stat.name then
                    self:_update(userId, name, value)
                end
            end
        end
    end
end

return StatController