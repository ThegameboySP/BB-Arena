local TextService = game:GetService("TextService")
local Players = game:GetService("Players")

return function (context, text)
	local objectiveCon = context:GetStore("ObjectiveCon")
	if objectiveCon.con then
		objectiveCon.con:Disconnect()
	end
	
	local filterResult = TextService:FilterStringAsync(text, context.Executor.UserId, Enum.TextFilterContext.PublicChat)
	local function onPlayerAdded(player)
		context:SendEvent(player, "Objective", filterResult:GetChatForUserAsync(player.UserId), context.Executor)
	end
	
	for _, player in Players:GetPlayers() do
		onPlayerAdded(player)
	end
	objectiveCon.con = Players.PlayerAdded:Connect(onPlayerAdded)
	
	return "Created objective!"
end