local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)

local GamemodeService = Knit.CreateService({
    Name = "GamemodeService";
    Client = {};
})

function GamemodeService:SetGamemode()
    
end

return GamemodeService