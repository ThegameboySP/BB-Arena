local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextService = game:GetService("TextService")

local Root = require(ReplicatedStorage.Common.Root)
local Promise = require(ReplicatedStorage.Packages.Promise)
local Cmdr = require(ServerScriptService.Packages.Cmdr)

local CmdrCore = ServerScriptService.Server.Cmdr.Core
local CmdrArena = ServerScriptService.Server.Cmdr.Arena
local registerArenaTypes = require(CmdrArena.registerTypes)
local canRun = require(CmdrArena.Hooks.canRun)

local getFullPlayerName = require(ReplicatedStorage.Common.Utils.getFullPlayerName)
local GameEnum = require(ReplicatedStorage.Common.GameEnum)
local RoduxFeatures = require(ReplicatedStorage.Common.RoduxFeatures)
local actions = RoduxFeatures.actions
local selectors = RoduxFeatures.selectors

local LockCommands = require(script.LockCommands)

local CmdrService = {
	Name = "CmdrService";
	Client = {
		CmdrLoaded = Root.remoteProperty(false);
		CommandExecuted = Root.remoteEvent();
		Warning = Root.remoteEvent();
		Reply = Root.remoteEvent();
	};
	
	Cmdr = Cmdr;
    _lockCommands = LockCommands.new(Root.Store);
	_logs = {};
}

local BLACKLISTED_COMMANDS = {
	kick = true; -- already have a kick
	thru = true; -- thru also defines a "t" alias, replacing team's alias
	respawn = true; -- already have a respawn
	replace = true; -- replace defines a "map" alias for some reason
	["goto-place"] = true;
}

function CmdrService:CanRun(player, group)
	return canRun.canRun(Root.Store:getState().users, player.UserId, group)
end

function CmdrService:GetLogs()
	return self._logs
end

function CmdrService:OnInit()
	local ownerId = game.PrivateServerOwnerId
	if ownerId then
        if selectors.getAdmin(Root.Store:getState(), ownerId) < GameEnum.AdminTiers.Admin then
			Root.Store:dispatch(actions.setAdmin(ownerId, GameEnum.AdminTiers.Admin))
		end
	end

	self:_setupCmdr()

	Players.PlayerAdded:Connect(playerHandler)
	for _, player in pairs(Players:GetPlayers()) do
		playerHandler(player)
	end
end

function CmdrService:_setupCmdr()
	local common = Cmdr.Registry:GetStore("Common")
	common.Root = Root
	common.Store = Root.Store

	local CmdrReplicated = Instance.new("Folder")
	CmdrReplicated.Name = "CmdrReplicated"
	CmdrReplicated.Parent = ReplicatedStorage
	
	Cmdr:RegisterDefaultCommands(function(commandDefinition)
		local name = commandDefinition.Name:lower()
		return not BLACKLISTED_COMMANDS[name]
	end)
	
	registerArenaTypes(Cmdr.Registry, Root.globals.mapInfo:Get())

	Cmdr.Registry:RegisterCommandsIn(CmdrArena.Commands)
	Cmdr.Registry:RegisterCommandsIn(CmdrCore.Commands)

	local place = ServerScriptService:FindFirstChild("Place")
	if place then
		local customCommands = place:FindFirstChild("CmdrCommands")
		if customCommands then
			Cmdr.Registry:RegisterCommandsIn(customCommands)
		end
	end
	
	Cmdr.Registry:RegisterHook("BeforeRun", function(context)
		if context.Executor and not self:CanRun(context.Executor, context.Group) then
			return "You don't have permission to run this command."
		end

		context.Warn = function(_, msg)
			self.Client.Warning:FireClient(context.Executor, msg)
		end

		local reply = context.Reply
		context.Reply = function(_, msg)
			self.Client.Reply:FireClient(context.Executor, msg)
			reply(context, msg)
		end
	end)

	Cmdr:RegisterHook("BeforeRun", function(context)
		return self._lockCommands:beforeRun(
            context.Executor and context.Executor.UserId,
            self.Cmdr.Registry:GetCommand(context.Name)
        )
	end)
	
	Cmdr:RegisterHook("AfterRun", function(context)
		if #self._logs > 100 then
			table.remove(self._logs, 1)
		end
		
		task.spawn(function()
			local executorName = "Server"
			local argumentsText = table.concat(context.RawArguments, " ")

			if context.Executor then
				pcall(function()
					executorName = getFullPlayerName(context.Executor)
					
					local filterResult = TextService:FilterStringAsync(argumentsText, context.Executor.UserId, Enum.TextFilterContext.PublicChat)
					argumentsText = filterResult:GetNonChatStringForBroadcastAsync()
				end)
			end
	
			table.insert(self._logs, {
				ExecutorName = executorName;
				ArgumentsText = argumentsText;
				Name = context.Name;
				Response = context.Response;
			})
		end)
	end)
	
	require(CmdrArena.processCommands)(Cmdr.Registry)

	-- Replicate to all clients.
	CmdrArena.Hooks.Parent = CmdrReplicated
	CmdrArena.registerTypes.Parent = CmdrReplicated
	CmdrArena.processCommands.Parent = CmdrReplicated
	self.Client.CmdrLoaded:Set(true)
end

function CmdrService:LockCommand(commandName, byUserId)
	return self._lockCommands:lockCommand(
        byUserId,
        self.Cmdr.Registry:GetCommand(commandName)
    )
end

function CmdrService:UnlockCommand(commandName, byUserId)
	return self._lockCommands:unlockCommand(
        byUserId,
        self.Cmdr.Registry:GetCommand(commandName)
    )
end

function CmdrService:OnPlayerLoaded(player)
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

function playerHandler(player)
	-- 0 = unknown player, -1 = player1, -2 = player2, etc
	if player.UserId <= 0 then
		Root.Store:dispatch(actions.setAdmin(player.UserId, GameEnum.AdminTiers.Owner))
	end

	local getRank = Promise.promisify(player.GetRankInGroup)

	-- TOB Ranktester and beyond gets admin.
	getRank(player, 3397136):andThen(function(role)
		if role >= 11 then
			if selectors.getAdmin(Root.Store:getState(), player.UserId) < GameEnum.AdminTiers.Admin then
				Root.Store:dispatch(actions.setAdmin(player.UserId, GameEnum.AdminTiers.Admin))
			end
		end
	end):finally(function()
		player:SetAttribute("IsCmdrLoaded", true)
	end)
end

return CmdrService