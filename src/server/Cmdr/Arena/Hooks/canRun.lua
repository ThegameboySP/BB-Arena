local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local GameEnum = require(ReplicatedStorage.Common.GameEnum)

local IS_STUDIO = RunService:IsStudio()

local anyGroups = table.freeze({
	Any = true;
	Help = true;
	DefaultUtil = true;
	UserAlias = true;
	Utility = true;
})

local function canRun(admins, userId, group)
	if userId == nil then
        return true
    end

	if anyGroups[group] then
		return true
	end

	if group == "Studio" then
		return IS_STUDIO
	end

	local requiredAdmin = 0
	if group == "Admin" or group == "DefaultAdmin" then
		requiredAdmin = GameEnum.AdminTiers.Admin
	elseif group == "Owner" or group == "DefaultDebug" then
		requiredAdmin = GameEnum.AdminTiers.Owner
	end

	local playerAdmin = admins[userId] or 0

	return playerAdmin >= requiredAdmin
end

return {
	canRun = canRun;
	anyGroups = anyGroups;
}