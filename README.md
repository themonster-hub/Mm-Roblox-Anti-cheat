

MM Anti-Cheat v1.0

![alt text](https://img.shields.io/github/v/tag/author/repo?label=version&color=blue)


![alt text](https://img.shields.io/badge/License-Proprietary-red)


![alt text](https://img.shields.io/badge/Status-Active-brightgreen)

Overview

MM Anti-Cheat is a comprehensive, server-authoritative anti-cheat system for Roblox, featuring advanced behavior validation, network security, and physics monitoring. It is engineered on the principle of zero client trust, effectively detecting and preventing a wide range of exploits by validating all player actions against server-side expectations.

Developer: Your Name / Studio

Version: 1.0

License: Proprietary Software - Unauthorized modification, distribution, or use is strictly prohibited.

Features
Core Features

Server-Authoritative Architecture: All critical logic runs on the server, making client-side bypasses exceptionally difficult.

Modular Detection: Detections can be individually enabled, disabled, and configured.

Violation & Escalation System: Accumulates violation points for suspicious behavior, leading to escalating punishments.

Secure Remote Handling: Built-in wrappers for remotes that automatically prevent spam and abuse.

Weakness Scanner: Audits the game for common security vulnerabilities and provides developer feedback.

Configuration-Driven: All thresholds and settings are managed in a single, easy-to-use configuration file.

Developer API: Simple functions to authorize legitimate game mechanics and prevent false positives.

Security & Detection Features

Speed Hack Detection: Monitors and validates player velocity.

Noclip & Phasing Detection: Uses raycasting to prevent players from passing through solid objects.

Teleport Detection: Flags and reverts impossibly large movements.

Infinite Jump & High Jump Detection: Validates jump frequency and vertical velocity.

Flight Detection: Inferred through a combination of noclip, high jump, and speed detection.

God Mode & Health Manipulation: Prevents unauthorized health increases.

MaxHealth Manipulation: Reverts unauthorized changes to a player's maximum health.

Stat Tampering: Protects leaderstats values from being modified by the client.

Tool Spoofing & Unauthorized Equipping: Detects tools that are not legitimately owned by the player.

GUI Injection Detection: Securely scans the client's CoreGui for unauthorized interfaces.

Executor Detection: Checks for global variables and metatable hooks common to exploit injectors.

Installation
Prerequisites

Roblox Studio

Administrative access to your Roblox game

Setup Steps

Import all files into your Roblox game, following the structure below.

Place server modules (MM_AntiCheat, MM_Config, MM_Remotes) and the loader script in ServerScriptService.

Place the client handler script (MM_ClientHandler) in StarterPlayerScripts.

Update MM_Config.lua with your preferences (e.g., Whitelist, ViolationLevels).

Use the Developer API (see below) in your game scripts to authorize legitimate actions.

Test the system thoroughly in a private server before public deployment.

File Structure
Generated code
game
└── ServerScriptService/
│   ├── MM_AntiCheat.lua       (ModuleScript)
│   ├── MM_Config.lua          (ModuleScript)
│   ├── MM_Remotes.lua         (ModuleScript)
│   └── AntiCheat_Loader.lua   (Script)
│
└── StarterPlayer/
    └── StarterPlayerScripts/
        └── MM_ClientHandler.lua (LocalScript)

Configuration

All settings are managed in MM_Config.lua.

Basic Configuration
Generated lua
-- In MM_Config.lua
Config.Whitelist = { [1] = true } -- Whitelist admin/developer UserIDs

-- Defines punishments based on accumulated violation points.
Config.ViolationLevels = {
	[50] = "KICK",
	[100] = function(player, reason)
		-- Custom ban logic here (e.g., DataStore, Trello, etc.)
		print("Banning "..player.Name.." for: "..reason)
	end,
}
IGNORE_WHEN_COPYING_START
content_copy
download
Use code with caution.
Lua
IGNORE_WHEN_COPYING_END
Callback Configuration
Generated lua
-- Custom logging, analytics, or Discord integration can be hooked here.
Config.Callbacks = {
	OnFlag = function(player, reason, points, totalViolations)
		-- Send a Discord webhook, log to a database, etc.
	end,
	OnKick = function(player, reason)
		-- Final data saving before a player is removed.
	end,
}
IGNORE_WHEN_COPYING_START
content_copy
download
Use code with caution.
Lua
IGNORE_WHEN_COPYING_END
Core Modules & API Documentation
MM_AntiCheat (API)

The primary interface for your game scripts to communicate with the anti-cheat system.

AntiCheat.AuthorizeStatChange(player, statName, newValue)

Authorizes a one-time change to a protected leaderstat value. Must be called before the change occurs.

AntiCheat.UpdateExpectedValue(player, propertyName, newValue)

Updates the anti-cheat's baseline expectation for a Humanoid property (e.g., WalkSpeed, MaxHealth). Use this for power-ups or temporary effects.

MM_Remotes (API)

Provides secure constructors for network communication.

Remotes.WrapRemoteEvent(name)

Returns a secure RemoteEvent wrapper that automatically handles spam detection.

Remotes.WrapRemoteFunction(name)

Returns a secure RemoteFunction wrapper.

Remotes.SecureClickDetector(clickDetector)

Adds auto-clicker detection to an existing ClickDetector.

Security Settings & Thresholds

These values are configured within the specific detection tables in MM_Config.lua.

Movement Thresholds
Generated lua
Config.Speed.Buffer = 5                 -- Allowed speed variance above WalkSpeed.
Config.Teleport.MaxDistance = 100       -- Max distance a player can travel in a single physics step.
Config.InfiniteJump.TimeThreshold = 0.2 -- Minimum time between jumps.
IGNORE_WHEN_COPYING_START
content_copy
download
Use code with caution.
Lua
IGNORE_WHEN_COPYING_END
Network Thresholds
Generated lua
Config.Remotes.EventSpam.MaxRequests = 10 -- Max remote fires per...
Config.Remotes.EventSpam.TimeFrame = 1    -- ...second.

Config.AutoClicker.MaxClicks = 15         -- Max clicks per...
Config.AutoClicker.TimeFrame = 1          -- ...second on a single detector.
IGNORE_WHEN_COPYING_START
content_copy
download
Use code with caution.
Lua
IGNORE_WHEN_COPYING_END
Punishment System

The punishment system is driven by ViolationLevels in the configuration file.

Violation Points

Each detected offense adds a specific number of ViolationPoints to the player's profile.

The severity of the offense determines the points assigned (e.g., Remote Spam: 5 points, Executor Detection: 100 points).

Escalation

When a player's total violation points cross a threshold defined in ViolationLevels, the corresponding action is triggered.

Actions can be a predefined string ("KICK") or a custom function for full control over banning.

Generated lua
-- Example: A player with 48 points who gets flagged for Remote Spam (+5 points)
-- will have 53 total points, crossing the 50-point threshold and triggering a kick.
Config.ViolationLevels = {
	[50] = "KICK",
	[100] = -- Ban function
}
IGNORE_WHEN_COPYING_START
content_copy
download
Use code with caution.
Lua
IGNORE_WHEN_COPYING_END
Support and Contact

For support or inquiries regarding MM Anti-Cheat, please contact the developer.

Developer: Your Name / Studio

Version: 1.0

Last Updated: 2024-05-21

License

This anti-cheat system is proprietary software. All files and code are the intellectual property of the developer. Any unauthorized modification, reproduction, distribution, or use of this system, in whole or in part, is strictly prohibited and may result in legal action and a permanent ban from associated games.