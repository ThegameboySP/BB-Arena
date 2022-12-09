local ReplicatedStorage = game:GetService("ReplicatedStorage")
local makeEnum = require(ReplicatedStorage.Common.Utils.makeEnum)

return makeEnum("DeathCause", {
	Admin = 0,
	Lava = 1,
	Void = 2,
	Kill = 3,
})
