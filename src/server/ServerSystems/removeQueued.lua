local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameEnum = require(ReplicatedStorage.Common.GameEnum)
local MatterComponents = require(ReplicatedStorage.Common.MatterComponents)

local function removeQueued(root)
	for id in root.world:query(MatterComponents.QueuedForRemoval) do
		root.world:despawn(id)
	end
end

return {
	event = "PostSimulation",
	priority = GameEnum.SystemPriorities.CoreAfter,
	system = removeQueued,
}
