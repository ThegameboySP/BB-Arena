local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

local Signal = require(ReplicatedStorage.Packages.Signal)
local RoduxFeatures = require(ReplicatedStorage.Common.RoduxFeatures)
local getLocalSetting = RoduxFeatures.selectors.getLocalSetting
local Effects = require(ReplicatedStorage.Common.Utils.Effects)

local function crosshair(root)
    local activeCrosshair
    local reloadingCrosshair
    local updated = Signal.new()

    local function onChanged(new, old)
        if
            old == nil
            or getLocalSetting(new, "weaponCrosshairId") ~= getLocalSetting(old, "weaponCrosshairId")
            or getLocalSetting(new, "weaponCrosshairReloadingId") ~= getLocalSetting(old, "weaponCrosshairReloadingId")
        then
            activeCrosshair = "rbxassetid://" .. getLocalSetting(new, "weaponCrosshairId")
            reloadingCrosshair = "rbxassetid://" .. getLocalSetting(new, "weaponCrosshairReloadingId")

            updated:Fire()
        end
    end

    root.Store.changed:connect(onChanged)
    onChanged(root.Store:getState(), nil)

    Effects.call(LocalPlayer, Effects.pipe({
        Effects.character,
        Effects.childrenFilter(function(child)
            return child:IsA("Tool")
        end),
        function(tool)
            local function update()
                if tool.Enabled then
                    Mouse.Icon = activeCrosshair
                else
                    Mouse.Icon = reloadingCrosshair
                end
            end

            local connection = tool:GetPropertyChangedSignal("Enabled"):Connect(update)
            local connection2 = updated:Connect(update)
            update()

            return function()
                connection:Disconnect()
                connection2:Disconnect()

                Mouse.Icon = ""
            end
        end
    }))
end

return crosshair