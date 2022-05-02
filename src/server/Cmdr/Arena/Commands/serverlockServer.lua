local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LOCKED_MESSAGE = "The server is locked!"

return function (context)
	local gatekeeping = context:GetStore("Gatekeeping")

	if gatekeeping.ServerLockConnection == nil then
		gatekeeping.ServerLockConnection = Players.PlayerAdded:Connect(function(player)
			-- TODO
			RunService.Heartbeat:Wait()
			if (player:GetAttribute("AdminIndex") or 0) >= 1 then return end
			player:Kick(LOCKED_MESSAGE)
		end)

        return "Locked server!"
	end

	return "Server already locked!"
end