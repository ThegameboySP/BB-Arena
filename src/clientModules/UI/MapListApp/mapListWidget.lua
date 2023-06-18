local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextService = game:GetService("TextService")

local Llama = require(ReplicatedStorage.Packages.Llama)
local Roact = require(ReplicatedStorage.Packages.Roact)
local RoactHooks = require(ReplicatedStorage.Packages.RoactHooks)
local e = Roact.createElement

local button = require(script.Parent.Parent.Presentational.button)
local window = require(script.Parent.Parent.Presentational.window)
local thumbnail = require(script.Parent.thumbnail)

local ThemeContext = require(script.Parent.Parent.ThemeContext)

local columns = {
	"Map name",
	"Teams",
	"Neutral allowed",
	"CTF",
	"Control Points",
	"Size",
	"Creator",
}

local booleanSort = function(a, b)
	return a.sortingColumn == "yes" and b.sortingColumn == "no"
end

local reverseBooleanSort = function(a, b)
	return a.sortingColumn == "no" and b.sortingColumn == "yes"
end

local defaultSort = function(a, b)
	return a.sortingColumn < b.sortingColumn
end

local reverseDefaultSort = function(a, b)
	return a.sortingColumn > b.sortingColumn
end

local sizeSort = function(a, b)
	local ax, az = a.sortingColumn:match("(%d+)x(%d+)")
	local bx, bz = b.sortingColumn:match("(%d+)x(%d+)")

	return (ax * az) > (bx * bz)
end

local reverseSizeSort = function(a, b)
	local ax, az = a.sortingColumn:match("(%d+)x(%d+)")
	local bx, bz = b.sortingColumn:match("(%d+)x(%d+)")

	return (ax * az) < (bx * bz)
end

local reverseSorts = {
	[booleanSort] = reverseBooleanSort,
	[defaultSort] = reverseDefaultSort,
	[sizeSort] = reverseSizeSort,
}

local sortingMethods = {
	["Neutral allowed"] = booleanSort,
	["CTF"] = booleanSort,
	["Control Points"] = booleanSort,
	["Size"] = sizeSort,
}

local PADDING_Y = 10

local function getThumbnail(props, selected)
	local mapThumbnail = nil
	if props.mapInfo[selected] then
		mapThumbnail = props.mapInfo[selected].Thumbnail
	elseif props.activeMap then
		mapThumbnail = props.mapInfo[props.activeMap].Thumbnail
	end

	if type(mapThumbnail) == "string" then
		return { image = mapThumbnail }
	end

	return mapThumbnail
end

