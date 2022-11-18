local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Roact = require(ReplicatedStorage.Packages.Roact)
local RoactRodux = require(ReplicatedStorage.Packages.RoactRodux)
local Rodux = require(ReplicatedStorage.Packages.Rodux)

local RoduxFeatures = require(ReplicatedStorage.Common.RoduxFeatures)

local e = Roact.createElement

local MapListApp = require(script.Parent)

local thumbnails = {
	"rbxassetid://11564755954",
	"rbxassetid://11565140333",
	"rbxassetid://11565600116",
}
local mapInfo = {}
for i = 1, 100 do
    mapInfo["Of Fleeting Dreams" .. i] = {
        ["teamSize"] = 2;
        ["size"] = i .. "x" .. 100 - i;
        ["neutralAllowed"] = true;
        ["supportsCTF"] = i % 2 == 0;
        ["supportsControlPoints"] = i % 2 == 1;
        ["creator"] = "BenBonez (RCL)";
		["thumbnail"] = thumbnails[math.random(#thumbnails)];
    }
end

local test = {
    ["Applewood Valley"] = {
       ["creator"] = "fozetz & GloriedRage",
       ["neutralAllowed"] = true,
       ["size"] = Vector3.new(157, 49, 366),
       ["supportsCTF"] = true,
       ["supportsControlPoints"] = true,
       ["teamSize"] = 2
    },
    ["Architects Keep"] =    {
       ["creator"] = "567koala",
       ["neutralAllowed"] = true,
       ["size"] = Vector3.new(302, 131, 504),
       ["supportsCTF"] = true,
       ["supportsControlPoints"] = true,
       ["teamSize"] = 2
    },
    ["Arena"] =    {
       ["neutralAllowed"] = true,
       ["size"] = Vector3.new(1276, 485, 987),
       ["supportsCTF"] = false,
       ["supportsControlPoints"] = false,
       ["teamSize"] = 0
    },
    ["Ariamis"] =    {
       ["creator"] = "koke15",
       ["neutralAllowed"] = true,
       ["size"] = Vector3.new(403, 133, 406),
       ["supportsCTF"] = true,
       ["supportsControlPoints"] = true,
       ["teamSize"] = 2
    },
    ["Atrophy"] =    {
       ["creator"] = "Delfino",
       ["neutralAllowed"] = true,
       ["size"] = Vector3.new(280, 17, 232),
       ["supportsCTF"] = false,
       ["supportsControlPoints"] = false,
       ["teamSize"] = 2
    },
    ["Autumn Remains"] =    {
       ["creator"] = "rivetbomber",
       ["neutralAllowed"] = true,
       ["size"] = Vector3.new(500, 213, 300),
       ["supportsCTF"] = true,
       ["supportsControlPoints"] = true,
       ["teamSize"] = 2,
       ["thumbnail"] = "rbxassetid://11567442436"
    },
    ["BALLERROADS2"] =    {
       ["creator"] = "GloriedRage",
       ["neutralAllowed"] = true,
       ["size"] = Vector3.new(400, 83, 400),
       ["supportsCTF"] = false,
       ["supportsControlPoints"] = false,
       ["teamSize"] = 2
    },
    ["BRM"] =    {
       ["creator"] = "GloriedRage",
       ["neutralAllowed"] = true,
       ["size"] = Vector3.new(460, 237, 460),
       ["supportsCTF"] = false,
       ["supportsControlPoints"] = false,
       ["teamSize"] = 0
    },
    ["Badlands"] =    {
       ["creator"] = "Madsanity, Boy4u2",
       ["neutralAllowed"] = true,
       ["size"] = Vector3.new(449, 71, 448),
       ["supportsCTF"] = true,
       ["supportsControlPoints"] = true,
       ["teamSize"] = 2
    },
    ["Balanced"] =    {
       ["creator"] = "Drizlin",
       ["neutralAllowed"] = true,
       ["size"] = Vector3.new(198, 87, 195),
       ["supportsCTF"] = true,
       ["supportsControlPoints"] = true,
       ["teamSize"] = 2
    },
    ["Barren"] =    {
       ["creator"] = "homepunch",
       ["neutralAllowed"] = true,
       ["size"] = Vector3.new(500, 434, 300),
       ["supportsCTF"] = false,
       ["supportsControlPoints"] = false,
       ["teamSize"] = 2,
       ["thumbnail"] = "rbxassetid://11567442330"
    },
    ["Bastion"] =    {
       ["creator"] = "Ratwise/BenBonez (RCL)",
       ["neutralAllowed"] = true,
       ["size"] = Vector3.new(148, 367, 414),
       ["supportsCTF"] = true,
       ["supportsControlPoints"] = true,
       ["teamSize"] = 2
    },
    ["Battle Spiral"] =    {
       ["creator"] = "GloriedRage",
       ["neutralAllowed"] = true,
       ["size"] = Vector3.new(447, 58, 448),
       ["supportsCTF"] = true,
       ["supportsControlPoints"] = true,
       ["teamSize"] = 2
    },
    ["Battles of Frost"] =    {
       ["creator"] = "cooldude12345555 & GloriedRage",
       ["neutralAllowed"] = true,
       ["size"] = Vector3.new(549, 139, 599),
       ["supportsCTF"] = true,
       ["supportsControlPoints"] = true,
       ["teamSize"] = 2
    },
    ["Black"] =    {
       ["creator"] = "homepunch",
       ["neutralAllowed"] = true,
       ["size"] = Vector3.new(556, 653, 445),
       ["supportsCTF"] = true,
       ["supportsControlPoints"] = false,
       ["teamSize"] = 2
    },
    ["Blox City"] =    {
       ["creator"] = "Samonji",
       ["neutralAllowed"] = true,
       ["size"] = Vector3.new(463, 148, 463),
       ["supportsCTF"] = false,
       ["supportsControlPoints"] = false,
       ["teamSize"] = 2
    },
    ["Blox Vegas"] =    {
       ["creator"] = "Delfino",
       ["neutralAllowed"] = true,
       ["size"] = Vector3.new(621, 2386, 510),
       ["supportsCTF"] = false,
       ["supportsControlPoints"] = true,
       ["teamSize"] = 2
    },
    ["Blue"] =    {
       ["creator"] = "homepunch",
       ["neutralAllowed"] = true,
       ["size"] = Vector3.new(556, 652, 445),
       ["supportsCTF"] = true,
       ["supportsControlPoints"] = false,
       ["teamSize"] = 2
    },
    ["Brick Kings Lagoon"] =    {
       ["creator"] = "KingForest",
       ["neutralAllowed"] = true,
       ["size"] = Vector3.new(302, 74, 302),
       ["supportsCTF"] = true,
       ["supportsControlPoints"] = true,
       ["teamSize"] = 2,
       ["thumbnail"] = "rbxassetid://11565140333"
    },
    ["Brickbattle Meadows"] =    {
       ["creator"] = "fozetz",
       ["neutralAllowed"] = true,
       ["size"] = Vector3.new(465, 291, 315),
       ["supportsCTF"] = true,
       ["supportsControlPoints"] = true,
       ["teamSize"] = 2
    },
    ["Bricktops"] =    {
       ["creator"] = "owen0202 (RCL)",
       ["neutralAllowed"] = true,
       ["size"] = Vector3.new(248, 57, 348),
       ["supportsCTF"] = true,
       ["supportsControlPoints"] = true,
       ["teamSize"] = 2
    },
    ["Bunnyland"] =    {
       ["creator"] = "snarl",
       ["neutralAllowed"] = true,
       ["size"] = Vector3.new(210, 58, 196),
       ["supportsCTF"] = true,
       ["supportsControlPoints"] = true,
       ["teamSize"] = 2
    },
    ["Castle"] =    {
       ["creator"] = "odkal",
       ["neutralAllowed"] = true,
       ["size"] = Vector3.new(233, 63, 223),
       ["supportsCTF"] = true,
       ["supportsControlPoints"] = true,
       ["teamSize"] = 2
    },
    ["Center"] =    {
       ["creator"] = "GloriedRage",
       ["neutralAllowed"] = true,
       ["size"] = Vector3.new(210, 33, 196),
       ["supportsCTF"] = false,
       ["supportsControlPoints"] = false,
       ["teamSize"] = 2,
       ["thumbnail"] = "rbxassetid://11566648465"
    },
    ["Chaos Canyon"] =    {
       ["creator"] = "Shedletsky",
       ["neutralAllowed"] = true,
       ["size"] = Vector3.new(300, 86, 351),
       ["supportsCTF"] = false,
       ["supportsControlPoints"] = false,
       ["teamSize"] = 2
    },
    ["Coastline"] =    {
       ["creator"] = "RocketMan",
       ["neutralAllowed"] = true,
       ["size"] = Vector3.new(4830, 172, 5245),
       ["supportsCTF"] = false,
       ["supportsControlPoints"] = true,
       ["teamSize"] = 2,
       ["thumbnail"] = "rbxassetid://11567442231"
    },
    ["Coldfront"] =    {
       ["creator"] = "BenBonez (RCL)",
       ["neutralAllowed"] = true,
       ["size"] = Vector3.new(340, 105, 364),
       ["supportsCTF"] = true,
       ["supportsControlPoints"] = true,
       ["teamSize"] = 2
    },
    ["Cross"] =    {
       ["creator"] = "BenBonez (RCL)",
       ["neutralAllowed"] = true,
       ["size"] = Vector3.new(180, 49, 191),
       ["supportsCTF"] = true,
       ["supportsControlPoints"] = true,
       ["teamSize"] = 2
    },
    ["Crossing of Jade"] =    {
       ["creator"] = "SmoresIV",
       ["neutralAllowed"] = true,
       ["size"] = Vector3.new(245, 92, 246),
       ["supportsCTF"] = false,
       ["supportsControlPoints"] = true,
       ["teamSize"] = 2
    },
    ["Crosspaths"] =    {
       ["creator"] = "BrickLord34",
       ["neutralAllowed"] = true,
       ["size"] = Vector3.new(403, 190, 403),
       ["supportsCTF"] = true,
       ["supportsControlPoints"] = true,
       ["teamSize"] = 2
    },
    ["Crossroads"] =    {
       ["creator"] = "Shedletsky",
       ["neutralAllowed"] = true,
       ["size"] = Vector3.new(400, 83, 400),
       ["supportsCTF"] = false,
       ["supportsControlPoints"] = false,
       ["teamSize"] = 2
    },
    ["CrossroadsFortress"] =    {
       ["creator"] = "vbaumel",
       ["neutralAllowed"] = true,
       ["size"] = Vector3.new(400, 112, 1211),
       ["supportsCTF"] = true,
       ["supportsControlPoints"] = true,
       ["teamSize"] = 2
    },
    ["Crown"] =    {
       ["creator"] = "BenBonez (RCL)",
       ["neutralAllowed"] = true,
       ["size"] = Vector3.new(297, 113, 191),
       ["supportsCTF"] = true,
       ["supportsControlPoints"] = true,
       ["teamSize"] = 2
    },
    ["Crystal Lake"] =    {
       ["creator"] = "GloriedRage",
       ["neutralAllowed"] = true,
       ["size"] = Vector3.new(500, 228, 300),
       ["supportsCTF"] = true,
       ["supportsControlPoints"] = true,
       ["teamSize"] = 2,
       ["thumbnail"] = "rbxassetid://11564755954"
    },
    ["Duel1"] =    {
       ["creator"] = "koke15",
       ["neutralAllowed"] = true,
       ["size"] = Vector3.new(259, 219, 360),
       ["supportsCTF"] = false,
       ["supportsControlPoints"] = false,
       ["teamSize"] = 2
    },
    ["Duel3"] =    {
       ["creator"] = "koke15",
       ["neutralAllowed"] = true,
       ["size"] = Vector3.new(259, 219, 360),
       ["supportsCTF"] = false,
       ["supportsControlPoints"] = false,
       ["teamSize"] = 2,
       ["thumbnail"] = "rbxassetid://11567441815"
    },
    ["Duel5"] =    {
       ["creator"] = "koke15",
       ["neutralAllowed"] = true,
       ["size"] = Vector3.new(260, 219, 360),
       ["supportsCTF"] = false,
       ["supportsControlPoints"] = false,
       ["teamSize"] = 2,
       ["thumbnail"] = "rbxassetid://11566642381"
    },
    ["Duel8"] =    {
       ["creator"] = "koke15",
       ["neutralAllowed"] = true,
       ["size"] = Vector3.new(259, 219, 360),
       ["supportsCTF"] = false,
       ["supportsControlPoints"] = false,
       ["teamSize"] = 2
    },
    ["FCG"] =    {
       ["creator"] = "koke15",
       ["neutralAllowed"] = true,
       ["size"] = Vector3.new(460, 233, 460),
       ["supportsCTF"] = false,
       ["supportsControlPoints"] = false,
       ["teamSize"] = 0
    },
    ["Faction Action"] =    {
       ["creator"] = "GFink",
       ["neutralAllowed"] = true,
       ["size"] = Vector3.new(556, 293, 550),
       ["supportsCTF"] = true,
       ["supportsControlPoints"] = true,
       ["teamSize"] = 3
    },
    ["Forest"] =    {
       ["creator"] = "Boy4u2, MrUnlucky",
       ["neutralAllowed"] = true,
       ["size"] = Vector3.new(358, 254, 992),
       ["supportsCTF"] = true,
       ["supportsControlPoints"] = true,
       ["teamSize"] = 2
    },
    ["Fort Vulcan"] =    {
       ["creator"] = "GloriedRage",
       ["neutralAllowed"] = true,
       ["size"] = Vector3.new(1916, 437, 1927),
       ["supportsCTF"] = false,
       ["supportsControlPoints"] = true,
       ["teamSize"] = 2
    },
    ["FullMetal"] =    {
       ["creator"] = "Fullmetalbloxxer",
       ["neutralAllowed"] = true,
       ["size"] = Vector3.new(457, 137, 407),
       ["supportsCTF"] = false,
       ["supportsControlPoints"] = false,
       ["teamSize"] = 2
    },
    ["Galactic Times"] =    {
       ["creator"] = "snarl",
       ["neutralAllowed"] = true,
       ["size"] = Vector3.new(503, 221, 304),
       ["supportsCTF"] = true,
       ["supportsControlPoints"] = true,
       ["teamSize"] = 2
    },
    ["Ghost Town"] =    {
       ["creator"] = "homepunch",
       ["neutralAllowed"] = true,
       ["size"] = Vector3.new(502, 271, 302),
       ["supportsCTF"] = false,
       ["supportsControlPoints"] = false,
       ["teamSize"] = 2
    },
    ["Goldenfield"] =    {
       ["creator"] = "Boy4u2, NewtonVolta9, MrUnlucky",
       ["neutralAllowed"] = true,
       ["size"] = Vector3.new(504, 323, 708),
       ["supportsCTF"] = true,
       ["supportsControlPoints"] = true,
       ["teamSize"] = 2
    },
    ["Gorge"] =    {
       ["creator"] = "outflash/EnigmaPenguin/haypro",
       ["neutralAllowed"] = true,
       ["size"] = Vector3.new(322, 58, 278),
       ["supportsCTF"] = true,
       ["supportsControlPoints"] = true,
       ["teamSize"] = 2
    },
    ["Harvest Road"] =    {
       ["creator"] = "RocketMan",
       ["neutralAllowed"] = true,
       ["size"] = Vector3.new(406, 69, 406),
       ["supportsCTF"] = false,
       ["supportsControlPoints"] = false,
       ["teamSize"] = 2
    },
    ["Haven Fields"] =    {
       ["creator"] = "RocketMan",
       ["neutralAllowed"] = true,
       ["size"] = Vector3.new(500, 243, 300),
       ["supportsCTF"] = true,
       ["supportsControlPoints"] = true,
       ["teamSize"] = 2
    },
    ["Heaven"] =    {
       ["creator"] = "CloudGrump",
       ["neutralAllowed"] = true,
       ["size"] = Vector3.new(341, 70, 240),
       ["supportsCTF"] = false,
       ["supportsControlPoints"] = false,
       ["teamSize"] = 2
    },
    ["Hill Swamp"] =    {
       ["creator"] = "GloriedRage",
       ["neutralAllowed"] = true,
       ["size"] = Vector3.new(504, 121, 505),
       ["supportsCTF"] = false,
       ["supportsControlPoints"] = true,
       ["teamSize"] = 2
    },
    ["Hurricane"] =    {
       ["creator"] = "567koala",
       ["neutralAllowed"] = true,
       ["size"] = Vector3.new(500, 175, 707),
       ["supportsCTF"] = true,
       ["supportsControlPoints"] = true,
       ["teamSize"] = 2
    },
    ["Jack O' Lanterns Den"] =    {
       ["creator"] = "CloudGrump, ccyan",
       ["neutralAllowed"] = true,
       ["size"] = Vector3.new(108, 152, 250),
       ["supportsCTF"] = false,
       ["supportsControlPoints"] = false,
       ["teamSize"] = 2
    },
    ["Kingdom"] =    {
       ["creator"] = "Boy4u2, NewtonVolta9, MrUnlucky, glowsar",
       ["neutralAllowed"] = true,
       ["size"] = Vector3.new(405, 104, 456),
       ["supportsCTF"] = false,
       ["supportsControlPoints"] = false,
       ["teamSize"] = 4
    },
    ["KoahRong"] =    {
       ["creator"] = "koke15",
       ["neutralAllowed"] = true,
       ["size"] = Vector3.new(2162, 1098, 2048),
       ["supportsCTF"] = true,
       ["supportsControlPoints"] = true,
       ["teamSize"] = 2
    },
    ["Krypton"] =    {
       ["creator"] = "GloriedRage",
       ["neutralAllowed"] = true,
       ["size"] = Vector3.new(300, 427, 500),
       ["supportsCTF"] = true,
       ["supportsControlPoints"] = false,
       ["teamSize"] = 2,
       ["thumbnail"] = "rbxassetid://11565600116"
    },
    ["Layer_2"] =    {
       ["creator"] = "odkal",
       ["neutralAllowed"] = true,
       ["size"] = Vector3.new(439, 415, 259),
       ["supportsCTF"] = false,
       ["supportsControlPoints"] = false,
       ["teamSize"] = 2
    },
    ["Leviathan"] =    {
       ["creator"] = "GloriedRage",
       ["neutralAllowed"] = true,
       ["size"] = Vector3.new(507, 368, 300),
       ["supportsCTF"] = false,
       ["supportsControlPoints"] = false,
       ["teamSize"] = 2
    },
    ["Mad Mad Massacre"] =    {
       ["creator"] = "Boy4u2/Bloodtussk",
       ["neutralAllowed"] = true,
       ["size"] = Vector3.new(208, 233, 753),
       ["supportsCTF"] = true,
       ["supportsControlPoints"] = false,
       ["teamSize"] = 2
    },
    ["Map1"] =    {
       ["creator"] = "koke15",
       ["neutralAllowed"] = true,
       ["size"] = Vector3.new(410, 451, 460),
       ["supportsCTF"] = false,
       ["supportsControlPoints"] = false,
       ["teamSize"] = 2,
       ["thumbnail"] = "rbxassetid://11567441638"
    },
    ["Map10"] =    {
       ["creator"] = "koke15",
       ["neutralAllowed"] = true,
       ["size"] = Vector3.new(410, 451, 460),
       ["supportsCTF"] = false,
       ["supportsControlPoints"] = false,
       ["teamSize"] = 2,
       ["thumbnail"] = "rbxassetid://11567440096"
    },
    ["Map11"] =    {
       ["creator"] = "koke15",
       ["neutralAllowed"] = true,
       ["size"] = Vector3.new(410, 451, 460),
       ["supportsCTF"] = false,
       ["supportsControlPoints"] = false,
       ["teamSize"] = 2,
       ["thumbnail"] = "rbxassetid://11567439906"
    },
    ["Map12"] =    {
       ["creator"] = "Boy4u2/NewtonVolta",
       ["neutralAllowed"] = true,
       ["size"] = Vector3.new(410, 451, 460),
       ["supportsCTF"] = false,
       ["supportsControlPoints"] = true,
       ["teamSize"] = 2,
       ["thumbnail"] = "rbxassetid://11566629111"
    },
    ["Map2"] =    {
       ["creator"] = "koke15",
       ["neutralAllowed"] = true,
       ["size"] = Vector3.new(410, 451, 460),
       ["supportsCTF"] = false,
       ["supportsControlPoints"] = false,
       ["teamSize"] = 2,
       ["thumbnail"] = "rbxassetid://11567441528"
    },
    ["Map3"] =    {
       ["creator"] = "koke15",
       ["neutralAllowed"] = true,
       ["size"] = Vector3.new(410, 451, 460),
       ["supportsCTF"] = false,
       ["supportsControlPoints"] = false,
       ["teamSize"] = 2,
       ["thumbnail"] = "rbxassetid://11567441368"
    },
    ["Map4"] =    {
       ["creator"] = "koke15",
       ["neutralAllowed"] = true,
       ["size"] = Vector3.new(410, 451, 460),
       ["supportsCTF"] = false,
       ["supportsControlPoints"] = false,
       ["teamSize"] = 2,
       ["thumbnail"] = "rbxassetid://11567441229"
    },
    ["Map5"] =    {
       ["creator"] = "koke15",
       ["neutralAllowed"] = true,
       ["size"] = Vector3.new(410, 451, 460),
       ["supportsCTF"] = false,
       ["supportsControlPoints"] = false,
       ["teamSize"] = 2,
       ["thumbnail"] = "rbxassetid://11567440937"
    },
    ["Map6"] =    {
       ["creator"] = "koke15",
       ["neutralAllowed"] = true,
       ["size"] = Vector3.new(410, 451, 460),
       ["supportsCTF"] = false,
       ["supportsControlPoints"] = false,
       ["teamSize"] = 2,
       ["thumbnail"] = "rbxassetid://11567440640"
    },
    ["Map7"] =    {
       ["creator"] = "koke15",
       ["neutralAllowed"] = true,
       ["size"] = Vector3.new(410, 451, 460),
       ["supportsCTF"] = false,
       ["supportsControlPoints"] = false,
       ["teamSize"] = 2,
       ["thumbnail"] = "rbxassetid://11567440526"
    },
    ["Map8"] =    {
       ["creator"] = "koke15",
       ["neutralAllowed"] = true,
       ["size"] = Vector3.new(410, 451, 460),
       ["supportsCTF"] = false,
       ["supportsControlPoints"] = false,
       ["teamSize"] = 2,
       ["thumbnail"] = "rbxassetid://11567440388"
    },
    ["Map9"] =    {
       ["creator"] = "koke15",
       ["neutralAllowed"] = true,
       ["size"] = Vector3.new(410, 451, 460),
       ["supportsCTF"] = false,
       ["supportsControlPoints"] = false,
       ["teamSize"] = 2,
       ["thumbnail"] = "rbxassetid://11567440292"
    },
    ["Mars"] =    {
       ["creator"] = "vbaumel",
       ["neutralAllowed"] = true,
       ["size"] = Vector3.new(500, 261, 300),
       ["supportsCTF"] = true,
       ["supportsControlPoints"] = false,
       ["teamSize"] = 2
    },
    ["Midflat"] =    {
       ["creator"] = "GloriedRage",
       ["neutralAllowed"] = true,
       ["size"] = Vector3.new(340, 25, 240),
       ["supportsCTF"] = false,
       ["supportsControlPoints"] = false,
       ["teamSize"] = 2
    },
    ["Moose"] =    {
       ["creator"] = "Sn_rl",
       ["neutralAllowed"] = true,
       ["size"] = Vector3.new(306, 56, 217),
       ["supportsCTF"] = false,
       ["supportsControlPoints"] = false,
       ["teamSize"] = 2
    },
    ["Mount Vanta"] =    {
       ["creator"] = "koke15",
       ["neutralAllowed"] = true,
       ["size"] = Vector3.new(400, 101, 402),
       ["supportsCTF"] = false,
       ["supportsControlPoints"] = false,
       ["teamSize"] = 2
    },
    ["Nirvana"] =    {
       ["creator"] = "GloriedRage",
       ["neutralAllowed"] = true,
       ["size"] = Vector3.new(339, 41, 240),
       ["supportsCTF"] = false,
       ["supportsControlPoints"] = false,
       ["teamSize"] = 2
    },
    ["OMG"] =    {
       ["creator"] = "MadSanity",
       ["neutralAllowed"] = true,
       ["size"] = Vector3.new(456, 95, 456),
       ["supportsCTF"] = false,
       ["supportsControlPoints"] = false,
       ["teamSize"] = 0
    },
    ["Of Fleeting Dreams"] =    {
       ["creator"] = "Delfino",
       ["neutralAllowed"] = true,
       ["size"] = Vector3.new(702, 2122, 903),
       ["supportsCTF"] = true,
       ["supportsControlPoints"] = false,
       ["teamSize"] = 2
    },
    ["Open Night"] =    {
       ["creator"] = "GloriedRage",
       ["neutralAllowed"] = true,
       ["size"] = Vector3.new(210, 38, 196),
       ["supportsCTF"] = false,
       ["supportsControlPoints"] = false,
       ["teamSize"] = 2
    },
    ["PXF"] =    {
       ["creator"] = "koke15",
       ["neutralAllowed"] = true,
       ["size"] = Vector3.new(456, 66, 456),
       ["supportsCTF"] = false,
       ["supportsControlPoints"] = false,
       ["teamSize"] = 0
    },
    ["Pitch"] =    {
       ["creator"] = "swords333",
       ["neutralAllowed"] = true,
       ["size"] = Vector3.new(259, 16, 166),
       ["supportsCTF"] = false,
       ["supportsControlPoints"] = false,
       ["teamSize"] = 2
    },
    ["Pitgrounds"] =    {
       ["creator"] = "keitheroni (RCL)",
       ["neutralAllowed"] = true,
       ["size"] = Vector3.new(418, 71, 329),
       ["supportsCTF"] = true,
       ["supportsControlPoints"] = false,
       ["teamSize"] = 2
    },
    ["Point Phosphor"] =    {
       ["creator"] = "YungPhosphor",
       ["neutralAllowed"] = true,
       ["size"] = Vector3.new(498, 205, 702),
       ["supportsCTF"] = true,
       ["supportsControlPoints"] = true,
       ["teamSize"] = 2
    },
    ["Pwn2"] =    {
       ["creator"] = "odkal",
       ["neutralAllowed"] = true,
       ["size"] = Vector3.new(410, 97, 410),
       ["supportsCTF"] = true,
       ["supportsControlPoints"] = true,
       ["teamSize"] = 2
    },
    ["Pwn3"] =    {
       ["creator"] = "odkal",
       ["neutralAllowed"] = true,
       ["size"] = Vector3.new(411, 349, 416),
       ["supportsCTF"] = true,
       ["supportsControlPoints"] = true,
       ["teamSize"] = 2
    },
    ["Pwn4"] =    {
       ["creator"] = "odkal",
       ["neutralAllowed"] = true,
       ["size"] = Vector3.new(600, 308, 600),
       ["supportsCTF"] = true,
       ["supportsControlPoints"] = true,
       ["teamSize"] = 2
    },
    ["Raven Rock"] =    {
       ["creator"] = "Games (ROBLOXBATTLE)",
       ["neutralAllowed"] = true,
       ["size"] = Vector3.new(404, 106, 404),
       ["supportsCTF"] = true,
       ["supportsControlPoints"] = true,
       ["teamSize"] = 2
    },
    ["Rocket Arena"] =    {
       ["creator"] = "Shedletsky",
       ["neutralAllowed"] = true,
       ["size"] = Vector3.new(512, 93, 512),
       ["supportsCTF"] = true,
       ["supportsControlPoints"] = true,
       ["teamSize"] = 2
    },
    ["Sand Valley"] =    {
       ["creator"] = "RocketMan",
       ["neutralAllowed"] = true,
       ["size"] = Vector3.new(340, 30, 240),
       ["supportsCTF"] = false,
       ["supportsControlPoints"] = false,
       ["teamSize"] = 2
    },
    ["Savanna"] =    {
       ["creator"] = "GloriedRage",
       ["neutralAllowed"] = true,
       ["size"] = Vector3.new(501, 205, 302),
       ["supportsCTF"] = false,
       ["supportsControlPoints"] = false,
       ["teamSize"] = 2
    },
    ["Serpant Arena"] =    {
       ["creator"] = "koke15",
       ["neutralAllowed"] = true,
       ["size"] = Vector3.new(303, 73, 468),
       ["supportsCTF"] = false,
       ["supportsControlPoints"] = false,
       ["teamSize"] = 2
    },
    ["Siege"] =    {
       ["creator"] = "ep/outflash (RCL)",
       ["neutralAllowed"] = true,
       ["size"] = Vector3.new(276, 32, 394),
       ["supportsCTF"] = true,
       ["supportsControlPoints"] = true,
       ["teamSize"] = 2
    },
    ["Skylands"] =    {
       ["creator"] = "Games (ROBLOXBATTLE)",
       ["neutralAllowed"] = true,
       ["size"] = Vector3.new(1336, 894, 943),
       ["supportsCTF"] = true,
       ["supportsControlPoints"] = true,
       ["teamSize"] = 2
    },
    ["Snow"] =    {
       ["creator"] = "GloriedRage, glowsar",
       ["neutralAllowed"] = true,
       ["size"] = Vector3.new(756, 348, 1080),
       ["supportsCTF"] = true,
       ["supportsControlPoints"] = false,
       ["teamSize"] = 2
    },
    ["Snowy Cabins"] =    {
       ["creator"] = "GloriedRage",
       ["neutralAllowed"] = true,
       ["size"] = Vector3.new(214, 47, 196),
       ["supportsCTF"] = false,
       ["supportsControlPoints"] = false,
       ["teamSize"] = 2
    },
    ["Spike Canyon"] =    {
       ["creator"] = "Boy4u2",
       ["neutralAllowed"] = true,
       ["size"] = Vector3.new(499, 133, 300),
       ["supportsCTF"] = false,
       ["supportsControlPoints"] = false,
       ["teamSize"] = 2
    },
    ["Steeltops"] =    {
       ["creator"] = "BenBonez (RCL)",
       ["neutralAllowed"] = true,
       ["size"] = Vector3.new(252, 59, 348),
       ["supportsCTF"] = true,
       ["supportsControlPoints"] = true,
       ["teamSize"] = 2
    },
    ["Stonebricks"] =    {
       ["creator"] = "thea96 (RCL)/swords333",
       ["neutralAllowed"] = true,
       ["size"] = Vector3.new(248, 186, 348),
       ["supportsCTF"] = true,
       ["supportsControlPoints"] = true,
       ["teamSize"] = 2
    },
    ["Sunset Park"] =    {
       ["creator"] = "GloriedRage",
       ["neutralAllowed"] = true,
       ["size"] = Vector3.new(339, 44, 240),
       ["supportsCTF"] = false,
       ["supportsControlPoints"] = false,
       ["teamSize"] = 2
    },
    ["Swamp"] =    {
       ["creator"] = "koke15",
       ["neutralAllowed"] = true,
       ["size"] = Vector3.new(500, 244, 301),
       ["supportsCTF"] = true,
       ["supportsControlPoints"] = false,
       ["teamSize"] = 2
    },
    ["Taipan"] =    {
       ["creator"] = "koke15",
       ["neutralAllowed"] = true,
       ["size"] = Vector3.new(406, 76, 456),
       ["supportsCTF"] = false,
       ["supportsControlPoints"] = false,
       ["teamSize"] = 2
    },
    ["Throneland"] =    {
       ["creator"] = "GloriedRage",
       ["neutralAllowed"] = true,
       ["size"] = Vector3.new(591, 397, 577),
       ["supportsCTF"] = false,
       ["supportsControlPoints"] = false,
       ["teamSize"] = 2
    },
    ["Trenches"] =    {
       ["creator"] = "swords333",
       ["neutralAllowed"] = true,
       ["size"] = Vector3.new(333, 34, 200),
       ["supportsCTF"] = true,
       ["supportsControlPoints"] = true,
       ["teamSize"] = 2
    },
    ["Tribute"] =    {
       ["creator"] = "ep (RCL)",
       ["neutralAllowed"] = true,
       ["size"] = Vector3.new(276, 36, 376),
       ["supportsCTF"] = true,
       ["supportsControlPoints"] = true,
       ["teamSize"] = 2
    },
    ["Tron"] =    {
       ["creator"] = "swords333",
       ["neutralAllowed"] = true,
       ["size"] = Vector3.new(302, 452, 41),
       ["supportsCTF"] = true,
       ["supportsControlPoints"] = true,
       ["teamSize"] = 2
    },
    ["TwoFlags"] =    {
       ["creator"] = "CloudGrump",
       ["neutralAllowed"] = true,
       ["size"] = Vector3.new(70, 127, 70),
       ["supportsCTF"] = true,
       ["supportsControlPoints"] = true,
       ["teamSize"] = 2
    },
    ["Viper Crater"] =    {
       ["creator"] = "koke15",
       ["neutralAllowed"] = true,
       ["size"] = Vector3.new(399, 210, 400),
       ["supportsCTF"] = false,
       ["supportsControlPoints"] = false,
       ["teamSize"] = 2
    },
    ["White"] =    {
       ["creator"] = "homepunch",
       ["neutralAllowed"] = true,
       ["size"] = Vector3.new(556, 652, 445),
       ["supportsCTF"] = true,
       ["supportsControlPoints"] = false,
       ["teamSize"] = 2
    },
    ["Winter Valley"] =    {
       ["creator"] = "joacimblue4",
       ["neutralAllowed"] = true,
       ["size"] = Vector3.new(200, 54, 200),
       ["supportsCTF"] = false,
       ["supportsControlPoints"] = false,
       ["teamSize"] = 2
    },
    ["Yellow"] =    {
       ["creator"] = "homepunch",
       ["neutralAllowed"] = true,
       ["size"] = Vector3.new(556, 652, 445),
       ["supportsCTF"] = true,
       ["supportsControlPoints"] = false,
       ["teamSize"] = 2
    }
 }

return function(target)
    local store = Rodux.Store.new(RoduxFeatures.reducer, nil, { Rodux.thunkMiddleware })
    store:dispatch(RoduxFeatures.actions.setMapInfo(test))

	local tree
	local roactTree = e(MapListApp, {
		onClosed = function()
			Roact.unmount(tree)
		end;
        activeMap = next(test);
		getThumbnail = function()
			return "rbxassetid://11565600116"
		end;
	})
    
	roactTree = Roact.createElement(RoactRodux.StoreProvider, {
		store = store;
	}, {
		Main = roactTree
	})

	tree = Roact.mount(roactTree, target)

	return function()
		Roact.unmount(tree)
	end
end