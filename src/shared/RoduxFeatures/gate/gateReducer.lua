local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Rodux = require(ReplicatedStorage.Packages.Rodux)
local Llama = require(ReplicatedStorage.Packages.Llama)

local Dictionary = Llama.Dictionary

return Rodux.createReducer({
    serverLockedBy = nil;
    banned = {};
    whitelisted = {};
}, {
    gate_lockServer = function(state, action)
        return Dictionary.merge(state, {
            serverLockedBy = action.payload.userId;
        })
    end;
    gate_userBanned = function(state, action)
        return Dictionary.mergeDeep(state, {
            banned = {
                [action.payload.userId] = action.payload;
            };
            whitelisted = {
                [action.payload.userId] = Llama.None;
            };
        })
    end;
    gate_userUnbanned = function(state, action)
        return Dictionary.mergeDeep(state, {
            banned = {
                [action.payload.userId] = Llama.None;
            }
        })
    end;
    gate_userWhitelisted = function(state, action)
        return Dictionary.mergeDeep(state, {
            whitelisted = {
                [action.payload.userId] = true;
            };
            banned = {
                [action.payload.userId] = Llama.None;
            }
        })
    end;
    gate_userUnwhitelisted = function(state, action)
        return Dictionary.mergeDeep(state, {
            whitelisted = {
                [action.payload.userId] = Llama.None;
            }
        })
    end;
})