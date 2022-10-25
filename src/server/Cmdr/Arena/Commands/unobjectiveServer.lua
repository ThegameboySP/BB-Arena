local Players = game:GetService("Players")

return function (context)
	local objectiveCon = context:GetStore("ObjectiveCon")
	if objectiveCon.con then
		objectiveCon.con:Disconnect()
	end
	
	for _, player in Players:GetPlayers() do
		player:SetAttribute("Objective", nil)
	end

	context:BroadcastEvent("Unobjective")
end