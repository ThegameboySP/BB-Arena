local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local t = require(ReplicatedStorage.Packages.t)
local Component = require(ReplicatedStorage.Common.Component).Component
local Raycaster = require(ReplicatedStorage.Common.Raycaster)
local General = require(ReplicatedStorage.Common.Utils.General)
local Bin = require(ReplicatedStorage.Common.Utils.Bin)

local S_CTF_Flag = Component:extend("CTF_Flag", {
    realm = "server";
	UpdateEvent = RunService.Heartbeat;

    checkConfig = t.interface({
        DespawnTime = t.number;
    });
})

-- Flag is slightly on the back of the player.
local FLAG_CHARACTER_OFFSET = CFrame.new(0.27, -1.50, 1.03, 0.70, -0.71, 0, 0.71, 0.71, 0, 0, 0, 1)
local FLAG_STAND_OFFSET = CFrame.new(0, 2.9, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1)
local DROPPED_DEBOUNCE = 0.4

local function weldToCharacter(flag, character)
	local weld = Instance.new("Weld")
	weld.Part0 = character.Head
	weld.Part1 = flag
	weld.C0 = FLAG_CHARACTER_OFFSET
	weld.Parent = character.Head

	return weld
end

function S_CTF_Flag:_dockFlag()
	self.Instance.CFrame = self._stand.Instance.CFrame * FLAG_STAND_OFFSET
end

function S_CTF_Flag:OnTouchdown(player)
	self:_changeState("Docked")
	self.Captured:Fire(player)
end

function S_CTF_Flag:OnReturn()
	self:_changeState("Docked")
end

function S_CTF_Flag:OnInit()
	local flag = self.Instance

	-- For external code.
	flag.Name = "Flag"
	
    self.bin = Bin.new()
    self.Docked = self:Signal()
    self.Dropped = self:Signal()
    self.PickedUp = self:Signal()
    self.Captured = self:Signal()
    self.Stolen = self:Signal()
    self.Recovered = self:Signal()
    self.TimedOut = self:Signal()
	
	self:RemoteEvent("PickedUp")

    self:RemoteEvent("Drop").OnServerEvent:Connect(function(player)
        if player == self.State.EquippingPlayer and self.State.State ~= "Dropped" then
            self:_changeState("Dropped")
		end
    end)
	
	self._droppedTime = 0
	self._stand = self.Manager:GetComponent(self.Instance.Parent, "CTF_FlagStand")
	if self._stand == nil then
		task.spawn(error, "Could not find flag stand under " .. self.Instance:GetFullName())
	end
	
	flag.CanCollide = false
	flag.Anchored = false
	flag.Massless = true
	flag.Parent = self._stand.Instance

	local pointLight = Instance.new("PointLight")
	pointLight.Shadows = true
	pointLight.Brightness = 8
	pointLight.Range = 10
	pointLight.Enabled = false
	pointLight.Parent = flag

	local texture = Instance.new("Texture")
	texture.Texture = flag:IsA("MeshPart") and flag.TextureID or flag.Mesh.TextureId
	texture.Parent = flag
	flag.Mesh.TextureId = ""
	flag.Material = Enum.Material.Neon
end

function S_CTF_Flag:OnStart()
	local team = self._stand.State.Team
	self:SetState({Team = team})
	
	self.Instance.Color = team.TeamColor.Color
	self.Instance.PointLight.Color = team.TeamColor.Color
	
	self:_changeState("Docked")
end

function S_CTF_Flag:_changeState(state, ...)
	if self.State.State == state then
		return
	end

	local method = self["_" .. state:sub(1, 1):lower() .. state:sub(2, -1)]
	if type(method) == "function" then
		method(self, Bin.new(), ...)
	else
		error(state .. " is not a valid state")
	end
end

