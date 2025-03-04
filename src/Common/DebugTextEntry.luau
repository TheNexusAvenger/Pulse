--Individual entry for a debug text.
--!strict

local HttpService = game:GetService("HttpService")

local DebugTextEntry = {}
DebugTextEntry.__index = DebugTextEntry

export type SerializedDebugTextEntry = {
    Id: string,
    SortOrder: number,
    Name: string,
    Text: string,
    AuthorizationRequired: boolean,
}
export type DebugTextEntry = {
    Id: string,
    SortOrder: number,
    Name: string,
    Text: string,
    AuthorizationRequired: boolean,
    TextChanged: RBXScriptSignal,
    TextChangedEvent: BindableEvent,
} & typeof(setmetatable({}, DebugTextEntry))



--[[
Creates a debug text entry.
--]]
function DebugTextEntry.new(SortOrder: number, Name: string): DebugTextEntry
    local TextChangedEvent = Instance.new("BindableEvent")
    return setmetatable({
        Id = HttpService:GenerateGUID(false),
        SortOrder = SortOrder,
        Name = Name,
        Text = "",
        AuthorizationRequired = false,
        TextChanged = TextChangedEvent.Event :: RBXScriptSignal,
        TextChangedEvent = TextChangedEvent,
    }, DebugTextEntry) :: DebugTextEntry
end

--[[
Sets the text of the entry.
--]]
function DebugTextEntry.SetText(self: DebugTextEntry, Text: string): DebugTextEntry
    if self.Text ~= Text then
        self.Text = Text
        self.TextChangedEvent:Fire()
    end
    return self
end

--[[
Makes the text require authorization to be displayed.
--]]
function DebugTextEntry.RequireAuthorization(self: DebugTextEntry): DebugTextEntry
    self.AuthorizationRequired = true
    return self
end

--[[
Returns if a player is authorized to see the message.
--]]
function DebugTextEntry.IsAuthorized(self: DebugTextEntry, Player: Player): boolean
    return not self.AuthorizationRequired or Player:GetAttribute("PulseAuthorized") == true
end

--[[
Serializes the debug text.
--]]
function DebugTextEntry.Serialize(self: DebugTextEntry): SerializedDebugTextEntry
    return {
        Id = self.Id,
        SortOrder = self.SortOrder,
        Name = self.Name,
        Text = self.Text,
        AuthorizationRequired = self.AuthorizationRequired,
    }
end

--[[
Destroys the debug text entry.
Note: This is only intended for tests. It will not remove text from the debug view.
--]]
function DebugTextEntry.Destroy(self: DebugTextEntry): ()
    self.TextChangedEvent:Destroy()
end



return DebugTextEntry