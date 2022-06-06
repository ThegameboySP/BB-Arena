local ReplicatedStorage = game:GetService("ReplicatedStorage")

local getFullPlayerName = require(ReplicatedStorage.Common.Utils.getFullPlayerName)

return function(context, players, teams, shouldSpawn)
    local teamIndex = 0

    while #players > 0 do
        teamIndex = teamIndex % #teams + 1
        local team = teams[teamIndex]

        local player = table.remove(players, #players)
        player.Team = team

        if shouldSpawn then
            task.spawn(player.LoadCharacter, player)
        end

        context:Reply(string.format("Teamed %s to %s team", getFullPlayerName(player), team.Name))
    end

    return ""
end