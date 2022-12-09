local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local Promise = require(ReplicatedStorage.Packages.Promise)
local RichText = require(ReplicatedStorage.Common.Utils.RichText)

local TWEEN_INFO = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, 0)
local TRANSPARENCY_DEFAULT = 0.2

local Gui = ReplicatedStorage.UI.Hint:Clone()
Gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

local Main = Gui.Background
local MsgText = Main.MessageText
local Bar = Main.Bar

local timer = 0
local c = nil
local promise = nil
local shouldBeVisible = false

local TweenableObjects = {
	Main,
	Bar,
	Main.MessageText,
}

local TextOnly = {
	MessageText = 1,
}

local function countWords(msg)
	local count = 0
	for _ in string.gmatch(msg, "(%w+)") do
		count += 1
	end

	return count
end

local function tweenTransition(visible)
	shouldBeVisible = visible
	if promise then
		promise:cancel() -- Cancel Dr Seuss.
	end
	promise = Promise.new(function(resolve, reject, onCancel) -- first time using promises
		-- want people to see the tween
		if visible then
			Main.Visible = visible
		end

		local tweens = {}

		local number = visible and TRANSPARENCY_DEFAULT or 1

		local function registerAndPlay(tween)
			tween:Play()
			table.insert(tweens, tween)
		end

		for _, guiObj in pairs(TweenableObjects) do
			if not guiObj:IsA("Frame") then
				registerAndPlay(TweenService:Create(guiObj, TWEEN_INFO, { TextTransparency = number }))
				registerAndPlay(TweenService:Create(guiObj, TWEEN_INFO, { TextStrokeTransparency = number }))
			end
			if not TextOnly[guiObj.Name] then
				registerAndPlay(TweenService:Create(guiObj, TWEEN_INFO, { BackgroundTransparency = number }))
			end
		end

		local c2

		onCancel(function()
			for _, tween in pairs(tweens) do
				tween:Pause()
				tween = nil
			end
			if c2 then
				c:Disconnect()
			end
		end)

		local t = time()
		c2 = RunService.RenderStepped:Connect(function()
			if (time() - t) > 1.5 then
				Main.Visible = shouldBeVisible
				c2:Disconnect()
				resolve(visible)
			end
		end)
	end):andThen(function()
		promise = nil -- not sure if this necessary
	end)
end

local function close()
	if c then
		c:Disconnect()
	end
	tweenTransition(false)
	MsgText.Text = ""
end

-- Message: string
-- Options.sender: player or string
-- Options.color: Color3
-- Options.stayOpen: boolean
return function(Message, Options)
	Options = Options or {}

	local seconds = (countWords(Message) * 0.3) + 1
	timer += seconds
	local Color = Options.color or Color3.new(1, 1, 1)

	if c then
		c:Disconnect()
	end

	tweenTransition(true)

	if not Options.stayOpen then
		c = RunService.RenderStepped:Connect(function(step)
			timer -= step
			if timer < 0.2 then
				close()
			end
		end)
	end

	local Sender = Options.sender
	local SenderColor = (typeof(Sender) == "Instance" and Sender:IsA("Player")) and Sender.TeamColor.Color
		or Color3.new(1, 1, 1)
	Bar.BackgroundColor3 = SenderColor
	Sender = typeof(Sender) == "string" and Sender or tostring(Sender)

	Message = RichText.bold("[" .. RichText.color(Sender, SenderColor) .. "]: ") .. RichText.color(Message, Color)

	MsgText.Text = Message
end
