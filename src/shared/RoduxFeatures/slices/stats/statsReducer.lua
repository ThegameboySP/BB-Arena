local ReplicatedStorage = game:GetService("ReplicatedStorage")

local t = require(ReplicatedStorage.Packages.t)
local Llama = require(ReplicatedStorage.Packages.Llama)
local GameEnum = require(ReplicatedStorage.Common.GameEnum)
local RoduxUtils = require(script.Parent.Parent.Parent.RoduxUtils)

local Dictionary = Llama.Dictionary
local Gamemodes = ReplicatedStorage.Common.Gamemodes

local function add(tbl, key, amount)
    local value = 0
    if tbl then
        value = tbl[key]
    end

    if type(value) ~= "number" then
        value = 0
    end

    return value + amount
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
        local payload = action.payload

        local rank
        if payload.name == "KOs" then
            rank = calculateRank(add(state.alltimeStats[payload.userId], "KOs", payload.amount))
        end

        local patch = {}
        for _, key in {"alltimeStats", "serverStats", "visualStats"} do
            patch[key] = {
                [payload.userId] = {
                    [payload.name] = add(state[key][payload.userId], payload.name, payload.amount);
                };
            }
        end

        return Dictionary.mergeDeep(
            state,
            patch,
            rank and {
                ranks = {[payload.userId] = rank};
            }
        )
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
        })
    end;
    users_joined = function(state, action)
        return Dictionary.mergeDeep(state, {
            serverStats = {[action.payload.userId] = defaultStats};
            visualStats = {[action.payload.userId] = defaultStats};
        })
    end;
})