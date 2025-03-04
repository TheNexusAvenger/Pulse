--Server state for Pulse.
--!strict

local Players = game:GetService("Players")

local DebugTextEntry = require(script.Parent:WaitForChild("Common"):WaitForChild("DebugTextEntry"))

local DebugServerState = {}
DebugServerState.__index = DebugServerState

export type DebugServerState = {
    NewDebugTextEntryUpdatedEvent: RemoteEvent,
    GetDebugTextEntriesFunction: RemoteFunction,
    DebugTextEntries: {DebugTextEntry.DebugTextEntry},
    EventConnections: {RBXScriptConnection},
    IsAuthorizedFunction: ((Player) -> (boolean))?,
} & typeof(setmetatable({}, DebugServerState))



--[[
Creates a debug server state.
--]]
function DebugServerState.new(): DebugServerState
    --Create the replication instances.
    if not script.Parent:FindFirstChild("DebugTextEntryUpdated") then
        local NewDebugTextEntryUpdatedEvent = Instance.new("RemoteEvent")
        NewDebugTextEntryUpdatedEvent.Name = "DebugTextEntryUpdated"
        NewDebugTextEntryUpdatedEvent.Parent = script.Parent
    end
    local DebugTextEntryUpdatedEvent = script.Parent:FindFirstChild("DebugTextEntryUpdated") :: RemoteEvent

    if not script.Parent:FindFirstChild("GetDebugTextEntries") then
        local NewGetDebugTextEntriesFunction = Instance.new("RemoteFunction")
        NewGetDebugTextEntriesFunction.Name = "GetDebugTextEntries"
        NewGetDebugTextEntriesFunction.Parent = script.Parent
    end
    local GetDebugTextEntriesFunction = script.Parent:FindFirstChild("GetDebugTextEntries") :: RemoteFunction

    --Create the object.
    local self = setmetatable({
        NewDebugTextEntryUpdatedEvent = DebugTextEntryUpdatedEvent,
        GetDebugTextEntriesFunction = GetDebugTextEntriesFunction,
        DebugTextEntries = {},
        EventConnections = {},
    }, DebugServerState) :: DebugServerState

    --Set up clients requesting existing text.
    GetDebugTextEntriesFunction.OnServerInvoke = function(Player)
        local Entries = {}
        for _, Entry in self.DebugTextEntries do
            if not Entry:IsAuthorized(Player) then continue end
            table.insert(Entries, Entry:Serialize())
        end
        return Entries
    end

    --Create and return the object.
    return self
end

--[[
Adds a debug text entry.
--]]
function DebugServerState.AddEntry(self: DebugServerState, Entry: DebugTextEntry.DebugTextEntry): ()
    --Store the entry.
    table.insert(self.DebugTextEntries, Entry)
    
    --Send out the entry.
    self:SendEntry(Entry)

    --Connect the text changing.
    table.insert(self.EventConnections, Entry.TextChanged:Connect(function()
        self:SendEntry(Entry)
    end))
end

--[[
Sends a debug text entry to all clients.
--]]
function DebugServerState.SendEntry(self: DebugServerState, Entry: DebugTextEntry.DebugTextEntry): ()
    local EntryData = Entry:Serialize()
    for _, Player in Players:GetPlayers() do
        if not Entry:IsAuthorized(Player) then continue end
        self.NewDebugTextEntryUpdatedEvent:FireClient(Player, EntryData)
    end
end

--[[
Attempts to authorize a player for debug text.
--]]
function DebugServerState.AttemptAuthorization(self: DebugServerState, Player: Player): ()
    if not self.IsAuthorizedFunction then return end
    xpcall(function()
        Player:SetAttribute("PulseAuthorized", self.IsAuthorizedFunction(Player))
    end, function(ErrorMessage)
        warn(`Failed to check debug authorization for {Player} because: {ErrorMessage}`)
        Player:SetAttribute("PulseAuthorized", false)
    end)
end

--[[
Enables debug text authorization.
--]]
function DebugServerState.EnableAuthorization(self: DebugServerState, IsAuthorized: (Player) -> (boolean)): ()
    --Store the IsAuthorized function.
    self.IsAuthorizedFunction = IsAuthorized

    --Set up player authorization.
    table.insert(self.EventConnections, Players.PlayerAdded:Connect(function(Player)
        self:AttemptAuthorization(Player)
    end))
    for _, Player in Players:GetPlayers() do
        task.spawn(function()
            self:AttemptAuthorization(Player)
        end)
    end
end

--[[
Destroys the debug server state.
--]]
function DebugServerState.Destroy(self: DebugServerState): ()
    self.NewDebugTextEntryUpdatedEvent:Destroy()
    self.GetDebugTextEntriesFunction:Destroy()
    for _, EventConnection in self.EventConnections do
        EventConnection:Disconnect()
    end
    self.EventConnections = {}
end



return DebugServerState