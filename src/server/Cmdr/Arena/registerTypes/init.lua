return function(registry, mapInfo)
    for _, child in script:GetChildren() do
        require(child)(registry, mapInfo)
    end

    registry.Types.player = registry.Types.arenaPlayer
	registry.Types.players = registry.Types.arenaPlayers

    registry.Types.playerId = registry.Types.arenaPlayerId
    registry.Types.playerIds = registry.Types.arenaPlayerIds
end