local function mapListWidget(props, hooks)
	local theme = hooks.useContext(ThemeContext)
	local values = hooks.useValue()

	local sortBy, setSortBy = hooks.useState("Map name")
	local reversed, setReversed = hooks.useState(false)
	local selected, setSelected = hooks.useState(props.activeMap)
	local isFull, setIsFull = hooks.useState(false)

	if not next(values) then
		values.outerRef = Roact.createRef()
	end

	local outputTextBinding, setOutputText = hooks.useBinding("")

	local rowElements = {}
	local headerRowElements = {}

	local yContents = 0
	for i, column in columns do
		local text = column .. (if sortBy == column then reversed and " ▲" or " ▼" else "")
		local textBounds = TextService:GetTextSize(text, 24, Enum.Font.GothamBold, Vector2.new(200, 200))
		yContents = math.max(yContents, textBounds.Y)

		headerRowElements[column] = e("TextButton", {
			BackgroundTransparency = 1,

			Font = Enum.Font.GothamBold,
			Text = text,
			TextSize = 24,
			TextColor3 = theme.text,
			TextXAlignment = Enum.TextXAlignment.Center,
			TextYAlignment = Enum.TextYAlignment.Top,
			LayoutOrder = i,

			Size = UDim2.fromOffset(textBounds.X, textBounds.Y),
		})
	end

	local headerRef = hooks.useBinding()

	hooks.useEffect(function()
		local root = values.outerRef:getValue():FindFirstChild("Window")
		local scrollingFrame = root:FindFirstChild("ContentsContainer")

		local header = headerRef:getValue()
		local headerClone = header:Clone()
		headerClone:ClearAllChildren()

		local absolutePosition = header.AbsolutePosition

		local UIScale = header.Parent.Parent.UIScale
		local oldSizesByChild = {}
		local connections = {}
		for _, child in header:GetChildren() do
			-- I'm sorry.
			local position = child.AbsolutePosition - absolutePosition
			position /= UIScale.Scale

			local size = child.AbsoluteSize
			size /= UIScale.Scale

			local clone = child:Clone()
			clone.Size = UDim2.new(0, size.X, 0, size.Y)
			clone.Position = UDim2.new(0, position.X, 0, 0)
			clone.TextTransparency = 0
			clone.Parent = headerClone

			local column = child.Name
			table.insert(
				connections,
				clone.MouseButton1Down:Connect(function()
					if isFull then
						return
					end

					if sortBy == column then
						setReversed(not reversed)
					else
						setSortBy(column)
						setReversed(false)
					end
				end)
			)

			oldSizesByChild[child] = child.Size
			child.TextTransparency = 1
			child.Size = UDim2.new(0, child.Size.X.Offset, 0, 0)
		end

		local position = (scrollingFrame.AbsoluteSize - scrollingFrame.UITableLayout.AbsoluteContentSize).X
				/ UIScale.Scale
				/ 2
			+ scrollingFrame.Position.X.Offset

		headerClone.Position = UDim2.fromOffset(position, 20)
		headerClone.Parent = header.Parent.Parent

		return function()
			headerClone.Parent = nil

			for child, size in oldSizesByChild do
				child.Size = size
			end

			for _, connection in connections do
				connection:Disconnect()
			end
		end
	end)

	table.insert(
		rowElements,
		e("Frame", {
			[Roact.Ref] = headerRef,

			BackgroundTransparency = 1,
			Size = UDim2.fromOffset(300, 200),
		}, headerRowElements)
	)

	local rowValues = {}

	for _, mapInfo in props.mapInfo do
		local sortingColumn = mapInfo[sortBy]
		if type(sortingColumn) == "string" then
			sortingColumn = string.lower(sortingColumn)
		end

		table.insert(rowValues, {
			sortingColumn = sortingColumn,
			mapInfo = mapInfo,
		})
	end

	if reversed then
		local sortingMethod = sortingMethods[sortBy] or defaultSort
		table.sort(rowValues, reverseSorts[sortingMethod])
	else
		table.sort(rowValues, sortingMethods[sortBy] or defaultSort)
	end

	if props.activeMap then
		table.insert(rowValues, 1, {
			sortingColumn = props.mapInfo[props.activeMap][sortBy],
			mapInfo = props.mapInfo[props.activeMap],
		})
	end

	for _, entry in rowValues do
		local nextRowElements = {}
		local maxY = 0

		for _, column in columns do
			local value = entry.mapInfo[column]

			local str = tostring(value)

			local max = 160
			local textBounds = TextService:GetTextSize(str, 20, Enum.Font.Gotham, Vector2.new(max - 20, math.huge))
			textBounds = Vector2.new(math.min(max, textBounds.X + 20), textBounds.Y)
			maxY = math.max(maxY, textBounds.Y)

			table.insert(
				nextRowElements,
				e("TextLabel", {
					BackgroundTransparency = 1,

					Font = Enum.Font.Gotham,
					Text = str,
					TextSize = 20,
					TextTransparency = 0,
					TextWrapped = true,
					TextColor3 = theme.text,
					TextXAlignment = Enum.TextXAlignment.Center,
					TextYAlignment = Enum.TextYAlignment.Center,

					Size = UDim2.fromOffset(textBounds.X, textBounds.Y),
				})
			)
		end

		yContents += maxY + PADDING_Y * 2

		local isActive = props.activeMap == entry.mapInfo["Map name"]
		local isSelected = selected == entry.mapInfo["Map name"]

		table.insert(
			rowElements,
			e("TextButton", {
				BackgroundTransparency = if isSelected then 0.6 else 1,
				BackgroundColor3 = if isSelected then theme.accent elseif isActive then theme.text else theme.foreground,
				Text = "",

				TextTransparency = if isFull then 0 else 0.1,
				BorderSizePixel = 0,

				[Roact.Event.MouseButton1Down] = if isFull
					then nil
					else function()
						setSelected(entry.mapInfo["Map name"])
					end,
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

	hooks.useEffect(function()
		-- Sometimes cells are improperly sized in UITableLayout. This is essentially a hack to get :ApplyLayout.
		local root = values.outerRef:getValue():FindFirstChild("Window")
		local scrollingFrame = root:FindFirstChild("ContentsContainer")

		for _, child in scrollingFrame:GetChildren() do
			if child:IsA("GuiObject") then
				child.Visible = false
			end
		end

		local _ = scrollingFrame:FindFirstChild("UITableLayout").AbsoluteContentSize

		for _, child in scrollingFrame:GetChildren() do
			if child:IsA("GuiObject") then
				child.Visible = true
			end
		end
	end)

	return e("Frame", {
		[Roact.Ref] = values.outerRef,

		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
	}, {
		Window = e(window, {
			size = UDim2.new(0, 1100, 0, 550),
			image = "rbxassetid://10866961648",
			imageSize = Vector2.new(63, 50),
			name = "Map list",
			useExitButton = true,
			draggable = true,

			outerRef = values.outerRef,
			onClosed = props.onClosed,
		}, {
			-- Question = e("ImageButton", {
			-- 	AnchorPoint = Vector2.new(1, 1);
			-- 	Size = UDim2.new(0, 30, 0, 30);
			-- 	Position = UDim2.new(1, -10, 1, -56);

			-- 	BackgroundTransparency = 1;
			-- 	Image = "rbxassetid://11233340291";

			-- 	[Roact.Event.Activated] = function()
			-- 		api.start({ notificationAlpha = 0 })
			-- 	end;
			-- });
			-- NotificationInactive = e("Frame", {
			-- 	Size = UDim2.new(1, 0, 1, 0);
			-- 	BackgroundTransparency = styles.notificationAlpha:map(function(value)
			-- 		return 1 - ((1 - value) * 0.6)
			-- 	end);
			-- 	BorderSizePixel = 0;
			-- 	BackgroundColor3 = Color3.new(0, 0, 0);

			-- 	ZIndex = 9;
			-- });
			-- Notification = e("Frame", {
			-- 	AnchorPoint = Vector2.new(0.5, 1);
			-- 	Position = styles.notificationAlpha:map(function(value)
			-- 		return UDim2.new(0.5, 0, 1, 400 * value)
			-- 	end);
			-- 	Size = UDim2.new(0, 500, 0, 150);

			-- 	BorderSizePixel = 0;

			-- 	ZIndex = 10;
			-- }, {
			-- 	UIStroke = e("UIStroke", {
			-- 		Thickness = 2;
			-- 		Color = theme.border;
			-- 	});
			-- 	UICorner = e("UICorner", {
			-- 		CornerRadius = UDim.new(0, 8);
			-- 	});
			-- 	UIGradient = e("UIGradient", {
			-- 		Color = ColorSequence.new({
			-- 			ColorSequenceKeypoint.new(0, theme.foreground);
			-- 			ColorSequenceKeypoint.new(0.6, theme.foreground);
			-- 			ColorSequenceKeypoint.new(1, theme.background:Lerp(theme.foreground, 0));
			-- 		});
			-- 		Rotation = 90;
			-- 	});
			-- 	QuestionMark = e("TextLabel", {
			-- 		Position = UDim2.new(0, 20, 0, 26);

			-- 		TextColor3 = theme.highContrast;
			-- 		FontFace = Font.fromName("Gotham", Enum.FontWeight.Bold);
			-- 		TextSize = 50;

			-- 		Text = "?";
			-- 	});

			-- 	Description = e("TextLabel", {
			-- 		AnchorPoint = Vector2.new(0.5, 1);
			-- 		Position = UDim2.new(0.5, 0, 1, -34);
			-- 		Size = UDim2.new(0, 400, 0, 120);

			-- 		BackgroundColor3 = theme.background;
			-- 		BackgroundTransparency = 1;
			-- 		BorderSizePixel = 0;

			-- 		TextColor3 = theme.title;
			-- 		FontFace = Font.fromName("Gotham", Enum.FontWeight.Medium);
			-- 		TextSize = 28;
			-- 		TextWrapped = true;
			-- 		Text = [[Press a map name to view its thumbnail. Then click the thumbnail to toggle its visibility.]];
			-- 	});

			-- 	Ok = e(button, {
			-- 		text = "OK";
			-- 		position = UDim2.new(0.5, 0, 1, -6);
			-- 		anchor = Vector2.new(0.5, 1);
			-- 		color = theme.lessImportantButton;
			-- 		textColor = theme.highContrast;
			-- 		textSize = 28;

			-- 		padding = 10;
			-- 		minSize = Vector2.new(150, 40);

			-- 		onPressed = function()
			-- 			api.start({ notificationAlpha = 1 })
			-- 		end;
			-- 	});
			-- });
			ThumbnailContainer = e(thumbnail, {
				size = UDim2.new(1, -20, 1, -20),
				zIndex = if isFull then 2 else 0,
				isFull = isFull,
				thumbnail = getThumbnail(props, selected),

				onFullChanged = setIsFull,
			}),

			ContentsContainer = e(
				"ScrollingFrame",
				{
					BackgroundTransparency = 1,
					BackgroundColor3 = theme.foreground,
					ScrollBarImageColor3 = theme.scrollbar,
					BorderSizePixel = 0,
					ScrollBarThickness = 12,

					AnchorPoint = Vector2.new(0, 0),
					Position = UDim2.new(0, 20, 0, 46),
					Size = UDim2.new(1, -40, 0, 364),
					CanvasSize = UDim2.fromOffset(0, yContents),
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

			ChangeMap = e(button, {
				text = "Change to selected map",
				position = UDim2.new(0.5, 0, 0, 425),
				anchor = Vector2.new(0.5, 0),
				color = theme.lessImportantButton,
				textColor = theme.title,
				textSize = 28,

				onPressed = function()
					if selected and not isFull then
						local output = props.changeToMap(selected)
						setOutputText(output)
					end
				end,
			}),

			OutputContainer = e("Frame", {
				Visible = true,
				BackgroundTransparency = 1,
				ClipsDescendants = true,

				Size = UDim2.new(1, -20, 0, 50),
				AnchorPoint = Vector2.new(0.5, 1),
				Position = UDim2.new(0.5, 0, 1, 0),
			}, {
				Output = e("ImageLabel", {
					ImageColor3 = theme.foreground,
					Image = "rbxassetid://9264443152",
					ScaleType = Enum.ScaleType.Slice,
					SliceCenter = Rect.new(Vector2.new(128, 128), Vector2.new(128, 128)),
					SliceScale = 0.1,

					BorderSizePixel = 0,
					Size = UDim2.new(1, 0, 1, -10),
					AnchorPoint = Vector2.new(0.5, 1),
					Position = UDim2.new(0.5, 0, 1, -10),
					BackgroundTransparency = 1,
				}, {
					TextLabel = e("TextLabel", {
						BackgroundTransparency = 1,

						Size = UDim2.fromScale(1, 1),
						Position = UDim2.new(0, 0, 0, 0),

						Text = outputTextBinding,
						TextSize = 28,
						Font = Enum.Font.GothamSemibold,
						TextColor3 = theme.text,
					}),
				}),
			}),
		}),
	})
end

return RoactHooks.new(Roact)(mapListWidget)
