local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)

local function adminTierChanged(userId, tier)
    return {
        type = "permissions_setAdminTier";
        payload = {
            userId = userId;
            adminTier = tier;
        };
    }
end

local function saveAdminTierChanged(userId, tier)
    return function(store)
        Knit.GetService("CmdrService"):SaveAdminTier(userId, tier)
        store:dispatch(adminTierChanged(userId, tier))
    end
end

return {
    saveAdminTierChanged = saveAdminTierChanged;
    adminTierChanged = adminTierChanged;
}