local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Roact = require(ReplicatedStorage.Packages.Roact)
local RoactHooks = require(ReplicatedStorage.Packages.RoactHooks)
local RoactSpring = require(ReplicatedStorage.Packages.RoactSpring)
local e = Roact.createElement

local HUDConstants = require(ReplicatedStorage.ClientModules.UI.HUDConstants)
local draggable = require(script.Parent.Parent.draggable)

local ITEM_SIZE = 62

function inventoryItem(props, hooks)
	local styles, api = RoactSpring.useSpring(hooks, function()
		return {
			position = UDim2.new(0, 0, 0, 0),
		}
	end)

	local positionBinding, setPosition = hooks.useBinding(UDim2.fromOffset(0, 0))
	local isButton = (props.onClicked ~= nil) or props.canDrag

	return e("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(ITEM_SIZE, ITEM_SIZE),
		LayoutOrder = props.layoutOrder,
	}, {
		DraggableArea = e(draggable, {
			positionBinding = { binding = positionBinding, set = setPosition },
			topRef = props.ref,
			outerRef = props.outerRef,
			scaleBinding = props.scaleBinding,
			position = positionBinding,

			enabled = props.canDrag,

			onDragBegin = function()
				api.stop()
			end,
			onDragged = props.onDragged,
			onDragReleased = function()
				local dir = (
					props.ref:getValue().Parent.Parent.AbsolutePosition - props.ref:getValue().Parent.AbsolutePosition
				).Unit
				if dir.X ~= dir.X then
					dir = Vector2.new(0, dir.Y)
				end

				if dir.Y ~= dir.Y then
					dir = Vector2.new(dir.X, 0)
				end

				api.start({
					immediate = true,
					to = { position = UDim2.fromOffset(dir.X * 7, dir.Y * 7) },
				}):andThen(function()
					api.start({
						to = { position = UDim2.fromOffset(0, 0) },
					})
				end)

				setPosition(UDim2.fromOffset(0, 0))

				props.onDragReleased()
			end,
		}, {
			Button = e(isButton and "TextButton" or "TextLabel", {
				[Roact.Ref] = props.ref,

				Size = UDim2.fromOffset(ITEM_SIZE, ITEM_SIZE),
				Position = styles.position,

				BackgroundColor3 = Color3.fromRGB(16, 17, 19),
				BackgroundTransparency = if props.selected then 0.4 else 0.55,
				AutoButtonColor = if isButton then false else nil,

				Text = "",

				BorderMode = Enum.BorderMode.Outline,
				BorderSizePixel = if props.selected then 3 else 0,
				BorderColor3 = Color3.new(1, 1, 1),

				[Roact.Event.MouseButton1Down] = if isButton then props.onClicked else nil,
			}, {
				Image = e("ImageLabel", {
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.new(0.5, 0, 0.5, 0),
					Size = UDim2.new(1, -HUDConstants.HUD_PADDING, 1, -HUDConstants.HUD_PADDING),

					BackgroundTransparency = 1,
					-- ImageTransparency = if props.selected then 0.2 else 0;
					Image = props.thumbnail,

					BorderSizePixel = 0,
				}),

				Charge = e("Frame", {
					AnchorPoint = Vector2.new(0.5, 1),
					Position = UDim2.new(0.5, 0, 1, -HUDConstants.HUD_PADDING / 2),
					Size = UDim2.new(
						1,
						-HUDConstants.HUD_PADDING,
						0,
						(ITEM_SIZE - HUDConstants.HUD_PADDING) * props.charge
					),

					BackgroundColor3 = Color3.fromRGB(123, 167, 233),
					BackgroundTransparency = 0.5,
					BorderSizePixel = 0,
				}),
			}),
		}),
	})
end

inventoryItem = RoactHooks.new(Roact)(inventoryItem)

local function mainWidget(props, hooks)
	local guiValuesToInsert = hooks.useValue()

	local itemElementsByName = {}
	local itemRefsByOrder = {}

	for itemIndex, item in props.items do
		local ref = Roact.createRef()
		table.insert(itemRefsByOrder, ref)

		itemElementsByName[item.name] = e(inventoryItem, {
			canDrag = props.onOrderChanged ~= nil,

			padding = HUDConstants.HUD_PADDING,
			thumbnail = item.thumbnail,
			selected = props.equippedItemName == item.name,
			charge = item.charge or 0,
			layoutOrder = itemIndex,

			ref = ref,
			outerRef = props.rootRef,
			scaleBinding = props.scaleBinding,

			onDragged = function()
				local gui = ref:getValue()
				guiValuesToInsert.distance = math.huge

				for index, itemRef in itemRefsByOrder do
					if itemRef ~= ref then
						local delta = gui.AbsolutePosition - itemRef:getValue().AbsolutePosition
						local distance = delta.Magnitude

						if distance < guiValuesToInsert.distance then
							guiValuesToInsert.distance = distance
							guiValuesToInsert.newIndex = index
							guiValuesToInsert.oldIndex = itemIndex
							guiValuesToInsert.item = item
						end
					end
				end
			end,

			onDragReleased = function()
				if guiValuesToInsert.distance <= 100 then
					local newLayout = table.clone(props.items)

					local newIndex = guiValuesToInsert.newIndex
					local oldIndex = guiValuesToInsert.oldIndex
					table.remove(newLayout, oldIndex)
					table.insert(newLayout, newIndex, guiValuesToInsert.item)

					props.onOrderChanged(newLayout)
				end
			end,

			onClicked = props.onEquipped and function()
				if props.equippedItemName == item.name then
					props.onEquipped(nil)
				else
					props.onEquipped(item.name)
				end
			end,
		})
	end

	itemElementsByName.UIListLayout = e("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		SortOrder = Enum.SortOrder.LayoutOrder,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		VerticalAlignment = Enum.VerticalAlignment.Bottom,
		Padding = UDim.new(0, HUDConstants.HUD_PADDING),
	})

	return Roact.createFragment(itemElementsByName)
end

mainWidget = RoactHooks.new(Roact)(mainWidget)

return mainWidget
