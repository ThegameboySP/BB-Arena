local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Signal = require(ReplicatedStorage.Packages.Signal)
local Effects = require(ReplicatedStorage.Common.Utils.Effects)
local RoduxFeatures = require(ReplicatedStorage.Common.RoduxFeatures)
local getLocalSetting = RoduxFeatures.selectors.getLocalSetting

local function filterProjectile(proj)
	local name = proj.Name:lower()

	return proj:IsA("BasePart")
		and (
			name:find("rocket")
			or name:find("superball")
			or name:find("pellet")
			or name:find("paintball")
			or name:find("bomb")
		)
end

local function neonTools(root)
	local changed = Signal.new()

	local function applyNeon(part)
		local function update()
			if getLocalSetting(root.Store:getState(), "neonWeapons") then
				part.Material = Enum.Material.Neon
			else
				part.Material = Enum.Material.Plastic
			end
		end

		update()

		-- The toolset will try to sync a superball's material, so a brute force method is used.
		local connection = part:GetPropertyChangedSignal("Material"):Connect(update)
		local updateConnection = changed:Connect(update)

		return function()
			connection:Disconnect()
			updateConnection:Disconnect()
		end
	end

	local function onChanged(new, old)
		if not old or getLocalSetting(new, "neonWeapons") ~= getLocalSetting(old, "neonWeapons") then
			changed:Fire()
		end
	end

	root.StoreChanged:Connect(onChanged)

	Effects.call(
		workspace:WaitForChild("Projectiles"):WaitForChild("Active"),
		Effects.pipe({
			Effects.children,
			Effects.childrenFilter(filterProjectile),
			applyNeon,
		})
	)

	Effects.call(
		workspace:WaitForChild("Projectiles"):WaitForChild("Extrapolated"),
		Effects.pipe({
			Effects.childrenFilter(filterProjectile),
			applyNeon,
		})
	)

	Effects.call(
		Players,
		Effects.pipe({
			Effects.children,
			Effects.character,
			Effects.childrenFilter(function(child)
				return child:IsA("Tool")
			end),
			Effects.childrenFilter(function(child)
				return child:IsA("BasePart") and child.Name == "Handle"
			end),
			applyNeon,
		})
	)
end

return neonTools
