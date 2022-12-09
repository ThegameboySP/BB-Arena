local NIL_SYMBOL = "__nil"

local deltaMiddleware = {
	None = NIL_SYMBOL,

	outbound = function(nextFn)
		local lastValue

		return function(value, isInitializing)
			if isInitializing then
				return nextFn(value, true)
			end

			local delta = value

			if type(value) == "table" then
				if type(lastValue) == "table" then
					delta = {}

					for k, v in pairs(value) do
						if lastValue[k] ~= v then
							delta[k] = v
						end
					end

					for k in pairs(lastValue) do
						if value[k] == nil then
							delta[k] = NIL_SYMBOL
						end
					end

					if not next(delta) then
						return
					end
				end
			end

			lastValue = value

			return nextFn(delta, isInitializing)
		end
	end,

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
			end

			lastResolvedValue = resolvedValue

			return nextFn(resolvedValue)
		end
	end,
}

return deltaMiddleware
