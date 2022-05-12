return function(context, players)
    local StatService = context:GetStore("Common").Knit.GetService("StatService")

    local registeredStats = StatService:GetRegisteredStats()

    for statName, users in pairs(StatService:GetStats()) do
        for _, player in pairs(players) do
            local userId = player.UserId
            local default = registeredStats[statName].default
            StatService:SetStat(userId, statName, default)
            context:Reply(string.format("%s %q %s -> %s", tostring(player), statName, tostring(users[userId]), tostring(default)))
        end
    end

    return ""
end