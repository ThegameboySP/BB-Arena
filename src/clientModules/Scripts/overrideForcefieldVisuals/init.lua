local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local RoduxFeatures = require(ReplicatedStorage.Common.RoduxFeatures)
local getLocalSetting = RoduxFeatures.selectors.getLocalSetting

local retroForcefields = require(script.retroForcefields)
local simpleForcefields = require(script.simpleForcefields)
local defaultForcefields = require(script.defaultForcefields)

local callbackByName = {
    Default = defaultForcefields;
    Retro = retroForcefields;
    Simple = simpleForcefields;
}

local function removeData(data)
    data.node.Parent = nil

    if data.initialized then
        data.remove(data)
    end

    data.forcefield.Visible = true
end

local function overrideForcefieldVisuals(root)
    local activeForcefields = {}

    local function hook(add, remove, step)
        local connections = {}

        local function onDescendantAdded(descendant)
            if
                not descendant:IsA("ForceField")
                or not descendant.Visible
                or CollectionService:HasTag(descendant, "ForceFieldVisual")
            then
                return
            end

            descendant.Visible = false

            if
                descendant.Parent and descendant.Parent:FindFirstChild("Humanoid")
                and not activeForcefields[descendant.Parent]
            then
                local character = descendant.Parent

                local node = Instance.new("ObjectValue")
                node.Name = "VisualForcefieldNode"
                node.Value = character
                node.Parent = descendant
                CollectionService:AddTag(node, "VisualForcefieldNode")

                local data = {
                    character = character;
                    forcefield = descendant;
                    startedTimestamp = os.clock();
                    node = node;
                    queued = true;
                    initialized = false;
                    remove = remove;
                }

                activeForcefields[character] = data
            end
        end

        for _, descendant in Workspace:GetDescendants() do
            onDescendantAdded(descendant)
        end
        table.insert(connections, Workspace.DescendantAdded:Connect(onDescendantAdded))

        table.insert(connections, CollectionService:GetInstanceRemovedSignal("VisualForcefieldNode"):Connect(function(instance)
            local data = activeForcefields[instance.Value]

            if data then
                data.removing = true
            end
        end))

        table.insert(connections, RunService.Heartbeat:Connect(function()
            local currentCamera = Workspace.CurrentCamera

            for key, data in activeForcefields do
                if data.removing then
                    if data.character:IsDescendantOf(game) then
                        local newForcefield

                        for _, child in data.character:GetChildren() do
                            if child:IsA("ForceField") and not CollectionService:HasTag(child, "ForceFieldVisual") then
                                newForcefield = child
                                break
                            end
                        end
    
                        if newForcefield then
                            data.node.Parent = newForcefield
                            data.forcefield = newForcefield
                            data.removing = false
                        end
                    end

                    if data.removing then
                        activeForcefields[key] = nil
                        removeData(data)

                        continue
                    end
                end

                if data.queued then
                    local item = add(data)

                    if item == false then
                        continue
                    end
                    
                    if type(item) == "function" then
                        local lastTransparency = 0
                        data.setTransparency = function(transparency)
                            if transparency == lastTransparency then
                                return
                            end

                            item(transparency)

                            lastTransparency = transparency
                        end
                    end

                    data.queued = false
                    data.initialized = true
                end

                if data.setTransparency then
                    -- Taken from CameraModule/TransparencyController
                    local distance = (currentCamera.Focus.p - currentCamera.CoordinateFrame.p).magnitude
                    local transparency = (distance<2) and (1.0-(distance-0.5)/1.5) or 0
                    if transparency < 0.5 then
                        transparency = 0
                    end
                    
                    data.setTransparency(transparency)
                end
            end

            if step then
                step()
            end
        end))

        return function()
            for key, data in activeForcefields do
                activeForcefields[key] = nil
                removeData(data)
            end

            for _, connection in connections do
                connection:Disconnect()
            end
        end
    end

    local undo

    local function setupTheme(theme)
        local callback = callbackByName[theme]
        if not callback then
            return
        end

        local interface = callback()

        if undo then
            undo()
        end

        undo = hook(interface.add, interface.remove, interface.step)
    end

    local function onChanged(new, old)
        if old == nil or getLocalSetting(new, "forcefieldTheme") ~= getLocalSetting(old, "forcefieldTheme") then
            setupTheme(getLocalSetting(new, "forcefieldTheme"))
        end
    end

    onChanged(root.Store:getState(), nil)
    root.Store.changed:connect(onChanged)
end

return overrideForcefieldVisuals