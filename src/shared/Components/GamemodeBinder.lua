local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Component = require(ReplicatedStorage.Common.Component).Component
return Component:extend("GamemodeBinder", {
    noReplicate = true;
    dontClone = true;
})