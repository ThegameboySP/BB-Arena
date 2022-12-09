local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local ContentProvider = game:GetService("ContentProvider")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Promise = require(ReplicatedStorage.Packages.Promise)
local Skybox = ReplicatedStorage.Assets.Prefabs.Skybox

local FakeSkybox = {}
FakeSkybox.__index = FakeSkybox

function FakeSkybox.new()
	local viewportFrame = Instance.new("ViewportFrame")
	local skybox = Skybox:Clone()
	skybox:SetPrimaryPartCFrame(CFrame.new())
	scaleModel(skybox, 500)
	skybox.Parent = viewportFrame

	local newCamera = Instance.new("Camera")
	newCamera.CFrame = CFrame.new(Vector3.new(), skybox.PrimaryPart.CFrame.LookVector)
	newCamera.Parent = viewportFrame

	viewportFrame.CurrentCamera = newCamera
	viewportFrame.Size = UDim2.fromScale(1, 1)
	viewportFrame.BackgroundColor3 = Color3.new(0, 0, 0)
	viewportFrame.BorderColor3 = Color3.new(0, 0, 0)
	viewportFrame.BackgroundTransparency = 0
	viewportFrame.BorderSizePixel = 0
	viewportFrame.Ambient = Color3.new(1, 1, 1)
	viewportFrame.LightColor = Color3.new(0, 0, 0)
	viewportFrame.ZIndex = 0
	viewportFrame.Name = "FakeSkybox"

	return setmetatable({
		_viewport = viewportFrame,
		_skybox = skybox,
	}, FakeSkybox)
end

function FakeSkybox:Destroy()
	self._viewport:Destroy()
end

function FakeSkybox:_cleanup()
	if self._cleanupFn then
		self._cleanupFn()
	end
end

function FakeSkybox:Adorn(gui, root)
	self:_cleanup()

	local camera
	local function onCurrentCameraChanged()
		camera = root.CurrentCamera
	end

	local camConnection = root:GetPropertyChangedSignal("CurrentCamera"):Connect(onCurrentCameraChanged)
	onCurrentCameraChanged()

	local viewport = self._viewport
	local id = HttpService:GenerateGUID()
	RunService:BindToRenderStep(id, Enum.RenderPriority.Last.Value, function()
		if viewport.Visible == false or viewport.ImageTransparency == 1 then
			return
		end
		local CF = camera.CFrame
		local offset = CFrame.fromMatrix(Vector3.new(0, 0, 0), CF.RightVector, CF.UpVector, -CF.LookVector)
		viewport.CurrentCamera.CFrame = offset
	end)

	self._cleanupFn = function()
		RunService:UnbindFromRenderStep(id)
		viewport.Parent = nil
		camConnection:Disconnect()
	end

	viewport.Parent = gui
end

function FakeSkybox:GetRoot()
	return self._viewport
end

function FakeSkybox:SetZIndex(zIndex)
	self._viewport.ZIndex = zIndex
end

function FakeSkybox:SetSky(sky)
	return Promise.new(function(resolve)
		-- Roblox won't detect skies as having preloadable properties...
		local folder = Instance.new("Folder")
		Instance.new("Decal", folder).Texture = sky.SkyboxLf
		Instance.new("Decal", folder).Texture = sky.SkyboxRt
		Instance.new("Decal", folder).Texture = sky.SkyboxBk
		Instance.new("Decal", folder).Texture = sky.SkyboxDn
		Instance.new("Decal", folder).Texture = sky.SkyboxUp
		Instance.new("Decal", folder).Texture = sky.SkyboxFt

		ContentProvider:PreloadAsync(folder:GetChildren(), resolve)
	end):andThen(function()
		for _, part in pairs(self._skybox:GetChildren()) do
			if part:IsA("BasePart") then
				local name = part.Name
				local texture = sky["Skybox" .. name]
				part.Decal.Texture = texture
			end
		end
	end)
end

function scaleModel(model, scale)
	if scale ~= 1 then
		for _, v in next, model:GetDescendants() do
			if v:IsA("BasePart") then
				v.Size = v.Size * scale
				v.Position = v.Position * scale
			elseif v:IsA("JointInstance") then
				local C0, C1 = v.C0, v.C1
				v.C0 = C0 + (C0.p * (scale - 1))
				v.C1 = C1 + (C1.p * (scale - 1))
			elseif v:IsA("DataModelMesh") then
				if v:IsA("SpecialMesh") and v.MeshType == Enum.MeshType.FileMesh then
					v.Scale = v.Scale * scale
				end
				v.Offset = v.Offset * scale
			elseif v:IsA("Attachment") then
				v.Position = v.Position * scale
			end
		end
	end
end

return FakeSkybox
