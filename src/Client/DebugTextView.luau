--Displays debug text on the client.
--!strict

local MAXIMUM_BACKGROUND_TRANSPARENCY = 0.5

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")

local DebugTextEntry = require(script.Parent.Parent:WaitForChild("Common"):WaitForChild("DebugTextEntry"))

local DebugTextView = {}
DebugTextView.__index = DebugTextView

export type DebugTextView = {
    DebugScreenGui: ScreenGui,
    DebugTextLabel: TextLabel,
    DebugTextEntries: {DebugTextEntry.DebugTextEntry},
    EventConnections: {RBXScriptConnection},
} & typeof(setmetatable({}, DebugTextView))



--[[
Creates a debug text view.
--]]
function DebugTextView.new(Parent: Instance?): DebugTextView
    --Create the text display.
    local DebugScreenGui = Instance.new("ScreenGui")
    DebugScreenGui.DisplayOrder = 1000
    DebugScreenGui.Name = "DebugText"
    DebugScreenGui.ResetOnSpawn = false
    DebugScreenGui.Enabled = false
    task.spawn(function()
        DebugScreenGui.Parent = Parent or Players.LocalPlayer:WaitForChild("PlayerGui")
    end)

    local DebugTextLabel = Instance.new("TextLabel")
    DebugTextLabel.AnchorPoint = Vector2.new(0, 1)
    DebugTextLabel.BackgroundTransparency = MAXIMUM_BACKGROUND_TRANSPARENCY * GuiService.PreferredTransparency
    DebugTextLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    DebugTextLabel.AutomaticSize = Enum.AutomaticSize.XY
    DebugTextLabel.Size = UDim2.new(0, 0, 0, 0)
    DebugTextLabel.Position = UDim2.new(0, 4, 1, -4)
    DebugTextLabel.Font = Enum.Font.SourceSans
    DebugTextLabel.Text = ""
    DebugTextLabel.TextSize = 18
    DebugTextLabel.RichText = true
    DebugTextLabel.TextWrapped = true
    DebugTextLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    DebugTextLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    DebugTextLabel.TextStrokeTransparency = 0
    DebugTextLabel.TextXAlignment = Enum.TextXAlignment.Left
    DebugTextLabel.TextYAlignment = Enum.TextYAlignment.Bottom
    DebugTextLabel.Parent = DebugScreenGui

    --Create and return the object.
    return setmetatable({
        DebugScreenGui = DebugScreenGui,
        DebugTextLabel = DebugTextLabel,
        DebugTextEntries = {},
        EventConnections = {
            GuiService:GetPropertyChangedSignal("PreferredTransparency"):Connect(function()
                DebugTextLabel.BackgroundTransparency = MAXIMUM_BACKGROUND_TRANSPARENCY * GuiService.PreferredTransparency
            end)
        },
    }, DebugTextView) :: DebugTextView
end

--[[
Updates the displayed text.
--]]
function DebugTextView.Update(self: DebugTextView): ()
    local TextLines = {}
    for _, Entry in self.DebugTextEntries do
        if not Entry:IsAuthorized(Players.LocalPlayer) then continue end
        if Entry.Name == "" then
            table.insert(TextLines, Entry.Text)
        else
            table.insert(TextLines, `<font color=\"rgb(220,220,220)\">{Entry.Name}:</font> {Entry.Text}`)
        end
    end
    self.DebugTextLabel.Text = table.concat(TextLines, "\n")
end

--[[
Adds a debug text entry.
--]]
function DebugTextView.AddEntry(self: DebugTextView, Entry: DebugTextEntry.DebugTextEntry): ()
    --Store the entry.
    table.insert(self.DebugTextEntries, Entry)
    table.sort(self.DebugTextEntries, function(a, b)
        return a.SortOrder < b.SortOrder
    end)

    --Update the text.
    self:Update()
    Entry.TextChanged:Connect(function()
        self:Update()
    end)
end

--[[
Binds a key to toggling the debug view.
This can be called multiple times with different inputs.
--]]
function DebugTextView.BindToggleKey(self: DebugTextView, Key: Enum.KeyCode): DebugTextView
    table.insert(self.EventConnections, UserInputService.InputBegan:Connect(function(Input, Processed)
        if Processed then return end
        if Input.KeyCode ~= Key then return end
        self.DebugScreenGui.Enabled = not self.DebugScreenGui.Enabled
    end))
    return self
end

--[[
Destroys the debug text view.
--]]
function DebugTextView.Destroy(self: DebugTextView): ()
    self.DebugScreenGui:Destroy()
    for _, Entry in self.DebugTextEntries do
        Entry:Destroy()
    end
    self.DebugTextEntries = {}
    for _, EventConnection in self.EventConnections do
        EventConnection:Disconnect()
    end
    self.EventConnections = {}
end



return DebugTextView