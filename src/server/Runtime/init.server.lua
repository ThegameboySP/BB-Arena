local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Knit = require(ReplicatedStorage.Packages.Knit)
local RemoteProperty = require(ReplicatedStorage.Common.RemoteProperty)
local EventBus = require(ReplicatedStorage.Common.EventBus)
local defaultGlobalValues = require(script.Parent.defaultGlobalValues)

local loadTools = require(script.loadTools)

local Configuration = ReplicatedStorage.Configuration
local Services = script.Parent.Services

local function registerKnit()
    local RemoteProperties = Instance.new("Folder")
    RemoteProperties.Name = "RemoteProperties"
    RemoteProperties.Parent = ReplicatedStorage
    
    Knit.globals = {}
    for key, value in pairs(defaultGlobalValues) do
        Knit.globals[key] = RemoteProperty.new(RemoteProperties, key)
        Knit.globals[key]:Set(value)
    end
    
    local notificationRemote = Instance.new("RemoteEvent")
    notificationRemote.Name = "NotificationRemote"
    notificationRemote.Parent = ReplicatedStorage
    
    Knit.hint = function(message, color, sender)
        notificationRemote:FireAllClients(true, message, color, sender)
    end

    Knit.notification = function(message, color, sender)
        notificationRemote:FireAllClients(false, message, color, sender)
    end

    Knit.GetSingleton = function(name)
        return Knit.GetService(name .. "Service")
    end

    Knit.AddServices(Services)
    
    Knit.Start()
        :catch(warn)
        :await()
    
    local startingMapName = Configuration:GetAttribute("StartingMapName")
    if startingMapName then
        Knit.GetService("MapService"):ChangeMap(startingMapName)
    end
end

local function spawnPlayers()
    Players.PlayerAdded:Connect(function(player)
        player:LoadCharacter()
    end)

    EventBus.playerDied:Connect(function(player)
        task.delay(Knit.globals.respawnTime:Get(), function()
            player:LoadCharacter()
        end)
    end)
end

loadTools()
registerKnit()
spawnPlayers()

workspace:SetAttribute("GameInitialized", true)