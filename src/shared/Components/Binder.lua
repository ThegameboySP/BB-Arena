local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Bin = require(ReplicatedStorage.Common.Utils.Bin)

local Component = require(ReplicatedStorage.Common.Component).Component
return Component:extend("Binder", {
    noReplicate = true;
    dontClone = true;
    
    OnDestroy = function(self)
        if self.process.OnDestroy then
            self.process.OnDestroy(self)
        end

        self.bin:DoCleaning()
    end;
    OnInit = function(self)
        if self.Instance:IsA("ModuleScript") then
            self.process = require(self.Instance)
            if type(self.process) ~= "table" then
                task.spawn(error, self.Instance:GetFullName() .. " did not return a table")
                return
            end

            for k, v in pairs(self.process) do
                if k ~= "OnDestroy" then
                    self[k] = v
                end
            end

            self.bin = Bin.new()

            if self.process.OnInit then
                self.process.OnInit(self)
            end
        end
    end;
})