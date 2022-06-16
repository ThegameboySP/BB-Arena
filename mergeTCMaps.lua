assert(type(...) == "string", "you gotta pass in the map selector")

local function findMap(dm, mapName)
    return {
        map = dm.ServerStorage.Maps:FindFirstChild(mapName) or dm.Workspace.MapRoot:FindFirstChild(mapName);
        lighting = dm.ServerStorage.Plugin_LightingSaves:FindFirstChild(mapName);
    }
end

local function count(t)
    local c = 0
    for _ in pairs(t) do
        c = c + 1
    end

    return c
end

local tcGame = remodel.readPlaceAsset("6558762994")
local localGame = remodel.readPlaceFile("../arena.rbxl")

local maps = tcGame.ServerStorage.Maps:GetChildren()
local workspaceMap = tcGame.Workspace.MapRoot:GetChildren()[1]
if workspaceMap then
    table.insert(maps, workspaceMap)
end

local mapsToOverwriteWith = {}

if ... == "all" then
    for _, map in ipairs(maps) do
        assert(not mapsToOverwriteWith[map.Name], "Duplicate map name")
        mapsToOverwriteWith[map.Name] = findMap(tcGame, map.Name)
    end
else
    for _, mapName in ipairs({...}) do
        print("merging " .. mapName)

        local data = findMap(tcGame, mapName)
        if data.map == nil then
            error("No map named " .. mapName)
        end

        mapsToOverwriteWith[data.map.Name] = data
    end
end

for _, data in pairs(mapsToOverwriteWith) do
    local oldMap = findMap(localGame, data.map.Name)

    if oldMap.map then
        oldMap.map:Destroy()
    end
    
    local oldLighting = localGame.ServerStorage.Plugin_LightingSaves:FindFirstChild(data.map.Name)
    if oldLighting then
        oldLighting:Destroy()
    end

    data.map.Parent = localGame.ServerStorage.Maps

    if data.lighting then
        data.lighting.Parent = localGame.ServerStorage.Plugin_LightingSaves
    end
end

if count(mapsToOverwriteWith) == 1 then
    local currentMap = localGame.Workspace.MapRoot:GetChildren()[1]
    if currentMap then
        currentMap.Parent = localGame.ServerStorage.Maps
    end

    local _, data = next(mapsToOverwriteWith)
    data.map.Parent = localGame.Workspace.MapRoot
end

remodel.writePlaceFile(localGame, "../arena.rbxl")