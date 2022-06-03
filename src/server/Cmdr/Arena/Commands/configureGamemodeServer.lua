local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CmdrUtils = require(ReplicatedStorage.Common.Utils.CmdrUtils)

return function(context, key, value)
    local GamemodeService = context:GetStore("Common").Knit.GetService("GamemodeService")

    local resolvedValue = CmdrUtils.transformType(value)

    if GamemodeService.CurrentGamemode.definition.config[key] then
        GamemodeService:SetConfig({[key] = resolvedValue})

        return string.format("Set %s to %s", key, tostring(value))
    else
        GamemodeService:FireGamemodeEvent(key, resolvedValue)

        return "Fired " .. key
    end
end