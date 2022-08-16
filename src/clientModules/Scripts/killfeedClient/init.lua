local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local RichText = require(ReplicatedStorage.Common.Utils.RichText)

local KillfeedGui = script.KillfeedGui

local MAX_MESSAGES = 50

local BEST_FLAG_DISTANCE = 500
local BEST_KILL_DISTANCE = 200
local BEST_CLUTCH_DISTANCE = 100

local SK_DEFAULT = {
	"made a BIG mistake",
	"did an OOPS",
	"short circuited",
	"epicly failed",
	"slipped on a banana peel"
}

-- local KILL_MESSAGES = {
-- 	"BLOXXED",
-- 	"CRUSHED",
-- 	"EZ'd",
-- 	"REKT",
-- 	"PWNED",
-- 	"OWNED",
-- 	"WENT SICKO MODE ON"
-- }

local DIED_DEFAULT = {
	"mysteriously died",
	"died somehow",
	"weirdly lost all their health"
}

local DIED_SPECIAL = {
	Void = {
		Color = Color3.new(0.0862745, 0.0862745, 0.0862745);
		Message = "falling into the void"
	};
	Lava =  {
		Color = Color3.new(1, 0.25098, 0);
		Message = "burning in lava"
	};
	Admin =  {
		Color = Color3.new(0.5, 0.5, 0.5);
		Message = "admin commands"
	};
}

local function makePastel(color)
    return color:Lerp(Color3.new(0.8, 0.8, 0.8), 0.5)
end

local function killfeedClient(root)
	local remote = root:getRemoteEvent("Killfeed")
	local componentManager = root:GetService("MapController").ClonerManager.Manager

	local Gui = KillfeedGui:Clone()
	Gui.Parent = Players.LocalPlayer.PlayerGui

	local main = assert(Gui:FindFirstChild("Main"))
	local toggle = assert(Gui:FindFirstChild("Toggle"))
	local templates = assert(Gui:FindFirstChild("Templates"))

	local trueMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
	if trueMobile then
		main.Position = UDim2.fromScale(1, .5)
		main.Size = UDim2.fromScale(.2, .25)
		toggle.Position = UDim2.fromScale(1, .75)
	end

	toggle.MouseButton1Click:Connect(function()
		main.Visible = not main.Visible
		toggle.Text = main.Visible and '>' or '<'
	end)

	-- PingRemote.OnClientEvent:Connect(function()
	-- 	PingRemote:FireServer()
	-- end)

	local i = 0
	local elements = {}

	local function configurePlayer(playerElement, data, person)
		playerElement.PlayerName.Text = data[person].Name
		playerElement.PlayerName.TextColor3 = data[person].TeamColor.Color
		playerElement.HeadImage.Image = Players:GetUserThumbnailAsync(data[person].UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)

		if playerElement:FindFirstChild("Ping") then
			playerElement.Ping.Text = string.format("%.1f ms", data[person .. "Ping"] * 1000)
		end
		
		if playerElement:FindFirstChild("FlagImage") and data.Flag then
			playerElement.FlagImage.Visible = true
			playerElement.FlagImage.ImageColor3 = data.FlagTeam.TeamColor.Color
		end
	end
	
	local function configureFlag(flagElement, team)
		local image = flagElement.FlagImage
		local grade = image.Background.UIGradient
		
		local color = team.TeamColor.Color
		local pastel = makePastel(color)
		local csc = ColorSequence.new(pastel)
		
		grade.Color = csc
		image.ImageColor3 = color
	end
	
	local function processFeed(data)
		i += 1

		local feedElement = templates:FindFirstChild(data.Type):Clone()

		if data.Type == "Kill" then
			configurePlayer(feedElement.Dead, data, "Dead")
			configurePlayer(feedElement.Killer, data, "Killer")

			local distanceLabel = feedElement.WeaponAndDistance.Distance
			local ratio = math.min(data.Distance/BEST_KILL_DISTANCE, 1)

			distanceLabel.Text = RichText.color(string.format("%.1f studs", data.Distance), Color3.new(ratio, .5, .5))
			feedElement.WeaponAndDistance.WeaponImage.Image = data.Weapon

		elseif data.Type == "Died" then
			configurePlayer(feedElement.Dead, data, "Dead")

			local textLabel = feedElement.Message.Text
			textLabel.Text = DIED_DEFAULT[math.random(1, #DIED_DEFAULT)]

			if data.DeathCause then
				local Color = Color3.new(1, 1, 1)
				local Message = data.DeathCause

				if DIED_SPECIAL[data.DeathCause] then
					Color = DIED_SPECIAL[data.DeathCause].Color
					Message = DIED_SPECIAL[data.DeathCause].Message
				end

				textLabel.Text = "died by " .. RichText.color(Message, Color)

				if data.WhileFighting then
					local text = textLabel.Text
					local plr = data.WhileFighting.Value
					textLabel.Text = text .. " while fighting " .. RichText.color(plr.Name, plr.TeamColor.Color)
				end
			end

		elseif data.Type == "SK" then
			configurePlayer(feedElement.Dead, data, "Dead")
			feedElement.Weapon.WeaponImage.Image = data.Weapon
			feedElement.Message.Text.Text = SK_DEFAULT[math.random(1, #SK_DEFAULT)]

		elseif data.Type == "Capture" then
			local flagTeam = componentManager:GetComponent(data.Flag, "CTF_Flag").State.Team

			configurePlayer(feedElement.Capturer, data, "Capturer")
			configureFlag(feedElement.Flag, flagTeam)

			local textLabel = feedElement.Message.Text
			local ratio = math.min(data.DistanceTraveled/BEST_FLAG_DISTANCE, 1)

			textLabel.Text = ("captured the "..
				RichText.color(flagTeam.Name .. " team's", flagTeam.TeamColor.Color)..
				" flag, traveling "..
				RichText.color(math.round(data.DistanceTraveled), Color3.new(.5, ratio, .5))..
				" studs!"
			)
			
		elseif data.Type == "Recovery" then
			local flagTeam = componentManager:GetComponent(data.Flag, "CTF_Flag").State.Team

			configurePlayer(feedElement.Recoverer, data, "Recoverer")
			configureFlag(feedElement.Flag, flagTeam)

			local textLabel = feedElement.Message.Text
			local ratio = math.min(data.ClutchIndex/BEST_CLUTCH_DISTANCE, 1)

			textLabel.Text = ("recovered the "..
				RichText.color(flagTeam.Name .. " team's", flagTeam.TeamColor.Color)..
				" flag, scoring a "..
				RichText.color(math.round(data.ClutchIndex*10)/10, Color3.new(.5, .5, ratio))..
				" clutch score!"
			)
		end

		feedElement.LayoutOrder = -i

		table.insert(elements, feedElement)

		if #elements > MAX_MESSAGES then
			local lastElement = elements[1]
			table.remove(elements, 1)
			lastElement:Destroy()
		end

		feedElement.Visible = true
		feedElement.Parent = main
	end
	
	remote.OnClientEvent:Connect(processFeed)

	root:getRemoteEvent("CTF_Captured").OnClientEvent:Connect(function(data)
		processFeed({
			Type = "Capture";
			Capturer = data.player;
			DistanceTraveled = data.distanceTraveled;
			Flag = data.flag;
		})
	end)

	root:getRemoteEvent("CTF_Recovered").OnClientEvent:Connect(function(data)
		processFeed({
            Type = "Recovery";
			Recoverer = data.player;
			ClutchIndex = data.defensiveClutch;
			Flag = data.flag;
        })
	end)
end

return killfeedClient