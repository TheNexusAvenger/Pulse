--Main module for Pulse.
--!strict

local RunService = game:GetService("RunService")

local DebugTextView = require(script:WaitForChild("Client"):WaitForChild("DebugTextView"))
local DebugClientState = require(script:WaitForChild("Client"))
local DebugTextEntry = require(script:WaitForChild("Common"):WaitForChild("DebugTextEntry"))

local Pulse = {
    DebugClientState = nil :: DebugClientState.DebugClientState?,
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
function Pulse.AddEntry(self: Pulse, SortOrder: number, Name: string): DebugTextEntry.DebugTextEntry
    local Entry = DebugTextEntry.new(SortOrder, Name)
    if self.DebugClientState then
        self.DebugClientState:AddEntry(Entry)
    end
    return Entry
end



--Create the state.
if RunService:IsClient() then
    Pulse.DebugClientState = DebugClientState.new()
end



return Pulse