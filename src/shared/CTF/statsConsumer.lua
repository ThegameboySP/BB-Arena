return function(Gamemode, queue)
    for _, action in ipairs(queue) do
        if action.type == "CTF_EnemyKilledWithFlag" then
            Gamemode.Remotes:fire("CTF_EnemyKilledWithFlag", action.deathRecord.killer, action.deathRecord.victim)
        end
    end
end