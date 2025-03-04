--Tests DebugServerState.
--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DebugServerState = require(ReplicatedStorage.Pulse.Server)

return function()
    describe("A DebugServerState", function()
        local MockPlayer = nil
        local TestDebugServerState = nil
        beforeEach(function()
            MockPlayer = Instance.new("Folder") :: any
            TestDebugServerState = DebugServerState.new()
        end)

        afterEach(function()
            TestDebugServerState:Destroy()
        end)

        it("should authorize players.", function()
            TestDebugServerState.IsAuthorizedFunction = function()
                return true
            end

            TestDebugServerState:AttemptAuthorization(MockPlayer)
            expect(MockPlayer:GetAttribute("PulseAuthorized")).to.equal(true)
        end)

        it("should not authorize players.", function()
            TestDebugServerState.IsAuthorizedFunction = function()
                return false
            end

            TestDebugServerState:AttemptAuthorization(MockPlayer)
            expect(MockPlayer:GetAttribute("PulseAuthorized")).to.equal(false)
        end)

        it("should not authorize players with an error.", function()
            TestDebugServerState.IsAuthorizedFunction = function()
                error("Test error")
            end

            TestDebugServerState:AttemptAuthorization(MockPlayer)
            expect(MockPlayer:GetAttribute("PulseAuthorized")).to.equal(false)
        end)
    end)
end