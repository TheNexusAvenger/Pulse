--Individual entry for a debug text.
--!strict

local DebugTextEntry = {}
DebugTextEntry.__index = DebugTextEntry

export type DebugTextEntry = {
    SortOrder: number,
    Name: string,
    Text: string,
    TextChanged: RBXScriptSignal,
    TextChangedEvent: BindableEvent,
} & typeof(setmetatable({}, DebugTextEntry))



--[[
Creates a debug text entry.
--]]
function DebugTextEntry.new(SortOrder: number, Name: string): DebugTextEntry
    local TextChangedEvent = Instance.new("BindableEvent")
    return setmetatable({
        SortOrder = SortOrder,
        Name = Name,
        Text = "",
        TextChanged = TextChangedEvent.Event :: RBXScriptSignal,
        TextChangedEvent = TextChangedEvent,
    }, DebugTextEntry) :: DebugTextEntry
end

--[[
Sets the text of the entry.
--]]
function DebugTextEntry.SetText(self: DebugTextEntry, Text: string): DebugTextEntry
    self.Text = Text
    self.TextChangedEvent:Fire()
    return self
end

--[[
Destroys the debug text entry.
Note: This is only intended for tests. It will not remove text from the debug view.
--]]
function DebugTextEntry.Destroy(self: DebugTextEntry): ()
    self.TextChangedEvent:Destroy()
end



return DebugTextEntry