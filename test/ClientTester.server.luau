--Tests Pulse on the client.
--!strict

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Pulse = require(ReplicatedStorage:WaitForChild("Pulse"))

--Create the window.
Pulse:AddTextView()
    :BindToggleKey(Enum.KeyCode.F4)

--Add sample debug text.
local Entry = Pulse:AddEntry(1, "Client Session Time")
task.spawn(function()
    while true do
        Entry:SetText(tostring(math.floor(Workspace.DistributedGameTime)))
        task.wait(1)
    end
end)
