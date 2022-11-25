local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Matter = require(ReplicatedStorage.Packages.Matter)

return Matter.component("Team", {
    name = nil;
    color = nil;
    participating = false;
    enableTools = false;
})
