local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Roact = require(ReplicatedStorage.Packages.Roact)
local Effects = require(ReplicatedStorage.Common.Utils.Effects)
local HUD = require(ReplicatedStorage.ClientModules.UI.HUD)
local RoduxFeatures = require(ReplicatedStorage.Common.RoduxFeatures)
local selectors = RoduxFeatures.selectors

local LocalPlayer = Players.LocalPlayer

local function mapTools(tools, order)
	local items = table.create(#tools)

	for _, tool in tools do
		local module
		if tool.Name == "Bomb" then
			local client = tool:FindFirstChild("Client")
			if client then
				local bombClient = client:FindFirstChild("BombClient")
				if bombClient then
					module = require(bombClient)
				end
			end
		end

		table.insert(items, {
			name = tool.Name,
			thumbnail = tool.TextureId,
			charge = if module
				then math.min(
					1,
					(os.clock() - (module.bombJumpTimestamp or 0)) / _G.BB.Settings.Bomb.BombJumpReloadTime
				)
				else nil,
		})
	end

	table.sort(items, function(a, b)
		return (table.find(order, a.name) or 0) < (table.find(order, b.name) or 0)
	end)

	return items
end

local function getToolInstanceByName(tools, name)
	for _, tool in tools do
		if tool.Name == name then
			return tool
		end
	end

	return nil
end

local function updateHUD(root)
	local Input = root.Input

	task.spawn(function()
		repeat
			task.wait()
		until pcall(function()
			StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
		end)
	end)

	local activeHumanoid = nil

	local function equipTool(tool)
		-- I don't know why, but if the character's parent is nil (when spawning),
		-- the tool is taken out of the DataModel, even when the character supposedly enters it.
		local character = LocalPlayer.Character
		local humanoid = character and character:FindFirstChild("Humanoid")
		if humanoid and character.Parent then
			humanoid:UnequipTools()

			if tool then
				tool.Parent = LocalPlayer.Character
			end
		end
	end

	local cachedTools = {}
	local equippedItemBinding, setEquippedItem = Roact.createBinding()
	local secondsTimerBinding, setSecondsTimer = Roact.createBinding(0)
	local toolsBinding, setTools = Roact.createBinding({})
	local toolTipBinding, setToolTip = Roact.createBinding("")
	local humanoidInfoBinding, setHumanoidInfo = Roact.createBinding({})
	local displayBattleInfoBinding, setDisplayBattleInfo = Roact.createBinding(false)

	local function updateProps()
		cachedTools = table.freeze(root.Tools:GetEquippedTools())
		setTools(table.freeze(mapTools(cachedTools, selectors.getLocalSetting(root.Store:getState(), "weaponOrder"))))

		local equippedTool = root.Tools:GetEquippedTool()
		if equippedTool then
			setEquippedItem(equippedTool.Name)
		end

		local timestamp = ReplicatedStorage:GetAttribute("TimerTimestamp")
		if timestamp then
			setSecondsTimer(timestamp - Workspace:GetServerTimeNow())
		end

		if activeHumanoid then
			setHumanoidInfo({
				health = activeHumanoid.Health,
				maxHealth = activeHumanoid.MaxHealth,
				isGodded = activeHumanoid:GetAttribute("IsGodded"),
			})
		end

		return {
			equippedItemBinding = equippedItemBinding,
			itemsBinding = toolsBinding,

			toolTipBinding = toolTipBinding,
			humanoidInfoBinding = humanoidInfoBinding,

			failedAction = Input.ActionFailure,

			onEquipped = function(itemName)
				equipTool(getToolInstanceByName(cachedTools, itemName))
			end,

			displayBattleInfoBinding = displayBattleInfoBinding,
			secondsTimerBindingBinding = secondsTimerBinding,
		}
	end

	local screenGui = Instance.new("ScreenGui")
	screenGui.ResetOnSpawn = false
	screenGui.DisplayOrder = -1
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Parent = LocalPlayer.PlayerGui

	local handle = Roact.mount(Roact.createElement(HUD, updateProps()), screenGui)

	local function onTeamChanged()
		local team = LocalPlayer.Team
		if team and CollectionService:HasTag(team, "ToolsEnabled") then
			setDisplayBattleInfo(true)
		else
			setDisplayBattleInfo(false)
		end
	end

	LocalPlayer:GetPropertyChangedSignal("Team"):Connect(onTeamChanged)
	onTeamChanged()

	RunService.Heartbeat:Connect(function()
		local currentTool = root.Tools:GetEquippedTool()

		local strs = {}
		if currentTool and selectors.getLocalSetting(root.Store:getState(), "showToolHints") then
			for actionName, fns in Input:GetActions() do
				local keyName = Input:GetBoundKeyNameForAction(actionName)
				local text, input = fns.text(currentTool, root)

				if input or keyName then
					table.insert(strs, string.format("[%s] - %s", input or keyName, text))
				end
			end
		end

		local newToolTip = table.concat(strs, " ")
		if newToolTip ~= toolTipBinding:getValue() then
			setToolTip(newToolTip)
		end

		if handle then
			updateProps()
		end
	end)

	root.Input.EquippedItemHotkey:Connect(function(order)
		local item = toolsBinding:getValue()[order]
		if displayBattleInfoBinding:getValue() and item then
			local equippedTool = root.Tools:GetEquippedTool()
			if equippedTool and equippedTool.instance.Name == item.name then
				equipTool(nil)
			else
				equipTool(getToolInstanceByName(cachedTools, item.name))
			end
		end
	end)

	Effects.call(
		LocalPlayer,
		Effects.pipe({
			Effects.character,
			function(character)
				activeHumanoid = character:FindFirstChild("Humanoid")

				return function()
					activeHumanoid = nil
				end
			end,
		})
	)
end

return updateHUD
