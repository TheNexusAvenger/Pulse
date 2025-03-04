--Tests Pulse on the server.
--!strict

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Pulse = require(ReplicatedStorage:WaitForChild("Pulse"))

--Add authorization.
Pulse:EnableAuthorization(function(Player)
    return game.JobId == "" or Player.UserId == game.CreatorId
end)

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