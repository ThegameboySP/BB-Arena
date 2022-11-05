local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ScriptContext = game:GetService("ScriptContext")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local Root = require(ReplicatedStorage.Common.Root)
local RemoteProperty = require(ReplicatedStorage.Common.RemoteProperty)
local EventBus = require(ReplicatedStorage.Common.EventBus)
local roduxClient = require(ReplicatedStorage.ClientModules.roduxClient)
local SoundPlayer = require(ReplicatedStorage.Common.Utils.SoundPlayer)
local Tools = require(ReplicatedStorage.ClientModules.Tools)
local Input = require(ReplicatedStorage.ClientModules.Input)

local notificationGUI = require(ReplicatedStorage.ClientModules.UI.notificationGUI)
local hintGUI = require(ReplicatedStorage.ClientModules.UI.hintGUI)

local RespawnGui = ReplicatedStorage.UI.RespawnGui
local RemoteProperties = ReplicatedStorage:WaitForChild("RemoteProperties")
local notificationRemote = ReplicatedStorage:WaitForChild("NotificationRemote")
local clientErrorRemote = ReplicatedStorage:WaitForChild("ClientErrorRemote")

local Controllers = ReplicatedStorage.ClientModules.Controllers
local Scripts = ReplicatedStorage.ClientModules.Scripts

_G.debug = require(ReplicatedStorage.Common.Utils.breakpoint)

if not Players.LocalPlayer:GetAttribute("Initialized") then
    Players.LocalPlayer:GetAttributeChangedSignal("Initialized"):Wait()
end

-- Legacy toolset crap
while not _G.BB or not _G.BB.Local do
    task.wait()
end

local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local function getRemoteEvent(_, name)
    return RemoteEvents:WaitForChild(name)
end

local function registerRoot()
    Root:RegisterServicesIn(Controllers)

    Root:Start()
        :catch(function(err)
            task.spawn(error, tostring(err))
        end)
        :await()

    local MapService = Root:GetServerService("MapService")

    local MapController = Root:GetService("MapController")
    local GamemodeController = Root:GetService("GamemodeController")

    local queuedMap
    MapService.MapChanging:Connect(function(mapName, oldMapName)
        MapController:onMapChanging(mapName, oldMapName)
    end)

    MapService.CurrentMap:Observe(function(map)
        queuedMap = map
    end)

    local queuedGamemodeName
    local function onChanged(new, old)
        if old == nil or new.game.gamemodeId ~= old.game.gamemodeId then
            if new.game.gamemodeId == nil then
                queuedGamemodeName = "nil"
            else
                queuedGamemodeName = new.game.gamemodeId
            end
        end
    end

    Root.Store.changed:connect(onChanged)
    onChanged(Root.Store:getState(), nil)

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

local function runScripts()
    for _, script in ipairs(Scripts:GetChildren()) do
        task.spawn(require(script), Root)
    end
end

local function registerRodux()
    roduxClient(Root)
end

local function init()
    Root.globals = {}
    Root.SoundPlayer = SoundPlayer.new()
    Root.Input = Input.new(Root)
    Root.Tools = Tools.new(Root)

    for _, child in pairs(RemoteProperties:GetChildren()) do
        Root.globals[child.Name] = RemoteProperty.new(RemoteProperties, child.Name)
    end

    Root.notification = function(msg, options)
        options = options or {}
        options.sender = options.sender or "Nexus Arena"

        notificationGUI(msg, options)
    end
    Root.hint = function(msg, options)
        options = options or {}
        options.sender = options.sender or "Nexus Arena"

        hintGUI(msg, options)
    end

    Root.getRemoteEvent = getRemoteEvent
    
    notificationRemote.OnClientEvent:Connect(function(isHint, message, options)
        if isHint then
            Root.hint(message, options)
        else
            Root.notification(message, options)
        end
    end)

    ScriptContext.Error:Connect(function(message, stackTrace)
        -- Avoid stupid error spam caused by the toolset.
        local loweredStacktrace = stackTrace:lower()
        if not stackTrace or (not loweredStacktrace:find("backpack") and not loweredStacktrace:find("tool")) then
            clientErrorRemote:FireServer(message, stackTrace)
        end
    end)
end

init()
registerRodux()
registerRoot()
Root.Input:Init()
Root.Tools:Init()
runScripts()

EventBus:GetPlayerDiedSignal(Players.LocalPlayer):Connect(function()
    local gui = RespawnGui:Clone()
    gui.Parent = Players.LocalPlayer.PlayerGui

    local duration = Root.globals.respawnTime:Get()
    local con = RunService.Heartbeat:Connect(function(dt)
        duration = math.max(0, duration - dt)
        gui.TextLabel.Text = string.format("Respawn in: %d", duration + 1)
    end)

    Players.LocalPlayer.CharacterAdded:Wait()

    con:Disconnect()
    gui.Parent = nil
end)