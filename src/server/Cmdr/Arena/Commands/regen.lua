local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Components = require(ReplicatedStorage.Common.Components)

return {
    Name = "regen";
    Aliases = {};
    Description = "Regens the map, in whole or in part.";
    Group = "Admin";
    Args = {
        function(context)
            local MapSingleton = context:GetStore("Common").Root:GetSingleton("Map")
            local manager = MapSingleton.ClonerManager.Manager

            local instances = {}
            for _, component in manager:GetComponents(Components.RegenGroup) do
                table.insert(instances, component.Instance)
            end

            return {
                Type = context.Cmdr.Util.MakeListableType(context.Cmdr.Util.MakeEnumType("regen group", instances));
                Name = "groups";
                Description = "Parts of the map to regen";
                Optional = true;
            }
        end;
    }
}