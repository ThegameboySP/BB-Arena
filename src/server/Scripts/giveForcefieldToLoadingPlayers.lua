local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Effects = require(ReplicatedStorage.Common.Utils.Effects)

local function giveForcefieldToLoadingPlayers()
    Effects.call(CollectionService, Effects.pipe({
        Effects.getFromTag("PlayerStreamingMap"),
        Effects.character,
        function(character)
            local ff = Instance.new("ForceField")
            CollectionService:AddTag(ff, "StreamingMapForcefield")
            ff.Parent = character

            return function()
                ff.Parent = nil
            end
        end
    }))
end

return giveForcefieldToLoadingPlayers