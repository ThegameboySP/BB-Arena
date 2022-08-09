local CollectionService = game:GetService("CollectionService")

return function(signals)
    local participantDied = signals.participantDied

    signals.playerDied:Connect(function(player, killer)
        local team = player.Team
        if team and CollectionService:HasTag(team, "ParticipatingTeam") then
            participantDied:Fire(player, killer)
        end
    end)
end