local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Signal = require(ReplicatedStorage.Packages.Signal)

local legacyNameMap = {
	RenderStepped = "PreRender",
	Stepped = "PreSimulation",
	Heartbeat = "PostSimulation",
}

local signalOrder = { "PreRender", "PreSimulation", "PostSimulation" }

return {
	bindSignals = function(middleware)
		local signals = {
			RenderStepped = Signal.new(),
			Stepped = Signal.new(),
			Heartbeat = Signal.new(),
		}

		for name, signal in signals do
			if name == "RenderStepped" and RunService:IsServer() then
				continue
			end

			RunService[name]:Connect(middleware(function()
				signal:Fire()
			end, legacyNameMap[name]))
		end

		return {
			PreRender = signals.RenderStepped,
			PreSimulation = signals.Stepped,
			PostSimulation = signals.Heartbeat,
		}
	end,
	testBindSignals = function(isServer)
		local middlewareBySignalName = {}

		return function(middleware)
			local signals = {
				PreRender = Signal.new(),
				PreSimulation = Signal.new(),
				PostSimulation = Signal.new(),
			}

			for name, signal in signals do
				middlewareBySignalName[name] = middleware(function()
					signal:Fire()
				end, name)
			end

			return signals
		end, function()
			for _, name in signalOrder do
				if name ~= "PreRender" or not isServer then
					middlewareBySignalName[name]()
				end
			end
		end
	end,
}
