local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)

return function(_, key, value)
    Knit.globals[key]:Set(value)
end