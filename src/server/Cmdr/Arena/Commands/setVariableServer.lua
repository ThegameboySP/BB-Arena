local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Root = require(ReplicatedStorage.Common.Root)

return function(_, key, value)
	Root.globals[key]:Set(value)
end
