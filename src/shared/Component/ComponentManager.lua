local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Signal = require(ReplicatedStorage.Packages.Signal)

local Manager = {}
Manager.__index = Manager

function Manager.new()
    return setmetatable({
        AddedComponents = Signal.new();
        RemovingComponent = Signal.new();

        _componentsByInstance = {};
        _componentsByClass = {};
    }, Manager)
end

function Manager:_assertComponent(item)
    if not type(item) == "table" or not item.new then
        error(("Expected component, got %s"):format(tostring(item)), 3)
    end
end

function Manager:AddComponent(instance, class, params)
    self:_assertComponent(class)

    local existingComponent = self:GetComponent(instance, class)
    if existingComponent then
        return existingComponent
    end

    local component = class.new(instance, params)
    self:_addComponent(instance, component, params)
    component:OnInit()
    component:OnStart()
    
    self.AddedComponents:Fire({component})

    return component
end

function Manager:_addComponent(instance, component, params)
    local class = getmetatable(component)
    if class.checkInstance then
        local ok, err = class.checkInstance(instance)
        if not ok then
            error(("Component %q at %s instance check failed:\n%s"):format(tostring(class), instance:GetFullName(), err))
        end
    end

    if class.checkConfig then
        local ok, err = class.checkConfig(params)
        if not ok then
            error(("Component %q at %s config check failed:\n%s"):format(tostring(class), instance:GetFullName(), err))
        end
    end

    self._componentsByInstance[instance] = self._componentsByInstance[instance] or {}
    self._componentsByInstance[instance][class] = component

    self._componentsByClass[class] = self._componentsByClass[class] or {}
    self._componentsByClass[class][component] = true
end

function Manager:BulkAddComponent(instances, classes, params)
    local added = {}

    for i, instance in ipairs(instances) do
        local class = classes[i]
        self:_assertComponent(class)

        if self:GetComponent(instance, class) then
            self:RemoveComponent(instance, class)
        end

        local component = class.new(instance, params[i])
        self:_addComponent(instance, component, params[i])
        
        component:OnInit()
        table.insert(added, component)
    end

    for _, component in ipairs(added) do
        component:OnStart()
    end

    self.AddedComponents:Fire(added)

    return added
end

function Manager:RemoveComponent(instance, class)
    self:_assertComponent(class)

    local component = self:GetComponent(instance, class)
    if not component then
        return
    end

    self.RemovingComponent:Fire(component)

    self._componentsByInstance[instance][class] = nil
    self._componentsByClass[class][component] = nil
    component:Destroy()
end

function Manager:GetComponent(instance, class)
    self:_assertComponent(class)

    local components = self._componentsByInstance[instance]
    if components == nil then
        return nil
    end
    
    return components[class]
end

function Manager:GetComponents(class)
    self:_assertComponent(class)

    local components = self._componentsByClass[class]
    if components == nil then
        return {}
    end

    local added = {}
    for component in pairs(components) do
        table.insert(added, component)
    end

    return added
end

function Manager:Clear()
    for instance, classes in pairs(self._componentsByInstance) do
        for class in pairs(classes) do
            self:RemoveComponent(instance, class)
        end
    end
end

return Manager