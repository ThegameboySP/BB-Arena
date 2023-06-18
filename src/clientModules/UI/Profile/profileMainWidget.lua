local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TextService = game:GetService("TextService")

local Roact = require(ReplicatedStorage.Packages.Roact)
local RoactHooks = require(ReplicatedStorage.Packages.RoactHooks)
local RoactSpring = require(ReplicatedStorage.Packages.RoactSpring)
local Llama = require(ReplicatedStorage.Packages.Llama)
local e = Roact.createElement

local window = require(script.Parent.Parent.Presentational.window)
local button = require(script.Parent.Parent.Presentational.button)
local ThemeContext = require(script.Parent.Parent.ThemeContext)
local declareUtils = require(script.Parent.Parent.Utils.declareUtils)

local STROKE_THICKNESS = 16
local MARGIN = 12 --10--16

local STAT_TABS = { "Arena stats", "Ranged stats", "Gamemode stats" }
local STATS = {
	["Arena stats"] = {
		{ "Kills", "KOs" },
		{ "Deaths", "WOs" },
		{ "Best killstreak", "bestKillstreak" }, --{"XP", "XP"},
		{ "Wins", "alltimeWins" },
		{ "Losses", "alltimeLosses" },
	},
	["Ranged stats"] = {},
	["Gamemode stats"] = {
		{ "CTF wins", "CTFWins" },
		{ "CTF losses", "CTFLosses" },
		{ "Scrimmage wins", "ScrimmageWins" },
		{ "Scrimmage losses", "ScrimmageLosses" },
		{ "Control Points wins", "ControlPointsWins" },
		{ "Control Points losses", "ControlPointsLosses" },
	},
}

local TOOLS = { "Superball", "Bomb", "Rocket", "PaintballGun" }
local RANGED_STATS = {
	{
		header = "Long range kills (120+ studs)",
		statGroup = "longRange",
	},
	{
		header = "Medium range kills (70–120 studs)",
		statGroup = "mediumRange",
	},
	{
		header = "Close range kills (0–70 studs)",
		statGroup = "closeRange",
	},
}

local function makeCircle(props)
	return Roact.createFragment({
		UICorner = e("UICorner", {
			CornerRadius = UDim.new(0, 100_000),
		}),

		UIStroke = if not props.thickness
			then nil
			else e("UIStroke", {
				Color = props.color,
				Thickness = props.thickness,
			}),
	})
end

local function circle(props)
	return e(
		"Frame",
		{
			AnchorPoint = props.anchorPoint,
			Position = props.position,
			Size = props.size,

			BackgroundTransparency = if props.thickness then 1 else 0,
			BackgroundColor3 = props.color,
			BorderSizePixel = 0,

			ZIndex = props.zIndex,
		},
		Llama.Dictionary.merge({
			circle = e(makeCircle, props),
		}, props[Roact.Children])
	)
end

local function keyValueLayout(props)
	local children = {}
	local y = 0
	for i, entry in props.values do
		if type(entry[1]) == "string" then
			table.insert(
				children,
				e("TextLabel", {
					BackgroundTransparency = 1,

					AnchorPoint = Vector2.new(0, 0.5),
					Position = UDim2.new(0, -6, 0, y),
					Size = UDim2.new(0, 200, 0, 50),
					Font = Enum.Font.GothamBold,
					Text = "• " .. entry[1],
					TextSize = props.textSize,
					TextColor3 = props.textColor,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextYAlignment = Enum.TextYAlignment.Center,
				})
			)

			table.insert(
				children,
				e("TextLabel", {
					BackgroundTransparency = 1,

					AnchorPoint = Vector2.new(1, 0.5),
					Position = UDim2.new(1, -6, 0, y),
					Size = UDim2.new(0, 200, 0, 50),
					Font = Enum.Font.Gotham,
					Text = entry[2],
					TextSize = props.textSize,
					TextColor3 = props.textColor,
					TextXAlignment = Enum.TextXAlignment.Right,
					TextYAlignment = Enum.TextYAlignment.Center,
				})
			)
		else
			table.insert(children, entry[1])
			table.insert(children, entry[2])
		end

		y += props.textSize

		if props.values[i + 1] then
			table.insert(
				children,
				e("Frame", {
					AnchorPoint = Vector2.new(0.5, 0),
					Position = UDim2.new(0.5, 0, 0, y),
					Size = UDim2.new(1, 0, 0, 2),
					BackgroundColor3 = props.dividerColor,
					BorderSizePixel = 0,
				})
			)
		end

		y += props.yPadding
	end

	return Roact.createFragment(children)
