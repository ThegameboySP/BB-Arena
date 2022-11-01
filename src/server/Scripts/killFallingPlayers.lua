local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local GameEnum = require(ReplicatedStorage.Common.GameEnum)
local General = require(ReplicatedStorage.Common.Utils.General)

local FallenPartsDestroyHeight = Workspace.FallenPartsDestroyHeight

-- There is a Roblox bug where a player can ride a fallen part down to the void, then
-- snap back up once it's destroyed. This is a patch around that.
local function killFallingPlayers(root)
    local part = Instance.new("Part")
    part.CFrame = CFrame.new(0, FallenPartsDestroyHeight + 50, 0)
    part.Size = Vector3.new(2048, 1, 2048)
    part.Anchored = true
    part.Name = "Void"
    part.CanCollide = false
    part.Transparency = 1
    part.Parent = Workspace

    part.Touched:Connect(function(hit)
        local character = General.getCharacter(hit)

        if character then
            root:KillCharacter(character, GameEnum.DeathCause.Void)
        end
    end)
end

return killFallingPlayers