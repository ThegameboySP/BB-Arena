local ReplicatedStorage = game:GetService("ReplicatedStorage")
local notificationGUI = require(ReplicatedStorage.ClientModules.UI.notificationGUI)

return function(text, player, color)
    notificationGUI(text, {
        sender = player;
        color = color;
    })
end