local Spectators = game:GetService("Teams").Spectators
local PhysicsService = game:GetService("PhysicsService")

local Effects = require(game:GetService("ReplicatedStorage").Common.Utils.Effects)

Effects.call(Spectators, Effects.pipe({
    Effects.instance("GetPlayers", "PlayerAdded", "PlayerRemoved"),
    Effects.character,

    function(character)
        local parts = {}
        local cancelled = false

        task.defer(function()
            if cancelled then
                return
            end

            for _, descendant in pairs(character:GetDescendants()) do
                if descendant:IsA("BasePart") then
                    PhysicsService:SetPartCollisionGroup(descendant, "Spectators")
                    table.insert(parts, descendant)
                end
            end
        end)
        
        return function ()
            cancelled = true
            for _, part in pairs(parts) do
                PhysicsService:SetPartCollisionGroup(part, "PlayerParts")
            end
        end
    end
}))