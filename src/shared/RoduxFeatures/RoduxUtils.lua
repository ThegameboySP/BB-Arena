local RoduxUtils = {}

function RoduxUtils.createReducer(initialState, handlers)
	return function(state, action, rootState)
		if state == nil then
			state = initialState
		end

		local handler = handlers[action.type]

		if handler then
			return handler(state, action, rootState)
		end

		return state
	end
end


function RoduxUtils.numberIndicesToString(map)
    local strMap = {}
    for number, value in pairs(map) do
        strMap[tostring(number)] = value
    end

    return strMap
end

function RoduxUtils.stringIndicesToNumber(map)
    local numberMap = {}
    for str, value in pairs(map) do
        numberMap[tonumber(str)] = value
    end

    return numberMap
end

return RoduxUtils