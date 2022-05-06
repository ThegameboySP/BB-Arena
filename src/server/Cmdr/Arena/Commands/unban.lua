local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CmdrUtils = require(ReplicatedStorage.Common.Utils.CmdrUtils)

return function (Cmdr)
    local wrappedUserIds = CmdrUtils.wrapAutoSuggestions(Cmdr.Registry.Types.playerIds, function()
        local suggestions = {}
        for userId in pairs(Cmdr:GetStore("Common").Store:getState().users.banned) do
            table.insert(suggestions, userId)
        end

        return suggestions 
    end)

    return {
        Name = "unban";
        Aliases = {};
        Description = "Unbans UserIds.";
        Group = "Owner";
        Args = {
            {
                Type = wrappedUserIds;
                Name = "Players";
                Description = "Players to damage";
            }
        };
    }
end