return {
    Name = "unban";
    Aliases = {};
    Description = "Unbans UserIds.";
    Group = "Owner";
    Args = {
        {
            Type = "playerId",
            Name = "Player";
            Description = "Player to unban";
        }
    }       
}