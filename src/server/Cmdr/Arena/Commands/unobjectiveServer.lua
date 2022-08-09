return function (context)
	local objectiveCon = context:GetStore("ObjectiveCon")
	if objectiveCon.con then
		objectiveCon.con:Disconnect()
	end
	
	context:BroadcastEvent("Unobjective")
end