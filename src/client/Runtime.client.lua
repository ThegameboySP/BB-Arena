local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local Knit = require(ReplicatedStorage.Packages.Knit)
local RemoteProperty = require(ReplicatedStorage.Common.RemoteProperty)
local EventBus = require(ReplicatedStorage.Common.EventBus)

local RemoteProperties = ReplicatedStorage:WaitForChild("RemoteProperties")
local Controllers = ReplicatedStorage.ClientModules.Controllers

if not workspace:GetAttribute("GameInitialized") then
    workspace:GetAttributeChangedSignal("GameInitialized"):Wait()
end

local function registerKnit()
    Knit.globals = {}
    for _, child in pairs(RemoteProperties:GetChildren()) do
        Knit.globals[child.Name] = RemoteProperty.new(RemoteProperties, child.Name)
    end

    Knit.AddControllers(Controllers)

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

    RunService.Heartbeat:Connect(function()
        updateControllers()
    end)
end

registerKnit()

EventBus:GetPlayerDiedSignal(Players.LocalPlayer):Connect(function()
    local gui = ReplicatedStorage.UI.RespawnGui:Clone()
    gui.Parent = Players.LocalPlayer.PlayerGui

    local duration = Knit.globals.respawnTime:Get()
    local con = RunService.Heartbeat:Connect(function(dt)
        duration = math.max(0, duration - dt)
        gui.TextLabel.Text = string.format("Respawn in: %d", duration + 1)
    end)

    Players.LocalPlayer.CharacterAdded:Wait()

    con:Disconnect()
    gui.Parent = nil
end)