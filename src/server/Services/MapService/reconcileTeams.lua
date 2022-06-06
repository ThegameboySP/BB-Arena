local function reconcileTeams(players, newTeamNameToColor, oldTeamsMap)
    local reconciledTeams = {}
    local newTeamsMap = {}
    local playersToFill = table.clone(players)

    local newTeamsLength = 0
    for name, color in newTeamNameToColor do
        local newTeam = {color = color, players = {}, name = name}
        newTeamsMap[name] = newTeam
        newTeamsLength += 1
    end

    local oldTeamsLength = 0
    local newTeamsKey = nil
    for name in oldTeamsMap do
        local teamsKey, newTeam = next(newTeamsMap, newTeamsKey)
        newTeamsKey = teamsKey

        reconciledTeams[name] = newTeam
        oldTeamsLength += 1
    end

    if newTeamsLength == 0 then
        return reconciledTeams, newTeamsMap, playersToFill

    elseif newTeamsLength > oldTeamsLength or oldTeamsLength > newTeamsLength then
        local teamKey = nil
        
        while #playersToFill > 0 do
            if not next(newTeamsMap, teamKey) then
                teamKey = nil
            end

            local key, team = next(newTeamsMap, teamKey)
            teamKey = key
            table.insert(team.players, table.remove(playersToFill, #playersToFill))
        end

    elseif oldTeamsLength == newTeamsLength then
        for oldTeamName, newTeam in reconciledTeams do
            newTeam.players = oldTeamsMap[oldTeamName].players
        end
    end

    return reconciledTeams, newTeamsMap, {}
end

return reconcileTeams