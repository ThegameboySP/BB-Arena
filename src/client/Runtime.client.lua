local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)

Knit.AddControllers(game:GetService("ReplicatedStorage").ClientModules.Controllers)

Knit.Start()
    :catch(warn)
    :await()

local MapService = Knit.GetService("MapService")
local GamemodeService = Knit.GetService("GamemodeService")

local MapController = Knit.GetController("MapController")
local GamemodeController = Knit.GetController("GamemodeController")

local queuedMap
MapService.CurrentMap:Observe(function(map)
    queuedMap = map
end)

local queuedGamemodeName
GamemodeService.CurrentGamemode:Observe(function(gamemodeName)
    if gamemodeName == nil then
        queuedGamemodeName = "nil"
    else
        queuedGamemodeName = gamemodeName
    end
end)

local function updateControllers()
    if queuedMap then
        MapController:onMapChanged(queuedMap)
    end

    if queuedGamemodeName and queuedGamemodeName ~= "nil" then
        GamemodeController:onGamemodeStarted(queuedGamemodeName)
    elseif queuedGamemodeName == "nil" then
        GamemodeController:onGamemodeEnded()
    end
    
    if queuedGamemodeName then
        GamemodeController:onMapChanged()
    end

    queuedMap = nil
    queuedGamemodeName = nil
end

game:GetService("RunService").Heartbeat:Connect(function()
    updateControllers()
end)