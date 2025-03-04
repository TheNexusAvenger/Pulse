--Client state for the debug text.
--!strict

local DebugTextEntry = require(script.Parent:WaitForChild("Common"):WaitForChild("DebugTextEntry"))
local DebugTextView = require(script:WaitForChild("DebugTextView"))

local DebugClientState = {}
DebugClientState.__index = DebugClientState

export type DebugClientState = {
    DebugTextView: DebugTextView.DebugTextView?,
    QueuedDebugTextEntries: {DebugTextEntry.DebugTextEntry},
} & typeof(setmetatable({}, DebugClientState))



--[[
Creates a debug client state.
--]]
function DebugClientState.new(): DebugClientState
    return setmetatable({
        QueuedDebugTextEntries = {},
    }, DebugClientState) :: DebugClientState
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