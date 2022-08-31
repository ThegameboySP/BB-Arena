local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CmdrUtils = require(ReplicatedStorage.Common.Utils.CmdrUtils)

return function(registry)
    local type = CmdrUtils.constrainedNumber(0, 1)
    type.DisplayName = "% Percentage"

	registry:RegisterType("percentage", type)
end