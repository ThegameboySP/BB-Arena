local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Root = require(ReplicatedStorage.Common.Root)
local CmdrUtils = require(ReplicatedStorage.Common.Utils.CmdrUtils)

return {
    Name = "setVariable";
    Aliases = {"gvar"};
    Description = "Sets a replicated global variable";
    Group = "Admin";
    AutoExec = {
        'alias "sTrowels|Sets whether spectator trowels are allowed or not" gvar spectatorsCanBuildTrowels $1{boolean|toggle}';
    };
    Args = CmdrUtils.keyValueArgs("variable", 1, function()
        return Root.globals
    end, function(remoteProperty, name)
        return {
            Type = type(remoteProperty:Get());
            Name = name;
        }, remoteProperty:Get()
    end);
}