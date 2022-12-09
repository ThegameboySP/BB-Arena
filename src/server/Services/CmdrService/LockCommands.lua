local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local CmdrArena = ServerScriptService.Server.Cmdr.Arena
local canRun = require(CmdrArena.Hooks.canRun)

local GameEnum = require(ReplicatedStorage.Common.GameEnum)
local LitUtils = require(ReplicatedStorage.Common.Utils.LitUtils)
local RoduxFeatures = require(ReplicatedStorage.Common.RoduxFeatures)
local selectors = RoduxFeatures.selectors

local LockCommands = {}
LockCommands.__index = LockCommands

function LockCommands.new(store)
	return setmetatable({
		_store = store,
		_lockedCommands = {},
	}, LockCommands)
end

function LockCommands:beforeRun(executorId, command)
	if command == nil then
		return
	end

	local locked = self._lockedCommands[command.Name:lower()]
	if not locked or executorId == nil then
		return
	end

	local state = self._store:getState()
	local byAdmin = selectors.getAdmin(state, locked.userId)

	if selectors.getAdmin(state, executorId) < byAdmin then
		local tierName = GameEnum.AdminTiersByValue[byAdmin]
		return string.format("This command is locked by %s %s.", LitUtils.getIndefiniteArticle(tierName), tierName)
	end
end

function LockCommands:lockCommand(byUserId, command)
	if command == nil then
		return "No command found that matches that name"
	end

	local commandName = command.Name:lower()

	-- If anyone can run this command, don't lock it.
	if canRun.anyGroups[command.Group] then
		return string.format("Cannot lock %q: isn't admin bound.", commandName)
	end

	local lockedBy = self._lockedCommands[commandName]
	local admin = selectors.getAdmin(self._store:getState(), byUserId)

	if lockedBy and selectors.getAdmin(self._store:getState(), lockedBy.userId) >= admin then
		return string.format("Cannot lock %q: already locked by an admin of equal or greater rank.", commandName)
	end

	self._lockedCommands[commandName] = { userId = byUserId }

	return string.format("Locked %q.", commandName)
end

function LockCommands:unlockCommand(byUserId, command)
	if command == nil then
		return "No command found that matches that name"
	end

	local commandName = command.Name:lower()

	local lockedBy = self._lockedCommands[commandName]
	if lockedBy == nil then
		return string.format("Cannot unlock %q: command isn't locked.", commandName)
	end

	local admin = selectors.getAdmin(self._store:getState(), byUserId)
	local byAdmin = selectors.getAdmin(self._store:getState(), lockedBy.userId)

	if lockedBy and byAdmin > admin then
		local tierName = GameEnum.AdminTiersByValue[byAdmin]
		return string.format(
			"Cannot unlock %q: locked by %s %s.",
			commandName,
			LitUtils.getIndefiniteArticle(tierName),
			tierName
		)
	end

	self._lockedCommands[commandName] = nil

	return string.format("Unlocked %q.", commandName)
end

return LockCommands
