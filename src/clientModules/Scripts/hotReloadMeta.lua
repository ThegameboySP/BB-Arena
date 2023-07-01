local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Rewire = require(ReplicatedStorage.Packages.Rewire)
local Llama = require(ReplicatedStorage.Packages.Llama)

local Definitions = require(ReplicatedStorage.Common.Definitions)
local RoduxFeatures = require(ReplicatedStorage.Common.RoduxFeatures)

local function hotReloadMeta(root)
	if not RunService:IsStudio() then
		return
	end

	local metaFolder = ReplicatedStorage:FindFirstChild("MapMetaFolder")
	local reloader = Rewire.HotReloader.new()

	for _, child in metaFolder:GetChildren() do
		local mapName = child.Name

		reloader:listen(child, function(module)
			module.Name = "__IgnoreThis"

			local ok, required = pcall(function()
				return require(module)
			end)

			if ok and Definitions.mapMeta(required) then
				root.Store:dispatch(RoduxFeatures.actions.setSpecificMapInfo(mapName, {
					creator = required.Creator or Llama.None,
					thumbnail = required.Thumbnail or Llama.None,
				}))
			end
		end, function(module)
			module.Name = mapName
		end)
	end
end

return hotReloadMeta
