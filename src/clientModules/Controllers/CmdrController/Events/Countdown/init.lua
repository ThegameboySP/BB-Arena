local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local Message = script.Message

local lastGUI

return function(CmdrClient)
	CmdrClient:HandleEvent("Countdown", function(text, _player, duration)
		if lastGUI and lastGUI.Parent then
			lastGUI:Destroy()
		end
		
		local message = Message:Clone()
		message.Frame.Msg.Text = text
		message.Parent = Players.LocalPlayer.PlayerGui
		
		for _, element in message.Frame:GetChildren() do
			pcall(function()
				element.BackgroundTransparency = 1
				element.TextTransparency = 1
				element.TextStrokeTransparency = 1
			end)
		end
		
		local function tweenTransparency(element, property, transparency)
			local goal = {}
			goal[property] = transparency
			
			local tween = TweenService:Create(
				element,
				TweenInfo.new(0.5, Enum.EasingStyle.Linear, Enum.EasingDirection.In),
				goal
			)
			tween:Play()
		end
		
		tweenTransparency(message.Frame.BG, "BackgroundTransparency", 0.7)
		tweenTransparency(message.Frame.Msg, "TextTransparency", 0)
		tweenTransparency(message.Frame.Msg, "TextStrokeTransparency", 0.75)
		tweenTransparency(message.Frame.Owner, "TextTransparency", 0)
		
		lastGUI = message
		
		task.wait(duration or 6)
		
		if message.Parent then
			tweenTransparency(message.Frame.BG, "BackgroundTransparency", 1)
			tweenTransparency(message.Frame.Msg, "TextTransparency", 1)
			tweenTransparency(message.Frame.Msg, "TextStrokeTransparency", 1)
			tweenTransparency(message.Frame.Owner, "TextTransparency", 1)
			
			task.wait(0.5)
			
			message:Destroy()
		end
	end)
end