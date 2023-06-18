local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextService = game:GetService("TextService")

local Llama = require(ReplicatedStorage.Packages.Llama)
local Roact = require(ReplicatedStorage.Packages.Roact)
local RoactHooks = require(ReplicatedStorage.Packages.RoactHooks)
local e = Roact.createElement

local declareUtils = require(script.Parent.Parent.Utils.declareUtils)
local window = require(script.Parent.Parent.Presentational.window)

local ThemeContext = require(script.Parent.Parent.ThemeContext)

local columns = {
	"User",
	"KOs",
	"WOs",
	"KDR",
}

local numberSort = function(a, b)
	return a.sortingValue > b.sortingValue
end

local reverseNumberSort = function(a, b)
	return a.sortingValue < b.sortingValue
end

local defaultSort = function(a, b)
	return a.sortingValue < b.sortingValue
end

local reverseDefaultSort = function(a, b)
	return a.sortingValue > b.sortingValue
end

local KOSort = function(a, b)
	return a.userInfo.index < b.userInfo.index
end

local reverseKOSort = function(a, b)
	return a.userInfo.index > b.userInfo.index
end

local sortingMethods = {
	KOs = KOSort,
	WOs = numberSort,
	KDR = numberSort,
}

local reverseSorts = {
	[numberSort] = reverseNumberSort,
	[defaultSort] = reverseDefaultSort,
	[KOSort] = reverseKOSort,
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

local PADDING_Y = 10

local function leaderboardWidget(props, hooks)
	local theme = hooks.useContext(ThemeContext)

	local sortBy, setSortBy = hooks.useState("KOs")
	local reversed, setReversed = hooks.useState(false)
	local outerRef = hooks.useBinding()

	local rowElements = {}
	local headerRowElements = {}
	local yContents = 32 + PADDING_Y

	for i, column in columns do
		local text = column .. (if sortBy == column then reversed and " ▲" or " ▼" else "")
		local textBounds = TextService:GetTextSize(text, 32, Enum.Font.GothamBold, Vector2.new(200, 200))

		headerRowElements[column] = e("TextButton", {
			BackgroundTransparency = 1,

			Font = Enum.Font.GothamBold,
			Text = text,
			TextSize = 32,
			TextColor3 = theme.text,
			TextXAlignment = if column == "User" then Enum.TextXAlignment.Left else Enum.TextXAlignment.Center,
			TextYAlignment = Enum.TextYAlignment.Top,
			LayoutOrder = i,

			Size = UDim2.fromOffset(textBounds.X, textBounds.Y),

			[Roact.Event.Activated] = function()
				if sortBy == column then
					setReversed(not reversed)
				else
					setSortBy(column)
					setReversed(false)
				end
			end,
		})
	end

	table.insert(
		rowElements,
		e("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.fromOffset(300, 200),
		}, headerRowElements)
	)

	local rowValues = {}

	for _, userInfo in props.userInfo do
		local sortingColumn = userInfo[sortBy]

		local value = sortingColumn
		if type(sortingColumn) == "table" and sortingColumn.original then
			value = sortingColumn.original
		elseif type(sortingColumn) == "string" then
			value = string.lower(sortingColumn)
		end

		table.insert(rowValues, {
			sortingColumn = sortingColumn,
			sortingValue = value,
			userInfo = userInfo,
		})
	end

	if reversed then
		local sortingMethod = sortingMethods[sortBy] or defaultSort
		table.sort(rowValues, reverseSorts[sortingMethod])
	else
		table.sort(rowValues, sortingMethods[sortBy] or defaultSort)
	end

	for _, entry in rowValues do
		local nextRowElements = {}
		yContents += 28 + PADDING_Y * 2 + 2

		for _, column in columns do
			local value = entry.userInfo[column]
			if type(value) == "table" and value.original then
				value = value.string
			end

			local max = 550
			local textBounds
			if column == "User" then
				textBounds = Vector2.new(max, 0)
			else
				textBounds = TextService:GetTextSize(value, 28, Enum.Font.Gotham, Vector2.new(max - 20, 28))
				textBounds = Vector2.new(math.min(max, textBounds.X + 20), 0)
			end

			table.insert(
				nextRowElements,
				e(
					"Frame",
					{
						BackgroundTransparency = 1,
						Size = UDim2.fromOffset(textBounds.X, 30),
					},
					declareUtils.doThis(function()
						local xAdvancer = declareUtils.NumberAdvancer.new(0)

						return {
							Position = if column ~= "User"
								then nil
								else e("TextLabel", {
									AnchorPoint = Vector2.new(0, 0.5),
									Position = UDim2.new(0, 0, 0.5, 0),
									Size = UDim2.new(0, xAdvancer:advance(30), 0, 30),
									BackgroundTransparency = 1,

									Font = Enum.Font.Gotham,
									TextSize = 16,
									Text = tostring(entry.userInfo.index),
									TextColor3 = theme.highContrast,
								}),
							Icon = if column ~= "User"
								then nil
								else e("ImageLabel", {
									AnchorPoint = Vector2.new(0, 0.5),
									Position = UDim2.new(0, xAdvancer:add(0), 0.5, 0),
									Size = UDim2.new(0, 36, 0, 36),
									BackgroundTransparency = 1,

									Image = declareUtils.doThis(function()
										local binding, set = Roact.createBinding()
										entry.userInfo.image:andThen(function(content)
											set(content)
										end)

										return binding
									end),
								}, {
									e(makeCircle, {
										thickness = 2,
										color = theme.border,
									}),
								}),
							TextLabel = e("TextLabel", {
								AnchorPoint = if column == "User" then Vector2.new(0, 0.5) else Vector2.new(0.5, 0.5),
								Position = if column == "User"
									then UDim2.new(0, xAdvancer:add(50), 0.5, 0)
									else UDim2.new(0.5, 0, 0.5, 0),
								Size = UDim2.new(0, if column == "User" then textBounds.X - 80 else textBounds.X, 1, 8),

								BackgroundTransparency = 1,

								Font = Enum.Font.Gotham,
								Text = value,
								TextSize = 28,
								TextTransparency = 0,
								TextTruncate = Enum.TextTruncate.AtEnd,
								TextColor3 = theme.text,
								TextXAlignment = if column == "User"
									then Enum.TextXAlignment.Left
									else Enum.TextXAlignment.Center,
								TextYAlignment = Enum.TextYAlignment.Center,
							}),
						}
					end)
				)
			)
		end

		table.insert(
			rowElements,
			e("Frame", {
				BackgroundTransparency = 1,
			}, nextRowElements)
		)

		table.insert(
			rowElements,
			e("Frame", {
				Size = UDim2.new(0.1, 0, 0, 100),
				BorderColor3 = theme.border,
				BackgroundTransparency = 0,
			})
		)
	end

	local rowElementsMap = {}
	for i, element in rowElements do
		rowElementsMap[string.char(i)] = element
	end

	return e("Frame", {
		[Roact.Ref] = outerRef,

		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
	}, {
		Window = e(window, {
			size = UDim2.new(0, 1000, 0, 550),
			image = "rbxassetid://10866961648",
			imageSize = Vector2.new(63, 50),
			name = "Leaderboard",
			useExitButton = false,
			draggable = false,

			outerRef = outerRef,
			onClosed = props.onClosed,
		}, {
			ContentsContainer = e(
				"ScrollingFrame",
				{
					BackgroundTransparency = 1,
					BackgroundColor3 = theme.foreground,
					ScrollBarImageColor3 = theme.scrollbar,
					BorderSizePixel = 0,
					ScrollBarThickness = 12,

					AnchorPoint = Vector2.new(0.5, 1),
					Position = UDim2.new(0.5, 0, 1, 0),
					Size = UDim2.new(1, 0, 0, 540),
					CanvasSize = UDim2.new(1, 0, 0, yContents),
					ScrollingDirection = Enum.ScrollingDirection.Y,
				},
				Llama.Dictionary.merge({
					UITableLayout = e("UITableLayout", {
						Padding = UDim2.fromOffset(20, PADDING_Y),
						MajorAxis = Enum.TableMajorAxis.RowMajor,
						HorizontalAlignment = Enum.HorizontalAlignment.Center,
						SortOrder = Enum.SortOrder.Name,
					}),
				}, rowElementsMap)
			),
		}),
	})
end

return RoactHooks.new(Roact)(leaderboardWidget)
