local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Effects = require(ReplicatedStorage.Common.Utils.Effects)
local RoduxFeatures = require(ReplicatedStorage.Common.RoduxFeatures)
local getLocalSetting = RoduxFeatures.selectors.getLocalSetting

local Trail = script.Trail

local MIN_BEAM_LENGTH = 0.3
local MAX_BEAM_LENGTH = 0.6

local function getPosition(character, name)
	local part = character:FindFirstChild(name)
	if part then
		return part.Position
	end

	return Vector3.zero
end

local function mapTransparency(alpha)
	return NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(math.max(0, 0 + (1 - alpha) * 0.3), 0.6),
		NumberSequenceKeypoint.new(math.max(0, 0 + (1 - alpha) * 0.7), 0.6),
		-- -0.6 is some arbitrary number that will make the beam's length animation look better
		NumberSequenceKeypoint.new(math.clamp(0 + (1 - math.max(0, alpha - 0.6)), 0, 1), 1),
		NumberSequenceKeypoint.new(1, 1),
	})
end

local function onBuildingTrowel(player, pos)
	local character = player.Character

	if character then
		local trail = Trail:Clone()
		local a0 = Instance.new("Attachment")
		local a1 = Instance.new("Attachment")
		trail.Attachment0 = a0
		trail.Attachment1 = a1

		a0.Position = pos
		a1.Position = pos

		local part = Instance.new("Part")
		part.Anchored = true
		part.CanCollide = false
		part.CanTouch = false
		part.CanQuery = false
		part.Name = "TrowelOwnerVisual"

		trail.Parent = part
		a0.Parent = part
		a1.Parent = part
		part.Parent = Workspace

		local startingTime = os.clock()
		local cn
		cn = RunService.Heartbeat:Connect(function()
			local delta = os.clock() - startingTime
			local alpha = TweenService:GetValue(delta / 0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

			if delta > 0.8 or not character.Parent then
				part.Parent = nil
				cn:Disconnect()
				return
			end

			local a0Delta = (getPosition(character, "Head") - pos) * (alpha + 0.003)
			local a1Delta = ((getPosition(character, "Head") - pos) * alpha)
			local a0ClampedDelta = a0Delta.Unit
				* (a1Delta.Magnitude + math.clamp((a0Delta - a1Delta).Magnitude, MIN_BEAM_LENGTH, MAX_BEAM_LENGTH))

			a0.Position = pos + a0ClampedDelta
			a1.Position = pos + a1Delta
			trail.Transparency = mapTransparency(delta / 0.4)
		end)
	end
end

local pipeline = Effects.pipe({
	Effects.children,
	Effects.childrenFilter(function(child)
		return child.Name:lower():find("wall")
	end),
	function(wall)
		local folder = wall:WaitForChild("PhysicsFolder")
		local creator = folder:WaitForChild("creator")

		local connections = {}
		for _, child in wall:GetChildren() do
			if not child:IsA("BasePart") then
				continue
			end

			table.insert(
				connections,
				child:GetPropertyChangedSignal("Anchored"):Connect(function()
					for _, connection in connections do
						connection:Disconnect()
					end

					onBuildingTrowel(creator.Value, child.Position)
				end)
			)
		end

		return function()
			for _, connection in connections do
				connection:Disconnect()
			end
		end
	end,
})

local function buildTrowelDisplay(root)
	local activeProjectiles = Workspace:WaitForChild("Projectiles"):WaitForChild("Active")
	local undo

	local function update(new, old)
		if not old or getLocalSetting(new, "trowelBuildDisplay") ~= getLocalSetting(old, "trowelBuildDisplay") then
			if undo then
				undo()
			end

			if getLocalSetting(new, "trowelBuildDisplay") then
				undo = Effects.call(activeProjectiles, pipeline)
			end
		end
	end

	root.StoreChanged:Connect(update)
	update(root.Store:getState(), nil)
end

return buildTrowelDisplay
