return {
	Name = "toggleSpectateData";
	Aliases = {"sdata"};
	Description = "Set activation of sending spectate data.";
	Group = "Admin";
	Args = {
		{
			Type = "boolean",
			Name = "enabled",
			Description = "On or off"
		}
	};
}