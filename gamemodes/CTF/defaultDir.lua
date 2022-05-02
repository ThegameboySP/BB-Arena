local ReplicatedStorage = game:GetService("ReplicatedStorage")

return {
    Promise = require(ReplicatedStorage.Packages.Promise);
    Bin = require(ReplicatedStorage.Common.Utils.Bin);
}