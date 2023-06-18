local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Signal = require(ReplicatedStorage.Packages.Signal)
local Promise = require(ReplicatedStorage.Packages.Promise)
local RemoteEvent = require(ReplicatedStorage.Common.RemoteEvent)
local RemoteProperty = require(ReplicatedStorage.Common.RemoteProperty)
local Status = require(script.Parent.Status)

local Services = {}
Services.__index = Services

function Services.new(replicatedContainer)
	return setmetatable({
		services = {},
		serverServices = nil,
		status = Status.Uninitialized,
		_replicatedRoot = nil,
		_startedSignal = Signal.new(),
		_replicatedContainer = replicatedContainer or ReplicatedStorage,
	}, Services)
end

function Services:RegisterServices(services)
	for name, service in pairs(services) do
		self:RegisterService(name, service)
	end
end

function Services:RegisterService(name, service)
	if self.services[name] then
		error(("Duplicate service %q"):format(name))
	end

	self.services[name] = service
end

function Services:RegisterServicesIn(root)
	for _, child in pairs(root:GetChildren()) do
		if child:IsA("ModuleScript") then
			self:RegisterService(child.Name, require(child))
		elseif child:IsA("Folder") then
			self:RegisterServicesIn(child)
		end
	end
end

function Services:GetService(name)
	if self.status == Status.Uninitialized then
		error("Cannot call GetService until Services is initialized")
	end

	return self.services[name] or error("No service named " .. name)
end

function Services:GetSingleton(name)
	if self.isServer then
		return self:GetService(name .. "Service")
	else
		return self:GetService(name .. "Controller")
	end
end

function Services:GetServerService(name)
	if self.status == Status.Uninitialized then
		error("Cannot call GetServerService until Root is initialized")
	end

	return if self.serverServices then self.serverServices[name] or error("No server service named " .. name) else nil
end

function Services:Start(root)
	assert(self.status == Status.Uninitialized, "Already started services")

	task.spawn(function()
		self.status = Status.Initializing

		if self.isServer then
			self._replicatedRoot = Instance.new("Folder")
			self._replicatedRoot.Name = "Root_Replication"
			self._replicatedRoot.Parent = self._replicatedContainer
		else
			self._replicatedRoot = self._replicatedContainer:WaitForChild("Root_Replication")

			if not self._replicatedRoot:GetAttribute("Replicated") then
				self._replicatedRoot:GetAttributeChangedSignal("Replicated"):Wait()
			end
		end

		if self.isServer then
			for name, service in pairs(self.services) do
				local folder = Instance.new("Folder")
				folder.Name = name

				for key, value in pairs(service.Client or {}) do
					if value.type == "__remoteEvent" then
						local remoteEvent = Instance.new("RemoteEvent")
						remoteEvent.Name = "RemoteEvent_" .. key
						remoteEvent.Parent = folder

						service.Client[key] = RemoteEvent.new(remoteEvent)
					elseif value.type == "__remoteProperty" then
						service.Client[key] = RemoteProperty.new(folder, "RemoteProperty_" .. key)

						service.Client[key]:Set(value.default)
					end
				end

				folder.Parent = self._replicatedRoot
			end
		else
			self.serverServices = {}

			for _, folder in ipairs(self._replicatedRoot:GetChildren()) do
				local serverService = {}
				self.serverServices[folder.Name] = serverService

				for _, child in ipairs(folder:GetChildren()) do
					if child.Name:find("RemoteEvent") then
						serverService[child.Name:match("RemoteEvent_(.+)$")] = RemoteEvent.new(child)
					elseif child.Name:find("RemoteProperty") then
						serverService[child.Name:match("RemoteProperty_(.+)$")] = RemoteProperty.new(folder, child.Name)
					end
				end
			end
		end

		local servicesOrder = {}
		for _, service in self.services do
			table.insert(servicesOrder, service)
		end

		table.sort(servicesOrder, function(a, b)
			return (a.Priority or 0) > (b.Priority or 0)
		end)

		for _, service in servicesOrder do
			service.Root = root

			if service.OnInit then
				xpcall(service.OnInit, function(err)
					task.spawn(error, debug.traceback(err, 2))
				end, service)
			end
		end

		for _, service in servicesOrder do
			if service.OnStart then
				task.spawn(service.OnStart, service)
			end
		end

		self._replicatedRoot:SetAttribute("Replicated", true)

		self.status = Status.Initialized
		self._startedSignal:Fire()
	end)

	return self:OnStart()
end

function Services:OnStart()
	if self.status == Status.Initialized then
		return Promise.resolve()
	else
		return Promise.fromEvent(self._startedSignal)
	end
end

function Services.remoteEvent()
	return {
		type = "__remoteEvent",
	}
end

function Services.remoteProperty(default)
	return {
		type = "__remoteProperty",
		default = default,
	}
end

return Services
