local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Teams = game:GetService("Teams")

local LocalPlayer = Players.LocalPlayer

local function teamMembersSeeInfoFarAway()
    RunService.Heartbeat:Connect(function()
        local team = LocalPlayer.Team
        
        if team == Teams.Spectators then
            for _, player in ipairs(Players:GetPlayers()) do
                if player == LocalPlayer then continue end
                local char = player.Character
                if not char then continue end
                local hum = char:FindFirstChild("Humanoid")
                if not hum then continue end
                
                hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.Viewer
                hum.NameOcclusion = Enum.NameOcclusion.EnemyOcclusion
                hum.HealthDisplayType = Enum.HumanoidHealthDisplayType.DisplayWhenDamaged
            end
        else
            for _, player in ipairs(Players:GetPlayers()) do
                if player == LocalPlayer then continue end
                local char = player.Character
                if not char then continue end
                local hum = char:FindFirstChild("Humanoid")
                if not hum then continue end
                
                if player.Team == team then
                    hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.Subject
                    hum.NameOcclusion = Enum.NameOcclusion.NoOcclusion
                    hum.NameDisplayDistance = math.huge
                    hum.HealthDisplayType = Enum.HumanoidHealthDisplayType.DisplayWhenDamaged
                    hum.HealthDisplayDistance = math.huge
                else
                    hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.Viewer
                    hum.NameOcclusion = Enum.NameOcclusion.EnemyOcclusion
                    hum.HealthDisplayType = Enum.HumanoidHealthDisplayType.DisplayWhenDamaged
                end
            end
        end
    end)
end

return teamMembersSeeInfoFarAway