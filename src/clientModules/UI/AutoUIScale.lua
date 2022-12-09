local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GuiService = game:GetService("GuiService")

local Roact = require(ReplicatedStorage.Packages.Roact)
local AutoUIScale = Roact.Component:extend("UIScaledScreenGui")

function AutoUIScale:init(props)
	self.onScaleChanged = props and props.onScaleChanged
	self.ref = Roact.createRef()
	self.scaleBinding, self.updateScaleBinding = Roact.createBinding(1)
end

AutoUIScale.defaultProps = {
	minAxisSize = 320, -- minimum supported resolution (on small axis)
	maxAxisSize = 1080, -- max supported resolution (on small axis)
	minScaleRatio = 0.3, -- min scale ratio
	maxScaleRatio = 1, -- max scale ratio
}

function AutoUIScale:render()
	return Roact.createElement("UIScale", {
		Scale = self.scaleBinding,
		[Roact.Ref] = self.ref,
		[Roact.Event.AncestryChanged] = function()
			self:updateScale()
		end,
	})
end

function AutoUIScale:calculateRatio(minAxis, ignoreGuiInset)
	local guiInset = GuiService:GetGuiInset()
	local minAxisSize = self.props.minAxisSize
	if not ignoreGuiInset then
		minAxisSize = minAxisSize - guiInset.Y
	end
	local maxAxisSize = self.props.maxAxisSize
	local delta = maxAxisSize - minAxisSize
	local ratio = (minAxis - minAxisSize) / delta * (self.props.maxScaleRatio - self.props.minScaleRatio)
		+ self.props.minScaleRatio
	return math.clamp(ratio, 0.3, 1)
end

function AutoUIScale:clearListener()
	if self.viewportChangedListener then
		self.viewportChangedListener:Disconnect()
		self.viewportChangedListener = nil
	end
end

function AutoUIScale:setScale(scale)
	self.updateScaleBinding(scale)
	if self.onScaleChanged then
		self.onScaleChanged(scale)
	end
end

function AutoUIScale:updateScale()
	self:clearListener()
	local ref = self.ref:getValue()
	if ref then
		local viewport = ref:FindFirstAncestorWhichIsA("ScreenGui")
			or ref:FindFirstAncestorWhichIsA("DockWidgetPluginGui")
		if viewport then
			local absX = viewport.AbsoluteSize.X
			local absY = viewport.AbsoluteSize.Y
			local ignoredGuiInset = (not viewport:IsA("DockWidgetPluginGui") and viewport.IgnoreGuiInset)
			self:setScale(self:calculateRatio(math.min(absX, absY), ignoredGuiInset))
			self.viewportChangedListener = viewport:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
				self:setScale(
					self:calculateRatio(math.min(viewport.AbsoluteSize.X, viewport.AbsoluteSize.Y), ignoredGuiInset)
				)
			end)
		end
	end
end

function AutoUIScale:didMount()
	self:updateScale()
end

function AutoUIScale:didUpdate()
	self:updateScale()
end

function AutoUIScale:willUnmount()
	self:clearListener()
end

return AutoUIScale
