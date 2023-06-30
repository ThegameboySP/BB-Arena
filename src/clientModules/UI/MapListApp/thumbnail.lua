local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")

local Roact = require(ReplicatedStorage.Packages.Roact)
local RoactHooks = require(ReplicatedStorage.Packages.RoactHooks)
local RoactSpring = require(ReplicatedStorage.Packages.RoactSpring)
local Promise = require(ReplicatedStorage.Packages.Promise)
local e = Roact.createElement

local blendAlpha = require(script.Parent.Parent.Utils.blendAlpha)
local Snowfall = require(script.Parent.Parent.Effects.Snowfall)
local classicHalloweenSounds = require(script.Parent.Parent.Effects.classicHalloweenSounds)
local ThumbnailAnimator = require(script.Parent.ThumbnailAnimator)

local function useSnow(thumbnail)
	return if type(thumbnail) == "table" then thumbnail.snow == true else false
end

local function buildThumbnails(thumbnail)
	if thumbnail == nil then
		return {}
	end

	local array = if thumbnail[1] then thumbnail else { thumbnail }
	local thumbnailsCopy = {}
	for _, thumbnailEntry in array do
		table.insert(thumbnailsCopy, table.clone(thumbnailEntry))
	end

	for index, clone in thumbnailsCopy do
		clone.ref = Roact.createRef()
		clone.positionBinding, clone.setPosition = Roact.createBinding(UDim2.new(0.5, 0, 0.5, 0))

		if index == #thumbnailsCopy then
			clone.next = thumbnailsCopy[1]
		else
			clone.next = thumbnailsCopy[index + 1]
		end
	end

	return thumbnailsCopy
end

local function thumbnailKeyFn(thumbnail)
	return HttpService:JSONEncode(thumbnail)
end

