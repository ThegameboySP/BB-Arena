local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CmdrUtils = require(ReplicatedStorage.Common.Utils.CmdrUtils)

return function(context, key, value)
    local GamemodeService = context:GetStore("Common").Knit.GetService("GamemodeService")
    GamemodeService:FireGamemodeEvent(key, CmdrUtils.transformType(value))

    return "Fired " .. key
end