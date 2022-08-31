local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameEnum = require(ReplicatedStorage.Common.GameEnum)

local usersSelectors = require(script.Parent.usersSelectors)
local getAdmin = usersSelectors.getAdmin

local function setAdmin(userId, admin, byUser)
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

local function setReferee(userId, isReferee, byUser)
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

local function setUserWhitelisted(userId, byUser, isWhitelisted)
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

local function setServerLocked(lockingUserId, isLocked)
    return function(store)
        local state = store:getState()

        if
            isLocked ~= (not not state.users.serverLockedBy)
            and getAdmin(state, lockingUserId) >= getAdmin(state, state.users.serverLockedBy)
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
                    store:dispatch(setUserWhitelisted(userId, lockingUserId, true))
                end
            end
        end
    end
end

local function setUserBanned(userId, byUser, isBanned)
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

local function userJoined(userId)
    return {
        type = "users_joined";
        payload = {
            userId = userId;
        }
    }
end

local function userLeft(userId)
    return {
        type = "users_left";
        payload = {
            userId = userId;
        }
    }
end

local function saveSettings(userId, settings)
    return {
        type = "users_saveSettings";
        payload = {
            userId = userId;
            settings = settings;
        };
        meta = {
            serverRemote = {"SaveSettings", settings};
            interestedUserIds = {userId};
        }
    }
end

local function setLocalSetting(userId, id, value)
    return {
        type = "users_setLocalSetting";
        payload = {
            userId = userId;
            id = id;
            value = value;
        };
        meta = {
            realm = "client";
        }
    }
end

local function flushSaveSettings(userId)
    return function(store)
        local state = store:getState()

        store:dispatch(saveSettings(userId, state.users.locallyEditedSettings))

        store:dispatch({
            type = "users_flushSaveSettings";
            payload = {};
            meta = {
                realm = "client";
            }
        })
    end
end

return {
    setAdmin = setAdmin;
    setReferee = setReferee;
    setServerLocked = setServerLocked;
    setUserBanned = setUserBanned;
    setUserWhitelisted = setUserWhitelisted;
    userJoined = userJoined;
    userLeft = userLeft;
    
    saveSettings = saveSettings;
    setLocalSetting = setLocalSetting;
    flushSaveSettings = flushSaveSettings;
}