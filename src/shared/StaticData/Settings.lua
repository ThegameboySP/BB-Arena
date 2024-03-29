local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Sounds = ReplicatedStorage.Assets.Sounds

local Llama = require(ReplicatedStorage.Packages.Llama)
local ForcefieldThemes = require(ReplicatedStorage.Common.GameEnum.ForcefieldThemes)
local WeaponThemes = require(script.Parent.WeaponThemes)

local array = {
	{
		key = "weaponOrder",
		group = "input",

		default = {
			"Sword",
			"Slingshot",
			"Rocket",
			"Trowel",
			"Bomb",
			"Superball",
			"PaintballGun",
		},
		equals = Llama.List.equals,
		type = "toolOrder",
		name = "Tool order",
		description = "The hotkey order of your tools",
	},
	{
		key = "showToolHints",
		group = "input",

		default = true,
		type = "boolean",
		name = "Show tool hints",
		description = "Whether to show hints for equipped tools.",
	},
	{
		key = "bombJumpDefault",
		group = "input",

		default = false,
		type = "boolean",
		name = "Bomb jump combo",
		description = "Whether the stopping, spawning a bomb, and jumping combo results in a bomb jump. This setting is always enabled for mobile.",
		invalidates = { "bombJumpKeybind" },
		mobile = {
			valid = false,
			value = true,
		},
	},
	{
		key = "bombJumpKeybind",
		group = "input",

		default = "E",
		type = "keybind",
		name = "Bomb jump keybind",
		description = "Disabled for mobile.",
		mobile = {
			valid = false,
		},
	},
	{
		key = "trowelVisualizationKeybind",
		group = "input",

		default = "Q",
		type = "keybind",
		name = "Trowel visualization keybind",
		description = "Disabled for mobile.",
		mobile = {
			valid = false,
		},
	},
	{
		key = "weaponCrosshairId",
		group = "input",

		default = "507449825",
		type = "contentImage",
		name = "Weapon crosshair ID",
		description = "The ID of your weapons' crosshair",
		mobile = {
			valid = false,
		},
	},
	{
		key = "weaponCrosshairReloadingId",
		group = "input",

		default = "507449806",
		type = "contentImage",
		name = "Weapon reloading crosshair ID",
		description = "The ID of your weapons' reloading crosshair",
		mobile = {
			valid = false,
		},
	},
	{
		key = "enemyDefaultAppearance",
		group = "place",

		default = false,
		type = "boolean",
		name = "Enemies have default appearance",
		description = "Whether enemies are set as a noob. This is useful in case someone dresses up in a way to camouflage in the map",
	},
	{
		key = "lighting",
		group = "place",

		default = 0.5,
		type = "percentage",
		name = "Brightness",
		description = "The brightness of the game world",
	},
	{
		key = "fieldOfView",
		group = "place",

		default = 70,
		type = "range",
		payload = {
			min = 20,
			max = 120,
			sign = "°",
		},
		name = "Field of view",
		description = "The field of view of your camera",
	},
	{
		key = "forcefieldTheme",
		group = "place",

		default = "Default",
		type = "enum",
		payload = ForcefieldThemes,
		name = "Forcefield theme",
		description = "The theme of forcefields. Only applies to your screen",
	},
	{
		key = "weaponTheme",
		group = "tool",

		default = "Normal",
		type = "enum",
		payload = WeaponThemes,
		name = "Tools theme",
		description = "The theme of your tools. Other players will be able to see this",

		replicateToAll = true,
	},
	{
		key = "weaponThemeHighGraphics",
		group = "tool",

		default = true,
		type = "boolean",
		name = "Fancy tools themes",
		description = "Whether themes have extra decorations. This can be distracting. Only applies to your screen",
	},
	{
		key = "neonWeapons",
		group = "tool",

		type = "boolean",
		default = true,
		name = "Neon tools",
		description = "Whether all tools and projectiles should be neon. Only applies to your screen",
	},
	{
		key = "trowelBuildDisplay",
		group = "tool",

		default = true,
		type = "boolean",
		name = "Trowel build display",
		description = "Whether a line is drawn between a trowel and the player who fired it",
	},
	{
		key = "trowelVisualization",
		group = "tool",

		default = true,
		type = "boolean",
		name = "Trowel visualization",
		description = "Whether the position and orientation of your trowel is shown before firing",
	},
	{
		key = "practiceWeaponDisplay",
		group = "tool",

		default = false,
		type = "boolean",
		name = "Practice superball visualization",
		description = "Whether the superball's trajectory is shown before firing while under the Practice team",
	},
	{
		key = "weaponVolume",
		group = "sounds",

		default = 0.5,
		type = "percentage",
		name = "Tools volume",
		description = "The volume of the toolset. With this, you don't have to sacrifice your hearing to play!",
	},
	{
		key = "musicVolume",
		group = "sounds",

		default = 0.5,
		type = "percentage",
		name = "Music volume",
		description = "The volume of the in-game music",
	},
	{
		key = "mapVolume",
		group = "sounds",

		default = 0.5,
		type = "percentage",
		name = "Map volume",
		description = [[The volume of the ambient sounds in maps. Includes "music" found in maps as well]],
	},
	{
		key = "gamemodeVolume",
		group = "sounds",

		default = 0.5,
		type = "percentage",
		name = "Gamemode volume",
		description = "The volume of gamemode sound effects",
	},
	{
		key = "dieSound",
		group = "sounds",

		default = nil,
		type = "contentSound",
		payload = {
			defaultSound = Sounds.DefaultDied,
		},
		name = "Die sound",
		description = "The ID of the sound that plays when someone dies. This replaces the default OOF sound",
	},
}

local dictionary = {}
for index, setting in array do
	dictionary[setting.key] = setting
	setting.order = index
end

return table.freeze(dictionary)
