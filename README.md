
MM Anti-Cheat

![alt text](https://img.shields.io/badge/Type-Server--Side-blue)


![alt text](https://img.shields.io/badge/Architecture-Modular-green)


![alt text](https://img.shields.io/badge/Compatibility-FilteringEnabled-brightgreen)

MM Anti-Cheat is a modular, server-authoritative anti-cheat solution for Roblox. It is engineered on the principle of zero client trust, with all critical detection logic operating on the server to ensure high resistance to tampering and full compliance with the FilteringEnabled environment.

Table of Contents

Philosophy

Feature Set

Installation

System Architecture

Configuration

API & Integration

Weakness Scanner

Disclaimer

Philosophy

The core design is strictly server-authoritative. No client-side input is trusted for game-critical mechanics. Detections are performed by validating player actions and states against server-side expectations, rendering most client-side manipulation ineffective.

Feature Set
Category	Detections & Features
Movement & Physics	Speed Hacks, Noclip, Teleporting, High Jumps, Infinite Jumps, State Bypassing (Anti-Ragdoll/Death), Vehicle Fling, Swim Speed Hacks.
Character & Stats	Health Tampering, MaxHealth Modification, Unauthorized Stat Changes (leaderstats), WalkSpeed/JumpPower Manipulation, Unauthorized Tool Equipping, Body Part Resizing, Character Parenting, Accessory Spam.
Network & Remotes	RemoteEvent Spam/Throttling, RemoteFunction Wrappers, Auto-Clicker/Interaction Rate Limiting, Chat Spam Detection.
Client-Side Integrity	Secure GUI Injection Checks (scans CoreGui), Executor Environment Detection (checks _G and metatables), Nonce-based validation to prevent client check spoofing.
System & Security	Weakness Scanner: Identifies common vulnerabilities in the game's structure, such as unprotected remotes or misplaced server scripts.
Installation
1. File Structure

Place the system's four scripts into your game environment as follows. The SecureRemotes folder will be generated automatically upon initialization.

Generated code
game
└── ServerScriptService
│   ├── MM_AntiCheat.lua       (ModuleScript)
│   ├── MM_Config.lua          (ModuleScript)
│   ├── MM_Remotes.lua         (ModuleScript)
│   └── AntiCheat_Loader.lua   (Script)
│
└── StarterPlayer
    └── StarterPlayerScripts
        └── MM_ClientHandler.lua (LocalScript)

2. Create Loader Script

Create a new Script in ServerScriptService named AntiCheat_Loader.lua. This script boots the system.

Generated lua
--- /ServerScriptService/AntiCheat_Loader.lua
local ServerScriptService = game:GetService("ServerScriptService")

local AntiCheat = require(ServerScriptService.MM_AntiCheat)
local Config = require(ServerScriptService.MM_Config)

AntiCheat.Init(Config)
IGNORE_WHEN_COPYING_START
content_copy
download
Use code with caution.
Lua
IGNORE_WHEN_COPYING_END
3. Create Client Handler

Create a new LocalScript in StarterPlayerScripts named MM_ClientHandler.lua and paste in the client-side code provided with the system files. This handles integrity checks requested by the server.

System Architecture

MM_AntiCheat.lua (Core Logic & Detection Engine): The central module that runs the main RunService.Heartbeat detection loop. It tracks player state, manages violation data, and executes configured penalties.

MM_Config.lua (Configuration Module): A centralized table of all settings. This file is used to enable/disable detections, tune thresholds, whitelist UserIDs, and define violation responses. This is the primary file for customization.

MM_Remotes.lua (Remote & Network Security Layer): Manages secure client-server communication. It provides wrapped RemoteEvent and RemoteFunction constructors that automatically incorporate spam detection. It also manages the nonce-based system for client-side integrity checks.

MM_ClientHandler.lua (Client-Side Integrity Handler): A minimal LocalScript that responds to server requests for environment checks (e.g., CoreGui scans). It operates on a request-response model and has no authority of its own.

Configuration

All system behavior is controlled via MM_Config.lua.

Whitelist: An array of UserIds to be ignored by all cheat detections.

ViolationLevels: A dictionary mapping violation point thresholds to actions ("KICK" or a custom function).

Callbacks.OnFlag: A function that fires whenever a player is flagged. Ideal for integrating with external logging services or analytics.

Detection Tables: Each feature (e.g., Config.Speed, Config.Teleport) is a table containing an Enabled boolean and other specific parameters like ViolationPoints.

API & Integration

To prevent false positives, you must inform the anti-cheat of legitimate, server-driven changes to player state.

Authorizing Stat Changes

Before a server script modifies a protected leaderstat, it must pre-authorize the change.

Function Signature:
AntiCheat.AuthorizeStatChange(player: Player, statName: string, newValue: any)

Example (Shop Script):

Generated lua
local AntiCheat = require(game.ServerScriptService.MM_AntiCheat)

function purchaseItem(player, itemCost)
    local stats = player.leaderstats
    if stats.Cash.Value >= itemCost then
        local newCashValue = stats.Cash.Value - itemCost
        
        -- 1. Authorize the new value before changing it.
        AntiCheat.AuthorizeStatChange(player, "Cash", newCashValue)
        
        -- 2. Apply the change.
        stats.Cash.Value = newCashValue
    end
end
IGNORE_WHEN_COPYING_START
content_copy
download
Use code with caution.
Lua
IGNORE_WHEN_COPYING_END
Updating Expected Properties

If a server script changes a Humanoid property (e.g., for a power-up), update the anti-cheat's baseline expectation.

Function Signature:
AntiCheat.UpdateExpectedValue(player: Player, propertyName: string, newValue: any)

Example (Speed Boost Power-up):

Generated lua
local AntiCheat = require(game.ServerScriptService.MM_AntiCheat)

function applySpeedBoost(character)
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end
    
    local player = game.Players:GetPlayerFromCharacter(character)
    if not player then return end

    -- 1. Update the expected value.
    AntiCheat.UpdateExpectedValue(player, "WalkSpeed", 50)
    
    -- 2. Apply the change.
    humanoid.WalkSpeed = 50
end
IGNORE_WHEN_COPYING_START
content_copy
download
Use code with caution.
Lua
IGNORE_WHEN_COPYING_END
Securing Remotes

Wrap your game's remotes to automatically benefit from the built-in spam protection.

Example:

Generated lua
local Remotes = require(game.ServerScriptService.MM_Remotes)

-- Creates a secure remote in the designated folder.
local onPlayerAction = Remotes.WrapRemoteEvent("PlayerAction")

-- Use the wrapped event. The callback is protected from spam.
onPlayerAction:Connect(function(player, actionType)
    -- Process the legitimate player action here.
end)
IGNORE_WHEN_COPYING_START
content_copy
download
Use code with caution.
Lua
IGNORE_WHEN_COPYING_END
Weakness Scanner

The system includes a utility that runs on server startup to scan for common security flaws in your game's structure, such as:

Unprotected RemoteEvent or RemoteFunction instances in ReplicatedStorage.

Potentially sensitive ModuleScripts in client-accessible locations.

Server Scripts located in StarterPlayerScripts.

This feature provides actionable warnings in the server console to help developers harden their game's security posture.

Disclaimer

This system provides a robust defense against a wide array of common exploits. However, no anti-cheat solution is infallible. It should be used as one layer in a comprehensive security strategy that includes diligent server-side validation and secure coding practices.