local ReplicatedStorage = game:GetService("ReplicatedStorage")
local makeEnum = require(ReplicatedStorage.Common.Utils.makeEnum)

return makeEnum("ForcefieldThemes", {
    Default = "Default";
    Retro = "Retro";
    Simple = "Simple";
})