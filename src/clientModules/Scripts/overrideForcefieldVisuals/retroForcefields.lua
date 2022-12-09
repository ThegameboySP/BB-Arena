local CollectionService = game:GetService("CollectionService")

local FLASH_DURATION = 0.6
local COLORS = {
	BrickColor.new("Really red").Color,
	BrickColor.new("Really blue").Color,
}

local function createBox(part)
	local box = Instance.new("SelectionBox")
	box.Name = "ForceFieldBox"
	box.Adornee = part
	box.LineThickness = 0.09
	box.Parent = part

	return box
end

local function retroForcefields()
	local adornedCharacters = {}

	return {
		add = function(data)
			local boxes = {}
			local tag = tostring(data)
			for _, box in boxes do
				CollectionService:AddTag(box, tag)
			end

			adornedCharacters[data.character] = data

			local function onDescendantAdded(descendant)
				if descendant:IsA("BasePart") then
					local box = createBox(descendant)
					CollectionService:AddTag(box, tag)
				end
			end

			for _, descendant in data.character:GetDescendants() do
				onDescendantAdded(descendant)
			end

			local con1 = data.character.DescendantAdded:Connect(onDescendantAdded)
			local con2 = data.character.DescendantRemoving:Connect(function(descendant)
				CollectionService:RemoveTag(descendant, tag)

				local box = descendant:FindFirstChild("ForceFieldBox")
				if box then
					box.Parent = nil
				end
			end)

			data.disconnect = function()
				con1:Disconnect()
				con2:Disconnect()
			end

			return function(transparency)
				for _, box in CollectionService:GetTagged(tag) do
					box.Transparency = transparency
				end
			end
		end,
		remove = function(data)
			adornedCharacters[data.character] = nil

			for _, box in CollectionService:GetTagged(tostring(data)) do
				box.Parent = nil
			end

			data.disconnect()
		end,
		step = function()
			local currentTime = os.clock()

			for _, data in adornedCharacters do
				local timeElapsed = currentTime - data.startedTimestamp
				local colorIndex = math.floor(timeElapsed / FLASH_DURATION)
				colorIndex = (colorIndex % #COLORS) + 1

				local thisColor = COLORS[colorIndex]
				local nextColor = COLORS[colorIndex % #COLORS + 1]

				local alpha = (timeElapsed % FLASH_DURATION) / FLASH_DURATION
				local betweenColor = thisColor:Lerp(nextColor, alpha)

				for _, box in CollectionService:GetTagged(tostring(data)) do
					box.Color3 = betweenColor
				end
			end
		end,
	}
end

return retroForcefields
