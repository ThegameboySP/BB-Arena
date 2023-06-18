local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local SoundService = game:GetService("SoundService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")

local EventBus = require(ReplicatedStorage.Common.EventBus)
local RoduxFeatures = require(ReplicatedStorage.Common.RoduxFeatures)
local getSavedSetting = RoduxFeatures.selectors.getSavedSetting
local getLocalSetting = RoduxFeatures.selectors.getLocalSetting

local LocalPlayer = Players.LocalPlayer

local function respectSettings(root)
	local weaponGroup = SoundService:FindFirstChild("Tools")
	local projectiles = Workspace:FindFirstChild("Projectiles")

	local colorCorrection = Instance.new("ColorCorrectionEffect")
	colorCorrection.Name = "IlluminanceCorrection"
	colorCorrection.Parent = Lighting

	local diedSound

	EventBus.playerDied:Connect(function(player)
		if diedSound then
			local part = player.Character:FindFirstChild("HumanoidRootPart")
			if part then
				local died = part:FindFirstChild("Died")
				if died then
					died.Volume = 0
				end
			end

			root.SoundPlayer:Play3DSound(diedSound, part.Position)
		end
	end)

	local function onDescendantAdded(descendant)
		if descendant:IsA("Sound") then
			if
				descendant:FindFirstAncestorWhichIsA("Tool")
				or descendant:IsDescendantOf(projectiles)
				or descendant:FindFirstAncestor("ToolObjects")
			then
				descendant.SoundGroup = weaponGroup
			end
		end
	end

	game.DescendantAdded:Connect(onDescendantAdded)
	for _, descendant in game:GetDescendants() do
		onDescendantAdded(descendant)
	end

	local function onChanged(new, old)
		assert(new, "New Rodux state was somehow nil")

		if old == nil or getLocalSetting(new, "musicVolume") ~= getLocalSetting(old, "musicVolume") then
			SoundService.Music.Volume = getLocalSetting(new, "musicVolume")
		end

		if old == nil or getLocalSetting(new, "mapVolume") ~= getLocalSetting(old, "mapVolume") then
			SoundService.Map.Volume = getLocalSetting(new, "mapVolume")
		end

		if old == nil or getLocalSetting(new, "gamemodeVolume") ~= getLocalSetting(old, "gamemodeVolume") then
			SoundService.Gamemode.Volume = getLocalSetting(new, "gamemodeVolume")
		end

		if old == nil or getLocalSetting(new, "weaponVolume") ~= getLocalSetting(old, "weaponVolume") then
			weaponGroup.Volume = getLocalSetting(new, "weaponVolume")
		end

		if old == nil or getLocalSetting(new, "lighting") ~= getLocalSetting(old, "lighting") then
			local percent = getLocalSetting(new, "lighting")
			colorCorrection.Brightness = 1 * (percent - 0.5)
			colorCorrection.Contrast = 0.5 * (percent - 0.5)
		end

		if old == nil or getLocalSetting(new, "fieldOfView") ~= getLocalSetting(old, "fieldOfView") then
			Workspace.CurrentCamera.FieldOfView = getLocalSetting(new, "fieldOfView")
		end

		if
			old == nil
			or getLocalSetting(new, "weaponThemeHighGraphics") ~= getLocalSetting(old, "weaponThemeHighGraphics")
		then
			_G.BB.Local.ThemesHighGraphics = getLocalSetting(new, "weaponThemeHighGraphics")
		end

		if old == nil or getLocalSetting(new, "weaponTheme") ~= getLocalSetting(old, "weaponTheme") then
			LocalPlayer:WaitForChild("Theme").Value = getLocalSetting(new, "weaponTheme")
		end

		if old == nil or getLocalSetting(new, "dieSound") ~= getLocalSetting(old, "dieSound") then
			local dieSoundId = getLocalSetting(new, "dieSound")
			if dieSoundId then
				local sound = Instance.new("Sound")
				sound.SoundId = "rbxassetid://" .. tostring(dieSoundId)
				diedSound = sound
			else
				diedSound = nil
			end
		end

		if old == nil or new.users.userSettings ~= old.users.userSettings then
			for userId, settings in new.users.userSettings do
				local player = Players:GetPlayerByUserId(userId)

				if player and player ~= LocalPlayer then
					Players:GetPlayerByUserId(userId):WaitForChild("Theme").Value =
						getSavedSetting(new, userId, "weaponTheme")
				end
			end
		end
	end

	root.StoreChanged:Connect(onChanged)
	onChanged(root.Store:getState(), nil)
end

return respectSettings
