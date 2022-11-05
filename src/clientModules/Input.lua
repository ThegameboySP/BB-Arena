local ContextActionService = game:GetService("ContextActionService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Signal = require(ReplicatedStorage.Packages.Signal)
local RoduxFeatures = require(ReplicatedStorage.Common.RoduxFeatures)
local getSavedSetting = RoduxFeatures.selectors.getSavedSetting
local ToolActions = require(ReplicatedStorage.Common.StaticData.ToolActions)

local UserId = Players.LocalPlayer.UserId

local Input = {}
Input.__index = Input

function Input.new(root)
    return setmetatable({
        ActionSuccess = Signal.new();
        ActionFailure = Signal.new();
        EquippedItemHotkey = Signal.new();

        root = root;
        equippedTool = nil;

        activeKeybinds = {};
        currentToolActions = nil;
        lastActive = {};
        lastTool = nil;
    }, Input)
end

-- TO TEST:
-- getSavedSetting should take an optional userId LAST. don't need LocalPlayer reference
-- ContextActionService "mock" (UnbindAction and BindAction only)
-- Tools needs to be mocked as well. Matter would work much better than this. though the toolset being OOP is problematic for testing
-- need a safe reference of Root (ugh)

-- so... save testing for later ! :D

function Input:onUpdate(new, old)
    local tool = self.root.Tools:GetEquippedTool()

    if tool and self.lastTool ~= tool.module then
        self.lastTool = tool.module
        table.clear(self.lastActive)
        
        for actionName in self.activeKeybinds do
            ContextActionService:UnbindAction(actionName)
        end
        table.clear(self.activeKeybinds)
    end

    if tool == nil then
        self.currentToolActions = nil
        return
    end

    self.currentToolActions = ToolActions[tool.instance.Name]

    local touchEnabled = UserInputService.TouchEnabled

    for actionName, fns in self.currentToolActions or {} do
        local isActive = (not touchEnabled) and fns.isActive(new)

        local keyName = getSavedSetting(new, UserId, actionName .. "Keybind")
        if
            self.lastActive[actionName] ~= isActive
            or old == nil
            or keyName ~= getSavedSetting(old, UserId, actionName .. "Keybind")
        then
            self.lastActive[actionName] = isActive
            
            if not isActive or keyName ~= self.activeKeybinds[actionName] then
                ContextActionService:UnbindAction(actionName)
                self.activeKeybinds[actionName] = nil
            end
            
            if isActive and pcall(function() return Enum.KeyCode[keyName] end) then
                ContextActionService:BindAction(actionName, function(_, state)
                    local success = fns.perform(tool, state, self.root)

                    if success == true then
                        self.ActionSuccess:Fire(actionName)
                    elseif success == false then
                        self.ActionFailure:Fire(actionName)
                    end
                end, false, Enum.KeyCode[keyName])

                self.activeKeybinds[actionName] = keyName
            end

            fns.setEnabled(isActive)
        end
    end
end

local enumToOrder = {
    [Enum.KeyCode.One] = 1;
    [Enum.KeyCode.Two] = 2;
    [Enum.KeyCode.Three] = 3;
    [Enum.KeyCode.Four] = 4;
    [Enum.KeyCode.Five] = 5;
    [Enum.KeyCode.Six] = 6;
    [Enum.KeyCode.Seven] = 7;
    [Enum.KeyCode.Eight] = 8;
    [Enum.KeyCode.Nine] = 9;
}

function Input:Init()
    self.root.Store.changed:connect(function(...)
        self:onUpdate(...)
    end)

    self:onUpdate(self.root.Store:getState(), nil)

    UserInputService.InputBegan:Connect(function(input, gp)
        if gp then
            return
        end

        local order = enumToOrder[input.KeyCode]
        if order then
            self.EquippedItemHotkey:Fire(order)
        end
    end)
end

function Input:onToolEquipped()
    self:onUpdate(self.root.Store:getState(), nil)
end

function Input:onToolUnequipped()
    self:onUpdate(self.root.Store:getState(), nil)
end

function Input:GetActiveActions()
    local activeActions = {}
    for actionName in self.activeKeybinds do
        activeActions[actionName] = self.currentToolActions[actionName]
    end

    return activeActions
end

function Input:GetActions()
    local tool = self.root.Tools:GetEquippedTool()
    if tool == nil then
        return {}
    end

    return ToolActions[tool.instance.Name] or {}
end

function Input:GetBoundKeyNameForAction(actionName)
    return self.activeKeybinds[actionName]
end

return Input