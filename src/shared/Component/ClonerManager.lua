local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

local ComponentManager = require(script.Parent.ComponentManager)
local Cloner = require(ReplicatedStorage.Common.Cloner)

local function getMatchedTagsByPrototype(root, tags, isServer, matchedTagsByPrototype)
	for _, child in pairs(root:GetChildren()) do
		if isServer and child.Name == "Client" then
			continue
		end

		local matchedTagsMap = {}
		for _, tag in pairs(CollectionService:GetTags(child)) do
			if tags[tag] then
				matchedTagsMap[tag] = true
			end
		end

		if next(matchedTagsMap) then
			matchedTagsByPrototype[child] = matchedTagsMap
		end

		getMatchedTagsByPrototype(child, tags, false, matchedTagsByPrototype)
	end

	return matchedTagsByPrototype
end

local function getConfig(instance, tag)
	local config = {}
	local attributes = instance:GetAttributes()

	for name, value in pairs(attributes) do
		if string.sub(name, 1, #tag + 1) == (tag .. "_") then
			config[string.sub(name, #tag + 2, -1)] = value
		end
	end

	return config
end

local ClonerManager = {}
ClonerManager.ReplicatedRoot = ReplicatedStorage
ClonerManager.__index = ClonerManager

function ClonerManager.new(namespace)
	return setmetatable({
		_registered = {},
		_namespace = namespace,
		_folder = nil,

		_instanceQueue = {},
		_classQueue = {},
		_paramsQueue = {},

		Manager = ComponentManager.new(),
		Cloner = nil,
	}, ClonerManager)
end

function ClonerManager:_initCloner(root, isServer)
	self.Cloner = Cloner.new(getMatchedTagsByPrototype(root, self._registered, isServer, {}), function(clones)
		for _, record in pairs(clones) do
			for tag in pairs(record.tagsMap) do
				self:_addToQueue(record.clone, tag, getConfig(record.clone, tag))
			end
		end
	end, function(clone, tagsMap)
		for tag in pairs(tagsMap) do
			local class = self._registered[tag]

			if class then
				self.Manager:RemoveComponent(clone, class)
			end
		end
	end)
end

function ClonerManager:_addToQueue(instance, tag, params)
	local class = self._registered[tag]

	if class then
		table.insert(self._instanceQueue, instance)
		table.insert(self._classQueue, class)
		table.insert(self._paramsQueue, params)
	end
end

function ClonerManager:Flush()
	local components = self.Manager:BulkAddComponent(self._instanceQueue, self._classQueue, self._paramsQueue)
	table.clear(self._instanceQueue)
	table.clear(self._classQueue)
	table.clear(self._paramsQueue)

	return components
end

function ClonerManager:ReplicateToClients(components)
	local instances = {}
	local tagMapsByInstance = {}

	for _, component in components do
		if getmetatable(component).noReplicate then
			continue
		end

		if not tagMapsByInstance[component.Instance] then
			tagMapsByInstance[component.Instance] = {}
			table.insert(instances, { component.Instance, tagMapsByInstance[component.Instance] })
		end

		component:ForceReplicate()
		tagMapsByInstance[component.Instance][tostring(component)] = true
		self._replicatedComponents[component] = true
	end

	if instances[1] then
		self._folder.Added:FireAllClients(instances)
	end
end

function ClonerManager:ClientInit(root)
	assert(self.Cloner == nil, "A cloner is already active")

	if not self._folder then
		self._folder = self.ReplicatedRoot:WaitForChild(self._namespace)

		self._folder:WaitForChild("Added").OnClientEvent:Connect(function(instances)
			for _, entry in pairs(instances) do
				if entry[1] == nil then
					warn("[Cloner manager]", "Instance doesn't exist in this realm:", entry[2])
					continue
				end

				for tag in pairs(entry[2]) do
					self:_addToQueue(entry[1], tag, getConfig(entry[1], tag))
				end
			end
		end)

		self._folder:WaitForChild("Removed").OnClientEvent:Connect(function(instance, tag)
			if self._registered[tag] then
				self.Manager:RemoveComponent(instance, self._registered[tag])
			end
		end)
	end

	self:_initCloner(root, false)
end

function ClonerManager:ServerInit(root)
	assert(self.Cloner == nil, "A cloner is already active")

	if not self._folder then
		self._replicatedComponents = {}

		self._folder = Instance.new("Folder")
		self._folder.Name = self._namespace

		local added = Instance.new("RemoteEvent")
		added.Name = "Added"
		added.Parent = self._folder

		local removed = Instance.new("RemoteEvent")
		removed.Name = "Removed"
		removed.Parent = self._folder

		self._folder.Parent = self.ReplicatedRoot

		local function onPlayerAdded(player)
			local instances = {}

			for instance, components in pairs(self.Manager._componentsByInstance) do
				local tagsMap = {}
				for component in pairs(components) do
					tagsMap[tostring(component)] = true
				end

				table.insert(instances, { instance, tagsMap })
			end

			added:FireClient(player, instances)
		end

		Players.PlayerAdded:Connect(onPlayerAdded)
		for _, player in pairs(Players:GetPlayers()) do
			onPlayerAdded(player)
		end

		self.Manager.RemovingComponent:Connect(function(component)
			if self._replicatedComponents[component] then
				self._replicatedComponents[component] = nil

				self._folder.Removed:FireAllClients(component.Instance, tostring(component))
			end
		end)
	end

	self:_initCloner(root, true)
end

function ClonerManager:Clear()
	if self.Cloner then
		self.Cloner:Destroy()
		self.Cloner = nil
	end

	self.Manager:Clear()

	table.clear(self._instanceQueue)
	table.clear(self._classQueue)
	table.clear(self._paramsQueue)
end

function ClonerManager:Register(class)
	if class.dontClone then
		return
	end

	if self._registered[tostring(class)] then
		error(("Duplicate component class %q"):format(tostring(class)))
	end

	self._registered[tostring(class)] = class
	self.Manager:Register(class)
end

return ClonerManager
