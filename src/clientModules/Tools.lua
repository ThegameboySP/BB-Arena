local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Signal = require(ReplicatedStorage.Packages.Signal)
local Effects = require(ReplicatedStorage.Common.Utils.Effects)

local LocalPlayer = Players.LocalPlayer

local Tools = {}
Tools.__index = Tools

function Tools.new(root)
    return setmetatable({
        ToolEquipped = Signal.new();
        ToolUnequipped = Signal.new();

        equippedTool = nil;
        root = root;
    }, Tools)
end

function Tools:Init()
    Effects.call(LocalPlayer, Effects.pipe({
        Effects.character,
        Effects.childrenFilter(function(child)
            return child:IsA("Tool")
        end),
        function(tool)
            local function onDescendantAdded(descendant)
                if descendant:IsA("ModuleScript") and descendant.Name:lower():find("client$") then
                    self.equippedTool = {
                        instance = tool;
                        module = require(descendant);
                    }
                end
            end

            local connection = tool.DescendantAdded:Connect(onDescendantAdded)
            for _, descendant in tool:GetDescendants() do
                onDescendantAdded(descendant)
            end

            self.root.Input:onToolEquipped(tool)
            self.ToolEquipped:Fire(tool)

            return function()
                connection:Disconnect()
                self.equippedTool = nil
                self.root.Input:onToolUnequipped(tool)
                self.ToolUnequipped:Fire(tool)
            end
        end,
    }))
end

-- Returns module AND the instance.
function Tools:GetEquippedTool()
    if not self.equippedTool then
        return nil
    end

    return {
        module = self.equippedTool.module,
        instance = self.equippedTool.instance
    }
end

function Tools:GetEquippedTools()
    local tools = {}

    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if backpack then
        tools = backpack:GetChildren()
    end

    local character = LocalPlayer.Character
    if character then
        for _, child in character:GetChildren() do
            if child:IsA("Tool") then
                table.insert(tools, child)
            end
        end
    end

    -- local toolRecords = {}
    -- for _, tool in tools do
    --     local toolModule

    --     local clientFolder = tool:FindFirstChild("Client")
    --     if clientFolder then
    --         local module = clientFolder:FindFirstChild(tool.Name .. "Client")
    --         if module then
    --             toolModule = require(module)
    --         end
    --     end

    --     table.insert(toolRecords, {
    --         module = toolModule;
    --         instance = tool;
    --     })
    -- end

    return tools
end

return Tools