local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local Knit = require(ReplicatedStorage.Packages.Knit)
local RemoteProperty = require(ReplicatedStorage.Common.RemoteProperty)
local EventBus = require(ReplicatedStorage.Common.EventBus)

local notificationGUI = require(ReplicatedStorage.ClientModules.UI.notificationGUI)
local hintGUI = require(ReplicatedStorage.ClientModules.UI.hintGUI)

local RespawnGui = ReplicatedStorage.UI.RespawnGui
local RemoteProperties = ReplicatedStorage:WaitForChild("RemoteProperties")
local notificationRemote = ReplicatedStorage:WaitForChild("NotificationRemote")
local Controllers = ReplicatedStorage.ClientModules.Controllers

if not workspace:GetAttribute("GameInitialized") then
    workspace:GetAttributeChangedSignal("GameInitialized"):Wait()
end

local function registerKnit()
    Knit.globals = {}
    for _, child in pairs(RemoteProperties:GetChildren()) do
        Knit.globals[child.Name] = RemoteProperty.new(RemoteProperties, child.Name)
    end

    Knit.notification = notificationGUI
    Knit.hint = hintGUI
    
    notificationRemote.OnClientEvent:Connect(function(isHint, message, color, sender)
        if isHint then
            hintGUI(message, color, sender or "Nexus Arena")
        else
            notificationGUI(message, color, sender or "Nexus Arena")
        end
    end)

    Knit.GetSingleton = function(name)
        return Knit.GetController(name .. "Controller")
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
            task.spawn(MapController.onMapChanged, MapController, queuedMap)
        end

        if queuedGamemodeName and queuedGamemodeName ~= "nil" then
            task.spawn(GamemodeController.onGamemodeStarted, GamemodeController, queuedGamemodeName)
        elseif queuedGamemodeName == "nil" then
            task.spawn(GamemodeController.onGamemodeEnded, GamemodeController)
        end
        
        if queuedMap then
            task.spawn(GamemodeController.onMapChanged, GamemodeController)
        end

        task.spawn(MapController.ClonerManager.Flush, MapController.ClonerManager)

        queuedMap = nil
        queuedGamemodeName = nil
    end

    RunService.Heartbeat:Connect(function()
        updateControllers()
    end)
end

registerKnit()

EventBus:GetPlayerDiedSignal(Players.LocalPlayer):Connect(function()
    local gui = RespawnGui:Clone()
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