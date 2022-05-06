local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Rodux = require(ReplicatedStorage.Packages.Rodux)
local Llama = require(ReplicatedStorage.Packages.Llama)

local Dictionary = Llama.Dictionary

return Rodux.createReducer({
    kos = {};
    wos = {};
    kdr = {};
    allTimeKOs = {};
    allTimeWOs = {};
    teams = {};
}, {
    datastore_userFetched = function(state, action)
        local userId = action.payload.userId
        local stats = action.payload.file.stats

        local kos = state.allTimeKOs[userId] + (stats.kos or 0)
        local wos = state.allTimeWOs[userId] + (stats.wos or 0)

        return Dictionary.mergeDeep(state, {
            allTimeKOs = {[userId] = kos};
            allTimeWOs = {[userId] = wos};
            kdr = {[userId] = kos / wos};
        })
    end;
    users_joined = function(state, action)
        local userId = action.payload.userId

        return Dictionary.map(state, function(value, key)
            if key == "teams" then
                return value
            end

            return Dictionary.merge({
                [userId] = value[userId] or 0
            })
        end)
    end;
    users_left = function(state, action)
        return Dictionary.mergeDeep(state, {
            allTimeKOs = {
                [action.payload.userId] = Llama.None;
            };
            allTimeWOs = {
                [action.payload.userId] = Llama.None;
            }
        })
    end;
    players_died = function(state, action)
        local victimId = action.payload.victimId
        local killerId = action.payload.killerId

        return Dictionary.mergeDeep({
            wos = {[victimId] = state.wos[victimId] + 1};
            allTimeWOs = {[victimId] = state.wos[victimId] + 1};
            kdr = {
                [victimId] = state.kos[victimId] / state.wos[victimId];
            };
        }, killerId and {
            kos = {[killerId] = state.kos[killerId] + 1};
            allTimeKOs = {[killerId] = state.allTimeKOs[killerId] + 1};
            kdr = {
                [killerId] = state.kos[killerId] / state.wos[killerId];
            }
        })
    end;
})