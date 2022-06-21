local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Promise = require(ReplicatedStorage.Packages.Promise)
local Cmdr = require(ServerScriptService.Packages.Cmdr)

local CmdrCore = ServerScriptService.Server.Cmdr.Core
local CmdrArena = ServerScriptService.Server.Cmdr.Arena
local registerArenaTypes = require(CmdrArena.registerTypes)
local canRun = require(CmdrArena.Hooks.canRun)

local GameEnum = require(ReplicatedStorage.Common.GameEnum)
local LitUtils = require(ReplicatedStorage.Common.Utils.LitUtils)
local RoduxFeatures = require(ReplicatedStorage.Common.RoduxFeatures)
local actions = RoduxFeatures.actions
local selectors = RoduxFeatures.selectors

local CmdrService = Knit.CreateService({
	Name = "CmdrService";
	Client = {
		CmdrLoaded = Knit.CreateProperty(false);
		CommandExecuted = Knit.CreateSignal();
		Warning = Knit.CreateSignal();
	};
	
	Cmdr = Cmdr;
	_lockedCommands = {};
})

local BLACKLISTED_COMMANDS = {
	kick = true; -- already have a kick
	thru = true; -- thru also defines a "t" alias, replacing team's alias
	respawn = true; -- already have a respawn
	replace = true; -- replace defines a "map" alias for some reason
}

function CmdrService:CanRun(player, group)
	return canRun.canRun(Knit.Store:getState().users.admins, player.UserId, group)
end

function CmdrService:KnitStart()
	self:_setupCmdr()

	Players.PlayerAdded:Connect(playerHandler)
	for _, player in pairs(Players:GetPlayers()) do
		playerHandler(player)
	end
end

function CmdrService:_setupCmdr()
	local common = Cmdr.Registry:GetStore("Common")
	common.Knit = Knit
	common.Store = Knit.Store

	local CmdrReplicated = Instance.new("Folder")
	CmdrReplicated.Name = "CmdrReplicated"
	CmdrReplicated.Parent = ReplicatedStorage
	
	Cmdr:RegisterDefaultCommands(function(commandDefinition)
		local name = commandDefinition.Name:lower()
		return not BLACKLISTED_COMMANDS[name]
	end)
	
	registerArenaTypes(Cmdr.Registry, Knit.globals.mapInfo:Get())

	Cmdr.Registry:RegisterCommandsIn(CmdrArena.Commands)
	Cmdr.Registry:RegisterCommandsIn(CmdrCore.Commands)
	
	Cmdr.Registry.Types.player = Cmdr.Registry.Types.arenaPlayer
	Cmdr.Registry.Types.players = Cmdr.Registry.Types.arenaPlayers
	
	Cmdr.Registry:RegisterHook("BeforeRun", function(context)
		if not self:CanRun(context.Executor, context.Group) then
			local msg = "You don't have permission to run this command."
			
			if context.Executor then
				self.Client.Warning:Fire(context.Executor, msg)
			end
			
			return msg
		end

		context.State.Warnings = {}
		context.Warn = function(msg)
			table.insert(context.State.Warnings, msg)
		end
	end)

	Cmdr:RegisterHook("BeforeRun", function(context)
		local locked = self._lockedCommands[context.Name]
		if not locked or context.Executor == nil then
			return
		end
		
		local state = Knit.Store:getState()

		local byAdmin = selectors.getAdmin(state, locked.userId)
		if selectors.getAdmin(state, context.Executor.UserId) < byAdmin then
			local tierName = GameEnum.AdminTiersByValue[byAdmin]
			return string.format("This command is locked by %s %s.", LitUtils.getIndefiniteArticle(tierName), tierName)
		end
	end)
	
	Cmdr:RegisterHook("AfterRun", function(context)
		self.Client.CommandExecuted:FireAll({
			ExecutorName = context.Executor and context.Executor.Name or "Server";
			RawText = context.RawText;
			Response = context.Response;
		})
		
		for _, warning in ipairs(context.State.Warnings) do
			self.Client.Warning:Fire(context.Executor, warning)
		end
	end)
	
	-- Replicate to all clients.
	CmdrArena.Hooks.Parent = CmdrReplicated
	CmdrArena.registerTypes.Parent = CmdrReplicated
	self.Client.CmdrLoaded:Set(true)
end

function CmdrService:LockCommand(commandName, byUserId)
	commandName = commandName:lower()

	local command = self.Cmdr.Registry.Commands[commandName]
	if command == nil then
		return 0
	end

	-- If anyone can run this command, don't lock it.
	if canRun.anyGroups[command.Group] then
		return 1, string.format("Cannot lock %q: isn't admin bound.", commandName)
	end
	
	local locked = self._lockedCommands[commandName]
	local admin = selectors.getAdmin(Knit.Store:getState(), byUserId)

	if locked and selectors.getAdmin(Knit.Store:getState(), locked.userId) >= admin then
		return 2, string.format("Cannot lock %q: already locked by an admin of equal or greater rank.", commandName)
	end
	
	self._lockedCommands[commandName] = {userId = byUserId}

	return 3, string.format("Locked %q.", commandName)
end

function CmdrService:UnlockCommand(commandName, byUserId)
	commandName = commandName:lower()

	local locked = self._lockedCommands[commandName]
	if locked == nil then
		return 0, string.format("Cannot unlock %q: command isn't locked.", commandName)
	end

	local admin = selectors.getAdmin(Knit.Store:getState(), byUserId)
	local byAdmin = selectors.getAdmin(Knit.Store:getState(), locked.userId)

	if locked and byAdmin > admin then
		local tierName = GameEnum.AdminTiersByValue[byAdmin]
		return 1, string.format("Cannot unlock %q: locked by %s %s.", commandName, LitUtils.getIndefiniteArticle(tierName), tierName)
	end
	
	self._lockedCommands[commandName] = nil

	return 2, string.format("Unlocked %q.", commandName)
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
		Knit.Store:dispatch(actions.setAdmin(player.UserId, GameEnum.AdminTiers.Owner))
	end

	local getRank = Promise.promisify(player.GetRankInGroup)

	-- TOB Ranktester and beyond gets admin.
	getRank(player, 3397136):andThen(function(role)
		if role >= 11 then
			if (Knit.Store:getState().users.admins[player.UserId] or 0) < GameEnum.AdminTiers.Admin then
				Knit.Store:dispatch(actions.setAdmin(player.UserId, GameEnum.AdminTiers.Admin))
			end
		end
	end):finally(function()
		player:SetAttribute("IsCmdrLoaded", true)
	end)
end

return CmdrService