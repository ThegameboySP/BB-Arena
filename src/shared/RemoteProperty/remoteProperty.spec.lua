local RemoteProperty = require(script.Parent)

local function RETURN(...)
    return ...
end

local testMiddleware = {
    outbound = function(nextFn)
        return function(value)
            return nextFn(value .. "y")
        end
    end;
    inbound = function(nextFn)
        return function()
            return nextFn("test")
        end
    end;
}

return function()
    describe("delta middleware", function()
        local outbound
        local inbound
        beforeEach(function()
            outbound = RemoteProperty.deltaMiddleware.outbound(RETURN)
            inbound = RemoteProperty.deltaMiddleware.inbound(RETURN)
        end)

        it("should produce a delta table based off last table", function()
            local result1 = inbound(outbound({1}))
            local result2 = inbound(outbound({1, 2}))

            expect(#result1).to.equal(1)
            expect(#result2).to.equal(2)
        end)

        it("should return table if last value wasn't a table", function()
            local result1 = inbound(outbound("test"))
            local result2 = inbound(outbound({1, 2}))

            expect(result1).to.equal("test")
            expect(#result2).to.equal(2)
        end)

        it("should return nothing if there was no change", function()
            local result1 = inbound(outbound({1, 2}))
            local result2 = {outbound({1, 2})}

            expect(#result1).to.equal(2)
            expect(#result2).to.equal(0)
        end)
    end)

    describe("remote property", function()
        RemoteProperty.isTesting = true

        local property
        beforeEach(function()
            property = RemoteProperty.new(Instance.new("Folder"), "test")
        end)

        afterEach(function()
            property:Destroy()
            RemoteProperty.isServer = true
        end)

        it("should never accept unfrozen tables", function()
            expect(function()
                property:Set({})
            end).to.throw()
        end)

        it("server: should set and fire value, returning if identical to last", function()
            RemoteProperty.isServer = true

            property = RemoteProperty.new(Instance.new("Folder"), "test", {testMiddleware})

            local firedValues = {}
            property.Changed:Connect(function(value)
                table.insert(firedValues, value)
            end)

            property:Set("test")
            expect(property:Get()).to.equal("test")
            expect(#firedValues).to.equal(1)
            expect(firedValues[1]).to.equal("test")

            property:Set("test")
            expect(property:Get()).to.equal("test")
            expect(#firedValues).to.equal(1)

            property:Set("test2")
            expect(property:Get()).to.equal("test2")
            expect(#firedValues).to.equal(2)
            expect(firedValues[2]).to.equal("test2")
        end)

        it("client: should set and fire the middleware's resolved value, returning if identical to last", function()
            RemoteProperty.isServer = false

            property = RemoteProperty.new(Instance.new("Folder"), "test", {testMiddleware})

            local firedValues = {}
            property.Changed:Connect(function(value)
                table.insert(firedValues, value)
            end)

            property:_set(0)
            expect(property:Get()).to.equal("test")
            expect(#firedValues).to.equal(1)
            expect(firedValues[1]).to.equal("test")

            property:_set(1)
            expect(property:Get()).to.equal("test")
            expect(#firedValues).to.equal(1)
            expect(firedValues[1]).to.equal("test")
        end)
    end)
end