--Tests Pulse on the server.
--!strict

local TEST_MODE = "STANDALONE" :: "STANDALONE" | "NEXUS_ADMIN"

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Pulse = require(ReplicatedStorage:WaitForChild("Pulse"))

--Add instance tracking text.
Pulse:AddInstanceTracking(11)
Pulse.InstanceTracking:AutoTrackPlayers()
Pulse.InstanceTracking:AutoTrackByTag("TestTag1", "TestTag1")
Pulse.InstanceTracking:AutoTrackByTag("TestTag2", "TestTag2")

--Add sample debug text.
local TimeEntry = Pulse:AddEntry(2, "Server Session Time")
task.spawn(function()
    while true do
        TimeEntry:SetText(tostring(math.floor(Workspace.DistributedGameTime)))
        task.wait(1)
    end
end)

local TotalPlayers = #Players:GetPlayers()
local PlayersEntry = Pulse:AddEntry(3, "Player Joins"):RequireAuthorization():SetText(tostring(TotalPlayers))
Players.PlayerAdded:Connect(function()
    TotalPlayers += 1
    PlayersEntry:SetText(tostring(TotalPlayers))
end)

--Add authorization.
print(`Testing debug text with {TEST_MODE} authorization.`)
if TEST_MODE == "NEXUS_ADMIN" then
    --Load Nexus Admin with the default configuration.
    (require(386507112) :: any)(script, {})

    --Add Nexus Admin integration.
    local NexusAdminIntegration = require(ReplicatedStorage:WaitForChild("Pulse"):WaitForChild("Admin"):WaitForChild("NexusAdmin"))
    NexusAdminIntegration:EnableAdminLevelAuthorization(0)
        :AddCommands(0)
elseif TEST_MODE == "STANDALONE" then
    --Add simple authorization.
    Pulse:EnableAuthorization(function(Player)
        return game.JobId == "" or Player.UserId == game.CreatorId
    end)
end

--Add and clear instances to simulate a memory leak.
local StoredInstances = {}
while true do
    local Folder = Instance.new("Folder")
    Folder:AddTag("TestTag1")
    Folder.Parent = ReplicatedStorage
    if math.random() > 0.5 then
        Pulse.InstanceTracking:Tag("TestTag1", Folder, "KeptInstance")
        Folder:AddTag("TestTag2")
        table.insert(StoredInstances, Folder)
    end
    task.wait(0.5)

    if math.random() > 0.5 then
        Folder.Parent = Instance.new("Folder")
    else
        Folder:Destroy()
    end
    task.wait(0.5)
end