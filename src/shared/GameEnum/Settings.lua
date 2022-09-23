return table.freeze({
    lighting = {
        order = 1;
        group = "place";

        default = 0.5;
        type = "percentage";
        name = "Brightness";
        description = "The brightness of the game world";
    },
    musicVolume = {
        order = 2;
        group = "place";

        default = 0.5;
        type = "percentage";
        name = "Music volume";
        description = "The volume of the in-game music";
    },
    mapVolume = {
        order = 3;
        group = "place";

        default = 0.5;
        type = "percentage";
        name = "Map volume";
        description = [[The volume of the ambient sounds in maps. Includes "music" found in maps as well]];
    },
    gamemodeVolume = {
        order = 4;
        group = "place";

        default = 0.5;
        type = "percentage";
        name = "Gamemode volume";
        description = "The volume of gamemode sound effects";
    },
    fieldOfView = {
        order = 5;
        group = "place";

        default = 70;
        type = "range";
        payload = {
            min = 20,
            max = 120,
            sign = "°"
        };
        name = "Field of view";
        description = "The field of view of your camera";
    },
    weaponVolume = {
        order = 1;
        group = "tool";

        default = 0.5;
        type = "percentage";
        name = "Tools volume";
        description = "The volume of the toolset. With this, you don't have to choose between your hearing and playing Brickbattle!";
    },
    neonWeapons = {
        order = 2;
        group = "tool";

        type = "boolean";
        default = true;
        name = "Neon tools";
        description = "Whether neon weapons should be displayed or not";
    },
})