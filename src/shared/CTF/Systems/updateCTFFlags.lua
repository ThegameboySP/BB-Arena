local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

local Components = require(script.Parent.Components)

local function getCharacter(instance)
    local character = instance.Parent
    if not character:FindFirstChild("Humanoid") then
        return nil
    end

    if CollectionService:HasTag(character, "FightingCharacter") then
        return nil
    end

    return character
end

local function updateCTFFlags(world, context)
    for id, flag, part in world:query(Components.Flag, Components.Part) do
        if flag.state == "Dropped" or flag.state == "OnStand" then
            for _, hit in Matter.useEvent(part.part, "Touched") do
                local character = getCharacter(hit)
                if character == nil then
                    continue
                end

                local player = Players:GetPlayerFromCharacter(character)
                if player.Team == nil or player.Team.Name == flag.teamName then
                    continue
                end

                world:insert(id, flag:patch({
                    character = character;
                }))
            end
        end
    end

    -- Parent the flag.
    for _id, flag, part in world:query(Components.Flag, Components.Part) do
        if flag.character and flag.character ~= part.part.Parent then
            part.part.Parent = flag.character
        elseif not flag.character then
            part.part.Parent = workspace
        end
    end

    for id, flagStand, part in world:query(Components.FlagStand, Components.part) do
        for _, hit in Matter.useEvent(part.part, "Touched") do
            local character = getCharacter(hit)
            if character == nil then
                continue
            end

            local characterFlag = getFlag(character)
            if not characterFlag then
                continue
            end

            local flagId, flag = getComponentFromInstance(characterFlag)
            world:insert(flagId, flag:patch({
                state = "OnStand";
            }))

            context.events:fire("flagCapture", table.freeze({
                player = Players:GetPlayerFromCharacter(character);
                flagStandId = id;
                flagId = flagId;
            }))
        end
    end
end

return updateCTFFlags