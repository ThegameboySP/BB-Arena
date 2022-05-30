local ReplicatedStorage = game:GetService("ReplicatedStorage")

task.spawn(function()
    local Settings = require(7564402844)
    require(6101328137)(Settings)
end)

local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)

Knit.AddServices(script.Parent.Services)

Knit.Start()
    :catch(warn)
    :await()

local startingMapName = ReplicatedStorage.Configuration:GetAttribute("StartingMapName")
if startingMapName then
    Knit.GetService("MapService"):ChangeMap(startingMapName)
end

-- local MapService = Knit.GetService("MapService")
-- local GamemodeService = Knit.GetService("GamemodeService")

-- local function updateServices()
--     if MapService.queued.map then
--         MapService:changeMap(MapService.queued.map)
--     end

--     if GamemodeService.queued.gamemodeInfo then
--         GamemodeService:startGamemode(GamemodeService.queued.gamemodeInfo)
--     elseif GamemodeService.queued.stopGamemode then
--         GamemodeService:stopGamemode()
--     end
    
--     if MapService.queued.map then
--         GamemodeService:onMapChanged()
--     end

--     table.clear(MapService.queued)
--     table.clear(GamemodeService.queued)
-- end

-- game:GetService("RunService").Heartbeat:Connect(function()
--     updateServices()
-- end)