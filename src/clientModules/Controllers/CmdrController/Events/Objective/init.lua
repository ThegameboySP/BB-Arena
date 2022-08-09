local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local Gui = script.ObjectiveGUI
local Frame = Gui.Frame
local Objective = Frame.Objective

Frame.Size = UDim2.fromScale(0, 0)
Gui.Parent = Players.LocalPlayer.PlayerGui

local FULL = {Size = UDim2.new(0.45, 0, 0, 36)}
local SMALL = {Size = UDim2.new(0.001, 0, 0, 36)}
local TEXT_ON = {TextTransparency = 0, TextStrokeTransparency = 0.5}
local TEXT_OFF = {TextTransparency = 1, TextStrokeTransparency = 1}

return function(msg)
	if msg == nil then
		local t1 = TweenService:Create(Frame, TweenInfo.new(0.75, Enum.EasingStyle.Quad, Enum.EasingDirection.In), SMALL)
		local t2 = TweenService:Create(Objective, TweenInfo.new(0.75, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), TEXT_OFF)
		t2:Play()

		t1.Completed:Once(function()
			local t3 = TweenService:Create(Frame, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.fromScale(0, 0)})
			t3:Play()
		end)
        
		t1:Play()
		return
	end
	
	Frame.Size = UDim2.fromScale(0, 0)
	Objective.Text = msg
	Objective.TextTransparency = 1
	Objective.TextStrokeTransparency = 1
	
	local t1 = TweenService:Create(Frame, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In), SMALL)
	t1.Completed:Once(function()
		local t2 = TweenService:Create(Frame, TweenInfo.new(0.75, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), FULL)
		t2:Play()
		local t3 = TweenService:Create(Objective, TweenInfo.new(0.75, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), TEXT_ON)
		t3:Play()
	end)
    
	t1:Play()
end