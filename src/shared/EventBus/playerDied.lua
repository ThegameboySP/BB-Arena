local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Signal = require(ReplicatedStorage.Packages.Signal)
local Effects = require(ReplicatedStorage.Common.Utils.Effects)

return function(EventBus)
    local playerDied = EventBus.playerDied
    local trackingPlayers = {}

    function EventBus:GetPlayerDiedSignal(player)
        if trackingPlayers[player] then
            return trackingPlayers[player]
        end

        trackingPlayers[player] = Signal.new()

        return trackingPlayers[player]
    end

    Players.PlayerRemoving:Connect(function(player)
        if trackingPlayers[player] then
            trackingPlayers[player]:Destroy()
            trackingPlayers[player] = nil
        end
    end)

    Effects.call(Players, Effects.pipe({
        Effects.instance("GetPlayers", "PlayerAdded", "PlayerRemoving"),
        Effects.character,
        function(character)
            local humanoid = character:FindFirstChild("Humanoid")
            
            local con = humanoid.StateChanged:Connect(function(_, new)
                if new == Enum.HumanoidStateType.Dead then
                    local creatorValue = humanoid:WaitForChild("creator", 0.1)
                    local creator = creatorValue and creatorValue.Value

                    local player = Players:GetPlayerFromCharacter(character)
                    if trackingPlayers[player] then
                        trackingPlayers[player]:Fire(creator)
                    end

                    playerDied:Fire(player, creator)
                end
            end)

            return function()
                con:Disconnect()
            end
        end
    }))
end