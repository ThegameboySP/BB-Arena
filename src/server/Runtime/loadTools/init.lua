local ServerScriptService = game:GetService("ServerScriptService")

local Toolset = ServerScriptService.Packages.Toolset

local ThemePack = script.ThemePack
local CustomThemePack = script.CustomThemePack

local settings = {
	-- GENERAL WEAPON SETTINGS --
	SuperballFly = false,
	SlingClimb = true,
	RocketRiding = false,
	RocketsExplodeSBs = true, -- WIP
	TagLifetime = 10,
	NativeCrosshair = false,
	
	-- TEAM SETTINGS --
	SpectatorTeamActive = true,   -- Spectators can't take or deal dmg.
	IgnoreCertainTeams = true,
	TeamsFiltered = {"Gladiators", "Practice"}, -- "neutral" teams
	ThemeOverrides = true, -- themes will override team colors if above is true

	Themes = {
		ThemePacks = {ThemePack, CustomThemePack};
		TrailsOmitted = {"Normal", "Team Color"}; -- Add theme names for them to not have trails
		TrailFilterType = true;
	},

	-- DOOMSPIRE SETTINGS --
	Doomspire = {
		SlingFly = false;
		RocketCollisions = false;
	},

	-- EXPLOSION SETTINGS --
	Explosions = {
		DestroyTrowelWallsOverride = true; --If true, overrides Explosions.DestroyParts
		DebrisTime = 0; -- must be >0 for parts to be added to debris collection
		FlingYou = false; -- Will fling your body parts!
		LimbRemoval = false;
        FlingBombs = false;
        FlingParts = true;
	},
	
	-- SPECIFIC WEAPON SETTINGS -- 
	Bomb = {
		DespawnTime = 4; -- despawns after x seconds
		SelfDamage = true;
		BombJumpReloadTime = 15;
	},
	Rocket = {
		ShootInsideBricks = false;
		SelfDamage = true;
		DespawnTime = 12; -- despawns after x seconds
	},
	Slingshot = {
		ShootInsideBricks = false;
	},
	Superball = {
		ShootInsideBricks = false;	
	},
	Sword = {
		FloatAmount = 5000;
		JumpHeight = 15;
		LungeExtensionTime = .85;
	},
	PaintballGun = {
		Damage = 15;
		Speed = 200;
		MultiplierPartNames = {
			Head = false,
			Torso = false,
			UpperTorso = false,
			LowerTorso = false,
			HumanoidRootPart = false
		};
		ShootInsideBricks = false;
	},
	
	
	-- SECURIY SETTINGS --
	Security = {
		-- Numbers are thresholds that, if surpassed, will deactivate projectile 
		--(cause no dmg and stop replication)
		Master = false, -- If set to false, will have no security logs or repercussions
		PSPV = false; -- Hitbox verification
		Ricochet = false; -- secure ricochet damage
	},


	-- LOCAL MISC SETTINGS --
	LocalSettingsDefaults = { -- mostly aesthetic
		Hit = "Ping"; -- None for no sound
		Themes = true;
		ThemesHighGraphics = true;
	},
}

local function loadTools()
    task.spawn(function()
        require(Toolset)(settings)
    end)
end

return loadTools