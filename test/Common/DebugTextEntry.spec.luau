--Tests DebugTextEntry.
--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DebugTextEntry = require(ReplicatedStorage.Pulse.Common.DebugTextEntry)

return function()
    describe("A DebugTextEntry", function()
        local TestDebugTextEntry = nil
        beforeEach(function()
            TestDebugTextEntry = DebugTextEntry.new(5, "TestName")
        end)
        
        afterEach(function()
            TestDebugTextEntry:Destroy()
        end)

        it("should be set up correct.", function()
            expect(TestDebugTextEntry.SortOrder).to.equal(5)
            expect(TestDebugTextEntry.Name).to.equal("TestName")
            expect(TestDebugTextEntry.Text).to.equal("")
        end)

        it("should change text.", function()
            local TextChangedFired = false
            TestDebugTextEntry.TextChanged:Connect(function()
                TextChangedFired = true
            end)

            TestDebugTextEntry:SetText("TestText")
            expect(TestDebugTextEntry.Text).to.equal("TestText")
            task.wait()
            expect(TextChangedFired).to.equal(true)
        end)
    end)
end