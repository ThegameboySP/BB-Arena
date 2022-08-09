local TextService = game:GetService("TextService")
local Players = game:GetService("Players")

return function (context, text)
	local filterResult = TextService:FilterStringAsync(text, context.Executor.UserId, Enum.TextFilterContext.PublicChat)
	
	for _, player in ipairs(Players:GetPlayers()) do
		context:SendEvent(player, "Hint", filterResult:GetChatForUserAsync(player.UserId), context.Executor)
	end
end