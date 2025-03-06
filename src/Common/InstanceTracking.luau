--Tracks instances and to identify memory leaks.
--!strict

local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")

local DebugTextEntry = require(script.Parent:WaitForChild("DebugTextEntry"))

local InstanceTracking = {}
InstanceTracking.__index = InstanceTracking

export type InstanceTrackingEntry = {
    AutoTagName: boolean,
    TotalEntries: number,
    TagsTotals: {[string]: number},
    Instances: {[any]: {[string]: boolean}},
}
export type InstanceTrackingSummaryEntry = {
    CurrentInstances: number,
    NotUnderGameInstances: number,
    NilParentInstances: number,
    TotalInstances: number,
    Tags: {
        [string]: {
            CurrentInstances: number,
            NotUnderGameInstances: number,
            NilParentInstances: number,
            TotalInstances: number,
        }
    },
}
export type InstanceTracking = {
    Active: boolean,
    TextRefreshDelay: number,
    TrackedInstances: {[string]: InstanceTrackingEntry},
    EventConnections: {RBXScriptConnection},
    PlayerEventConnections: {[Player]: {RBXScriptConnection}},
} & typeof(setmetatable({}, InstanceTracking))



--[[
Creates an instance tracking state.
--]]
function InstanceTracking.new(): InstanceTracking
    return setmetatable({
        Active = true,
        TextRefreshDelay = 0.25,
        TrackedInstances = {},
        EventConnections = {},
        PlayerEventConnections = {},
    }, InstanceTracking) :: InstanceTracking
end

--[[
Returns the group for tracking instances.
--]]
function InstanceTracking.GetGroup(self: InstanceTracking, Group: string): InstanceTrackingEntry
    if not self.TrackedInstances[Group] then
        self.TrackedInstances[Group] = {
            AutoTagName = false,
            TotalEntries = 0,
            TagsTotals = {},
            Instances = setmetatable({}, {__mode="k"}) :: any,
        }
    end
    return self.TrackedInstances[Group]
end

--[[
Tracks an instance.
--]]
function InstanceTracking.Track(self: InstanceTracking, Group: string, Ins: any): ()
    --Return if the instance is already tracked.
    local TrackedInstanceGroup = self:GetGroup(Group)
    if TrackedInstanceGroup.Instances[Ins] then return end

    --Track the instance with the name tag.
    local Tags = {}
    TrackedInstanceGroup.TotalEntries += 1
    TrackedInstanceGroup.Instances[Ins] = Tags
    if TrackedInstanceGroup.AutoTagName and (typeof(Ins) == "Instance" or Ins.Name) then
        self:Tag(Group, Ins, `Name:{Ins.Name}`)
    end
end

--[[
Enables auto-tracking of instances with a collection service tag.
--]]
function InstanceTracking.AutoTrackByTag(self: InstanceTracking, Group: string, Tag: string): InstanceTracking
    table.insert(self.EventConnections, CollectionService:GetInstanceAddedSignal(Tag):Connect(function(Ins)
        self:Track(Group, Ins)
    end))
    for _, Ins in CollectionService:GetTagged(Tag) do
        self:Track(Group, Ins)
    end
    return self
end

--[[
Enables auto-tracking of instances with a class name.
--]]
function InstanceTracking.AutoTrackByClassName(self: InstanceTracking, Group: string, ClassName: string): InstanceTracking
    --Track existing instances.
    for _, Ins in game:GetDescendants() do
        if not Ins:IsA(ClassName) then continue end
        self:Track(Group, Ins)
    end

    --Store the filter for new instances.
    table.insert(self.EventConnections, game.DescendantAdded:Connect(function(Ins)
        if not Ins:IsA(ClassName) then return end
        self:Track(Group, Ins)
    end))
    return self
end

--[[
Enables auto-tracking of players and characters.
--]]
function InstanceTracking.AutoTrackPlayers(self: InstanceTracking): InstanceTracking
    local function HandlePlayer(Player: Player): ()
        --Track the player.
        self:Track("Players", Player)

        --Track characters.
        local PlayerEventConnections = {}
        self.PlayerEventConnections[Player] = PlayerEventConnections
        table.insert(PlayerEventConnections, Player.CharacterAdded:Connect(function(Character)
            self:Track("Characters", Character)
        end))
        if Player.Character then
            self:Track("Characters", Player.Character)
        end
    end
    
    --Track the players.
    for _, Player in Players:GetPlayers() do
        HandlePlayer(Player)
    end
    table.insert(self.EventConnections, Players.PlayerAdded:Connect(HandlePlayer))

    --Clear events for players leaving.
    table.insert(self.EventConnections, Players.PlayerRemoving:Connect(function(Player)
        if self.PlayerEventConnections[Player] then
            for _, EventConnection in self.PlayerEventConnections[Player] do
                EventConnection:Disconnect()
            end
        end
        self.PlayerEventConnections[Player] = nil
    end))
    return self
end

--[[
Tags and instance.
If the instance isn't already tracked, it will be tracked.
--]]
function InstanceTracking.Tag(self: InstanceTracking, Group: string, Ins: any, Tag: string): ()
    --Track the instance.
    self:Track(Group, Ins)

    --Tag the instance.
    local TrackedInstanceGroup = self.TrackedInstances[Group]
    if not TrackedInstanceGroup then return end
    local TrackedInstance = TrackedInstanceGroup.Instances[Ins]
    if not TrackedInstance or TrackedInstance[Tag] then return end
    TrackedInstance[Tag] = true
    TrackedInstanceGroup.TagsTotals[Tag] = (TrackedInstanceGroup.TagsTotals[Tag] or 0) + 1
