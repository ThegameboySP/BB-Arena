local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Events = script.Events

local Root = require(ReplicatedStorage.Common.Root)
local Promise = require(ReplicatedStorage.Packages.Promise)

local CmdrReplicated = ReplicatedStorage.CmdrReplicated
local canRun = require(CmdrReplicated.Hooks.canRun)
local CmdrNotifications = require(script.CmdrNotifications)

local LOCAL_PLAYER = Players.LocalPlayer
local ERROR_COLOR = Color3.fromRGB(255, 112, 112)

local CmdrController = {
	Name = "CmdrController";
	Cmdr = nil;
}

function CmdrController:CanRun(player, group)
	return canRun.canRun(Root.Store:getState().users, player.UserId, group)
end

function CmdrController:OnInit()
    local CmdrService = Root:GetServerService("CmdrService")

	CmdrService.Warning:Connect(function(str)
		CmdrNotifications:AddMessage(str, true, ERROR_COLOR)
	end)

	local CmdrClient = require(ReplicatedStorage.CmdrClient)
	self.Cmdr = CmdrClient
	
    local common = CmdrClient.Registry:GetStore("Common")
	common.Root = Root
	common.Store = Root.Store
end

function CmdrController:OnStart()
	local CmdrClient = self.Cmdr

	require(CmdrReplicated.registerTypes)(CmdrClient.Registry, Root.globals.mapInfo:Get())
	CmdrClient.Registry.Types.player = CmdrClient.Registry.Types.arenaPlayer
	CmdrClient.Registry.Types.players = CmdrClient.Registry.Types.arenaPlayers
	
	if RunService:IsStudio() then
		CmdrClient.Dispatcher:EvaluateAndRun("bind t blink")
	end

	CmdrClient:SetPlaceName("bb-arena")
	CmdrClient:SetActivationKeys({ Enum.KeyCode.F2, Enum.KeyCode.Semicolon })
	UserInputService.InputBegan:Connect(function(input, gp)
		if not gp and input.KeyCode == Enum.KeyCode.Escape then
		    CmdrClient:Hide()
        end
	end)

	-- Set blank BeforeRun hook so commands can run.
	-- We set this on the server so it doesn't matter.
	CmdrClient.Registry:RegisterHook("BeforeRun", function() end)
	
	for _, eventModule in Events:GetChildren() do
		CmdrClient:HandleEvent(eventModule.Name, require(eventModule))
	end
	
	LOCAL_PLAYER.Chatted:Connect(function(message)
		if message:sub(1, 1) ~= ":" then
            return
        end

		local dispatcher = CmdrClient.Dispatcher
		local cmd = message:sub(2, -1)
		if cmd == "help" or cmd == "cmds" or cmd == "commands" then
			CmdrClient:Show()
			return dispatcher:EvaluateAndRun("help", LOCAL_PLAYER)
		elseif cmd == "logs" or cmd == "l" then
			CmdrClient:Show()
			return dispatcher:EvaluateAndRun("logs", LOCAL_PLAYER)
		elseif cmd == "console" then
			return CmdrClient:Show()
		end
		
		local msg = dispatcher:EvaluateAndRun(cmd, LOCAL_PLAYER)
		local r1, err = dispatcher:Evaluate(cmd, LOCAL_PLAYER)
		if r1 == false then
			CmdrNotifications:AddMessage(err, true, ERROR_COLOR)
			dispatcher:EvaluateAndRun(("reply %q %s"):format(("%q: -> %s"):format(cmd, err), "255,73,73"))
		else
			if msg ~= "Command executed." then
				CmdrNotifications:AddMessage(msg, false)
			end

			dispatcher:EvaluateAndRun(("reply %q %s"):format(("%q: -> %s"):format(cmd, msg), "255,255,255"))
		end
	end)
end

function CmdrController:OnPlayerLoaded(player)
	if player:GetAttribute("IsCmdrLoaded") then
		return Promise.resolve()
	else
		return Promise.new(function(resolve, _, onCancel)
			local con = player:GetAttributeChangedSignal("IsCmdrLoaded"):Connect(resolve)
			
			if onCancel(function()
				con:Disconnect()
			end) then con:Disconnect() end
		end)
	end
end
return CmdrController