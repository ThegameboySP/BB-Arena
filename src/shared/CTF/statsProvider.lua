local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")

--[[
    (events later dispatch Rodux actions)

    gets captures along w/ stats:
        - distance traveled w/ flag
        - deaths w/ flag
        - kills w/ flag
        - kills w/ enemy w/ a flag
]]

local function getFlag(character)
    return character:FindFirstChild("Flag")
end

local Provider = {}
Provider.__index = Provider

function Provider.new(queue)
    return setmetatable({
        queue = queue;
        characterLastPositions = {};
    })
end

function Provider:step()
    local characters = CollectionService:GetTagged("FightingCharacter")

    for _, character in pairs(characters) do
        local currentPos = character.Head.Position
        local lastPos = self.characterLastPositions[character]
        
        if lastPos then
            table.insert(self.queue, {
                type = "CTF_MovedWithFlag";
                distance = (lastPos - currentPos).Magnitude
            })
        end

        self.characterLastPositions[character] = currentPos
    end
end

function Provider:init(flagStands, signals)
    local connections = {}

    for _, flagStand in pairs(flagStands) do
        table.insert(connections, flagStand.Touched:Connect(function(hit)
            local character = hit.Parent
            if not character:FindFirstChild("Humanoid") then
                continue
            end

            if CollectionService:HasTag(character, "FightingCharacter") then
                continue
            end

            local flag = getFlag(character)
            if not flag then
                continue
            end

            table.insert(self.queue, {
                type = "CTF_FlagCapture";
                player = Players:GetPlayerFromCharacter(character);
                flag = flag;
            })
        end))
    end

    table.insert(connections, signals.Death:Connect(function(death)
        if death.killRecord then
            if getFlag(death.victim) then
                table.insert(self.queue, {type = "CTF_EnemyKilledWithFlag", deathRecord = death})
            end

            if death.victim ~= death.killRecord.killer and getFlag(death.killRecord.killer) then
                table.insert(self.queue, {type = "CTF_KillsWithFlag", deathRecord = death})
            end
        end
    end))

    table.insert(connections, CollectionService:GetInstanceRemovedSignal("FightingCharacter"):Connect(function(character)
        self.characterLastPositions[character] = nil
    end))

    return connections
end

return Provider