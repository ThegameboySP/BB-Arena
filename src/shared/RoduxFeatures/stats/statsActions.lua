local function setStatVisual(userId, name, value)
    return {
        type = "stats_setVisual";
        payload = {
            userId = userId;
            name = name;
            value = value;
        };
    }
end

local function incrementStatRaw(userId, name, amount)
    return {
        type = "stats_increment";
        payload = {
            userId = userId;
            name = name;
            amount = amount;
        };
    }
end

local function incrementStat(userId, name, amount)
    return function(store)
        local state = store:getState()
        local isVisible = state.stats.visibleRegisteredStats[name]

        local action = incrementStatRaw(userId, name, amount)
        action.meta = {
            interestedUserIds = if isVisible then nil else {};
        }
        
        store:dispatch(action)
    end
end

local function resetUsersStats(userIds)
    return {
        type = "stats_resetUsers";
        payload = {
            userIds = userIds;
        };
    }
end

return {
    setStatVisual = setStatVisual;
    incrementStatRaw = incrementStatRaw;
    incrementStat = incrementStat;
    resetUsersStats = resetUsersStats;
}