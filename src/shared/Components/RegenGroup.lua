local ReplicatedStorage = game:GetService("ReplicatedStorage")

local t = require(ReplicatedStorage.Packages.t)
local Component = require(ReplicatedStorage.Common.Component).Component

return Component:extend("RegenGroup", {
    checkConfig = t.interface({
        Time = t.number;
    })
})