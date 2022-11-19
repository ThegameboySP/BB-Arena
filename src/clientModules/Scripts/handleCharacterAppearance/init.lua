local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Teams = game:GetService("Teams")

local Effects = require(ReplicatedStorage.Common.Utils.Effects)
local RoduxFeatures = require(ReplicatedStorage.Common.RoduxFeatures)
local selectors = RoduxFeatures.selectors
local addAccoutrement = require(script.addAccoutrement)
local noobAppearance = require(script.noobAppearance)

local LocalPlayer = Players.LocalPlayer

local function isEnemyFn(player)
    return player.Team ~= LocalPlayer.Team or LocalPlayer.Team == Teams.Gladiators
end

local function handleCharacterAppearance(root)
    local PlayerAppearances = ReplicatedStorage:FindFirstChild("PlayerAppearances")

    local function updatePlayer(player, folder)
        if not folder then
            return
        end

        local character = player.Character
        local tag = "LocalAppearanceInstance_" .. player.Name

        for _, instance in CollectionService:GetTagged(tag) do
            instance.Parent = nil
        end

        local children = folder:GetChildren()
        for _, child in children do
            if child.Name == "R6" then
                for _, r6Content in child:GetChildren() do
                    table.insert(children, r6Content)
                end
            end
        end

        local hasFace = false
        for _, child in children do
            if child.Name == "face" then
                hasFace = true
                break
            end
        end

        if not hasFace then
            table.insert(children, noobAppearance.face)
        end

        for _, child in children do
            if child:IsA("Accoutrement") then
                local clone = child:Clone()
                CollectionService:AddTag(clone, tag)
                clone:FindFirstChild("Handle").CanCollide = false
                addAccoutrement(character, clone)
            elseif
                child:IsA("BodyColors") or child:IsA("Shirt")
                or child:IsA("Pants") or child:IsA("ShirtGraphic")
                or child:IsA("CharacterMesh")
            then
                local clone = child:Clone()
                CollectionService:AddTag(clone, tag)
                clone.Parent = character
            elseif child.Name == "face" then
                local clone = child:Clone()
                CollectionService:AddTag(clone, tag)

                local head = character:FindFirstChild("Head")
                if head then
                    local oldFace = head:FindFirstChild("face")
                    if oldFace then
                        oldFace.Parent = nil
                    end

                    clone.Parent = head
                end
            end
        end
    end

    local playersToUpdate = {}

    root:getRemoteEvent("NewPlayerAppearance").OnClientEvent:Connect(function(userId)
        local player = Players:GetPlayerByUserId(userId)
        if player then
            playersToUpdate[player] = true
        end
    end)

    Effects.call(Players, Effects.pipe({
        Effects.children,
        function(player, add)
            local function update()
                playersToUpdate[player] = true
            end

            add(player, { player = player })

            local connections = {
                LocalPlayer:GetPropertyChangedSignal("Team"):Connect(update),
                player:GetPropertyChangedSignal("Team"):Connect(update),
            }
            update()

            return function()
                for _, connection in connections do
                    connection:Disconnect()
                end
            end
        end,
        Effects.character,
        function(_, _, _, context)
            playersToUpdate[context.player] = true

            return function()
                playersToUpdate[context.player] = true
            end
        end
    }))

    local function onChanged(new, old)
        if
            old == nil
            or new.game.anonymousFighters ~= old.game.anonymousFighters
            or selectors.getLocalSetting(new, "enemyDefaultAppearance") ~= selectors.getLocalSetting(old, "enemyDefaultAppearance")
        then
            for _, player in Players:GetPlayers() do
                playersToUpdate[player] = true
            end
        end
    end

    root.Store.changed:connect(onChanged)
    onChanged(root.Store:getState(), nil)

    RunService.Heartbeat:Connect(function()
        local anonymousFighters = root.Store:getState().game.anonymousFighters
        local onFightingTeam = CollectionService:HasTag(LocalPlayer.Team, "FightingTeam") or LocalPlayer.Team == Teams.Gladiators
        local enemyDefaultAppearance = selectors.getLocalSetting(root.Store:getState(), "enemyDefaultAppearance")

        for player in playersToUpdate do
            local character = player.Character
            if character == nil or not character:FindFirstChild("Head") then
                continue
            end

            playersToUpdate[player] = nil

            if
                onFightingTeam and isEnemyFn(player)
                and (enemyDefaultAppearance or anonymousFighters)
            then
                updatePlayer(player, noobAppearance)

                if anonymousFighters then
                    local humanoid = character:FindFirstChild("Humanoid")
                    if humanoid then
                        humanoid.DisplayName = " "
                    end
                end
            else
                updatePlayer(player, PlayerAppearances:FindFirstChild(tostring(player.UserId)))

                local humanoid = character:FindFirstChild("Humanoid")
                if humanoid then
                    humanoid.DisplayName = player.DisplayName
                end
            end
        end
    end)
end

return handleCharacterAppearance