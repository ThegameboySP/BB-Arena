local function loggerOutboundMiddleware(nextFn)
	return function(value, isInitializing)
		if isInitializing then
			print("outbound initializing remote value:", value)
		else
			print("new outbound remote value:", value)
		end

		return nextFn(value)
	end
end

local function loggerInboundMiddleware(nextFn)
	return function(value)
		print("new inbound remote value:", value)

		return nextFn(value)
	end
end

return {
	inbound = loggerInboundMiddleware,
	outbound = loggerOutboundMiddleware,
}
