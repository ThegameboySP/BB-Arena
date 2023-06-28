local bodyColors = Instance.new("BodyColors")
bodyColors.HeadColor3 = BrickColor.new("Bright yellow").Color
bodyColors.LeftArmColor3 = BrickColor.new("Bright yellow").Color
bodyColors.RightArmColor3 = BrickColor.new("Bright yellow").Color
bodyColors.LeftLegColor3 = BrickColor.new("Br. yellowish green").Color
bodyColors.RightLegColor3 = BrickColor.new("Br. yellowish green").Color
bodyColors.TorsoColor3 = BrickColor.new("Bright blue").Color

local face = Instance.new("Decal")
face.Texture = "rbxasset://textures/face.png"
face.Name = "face"

local folder = Instance.new("Folder")
bodyColors.Parent = folder
face.Parent = folder

return folder
