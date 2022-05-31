local CollectionService = game:GetService("CollectionService")

return function(signals)
    local fighterDied = signals.fighterDied

    signals.playerDied:Connect(function(player, killer)
        if CollectionService:HasTag(player, "FightingPlayer") then
            fighterDied:Fire(player, killer)
        end
    end)
end