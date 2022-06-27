return function(context, players)
    local StatService = context:GetStore("Common").Knit.GetService("StatService")

    local registeredStats = StatService:GetRegisteredStats()
    local stats = StatService.Stats

    for statName in pairs(registeredStats) do
        for _, player in pairs(players) do
            local userId = player.UserId
            local default = registeredStats[statName].default
            StatService.Stats:Set(userId, statName, default)

            context:Reply(
                string.format("%s %q %s -> %s",
                tostring(player),
                statName,
                tostring(stats:GetUserStat(userId, statName)),
                tostring(default))
            )
        end
    end

    return ""
end