end

local function progressBar(props, hooks)
	local gradientRef = hooks.useBinding()

	local activeShineColor = props.activeColor:Lerp(Color3.new(1, 1, 1), 0.4)

	return e("Frame", {
		AnchorPoint = props.anchorPoint,
		Size = props.size,
		Position = props.position,

		BackgroundColor3 = props.backgroundColor,
		BorderSizePixel = 0,
	}, {
		UICorner = e("UICorner", {
			CornerRadius = UDim.new(0, 10),
		}),

		UIStroke = e("UIStroke", {
			Color = props.strokeColor,
			Thickness = 2,
		}),

		Active = e("Frame", {
			Size = UDim2.new(math.clamp(props.percent, 0.05, 1), 0, 1, 0),
			BackgroundColor3 = Color3.new(1, 1, 1),
			BorderSizePixel = 0,
		}, {
			UICorner = e("UICorner", {
				CornerRadius = UDim.new(0, 10),
			}),
			UIGradient = e("UIGradient", {
				[Roact.Ref] = gradientRef,
				Rotation = 90,
				Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, activeShineColor),
					ColorSequenceKeypoint.new(0.2, props.activeColor),
					ColorSequenceKeypoint.new(1, props.activeColor),
				}),
			}),
		}),
	})
end

progressBar = RoactHooks.new(Roact)(progressBar)

