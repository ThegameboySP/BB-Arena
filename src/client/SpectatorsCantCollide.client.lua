local Spectators = game:GetService("Teams").Spectators
local PhysicsService = game:GetService("PhysicsService")
local RunService = game:GetService("RunService")

local Effects = require(game:GetService("ReplicatedStorage").Common.Utils.Effects)

Effects.call(Spectators, Effects.pipe({
    Effects.instance("GetPlayers", "PlayerAdded", "PlayerRemoved"),
    Effects.character,

    function(character)
        local parts = {}
        for _, descendant in pairs(character:GetDescendants()) do
            if descendant:IsA("BasePart") and descendant.CanCollide then
                table.insert(parts, descendant)
            end
        end

        local con = RunService.Heartbeat:Connect(function()
            for _, part in pairs(parts) do
                PhysicsService:SetPartCollisionGroup(part, "Spectators")
            end
        end)
        
        return function ()
            con:Disconnect()

            for _, part in pairs(parts) do
                PhysicsService:SetPartCollisionGroup(part, "PlayerParts")
            end
        end
    end
}))