local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")

local Knit = require(ReplicatedStorage.Packages.Knit)
local RemoteProperty = require(ReplicatedStorage.Common.RemoteProperty)
local getFullPlayerName = require(ReplicatedStorage.Common.Utils.getFullPlayerName)
local EventBus = require(ReplicatedStorage.Common.EventBus)
local defaultGlobalValues = require(script.Parent.defaultGlobalValues)

local loadTools = require(script.loadTools)
local resetPlayer = require(script.resetPlayer)

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

    local clientErrorRemote = Instance.new("RemoteEvent")
    clientErrorRemote.Name = "ClientErrorRemote"
    clientErrorRemote.Parent = ReplicatedStorage

    clientErrorRemote.OnServerEvent:Connect(function(client, message, stackTrace)
        warn("[Game Critical]", getFullPlayerName(client) .. " errored:", message .. "\n" .. stackTrace)
    end)
    
    Knit.hint = function(message, options)
        options = options or {}
        options.sender = options.sender or "Nexus Arena"
        notificationRemote:FireAllClients(true, message, options)
    end

    Knit.notification = function(message, options)
        options = options or {}
        options.sender = options.sender or "Nexus Arena"
        notificationRemote:FireAllClients(false, message, options)
    end

    Knit.resetPlayer = resetPlayer

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
    local function onPlayerAdded(player)
        player:LoadCharacter()
    end

    Players.PlayerAdded:Connect(onPlayerAdded)
    for _, player in ipairs(Players:GetPlayers()) do
        task.spawn(onPlayerAdded, player)
    end

    EventBus.playerDied:Connect(function(player)
        local connections = {}
        local thread = task.delay(Knit.globals.respawnTime:Get(), function()
            for _, connection in ipairs(connections) do
                connection:Disconnect()
            end

            player:LoadCharacter()
        end)

        local function disconnect()
            task.cancel(thread)

            for _, connection in ipairs(connections) do
                connection:Disconnect()
            end
        end

        table.insert(connections, player.AncestryChanged:Connect(disconnect))
        table.insert(connections, player.CharacterAdded:Connect(disconnect))
    end)
end

local function warnIfSlow()
    local lastUpdate = os.clock()
    local lastWarn = 0

    RunService.Heartbeat:Connect(function()
        local timestamp = os.clock()

        if (timestamp - lastWarn) <= 5 then
            lastUpdate = timestamp
            return
        end

        local elapsedTime = timestamp - lastUpdate
        lastUpdate = timestamp

        if elapsedTime > (1/20) then
            warn(
                (elapsedTime <= (1/5)) and "[Game]" or "[Game Critical]",
                string.format("running at %.1f HZ", 1 / elapsedTime)
            )

            lastWarn = timestamp
        end
    end)
end

-- Clear Studio lighting.
Lighting:ClearAllChildren()

loadTools()
registerKnit()
spawnPlayers()
warnIfSlow()

workspace:SetAttribute("GameInitialized", true)