local function loggerMiddleware(nextDispatch, store)
	return function(action)
		local result = nextDispatch(action)

		print("Action", action.type, "dispatched:", action, "State changed to:", store:getState())

		return result
	end
end

return loggerMiddleware
