return function(context, commands)
    local CmdrService = context:GetStore("Common").Knit.GetService("CmdrService")
    local userId = context.Executor.UserId

    for _, commandName in ipairs(commands) do
        local _, msg = CmdrService:UnlockCommand(commandName, userId)

        if msg then
            context:Reply(msg)
        end
    end

    return ""
end