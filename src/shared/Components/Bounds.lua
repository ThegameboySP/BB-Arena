local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

local Signal = require(ReplicatedStorage.Packages.Signal)
local Component = require(ReplicatedStorage.Common.Component).Component

local Bounds = Component:extend("Bounds")

local function isPointIntersecting(v, min, max)
	return (v.X >= min.X and v.X <= max.X)
		and (v.Y >= min.Y and v.Y <= max.Y)
		and (v.Z >= min.Z and v.Z <= max.Z)
end

function Bounds:OnInit()
    self.CharacterAdded = Signal.new()
    self.CharacterRemoved = Signal.new()
    self.overlappingCharacters = {}
end

function Bounds:OnDestroy()
    self.CharacterAdded:Destroy()
    self.CharacterRemoved:Destroy()
    self.connection:Disconnect()
end

function Bounds:OnStart()
	local parts = {}
    local descendants = self.Instance:GetDescendants()
    table.insert(descendants, self.Instance)

    for _, descendant in descendants do
        if descendant:IsA("BasePart") then
            table.insert(parts, descendant)
        end
    end
	
    self.connection = RunService.Heartbeat:Connect(function()
        local characters = {}

        for _, player in pairs(CollectionService:GetTagged("FightingPlayer")) do
            local character = player.Character
            if character and character.PrimaryPart then
                table.insert(characters, character)
            end
        end

        local added = {}
        for _, part in pairs(parts) do
            local min = part.CFrame:PointToWorldSpace(-part.Size/2)
            local max = part.CFrame:PointToWorldSpace(part.Size/2)

            for _, character in pairs(characters) do
                if isPointIntersecting(character.PrimaryPart.Position, min, max) then
                    added[character] = true
                end
            end
        end

        for character in pairs(added) do
            if not self.overlappingCharacters[character] then
                self.overlappingCharacters[character] = true
                self.CharacterAdded:Fire(character)
            end
        end

        for character in pairs(self.overlappingCharacters) do
            if not added[character] then
                self.overlappingCharacters[character] = nil
                self.CharacterRemoved:Fire(character)
            end
        end
    end)
end

return Bounds