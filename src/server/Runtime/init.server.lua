local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local TestService = game:GetService("TestService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")

local Root = require(ReplicatedStorage.Common.Root)
local SoundPlayer = require(ReplicatedStorage.Common.Utils.SoundPlayer)
local RemoteProperty = require(ReplicatedStorage.Common.RemoteProperty)
local getFullPlayerName = require(ReplicatedStorage.Common.Utils.getFullPlayerName)
local EventBus = require(ReplicatedStorage.Common.EventBus)
local defaultGlobalValues = require(script.Parent.defaultGlobalValues)

local loadTools = require(script.loadTools)
local resetPlayer = require(script.resetPlayer)
local roduxServer = require(script.roduxServer)

local Configuration = ReplicatedStorage.Configuration
local Services = script.Parent.Services
local Scripts = script.Parent.Scripts

-- RunService:IsRunMode() always returns true even when hitting Play, so it's useless here.
if TestService.ExecuteWithStudioRun and RunService:IsStudio() then
    return
end

_G.debug = require(ReplicatedStorage.Common.Utils.breakpoint)

local RemoteEvents = Instance.new("Folder")
RemoteEvents.Name = "RemoteEvents"
RemoteEvents.Parent = ReplicatedStorage

local function getRemoteEvent(_, name)
    local remoteEvent = RemoteEvents:FindFirstChild(name)

    if not remoteEvent then
        remoteEvent = Instance.new("RemoteEvent")
        remoteEvent.Name = name
        remoteEvent.Parent = RemoteEvents
    end

    return remoteEvent
end

local function registerRoot()
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
        task.spawn(require(script), Root)
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

local function removeStudioInstances()
    -- Clear Studio lighting.
    Lighting:ClearAllChildren()

    for _, instance in ipairs(CollectionService:GetTagged("Studio")) do
        instance.Parent = nil
    end
end

local function setPlayerTags()
    RunService.Stepped:Connect(function()
		for _, player in Players:GetPlayers() do
            local team = player.Team

			if CollectionService:HasTag(team, "ParticipatingTeam") then
				CollectionService:AddTag(player, "ParticipatingPlayer")
			else
				CollectionService:RemoveTag(player, "ParticipatingPlayer")
			end

			if CollectionService:HasTag(team, "FightingTeam") then
				CollectionService:AddTag(player, "FightingPlayer")
			else
				CollectionService:RemoveTag(player, "FightingPlayer")
			end
		end
	end)
end

local function registerRodux()
    roduxServer(Root)
end

local function init()
    local RemoteProperties = Instance.new("Folder")
    RemoteProperties.Name = "RemoteProperties"
    RemoteProperties.Parent = ReplicatedStorage
    
    Root.SoundPlayer = SoundPlayer.new()
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
        notificationRemote:FireAllClients(true, message, options)
    end

    Root.notification = function(message, options)
        notificationRemote:FireAllClients(false, message, options)
    end

    Root.resetPlayer = resetPlayer
    Root.getRemoteEvent = getRemoteEvent
end

removeStudioInstances()
loadTools()
while not _G.BB do
    task.wait()
end

init()
registerRodux()
registerRoot()
runScripts()
spawnPlayers()
initializePlayers()
warnIfSlow()
setPlayerTags()

workspace:SetAttribute("GameInitialized", true)