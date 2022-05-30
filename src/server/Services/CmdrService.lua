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
	kick = true;
	thru = true;
	respawn = true;
	replace = true;
}

function CmdrService:CanRun(player, group)
	return canRun(Knit.Store:getState().users.admins, player, group)
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
	
	registerArenaTypes(Cmdr.Registry, Knit.GetService("MapService").Client.MapInfo:Get())

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
	
	local lockedCommands = self._lockedCommands
	Cmdr:RegisterHook("BeforeRun", function(context)
		local locked = lockedCommands[context.Name]
		if not locked then
			return
		end
		
		if context.Executor == nil then
			return
		end
		
		if selectors.canUserBeKickedBy(Knit.Store:getState(), context.Executor.UserId, locked.admin) then
			local tierName = GameEnum.AdminTierByValue[locked.admin]
			return string.format("This command is locked by %s %s.", LitUtils.getIndefiniteArticle(tierName), tierName)
		end
	end)
	
	-- Replicate to all clients.
	CmdrArena.Hooks.Parent = CmdrReplicated
	CmdrArena.registerTypes.Parent = CmdrReplicated
	self.Client.CmdrLoaded:Set(true)
end

function CmdrService:SaveAdminTier(userId, adminTier)

end

local BLACKLISTED_LOCKED_COMMANDS = {
	help = true;
	logs = true;
}
function CmdrService:LockCommand(commandName, executor)
	if BLACKLISTED_LOCKED_COMMANDS[commandName:lower()] then
		return false, "Cannot lock this command!"
	end
	
	local locked = self._lockedCommands[commandName]
	local admin = executor:GetAttribute("AdminIndex") or 0
	if locked and locked.admin >= admin then
		return false, "Already locked!"
	end
	
	self._lockedCommands[commandName] = {admin = admin}
	return true, "Locked!"
end

function CmdrService:UnlockCommand(commandName, executor)
	local locked = self._lockedCommands[commandName]
	local admin = executor:GetAttribute("AdminIndex") or 0
	if locked and locked.admin > admin then
		return false, ("Can't unlock a command locked by %s!"):format(GameEnum.AdminTierByValue[locked.admin])
	end

	if self._lockedCommands[commandName] == nil then
		return false, "Not locked!"
	end
	
	self._lockedCommands[commandName] = nil
	return true, "Unlocked!"
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