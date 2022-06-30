local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local BoundingCylinder = require(ReplicatedStorage.Common.Utils.BoundingCylinder)
local Component = require(ReplicatedStorage.Common.Component).Component
local General = require(ReplicatedStorage.Common.Utils.General)
local Bin = require(ReplicatedStorage.Common.Utils.Bin)
local Signal = require(ReplicatedStorage.Packages.Signal)
local t = require(ReplicatedStorage.Packages.t)

local makeInstances = require(script.makeInstances)
local getCapTimeMultiplier = require(script.getCapTimeMultiplier)

local S_CapturableFlag = Component:extend("CapturableFlag", {
	realm = "server";

	checkConfig = t.interface({
		CaptureTime = t.number;
		RecoverTime = t.number;
		PauseSeconds = t.number;
		Radius = t.number;
		NoBottomCollision = t.optional(t.boolean);
		BottomCollisionHeight = t.optional(t.number);
	});

	checkInstance = t.children({
		FlagHead = t.instanceIsA("BasePart");
		Pole = t.instanceIsA("BasePart");
	});
})

local function getUniqueGroups(groups)
	local uniqueGroups = {}

	for _, group in pairs(groups) do
		if table.find(uniqueGroups, group) then continue end
		table.insert(uniqueGroups, group)
	end

	return uniqueGroups
end

local function getGroupCount(groups, repeatedGroup)
	local count = 0

	for _, group in pairs(groups) do
		if group == repeatedGroup then
			count += 1
		end
	end

	return count
end

function S_CapturableFlag:OnInit()
	local remoteEvent = Instance.new("RemoteEvent")
	remoteEvent.Name = "Captured"
	remoteEvent.Parent = self.Instance

	self.Captured = Signal.new()
	self.Uncaptured = Signal.new()
end

function S_CapturableFlag:OnStart()
	self.bin = Bin.new()
	self._recoverSpeed = 1 / self.Config.RecoverTime
	self._captureSpeed = 1 / self.Config.CaptureTime
	
	for _, basePart in pairs(self.Instance:GetDescendants()) do
		if basePart:IsA("BasePart") then
			basePart.CanCollide = false
		end
	end
	
	self._radiusPart, self._pos, self._height = makeInstances(self.Instance, self.Config.Radius, self.Config.NoBottomCollision, self.Config.BottomCollisionHeight)
	self._radiusPart.Parent = self.Instance
	self.bin:Add(self._radiusPart)

	self:_changeState("settled")
end

function S_CapturableFlag:Destroy()
	self.bin:DoCleaning()
end

function S_CapturableFlag:_changeState(state, ...)
	if self.State.State == state then
		return
	end

	self["_" .. state](self, Bin.new(), ...)
end

function S_CapturableFlag:_incrementOverthrown(inc)
	self:SetState({PercentOverthrown = math.clamp(self.State.PercentOverthrown + inc, 0, 1)})
	return self.State.PercentOverthrown
end

function S_CapturableFlag:_settled(maid, cappedGroup, didCap)
	self.bin:AddId(maid, "stateMaid")
	local oldCappedGroup = self.State.CapturedBy
	self:SetState({
		State = "Settled";
		PercentOverthrown = 0;
		TeammatesCount = 0;
		CapturingGroup = false;
		CapturedBy = cappedGroup or false;
	})

	if cappedGroup then
		if oldCappedGroup and oldCappedGroup ~= cappedGroup then
			self.Uncaptured:Fire()
		end
		
		if didCap then
			self.Captured:Fire(cappedGroup)
			self.Instance.Captured:FireAllClients(cappedGroup)
		end
	end

	maid:Add(RunService.Heartbeat:Connect(function()
		local uniqueGroups = getUniqueGroups(self:_getGroupsInside(self.Whitelisted))
		local cappingGroup = (uniqueGroups[1] and uniqueGroups[1] ~= cappedGroup)
			and uniqueGroups[1] or uniqueGroups[2]
		
		if cappingGroup then
			self:SetState({CapturingGroup = cappingGroup})
			return self:_changeState("paused")
		end
	end))
end

