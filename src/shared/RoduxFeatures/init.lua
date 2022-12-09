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
			-- Reducers can read the entire state table, but only if absolutely required.
			newState[key] = reducer(state[key], action, state)
		end

		return newState
	end
end

local features = {}
local reducers = {}
local actions = {}
local selectors = {}
local middlewares = {}
local serializers = {}
local serializersArray = {}

for _, module in script.slices:GetChildren() do
	local feature = require(module)
	if type(feature) ~= "table" then
		continue
	end

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

	if feature.serializers then
		for actionName, entry in pairs(feature.serializers) do
			if serializers[actionName] then
				error(string.format("Duplicate action serializer %q", entry.actionName))
			end

			table.insert(serializersArray, {
				actionName = actionName,
				entry = entry,
			})
		end
	end
end

for _, child in script.middlewares:GetChildren() do
	middlewares[child.Name] = require(child)
end

local reducer = combineReducers(reducers)

table.sort(serializersArray, function(a, b)
	return a.actionName > b.actionName
end)

for index, tbl in serializersArray do
	tbl.entry.id = string.char(index)
	serializers[tbl.entry.id] = tbl.entry
	serializers[tbl.actionName] = tbl.entry
end

function actions.merge(with)
	return {
		type = "rodux_merge",
		payload = with,
	}
end

function actions.serialize(userId, serialized)
	return {
		type = "rodux_serialize",
		payload = {
			userId = userId,
			serialized = serialized,
		},
	}
end

function actions.deserialize(serialized)
	return {
		type = "rodux_deserialize",
		payload = {
			serialized = serialized,
		},
	}
end

return {
	index = features,

	reducer = function(state, action)
		if action.type == "rodux_merge" then
			return Dictionary.mergeDeep(state, action.payload)
		elseif action.type == "rodux_deserialize" then
			return Dictionary.merge(action.payload.serialized, reducer(state, action))
		end

		return reducer(state, action)
	end,

	actions = table.freeze(actions),
	selectors = table.freeze(selectors),
	middlewares = table.freeze(middlewares),
	serializers = table.freeze(serializers),
}
