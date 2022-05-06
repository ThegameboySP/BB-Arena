local Llama = require(game:GetService("ReplicatedStorage").Packages.Llama)
local mergeDeep = Llama.Dictionary.mergeDeep
local None = Llama.None

local Users = {}
Users.__index = Users

function Users.new(data)
    return table.freeze(setmetatable(data or {
        admins = {};
        whitelisted = {};
        banned = {};
    }, Users))
end

function Users:setAdmin(userId, adminLevel, byUser)
    if adminLevel >= self:getAdmin(byUser) then
        return self
    end

    return Users.new(mergeDeep(self, {
        admins = {
            [userId] = adminLevel;
        }
    }))
end

function Users:getAdmin(userId)
    return self.admins[userId] or 0
end

function Users:banUser(userId, byUser)
    if not self:canUserBeKickedBy(userId, byUser) then
        return self
    end

    return Users.new(mergeDeep(self, {
        whitelisted = {
            [userId] = None;
        };
        banned = {
            [userId] = byUser;
        }
    }))
end

function Users:unbanUser(userId, byUser)
    if not self:canUserBeKickedBy(userId, byUser) then
        return self
    end

    return Users.new(mergeDeep(self, {
        banned = {
            [userId] = None;
        }
    }))
end

function Users:whitelistUser(userId, byUser)
    if not self:canUserBeKickedBy(userId, byUser) then
        return self
    end

    return Users.new(mergeDeep(self, {
        whitelisted = {
            [userId] = byUser;
        }
    }))
end

function Users:unwhitelistUser(userId, byUser)
    local whitelistedBy = self.whitelisted[userId]
    if not whitelistedBy or not self:canUserBeKickedBy(whitelistedBy, byUser) then
        return self
    end

    return Users.new(mergeDeep(self, {
        whitelisted = {
            [userId] = None;
        }
    }))
end

function Users:isUserBanned(userId)
    local bannerId = self.banned[userId]
    if bannerId == nil then
        return false
    end

    local bannerAdmin = self.admins[bannerId]
    if bannerAdmin == nil then
        return false
    end

    local whitelistedBy = self.whitelisted[userId]
    if (whitelistedBy and self:getAdmin(whitelistedBy)) >= bannerAdmin then
        return false
    end

    return bannerAdmin > self:getAdmin(userId)
end

function Users:getUserBannedBy(userId)
    return self.banned[userId]
end

function Users:canUserBeKickedBy(userId, kickingUserId)
    local kickerAdmin = self.admins[kickingUserId]
    if kickerAdmin == nil then
        return false
    end

    return kickerAdmin > self:getAdmin(userId)
end

return Users