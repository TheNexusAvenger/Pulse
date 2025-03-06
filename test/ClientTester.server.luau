--Tests Pulse on the client.
--!strict

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Pulse = require(ReplicatedStorage:WaitForChild("Pulse"))

--Create the window.
Pulse:AddTextView()
    :BindToggleKey(Enum.KeyCode.F4)

--Add instance tracking text.
Pulse:AddInstanceTracking(10)
Pulse.InstanceTracking:AutoTrackPlayers()

--Add sample debug text.
local Entry = Pulse:AddEntry(1, "Client Session Time")
task.spawn(function()
    while true do
        Entry:SetText(tostring(math.floor(Workspace.DistributedGameTime)))
        task.wait(1)
    end
end)

--Add garbage collection.
Pulse:AddGarbageCollectionKeybinds(Enum.KeyCode.F6, Enum.KeyCode.F8)
Pulse:AddEntry(1000) --No name, no text.
Pulse:AddEntry(1001, "Force garbage collection"):SetText("Client - F6, Server - F8")

--Add Nexus Admin integration.
--This can be called without Nexus Admin loading.
local NexusAdminIntegration = require(ReplicatedStorage:WaitForChild("Pulse"):WaitForChild("Admin"):WaitForChild("NexusAdmin"))
NexusAdminIntegration:AddCommands(0)