local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TestService = game:GetService("TestService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")

local Root = require(ReplicatedStorage.Common.Root)
local RemoteProperty = require(ReplicatedStorage.Common.RemoteProperty)
local getFullPlayerName = require(ReplicatedStorage.Common.Utils.getFullPlayerName)
local EventBus = require(ReplicatedStorage.Common.EventBus)
local defaultGlobalValues = require(script.Parent.defaultGlobalValues)

local loadTools = require(script.loadTools)
local resetPlayer = require(script.resetPlayer)

local Configuration = ReplicatedStorage.Configuration
local Services = script.Parent.Services
local Scripts = script.Parent.Scripts

-- RunService:IsRunMode() always returns true even when hitting Play, so it's useless here.
if TestService.ExecuteWithStudioRun and RunService:IsStudio() then
    return
end

local function registerRoot()
    local RemoteProperties = Instance.new("Folder")
    RemoteProperties.Name = "RemoteProperties"
    RemoteProperties.Parent = ReplicatedStorage
    
    Root.globals = {}
    for key, value in pairs(defaultGlobalValues) do
        Root.globals[key] = RemoteProperty.new(RemoteProperties, key)
        Root.globals[key]:Set(value)
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
    
    Root.hint = function(message, options)
        options = options or {}
        options.sender = options.sender or "Nexus Arena"
        notificationRemote:FireAllClients(true, message, options)
    end

    Root.notification = function(message, options)
        options = options or {}
        options.sender = options.sender or "Nexus Arena"
        notificationRemote:FireAllClients(false, message, options)
    end

    Root.resetPlayer = resetPlayer

    Root:RegisterServicesIn(Services)
    
    Root:Start()
        :catch(warn)
        :await()
    
    local startingMapName = Configuration:GetAttribute("StartingMapName")
    if startingMapName then
        Root:GetService("MapService"):ChangeMap(startingMapName)
    end
end

local function runScripts()
    for _, script in ipairs(Scripts:GetChildren()) do
        require(script)(Root)
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
        local thread = task.delay(Root.globals.respawnTime:Get(), function()
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

local function initializePlayers()
    local function onPlayerAdded(player)
        -- hack
        task.delay(0.2, function()
            player:SetAttribute("Initialized", true)
        end)
    end

    Players.PlayerAdded:Connect(onPlayerAdded)
    for _, player in ipairs(Players:GetPlayers()) do
        onPlayerAdded(player)
    end
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
registerRoot()
runScripts()
spawnPlayers()
initializePlayers()
warnIfSlow()

workspace:SetAttribute("GameInitialized", true)