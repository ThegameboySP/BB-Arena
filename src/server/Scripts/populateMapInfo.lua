local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RoduxFeatures = require(ReplicatedStorage.Common.RoduxFeatures)

local function countTeams(t)
    local n = 0

    for _ in t do
        n += 1
    end

    return n
end

local function populateMapInfo(root)
    local MapService = root:GetService("MapService")
    local GamemodeService = root:GetService("GamemodeService")

    local mapInfo = {}

    for _, map in MapService:GetMaps() do
        local meta = require(map:FindFirstChild("Meta"))
        local size
        if map:IsA("Model") then
            _, size = map:GetBoundingBox()
        end

        local info = {
            neutralAllowed = true; -- TODO: probably temporary
            size = size;
            creator = meta.Creator;
            teamSize = countTeams(meta.Teams);
        }

        mapInfo[map.Name] = info

        for _, gamemode in GamemodeService:GetGamemodes() do
            if not gamemode.hasMapProps then
                continue
            end

            local key = "supports" .. gamemode.nameId
            
            if
                gamemode.minTeams > countTeams(meta.Teams)
                or not map:FindFirstChild(gamemode.nameId)
            then
                info[key] = false
                continue
            end

            info[key] = true
        end
    end

    root.Store:dispatch(RoduxFeatures.actions.merge({
        map = {
            mapInfo = mapInfo;
        };
    }))
end

return populateMapInfo