local bodyColors = Instance.new("BodyColors")
bodyColors.HeadColor3 = Color3.fromRGB(245, 205, 48)
bodyColors.LeftArmColor3 = Color3.fromRGB(245, 205, 48)
bodyColors.LeftLegColor3 = Color3.fromRGB(18, 18, 18)
bodyColors.RightArmColor3 = Color3.fromRGB(245, 205, 48)
bodyColors.RightLegColor3 = Color3.fromRGB(18, 18, 18)
bodyColors.TorsoColor3 = Color3.fromRGB(18, 18, 18)

local face = Instance.new("Decal")
face.Texture = "rbxasset://textures/face.png"
face.Name = "face"

local folder = Instance.new("Folder")
bodyColors.Parent = folder
face.Parent = folder

return folder
