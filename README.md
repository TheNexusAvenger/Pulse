# Pulse
*For checking the pulse of your game.*

Pulse is a library for easily presenting simple debug information, along
with information about stored instances to identify potential memory leaks.

## Debug Text Setup
### Debug View (Client-only)
In order to enable the debug text view, a call to `Pulse::AddTextView` and
at least 1 call to `Pulse::BindToggleKey` are required. Multiple keys can
be bound to toggling the view. `F4` is the current recommended default.

```luau
local Pulse = require(game:GetService("ReplicatedStorage"):WaitForChild("Pulse"))

Pulse:AddTextView()
Pulse:BindToggleKey(Enum.KeyCode.F4)
```

These can be chained together in a single call if desired.
```luau
local Pulse = require(game:GetService("ReplicatedStorage"):WaitForChild("Pulse"))

Pulse:AddTextView():BindToggleKey(Enum.KeyCode.F4)
```

### Authorization (Server)
Access to sensitive debug text on the server can be controlled with
`Pulse::EnableAuthorization`. **This is required for instance tracking**, but
optional otherwise.

```luau
local Pulse = require(game:GetService("ReplicatedStorage"):WaitForChild("Pulse"))

Pulse:EnableAuthorization(function(Player: Player): boolean
    --Returns true if the player is authorized for sensitive debug text, or false if not.
    --Consider hooking up to an admin system's authorization system.
    return game.JobId == "" or Player.UserId == game.CreatorId
end)
```

### Debug Text (Client or Server)
Debug text can be added to the view on both the client and server. It can
be added before or after the debug view is loaded.

Initially, 2 parameters can be specified:
- `SortOrder` *(Required)*: Order of the debug text to appear, sorted from
  lowest at the top of the list to highest at the bottom of the list. Any
  number values can be used, including negative.
- `Name`: Name of the debug text. If not provided, no name will be displayed.

Two additional methods can be called on the returned text:
- `DebugTextEntry::SetText`: Sets the text to display (if not called, an
  empty string is used).
- `DebugTextEntry::RequireAuthorization`: Makes the text only display if
  the player is authorized. (Requires `Pulse::EnableAuthorization` to
  be set up.)

```luau
local Pulse = require(game:GetService("ReplicatedStorage"):WaitForChild("Pulse"))

--Displays "TestName: TestValue" with the sort order 5.
local Entry = Pulse:AddEntry(5, "TestName")
Entry:SetText("TestValue")

--Displays "TestName: TestValue" with the sort order 5 only if the player is authorized.
local Entry = Pulse:AddEntry(5, "TestName")
Entry:SetText("TestValue")
Entry:EnableAuthorization()

--Previous example, but at one line.
local Entry = Pulse:AddEntry(5, "TestName"):SetText("TestValue"):EnableAuthorization()

--Displays "TestValue" with a sort order 5.
local Entry = Pulse:AddEntry(5) --Name not provided.
Entry:SetText("TestValue")

--Creates just a newline with a sort order 5.
Pulse:AddEntry(5) --Name not provided. SetText not called.
```

### Instance Tracking Debug Text (Client and Server)
Debug text for instance tracking can be added with `Pulse::AddInstanceTracking`.
It must be called on the client *and* server if used, and requires
`Pulse::EnableAuthorization` to be set up to restrict access.
`Pulse::AddInstanceTracking` takes in a sort order.

```luau
local Pulse = require(game:GetService("ReplicatedStorage"):WaitForChild("Pulse"))

Pulse:AddInstanceTracking(5) --Recommended to use a different sort order on the client and server.
```

Client instances will have the name `Client instances` and server instances will
have the name `Server instances`. Each group stored in instance tracking will be
presented with the following format: `Group: 1 ([2N, ][3U, ]4T))`, where:
- `Group` is the name of the tracked group.
- `1` is the number of tracked instances in memory.
- `2N` is the number of tracked instances no under `game` but with a parent.
  *Only presented when 2N and 3U aren't the same and 2N is more than 0.*
- `3U` is the number of tracked instances with no parent.
  *Only presented when 3U is more than 0.*
