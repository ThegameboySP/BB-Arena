local ReplicatedStorage = game:GetService("ReplicatedStorage")
local makeEnum = require(ReplicatedStorage.Common.Utils.makeEnum)

return makeEnum("Ranks", {
    F = 0;
    E = 1;
    D = 2;
    C = 3;
    B = 4;
    A = 5;
    S = 6;
    SPlus = 7;
})