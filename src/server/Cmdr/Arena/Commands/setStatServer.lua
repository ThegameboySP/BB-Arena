local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RoduxFeatures = require(ReplicatedStorage.Common.RoduxFeatures)

local function getStatFromFriendlyName(stats, friendlyName)
	for _, stat in stats.registeredStats do
		if stat.friendlyName == friendlyName and stats.visibleRegisteredStats[stat.name] then
			return stat
		end
	end
end

return function(context, players, friendlyName, value)
    local store = context:GetStore("Common").Root.Store
    local stat = getStatFromFriendlyName(store:getState().stats, friendlyName)
        or error("No stat by friendly name: " .. friendlyName)

    local realName = stat.name

    for _, player in players do
        local userId = player.UserId
        local oldValue = store:getState().stats.visualStats[player.UserId][realName]
        store:dispatch(RoduxFeatures.actions.setStatVisual(userId, realName, value))

        context:Reply(string.format("%s %q %s -> %s", tostring(player), realName, tostring(oldValue), tostring(value)))
    end

    return ""
end