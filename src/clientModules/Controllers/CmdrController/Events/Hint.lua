local ReplicatedStorage = game:GetService("ReplicatedStorage")
local hintGUI = require(ReplicatedStorage.ClientModules.UI.hintGUI)

return function(text, player, color)
    hintGUI(text, {
        sender = player;
        color = color;
    })
end