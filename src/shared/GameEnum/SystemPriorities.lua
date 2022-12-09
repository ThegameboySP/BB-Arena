local ReplicatedStorage = game:GetService("ReplicatedStorage")
local makeEnum = require(ReplicatedStorage.Common.Utils.makeEnum)

return makeEnum("SystemPriorities", {
	RemoteBefore = 0,
	CoreBefore = 10,

	Service = 20,
	Gamemode = 30,

	CoreAfter = 90,
	RemoteAfter = 100,
})
