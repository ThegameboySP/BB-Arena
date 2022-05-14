local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Rodux = require(ReplicatedStorage.Packages.Rodux)
local Llama = require(ReplicatedStorage.Packages.Llama)

local Dictionary = Llama.Dictionary

return Rodux.createReducer({
    serverLockedBy = nil;
    banned = {};
    whitelisted = {};
    admins = {};
    activeUsers = {};
}, {
    users_joined = function(state, action)
        return Dictionary.mergeDeep(state, {
            activeUsers = {[action.payload.userId] = true}
        })
    end;
    users_left = function(state, action)
        return Dictionary.mergeDeep(state, {
            activeUsers = {[action.payload.userId] = Llama.None}
        })
    end;
    users_setAdmin = function(state, action)
        return Dictionary.mergeDeep(state, {
            admins = {[action.payload.userId] = action.payload.admin};
        })
    end;
    users_setServerLocked = function(state, action)
        return Dictionary.merge(state, {
            serverLockedBy = if action.payload.isLocked then action.payload.userId else Llama.None;
        })
    end;
    users_setBanned = function(state, action)
        if action.payload.isBanned then
            return Dictionary.mergeDeep(state, {
                banned = {
                    [action.payload.userId] = action.payload.byUser;
                };
            })
        else
            return Dictionary.mergeDeep(state, {
                banned = {
                    [action.payload.userId] = Llama.None;
                }
            })
        end
    end;
    users_setWhitelisted = function(state, action)
        if action.payload.isWhitelisted then
            return Dictionary.mergeDeep(state, {
                whitelisted = {
                    [action.payload.userId] = action.payload.byUser;
                };
            })
        else
            return Dictionary.mergeDeep(state, {
                whitelisted = {
                    [action.payload.userId] = Llama.None;
                }
            })
        end
    end;
})