local function dropdownBar(props, hooks)
	local theme = hooks.useContext(ThemeContext)
	local isCollapsed, setIsCollapsed = hooks.useState(false)

	local styles, api = RoactSpring.useSpring(hooks, function()
		return { alpha = if isCollapsed then 1 else 0 }
	end)

	local selectedPlayerTextBounds =
		TextService:GetTextSize(props.selectedPlayer.displayName, 20, Enum.Font.Gotham, Vector2.new(100, props.ySize))
	local maxSize = Vector2.new(200 + 30 * 3, selectedPlayerTextBounds.Y)

	local children = {}
	children.UICorner = e("UICorner", {
		CornerRadius = UDim.new(0, 6),
	})
	children.UIStroke = e("UIStroke", {
		Thickness = 2,
		Color = props.borderColor,
	})

	hooks.useEffect(function()
		if isCollapsed then
			api.start({
				alpha = 1,
				config = { tension = 400 },
			})
		else
			api.start({
				alpha = 0,
				config = { frequency = 0.1 },
			})
		end

		local connection = UserInputService.InputBegan:Connect(function(input, gp)
			if gp then
				return
			end

			if
				isCollapsed
				and (
					input.UserInputType == Enum.UserInputType.MouseButton1
					or input.UserInputType == Enum.UserInputType.Touch
				)
			then
				setIsCollapsed(false)
			end
		end)

		return function()
			connection:Disconnect()
		end
	end)

	local y = 0
	local players = {}
	table.insert(players, props.selectedPlayer)
	for _, player in props.players do
		table.insert(players, player)
	end

	for i, player in players do
		local advancer = declareUtils.NumberAdvancer.new(props.iconSize.X.Offset)
		local textBounds =
			TextService:GetTextSize(player.displayName, 20, Enum.Font.Gotham, Vector2.new(maxSize.X - 70, props.ySize))
		textBounds += Vector2.new(8, 0)

		table.insert(
			children,
			e("TextButton", {
				BackgroundTransparency = 1,

				LayoutOrder = i,
				Size = UDim2.new(0, maxSize.X, 0, props.ySize),
				Position = UDim2.new(0, 0, 0, y),
				Text = "",

				[Roact.Event.MouseButton1Down] = function()
					setIsCollapsed(not isCollapsed)

					if i ~= 1 then
						props.onChosenPlayer(player)
					end
				end,
			}, {
				Image = e("ImageLabel", {
					BackgroundTransparency = 1,
					Image = declareUtils.doThis(function()
						local binding, set = Roact.createBinding()
						player.image:andThen(function(content)
							set(content)
						end)

						return binding
					end),

					AnchorPoint = Vector2.new(0.5, 0.5),
					Size = props.iconSize,
					Position = UDim2.new(0, advancer:advance(30), 0.5, 0),
				}),
				DisplayName = e("TextLabel", {
					BackgroundTransparency = 1,
					Position = UDim2.new(0, advancer:add(0), 0, 0),
					Size = UDim2.new(0, advancer:advance(textBounds.X), 0, props.ySize),
					TextTruncate = Enum.TextTruncate.AtEnd,

					TextXAlignment = Enum.TextXAlignment.Left,
					Font = Enum.Font.Gotham,
					TextColor3 = props.displayNameColor,
					TextSize = 20,
					Text = player.displayName,
				}),
				Name = e("TextLabel", {
					Visible = (maxSize.X - advancer.number) > 100,

					BackgroundTransparency = 1,
					Position = UDim2.new(0, advancer:add(3), 0, 2),
					Size = UDim2.new(0, maxSize.X - advancer.number - 30, 0, props.ySize),
					TextTruncate = Enum.TextTruncate.AtEnd,

					TextXAlignment = Enum.TextXAlignment.Left,
					Font = Enum.Font.Gotham,
					TextColor3 = props.nameColor,
					TextSize = 14,
					Text = "@" .. player.name,
				}),
			})
		)

		y += props.ySize + 6

		if players[i + 1] then
			table.insert(
				children,
				e("Frame", {
					Size = UDim2.new(1, 0, 0, 2),
					Position = UDim2.new(0, 0, 0, y),
					BackgroundColor3 = props.borderColor,
					BorderSizePixel = 0,
				})
			)

			y += 6
		end
	end

	return e("ScrollingFrame", {
		ClipsDescendants = true,

		BackgroundTransparency = 0,
		BorderSizePixel = 0,
		BackgroundColor3 = props.backgroundColor,
		Size = styles.alpha:map(function(value)
			return UDim2.new(0, maxSize.X, 0, math.clamp(props.ySize + (y - props.ySize) * value, 0, 300))
		end),
		CanvasSize = styles.alpha:map(function(value)
			return UDim2.new(1, 0, 0, y * value)
		end),
		ScrollBarImageColor3 = theme.scrollbar,
		ScrollBarThickness = 6,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		Position = props.position,
		ZIndex = props.zIndex,
	}, children)
end

dropdownBar = RoactHooks.new(Roact)(dropdownBar)

local function getPlaceString(place)
	if place == nil then
		return "100th+"
	end

	if type(place) == "string" then
		return place
	end

	local str = tostring(place)
	local last = string.sub(str, -1, -1)

	if str == "11" then
		return "11th"
	elseif str == "12" then
		return "12th"
	elseif str == "13" then
		return "13th"
	elseif last == "1" then
		return str .. "st"
	elseif last == "2" then
		return str .. "nd"
	elseif last == "3" then
		return str .. "rd"
	end

	return str .. "th"
end

local function getKDRString(stats)
	local kdr
	if stats.WOs == 0 then
		kdr = stats.KOs
	else
		kdr = stats.KOs / stats.WOs
	end

	return string.format("%.1f", kdr)
end

local SECONDS_IN_DAY = 60 * 60 * 24
local SECONDS_IN_HOUR = 60 * 60
local function getTimePlayedString(secondsPlayed)
	return string.format("%dd %dh", secondsPlayed / SECONDS_IN_DAY, (secondsPlayed % SECONDS_IN_DAY) / SECONDS_IN_HOUR)
end

