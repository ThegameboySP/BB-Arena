local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local GameEnum = require(ReplicatedStorage.Common.GameEnum)

local usersSelectors = require(script.Parent.usersSelectors)
local getAdmin = usersSelectors.getAdmin

local actions = {}

function actions.setAdmin(userId, admin, byUser)
    return function(store)
        local state = store:getState()
        
        if
            byUser == nil or
            (getAdmin(state, byUser) > admin and getAdmin(state, userId) < getAdmin(state, byUser))
        then
            store:dispatch({
                type = "users_setAdmin";
                payload = {
                    userId = userId;
                    admin = admin;
                };
            })
        end
    end
end

function actions.setReferee(userId, isReferee, byUser)
    return function(store)
        local state = store:getState()
        
        if
            byUser == nil or
            (getAdmin(state, byUser) >= GameEnum.AdminTiers.Owner)
        then
            store:dispatch({
                type = "users_setReferee";
                payload = {
                    userId = userId;
                    isReferee = isReferee;
                };
            })
        end
    end
end

function actions.setUserWhitelisted(userId, isWhitelisted, byUser)
    return function(store)
        local state = store:getState()
        local whitelistedBy = state.users.whitelisted[userId]

        if getAdmin(state, byUser) > getAdmin(state, whitelistedBy) then
            store:dispatch({
                type = "users_setWhitelisted";
                payload = {
                    isWhitelisted = isWhitelisted;
                    byUser = byUser;
                    userId = userId;
                }
            })
        end
    end
end

function actions.setServerLocked(isLocked, lockingUserId)
    return function(store)
        local state = store:getState()

        if
            isLocked ~= (not not state.users.serverLockedBy)
            or getAdmin(state, lockingUserId) >= getAdmin(state, state.users.serverLockedBy)
        then
            store:dispatch({
                type = "users_setServerLocked";
                payload = {
                    isLocked = isLocked;
                    userId = lockingUserId;
                }
            })

            if isLocked then
                for userId in pairs(state.users.activeUsers) do
                    store:dispatch(actions.setUserWhitelisted(userId, true, lockingUserId))
                end
            end
        end
    end
end

function actions.setUserBanned(userId, isBanned, byUser)
    return function(store)
        local state = store:getState()
        local bannedBy = state.users.banned[userId]

        if isBanned ~= (bannedBy ~= nil) then
            if
                (bannedBy and getAdmin(state, byUser) >= getAdmin(state, bannedBy))
                or (not bannedBy and getAdmin(state, byUser) > getAdmin(state, userId))
            then
                store:dispatch({
                    type = "users_setBanned";
                    payload = {
                        isBanned = isBanned;
                        userId = userId;
                        byUser = byUser;
                    }
                })
            end
        end
    end
end

function actions.userJoined(userId)
    return {
        type = "users_joined";
        payload = {
            userId = userId;
        }
    }
end

function actions.userLeft(userId)
    return {
        type = "users_left";
        payload = {
            userId = userId;
        }
    }
end

function actions.datastoreFetchFailed(userId)
    return {
        type = "users_datastoreFetchFailed";
        payload = {
            userId = userId;
        };
        meta = {
            interestedUserIds = {userId};
        }
    }
end

function actions.saveSettings(userId, settings)
    return {
        type = "users_saveSettings";
        payload = {
            userId = userId;
            settings = settings;
        };
        meta = {
            serverInterested = true;
        }
    }
end

function actions.setLocalSetting(id, value)
    return {
        type = "users_setLocalSetting";
        payload = {
            id = id;
            value = value;
        };
        meta = {
            realm = "client";
        }
    }
end

function actions.flushSaveSettings()
    return function(store)
        local state = store:getState()

        store:dispatch(actions.saveSettings(Players.LocalPlayer and Players.LocalPlayer.UserId or 0, state.users.locallyEditedSettings))

        store:dispatch({
            type = "users_flushSaveSettings";
            payload = {};
            meta = {
                realm = "client";
            }
        })
    end
end

function actions.cancelLocalSettings(settings)
    return {
        type = "users_cancelLocalSettings";
        payload = {
            settings = settings;
        };
        meta = {
            realm = "client";
        }
    }
end

function actions.cancelLocalSetting(id)
    return {
        type = "users_cancelLocalSetting";
        payload = {
            id = id;
        };
        meta = {
            realm = "client";
        }
    }
end;

function actions.restoreDefaultSettings(settings)
    return {
        type = "users_restoreDefaultSettings";
        payload = {
            settings = settings;
        };
        meta = {
            realm = "client";
        }
    }
end

return actions