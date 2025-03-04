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

        it("should change not text when unchanged.", function()
            TestDebugTextEntry:SetText("TestText")

            local TextChangedFired = false
            TestDebugTextEntry.TextChanged:Connect(function()
                TextChangedFired = true
            end)

            TestDebugTextEntry:SetText("TestText")
            expect(TestDebugTextEntry.Text).to.equal("TestText")
            task.wait()
            expect(TextChangedFired).to.equal(false)
        end)

        it("should not require authorization.", function()
            expect(TestDebugTextEntry:IsAuthorized(nil :: any)).to.equal(true)
        end)

        it("should require authorization.", function()
            local MockPlayer = Instance.new("Folder") :: any
            TestDebugTextEntry:RequireAuthorization()
            expect(TestDebugTextEntry:IsAuthorized(MockPlayer)).to.equal(false)
            MockPlayer:SetAttribute("PulseAuthorized", false)
            expect(TestDebugTextEntry:IsAuthorized(MockPlayer)).to.equal(false)
            MockPlayer:SetAttribute("PulseAuthorized", true)
            expect(TestDebugTextEntry:IsAuthorized(MockPlayer)).to.equal(true)
        end)

        it("should serialize text entries.", function()
            TestDebugTextEntry.Id = "TestId"
            TestDebugTextEntry:SetText("TestText")
            TestDebugTextEntry:RequireAuthorization()
            
            local Data = TestDebugTextEntry:Serialize()
            expect(Data.Id).to.equal("TestId")
            expect(Data.SortOrder).to.equal(5)
            expect(Data.Name).to.equal("TestName")
            expect(Data.Text).to.equal("TestText")
            expect(Data.AuthorizationRequired).to.equal(true)
        end)
    end)
end