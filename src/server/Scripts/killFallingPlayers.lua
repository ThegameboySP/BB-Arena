local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

local GameEnum = require(ReplicatedStorage.Common.GameEnum)
local General = require(ReplicatedStorage.Common.Utils.General)

local PLAYER_DIE_BUFFER = 50
local PART_BUFFER = 800
local PART_COUNT = 4

-- There is a Roblox bug where a player can ride a fallen part down to the void, then
-- snap back up once it's destroyed. This is a patch around that.
local function killFallingPlayers(root)
    local void = Instance.new("Model")
    void.Name = "Void"

    local pPart = Instance.new("Part")
    pPart.Anchored = true
    pPart.CanCollide = false
    pPart.CanTouch = false
    pPart.CanQuery = false
    void.PrimaryPart = pPart

    local dieY = -math.huge
    RunService.Heartbeat:Connect(function()
        for _, player in Players:GetPlayers() do
            local character = player.Character
            local head = character and character:FindFirstChild("Head")

            if head and head.Position.Y <= dieY then
                root:KillCharacter(character, GameEnum.DeathCause.Void)
            end
        end
    end)

    for x = 0, PART_COUNT-1 do
        for z = 0, PART_COUNT-1 do
            local part = Instance.new("Part")
            part.Size = Vector3.new(2048, 1, 2048)
            part.CFrame = CFrame.new((x - PART_COUNT/2) * 2048, 0, (z - PART_COUNT/2) * 2048)
            part.Anchored = true
            part.Name = "VoidPart"
            part.CanCollide = false
            part.Transparency = 1
            part.Parent = void
        
            part.Touched:Connect(function(hit)
                if not General.getCharacter(hit) then
                    hit.Parent = nil

                    local model = hit:FindFirstAncestorWhichIsA("Model")
                    while model do
                        if not model:FindFirstChildWhichIsA("BasePart", true) then
                            model.Parent = nil
                        end

                        model = hit:FindFirstAncestorWhichIsA("Model")
                    end
                end
            end)
        end
    end

    local function onMapChanged(map)
        local cframe, size = map:GetBoundingBox()
        dieY = cframe.Position.Y - size.Y/2 - PLAYER_DIE_BUFFER

        void:PivotTo(CFrame.new(0, dieY - PART_BUFFER, 0))
        void.Parent = Workspace
    end

    local MapService = root:GetService("MapService")

    MapService.MapChanged:Connect(onMapChanged)
    if MapService.CurrentMap then
        onMapChanged(MapService.CurrentMap)
    end
end

return killFallingPlayers