function S_CapturableFlag:_paused(maid)
	self.bin:AddId(maid, "stateMaid")
	self:SetState({State = "Paused"})
	local config = self.Config

	local duration = 0
	maid:Add(RunService.Heartbeat:Connect(function(dt)
		duration += dt
		local uniqueGroups = getUniqueGroups(self:_getGroupsInside(self.Whitelisted))
		local cappingGroup = self.State.CapturingGroup
		local cappedGroup = self.State.CapturedBy

		-- If multiple groups, don't do anything.
		-- If the one group is the capturing group, start capping.
		-- Otherwise, start uncapping.
		if uniqueGroups[1] and uniqueGroups[2] then
			duration = 0
		elseif uniqueGroups[1] then
			if uniqueGroups[1] == cappingGroup and uniqueGroups[1] ~= cappedGroup then
				return self:_changeState("capping", self._captureSpeed)
			else
				return self:_changeState("uncapping", self._captureSpeed)
			end
		end

		self:SetState({TeammatesCount = getGroupCount(uniqueGroups, uniqueGroups[1])})

		if duration >= config.PauseSeconds then
			return self:_changeState("uncapping", self._recoverSpeed)
		end
	end))
end

function S_CapturableFlag:_capping(maid, speed)
	self.bin:AddId(maid, "stateMaid")
	self:SetState({State = "Capping"})

	maid:Add(RunService.Heartbeat:Connect(function(dt)
		local groups = self:_getGroupsInside(self.Whitelisted)
		local uniqueGroups = getUniqueGroups(groups)
		local cappingGroup = self.State.CapturingGroup

		if
			uniqueGroups[1] == nil
			or uniqueGroups[1] ~= cappingGroup
			or uniqueGroups[2]
		then
			return self:_changeState("paused")
		end

		local count = getGroupCount(groups, uniqueGroups[1])
		local percent = self:_incrementOverthrown(
			speed * dt * getCapTimeMultiplier(count)
		)

		self:SetState({TeammatesCount = count})

		if percent >= 1 then
			self:_changeState("settled", cappingGroup, true)
		end
	end))
end

function S_CapturableFlag:_uncapping(maid, speed)
	self.bin:AddId(maid, "stateMaid")
	self:SetState({
		State = "Uncapping";
	})
	
	maid:Add(RunService.Heartbeat:Connect(function(dt)
		local groups = self:_getGroupsInside(self.Whitelisted)
		local uniqueGroups = getUniqueGroups(groups)
		local cappingGroup = self.State.CapturingGroup
		
		if
			uniqueGroups[1] == cappingGroup
			or uniqueGroups[2]
		then
			return self:_changeState("paused")
		end

		local count = getGroupCount(groups, uniqueGroups[1])
		local percent = self:_incrementOverthrown(
			-speed * dt * getCapTimeMultiplier(count)
		)
	
		self:SetState({TeammatesCount = count})

		if percent <= 0 then
			self:_changeState("settled", self.State.CapturedBy, false)
		end
	end))
end

function S_CapturableFlag:GetPlayersInside(whitelisted)
	local players = {}

	for _, player in pairs(Players:GetPlayers()) do
		local char = player.Character
		if not General.isValidCharacter(char) then continue end
		if not BoundingCylinder.isPointIntersecting(
			self._pos, self.Config.Radius, self._height, char.PrimaryPart.Position
		) then continue end
		if whitelisted and not whitelisted[player] then continue end
		if table.find(players, player) then continue end

		table.insert(players, player)
	end

	return players
end

function S_CapturableFlag:GetTeamsInside(whitelisted)
	local teams = {}
	local playersMap = {}

	for _, player in pairs(Players:GetPlayers()) do
		if playersMap[player] then continue end

		local char = player.Character
		if not General.isValidCharacter(char) then continue end
		if not BoundingCylinder.isPointIntersecting(
			self._pos, self.Config.Radius, self._height, char.PrimaryPart.Position
		) then continue end

		local team = player.Team
		if whitelisted and not whitelisted[player.Team] then continue end

		table.insert(teams, team)
	end

	return teams
end

return S_CapturableFlag