local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserService = game:GetService("UserService")
local Players = game:GetService("Players")

local Promise = require(ReplicatedStorage.Packages.Promise)
local getFullPlayerName = require(ReplicatedStorage.Common.Utils.getFullPlayerName)
local Services = require(script.Services)
local Status = require(script.Status)

local Root = {}
Root.__index = Root
Root.isServer = RunService:IsServer()
Root.isTesting = false
Root.Services = Services

function Root.new(replicatedContainer)
	return setmetatable({
		services = Services.new(replicatedContainer),
		status = Status.Uninitialized,

		_infosByUserId = {},
		_userIdsByName = {},
	}, Root)
end

function Root:Start()
	assert(self.status == Status.Uninitialized, "Already started root")

	self.services.isServer = self.isServer

	return self.services:Start(self)
end

function Root:OnStart()
	return self.services:OnStart()
end

function Root:KillCharacter(character, cause)
	local humanoid = character:FindFirstChild("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return
	end

	local player = Players:GetPlayerFromCharacter(character)
	if player == nil then
		return
	end

	-- Override dumb legacy hit info.
	while humanoid:FindFirstChild("creator") do
		humanoid:FindFirstChild("creator").Parent = nil
	end

	while humanoid:FindFirstChildWhichIsA("ForceField") do
		humanoid:FindFirstChildWhichIsA("ForceField").Parent = nil
	end

	humanoid:SetAttribute("DeathCause", cause)

	-- Setting health to 0 will sometimes allow the default health script to heal that frame, preventing death.
	-- Setting health to below 0 doesn't work since it's capped at 0.
	-- You can't directly set a humanoid's state to Dead.
	-- TakeDamage is the only way I know of to get around the above problems.
	humanoid:TakeDamage(math.huge)
end

function Root:GetFullNameByUserId(userId)
	return self:GetUserInfoByUserId(userId):andThen(function(info)
		return getFullPlayerName(info)
	end, function()
		return "#" .. tostring(userId)
	end)
end

function Root:GetUserInfoByUserId(userId)
	local cached = self._infosByUserId[userId]

	if Promise.is(cached) then
		return cached
	elseif cached then
		return Promise.resolve(cached)
	end

	self._infosByUserId[userId] = Promise.new(function(resolve)
		local info = UserService:GetUserInfosByUserIdsAsync({ userId })[1]

		self._infosByUserId[userId] = table.freeze(info)
		self._userIdsByName[info.Username] = userId

		resolve(info)
	end):catch(function(err)
		warn(tostring(err))
		self._infosByUserId[userId] = nil
	end)

	return self._infosByUserId[userId]
end

function Root:GetUserIdByName(name)
	local cached = self._userIdsByName[name]

	if Promise.is(cached) then
		return cached
	elseif cached then
		return Promise.resolve(cached)
	end

	self._userIdsByName[name] = Promise.new(function(resolve)
		local userId = Players:GetUserIdFromNameAsync(name)
		self._userIdsByName[name] = userId

		resolve(userId)
	end)

	return self._userIdsByName[name]
end

function Root:GetService(name)
	return self.services:GetService(name)
end

function Root:GetSingleton(name)
	return self.services:GetSingleton(name)
end

function Root:GetServerService(name)
	return self.services:GetServerService(name)
end

return Root.new()
