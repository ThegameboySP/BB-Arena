local function initializeMiddleware(onInitializing)
	return function(nextFn)
		return function(value, isInitializing)
			if isInitializing then
				return onInitializing(value), true
			end

			return nextFn(value, isInitializing)
		end
	end
end

return initializeMiddleware
