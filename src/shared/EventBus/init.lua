local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Signal = require(ReplicatedStorage.Packages.Signal)

local EventBus = {}

for _, module in pairs(script:GetChildren()) do
    local handler = require(module)
    local signal = Signal.new()
    handler(signal)
    EventBus[module.Name] = signal
end

return EventBus