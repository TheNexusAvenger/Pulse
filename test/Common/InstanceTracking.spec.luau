--Tests InstanceTracking.
--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local DebugTextEntry = require(ReplicatedStorage.Pulse.Common.DebugTextEntry)
local InstanceTracking = require(ReplicatedStorage.Pulse.Common.InstanceTracking)

return function()
    describe("A InstanceTracking", function()
        local TestInstanceTracking = nil
        beforeEach(function()
            TestInstanceTracking = InstanceTracking.new()
        end)

        afterEach(function()
            TestInstanceTracking:Destroy()
        end)

        it("should track new instances.", function()
            local TestPart = Instance.new("Part")
            TestInstanceTracking:Track("Parts", TestPart)

            local Group = TestInstanceTracking.TrackedInstances["Parts"]
            expect(Group.AutoTagName).to.equal(false)
            expect(Group.TotalEntries).to.equal(1)
            expect(next(Group.TagsTotals) :: any).to.equal(nil)
            expect(next(Group.Instances[TestPart]) :: any).to.equal(nil)
        end)

        it("should not track duplicate instances.", function()
            local TestPart = Instance.new("Part")
            TestInstanceTracking:Track("Parts", TestPart)
            TestInstanceTracking:Track("Parts", TestPart)

            local Group = TestInstanceTracking.TrackedInstances["Parts"]
            expect(Group.AutoTagName).to.equal(false)
            expect(Group.TotalEntries).to.equal(1)
            expect(next(Group.TagsTotals) :: any).to.equal(nil)
            expect(next(Group.Instances[TestPart]) :: any).to.equal(nil)
        end)

        it("should track non-instances.", function()
            local TestData = {}
            TestInstanceTracking:Track("Data", TestData)

            local Group = TestInstanceTracking.TrackedInstances["Data"]
            expect(Group.AutoTagName).to.equal(false)
            expect(Group.TotalEntries).to.equal(1)
            expect(next(Group.TagsTotals) :: any).to.equal(nil)
            expect(next(Group.Instances[TestData]) :: any).to.equal(nil)
        end)

        it("should auto-track by tags.", function()
            local TestPart1 = Instance.new("Part")
            TestPart1:AddTag("TestTag")
            Debris:AddItem(TestPart1, 0.1)
            local TestPart2 = Instance.new("Part")
            TestPart2:AddTag("TestTag")
            Debris:AddItem(TestPart2, 0.1)
            
            TestPart1.Parent = ReplicatedStorage
            TestInstanceTracking:AutoTrackByTag("Parts", "TestTag")
            TestPart2.Parent = ReplicatedStorage
            task.wait()

            local Group = TestInstanceTracking.TrackedInstances["Parts"]
            expect(Group.AutoTagName).to.equal(false)
            expect(Group.TotalEntries).to.equal(2)
            expect(next(Group.TagsTotals) :: any).to.equal(nil)
            expect(next(Group.Instances[TestPart1]) :: any).to.equal(nil)
            expect(next(Group.Instances[TestPart2]) :: any).to.equal(nil)
        end)

        it("should auto-track by ClassName.", function()
            local TestHandles1 = Instance.new("Handles")
            Debris:AddItem(TestHandles1, 0.1)
            local TestHandles2 = Instance.new("Handles")
            Debris:AddItem(TestHandles2, 0.1)
            
            TestHandles1.Parent = ReplicatedStorage
            TestInstanceTracking:AutoTrackByClassName("Handles", "Handles")
            TestHandles2.Parent = ReplicatedStorage
            task.wait()

            local Group = TestInstanceTracking.TrackedInstances["Handles"]
            expect(Group.AutoTagName).to.equal(false)
            expect(Group.TotalEntries).to.equal(2)
            expect(next(Group.TagsTotals) :: any).to.equal(nil)
            expect(next(Group.Instances[TestHandles1]) :: any).to.equal(nil)
            expect(next(Group.Instances[TestHandles2]) :: any).to.equal(nil)
        end)

        it("should tag new instances.", function()
            local TestPart = Instance.new("Part")
            TestPart.Name = "TestPart"
            TestInstanceTracking:Tag("Parts", TestPart, "TestTag")

            local Group = TestInstanceTracking.TrackedInstances["Parts"]
            expect(Group.AutoTagName).to.equal(false)
            expect(Group.TotalEntries).to.equal(1)
            expect(Group.TagsTotals["TestTag"]).to.equal(1)
            expect(next(Group.Instances[TestPart]) :: any).to.equal("TestTag")
        end)

        it("should tag existing instances.", function()
            local TestPart = Instance.new("Part")
            TestPart.Name = "TestPart"
            TestInstanceTracking:Track("Parts", TestPart)
            TestInstanceTracking:Tag("Parts", TestPart, "TestTag")

            local Group = TestInstanceTracking.TrackedInstances["Parts"]
            expect(Group.AutoTagName).to.equal(false)
            expect(Group.TotalEntries).to.equal(1)
            expect(Group.TagsTotals["TestTag"]).to.equal(1)
            expect(next(Group.Instances[TestPart]) :: any).to.equal("TestTag")
        end)

        it("should tag existing instances with duplicate tags.", function()
            local TestPart = Instance.new("Part")
            TestPart.Name = "TestPart"
            TestInstanceTracking:Track("Parts", TestPart)
            TestInstanceTracking:Tag("Parts", TestPart, "TestTag")
            TestInstanceTracking:Tag("Parts", TestPart, "TestTag")

            local Group = TestInstanceTracking.TrackedInstances["Parts"]
            expect(Group.AutoTagName).to.equal(false)
            expect(Group.TotalEntries).to.equal(1)
            expect(Group.TagsTotals["TestTag"]).to.equal(1)
            expect(next(Group.Instances[TestPart]) :: any).to.equal("TestTag")
        end)

        it("should tag new instances with auto-tagged names.", function()
            TestInstanceTracking:AutoTagNames("Parts")
            local TestPart = Instance.new("Part")
            TestPart.Name = "TestPart"
            TestInstanceTracking:Track("Parts", TestPart)

            local Group = TestInstanceTracking.TrackedInstances["Parts"]
            expect(Group.AutoTagName).to.equal(true)
            expect(Group.TotalEntries).to.equal(1)
            expect(Group.TagsTotals["Name:TestPart"]).to.equal(1)
            expect(next(Group.Instances[TestPart]) :: any).to.equal("Name:TestPart")
        end)

        it("should tag existing instances with auto-tagged names.", function()
            local TestPart = Instance.new("Part")
            TestPart.Name = "TestPart"
            TestInstanceTracking:Track("Parts", TestPart)
            TestInstanceTracking:AutoTagNames("Parts")

            local Group = TestInstanceTracking.TrackedInstances["Parts"]
            expect(Group.AutoTagName).to.equal(true)
            expect(Group.TotalEntries).to.equal(1)
            expect(Group.TagsTotals["Name:TestPart"]).to.equal(1)
            expect(next(Group.Instances[TestPart]) :: any).to.equal("Name:TestPart")
        end)

        it("should tag new data with names with auto-tagged names.", function()
            TestInstanceTracking:AutoTagNames("Data")
            local TestData = {Name = "TestData"}
            TestInstanceTracking:Track("Data", TestData)

            local Group = TestInstanceTracking.TrackedInstances["Data"]
            expect(Group.AutoTagName).to.equal(true)
            expect(Group.TotalEntries).to.equal(1)
            expect(Group.TagsTotals["Name:TestData"]).to.equal(1)
            expect(next(Group.Instances[TestData]) :: any).to.equal("Name:TestData")
        end)

        it("should not tag new data with no name with auto-tagged names.", function()
            TestInstanceTracking:AutoTagNames("Data")
            local TestData = {}
            TestInstanceTracking:Track("Data", TestData)

            local Group = TestInstanceTracking.TrackedInstances["Data"]
            expect(Group.AutoTagName).to.equal(true)
            expect(Group.TotalEntries).to.equal(1)
            expect(next(Group.TagsTotals) :: any).to.equal(nil)
            expect(next(Group.Instances[TestData]) :: any).to.equal(nil)
        end)

        it("should create summaries without tags.", function()
            TestInstanceTracking:GetGroup("Parts").TotalEntries += 2

            local TestPart1 = Instance.new("Part")
            TestPart1.Parent = ReplicatedStorage
            Debris:AddItem(TestPart1, 0.1)
            local TestPart2 = Instance.new("Part")
            local TestPart3 = Instance.new("Part")
            TestPart3.Parent = TestPart2

            TestInstanceTracking:Tag("Parts", TestPart1, "TestTag")
            TestInstanceTracking:Tag("Parts", TestPart2, "TestTag")
            TestInstanceTracking:Tag("Parts", TestPart3, "TestTag")
            TestInstanceTracking:Tag("Parts", {}, "TestTag")
        
            local Summary = TestInstanceTracking:GetSummary("NO_TAGS")
            expect(Summary["Parts"].CurrentInstances).to.equal(4)
            expect(Summary["Parts"].NotUnderGameInstances).to.equal(2)
            expect(Summary["Parts"].NilParentInstances).to.equal(1)
            expect(Summary["Parts"].TotalInstances).to.equal(6)
            expect(Summary["Parts"].Tags["TestTag"]).to.equal(nil)
        end)

        it("should create summaries with tags.", function()
            TestInstanceTracking:GetGroup("Parts").TotalEntries += 2

            local TestPart1 = Instance.new("Part")
            TestPart1.Parent = ReplicatedStorage
            Debris:AddItem(TestPart1, 0.1)
            local TestPart2 = Instance.new("Part")
            local TestPart3 = Instance.new("Part")
            TestPart3.Parent = TestPart2

            TestInstanceTracking:Tag("Parts", TestPart1, "TestTag")
            TestInstanceTracking:Tag("Parts", TestPart2, "TestTag")
            TestInstanceTracking:Tag("Parts", TestPart3, "TestTag")
            TestInstanceTracking:Tag("Parts", {}, "TestTag")
        
            local Summary = TestInstanceTracking:GetSummary("ALL")
            expect(Summary["Parts"].CurrentInstances).to.equal(4)
            expect(Summary["Parts"].NotUnderGameInstances).to.equal(2)
            expect(Summary["Parts"].NilParentInstances).to.equal(1)
            expect(Summary["Parts"].TotalInstances).to.equal(6)
            expect(Summary["Parts"].Tags["TestTag"].CurrentInstances).to.equal(4)
            expect(Summary["Parts"].Tags["TestTag"].NotUnderGameInstances).to.equal(2)
            expect(Summary["Parts"].Tags["TestTag"].NilParentInstances).to.equal(1)
            expect(Summary["Parts"].Tags["TestTag"].TotalInstances).to.equal(4)
        end)

        it("should format a summary.", function()
            TestInstanceTracking:GetGroup("Parts").TotalEntries += 2

            local TestPart1 = Instance.new("Part")
            TestPart1.Parent = ReplicatedStorage
            Debris:AddItem(TestPart1, 0.1)
            local TestPart2 = Instance.new("Part")
            local TestPart3 = Instance.new("Part")
            TestPart3.Parent = TestPart2

            TestInstanceTracking:Track("Parts", TestPart1)
            TestInstanceTracking:Track("Parts", TestPart2)
            TestInstanceTracking:Track("Parts", TestPart3)
            TestInstanceTracking:Track("Parts", {})

            expect(TestInstanceTracking:FormatSummary()).to.equal("Parts: 4 (2<font color=\"rgb(200,150,0)\">N</font>, 1<font color=\"rgb(200,0,0)\">U</font>, 6T)")
        end)

        it("should format a summary with the same nil and unparented instances.", function()
            TestInstanceTracking:GetGroup("Parts").TotalEntries += 2

            local TestPart1 = Instance.new("Part")
            TestPart1.Parent = ReplicatedStorage
            Debris:AddItem(TestPart1, 0.1)
            local TestPart2 = Instance.new("Part")
            local TestPart3 = Instance.new("Part")

            TestInstanceTracking:Track("Parts", TestPart1)
            TestInstanceTracking:Track("Parts", TestPart2)
            TestInstanceTracking:Track("Parts", TestPart3)
            TestInstanceTracking:Track("Parts", {})

            expect(TestInstanceTracking:FormatSummary()).to.equal("Parts: 4 (2<font color=\"rgb(200,0,0)\">U</font>, 6T)")
        end)

        it("should bind with debug text.", function()
            local Entry = DebugTextEntry.new(5, "Test")
            TestInstanceTracking:GetGroup("Parts").TotalEntries += 2

            local TestPart1 = Instance.new("Part")
            TestPart1.Parent = ReplicatedStorage
            Debris:AddItem(TestPart1, 0.1)
            local TestPart2 = Instance.new("Part")
            local TestPart3 = Instance.new("Part")
            TestPart3.Parent = TestPart2

            TestInstanceTracking:Track("Parts", TestPart1)
            TestInstanceTracking:Track("Parts", TestPart2)
            TestInstanceTracking:Track("Parts", TestPart3)
            TestInstanceTracking:Track("Parts", {})
            TestInstanceTracking:BindDebugTextEntry(Entry)

            task.wait()
            expect(Entry.Text).to.equal("Parts: 4 (2<font color=\"rgb(200,150,0)\">N</font>, 1<font color=\"rgb(200,0,0)\">U</font>, 6T)")
        end)
    end)
end