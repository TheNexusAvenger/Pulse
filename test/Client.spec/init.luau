--Tests DebugClientState.
--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DebugClientState = require(ReplicatedStorage.Pulse.Client)
local DebugTextEntry = require(ReplicatedStorage.Pulse.Common.DebugTextEntry)

return function()
    describe("A DebugClientState", function()
        local TestDebugClientState = nil
        beforeEach(function()
            TestDebugClientState = DebugClientState.new()
        end)

        afterEach(function()
            TestDebugClientState:Destroy()
        end)

        it("should add text entries.", function()
            local View = TestDebugClientState:AddTextView()
            TestDebugClientState:AddEntry(DebugTextEntry.new(5, "TestName"):SetText("TestValue"))
            expect(View.DebugTextLabel.Text).to.equal("<font color=\"rgb(220,220,220)\">TestName:</font> TestValue")
        end)

        it("should queue text entries.", function()
            TestDebugClientState:AddEntry(DebugTextEntry.new(5, "TestName"):SetText("TestValue"))
            local View = TestDebugClientState:AddTextView()
            expect(View.DebugTextLabel.Text).to.equal("<font color=\"rgb(220,220,220)\">TestName:</font> TestValue")
        end)
    end)
end