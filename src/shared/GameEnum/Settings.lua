return table.freeze({
    neonWeapons = {
        default = true;
        cmdr = {
            Type = "boolean";
            Name = "Neon weapons";
            Description = "Whether neon weapons should be displayed or not";
        }
    };
    musicVolume = {
        default = 0.25;
        cmdr = {
            Type = "percentage";
            Name = "Music volume";
            Description = "The volume of the in-game music";
        };
    };
    mapVolume = {
        default = 0.25;
        cmdr = {
            Type = "percentage";
            Name = "Map volume";
            Description = [[The volume of the ambient sounds in maps. Includes "music" found in maps as well]];
        }
    };
})