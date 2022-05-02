return function (context)
    local gatekeeping = context:GetStore("Gatekeeping")

	if gatekeeping.ServerLockConnection then
		gatekeeping.ServerLockConnection:Disconnect()
		gatekeeping.ServerLockConnection = nil
		return "Unlocked server!"
	end
	
	return "Server isn't locked!"
end