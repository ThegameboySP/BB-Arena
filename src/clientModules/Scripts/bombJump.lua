local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Effects = require(ReplicatedStorage.Common.Utils.Effects)
local RoduxFeatures = require(ReplicatedStorage.Common.RoduxFeatures)
local getSavedSetting = RoduxFeatures.selectors.getSavedSetting

local LocalPlayer = Players.LocalPlayer
local UserId = LocalPlayer.UserId

local function bombJump(root)
    local equippingTool = nil

    Effects.call(LocalPlayer, Effects.pipe({
        Effects.character,
        Effects.childrenFilter(function(child)
            return child:IsA("Tool") and child.Name:lower():find("bomb")
        end),
        function(tool, add, remove)
            local function update()
                local clientFolder = tool:FindFirstChild("Client")
                if clientFolder then
                    local module = clientFolder:FindFirstChild("BombClient")

                    if module then
                        add(tool)
                        return
                    end
                end

                remove(tool)
            end

            local connection = tool.DescendantAdded:Connect(update)
            update()

            return function()
                connection:Disconnect()
            end
        end,
        function(tool)
            equippingTool = require(tool:FindFirstChild("Client"):FindFirstChild("BombClient"))

            return function()
                equippingTool = nil
            end
        end
    }))

    local keybindName
    local undo
    local function onUpdate(new, old)
        if
            old == nil
            or getSavedSetting(new, UserId, "bombJumpKeybind") ~= getSavedSetting(old, UserId, "bombJumpKeybind")
            or getSavedSetting(new, UserId, "bombJumpDefault") ~= getSavedSetting(old, UserId, "bombJumpDefault")
        then
            if undo then
                undo()
            end

            if getSavedSetting(new, UserId, "bombJumpDefault") then
                keybindName = nil
                _G.BB.Settings.BombJump = true
            else
                keybindName = getSavedSetting(new, UserId, "bombJumpKeybind")
                _G.BB.Settings.BombJump = false

                if keybindName then
                    ContextActionService:BindAction("BombJump", function(_, state)
                        if state == Enum.UserInputState.Begin and equippingTool then
                            equippingTool:FireAndBombJump()
                        end

                        return Enum.ContextActionResult.Pass
                    end, false, Enum.KeyCode[keybindName])

                    undo = function()
                        ContextActionService:UnbindAction("BombJump")
                    end
                end
            end
        end
    end

    root.Store.changed:connect(onUpdate)
    onUpdate(root.Store:getState(), nil)

    local screenGui = Instance.new("ScreenGui")
    screenGui.ResetOnSpawn = false

    local textLabel = Instance.new("TextLabel")
    textLabel.Text = ""
    textLabel.Font = Enum.Font.GothamBold
    textLabel.TextSize = 28
    textLabel.TextStrokeTransparency = 0
    textLabel.TextColor3 = Color3.new(1, 1, 1)
    textLabel.TextXAlignment = Enum.TextXAlignment.Center
    textLabel.AnchorPoint = Vector2.new(0.5, 1)
    textLabel.Position = UDim2.new(0.5, 0, 1, -80)
    textLabel.BackgroundTransparency = 1

    textLabel.Parent = screenGui

    RunService.Heartbeat:Connect(function()
        if equippingTool then
            if _G.BB.TrueMobile then
                textLabel.Text = ""
            elseif equippingTool.canBombJump then
                if keybindName then
                    textLabel.Text = string.format("%s - bomb jump", keybindName)
                else
                    textLabel.Text = "click and jump - bomb jump"
                end
            else
                if keybindName then
                    textLabel.Text = string.format("%s - bomb jump (recharging)", keybindName)
                else
                    textLabel.Text = "click and jump - bomb jump (recharging)"
                end
            end

            screenGui.Parent = LocalPlayer.PlayerGui
        else
            screenGui.Parent = nil
        end
    end)
end

return bombJump