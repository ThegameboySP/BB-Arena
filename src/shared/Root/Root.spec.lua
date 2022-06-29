local Root = require(script.Parent)

return function()
    it("should run OnInit on the same coroutine and OnStart on its own", function()
        local root = Root.new(Instance.new("Folder"))
        
        root:RegisterServices({
            TestService = {
                OnInit = function()
                    task.wait()
                end;

                OnStart = function()
                    coroutine.yield()
                end;
            }
        })

        local promise = root:Start()

        expect(promise:getStatus()).to.equal("Started")

        local timeout = promise:timeout(1)
        timeout:await()
        expect(timeout:getStatus()).to.equal("Resolved")
    end)

    it("should create remote events and remote properties where marked", function()
        local folder = Instance.new("Folder")
        local root = Root.new(folder)

        root:RegisterService("TestService", {
            Client = {
                RemoteEventTest = Root.remoteEvent();
                RemotePropertyTest = Root.remoteProperty();
            };
        })

        root:Start():await()

        local client = Root.new(folder)
        client.isServer = false
        client:Start():await()

        local service = client:GetServerService("TestService")
        expect(service).to.be.ok()
        expect(service.RemoteEventTest).to.be.ok()
        expect(service.RemotePropertyTest).to.be.ok()
    end)

    it("should wait on the client until the server is fully replicated", function()
        local folder = Instance.new("Folder")
        local serverRoot = Root.new(folder)
        serverRoot.isServer = true

        serverRoot:RegisterService("TestService", {
            OnInit = function()
                task.wait(1)
            end;
        })

        serverRoot:Start()

        local clientRoot = Root.new(folder)
        clientRoot.isServer = false
        local promise = clientRoot:Start()

        local timeout = promise:timeout(2)
        timeout:await()
        expect(timeout:getStatus()).to.equal("Resolved")
    end)
end