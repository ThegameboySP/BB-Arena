local function mapStatNames(stats)
    local names = {}

    for name in pairs(stats) do
        table.insert(names, name)
    end

    return names
end

return function(context, players, name, value)
    local root = context:GetStore("Common").Root
    local StatService = root:GetService("StatService")

    local statNames = mapStatNames(StatService:GetRegisteredStats())
    local fuzzyFinder = context.Cmdr.Util.MakeFuzzyFinder(statNames)
    local results = fuzzyFinder(name)

    if results[1] then
        for _, player in pairs(players) do
            local userId = player.UserId
            local oldValue = root.Store:getState().stats.visualStats[player.UserId][results[1]]
            StatService:SetStatVisual(userId, results[1], value)

            context:Reply(string.format("%s %q %s -> %s", tostring(player), results[1], tostring(oldValue), tostring(value)))
        end

        return ""
    end
    
    return string.format("%q is not a valid stat name", name)
end