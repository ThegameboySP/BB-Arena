local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local Players = game:GetService("Players")
local Teams = game:GetService("Teams")

local Knit = require(ReplicatedStorage.Packages.Knit)
Knit:OnStart():await()

local spectatorsCanBuildTrowels = Knit.globals.spectatorsCanBuildTrowels
local Spectators = Teams.Spectators
local LocalPlayer = Players.LocalPlayer

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

            if spectatorsCanBuildTrowels:Get() then
                local trowel = LocalPlayer.Backpack:FindFirstChild("Trowel")
                if trowel then
                    trowel.Parent = LocalPlayer.Character
                end
            end
        end
    end
end

-- Trowels break if immediately equipped?
local function deferredUpdate()
    task.delay(0.2, update)
end

LocalPlayer:GetPropertyChangedSignal("Team"):Connect(update)
update()
spectatorsCanBuildTrowels.Changed:Connect(deferredUpdate)

local connection
local function onChildAdded(child)
    if child:IsA("Backpack") then
        if connection then
            connection:Disconnect()
        end
        
        connection = child.ChildAdded:Connect(deferredUpdate)
        deferredUpdate()
    end
end
LocalPlayer.ChildAdded:Connect(onChildAdded)

local backpack = LocalPlayer:FindFirstChild("Backpack")
if backpack then
    onChildAdded(backpack)
end