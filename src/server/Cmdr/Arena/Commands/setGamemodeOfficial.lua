return {
	Name = "setGamemodeOfficial";
	Aliases = {"official"};
	Description = "Marks the current gamemode as official.";
	Group = "Owner";
    AutoExec = {
        'alias "ocp|Starts a new official game of Control Points." cp $1 && official on';
    };
	Args = {
        {
            Type = "boolean";
            Name = "is official";
            Default = true;
        }
    };
}