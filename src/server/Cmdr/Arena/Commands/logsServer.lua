local LOG_FORMAT = "%s: '%s' -> '%s'" -- Executor name, raw text, formatted text, output

return function(context, filterPlayer)
    local CmdrService = context:GetStore("Common").Root:GetService("CmdrService")
    local logs = CmdrService:GetLogs()

    local filterName = filterPlayer
    if typeof(filterPlayer) == "Instance" then
        filterName = filterPlayer.Name
    end

    for _, log in ipairs(logs) do
        if filterPlayer == nil or log.ExecutorName == filterName then
            context:Reply(LOG_FORMAT:format(log.ExecutorName, log.RawText, log.Response or "Command executed."))
        end
    end
    
    return ""
end