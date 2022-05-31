local RemoteProperty = require(script.Parent)

local function RETURN(...)
    return ...
end

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

        it("should return nil if there was no change", function()
            local result1 = inbound(outbound({1, 2}))
            local result2 = inbound(outbound({1, 2}))

            expect(#result1).to.equal(2)
            expect(result2).to.equal(nil)
        end)
    end)
end