function S_CTF_Flag:_dropped(bin)
    self.bin:AddId(bin, "stateBin")
	self.bin:Remove("weld")
	
	self.Instance.Parent = Workspace
	self.Instance.Anchored = true
	self.Instance.PointLight.Enabled = true
	
	local oldPlayer = self.State.EquippingPlayer
	self:SetState({
		State = "Dropped",
		EquippingPlayer = false,
		TimeLeft = self.Config.DespawnTime
	})
	
	local droppedTime = os.clock()
	bin:Add(self.Instance.Touched:Connect(function(part)
		if (os.clock() - droppedTime) <= DROPPED_DEBOUNCE then
			return
		end

		local player, character = General.getPlayerFromHitbox(part)
		if not player or not General.isValidCharacter(character) then
			return
		end
		
		if player.Team == self.State.Team then
			local pos = self.Instance.Position
			
			self:_changeState("Docked")
			self.Recovered:Fire(player, pos)
        elseif not self.Manager:GetComponent(character:FindFirstChild("Flag"), S_CTF_Flag) then
			self:_changeState("Carrying", player)
		end
	end))
	
	bin:Add(self.Instance.AncestryChanged:Connect(function()
		self:_changeState("Docked")
	end))

	bin:Add(self.UpdateEvent:Connect(function(dt)
		self:SetState({TimeLeft = self.State.TimeLeft - dt})
		
		if self.State.TimeLeft <= 0 then
			local oldPos = self.Instance.Position
			self:_changeState("Docked")

			self.TimedOut:Fire(oldPos)
		end
	end))
	
	local result = Raycaster.withFilter(self.Instance.Position, Vector3.yAxis * -100, nil, function(instance)
		return instance ~= self.Instance and not General.getCharacter(instance)
	end)
	
	if not result then
		self:_changeState("Docked")
		return
	end
	
	local pos = result.Position + Vector3.yAxis * 0.5
	self.Instance.CFrame = CFrame.lookAt(pos, pos + Vector3.yAxis * 1)
	
	self.Dropped:Fire(oldPlayer)
end

function S_CTF_Flag:_docked(bin)
	self.bin:AddId(bin, "stateBin")
    self.bin:Remove("weld")
	
	self.Instance.Parent = self._stand.Instance
	self.Instance.Anchored = true
	self.Instance.PointLight.Enabled = false
	self:_dockFlag()
	
	local oldPlayer = self.State.EquippingPlayer
	self:SetState({
		State = "Docked",
		EquippingPlayer = false
	})
	
	bin:Add(self.Instance.Touched:Connect(function(part)
		local player, character = General.getPlayerFromHitbox(part)
		if not player or not General.isValidCharacter(character) then
			return
		end
		
		if
			player.Team == self.State.Team
			or self.Manager:GetComponent(character:FindFirstChild("Flag"), S_CTF_Flag)
		then
			return
		end
		
		self:_changeState("Carrying", player)
		self.Stolen:Fire(player)
	end))

	self.Docked:Fire(oldPlayer)
end

function S_CTF_Flag:_carrying(bin, player)
	local character = player.Character
	
	self.bin:AddId(bin, "stateBin")
    bin:Add(weldToCharacter(self.Instance, character))
	
	self.Instance.Parent = character
	self.Instance.Anchored = false
	self.Instance.PointLight.Enabled = true

	self:SetState({
		State = "Carrying",
		EquippingPlayer = player
	})
	
	bin:Add(player.AncestryChanged:Connect(function()
		self:_changeState("Dropped")
	end))
	
	bin:Add(character.AncestryChanged:Connect(function()
		self:_changeState("Dropped")
	end))

	bin:Add(player:GetPropertyChangedSignal("Team"):Connect(function()
		self:_changeState("Dropped")
	end))
	
	local humanoid = character:FindFirstChild("Humanoid")
	if humanoid then
		bin:Add(humanoid.StateChanged:Connect(function(_, newState)
			if newState == Enum.HumanoidStateType.Dead then
				-- task.defer(function()
					self:_changeState("Dropped")
				-- end)
			end
		end))
	else
		self:_changeState("Dropped")
	end
	
	self:RemoteEvent("PickedUp"):FireAllClients(player)
	self.PickedUp:Fire(player)
end

return S_CTF_Flag