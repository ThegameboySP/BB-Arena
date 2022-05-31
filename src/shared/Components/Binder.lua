local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Component = require(ReplicatedStorage.Common.Component).Component
return Component:extend("Binder", {
    noReplicate = true;
    dontClone = true;

    OnInit = function(self)
        if self.Instance:IsA("ModuleScript") then
            local process = require(self.Instance)
            for k, v in pairs(process) do
                self[k] = v
            end

            if process.OnInit then
                process.OnInit(self)
            end
        end
    end;
})