local StarterGui = game:GetService("StarterGui")
local Spectators = game:GetService("Teams").Spectators
local LocalPlayer = game:GetService("Players").LocalPlayer

local function update()
    task.spawn(function()
        repeat task.wait() until pcall(function()
            StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, LocalPlayer.Team ~= Spectators)
        end)
    end)
    
    if LocalPlayer.Team == Spectators then
        if LocalPlayer.Character then
            local tool = LocalPlayer.Character:FindFirstChildWhichIsA("Tool")
            if tool then
                tool.Parent = LocalPlayer.Backpack
            end
        end
    end
end

LocalPlayer:GetPropertyChangedSignal("Team"):Connect(update)
update()