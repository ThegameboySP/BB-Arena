local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")
local Selection = game:GetService("Selection")

local Definitions = require(ReplicatedStorage.Common.Definitions)

local MapRoot = Workspace:FindFirstChild("MapRoot")

local PROP_TAGS = {"ControlPoint", "CTF_Flag"}

local maps = ServerStorage.Maps:GetChildren()
for _, child in MapRoot:GetChildren() do
    table.insert(maps, child)
end

local selection = {}
for _, map in maps do
    local ok, err = Definitions.map(map)
    if not ok then
        warn(map:GetFullName(), ":", err)
        table.insert(selection, map)
    end

    local descendants = map:GetDescendants()
    
    local props = {}
    for _, descendant in descendants do
        for _, tag in PROP_TAGS do
            if CollectionService:HasTag(descendant, tag) then
                table.insert(props, descendant)
            end
        end
    end

    for _, prop in props do
        local isUnderGamemodeFolder = false
        local parent = prop.Parent

        while parent and parent ~= map do
            if parent:GetAttribute("Prototype_DisableRun") then
                isUnderGamemodeFolder = true
                break
            end

            parent = parent.Parent
        end

        if not isUnderGamemodeFolder then
            warn(("%s is not under a gamemode folder"):format(prop:GetFullName()))
            table.insert(selection, map)
        end
    end

    local unanchoredPaths = {}
    for _, descendant in descendants do
        if descendant:IsA("BasePart") and not descendant.Anchored then
            local parent = descendant.Parent
            local isUnderRegenGroup = false

            while parent and parent ~= map do
                if CollectionService:HasTag(parent, "RegenGroup") then
                    isUnderRegenGroup = true
                    break
                end

                parent = parent.Parent
            end

            if not isUnderRegenGroup then
                table.insert(unanchoredPaths, descendant:GetFullName())
            end
        end
    end

    if unanchoredPaths[1] then
        warn(("%s has some unanchored parts that aren't under a regen group."):format(map:GetFullName()), unanchoredPaths)
        table.insert(selection, map)
    end
end

if selection[1] then
    Selection:Set(selection)
end