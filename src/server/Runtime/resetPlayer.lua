local Workspace = game:GetService("Workspace")

local spawns = {}

local random = Random.new()
local function shuffle(tbl)
	local shuffled = table.clone(tbl)

	for i = #tbl, 2, -1 do
		local j = random:NextInteger(1, i)
		shuffled[i], shuffled[j] = shuffled[j], shuffled[i]
	end

	return shuffled
end

local function onDescendantAdded(descendant)
    if descendant:IsA("SpawnLocation") then
        table.insert(spawns, descendant)
    end
end

Workspace.DescendantAdded:Connect(onDescendantAdded)
Workspace.DescendantRemoving:Connect(function(descendant)
    if descendant:IsA("SpawnLocation") then
        table.remove(spawns, table.find(spawns, descendant))
    end
end)

for _, descendant in pairs(Workspace:GetDescendants()) do
    onDescendantAdded(descendant)
end

local function resetPlayer(player)
    local character = player.Character
    if character == nil then
        return
    end

    if player.Team == nil then
        character:MoveTo(Vector3.zero)
        return
    end

    local teamColor = player.Team.TeamColor
    local chosenSpawn

    for _, spawn in ipairs(shuffle(spawns)) do
        if spawn.TeamColor == teamColor then
            chosenSpawn = spawn
            break
        end
    end

    if chosenSpawn == nil then
        character:MoveTo(Vector3.zero)
        return
    end

    character:MoveTo(chosenSpawn.Position)
end

return resetPlayer