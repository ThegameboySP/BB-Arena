local function mapStatNames(stats)
    local names = {}

    for name in pairs(stats) do
        table.insert(names, name)
    end

    return names
end

return function(context, players, name, value)
    local StatService = context:GetStore("Common").Knit.GetService("StatService")

    local statNames = mapStatNames(StatService:GetRegisteredStats())
    local fuzzyFinder = context.Cmdr.Util.MakeFuzzyFinder(statNames)
    local results = fuzzyFinder(name)

    if results[1] then
        for _, player in pairs(players) do
            local userId = player.UserId
            local oldValue = StatService.Stats:GetUserStat(results[1], userId)
            StatService.Stats:Set(userId, results[1], value)

            context:Reply(string.format("%s %q %s -> %s", tostring(player), results[1], tostring(oldValue), tostring(value)))
        end

        return ""
    end
    
    return string.format("%q is not a valid stat name", name)
end