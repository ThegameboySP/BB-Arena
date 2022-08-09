local Players = game:GetService("Players")

return function (context, seconds)
    task.spawn(function()
        for i = seconds, 0, -1 do
            for _, player in Players:GetPlayers() do
                if i > 0 then
                    context:SendEvent(player, "Countdown", tostring(i), context.Executor, 0.5)
                else
                    context:SendEvent(player, "Countdown", "GO!", context.Executor, 1)
                end
            end

            task.wait(1)
        end
    end)
end