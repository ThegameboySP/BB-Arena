return function(registry)
	for _, command in registry.Commands do
		local args = command.Args
		if args == nil then
			continue
		end

		local lastArg = args[#args]

		if
			type(lastArg) == "table"
			and not lastArg.Optional
			and (lastArg.Type == "players" or lastArg.Type == "player")
		then
			lastArg.Optional = true

			local run = command.Run
			if run then
				command.Run = function(context, ...)
					if select(select("#", ...), ...) == nil then
						local newArgs = { ... }

						if lastArg.Type == "players" then
							newArgs[select("#", ...)] = { context.Executor }
						else
							newArgs[select("#", ...)] = context.Executor
						end

						return run(context, unpack(newArgs))
					end

					return run(context, ...)
				end
			end
		end
	end
end
