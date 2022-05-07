local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Promise = require(ReplicatedStorage.Packages.Promise)

local CmdrReplicated = ReplicatedStorage:WaitForChild("CmdrReplicated")
local canRun = require(CmdrReplicated:WaitForChild("Hooks"):WaitForChild("canRun"))
local CmdrNotifications = require(script.CmdrNotifications)

local LOCAL_PLAYER = Players.LocalPlayer
local ERROR_COLOR = Color3.fromRGB(255, 112, 112)
local IS_STUDIO = game:GetService("RunService"):IsStudio()

local CmdrController = Knit.CreateController({
	Name = "CmdrController";
	Cmdr = nil;
	
	canRun = function(player, group)
		return require(canRun)(Knit.Store:getState().users.admins, player, group)
	end;
	_logs = {{}};
})

function CmdrController:KnitInit()
    local CmdrService = Knit.GetService("CmdrService")
	CmdrService.CommandExecuted:Connect(function(context)
		local len = #self._logs
		local latestPage = self._logs[len]
		
		local selectedPage = latestPage
		if #latestPage > 50 then
			selectedPage = {}
			self._logs[len + 1] = selectedPage
		end

		table.insert(selectedPage, context)
	end)

	CmdrService.Warning:Connect(function(str)
		CmdrNotifications:AddMessage(str, true, ERROR_COLOR)
	end)
end

function CmdrController:KnitStart()
    local CmdrService = Knit.GetService("CmdrService")
    local value = CmdrService.CmdrLoaded
    if not value:Get() then
        value.Changed:Wait()
    end

	local CmdrClient = require(ReplicatedStorage.CmdrClient)
	self.Cmdr = CmdrClient
	
    local common = CmdrClient.Registry:GetStore("Common")
	common.Store = Knit.Store

	require(CmdrReplicated.registerTypes)(CmdrClient.Registry, Knit.GetService("MapService").MapInfo:Get())
	CmdrClient.Registry.Types.player = CmdrClient.Registry.Types.arenaPlayer
	CmdrClient.Registry.Types.players = CmdrClient.Registry.Types.arenaPlayers
	
	if IS_STUDIO then
		CmdrClient.Dispatcher:EvaluateAndRun("bind t blink")
	end

	CmdrClient:SetPlaceName("bb-arena")
	CmdrClient:SetActivationKeys({ Enum.KeyCode.F2, Enum.KeyCode.Semicolon })
	UserInputService.InputBegan:Connect(function(input, gp)
		if not gp and input.KeyCode == Enum.KeyCode.Escape then
		    CmdrClient:Hide()
        end
	end)
	
	-- CmdrClient:HandleEvent("Wakeup", require(script.WakeupEvent))
	-- CmdrClient:HandleEvent("Message", require(script.MessageEvent))
	-- CmdrClient:HandleEvent("Countdown", require(script.CountdownEvent))
	-- CmdrClient:HandleEvent("Hint", require(script.HintEvent))
	-- CmdrClient:HandleEvent("Objective", require(script.ObjectiveEvent))
	-- CmdrClient:HandleEvent("Unobjective", require(script.UnobjectiveEvent))
	
	LOCAL_PLAYER.Chatted:Connect(function(message)
		if message:sub(1, 1) ~= ":" then
            return
        end

		local dispatcher = CmdrClient.Dispatcher
		local cmd = message:sub(2, -1)
		if cmd == "help" or cmd == "cmds" then
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
			dispatcher:EvaluateAndRun(("reply %q %s"):format(("%q: -> %s"):format(cmd, msg), "255,255,255"))
		end
	end)
end

function CmdrController:GetLogs(pageIndex)
	pageIndex = pageIndex or -1
	if pageIndex == 0 then
		pageIndex = -1
	end
	
	local len = #self._logs
	local index = math.clamp(len + pageIndex + 1, 1, len)
	return self._logs[index]
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