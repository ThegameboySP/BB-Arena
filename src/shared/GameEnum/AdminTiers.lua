local ReplicatedStorage = game:GetService("ReplicatedStorage")
local makeEnum = require(ReplicatedStorage.Common.Utils.makeEnum)

return makeEnum("AdminTiers", {
	None = 0,
	Admin = 1,
	Owner = 2,
})
