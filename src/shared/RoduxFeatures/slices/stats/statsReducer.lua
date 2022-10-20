local ReplicatedStorage = game:GetService("ReplicatedStorage")

local t = require(ReplicatedStorage.Packages.t)
local Llama = require(ReplicatedStorage.Packages.Llama)
local GameEnum = require(ReplicatedStorage.Common.GameEnum)
local RoduxUtils = require(script.Parent.Parent.Parent.RoduxUtils)

local Dictionary = Llama.Dictionary
local Gamemodes = ReplicatedStorage.Common.Gamemodes

local function addFromTable(source, delta)
    local clone = table.clone(source)

    for key, amount in delta do
        if type(clone[key]) == "number" then
            clone[key] = clone[key] + amount
        else
            clone[key] = amount
        end
    end

    return clone
end

local function calculateRank(kos)
    if type(kos) ~= "number" then
        return GameEnum.Ranks.F
    end

    if kos > 50 then
        return GameEnum.Ranks.E
    elseif kos > 100 then
        return GameEnum.Ranks.D
    elseif kos > 200 then
        return GameEnum.Ranks.C
    elseif kos > 500 then
        return GameEnum.Ranks.B
    elseif kos > 1000 then
        return GameEnum.Ranks.A
    elseif kos > 2000 then
        return GameEnum.Ranks.S
    elseif kos > 4000 then
        return GameEnum.Ranks.SPlus
    end

    return GameEnum.Ranks.F
end

local checkRegisteredStat = t.interface({
    default = t.any;
    name = t.string;
    friendlyName = t.optional(t.string);
    priority = t.number;
    domain = t.optional(t.string);
    persistent = t.optional(t.boolean);
    show = t.optional(t.boolean);
})

local defaultStats = {}
local registeredStats = {
    KOs = {name = "KOs", default = 0, priority = 1, show = true};
    WOs = {name = "WOs", default = 0, priority = 0, show = true};
}

for _, gamemode in Gamemodes:GetChildren() do
    local definition = require(gamemode).definition

    for name, stat in definition.stats do
        if registeredStats[name] then
            error(string.format("Duplicate stat name: %q", name))
        end

        local clone = table.clone(stat)
        clone.gamemodeId = definition.nameId
        clone.name = name

        registeredStats[name] = clone
    end
end

local registeredStatArray = {}
for _, stat in registeredStats do
    stat.priority = stat.priority or -1
    stat.friendlyName = stat.friendlyName or stat.name
    assert(checkRegisteredStat(stat))

    table.insert(registeredStatArray, stat)
end

table.sort(registeredStatArray, function(a, b)
    return a.name > b.name
end)

for index, stat in registeredStatArray do
    stat.id = index
    registeredStats[stat.id] = stat
    defaultStats[stat.name] = stat.default
end

local DEFAULT_STAT_KEYS = {"alltimeStats", "serverStats", "visualStats"}

local function increment(state, userId, keys, delta)
    local patch = {}
    for _, key in keys do
        patch[key] = {
            [userId] = addFromTable(state[key][userId], delta);
        }
    end

    local final = Dictionary.mergeDeep(state, patch)
    if delta.KOs and (table.find(keys, "serverStats") or table.find(keys, "alltimeStats")) then
        return Dictionary.mergeDeep(final, {
            ranks = {[userId] = calculateRank(final.alltimeStats[userId])};
        })
    end

    return final
end

