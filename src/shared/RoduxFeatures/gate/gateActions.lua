local function lockServer(lockingUserId)
    return function(store)
        local state = store:getState()
        store:dispatch({
            type = "gate_lockServer";
            payload = {
                userId = lockingUserId;
            }
        })

        for userId in pairs(state.users.connectedIds) do
            store:dispatch(Actions.whitelistUser(userId))
        end
    end
end

local function banUser(userId, banningUserId)
    return {
        type = "gate_userBanned";
        payload = {
            userId = userId;
            banningUserId = banningUserId;
        }
    }
end

local function unbanUser(userId)
    return {
        type = "gate_userUnbanned";
        payload = {
            userId = userId;
        }
    }
end

return {
    lockServer = lockServer;
    banUser = banUser;
}