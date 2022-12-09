local ReplicatedStorage = game:GetService("ReplicatedStorage")
local makeEnum = require(ReplicatedStorage.Common.Utils.makeEnum)

local enum = {}
for _, child in pairs(script:GetChildren()) do
	enum[child.Name] = require(child)
end

return makeEnum("GameEnum", enum)
