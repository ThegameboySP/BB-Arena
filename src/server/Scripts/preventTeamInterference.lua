local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local Teams = game:GetService("Teams")

local Spectators = Teams.Spectators
local MapRoot = Workspace.MapRoot
local SpectatorRegion = Workspace.SpectatorRegion

local onMap = RaycastParams.new()
onMap.FilterDescendantsInstances = {MapRoot}
onMap.FilterType = Enum.RaycastFilterType.Whitelist

local onSpectatorRegion = RaycastParams.new()
onSpectatorRegion.FilterDescendantsInstances = {SpectatorRegion}
onSpectatorRegion.FilterType = Enum.RaycastFilterType.Whitelist

local function getGroundedCharacters(players, params)
    local groundedCharacters = {}
    
    for _, player in pairs(players) do
        local character = player.Character
        if character == nil or not character.PrimaryPart then
            continue
        end

        local pos = character.PrimaryPart.Position
        local result = Workspace:Raycast(pos, -Vector3.yAxis * 20, params)

        if result then
            table.insert(groundedCharacters, character)
        end
    end

    return groundedCharacters
end

local function preventTeamInterference(Root)
    RunService.Heartbeat:Connect(function()
        for _, character in getGroundedCharacters(CollectionService:GetTagged("ParticipatingPlayer"), onSpectatorRegion) do
            Root.resetPlayer(Players:GetPlayerFromCharacter(character))
        end
    
        for _, character in getGroundedCharacters(Spectators:GetPlayers(), onMap) do
            Root.resetPlayer(Players:GetPlayerFromCharacter(character))
        end
    end)
end

return preventTeamInterference