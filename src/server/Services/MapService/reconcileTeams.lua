local function count(t)
    local c = 0
    for _ in t do
        c += 1
    end

    return c
end

local function reconcileTeams(players, newTeamNameToColor, oldTeamsMap)
    local reconciledTeams = {}
    local newTeamsMap = {}
    local playersToFill = table.clone(players)

    for name, color in newTeamNameToColor do
        newTeamsMap[name] = { color = color, players = {}, name = name }
    end

    local newTeamsKey = nil
    for name in oldTeamsMap do
        local teamsKey, newTeam = next(newTeamsMap, newTeamsKey)
        if newTeam == nil then
            break
        end

        newTeamsKey = teamsKey
        reconciledTeams[name] = newTeam
    end

    local newTeamsLength = count(newTeamsMap)
    local oldTeamsLength = count(oldTeamsMap)

    if newTeamsLength == 0 then
        return reconciledTeams, newTeamsMap, playersToFill

    elseif oldTeamsLength == newTeamsLength then
        for oldTeamName, newTeam in reconciledTeams do
            newTeam.players = oldTeamsMap[oldTeamName].players
        end

    else
        while #playersToFill > 0 do
            for _, team in newTeamsMap do
                table.insert(team.players, table.remove(playersToFill, #playersToFill))
            end
        end
    end

    return reconciledTeams, newTeamsMap, {}
end

return reconcileTeams