local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Roact = require(ReplicatedStorage.Packages.Roact)
local RoactHooks = require(ReplicatedStorage.Packages.RoactHooks)
local RoactSpring = require(ReplicatedStorage.Packages.RoactSpring)
local e = Roact.createElement

local button = require(script.Parent.Parent.Presentational.button)
local sidePanel = require(script.Parent.sidePanel)
local contents = require(script.Parent.contents)
local window = require(script.Parent.Parent.Presentational.window)

local ThemeContext = require(script.Parent.Parent.ThemeContext)

local SIDE_BAR_LENGTH = 4

local function countTable(t)
	local c = 0
	for _ in t do
		c += 1
	end

	return c
end

local function mainWidget(props, hooks)
	local categoryBinding, setCategory = hooks.useBinding(props.settingCategories[1])
	local isDisabled, setIsDisabled = hooks.useState(false)
	local selectedSettings, setSelectedSettings = hooks.useBinding({})
	local output, setOutput = hooks.useBinding(nil)

	local outerRef = hooks.useBinding()

	local styles, api = RoactSpring.useSpring(hooks, function()
		return {
			disabledAlpha = 0,
			disabledTransparency = 1,
		}
	end)

	local theme = hooks.useContext(ThemeContext)

	local selectEvent = Instance.new("BindableEvent")

	return e("Frame", {
		[Roact.Ref] = outerRef,

		Size = UDim2.fromScale(1, 1),
		Position = styles.disabledAlpha:map(function(alpha)
			return UDim2.new(0, 0, alpha, 20)
		end),

		BackgroundTransparency = 1,
	}, {
		Window = e(window, {
			size = UDim2.new(0, 1100, 0, 500),
			image = "rbxassetid://9206592117",
			imageSize = Vector2.new(50, 50),
			name = "Settings",
			useExitButton = false,
			draggable = not isDisabled,

			outerRef = outerRef,
		}, {
			DisabledOverlay = e("Frame", {
				Size = UDim2.new(1, 0, 1, 0),
				BackgroundColor3 = Color3.new(0, 0, 0),
				BackgroundTransparency = styles.disabledTransparency,
				ZIndex = 5,
			}),
			PanelContainer = e("Frame", {
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 0, 0, 20),
				Size = UDim2.new(1, 0, 1, -20),
			}, {
				Panel = e(sidePanel, {
					size = UDim2.new(0, 100, 1, 0),
					iconSize = UDim2.fromOffset(70, 70),
					dividerColor = theme.border,
					activeCategory = categoryBinding,

					settingCategories = props.settingCategories,
					onPressed = function(category)
						setCategory(category)
						selectEvent:Fire(function()
							return category
						end)
					end,
				}),
			}),

			ContentsContainer = e("ImageLabel", {
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 100 + SIDE_BAR_LENGTH, 0, 20),
				Size = UDim2.new(1, -100 - SIDE_BAR_LENGTH, 1, -88),

				Image = "rbxassetid://rbxassetid://10848356902",
			}, {
				Contents = e(contents, {
					settings = props.settingRecords,
					categories = props.settingCategories,
					changedSettings = props.changedSettings,

					onSettingChanged = props.onSettingChanged,
					onSettingCanceled = props.onSettingCanceled,

					categoryBinding = categoryBinding,
					selectEvent = selectEvent.Event,

					selectedSettings = selectedSettings,
					onSelectedChanged = function(settingId, isSelected)
						local clone = table.clone(selectedSettings:getValue())
						clone[settingId] = if isSelected then true else nil
						setSelectedSettings(clone)
						setOutput(nil)
					end,

					onCategoryChanged = function(category)
						setCategory(category)
					end,

					onPrompt = function(isPrompting)
						local promise = api.start({
							disabledAlpha = if isPrompting then 1 else 0,
							disabledTransparency = if isPrompting then 0 else 1,
						})

						if isPrompting then
							setIsDisabled(true)
						else
							promise:finally(function()
								setIsDisabled(false)
							end)
						end
					end,
				}),
			}),

			Selected = e(button, {
				position = UDim2.new(0, 116, 1, -10),
				anchor = Vector2.new(0, 1),
				minSize = Vector2.new(310, 48),
				padding = 10,

				textSize = 28,
				textColor = theme.highContrast,
				color = theme.lessImportantButton,

				text = Roact.joinBindings({ output, selectedSettings }):map(function(values)
					if values[1] then
						return values[1]
					end

					local count = countTable(values[2])

					if count > 0 then
						return string.format("Clear %d selection%s", count, if count > 1 then "s" else "")
					end

					return "Click settings to select"
				end),

				onPressed = function()
					if next(selectedSettings:getValue()) then
						setSelectedSettings({})
					end
				end,
			}),

			Confirm = e(button, {
				position = UDim2.new(0.5, 0, 1, -10),
				anchor = Vector2.new(0.5, 1),
				text = "Confirm",
				textSize = 28,
				minSize = Vector2.new(230, 0),
				color = theme.button,
				textColor = theme.highContrast,
				onPressed = function()
					props.onSettingsSaved()
					props.onClosed()
				end,
			}),

			Defaults = e(button, {
				position = UDim2.new(0.5, 240, 1, -10),
				anchor = Vector2.new(0.5, 1),
				text = "Restore defaults",
				textSize = 28,
				color = theme.lessImportantButton,
				textColor = theme.highContrast,
				onPressed = function()
					local selected = selectedSettings:getValue()

					local somethingSelected = next(selected) ~= nil
					local count = 0

					for _, settings in props.settingRecords do
						for _, setting in settings do
							if (not somethingSelected or selected[setting.id]) and setting.default ~= setting.value then
								count += 1
							end
						end
					end

					props.onRestoreDefaults(if next(selected) then selected else nil)
					setOutput(
						string.format("Restored %d default%s", count, if count > 1 or count == 0 then "s" else "")
					)
				end,
			}),

			Undo = e(button, {
				position = UDim2.new(0.5, 408, 1, -10),
				anchor = Vector2.new(0.5, 1),
				text = "Undo",
				textSize = 28,
				color = theme.lessImportantButton,
				textColor = theme.highContrast,
				onPressed = function()
					local selected = selectedSettings:getValue()

					local somethingSelected = next(selected) ~= nil
					local count = 0
					for _, settings in props.settingRecords do
						for _, setting in settings do
							if (not somethingSelected or selected[setting.id]) and setting.isChanged then
								count += 1
							end
						end
					end

					props.onSettingsCanceled(if next(selected) then selected else nil)
					setOutput(string.format("Undid %d setting%s", count, if count > 1 or count == 0 then "s" else ""))
				end,
			}),
		}),
	})
end

return RoactHooks.new(Roact)(mainWidget)
