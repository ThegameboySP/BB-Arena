local WeaponThemes = require(script.Parent.WeaponThemes)

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
        description = "The volume of the toolset. With this, you don't have to sacrifice your hearing to play!";
    },
    trowelVisualization = {
        order = 2;
        group = "tool";

        default = true;
        type = "boolean";
        name = "Trowel visualization";
        description = "Whether the position and orientation of your trowel is shown before firing. Press Q while equipping trowel to toggle";
    },
    weaponTheme = {
        order = 3;
        group = "tool";

        default = "Normal";
        type = "enum";
        payload = WeaponThemes;
        name = "Tools theme";
        description = "The theme of your tools. Other players will be able to see this";

        replicateToAll = true;
    },
    weaponThemeHighGraphics = {
        order = 4;
        group = "tool";

        default = true;
        type = "boolean";
        name = "Fancy tools themes";
        description = "Whether themes have extra decorations. This can be distracting. Only applies to your screen";
    },
    neonWeapons = {
        order = 5;
        group = "tool";

        type = "boolean";
        default = true;
        name = "Neon tools";
        description = "Whether all tools and projectiles should be neon. Only applies to your screen";
    },
})