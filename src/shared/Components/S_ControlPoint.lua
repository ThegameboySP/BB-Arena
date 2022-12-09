local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local t = require(ReplicatedStorage.Packages.t)
local S_CapturableFlag = require(ReplicatedStorage.Common.Components.S_CapturableFlag)

local function makeOrderGui()
	local Part = Instance.new("Part")
	Part.Transparency = 1
	Part.Anchored = true
	Part.CanCollide = false
	Part.CanTouch = false
	Part.CanQuery = false

	local BillboardGui = Instance.new("BillboardGui")
	BillboardGui.ResetOnSpawn = false
	BillboardGui.Size = UDim2.new(12, 0, 8, 0)
	BillboardGui.ClipsDescendants = true
	BillboardGui.StudsOffset = Vector3.new(0, 10, 0)
	BillboardGui.Parent = Part

	local Order = Instance.new("TextLabel")
	Order.Name = "Order"
	Order.Size = UDim2.new(1, 0, 1, 0)
	Order.BackgroundTransparency = 1
	Order.TextColor3 = Color3.fromRGB(255, 255, 255)
	Order.Font = Enum.Font.GothamBlack
	Order.TextScaled = true
	Order.Parent = BillboardGui

	local UIStroke = Instance.new("UIStroke")
	UIStroke.Transparency = 0.3
	UIStroke.Thickness = 4
	UIStroke.Parent = Order

	return Part, Order
end

return S_CapturableFlag:extend("ControlPoint", {
	realm = "server",

	checkConfig = t.intersection(
		S_CapturableFlag.checkConfig,
		t.interface({
			IsCenter = t.boolean,
			Order = t.intersection(t.numberMin(0), t.integer),
		})
	),
	_getGroupsInside = S_CapturableFlag.GetTeamsInside,

	OnInit = function(self)
		local whitelisted = {}
		self.Whitelisted = whitelisted
		for _, team in pairs(CollectionService:GetTagged("FightingTeam")) do
			whitelisted[team] = true
		end

		S_CapturableFlag.OnInit(self)
	end,

	OnStart = function(self)
		S_CapturableFlag.OnStart(self)

		local part, textLabel = makeOrderGui()
		self.bin:Add(part)

		textLabel.Text = tostring(self.Config.Order)
		local CF, size = self.Instance:GetBoundingBox()
		part.CFrame = CF * CFrame.new(0, size.Y / 2, 0)
		part.Parent = workspace
	end,
})
