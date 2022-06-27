local function updateStats(oldStats, mergeWith)
    oldStats = oldStats or {}

    local newStats = table.clone(oldStats)

    for name, usersData in pairs(mergeWith) do
        local oldUsersData = oldStats[name] or {}
        local newUsersData = table.clone(oldUsersData)
        newStats[name] = newUsersData

        for userId, value in pairs(usersData) do
            local userIdStr = tostring(userId)

            if type(value) == "number" and type(oldUsersData[userIdStr]) == "number" then
                newUsersData[userIdStr] += value
            else
                newUsersData[userIdStr] = value
            end
        end
    end

    return newStats
end

return updateStats