local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local EventBus = require(ReplicatedStorage.Common.EventBus)

local function getDistance(char1, char2)
    local pPart1 = char1.PrimaryPart
    local pPart2 = char2.PrimaryPart

    return if (pPart1 and pPart2) then (pPart1.Position - pPart2.Position).Magnitude else nil
end

local function killfeedServer(root)
    local remote = root:getRemoteEvent("Killfeed")
    local componentManager = root:GetService("MapService").ClonerManager.Manager

    EventBus.participantDied:Connect(function(participant, attacker, creatorValue)
        local character = participant.Character
        local participantHumanoid = character:FindFirstChild("Humanoid")
        if not participantHumanoid then
            return
        end
        
        local flag = character:FindFirstChild("Flag")
        local flagTeam = nil
        if flag then
            flagTeam = componentManager:GetComponent(flag, "CTF_Flag").State.Team
        end
        
        local attackingCharacter = attacker and attacker.Character
        
        local data = {}

        if attackingCharacter and CollectionService:HasTag(attacker, "ParticipatingPlayer") then
            local weapon = creatorValue:GetAttribute("WeaponImageId")

            if attacker == participant then
                data = {
                    Type = "SK",
                    Weapon = weapon,
                }
            else
                data = {
                    Type = "Kill",
                    Killer = attacker,
                    DeadPing = participant:GetNetworkPing(),
                    KillerPing = attacker:GetNetworkPing(),
                    Distance = getDistance(character, attackingCharacter),
                    Weapon = weapon,
                }
            end
        else
            data = {
                Type = "Died",
            }
        end
        
        if flag then
            data.FlagTeam = flagTeam
        end

        data.Dead = participant

        remote:FireAllClients(data)
    end)
end

return killfeedServer