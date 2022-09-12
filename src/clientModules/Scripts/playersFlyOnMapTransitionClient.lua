local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local PhysicsService = game:GetService("PhysicsService")

local MAX_SPEED = 100
local LocalPlayer = Players.LocalPlayer

local function keyDown(key)
    return UserInputService:IsKeyDown(key)
end

local isTyping = false
UserInputService.InputBegan:Connect(function(_, gp)
    isTyping = gp
end)

local function playersFlyOnMapTransitionClient(root)
    local isFlying = false

    local function shouldFly()
        if LocalPlayer.Team and CollectionService:HasTag(LocalPlayer.Team, "ParticipatingTeam") then
            return isFlying
        end

        return false
    end

    local activeHum = nil
    local activeBg = nil
    local activeBv = nil

    local function decorateCharacter(char)
        if shouldFly() and char then
            if not char.Parent then
                char.AncestryChanged:Wait()
            end

            local rootPart = char:FindFirstChild("HumanoidRootPart")
            local hum = char:FindFirstChild("Humanoid")

            if not rootPart or not hum then
                return
            end
    
            local bg = Instance.new("BodyGyro")
            CollectionService:AddTag(bg, "FlyingPhysics")
            bg.D = 200
            bg.P = 5000
            bg.CFrame = rootPart.CFrame
            bg.Parent = rootPart
    
            local bv = Instance.new("BodyVelocity")
            CollectionService:AddTag(bv, "FlyingPhysics")
            bv.Parent = rootPart
    
            local f = Vector3.new(9e9, 9e9, 9e9)
            hum.PlatformStand, bg.MaxTorque, bv.MaxForce = true, f, f
    
            activeHum = hum
            activeBg = bg
            activeBv = bv
        end
    end

    local function setFlying(enabled)
        if isFlying == enabled then
            return
        end

        isFlying = enabled

        if isFlying then
            if LocalPlayer.Character then
                decorateCharacter(LocalPlayer.Character)

                if shouldFly() then
                    -- Don't reset the collision group: the toolset expects a certain collision group for players,
                    -- and all fighting players will be respawned anyway.
                    for _, descendant in LocalPlayer.Character:GetDescendants() do
                        if descendant:IsA("BasePart") then
                            PhysicsService:SetPartCollisionGroup(descendant, "Game_NoClip")
                        end
                    end
                end
            end
        else
            for _, instance in CollectionService:GetTagged("FlyingPhysics") do
                instance.Parent = nil
            end
        end
    end

    local MapController = root:GetService("MapController")
    MapController.MapChanging:Connect(function()
        setFlying(true)
    end)

    MapController.MapChanged:Connect(function()
        setFlying(false)
    end)

    LocalPlayer.CharacterAdded:Connect(decorateCharacter)
    if LocalPlayer.Character then
        task.spawn(decorateCharacter, LocalPlayer.Character)
    end

    local m, acc = 5, Vector3.zero
    RunService.Heartbeat:Connect(function()
        if not isFlying or not activeHum then
            return
        end

        local dir, CF = activeHum.MoveDirection, Workspace.CurrentCamera.CoordinateFrame
        dir = (CF:inverse() * CFrame.new(CF.p + dir)).p
        acc *= 0.95
        acc =
            Vector3.new(
            math.max(-MAX_SPEED, math.min(MAX_SPEED, acc.x + dir.x * m)),
            math.max(
                -MAX_SPEED,
                math.min(
                    MAX_SPEED,
                    if not isTyping and keyDown(Enum.KeyCode.Space) then acc.y + m
                    elseif not isTyping and keyDown(Enum.KeyCode.LeftControl) then acc.y - m
                    else acc.y
                )
            ),
            math.max(-MAX_SPEED, math.min(MAX_SPEED, acc.z + dir.z * m))
        )

        activeBg.cframe, activeBv.velocity = CF, (CF * CFrame.new(acc)).p - CF.p
    end)
end

return playersFlyOnMapTransitionClient