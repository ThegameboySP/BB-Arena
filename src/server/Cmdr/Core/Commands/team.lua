return {
	Name = "team";
	Aliases = {"t"};
	Description = "Assigns players to a team";
	Group = "Admin";
    AutoExec = {
		'alias "tsp|Teams players to a team and then spawns them." team $1{players|Players} $2{team|Team} && spawn $1';
		'alias "tre|Teams players to a team and then refreshes them." team $1{players|Players} $2{team|Team} && re $1';
	};
	Args = {
		{
			Type = "players";
			Name = "Players";
			Description = "Names of the players to assign";
		},
		{
			Type = "team";
			Name = "Team";
			Description = "The team to assign";
		}
	};
}