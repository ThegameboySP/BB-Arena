local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer
local Wall = script.Wall

local RoduxFeatures = require(ReplicatedStorage.Common.RoduxFeatures)
local Effects = require(ReplicatedStorage.Common.Utils.Effects)

local FROM_COLOR = Color3.fromRGB(225, 225, 225)
local TO_COLOR = Color3.fromRGB(255, 255, 255)

local function snap(Vector)
	return (math.abs(Vector.x) > math.abs(Vector.z))
			and ((Vector.x > 0) and Vector3.new(1, 0, 0) or Vector3.new(-1, 0, 0))
		or ((Vector.z > 0) and Vector3.new(0, 0, 1) or Vector3.new(0, 0, -1))
end

local function makeWall()
	local wall = Wall:Clone()

	for _, descendant in pairs(wall:GetDescendants()) do
		if descendant:IsA("JointInstance") then
			descendant.Parent = nil
		elseif descendant:IsA("BasePart") then
			descendant.Anchored = true
			descendant.CanCollide = false
			descendant.CanTouch = false
			descendant.CanQuery = false
			descendant.CastShadow = false
			descendant.Transparency = 1
		end
	end

	local adornment = Instance.new("SelectionBox")
	adornment.Adornee = wall:FindFirstChild("Brick")
	adornment.Color3 = Color3.new(1, 1, 1)
	adornment.LineThickness = 0.1
	adornment.Transparency = 0.5
	adornment.Parent = wall

	return wall
end

local pipeline = Effects.pipe({
	Effects.character,
	Effects.childrenFilter(function(child)
		return child:IsA("Tool") and child.Name == "Trowel"
	end),
})

local function trowelVisualizer(root)
	-- Kennystar's dope code
	local Targeting =
		require(LocalPlayer.PlayerScripts:WaitForChild("ToolObjects"):WaitForChild("Core"):WaitForChild("Targeting"))

	local wall = makeWall()
	local equippingCharacter = nil

	pipeline(Players.LocalPlayer, function(tool)
		equippingCharacter = tool.Parent
	end, function()
		equippingCharacter = nil
	end)

	RunService.Heartbeat:Connect(function()
		if not equippingCharacter then
			wall.Parent = nil
			return
		end

		local isEnabled = RoduxFeatures.selectors.getLocalSetting(root.Store:getState(), "trowelVisualization")

		if not isEnabled then
			wall.Parent = nil
			return
		end

		local head = equippingCharacter:FindFirstChild("Head")
		if not head then
			wall.Parent = nil
			return
		end

		wall.Parent = Workspace

		local pos = UserInputService:GetMouseLocation()
		local _, worldPos = Targeting:Get3DPosition(pos.X, pos.Y, true)

		local vectorConstructor =
			Vector3.new(math.ceil(worldPos.X - 0.5), math.floor(worldPos.Y * 100) * 0.01, math.ceil(worldPos.Z - 0.5))

		local lookAt = snap((vectorConstructor - head.Position).Unit)
		local cf = CFrame.new(vectorConstructor, vectorConstructor + lookAt)
		wall:PivotTo(cf)

		local alpha = math.sin(os.clock())
		local color = FROM_COLOR:lerp(TO_COLOR, alpha)

		for _, descendant in pairs(wall:GetDescendants()) do
			if descendant:IsA("BasePart") then
				descendant.Color = color
			elseif descendant:IsA("SelectionBox") then
				local selectionColor = color:lerp(Color3.new(0.8, 0, 1), 0.2)
				descendant.Color3 = selectionColor
			end
		end
	end)
end

return trowelVisualizer
