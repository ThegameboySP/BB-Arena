local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local RemoteEvent = {}
RemoteEvent.__index = RemoteEvent

local IsServer = RunService:IsServer()

function RemoteEvent.new(remoteEvent)
	return setmetatable({
		remoteEvent = remoteEvent,
	}, RemoteEvent)
end

function RemoteEvent:Destroy()
	self.remoteEvent:Destroy()
end

function RemoteEvent:Connect(callback)
	if IsServer then
		return self.remoteEvent.OnServerEvent:Connect(callback)
	else
		return self.remoteEvent.OnClientEvent:Connect(callback)
	end
end

function RemoteEvent:FireFilter(filter, ...)
	for _, player in ipairs(Players:GetPlayers()) do
		if filter(player) then
			self.remoteEvent:FireClient(player, ...)
		end
	end
end

function RemoteEvent:FireExcept(filteredPlayer, ...)
	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= filteredPlayer then
			self.remoteEvent:FireClient(player, ...)
		end
	end
end

function RemoteEvent:FireClient(client, ...)
	self.remoteEvent:FireClient(client, ...)
end

function RemoteEvent:FireAllClients(...)
	self.remoteEvent:FireAllClients(...)
end

function RemoteEvent:FireServer(...)
	self.remoteEvent:FireServer(...)
end

return RemoteEvent
