local GuiService = game:GetService("GuiService")
local Lighting = game:GetService("Lighting")

local function blurOnOpen()
    local blur = Instance.new("BlurEffect")
    blur.Size = 10

    GuiService.MenuOpened:Connect(function()
        blur.Parent = Lighting
    end)

    GuiService.MenuClosed:Connect(function()
        -- Setting parent to nil not the same as destroying it.
        -- Doesn't lock its parent and destroy its connections.
        blur.Parent = nil
    end)
end

return blurOnOpen