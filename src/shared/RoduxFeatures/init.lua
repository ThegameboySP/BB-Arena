local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Rodux = require(ReplicatedStorage.Packages.Rodux)

local features = {}
local reducers = {}
local actions = {}
local selectors = {}

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
end

return {
    index = features;

    reducer = Rodux.combineReducers(reducers);
    actions = table.freeze(actions);
    selectors = table.freeze(selectors);
}