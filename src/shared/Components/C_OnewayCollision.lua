local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local t = require(ReplicatedStorage.Packages.t)
local Component = require(ReplicatedStorage.Common.Component).Component
local BoundingBox = require(ReplicatedStorage.Common.Utils.BoundingBox)
local Bin = require(ReplicatedStorage.Common.Utils.Bin)

local C_OneWayCollision = Component:extend("OneWayCollision", {
    realm = "client";
    checkConfig = t.strictInterface({
        Side = t.string;
        Bias = t.optional(t.number);
    })
})

local NOOP = function() end

function C_OneWayCollision:OnInit()
    self.bin = Bin.new()
	self.normal = Vector3.fromNormalId(Enum.NormalId[self.Config.Side])
	self.bias = self.Config.bias or 0
end

function C_OneWayCollision:OnDestroy()
    self.bin:DoCleaning()
end

local charParts = {}
local cMaid = Bin.new()

local function onCharacterAdded(character)
	cMaid:DoCleaning()
	table.clear(charParts)

	local function onChildAdded(child)
		if not child:IsA("BasePart") then return end
		table.insert(charParts, child)
	end
	cMaid:Add(character.ChildAdded:Connect(onChildAdded))
	for _, child in next, character:GetChildren() do
		onChildAdded(child)
	end

	cMaid:Add(character.ChildRemoved:Connect(function(child)
		if not child:IsA("BasePart") then return end
		table.remove(charParts, table.find(charParts, child))
	end))
end

function C_OneWayCollision:OnStart()
    local descendants = self.Instance:GetDescendants()
    table.insert(descendants, self.Instance)

    local descendantParts = {}
    for _, descendant in descendants do
        if descendant:IsA("BasePart") then
            table.insert(descendantParts, descendant)
        end
    end

	for _, part in next, descendantParts do
		self.bin:Add(part.Touched:Connect(NOOP)) -- setup TouchInterest
	end
	
	local bx1, by1, bz1, bx2, by2, bz2 = BoundingBox.getMinMax(descendantParts)
	bx1, by1, bz1, bx2, by2, bz2 = bx1 - 0.5, by1 - 2, bz1 - 0.5, bx2 + 0.5, by2 + 2, bz2 + 0.5
	
	local partsAbove = {}
	self.bin:Add(Players.LocalPlayer.CharacterAdded:Connect(onCharacterAdded))
	if Players.LocalPlayer.Character then
		onCharacterAdded(Players.LocalPlayer.Character)
	end
	
	local normal = self.normal
	local bias = self.bias
	local callback = function()
		local char = Players.LocalPlayer.Character
		if not char then return end
		local pPart = char.PrimaryPart
		if not pPart then return end

		local charPos, charSize, ax1, ay1, az1, ax2, ay2, az2 = BoundingBox.getAABB(charParts)
		charSize *= 0.9 -- Reduce by some arbitrary value to allow necessary breathing room
		local hCharSize = charSize / 2
		
		if not BoundingBox.isAABBIntersecting(ax1, ay1, az1, ax2, ay2, az2, bx1, by1, bz1, bx2, by2, bz2) then
			for _, part in next, descendantParts do
				local CF = part.CFrame
				local planePoint = CF:PointToWorldSpace(normal * (part.Size / 2))
				local wNormal = CF:VectorToWorldSpace(normal)
				planePoint -= wNormal * bias -- breathing room
				local furthestCharPoint = charPos - wNormal * hCharSize

				local above = BoundingBox.isAbove(furthestCharPoint, planePoint, wNormal)
				part.CanCollide = above
				partsAbove[part] = above
			end
			
			return
		end

		local vel = pPart.Velocity
		local velMag = vel.Magnitude
		local velUnit = vel.Unit

		for _, part in next, descendantParts do
			if partsAbove[part] then
				-- If currently on solid part, do not toggle the collision mid-way.
				-- In practice, this seems to help a single false positive from making a player fall.
                local isTouching = false
                for _, touching in part:GetTouchingParts() do
                    if touching.Parent == char then
                        isTouching = true
                        break
                    end
                end

				if isTouching then
					part.CanCollide = true
					return
				end
			end

			local CF = part.CFrame
			local wNormal = CF:VectorToWorldSpace(normal)
			-- If speeding towards solid part, set its collision no matter what.
			if velMag > 20 and velUnit:Dot(-wNormal) > 0 then
				part.CanCollide = true
			else
				local planePoint = CF:PointToWorldSpace(normal * (part.Size / 2))
				planePoint -= wNormal * bias -- breathing room
				local furthestCharPoint = charPos - wNormal * hCharSize

				local above = BoundingBox.isAbove(furthestCharPoint, planePoint, wNormal)
				part.CanCollide = above
				partsAbove[part] = above
			end
		end
	end
	
    self.bin:Add(RunService.Heartbeat:Connect(function()
        debug.profilebegin("One way collision")
		callback()
		debug.profileend()
    end))
end

return C_OneWayCollision