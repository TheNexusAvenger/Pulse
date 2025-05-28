--Provides integration with Nexus Admin.
--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")

local InstanceTracking = require(script.Parent.Parent:WaitForChild("Common"):WaitForChild("InstanceTracking"))

local NexusAdmin = {}
NexusAdmin.Pulse = nil :: any --Not required due to cyclic dependency.

export type NexusAdmin = typeof(NexusAdmin)



--[[
Returns the Nexus Admin API instance.
This will yield if Nexus Admin isn't loaded.
--]]
function NexusAdmin.GetNexusAdminApi(self: NexusAdmin): any
    --Return the client API.
    if RunService:IsClient() then
        return require(ReplicatedStorage:WaitForChild("NexusAdminClient", 10 ^ 99)) :: any
    end

    --Return the server API.
    local Api = require(ServerScriptService:WaitForChild("NexusAdmin", 10 ^ 99)) :: any
    while not Api:GetAdminLoaded() do task.wait() end
    return Api
end

--[[
Formats the summary to lines.
--]]
function NexusAdmin.FormatSummary(self: NexusAdmin, Summary: {[string]: InstanceTracking.InstanceTrackingSummaryEntry}): {string}
    --Sort the groups.
    local GroupNames = {}
    for GroupName, _ in Summary do
        table.insert(GroupNames, GroupName)
    end
    table.sort(GroupNames)

    --Build the lines.
    local Lines = {}
    for i, GroupName in GroupNames do
        --Add the header.
        table.insert(Lines, `{GroupName}:`)

        --Sort the totals.
        local GroupData = Summary[GroupName]
        local Tags = {
            {
                Name = "Total",
                CurrentInstances = GroupData.CurrentInstances,
                NotUnderGameInstances = GroupData.NotUnderGameInstances,
                NilParentInstances = GroupData.NilParentInstances,
                TotalInstances = GroupData.TotalInstances,
            },
        }
        for TagName, TagData in GroupData.Tags do
            table.insert(Tags, {
                Name = TagName,
                CurrentInstances = TagData.CurrentInstances,
                NotUnderGameInstances = TagData.NotUnderGameInstances,
                NilParentInstances = TagData.NilParentInstances,
                TotalInstances = TagData.TotalInstances,
            })
        end
        table.sort(Tags, function(a, b) return a.CurrentInstances > b.CurrentInstances end)

        --Add the lines.
        for _, TagData in Tags do
            local SummaryParts = {}
            if TagData.NotUnderGameInstances > 0 and TagData.NilParentInstances ~= TagData.NotUnderGameInstances then
                table.insert(SummaryParts, `{TagData.NotUnderGameInstances} not under game`)
            end
            if TagData.NilParentInstances > 0 then
                table.insert(SummaryParts, `{TagData.NilParentInstances} unparented`)
            end
            table.insert(SummaryParts, `{TagData.TotalInstances} total`)
            table.insert(Lines, `    {TagData.Name}: {TagData.CurrentInstances} ({table.concat(SummaryParts, ", ")})`)
        end

        --Add the separator.
        if (i ~= #GroupNames) then
            table.insert(Lines, "")
        end
    end

    --Return the lines.
    return Lines
end

--[[
Grants debug authorization for those with a Nexus Admin admin level.
If no admin level is provided, the default will be 0 (debug admin).
Must be called on the server.
--]]
function NexusAdmin.EnableAdminLevelAuthorization(self: NexusAdmin, AdminLevel: number?): NexusAdmin
    task.spawn(function()
        --Add the Nexus Admin authorization.
        local NexusAdminApi = self:GetNexusAdminApi()
        self.Pulse:EnableAuthorization(function(Player)
            return NexusAdminApi.Authorization:YieldForAdminLevel(Player) >= (AdminLevel or 0)
        end)
    end)

    return self
end

--[[
Registers commands in Nexus Admin, mainly for viewing instance tracking details.
Mest be called on the client and server.
If no command admin level is provided, the default will be 0 (debug admin).
--]]
function NexusAdmin.AddCommands(self: NexusAdmin, AdminLevel: number?): NexusAdmin
    task.spawn(function()
        --Add the client instances command.
        local NexusAdminApi = self:GetNexusAdminApi()
        NexusAdminApi.Registry:LoadCommand({
            Keyword = "clientinstances",
            Prefix = NexusAdminApi.Configuration.CommandPrefix,
            Category = "PulseCommands",
            Description = "Displays the summary of client instances.",
            AdminLevel = AdminLevel or 0,
            Run = function()
                if not RunService:IsClient() then return end

                local Window = NexusAdminApi.Window:CreateWindow("Client Instances")
                local TextList = Window:AddTextList()

                local function UpdateText()
                    TextList:SetLines(self:FormatSummary(self.Pulse.InstanceTracking:GetSummary("ALL")))
                end

                task.spawn(UpdateText)
                Window:EnableRefreshing(UpdateText)
                Window:EnableClosing()
                Window:EnableResizing()
                Window:Show()
            end,
        } :: any)

        --Add the server instances command.
        NexusAdminApi.Registry:LoadCommand({
            Keyword = "serverinstances",
            Prefix = NexusAdminApi.Configuration.CommandPrefix,
            Category = "PulseCommands",
            Description = "Displays the summary of server instances.",
            AdminLevel = AdminLevel or 0,
            Run = function()
                if not RunService:IsClient() then return end

                local GetInstanceTrackingSummaryFunction = script:WaitForChild("GetInstanceTrackingSummary")
                local Window = NexusAdminApi.Window:CreateWindow("Server Instances")
                local TextList = Window:AddTextList()

                local function UpdateText()
                    TextList:SetLines({"Loading..."})
                    TextList:SetLines(self:FormatSummary(GetInstanceTrackingSummaryFunction:InvokeServer()))
                end

                task.spawn(UpdateText)
                Window:EnableRefreshing(UpdateText)
                Window:EnableClosing()
                Window:EnableResizing()
                Window:Show()
            end,
        } :: any)

        --Set up fetching the server summary.
        if RunService:IsServer() then
            local GetInstanceTrackingSummaryFunction = Instance.new("RemoteFunction")
            GetInstanceTrackingSummaryFunction.Name = "GetInstanceTrackingSummary"
            GetInstanceTrackingSummaryFunction.Parent = script

            GetInstanceTrackingSummaryFunction.OnServerInvoke = function(Player)
                if not NexusAdminApi.Authorization:IsPlayerAuthorized(Player, AdminLevel or 0) then return {} end
                return self.Pulse.InstanceTracking:GetSummary("ALL")
            end
        end
    end)

    return self
end



return NexusAdmin