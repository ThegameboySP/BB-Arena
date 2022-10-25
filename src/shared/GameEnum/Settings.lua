local WeaponThemes = require(script.Parent.WeaponThemes)
local ForcefieldThemes = require(script.Parent.ForcefieldThemes)

local array = {
    {
        key = "bombJumpKeybind";
        group = "input";

        default = "E";
        type = "keybind";
        name = "Bomb jump keybind";
        description = "Disabled for mobile.";
        mobile = {
            valid = false;
        };
    },
    {
        key = "bombJumpDefault";
        group = "input";

        default = false;
        type = "boolean";
        name = "Bomb jump combo";
        description = "Whether the stopping, spawning a bomb, and jumping combo results in a bomb jump. This setting is always enabled for mobile.";
        invalidates = {"bombJumpKeybind"};
        mobile = {
            valid = false;
            value = true;
        };
    },
    {
        key = "lighting";
        group = "place";

        default = 0.5;
        type = "percentage";
        name = "Brightness";
        description = "The brightness of the game world";
    },
    {
        key = "musicVolume";
        group = "place";

        default = 0.5;
        type = "percentage";
        name = "Music volume";
        description = "The volume of the in-game music";
    },
    {
        key = "mapVolume";
        group = "place";

        default = 0.5;
        type = "percentage";
        name = "Map volume";
        description = [[The volume of the ambient sounds in maps. Includes "music" found in maps as well]];
    },
    {
        key = "gamemodeVolume";
        group = "place";

        default = 0.5;
        type = "percentage";
        name = "Gamemode volume";
        description = "The volume of gamemode sound effects";
    },
    {
        key = "fieldOfView";
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
    {
        key = "forcefieldTheme";
        group = "place";

        default = "Default";
        type = "enum";
        payload = ForcefieldThemes;
        name = "Forcefield theme";
        description = "The theme of forcefields. Only applies to your screen";
    },
    {
        key = "weaponVolume";
        group = "tool";

        default = 0.5;
        type = "percentage";
        name = "Tools volume";
        description = "The volume of the toolset. With this, you don't have to sacrifice your hearing to play!";
    },
    {
        key = "trowelVisualization";
        group = "tool";

        default = true;
        type = "boolean";
        name = "Trowel visualization";
        description = "Whether the position and orientation of your trowel is shown before firing. Press Q while equipping trowel to toggle";
    },
    {
        key = "trowelBuildDisplay";
        group = "tool";

        default = true;
        type = "boolean";
        name = "Trowel build display";
        description = "Whether a line is drawn between a trowel and the player who fired it";
    },
    {
        key = "practiceWeaponDisplay";
        group = "tool";

        default = false;
        type = "boolean";
        name = "Practice superball visualization";
        description = "Whether the superball's trajectory is shown before firing while under the Practice team";
    },
    {
        key = "weaponTheme";
        group = "tool";

        default = "Normal";
        type = "enum";
        payload = WeaponThemes;
        name = "Tools theme";
        description = "The theme of your tools. Other players will be able to see this";

        replicateToAll = true;
    },
    {
        key = "weaponThemeHighGraphics";
        group = "tool";

        default = true;
        type = "boolean";
        name = "Fancy tools themes";
        description = "Whether themes have extra decorations. This can be distracting. Only applies to your screen";
    },
    {
        key = "neonWeapons";
        group = "tool";

        type = "boolean";
        default = true;
        name = "Neon tools";
        description = "Whether all tools and projectiles should be neon. Only applies to your screen";
    },
}

local dictionary = {}
for index, setting in array do
    dictionary[setting.key] = setting
    setting.order = index
end

return table.freeze(dictionary)