local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameEnum = require(ReplicatedStorage.Common.GameEnum)

return function(context, players)
	local root = context:GetStore("Common").Root
	for _, player in players do
		root:KillCharacter(player.Character, GameEnum.DeathCause.Admin)
	end
end
