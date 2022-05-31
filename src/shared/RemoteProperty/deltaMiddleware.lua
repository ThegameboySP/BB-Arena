local NIL_SYMBOL = "__nil"

local deltaMiddleware = {
    outbound = function(nextFn)
        local lastValue

        return function(value, isInitializing)
            local resolvedValue = value

            if not isInitializing then
                if type(value) == "table" then
                    if type(lastValue) == "table" then
                        resolvedValue = {}
            
                        for k, v in pairs(value) do
                            if lastValue[k] ~= v then
                                resolvedValue[k] = v
                            end
                        end
            
                        for k in pairs(lastValue) do
                            if value[k] == nil then
                                resolvedValue[k] = NIL_SYMBOL
                            end
                        end
            
                        if not next(resolvedValue) then
                            return nil
                        end
                    end
                end

                lastValue = value

                return nextFn(resolvedValue, isInitializing)
            end

            return nextFn(value, isInitializing)
        end
    end;

    inbound = function(nextFn)
        local lastResolvedValue

        return function(replicatedValue)
            local resolvedValue = replicatedValue

            if type(replicatedValue) == "table" and type(lastResolvedValue) == "table" then
                resolvedValue = table.clone(lastResolvedValue)
        
                for k, v in pairs(replicatedValue) do
                    if v == NIL_SYMBOL then
                        resolvedValue[k] = nil
                    else
                        resolvedValue[k] = v
                    end
                end

                table.freeze(resolvedValue)
            end

            lastResolvedValue = resolvedValue

            return nextFn(resolvedValue)
        end
    end
}

return deltaMiddleware