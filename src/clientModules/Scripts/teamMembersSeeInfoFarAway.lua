local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Teams = game:GetService("Teams")

local Signal = require(ReplicatedStorage.Packages.Signal)
local Effects = require(ReplicatedStorage.Common.Utils.Effects)

local LocalPlayer = Players.LocalPlayer

local function updateHumanoid(humanoid, team)
    local localTeam = LocalPlayer.Team

    if localTeam == Teams.Spectators or team ~= localTeam then
        humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.Viewer
        humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.DisplayWhenDamaged
    else
        humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.Subject
        humanoid.NameDisplayDistance = math.huge
        humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.DisplayWhenDamaged
        humanoid.HealthDisplayDistance = math.huge
    end
end

local function teamMembersSeeInfoFarAway()
    local localTeamUpdated = Signal.new()

    -- Cache active humanoids and use callbacks for performance.
    Effects.call(Players, Effects.pipe({
        Effects.children,
        function(player, add)
            if player ~= LocalPlayer then
                add(player, {player = player})
            end
        end,
        Effects.character,
        function(character, _, _, context)
            local humanoid = character:FindFirstChild("Humanoid")
            
            local connection1 = context.player:GetPropertyChangedSignal("Team"):Connect(function()
                updateHumanoid(humanoid, context.player.Team)
            end)

            local connection2 = localTeamUpdated:Connect(function()
                updateHumanoid(humanoid, context.player.Team)
            end)

            updateHumanoid(humanoid, context.player.Team)

            return function()
                connection1:Disconnect()
                connection2:Disconnect()
            end
        end
    }))

    LocalPlayer:GetPropertyChangedSignal("Team"):Connect(function()
        localTeamUpdated:Fire()
    end)
end

return teamMembersSeeInfoFarAway