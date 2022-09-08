local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")

local RoduxFeatures = require(ReplicatedStorage.Common.RoduxFeatures)
local getLocalSetting = RoduxFeatures.selectors.getLocalSetting

local function respectSettings(root)
    local weaponGroup = SoundService:FindFirstChild("Tools")
    local projectiles = Workspace:FindFirstChild("Projectiles")

    local colorCorrection = Instance.new("ColorCorrectionEffect")
    colorCorrection.Name = "IlluminanceCorrection"
    colorCorrection.Parent = Lighting

    Workspace.DescendantAdded:Connect(function(descendant)
        if descendant:IsA("Sound") then
            if descendant:FindFirstAncestorWhichIsA("Tool") or descendant:IsDescendantOf(projectiles) then
                descendant.SoundGroup = weaponGroup
            end
        end
    end)

    local function onChanged(new, old)
        assert(new, "New Rodux state was somehow nil")
        
        if old == nil or getLocalSetting(new, "musicVolume") ~= getLocalSetting(old, "musicVolume") then
            SoundService.Music.Volume = 2 * getLocalSetting(new, "musicVolume")
        end

        if old == nil or getLocalSetting(new, "mapVolume") ~= getLocalSetting(old, "mapVolume") then
            SoundService.Map.Volume = 2 * getLocalSetting(new, "mapVolume")
        end

        if old == nil or getLocalSetting(new, "weaponVolume") ~= getLocalSetting(old, "weaponVolume") then
            weaponGroup.Volume = getLocalSetting(new, "weaponVolume")
        end

        if old == nil or getLocalSetting(new, "lighting") ~= getLocalSetting(old, "lighting") then
            local percent = getLocalSetting(new, "lighting")
            colorCorrection.Brightness = 1 * (percent - 0.5)
            colorCorrection.Contrast = 0.5 * (percent - 0.5)
        end
    end

    root.Store.changed:connect(onChanged)
    onChanged(root.Store:getState(), nil)
end

return respectSettings