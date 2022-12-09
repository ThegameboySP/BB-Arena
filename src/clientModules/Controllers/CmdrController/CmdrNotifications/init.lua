local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Sounds = ReplicatedStorage.Assets.Sounds

local CmdrNotifications = {}

local LOCAL_PLAYER = Players.LocalPlayer
local EASE_IN = TweenInfo.new(0.35, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)
local EASE_OUT = TweenInfo.new(0.75, Enum.EasingStyle.Exponential, Enum.EasingDirection.In)

local Gui = script.CmdrNotificationsGui
local Frame = script.CmdrNotificationsGui.Frame
local NotificationSound = Sounds.Beep1
local MessageTemp = Frame.Template

function CmdrNotifications:AddMessage(text, playSound, color)
	local children = MessageTemp:GetChildren()
	if #children > 4 then
		table.remove(children, 2):Destroy()
	end

	if playSound == true then
		NotificationSound:Play()
	end

	local msg = MessageTemp:Clone()
	msg.Name = "Entry"
	msg.BackgroundTransparency = 1
	msg.Size = UDim2.fromScale(0, 0)
	msg.Message.Text = text
	if color then
		msg.Message.TextColor3 = color
	end
	msg.Message.TextTransparency = 1
	msg.Parent = Frame

	local t1 = TweenService:Create(msg, EASE_IN, { BackgroundTransparency = 0.65, Size = UDim2.fromScale(1, 0.3) })
	local t2 = TweenService:Create(msg.Message, EASE_IN, { TextTransparency = 0 })
	t1:Play()
	t2:Play()

	task.delay(5, function()
		if msg.Parent == nil then
			return
		end

		local t3 = TweenService:Create(msg, EASE_OUT, { Size = UDim2.fromScale(0, 0) })
		local t4 = TweenService:Create(msg.Message, EASE_OUT, { TextTransparency = 0 })
		t4:Play()
		t3.Completed:Connect(function()
			msg:Destroy()
		end)
		t3:Play()
	end)
end

MessageTemp.Parent = nil
-- NotificationSound.Name = "CmdrNotification"
-- NotificationSound.Parent = workspace
Gui.Parent = LOCAL_PLAYER.PlayerGui

return CmdrNotifications
