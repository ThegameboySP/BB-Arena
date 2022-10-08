local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

local Effects = require(ReplicatedStorage.Common.Utils.Effects)
local RoduxFeatures = require(ReplicatedStorage.Common.RoduxFeatures)
local getLocalSetting = RoduxFeatures.selectors.getLocalSetting

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local Terrain = Workspace:FindFirstChild("Terrain")

local function beamProjectile(g, v0, x0, t1)
	-- calculate the bezier points
	local c = 0.5*0.5*0.5
	local p3 = 0.5*g*t1*t1 + v0*t1 + x0
	local p2 = p3 - (g*t1*t1 + v0*t1)/3
	local p1 = (c*g*t1*t1 + 0.5*v0*t1 + x0 - c*(x0+p3))/(3*c) - p2
	
	-- the curve sizes
	local curve0 = (p1 - x0).Magnitude
	local curve1 = (p2 - p3).Magnitude
	
	-- build the world CFrames for the attachments
	local b = (x0 - p3).Unit
	local r1 = (p1 - x0).Unit
	local u1 = r1:Cross(b).Unit
	local r2 = (p2 - p3).Unit
	local u2 = r2:Cross(b).Unit
	b = u1:Cross(r1).Unit
	
	local cf1 = CFrame.new(
		x0.x, x0.y, x0.z,
		r1.x, u1.x, b.x,
		r1.y, u1.y, b.y,
		r1.z, u1.z, b.z
	)
	
	local cf2 = CFrame.new(
		p3.x, p3.y, p3.z,
		r2.x, u2.x, b.x,
		r2.y, u2.y, b.y,
		r2.z, u2.z, b.z
	)
	
	return curve0, -curve1, cf1, cf2
end

local function updatePath(headPos, lookAt, beam)
    local bbSettings = _G.BB.Settings
    local attachment0 = beam.Attachment0
    local attachment1 = beam.Attachment1

    local spawnPos = headPos + lookAt * bbSettings.Superball.SpawnDistance

	local g = Vector3.new(0, -Workspace.Gravity, 0)
	local x0 = spawnPos
	local v0 = lookAt * bbSettings.Superball.Speed
    
    -- Time to project outward
	local t = 1

	local curve0, curve1, cf1, cf2 = beamProjectile(g, v0, x0, t)
    beam.CurveSize0 = curve0
    beam.CurveSize1 = curve1
    
    -- convert world space CFrames to be relative to the attachment parent
    attachment0.CFrame = (attachment0.Parent.CFrame:inverse() * cf1) - Vector3.new(0, 0.4, 0)
    attachment1.CFrame = (attachment1.Parent.CFrame:inverse() * cf2) - Vector3.new(0, 0.4, 0)
end

local pipeline = Effects.pipe({
    function(player, add, remove)
        local function update()
            local team = player.Team
            if team and team.Name == "Practice" then
                add(player)
            else
                remove(player)
            end
        end

        local connection = player:GetPropertyChangedSignal("Team"):Connect(update)
        update()

        return function()
            connection:Disconnect()
        end
    end,
    Effects.character,
    function(character, add, remove)
        local function update()
            local superball = character:FindFirstChild("Superball")
            local head = character:FindFirstChild("Head")

            if
                superball and superball:IsA("Tool")
                and head and head:IsA("BasePart")
            then
                add(character)
            else
                remove(character)
            end
        end

        local connections = {}
        table.insert(connections, character.ChildAdded:Connect(update))
        table.insert(connections, character.ChildRemoved:Connect(update))
        update()

        return function()
            for _, connection in connections do
                connection:Disconnect()
            end
        end
    end,
    function(character, _, _, context)
        local head = character:FindFirstChild("Head")

        local beam = context.beam
        beam.Parent = Terrain

        local function update()
            local headPos = head.Position
            local lookAt = (Mouse.Hit.Position - headPos).Unit
            updatePath(headPos, lookAt, beam)
        end
        
        local connection = RunService.Heartbeat:Connect(update)
        update()
        
        return function()
            connection:Disconnect()
            beam.Parent = nil
        end
    end
})

local function superballTrajectoryVisualizer(root)
    local attachment0 = Instance.new("Attachment")
    attachment0.Parent = Terrain
    local attachment1 = Instance.new("Attachment")
    attachment1.Parent = Terrain

    local beam = Instance.new("Beam")
    beam.Attachment0 = attachment0
    beam.Attachment1 = attachment1
    beam.Width0 = 2
    beam.Width1 = 2
    beam.Segments = 50
    beam.TextureSpeed = 0.25
    beam.LightEmission = 0.25
    beam.Texture = "rbxassetid://2724621315"
    beam.Transparency = NumberSequence.new(0.5)
    beam.Color = ColorSequence.new(Color3.new(1, 1, 1))

    local undo
    local function onChanged(new, old)
        if old == nil or getLocalSetting(new, "practiceWeaponDisplay") ~= getLocalSetting(old, "practiceWeaponDisplay") then
            if undo then
                undo()
            end

            if getLocalSetting(new, "practiceWeaponDisplay") then
                undo = Effects.call(LocalPlayer, pipeline, {beam = beam})
            end
        end
    end

    root.Store.changed:connect(onChanged)
    onChanged(root.Store:getState(), nil)
end

return superballTrajectoryVisualizer