- `4T` is the number of instances in the group that have existed, including ones
  that have been garbage collected (cleared from memory).

`Pulse::AddGarbageCollectionKeybinds` can be added on the client to allow
authorized users to request garbage collection on the client and server. If either
`KeyCode` is not provided, it is not set. `F6` and `F8` are currently recommended.

```luau
local Pulse = require(game:GetService("ReplicatedStorage"):WaitForChild("Pulse"))

Pulse:AddGarbageCollectionKeybinds(Enum.KeyCode.F6, Enum.KeyCode.F8) --Client and server garbage collection requests.
Pulse:AddGarbageCollectionKeybinds(Enum.KeyCode.F6) --Client-only garbage collection requests.
Pulse:AddGarbageCollectionKeybinds(nil, Enum.KeyCode.F8) --Server-only and server garbage collection requests.

Pulse:AddEntry(6, "Force garbage collection"):SetText("Client - F6, Server - F8"):RequireAuthorization() --Optional: helper text for keybinds.
```

## Instance Tracking
Instance tracking is a sub-module for tracking instances (and non-instances)
for potential memory leaks. It is available on both the client and server.
Adding debug text for instance tracking is covered in the previous section.

### Tracking Instances
Any instance and non-instance can be tracked manually with an assigned group.
An instance can be assigned to multiple groups.

```luau
local Pulse = require(game:GetService("ReplicatedStorage"):WaitForChild("Pulse"))

Pulse.InstanceTracking:Track("Parts", Instance.new("Part")) --Tracks a part with the "Parts" group.
Pulse.InstanceTracking:Track("States", {}) --Tracks a table.
```

### Auto-Tracking Instances
Instances can be automatically tracked with the following helper methods.

```luau
local Pulse = require(game:GetService("ReplicatedStorage"):WaitForChild("Pulse"))

--Automatically tracks instances tagged with "Car".
Pulse.InstanceTracking:AutoTrackByTag("Cars", "Car")

--Automatically tracks instances that are a BackpackItem (including Tools).
--NOTE: This uses game.DescendantAdded. If AutoTrackByTag can be easily used, use that instead.
Pulse.InstanceTracking:AutoTrackByClassName("Tools", "BackpackItem")

--Automatically tracks players and characters.
Pulse.InstanceTracking:AutoTrackPlayers()
```

### Tagging Instances
Along with tracking instances, instances can be tagged to provide additional
feedback with analysis tools.

Note: if an instance is tagged, it will automatically be tracked as well.

```luau
local Pulse = require(game:GetService("ReplicatedStorage"):WaitForChild("Pulse"))

--Tags that a part in the Parts group has been Touched.
Pulse.Instancetracking:Tag("Parts", Instance.new("Part"), "Touched")

--Tags that a round object has been started.
Pulse.Instancetracking:Tag("Round", {}, "Started")

--Automatically tags instances in a group with their name.
--This is intended when the total instances is far more than the options for name (tools, maps, etc).
--Avoid using this with players or characters.
Pulse.Instancetracking:AutoTagNames("Tools") --Ex: Use with Pulse.InstanceTracking:AutoTrackByClassName("Tools", "BackpackItem")
```

## Admin Integrations
Special integrations are provided for Nexus Admin. More implementations
can be considered - please create an Issue with a suggestion or Pull Request
with an implementation.

### Nexus Admin Integration
Nexus Admin integration allows for replacing `Pulse::EnableAuthorization`
with an admin level check, and creates commands to view totals for tags
(instead of just the groups with the debug text).

```luau
local NexusAdminIntegration = require(ReplicatedStorage:WaitForChild("Pulse"):WaitForChild("Admin"):WaitForChild("NexusAdmin"))

--Enables admin level authorization for admin level >= 1 (SERVER ONLY).
NexusAdminIntegration:EnableAdminLevelAuthorization(1)

--Adds `clientinstances` and `serverinstances` commands for admin level >= 1 (client AND server required together).
NexusAdminIntegration:AddCommands(1)
```

## License
Pulse is available under the terms of the MIT License. See [LICENSE](LICENSE)
for details.