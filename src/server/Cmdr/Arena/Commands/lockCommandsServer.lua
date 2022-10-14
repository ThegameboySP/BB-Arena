return function(context, commands)
    local CmdrService = context:GetStore("Common").Root:GetService("CmdrService")
    local userId = context.Executor.UserId

    for _, commandName in ipairs(commands) do
        local msg = CmdrService:LockCommand(commandName, userId)

        if msg then
            context:Reply(msg)
        end
    end

    return ""
end