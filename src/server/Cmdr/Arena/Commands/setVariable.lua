local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Root = require(ReplicatedStorage.Common.Root)

return {
    Name = "setVariable";
    Aliases = {"gvar"};
    Description = "Sets a replicated global variable";
    Group = "Admin";
    AutoExec = {
        'alias "sTrowels|Sets whether spectator trowels are allowed or not" gvar spectatorsCanBuildTrowels $1{boolean|toggle}';
    };
    Args = {
        function(context)
            local values = {}
            for name in pairs(Root.globals) do
                table.insert(values, name)
            end

            return {
                Type = context.Cmdr.Util.MakeEnumType("variables", values);
                Name = "variable";
            }
        end;
        function(context)
            local arg1 = context:GetArgument(1)
			if arg1:Validate() == false then
				return
			end

            local property = Root.globals[arg1:GetValue()]

            return {
                Type = type(property:Get());
                Name = "value";
                Description = "Current value: " .. tostring(property:Get());
            }
        end;
    };
}