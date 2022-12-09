local ReplicatedStorage = game:GetService("ReplicatedStorage")
local getFullPlayerName = require(ReplicatedStorage.Common.Utils.getFullPlayerName)

local LOG_FORMAT = "%s: '%s %s' -> '%s'"

return function(context, filterPlayer)
	local CmdrService = context:GetStore("Common").Root:GetService("CmdrService")
	local logs = CmdrService:GetLogs()

	local filterName
	if filterPlayer == "Instance" then
		filterName = getFullPlayerName(filterPlayer)
	end

	for _, log in ipairs(logs) do
		if filterPlayer == nil or log.ExecutorName == filterName then
			context:Reply(
				LOG_FORMAT:format(log.ExecutorName, log.Name, log.ArgumentsText, log.Response or "Command executed.")
			)
		end
	end

	return ""
end
