local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

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

	local metaFolder = Instance.new("Folder")
	metaFolder.Name = "MapMetaFolder"
	metaFolder.Parent = ReplicatedStorage

	local isStudio = RunService:IsStudio()
	local mapInfo = {}

	for _, map in MapService:GetMaps() do
		if isStudio then
			local metaModule = map:FindFirstChild("Meta")
			local metaClone = metaModule:Clone()
			metaClone.Name = map.Name
			metaClone.Parent = metaFolder
		end

		local meta = require(map:FindFirstChild("Meta"))
		local size
		if map:IsA("Model") then
			size = map:GetExtentsSize()
		end

		local info = {
			neutralAllowed = true, -- TODO: probably temporary
			size = size,
			creator = meta.Creator,
			teamSize = countTeams(meta.Teams),
			thumbnail = meta.Thumbnail,
		}

		mapInfo[map.Name] = info

		for _, gamemode in GamemodeService:GetGamemodes() do
			if not gamemode.hasMapProps then
				continue
			end

			local key = "supports" .. gamemode.nameId

			if gamemode.minTeams > countTeams(meta.Teams) or not map:FindFirstChild(gamemode.nameId) then
				info[key] = false
				continue
			end

			info[key] = true
		end
	end

	root.Store:dispatch(RoduxFeatures.actions.setMapInfo(mapInfo))
end

return populateMapInfo