local function thumbnail(props, hooks)
	local staticRef = hooks.useBinding()
	local effectsRef = hooks.useBinding()
	local styles, api = RoactSpring.useSpring(hooks, function()
		return { static = 1, transparency = 0, blendThumbnails = 0, effects = 0, snowAlpha = 0 }
	end)

	local thumbnails = hooks.useMemo(function()
		return buildThumbnails(props.thumbnail)
	end, { thumbnailKeyFn(props.thumbnail) })

	local currentThumbnail, setCurrentThumbnail = hooks.useState(nil)
	local lastThumbnail, setLastThumbnail = hooks.useState(nil)
	local lastThumbnails = hooks.useValue(thumbnails)
	local blendThumbnailPromise = hooks.useValue(Promise.resolve())
	local lastProps = hooks.useValue(props)

	-- print(
	-- 	"Current thumbnail:",
	-- 	currentThumbnail and table.find(thumbnails, currentThumbnail),
	-- 	"Last thumbnail:",
	-- 	lastThumbnail and table.find(thumbnails, lastThumbnail)
	-- )

	hooks.useEffect(function()
		local blend = false
		if lastThumbnail ~= currentThumbnail and lastProps.value == props then
			blend = true
		-- If we received new thumbnails: last = current, current = new.
		elseif lastThumbnails.value ~= thumbnails then
			lastThumbnails.value = thumbnails
			setLastThumbnail(currentThumbnail)
			setCurrentThumbnail(thumbnails[1])
			blend = true
		end

		lastProps.value = props

		if blend then
			blendThumbnailPromise.value = api.start({
				from = { blendThumbnails = 0 },
				to = { blendThumbnails = 1 },
				config = { duration = 2, easing = RoactSpring.easings.easeInOutQuad },
			})
		end

		if props.isFull then
			api.start({
				from = { static = 0 },
				to = { static = if currentThumbnail and currentThumbnail.creepy then 0.95 else 1 },
				config = { tension = 180, friction = 8, bounce = 1.5 },
			})
		end

		api.start({
			transparency = if props.isFull then 1 else 0,
			config = { tension = 250, clamp = true },
		})
	end)

	hooks.useEffect(function()
		-- Why a separate Animator class?
		-- 1.) can easily move multiple thumbnails
		-- 2.) less code here
		-- 3.) easily remember its state
		local connection = RunService.Heartbeat:Connect(function()
			local isResolved = blendThumbnailPromise.value:getStatus() == Promise.Status.Resolved

			for _, thumbnailInstance in thumbnails do
				if (thumbnailInstance == lastThumbnail and not isResolved) or thumbnailInstance == currentThumbnail then
					if not thumbnailInstance.animator then
						thumbnailInstance.animator = ThumbnailAnimator.new(thumbnailInstance)
					end

					local startMotor = thumbnailInstance.animator:Update()

					if thumbnailInstance == currentThumbnail and isResolved then
						if startMotor and #thumbnails > 1 then
							setCurrentThumbnail(thumbnailInstance.next)
							setLastThumbnail(thumbnailInstance)
						end
					end
				elseif isResolved then
					thumbnailInstance.animator = nil
				end
			end
		end)

		return function()
			connection:Disconnect()
		end
	end)

	local creepySounds = hooks.useValue(nil)
	hooks.useEffect(function()
		if currentThumbnail and currentThumbnail.creepy then
			if props.isFull then
				if not creepySounds.undo then
					creepySounds.soundGroup, creepySounds.undo = classicHalloweenSounds(staticRef:getValue())
				end

				TweenService:Create(creepySounds.soundGroup, TweenInfo.new(2), { Volume = 0.5 }):Play()
				return
			end
		end

		if creepySounds.undo then
			local tween = TweenService:Create(creepySounds.soundGroup, TweenInfo.new(2), { Volume = 0 })
			tween:Play()
			tween.Completed:Once(creepySounds.undo)
			creepySounds.undo = nil
			creepySounds.soundGroup = nil
		end
	end)

	hooks.useEffect(function()
		return function()
			if creepySounds.undo then
				creepySounds.undo()
			end
		end
	end, {})

	hooks.useEffect(function()
		local random = Random.new()
		local thread = task.spawn(function()
			while true do
				staticRef:getValue().ImageRectOffset =
					Vector2.new(random:NextInteger(0, 1024), random:NextInteger(0, 1024))

				task.wait(1 / 15)
			end
		end)

		return function()
			coroutine.close(thread)
		end
	end, {})

	local snowfall = hooks.useValue(nil)
	hooks.useEffect(function()
		if not snowfall.instance then
			snowfall.instance = Snowfall.new(effectsRef:getValue(), 600)
		end

		local lastConnection = snowfall.connection
		if useSnow(currentThumbnail) then
			if snowfall.connection then
				snowfall.connection:Disconnect()
			end

			snowfall.connection = RunService.Heartbeat:Connect(function(dt)
				snowfall.instance:Update(dt)
			end)
		end

		local doesUseSnow = useSnow(currentThumbnail)
		local promise = api.start({
			snowAlpha = if doesUseSnow then 0 else 1,
			config = {
				duration = if doesUseSnow then 2 else 1.2,
				easing = if doesUseSnow then RoactSpring.easings.easeInQuad else RoactSpring.easings.easeInOutQuad,
			},
		})

		return function()
			promise:andThen(function()
				if lastConnection and not useSnow(currentThumbnail) then
					lastConnection:Disconnect()
				end
			end)
		end
	end)

	hooks.useEffect(function()
		return function()
			if snowfall.connection then
				snowfall.connection:Disconnect()
			end

			snowfall.instance:Destroy()
		end
	end, {})

	local blendedThumbnailAlpha = Roact.joinBindings({
		transparency = styles.transparency:map(function(value)
			return 0.8 * (1 - value)
		end),
		blendThumbnails = styles.blendThumbnails,
	})

	return e("TextButton", {
		Active = true,
		ClipsDescendants = true,

		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = props.size,

		Text = "",
		BackgroundTransparency = 1,
		ZIndex = props.zIndex,

		[Roact.Event.Activated] = function()
			if currentThumbnail then
				props.onFullChanged(not props.isFull)
			end
		end,
	}, {
		Coverup = e("Frame", {
			Size = UDim2.new(1, 0, 1, 0),
			BorderSizePixel = 0,
			BackgroundColor3 = Color3.fromRGB(0, 0, 0),
			BackgroundTransparency = styles.transparency:map(function(value)
				return 1 - value
			end),
			ZIndex = -4,
		}),
		Static = e("ImageLabel", {
			[Roact.Ref] = staticRef,

			Visible = currentThumbnail ~= nil,

			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			Size = UDim2.new(1, 0, 1, 0),

			Image = "rbxassetid://268592485",
			BackgroundTransparency = 1,
			ImageTransparency = styles.static:map(function(value)
				return 0.8 - (1 - value) * 0.9
			end),

			ImageRectSize = Vector2.new(1024, 1024),
		}),
		ThumbnailContainer = e("Frame", {
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
			ZIndex = -3,
		}, {
			Thumbnail = e("ImageLabel", {
				ZIndex = 1,
				Size = UDim2.new(1, 40, 1, 40),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = if lastThumbnail then lastThumbnail.positionBinding else UDim2.new(0.5, 0, 0.5, 0),

				Image = if lastThumbnail then lastThumbnail.image else nil,
				ImageTransparency = blendedThumbnailAlpha:map(function(values)
					return blendAlpha({ values.transparency, values.blendThumbnails })
				end),
				BackgroundTransparency = 1,
			}),
			BlendThumbnail = e("ImageLabel", {
				ZIndex = 2,
				Size = UDim2.new(1, 40, 1, 40),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = if currentThumbnail then currentThumbnail.positionBinding else UDim2.new(0.5, 0, 0.5, 0),
				Image = if currentThumbnail then currentThumbnail.image else nil,
				ImageTransparency = blendedThumbnailAlpha:map(function(values)
					return blendAlpha({ values.transparency, 1 - values.blendThumbnails })
				end),
				BackgroundTransparency = 1,
			}),
			Effects = e("CanvasGroup", {
				[Roact.Ref] = effectsRef,

				ZIndex = 3,
				Size = UDim2.new(1, 40, 1, 40),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(0.5, 0, 0.5, 0),
				GroupTransparency = Roact.joinBindings({
					styles.transparency:map(function(value)
						return (1 - value) * 0.9
					end),
					styles.snowAlpha,
				}):map(blendAlpha),
				BackgroundTransparency = 1,
			}),
		}),
	})
end

return RoactHooks.new(Roact)(thumbnail)
