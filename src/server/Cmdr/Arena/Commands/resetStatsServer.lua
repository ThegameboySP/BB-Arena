local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RoduxFeatures = require(ReplicatedStorage.Common.RoduxFeatures)

return function(context, players)
	local root = context:GetStore("Common").Root

	local userIds = {}
	for _, player in players do
		table.insert(userIds, player.UserId)
	end

	root.Store:dispatch(RoduxFeatures.actions.resetUsersStats(userIds))
end
