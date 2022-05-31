local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Signal = require(ReplicatedStorage.Packages.Signal)

local EventBus = {}

local children = script:GetChildren()
for _, module in children do
    EventBus[module.Name] = Signal.new()
end

for _, module in pairs(script:GetChildren()) do
    local handler = require(module)
    handler(EventBus)
end

return EventBus