local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Matter = require(ReplicatedStorage.Packages.Matter)

return Matter.component("Player", {
    userId = 0;
    teamId = nil;
    player = nil;
    respawnQueued = false;
})