local function profileMainWidget(props, hooks)
	local theme = hooks.useContext(ThemeContext)
	local outerRef = hooks.useBinding()

	local selectedTab, setSelectedTab = hooks.useState(STAT_TABS[1])
	local selectedUserId, setSelectedUserId = hooks.useState(props.localUserId)
	local selectedPlayer = props.players[selectedUserId] or props.players[props.localUserId]

	local advanceY = declareUtils.NumberAdvancer.new(0)
	-- local advanceBarY = declareUtils.NumberAdvancer.new(0)

	return e("Frame", {
		[Roact.Ref] = outerRef,

		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
	}, {
		Window = e(window, {
			size = UDim2.new(0, 660, 0, 515),
			image = "rbxassetid://10866961648",
			imageSize = Vector2.new(63, 50),
			name = "User stats",
			useExitButton = true,
			draggable = true,

			topColor = theme.foreground,
			outerRef = outerRef,
			onClosed = props.onClosed,
		}, {
			-- Center = e("Frame", {
			-- 	AnchorPoint = Vector2.new(0, 0.5),
			-- 	Size = UDim2.new(1, 0, 0, 2),
			-- 	Position = UDim2.new(0, 0, 0.5, 0),
			-- 	ZIndex = 20,
			-- }),
			Background = e("Frame", {
				Size = UDim2.new(1, 0, 1, 0),
				BorderSizePixel = 0,
				BackgroundColor3 = Color3.new(1, 1, 1),
				ZIndex = -1,
			}, {
				UIGradient = e("UIGradient", {
					Rotation = 90,
					Color = ColorSequence.new({
						ColorSequenceKeypoint.new(0, theme.background),
						ColorSequenceKeypoint.new(0.3, theme.background),
						ColorSequenceKeypoint.new(1, theme.background:Lerp(Color3.new(0, 0, 0), 0)),
					}),
				}),
			}),
			Border = e("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(0.5, 0, 0.5, -62 / 2),
				Size = UDim2.new(1, 20, 1, 20 + 62),
				BorderSizePixel = 0,
				ZIndex = -2,
			}, {
				UIGradient = e("UIGradient", {
					Rotation = 90,
					Color = ColorSequence.new({
						ColorSequenceKeypoint.new(0, Color3.fromRGB(74, 81, 91)),
						ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 0)),
					}),
				}),
			}),

			Dropdown = e(dropdownBar, {
				position = UDim2.new(0, MARGIN / 2, 0, advanceY:add(MARGIN)),
				iconSize = UDim2.new(0, 30, 0, 30),

				selectedPlayer = selectedPlayer,
				players = props.players,

				ySize = advanceY:advance(30),
				backgroundColor = theme.foreground,
				displayNameColor = theme.highContrast,
				borderColor = theme.border,
				nameColor = theme.text,
				zIndex = 8,

				onChosenPlayer = function(player)
					setSelectedUserId(player.userId)
				end,
			}),

			ProgressBars = e("Frame", {
				Position = UDim2.new(0, 64, 0, advanceY:add(MARGIN)),
				Size = UDim2.new(0, 580, 0, 124 + STROKE_THICKNESS + STROKE_THICKNESS / 2),
				BackgroundColor3 = Color3.new(1, 1, 1),
				BorderSizePixel = 0,
				ZIndex = 1,
			}, {
				UIGradient = e("UIGradient", {
					Color = ColorSequence.new({
						ColorSequenceKeypoint.new(0, Color3.fromRGB(36, 57, 60):Lerp(theme.background, 0.5)),
						ColorSequenceKeypoint.new(0.6, Color3.fromRGB(36, 57, 60):Lerp(theme.background, 0.5)),
						ColorSequenceKeypoint.new(1, theme.background),
					}),
				}),

				-- Objective1 = e("TextLabel", {
				-- 	BackgroundTransparency = 1,
				-- 	RichText = true,
				-- 	Position = UDim2.new(0, 126, 0, advanceBarY:add(20)),
				-- 	Font = Enum.Font.GothamBold,
				-- 	TextColor3 = theme.highContrast,
				-- 	TextXAlignment = Enum.TextXAlignment.Left,
				-- 	Text = string.format(
				-- 		[[<font size="22">Get 30 KOs</font>]] .. [[<font size="14" color="#%s"> (44%%)</font>]],
				-- 		theme.text:ToHex()
				-- 	),
				-- }),

				-- Progress1 = e(progressBar, {
				-- 	position = UDim2.new(0, 126, 0, advanceBarY:add(20)),
				-- 	size = UDim2.new(0, 420, 0, advanceBarY:advance(22)),
				-- 	activeColor = Color3.fromRGB(58, 140, 39),
				-- 	backgroundColor = Color3.fromRGB(29, 31, 35),
				-- 	strokeColor = theme.border,
				-- 	percent = 0.25,
				-- }),

				-- Objective2 = e("TextLabel", {
				-- 	BackgroundTransparency = 1,
				-- 	RichText = true,
				-- 	Position = UDim2.new(0, 126, 0, advanceBarY:add(26)),
				-- 	Font = Enum.Font.GothamBold,
				-- 	TextColor3 = theme.highContrast,
				-- 	TextXAlignment = Enum.TextXAlignment.Left,
				-- 	Text = string.format(
				-- 		[[<font size="22">Get 300 XP</font>]] .. [[<font size="14" color="#%s"> (44%%)</font>]],
				-- 		theme.text:ToHex()
				-- 	),
				-- }),

				-- Progress2 = e(progressBar, {
				-- 	position = UDim2.new(0, 126, 0, advanceBarY:add(20)),
				-- 	size = UDim2.new(0, 420, 0, advanceBarY:advance(22)),
				-- 	activeColor = Color3.fromRGB(58, 140, 39),
				-- 	backgroundColor = Color3.fromRGB(29, 31, 35),
				-- 	strokeColor = theme.border,
				-- 	percent = 0.44,
				-- }),
			}),

			CharacterIcon = e(circle, {
				position = UDim2.new(0, STROKE_THICKNESS + MARGIN / 2, 0, advanceY:add(MARGIN - 6)),
				size = UDim2.new(0, 120 + STROKE_THICKNESS, 0, advanceY:advance(120 + STROKE_THICKNESS)),
				color = theme.foreground,
				zIndex = 2,
			}, {
				-- Rank = e("ImageLabel", {
				-- 	Image = "rbxassetid://11695217168",
				-- 	BackgroundTransparency = 1,
				-- 	AnchorPoint = Vector2.new(0.5, 0),
				-- 	Size = UDim2.new(0, 142 * 0.5, 0, 92 * 0.5),
				-- 	Position = UDim2.new(0.5, 0, 1, -34),
				-- }),
				Icon = e("ImageLabel", {
					BorderSizePixel = 0,
					BackgroundTransparency = 1,
					Image = declareUtils.doThis(function()
						local binding, set = Roact.createBinding()
						selectedPlayer.image:andThen(function(content)
							set(content)
						end)

						return binding
					end),

					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.new(0.5, 0, 0.5, 0),
					Size = UDim2.new(1, -STROKE_THICKNESS, 1, -STROKE_THICKNESS),
				}, {
					e(makeCircle),
				}),
				Border = e(circle, {
					anchorPoint = Vector2.new(0.5, 0.5),
					position = UDim2.new(0.5, 0, 0.5, 0),
					size = UDim2.new(1, 0, 1, 0),
					thickness = advanceY:advance(STROKE_THICKNESS / 2),
					color = theme.border,
				}, {
					BorderBackground = e(circle, {
						anchorPoint = Vector2.new(0.5, 0.5),
						position = UDim2.new(0.5, 0, 0.5, 0),
						size = UDim2.new(1, STROKE_THICKNESS, 1, STROKE_THICKNESS),
						thickness = MARGIN,
						color = theme.background,
					}),
				}),
			}),

			TopStats = e("Frame", {
				AnchorPoint = Vector2.new(0.5, 0),
				Position = UDim2.new(0.5, 0, 0, advanceY:add(MARGIN)),
				Size = UDim2.new(1, -MARGIN * 2, 0, advanceY:advance(100)),
				BorderSizePixel = 0,
				BackgroundColor3 = Color3.new(1, 1, 1),
				ZIndex = 5,
			}, {
				UIGradient = e("UIGradient", {
					Rotation = 90,
					Color = ColorSequence.new({
						ColorSequenceKeypoint.new(0, Color3.fromRGB(37, 41, 48)),
						ColorSequenceKeypoint.new(1, Color3.fromRGB(25, 28, 31)),
					}),
				}),
				UICorner = e("UICorner", {
					CornerRadius = UDim.new(0, 12),
				}),

				Text1 = e("TextLabel", {
					Font = Enum.Font.Gotham,
					RichText = true,
					TextSize = 28,
					BackgroundTransparency = 1,
					AnchorPoint = Vector2.new(0.5, 0),
					Position = UDim2.new(0.15, 0, 0, 0),
					Size = UDim2.new(0, 200, 1, 0),
					Text = string.format(
						[[<font size="34"><b>%s</b></font><br /><font size="28">Place</font>]],
						getPlaceString(selectedPlayer.data.place)
					),
					TextColor3 = theme.highContrast,
					LayoutOrder = 1,
				}),
				Text2 = e("TextLabel", {
					Font = Enum.Font.Gotham,
					RichText = true,
					TextSize = 28,
					BackgroundTransparency = 1,
					AnchorPoint = Vector2.new(0.5, 0),
					Position = UDim2.new(0.5, 0, 0, 0),
					Size = UDim2.new(0, 200, 1, 0),
					Text = string.format(
						[[<font size="34"><b>%s</b></font><br /><font size="28">Kill-death ratio</font>]],
						getKDRString(selectedPlayer.data.stats)
					),
					TextColor3 = theme.highContrast,
					LayoutOrder = 2,
				}),
				Text3 = e("TextLabel", {
					Font = Enum.Font.Gotham,
					RichText = true,
					TextSize = 28,
					BackgroundTransparency = 1,
					AnchorPoint = Vector2.new(0.5, 0),
					Position = UDim2.new(0.85, -10, 0, 0),
					Size = UDim2.new(0, 200, 1, 0),
					Text = string.format(
						[[<font size="34"><b>%s</b></font><br /><font size="28">Time played</font>]],
						getTimePlayedString(selectedPlayer.data.timePlayed)
					),
					TextColor3 = theme.highContrast,
					LayoutOrder = 3,
				}),
			}),

			TabsPart = e("Frame", {
				BackgroundTransparency = 1,
				Position = UDim2.new(0, MARGIN + STROKE_THICKNESS / 4, 0, advanceY:add(MARGIN)),
				Size = UDim2.new(1, -MARGIN - (MARGIN + STROKE_THICKNESS / 4), 0, advanceY:advance(50)),
			}, {
				Tabs = e(
					"Frame",
					{
						BackgroundTransparency = 1,
						Size = UDim2.new(1, 0, 1, 0),
					},
					declareUtils.doThis(function()
						local elements = {}
						elements.UIListLayout = e("UIListLayout", {
							Padding = UDim.new(0, MARGIN),
							HorizontalAlignment = Enum.HorizontalAlignment.Left,
							VerticalAlignment = Enum.VerticalAlignment.Top,
							FillDirection = Enum.FillDirection.Horizontal,
						})

						for i, tabName in STAT_TABS do
							elements["Tab" .. tostring(i)] = e(button, {
								text = tabName,
								textSize = 24,
								color = if selectedTab == tabName then theme.background else theme.foreground,
								textColor = theme.highContrast,
								font = Enum.Font.GothamBold,
								padding = 12,

								onPressed = function()
									setSelectedTab(tabName)
								end,
							})
						end

						return elements
					end)
				),

				Table = declareUtils.doThis(function()
					local function layout(layoutProps)
						return e("Frame", {
							BackgroundTransparency = 1,
							Size = UDim2.new(1, 0, 0, 0),
							AutomaticSize = Enum.AutomaticSize.Y,
							Position = UDim2.new(0, 0, 0, 50 + MARGIN),
							LayoutOrder = layoutProps.layoutOrder,
						}, {
							Left = e("Frame", {
								BackgroundTransparency = 1,
								Size = UDim2.new(0.5, -20, 1, 0),
								Position = UDim2.new(0, 6, 0, 0),
							}, {
								KeyValues = e(keyValueLayout, {
									textSize = 20,
									dividerColor = theme.border,
									textColor = theme.highContrast,
									yPadding = 20,
									values = layoutProps.leftCons,
								}),
							}),

							Right = e("Frame", {
								BackgroundTransparency = 1,
								AnchorPoint = Vector2.new(1, 0),
								Size = UDim2.new(0.5, -20, 1, 0),
								Position = UDim2.new(1, 0, 0, 0),
							}, {
								KeyValues = e(keyValueLayout, {
									textSize = 20,
									dividerColor = theme.border,
									textColor = theme.highContrast,
									yPadding = 20,
									values = layoutProps.rightCons,
								}),
							}),
						})
					end

					local stats = selectedPlayer.data.stats
					local scrollingFrameRef = hooks.useBinding()
					hooks.useEffect(function()
						if scrollingFrameRef:getValue() then
							local listLayout = scrollingFrameRef:getValue().Frame.UIListLayout
							local size = listLayout.AbsoluteContentSize
							scrollingFrameRef:getValue().CanvasSize = UDim2.new(0, size.X, 0, size.Y)
						end
					end)

					if selectedTab == "Ranged stats" then
						local elements = {}
						elements.Dummy = e("Frame", {
							BackgroundTransparency = 1,
							LayoutOrder = 0,
						})

						elements.UIListLayout = e("UIListLayout", {
							FillDirection = Enum.FillDirection.Vertical,
							HorizontalAlignment = Enum.HorizontalAlignment.Center,
							VerticalAlignment = Enum.VerticalAlignment.Top,
							SortOrder = Enum.SortOrder.LayoutOrder,
							Padding = UDim.new(0, 36),
						})

						local layoutOrder = 1
						for _, entry in RANGED_STATS do
							table.insert(
								elements,
								e("TextLabel", {
									BackgroundTransparency = 1,
									Position = UDim2.new(0.5, 0, 0, 0),
									Size = UDim2.new(0, 200, 0, 0),
									Text = entry.header,
									Font = Enum.Font.GothamBold,
									TextSize = 28,
									TextColor3 = theme.highContrast,
									LayoutOrder = layoutOrder,
									-- TextYAlignment = Enum.TextYAlignment.Bottom;
								})
							)

							layoutOrder += 1

							local leftCons = {}
							local rightCons = {}
							local statGroup = stats[entry.statGroup]
							for i, toolName in TOOLS do
								table.insert(
									if i % 2 == 0 then rightCons else leftCons,
									{ toolName, statGroup[toolName] or 0 }
								)
							end

							table.insert(
								elements,
								e(layout, {
									leftCons = leftCons,
									rightCons = rightCons,
									layoutOrder = layoutOrder,
								})
							)

							layoutOrder += 1
						end

						return e("ScrollingFrame", {
							[Roact.Ref] = scrollingFrameRef,

							ScrollBarImageColor3 = theme.scrollbar,
							AutomaticCanvasSize = Enum.AutomaticSize.Y,
							ScrollingDirection = Enum.ScrollingDirection.Y,
							BorderSizePixel = 0,
							BackgroundTransparency = 1,
							Size = UDim2.new(1, 12, 0, 130),
							Position = UDim2.new(0, 0, 0, 30 + MARGIN),
						}, {
							Frame = e("Frame", {
								Size = UDim2.new(1, -12, 1, 0),
								BackgroundTransparency = 1,
							}, elements),
						})
					else
						local leftCons = {}
						local rightCons = {}
						for i, cons in STATS[selectedTab] do
							table.insert(if i % 2 == 0 then rightCons else leftCons, { cons[1], stats[cons[2]] })
						end

						return layout({ leftCons = leftCons, rightCons = rightCons })
					end
				end),
			}),
		}),
	})
end

return RoactHooks.new(Roact)(profileMainWidget)
