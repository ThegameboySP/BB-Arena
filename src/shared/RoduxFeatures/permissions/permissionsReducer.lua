local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Rodux = require(ReplicatedStorage.Packages.Rodux)
local Llama = require(ReplicatedStorage.Packages.Llama)

local Dictionary = Llama.Dictionary

return Rodux.createReducer({
    adminTiers = {};
}, {
    permissions_setAdminTier = function(state, action)
        return Dictionary.mergeDeep(state, {
            adminTiers = {[action.payload.userId] = action.payload.adminTier};
        })
    end;
})