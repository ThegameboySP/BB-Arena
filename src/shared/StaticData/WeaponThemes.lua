local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WeaponThemes = ReplicatedStorage:FindFirstChild("Assets"):FindFirstChild("WeaponThemes")
local CustomWeaponThemes = ReplicatedStorage:FindFirstChild("Place"):FindFirstChild("WeaponThemes")

local themes = {
	Normal = true,
}

for _, child in WeaponThemes:GetChildren() do
	themes[child.Name] = true
end

for _, child in CustomWeaponThemes:GetChildren() do
	themes[child.Name] = true
end

return themes
