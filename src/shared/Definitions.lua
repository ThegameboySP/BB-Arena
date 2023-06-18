local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local t = require(ReplicatedStorage.Packages.t)

local Definitions = {}

local instanceIsModuleScript = t.instanceIsA("ModuleScript")
local moduleScriptChecker = function(checker)
	return function(instance)
		local ok, err = instanceIsModuleScript(instance)
		if not ok then
			return err
		end

		return checker(require(instance))
	end
end

local function mapChecker(checker)
	return function(map)
		if not CollectionService:HasTag(map, "Map") then
			return false, "Map does not have Map CollectionService tag"
		end

		return checker(map)
	end
end

Definitions.mapMeta = t.interface({
	Teams = t.map(t.string, t.BrickColor),

	IslandTopColor = t.optional(t.Color3),
	IslandBaseColor = t.optional(t.Color3),

	Creator = t.optional(t.string),
	Thumbnail = t.optional(t.union(
		t.string,
		t.strictInterface({
			image = t.string,
			snow = t.optional(t.boolean),
		})
	)),
})

Definitions.map = mapChecker(t.instanceOf("Model", {
	Meta = moduleScriptChecker(Definitions.mapMeta),
}))

return Definitions
