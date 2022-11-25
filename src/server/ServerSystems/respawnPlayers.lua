local ReplicatedStorage = game:GetService("ReplicatedStorage")
-- local Teams = game:GetService("Teams")

local GameEnum = require(ReplicatedStorage.Common.GameEnum)
local MatterComponents = require(ReplicatedStorage.Common.MatterComponents)

-- local TEAM_COLOR = Teams.Gladiators.TeamColor

-- local function getSpawnPositions(map)
-- 	local spawnPositions = {}
-- 	for _, item in map:GetDescendants() do
-- 		if item:IsA("SpawnLocation") and item.Enabled and item.TeamColor == TEAM_COLOR then
-- 			table.insert(spawnPositions, item)
-- 		end
-- 	end

-- 	return spawnPositions
-- end

-- local function respawnPlayers(root)
-- 	local lastSpawnPositions = {}
-- 	local usedSpawnPositions = {}
-- 	local index = 0
-- 	local lastMap
-- 	local function getCycledSpawnPosition()
-- 		local map = MapService.CurrentMap
-- 		if map == nil then
-- 			return {
-- 				position = Vector3.new(0, 40, 0),
-- 				duration = 0,
-- 			}
-- 		end

-- 		local spawnPositions = lastSpawnPositions
-- 		if map ~= lastMap then
-- 			table.clear(usedSpawnPositions)
-- 			spawnPositions = getSpawnPositions(map)
-- 			index = 0
-- 			lastSpawnPositions = spawnPositions
-- 			lastMap = map
-- 		end

-- 		index = (index % #spawnPositions) + 1
-- 		local spawn = spawnPositions[index]

-- 		return spawn and {
-- 			position = spawn.Position,
-- 			duration = spawn.Duration,
-- 		}
-- 	end

-- 	local function onPreSimulation()
-- 		for id, playerRecord in root.world:queryChanged(MatterComponents.Player) do
-- 			if playerRecord.new and playerRecord.new.respawnQueued and playerRecord.new.player then
-- 				root.world:insert(id, playerRecord.new:patch({ respawnQueued = false }))
-- 				task.spawn(playerRecord.new.player.LoadCharacter, playerRecord.new.player)
-- 			end
-- 		end

-- 		for _, characterId in Matter.useEvent(root.eventBus.characterAdded) do
-- 			if not root.world:contains(characterId) then
-- 				continue
-- 			end

-- 			local player = root.world:get(characterId, MatterComponents.Player)

-- 			if SHOULD_OVERRIDE_FILTER(player) then
-- 				if currentMap ~= lastMap then
-- 					table.clear(teamEntries)
-- 				end

-- 				local spawn
-- 				if RESPECT_TEAM_FILTER(player) then
-- 					local teamEntry = teamEntries[player.Team]

-- 					if teamEntry == nil or (os.clock() - teamEntry.createdTime) > 1 or teamEntry.spawnedCount >= 3 then
-- 						teamEntry = newTeamEntry(getCycledSpawnPosition())
-- 						teamEntries[player.Team] = teamEntry
-- 					end

-- 					teamEntry.spawnedCount += 1
-- 					spawn = teamEntry.spawn
-- 				else
-- 					spawn = getCycledSpawnPosition()
-- 				end

-- 				-- Spawn could be nil if there are no Gladiator spawns.
-- 				if spawn then
-- 					-- MoveTo should automatically resolve any part overlap.
-- 					char:MoveTo(spawn.position)

-- 					if char:FindFirstChildWhichIsA("ForceField") == nil then
-- 						local ff = Instance.new("ForceField")
-- 						ff.Parent = char
-- 						Debris:AddItem(ff, spawn.duration)
-- 					end
-- 				end
-- 			end
-- 		end
-- 	end

-- 	local function onCharacterAdded(character)
-- 		local player = Players:GetPlayerFromCharacter(character)

-- 		root.world:insert(
-- 			root:getEntityFromInstance(player),
-- 			MatterComponents.Character({
-- 				humanoid = character:FindFirstChild("Humanoid") or error("No humanoid for " .. character:GetFullName());
-- 			})
-- 		)

-- 		if SHOULD_OVERRIDE_FILTER(player) then
-- 			if getCurrentMap() ~= lastMap then
-- 				table.clear(teamEntries)
-- 			end

-- 			local spawn
-- 			if RESPECT_TEAM_FILTER(player) then
-- 				local teamEntry = teamEntries[player.Team]

-- 				if teamEntry == nil or (os.clock() - teamEntry.createdTime) > 1 or teamEntry.spawnedCount >= 3 then
-- 					teamEntry = newTeamEntry(getCycledSpawnPosition())
-- 					teamEntries[player.Team] = teamEntry
-- 				end

-- 				teamEntry.spawnedCount += 1
-- 				spawn = teamEntry.spawn
-- 			else
-- 				spawn = getCycledSpawnPosition()
-- 			end

-- 			-- Spawn could be nil if there are no Gladiator spawns.
-- 			if spawn then
-- 				-- MoveTo should automatically resolve any part overlap.
-- 				char:MoveTo(spawn.position)

-- 				if char:FindFirstChildWhichIsA("ForceField") == nil then
-- 					local ff = Instance.new("ForceField")
-- 					ff.Parent = char
-- 					Debris:AddItem(ff, spawn.duration)
-- 				end
-- 			end
-- 		end
-- 	end

-- 	return {
-- 		callbacks = {
-- 			preSimulation = onPreSimulation;
-- 			robloxCharacterAdded = onCharacterAdded;
-- 		};

-- 		priority = GameEnum.SystemPriorities.CoreAfter;
-- 	}
-- end

-- return respawnPlayers

local function respawnPlayers(root)
	for id, playerRecord in root.world:queryChanged(MatterComponents.Player) do
		if playerRecord.new and playerRecord.new.respawnQueued and playerRecord.new.player then
			root.world:insert(id, playerRecord.new:patch({ respawnQueued = false }))
			task.spawn(playerRecord.new.player.LoadCharacter, playerRecord.new.player)
		end
	end
end

return {
	event = "PreSimulation";
	priority = GameEnum.SystemPriorities.CoreAfter;
	system = respawnPlayers;
}