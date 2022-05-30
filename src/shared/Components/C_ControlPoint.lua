local ReplicatedStorage = game:GetService("ReplicatedStorage")

local C_CapturableFlag = require(ReplicatedStorage.Common.Components.C_CapturableFlag)

local WHITE = Color3.new(1, 1, 1)
local C_ControlPoint = C_CapturableFlag:extend("ControlPoint", {
    getFlagColor = function(captured, capturing, percentCaptured)
        return 
            (captured and captured.TeamColor.Color or WHITE)
            :lerp((capturing and capturing.TeamColor.Color or WHITE), percentCaptured)
    end
})

return C_ControlPoint