local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local t = require(ReplicatedStorage.Packages.t)
local Component = require(ReplicatedStorage.Common.Component).Component
local General = require(ReplicatedStorage.Common.Utils.General)

local Water = Component:extend("Water", {
	realm = "client",

	checkConfig = t.interface({
		StudsScale = t.number,
		Color = t.optional(t.Color3),
		NoRipples = t.optional(t.boolean),
		UnderColor = t.optional(t.Color3),
	}),
})

local Ripples = Instance.new("Texture")
Ripples.Texture = "rbxassetid://6471130103"
Ripples.Transparency = 0.45
Ripples.StudsPerTileU = 4
Ripples.StudsPerTileV = 4

local OFFSET_RATIO_U = 0.25
local OFFSET_RATIO_V = 0.375
local DEFAULT_SPEED = 0.05

function Water:OnDestroy()
	for _, connection in self._connections do
		connection:Disconnect()
	end
end

function Water:OnInit()
	self._connections = {}

	local instance = self.Instance
	instance.CanCollide = false
	instance.CastShadow = false
	instance.Material = Enum.Material.Fabric

	local config = self.Config
	config.Speed = config.Speed or DEFAULT_SPEED
	config.NoRipples = not not config.NoRipples
	config.UnderColor = config.UnderColor or Color3.new()
	config.Color = config.Color or Color3.fromRGB(39, 151, 255)

	local scale = config.StudsScale
	if not config.NoRipples then
		instance.Transparency = 1

		local ripples = Ripples:Clone()
		ripples.Color3 = self.Config.Color

		setupTopLayer(ripples, instance, scale)
		self._bottomLayer = setupBottomLayer(ripples, instance, scale)
	end
end

function Water:Animate(tex, dir)
	local config = self.Config
	local size = Vector2.new(tex.StudsPerTileU, tex.StudsPerTileV)

	table.insert(
		self._connections,
		RunService.RenderStepped:Connect(function(dt)
			tex.OffsetStudsU = (size.X * dir.X * (dt * config.Speed) + tex.OffsetStudsU) % size.X
			tex.OffsetStudsV = (size.Y * dir.Y * (dt * config.Speed) + tex.OffsetStudsV) % size.Y
		end)
	)
end

function Water:OnStart()
	if not self.Config.NoRipples then
		self:Animate(self.Instance.Top, Vector2.new(1, -1))
		self:Animate(self.Instance.Bottom, Vector2.new(1, -1))
		self:Animate(self._bottomLayer.Top, Vector2.new(-1, 1))
		self:Animate(self._bottomLayer.Bottom, Vector2.new(-1, 1))
	end
end

function setupLayer(instance, index)
	local CF = instance.CFrame
	local bottomLayer = instance:Clone()
	bottomLayer:ClearAllChildren()
	bottomLayer.CFrame = CFrame.fromMatrix(
		instance.Position + Vector3.new(0, 0.05 * index, 0),
		CF.RightVector,
		CF.UpVector,
		-CF.LookVector
	)
	bottomLayer.Anchored = false
	bottomLayer.Name = "WaterLayer"

	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Brick
	mesh.Scale = Vector3.new(2000, 1, 2000)
	mesh.Parent = bottomLayer

	General.weld(instance, bottomLayer)
	return bottomLayer
end

function setupTexture(ripples, scale, face)
	local tex = ripples:Clone()
	tex.StudsPerTileU = scale
	tex.StudsPerTileV = scale
	tex.Face = face
	tex.Name = face
	return tex
end

function setupBottomLayer(ripples, instance, scale)
	local function applyDifference(tex)
		tex.OffsetStudsU = tex.StudsPerTileU * OFFSET_RATIO_U
		tex.OffsetStudsV = tex.StudsPerTileV * OFFSET_RATIO_V
		return tex
	end
	local tex = applyDifference(setupTexture(ripples, scale, "Top"))
	local tex2 = applyDifference(setupTexture(ripples, scale, "Bottom"))

	local bottomLayer = setupLayer(instance, -1)
	tex.Parent = bottomLayer
	tex2.Parent = bottomLayer

	bottomLayer.Parent = instance.Parent
	return bottomLayer
end

function setupTopLayer(ripples, instance, scale)
	local tex = setupTexture(ripples, scale, "Top")
	local tex2 = setupTexture(ripples, scale, "Bottom")

	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Brick
	mesh.Scale = Vector3.new(2000, 1, 2000)
	mesh.Parent = instance

	tex.Parent = instance
	tex2.Parent = instance
end

return Water
