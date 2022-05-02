local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameEnum = require(ReplicatedStorage.Common.GameEnum)

local IS_STUDIO = game:GetService("RunService"):IsStudio()

return function(admins, player, group)
	if player == nil then
        return true
    end

    -- 0 = unknown player, -1 = player1, -2 = player2, etc
	local userId = player.UserId
	if userId <= 0 then
        return true
    end

	local playerAdmin = admins[player.UserId] or 0

	if group == "Any" or group == "Help" or group == "DefaultUtil" or group == "UserAlias" or group == "Utility" then
		return true
	end

	if group == "Studio" then
		return IS_STUDIO
	end

	if group == "Recorders" then
		return (not not player:GetAttribute("IsRecorder")) or playerAdmin >= GameEnum.AdminTiers.Owner
	elseif group == "Referee" then
		return (not not player:GetAttribute("IsReferee")) or playerAdmin >= GameEnum.AdminTiers.Owner
	end

	local requiredAdmin = 0
	if group == "Admin" or group == "DefaultAdmin" then
		requiredAdmin = GameEnum.AdminTiers.Admin
	elseif group == "Owner" or group == "DefaultDebug" then
		requiredAdmin = GameEnum.AdminTiers.Owner
	end

	return playerAdmin >= requiredAdmin
end