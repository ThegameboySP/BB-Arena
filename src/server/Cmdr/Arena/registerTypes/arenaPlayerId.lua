local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local getFullPlayerName = require(ReplicatedStorage.Common.Utils.getFullPlayerName)

local function getName(text)
    if text:find("[^%d]") then
        return text:match("@?([^@]+)$")
    end
end

local function getUserId(text)
    return tonumber(text:match("^(%d+)"))
end

return function(registry)
    local cmdr = registry.Cmdr
    local cachedInfos = {}
    local root = registry:GetStore("Common").Root

    local function onPlayerAdded(player)
        cachedInfos[player.UserId] = player.UserId .. "@" .. getFullPlayerName(player)
    end

    Players.PlayerAdded:Connect(onPlayerAdded)
    for _, player in Players:GetPlayers() do
        onPlayerAdded(player)
    end

    local function getFullNames()
        local fullNames = {}

        for _, fullName in cachedInfos do
            table.insert(fullNames, fullName)
        end

        return fullNames
    end

    local playerIdType = {
        DisplayName = "User Id";
    
        Transform = function(text)
            local findPlayer = cmdr.Util.MakeFuzzyFinder(getFullNames())
    
            return text, findPlayer(text)
        end;
    
        ValidateOnce = function(text)
            local name = getName(text)

            local ok, userId
            if name then
                ok, userId = root:GetUserIdByName(name):await()
                if not ok or not userId then
                    return false, "Not a valid user name."
                end
            else
                userId = getUserId(text)

                if not userId then
                    return false, "Not a valid user name / userId."
                end
            end

            root:GetUserInfoByUserId(userId):andThen(function(info)
                cachedInfos[info.Id] = info.Id .. "@" .. getFullPlayerName(info)
            end)

            return true
        end;

        Autocomplete = function(_, fullNames)
            return fullNames
        end;
    
        Parse = function(text)
            local name = getName(text)
            if name then
                return root:GetUserIdByName(name):expect()
            end

            return getUserId(text)
        end;
    }

	registry:RegisterType("arenaPlayerId", playerIdType)
	registry:RegisterType("arenaPlayerIds", cmdr.Util.MakeListableType(playerIdType))
end
