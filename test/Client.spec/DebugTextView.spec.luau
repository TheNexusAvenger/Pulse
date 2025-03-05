--Tests DebugTextView.
--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DebugTextView = require(ReplicatedStorage.Pulse.Client.DebugTextView)
local DebugTextEntry = require(ReplicatedStorage.Pulse.Common.DebugTextEntry)

return function()
    describe("A DebugTextView", function()
        local TestDebugTextView = nil
        beforeEach(function()
            TestDebugTextView = DebugTextView.new(Instance.new("Folder"))
        end)

        afterEach(function()
            TestDebugTextView:Destroy()
        end)

        it("should add text entries.", function()
            expect(TestDebugTextView.DebugTextLabel.Text).to.equal("")

            TestDebugTextView:AddEntry(DebugTextEntry.new(5, "TestName1"):SetText("TestValue1"))
            expect(TestDebugTextView.DebugTextLabel.Text).to.equal("TestName1: TestValue1")
            TestDebugTextView:AddEntry(DebugTextEntry.new(4, "TestName2"):SetText("TestValue2"))
            expect(TestDebugTextView.DebugTextLabel.Text).to.equal("TestName2: TestValue2\nTestName1: TestValue1")
            TestDebugTextView:AddEntry(DebugTextEntry.new(6):SetText("TestValue3"))
            expect(TestDebugTextView.DebugTextLabel.Text).to.equal("TestName2: TestValue2\nTestName1: TestValue1\nTestValue3")
        end)

        it("should update text entries.", function()
            expect(TestDebugTextView.DebugTextLabel.Text).to.equal("")

            local Entry = DebugTextEntry.new(5, "TestName"):SetText("TestValue1")
            TestDebugTextView:AddEntry(Entry)
            expect(TestDebugTextView.DebugTextLabel.Text).to.equal("TestName: TestValue1")
            Entry:SetText("TestValue2")
            task.wait()
            expect(TestDebugTextView.DebugTextLabel.Text).to.equal("TestName: TestValue2")
        end)
    end)
end