return RoduxUtils.createReducer({
    alltimeStats = {};
    serverStats = {};
    -- Server stats that are displayed to the user.
    -- This is separate since users can manually change their stats.
    visualStats = {};
    ranks = {};

    visibleRegisteredStats = {
        KOs = true;
        WOs = true;
    };
    usersReceivedGamemodeStats = {};
    registeredStats = registeredStats;
}, {
    rodux_hotReloaded = function(state)
        return Dictionary.merge(state, {
            registeredStats = registeredStats;
        })
    end;
    rodux_serialize = function(state)
        local serialized = {}

        serialized.alltimeStats = RoduxUtils.numberIndicesToString(state.alltimeStats)
        serialized.serverStats = RoduxUtils.numberIndicesToString(state.serverStats)
        serialized.visualStats = RoduxUtils.numberIndicesToString(state.visualStats)
        serialized.ranks = RoduxUtils.numberIndicesToString(state.ranks)
        serialized.usersReceivedGamemodeStats = RoduxUtils.numberIndicesToString(state.usersReceivedGamemodeStats)
        serialized.visibleRegisteredStats = state.visibleRegisteredStats

        return serialized
    end;
    rodux_deserialize = function(state, action)
        local serialized = action.payload.serialized.stats
        local patch = {}

        patch.alltimeStats = RoduxUtils.stringIndicesToNumber(serialized.alltimeStats)
        patch.serverStats = RoduxUtils.stringIndicesToNumber(serialized.serverStats)
        patch.visualStats = RoduxUtils.stringIndicesToNumber(serialized.visualStats)
        patch.ranks = RoduxUtils.stringIndicesToNumber(serialized.ranks)
        patch.usersReceivedGamemodeStats = RoduxUtils.stringIndicesToNumber(serialized.usersReceivedGamemodeStats)
        patch.visibleRegisteredStats = serialized.visibleRegisteredStats

        return Dictionary.merge(state, patch)
    end;

    stats_initializeUser = function(state, action)
        local payload = action.payload

        return Dictionary.mergeDeep(state, {
            alltimeStats = {[payload.userId] = payload.stats};
            rank = payload.stats.KOs and {[payload.userId] = calculateRank(payload.stats.KOs)};
        })
    end;
    stats_setVisual = function(state, action)
        local payload = action.payload

        return Dictionary.mergeDeep(state, {
            visualStats = {[payload.userId] = {[payload.name] = payload.value}};
        })
    end;
    stats_increment = function(state, action)
        return increment(state, action.payload.userId, DEFAULT_STAT_KEYS, {
            [action.payload.name] = action.payload.amount;
        })
    end;
    stats_resetUsers = function(state, action)
        local patch = {}
        for _, userId in action.payload.userIds do
            patch[userId] = defaultStats
        end

        return Dictionary.mergeDeep(state, {
            visualStats = patch;
        })
    end;
    game_playerDied = function(state, action)
        local payload = action.payload

        local newState
        if payload.deathCause == GameEnum.DeathCause.Admin then
            newState = increment(state, payload.userId, {"visualStats"}, {
                WOs = 1
            })
        else
            newState = increment(state, payload.userId, DEFAULT_STAT_KEYS, {
                WOs = 1
            })
        end

        if payload.deathCause ~= GameEnum.DeathCause.Admin and payload.killerId and payload.userId ~= payload.killerId then
            return increment(newState, payload.killerId, DEFAULT_STAT_KEYS, {
                KOs = 1;
            })
        end

        return newState
    end;
    game_gamemodeEnded = function(state, action)
        local gamemodeId = action.payload.gamemodeId

        local noneStats = {}
        local visibleRegisteredStats = {}
        for id, stat in registeredStats do
            if stat.gamemodeId == gamemodeId then
                noneStats[id] = Llama.None
                visibleRegisteredStats[id] = Llama.None
            end
        end

        local visualStatsPatch = {}
        for userId in state.usersReceivedGamemodeStats do
            visualStatsPatch[userId] = noneStats
        end

        return Dictionary.merge(state, {
            visualStats = Dictionary.mergeDeep(state.visualStats, visualStatsPatch);
            usersReceivedGamemodeStats = {};
            visibleRegisteredStats = Dictionary.merge(state.visibleRegisteredStats, visibleRegisteredStats);
        })
    end;
    game_gamemodeStarted = function(state, action, rootState)
        local gamemodeId = action.payload.gamemodeId

        local initializedStats = {}
        local visibleRegisteredStats = {}

        for id, stat in registeredStats do
            if stat.gamemodeId == gamemodeId then
                if stat.show then
                    visibleRegisteredStats[id] = true
                end

                initializedStats[id] = stat.default
            elseif defaultStats[id] then
                initializedStats[id] = defaultStats[id]
            end
        end

        local visualStatsPatch = {}
        for userId in rootState.users.activeUsers do
            visualStatsPatch[userId] = initializedStats
        end

        return Dictionary.merge(state, {
            visualStats = Dictionary.mergeDeep(state.visualStats, visualStatsPatch);
            visibleRegisteredStats = Dictionary.merge(state.visibleRegisteredStats, visibleRegisteredStats);
            usersReceivedGamemodeStats = rootState.users.activeUsers;
        })
    end;
    users_left = function(state, action)
        return Dictionary.mergeDeep(state, {
            serverStats = {[action.payload.userId] = Llama.None};
            alltimeStats = {[action.payload.userId] = Llama.None};
            visualStats = {[action.payload.userId] = Llama.None};
            ranks = {[action.payload.userId] = Llama.None};
        })
    end;
    users_joined = function(state, action)
        return Dictionary.mergeDeep(state, {
            serverStats = {[action.payload.userId] = defaultStats};
            visualStats = {[action.payload.userId] = defaultStats};
            alltimeStats = {[action.payload.userId] = defaultStats};
            ranks = {[action.payload.userId] = GameEnum.Ranks.F};
        })
    end;
})