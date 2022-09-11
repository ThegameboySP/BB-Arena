local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Llama = require(ReplicatedStorage.Packages.Llama)
local Dictionary = Llama.Dictionary

local function combineReducers(map)
	return function(state, action)
		-- If state is nil, substitute it with a blank table.
		if state == nil then
			state = {}
		end

        -- If there is any manually merged data, preserve it.
		local newState = table.clone(state)

		for key, reducer in pairs(map) do
			-- Each reducer gets its own state, not the entire state table
			newState[key] = reducer(state[key], action)
		end

		return newState
	end
end

local features = {}
local reducers = {}
local actions = {}
local selectors = {}
local middlewares = {}

actions.merge = function(with)
    return {
        type = "merge";
        payload = with;
    }
end

for _, module in pairs(script:GetChildren()) do
    local feature = require(module)
    features[module.Name] = feature
    
    if feature.reducer then
        reducers[module.Name] = feature.reducer
    end

    if feature.selectors then
        for selectorName, selector in pairs(feature.selectors) do
            if selectors[selectorName] then
                error(string.format("Duplicate selector name %q", selectorName))
            end
            
            selectors[selectorName] = selector
        end
    end

    if feature.actions then
        for actionName, actionCreator in pairs(feature.actions) do
            if selectors[actionName] then
                error(string.format("Duplicate action name %q", actionName))
            end

            actions[actionName] = actionCreator
        end
    end

    if feature.middlewares then
        for middlewareName, middleware in pairs(feature.middlewares) do
            if middlewares[middlewareName] then
                error(string.format("Duplicate middleware name %q", middlewareName))
            end

            middlewares[middlewareName] = middleware
        end
    end
end

local reducer = combineReducers(reducers)

return {
    index = features;

    reducer = function(state, action)
        if action.type == "merge" then
            return Dictionary.mergeDeep(state, action.payload)
        end

        return reducer(state, action)
    end;
    actions = table.freeze(actions);
    selectors = table.freeze(selectors);
    middlewares = middlewares;
}