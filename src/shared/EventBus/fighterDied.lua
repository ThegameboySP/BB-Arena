local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

local Effects = require(ReplicatedStorage.Common.Utils.Effects)

return function(signal)
    Effects.call(CollectionService, Effects.pipe({
        Effects.getFromTag("FightingTeam"),
        Effects.instance("GetPlayers", "PlayerAdded", "PlayerRemoved"),
        Effects.character,
        function(character)
            local humanoid = character:FindFirstChild("Humanoid")
            
            local con = humanoid.StateChanged:Connect(function(_, new)
                if new == Enum.HumanoidStateType.Dead then
                    local creatorValue = humanoid:WaitForChild("creator", 0.1)
                    local creator = creatorValue and creatorValue.Value

                    signal:Fire(Players:GetPlayerFromCharacter(character), creator)
                end
            end)

            return function()
                con:Disconnect()
            end
        end
    }))
end