end

--[[
Enables auto-tagging of instances with their name.
--]]
function InstanceTracking.AutoTagNames(self: InstanceTracking, Group: string): ()
    --Enable auto-tagging.
    local TrackedInstanceGroup = self:GetGroup(Group)
    if TrackedInstanceGroup.AutoTagName then return end
    TrackedInstanceGroup.AutoTagName = true

    --Tag existing instances.
    for Ins, _ in TrackedInstanceGroup.Instances do
        if typeof(Ins) ~= "Instance" and not Ins.Name then continue end
        self:Tag(Group, Ins, `Name:{Ins.Name}`)
    end
end

--[[
Returns a summary of the tracked instances.
--]]
function InstanceTracking.GetSummary(self: InstanceTracking, FormatMode: "ALL" | "NO_TAGS"): {[string]: InstanceTrackingSummaryEntry}
    local Summary = {}
    local AddTags = (FormatMode == "ALL")
    for GroupName, InstanceGroup in self.TrackedInstances do
        --Create the empty summary.
        local GroupSummary = {
            CurrentInstances = 0,
            NotUnderGameInstances = 0,
            NilParentInstances = 0,
            TotalInstances = InstanceGroup.TotalEntries,
            Tags = {},
        }
        if AddTags then
            for Tag, TagTotal in InstanceGroup.TagsTotals do
                GroupSummary.Tags[Tag] = {
                    CurrentInstances = 0,
                    NotUnderGameInstances = 0,
                    NilParentInstances = 0,
                    TotalInstances = TagTotal,
                }
            end
        end
        Summary[GroupName] = GroupSummary

        --Add the instances.
        for Ins, InsTags in InstanceGroup.Instances do
            --Add the total.
            local IsInstance = typeof(Ins) == "Instance"
            local NotUnderGame = IsInstance and not Ins:IsDescendantOf(game)
            local NilParent = IsInstance and (Ins.Parent == nil)
            GroupSummary.CurrentInstances += 1
            if NotUnderGame then
                GroupSummary.NotUnderGameInstances += 1
            end
            if NilParent then
                GroupSummary.NilParentInstances += 1
            end
            
            --Add the tags.
            if AddTags then
                for Tag, _ in InsTags do
                    local TagTotal = GroupSummary.Tags[Tag]
                    TagTotal.CurrentInstances += 1
                    if NotUnderGame then
                        TagTotal.NotUnderGameInstances += 1
                    end
                    if NilParent then
                        TagTotal.NilParentInstances += 1
                    end
                end
            end
        end
    end
    return Summary
end

--[[
Formats the summary of the instances.
--]]
function InstanceTracking.FormatSummary(self: InstanceTracking): string
    --Build the summary.
    local Summary = self:GetSummary("NO_TAGS")
    local InstanceSummaries = {}
    for GroupName, GroupSummary in Summary do
        --Build the string.
        local CurrentInstances, NotUnderGameInstances, NilParentInstances, TotalInstances = GroupSummary.CurrentInstances, GroupSummary.NotUnderGameInstances, GroupSummary.NilParentInstances, GroupSummary.TotalInstances
        local SummaryParts = {}
        if NotUnderGameInstances > 0 and NilParentInstances ~= NotUnderGameInstances then
            table.insert(SummaryParts, `{NotUnderGameInstances}<font color="rgb(255,150,0)">N</font>`)
        end
        if NilParentInstances > 0 then
            table.insert(SummaryParts, `{NilParentInstances}<font color="rgb(255,0,0)">U</font>`)
        end
        table.insert(SummaryParts, `{TotalInstances}T`)
        table.insert(InstanceSummaries, `{GroupName}: {CurrentInstances} ({table.concat(SummaryParts, ", ")})`)
    end

    --Sort and concat the entries.
    table.sort(InstanceSummaries)
    return table.concat(InstanceSummaries, ", ")
end

--[[
Binds a debug text entry to the instance tracking.
--]]
function InstanceTracking.BindDebugTextEntry(self: InstanceTracking, Entry: DebugTextEntry.DebugTextEntry): ()
    task.spawn(function()
        while self.Active do
            Entry:SetText(self:FormatSummary())
            task.wait(self.TextRefreshDelay)
        end
    end)
end

--[[
Attempts to force garbage collection.
--]]
function InstanceTracking.AttemptGarbageCollection(self: InstanceTracking): ()
    local Table = {}
    for _ = 1, 50000 do
        table.insert(Table, Instance.new("Part"))
    end
end

--[[
Destroys the instance tracking.
--]]
function InstanceTracking.Destroy(self: InstanceTracking): ()
    self.Active = false
    self.TrackedInstances = {}

    for _, EventConnection in self.EventConnections do
        EventConnection:Disconnect()
    end
    self.EventConnections = {}
    for _, PlayerEventConnections in self.PlayerEventConnections do
        for _, EventConnection in PlayerEventConnections do
            EventConnection:Disconnect()
        end
    end
    self.PlayerEventConnections = {}
end



return InstanceTracking