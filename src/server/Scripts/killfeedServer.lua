local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local EventBus = require(ReplicatedStorage.Common.EventBus)

local function getDistance(char1, char2)
	local pPart1 = char1.PrimaryPart
	local pPart2 = char2.PrimaryPart

	return if pPart1 and pPart2 then (pPart1.Position - pPart2.Position).Magnitude else 0
end

local function killfeedServer(root)
	local remote = root:getRemoteEvent("Killfeed")
	local componentManager = root:GetService("MapService").ClonerManager.Manager

	EventBus.participantDied:Connect(function(participant, info)
		local character = participant.Character
		local flag = character:FindFirstChild("Flag")

		local flagTeam = nil
		if flag then
			flagTeam = componentManager:GetComponent(flag, "CTF_Flag").State.Team
		end

		local attackingCharacter = info.killer and info.killer.Character

		local data = {}

		if attackingCharacter and CollectionService:HasTag(info.killer, "ParticipatingPlayer") then
			local weapon = info.weaponImageId

			if info.killer == participant then
				data = {
					Type = "SK",
					Weapon = weapon,
				}
			else
				data = {
					Type = "Kill",
					Killer = info.killer,
					DeadPing = participant:GetNetworkPing() * 2,
					KillerPing = info.killer:GetNetworkPing() * 2,
					Distance = getDistance(character, attackingCharacter),
					Weapon = weapon,
				}
			end
		else
			data = {
				Type = "Died",
				DeathCause = info.cause,
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
