--Client state for Pulse.
--!strict

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local DebugTextEntry = require(script.Parent:WaitForChild("Common"):WaitForChild("DebugTextEntry"))
local DebugTextView = require(script:WaitForChild("DebugTextView"))

local DebugClientState = {}
DebugClientState.__index = DebugClientState

export type DebugClientState = {
    DebugTextView: DebugTextView.DebugTextView?,
    ServerDebugTextEntries: {[string]: DebugTextEntry.DebugTextEntry},
    QueuedDebugTextEntries: {DebugTextEntry.DebugTextEntry},
    GetDebugTextEntriesFunction: RemoteFunction?,
} & typeof(setmetatable({}, DebugClientState))



--[[
Creates a debug client state.
--]]
function DebugClientState.new(): DebugClientState
    --Create the object.
    local self = setmetatable({
        ServerDebugTextEntries = {},
        QueuedDebugTextEntries = {},
    }, DebugClientState) :: DebugClientState

    --Connect server message replication.
    if RunService:IsRunning() then
        task.spawn(function()
            --Connect messages changing.
            (script.Parent:WaitForChild("DebugTextEntryUpdated", 10 ^ 99) :: RemoteEvent).OnClientEvent:Connect(function(EntryData: DebugTextEntry.SerializedDebugTextEntry)
                self:UpdateServerEntry(EntryData)
            end)

            --Get the initial messages.
            self.GetDebugTextEntriesFunction = script.Parent:WaitForChild("GetDebugTextEntries", 10 ^ 99) :: RemoteFunction
            Players.LocalPlayer:GetAttributeChangedSignal("PulseAuthorized"):Connect(function()
                self:FetchServerEntries()
            end)
            self:FetchServerEntries()
        end)
    end
    
    --Return the object.
    return self
end

--[[
Adds a debug text entry.
--]]
function DebugClientState.AddEntry(self: DebugClientState, Entry: DebugTextEntry.DebugTextEntry): ()
    if self.DebugTextView then
        self.DebugTextView:AddEntry(Entry)
    else
        table.insert(self.QueuedDebugTextEntries, Entry)
    end
end

--[[
Adds or updates an entry from the server.
--]]
function DebugClientState.UpdateServerEntry(self: DebugClientState, EntryData: DebugTextEntry.SerializedDebugTextEntry): ()
    --Create the entry.
    if not self.ServerDebugTextEntries[EntryData.Id] then
        local Entry = DebugTextEntry.new(EntryData.SortOrder, EntryData.Name)
        if EntryData.AuthorizationRequired then
            Entry:RequireAuthorization()
        end
        self:AddEntry(Entry)
        self.ServerDebugTextEntries[EntryData.Id] = Entry
    end

    --Update the text.
    self.ServerDebugTextEntries[EntryData.Id]:SetText(EntryData.Text)
end

--[[
Fetches the debug text entries from the server.
--]]
function DebugClientState.FetchServerEntries(self: DebugClientState): ()
    if not self.GetDebugTextEntriesFunction then return end
    for _, EntryData in self.GetDebugTextEntriesFunction:InvokeServer() :: {DebugTextEntry.SerializedDebugTextEntry} do
        self:UpdateServerEntry(EntryData)
    end
end

--[[
Adds the debug text view.
--]]
function DebugClientState.AddTextView(self: DebugClientState, Parent: Instance?): DebugTextView.DebugTextView
    if self.DebugTextView then return self.DebugTextView end
    
    --Create the new view.
    local NewDebugTextView = DebugTextView.new(Parent)
    self.DebugTextView = NewDebugTextView

    --Add the queued debug text.
    for _, Entry in self.QueuedDebugTextEntries do
        NewDebugTextView:AddEntry(Entry)
    end
    self.QueuedDebugTextEntries = {}

    --Return the view.
    return NewDebugTextView
end

--[[
Destroys the debug client state.
--]]
function DebugClientState.Destroy(self: DebugClientState): ()
    --Clear the queued debug text entries.
    for _, Entry in self.QueuedDebugTextEntries do
        Entry:Destroy()
    end
    self.QueuedDebugTextEntries = {}

    --Clear the text view.
    if self.DebugTextView then
        self.DebugTextView:Destroy()
        self.DebugTextView = nil
    end
end



return DebugClientState