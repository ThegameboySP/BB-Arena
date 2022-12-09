local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RoduxFeatures = require(ReplicatedStorage.Common.RoduxFeatures)
local getFullPlayerName = require(ReplicatedStorage.Common.Utils.getFullPlayerName)
local actions = RoduxFeatures.actions

return function(context, players, admin)
	local store = context:GetStore("Common").Store

	for _, player in pairs(players) do
		local state = store:getState()
		store:dispatch(actions.setAdmin(player.UserId, admin))

		if store:getState() ~= state then
			context:Reply(string.format("Successfully admined %s", getFullPlayerName(player)))
		end
	end

	return ""
end
