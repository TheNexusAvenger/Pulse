--Main module for Pulse.
--!strict

local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local DebugTextView = require(script:WaitForChild("Client"):WaitForChild("DebugTextView"))
local DebugClientState = require(script:WaitForChild("Client"))
local DebugTextEntry = require(script:WaitForChild("Common"):WaitForChild("DebugTextEntry"))
local InstanceTracking = require(script:WaitForChild("Common"):WaitForChild("InstanceTracking"))
local DebugServerState = require(script:WaitForChild("Server"))

local Pulse = {
    DebugClientState = nil :: DebugClientState.DebugClientState?,
    DebugServerState = nil :: DebugServerState.DebugServerState?,
    InstanceTracking = InstanceTracking.new(),
}
Pulse.__index = Pulse

export type Pulse = typeof(Pulse)



--[[
Adds the debug text view.
Must be called on the client.
--]]
function Pulse.AddTextView(self: Pulse): DebugTextView.DebugTextView
    --Throw an error if it was not called on the client.
    if not self.DebugClientState then
        error("Pulse::AddTextView must be called on the client.")
    end

    --Return the window.
    return self.DebugClientState:AddTextView()
end

--[[
Adds a debug text entry.
--]]
function Pulse.AddEntry(self: Pulse, SortOrder: number, Name: string?): DebugTextEntry.DebugTextEntry
    local Entry = DebugTextEntry.new(SortOrder, Name)
    if self.DebugClientState then
        self.DebugClientState:AddEntry(Entry)
    end
    if self.DebugServerState then
        self.DebugServerState:AddEntry(Entry)
    end
    return Entry
end

--[[
Enables debug text authorization.
Must be called on the server.
--]]
function Pulse.EnableAuthorization(self: Pulse, IsAuthorized: (Player) -> (boolean)): ()
    --Throw an error if it was not called on the server.
    if not self.DebugServerState then
        error("Pulse::EnableAuthorization must be called on the server.")
    end

    --Enable authorization.
    self.DebugServerState:EnableAuthorization(IsAuthorized)
end

--[[
Adds a debug text entry for instance tracking.
Calling EnableAuthorization on the server will be required.
--]]
function Pulse.AddInstanceTracking(self: Pulse, SortOrder: number): ()
    --Add the text.
    local Name = (RunService:IsClient() and "Client instances" or "Server instances")
    local Entry = self:AddEntry(SortOrder, Name):RequireAuthorization()
    self.InstanceTracking:BindDebugTextEntry(Entry)

    --Add the request for the server.
    if not self.DebugServerState then return end
    if not script:FindFirstChild("RequestGarbageCollection") then
        local NewRequestGarbageCollectionEvent = Instance.new("RemoteEvent")
        NewRequestGarbageCollectionEvent.Name = "RequestGarbageCollection"
        NewRequestGarbageCollectionEvent.Parent = script
    end

    (script:WaitForChild("RequestGarbageCollection") :: RemoteEvent).OnServerEvent:Connect(function(Player)
        if not Entry:IsAuthorized(Player) then return end
        self.InstanceTracking:AttemptGarbageCollection()
    end)
end

--[[
Binds keys for requesting garbage collection on the client and server.
Calling EnableAuthorization on the server will be required.
Must be called on the client.
--]]
function Pulse.AddGarbageCollectionKeybinds(self: Pulse, ClientKey: Enum.KeyCode?, ServerKey: Enum.KeyCode?): ()
    --Throw an error if it was not called on the client.
    if not self.DebugClientState then
        error("Pulse::AddGarbageCollectionKeybinds must be called on the client.")
    end

    --Bind the key for client garbage collection requests.
    if ClientKey then
        UserInputService.InputBegan:Connect(function(Input, Processed)
            if Processed then return end
            if Input.KeyCode ~= ClientKey then return end
            self.InstanceTracking:AttemptGarbageCollection()
        end)
    end

    --Bind the key for server garbage collection requests.
    if ServerKey then
        task.spawn(function()
            local RequestGarbageCollectionEvent = script:WaitForChild("RequestGarbageCollection", 10 ^ 99) :: RemoteEvent
            UserInputService.InputBegan:Connect(function(Input, Processed)
                if Processed then return end
                if Input.KeyCode ~= ServerKey then return end
                RequestGarbageCollectionEvent:FireServer()
            end)
        end)
    end
end



--Create the state.
if RunService:IsClient() then
    Pulse.DebugClientState = DebugClientState.new()
end
if RunService:IsServer() then
    Pulse.DebugServerState = DebugServerState.new()
end



return Pulse