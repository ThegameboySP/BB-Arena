local CollectionService = game:GetService("CollectionService")

return function(signals)
    local fighterDied = signals.fighterDied

    signals.playerDied:Connect(function(player, killer, creatorValue)
        local team = player.Team
        if team and CollectionService:HasTag(team, "FightingTeam") then
            fighterDied:Fire(player, killer, creatorValue)
        end
    end)
end