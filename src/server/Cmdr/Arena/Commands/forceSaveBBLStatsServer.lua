return function(context)
    local ok = context:GetStore("Common").Knit.GetService("BBLService"):_flushStatsToDataStore()

    return
        ok
        and "Successfully saved"
        or "Something went wrong with saving. Check console"
end