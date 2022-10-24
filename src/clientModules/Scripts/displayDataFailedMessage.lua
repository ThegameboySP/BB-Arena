local Players = game:GetService("Players")

local USER_ID = Players.LocalPlayer.UserId
local MESSAGE = [[
Unfortunately, Roblox datastores are giving us some trouble today.
Your data can't be loaded, so we're giving you a temporary blank save file.
Your data will attempt to save when you leave.
]]

local function displayDataFetchFailedMessage(root)
    local store = root.Store

    local function onChanged(new, old)
        if new.users.usersFailedDatastore[USER_ID] and (not old or not old.users.usersFailedDatastore[USER_ID]) then
            root.notification(MESSAGE, {
                stayOpen = true;
            })
        end
    end

    store.changed:connect(onChanged)
    onChanged(store:getState())
end

return displayDataFetchFailedMessage