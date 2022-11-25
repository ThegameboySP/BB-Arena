local Services = require(script.Parent.Services)

local function new(folder)
    folder = folder or Instance.new("Folder")
    local services = Services.new(folder)
    services.isServer = true

    return services, folder
end

return function()
    it("should run OnInit on the same coroutine and OnStart on its own", function()
        local services = new()

        services:RegisterServices({
            TestService = {
                OnInit = function()
                    task.wait()
                end;

                OnStart = function()
                    coroutine.yield()
                end;
            }
        })

        local promise = services:Start()

        expect(promise:getStatus()).to.equal("Started")

        local timeout = promise:timeout(1)
        timeout:await()
        expect(timeout:getStatus()).to.equal("Resolved")
    end)

    it("should create remote events and remote properties where marked", function()
        local services, folder = new()

        services:RegisterService("TestService", {
            Client = {
                RemoteEventTest = Services.remoteEvent();
                RemotePropertyTest = Services.remoteProperty();
            };
        })

        services:Start():await()

        local client = new(folder)
        client.isServer = false
        client:Start():await()

        local service = client:GetServerService("TestService")
        expect(service).to.be.ok()
        expect(service.RemoteEventTest).to.be.ok()
        expect(service.RemotePropertyTest).to.be.ok()
    end)

    it("should wait on the client until the server is fully replicated", function()
        local serverRoot, folder = new()
        serverRoot.isServer = true

        serverRoot:RegisterService("TestService", {
            OnInit = function()
                task.wait(1)
            end;
        })

        serverRoot:Start()

        local clientRoot = new(folder)
        clientRoot.isServer = false
        local promise = clientRoot:Start()

        local timeout = promise:timeout(2)
        timeout:await()
        expect(timeout:getStatus()).to.equal("Resolved")
    end)
end