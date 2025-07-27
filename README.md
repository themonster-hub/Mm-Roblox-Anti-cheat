
##MM Anti-Cheat

![alt text](https://img.shields.io/badge/Type-Server--Side-blue)


![alt text](https://img.shields.io/badge/Architecture-Modular-green)


![alt text](https://img.shields.io/badge/Compatibility-FilteringEnabled-brightgreen)

A comprehensive, server-authoritative anti-cheat solution designed for Roblox. This system is engineered on the principle of zero client trust, with all critical detection logic operating on the server to ensure high resistance to tampering and full compliance with the FilteringEnabled environment.

Table of Contents

Why MM Anti-Cheat?

Feature Set

Installation

System Architecture

Configuration

API & Integration

Weakness Scanner

License

Disclaimer

Why MM Anti-Cheat?

Server-Authoritative: The core design principle is to never trust the client. All detections are validated on the server, making exploits that manipulate client-side physics or properties ineffective.

Modular & Extensible: Detections are separated into modules that can be individually configured or disabled. The API allows for seamless integration with your existing game mechanics.

Developer-Friendly: Includes a built-in Weakness Scanner that automatically audits your game for common security vulnerabilities, providing actionable feedback to improve your overall security posture.

Secure by Default: The remote communication layer is built with security in mind, automatically handling spam/throttling and using nonce-based validation for client-side integrity checks to prevent spoofing.

Feature Set
Category	Detections & Features
Movement & Physics	<ul><li>Monitors and normalizes player velocity to prevent speed exploits.</li><li>Detects and reverts unauthorized positional changes (teleporting).</li><li>Performs raycast checks to prevent noclip/phasing through collidable geometry.</li><li>Flags excessive vertical velocity (high jumps) and jump frequency (infinite jumps).</li></ul>
Character & Stats	<ul><li>Prevents unauthorized modification of Humanoid.Health and Humanoid.MaxHealth.</li><li>Protects leaderstats values from client-side manipulation.</li><li>Reverts unauthorized changes to core properties like WalkSpeed and JumpPower.</li><li>Detects spoofed tools, duplicate character parts, and excessive accessory spam.</li></ul>
Network & Remotes	<ul><li>Provides wrapped RemoteEvent and RemoteFunction constructors with built-in spam and throttle protection.</li><li>Monitors ClickDetector interaction rates to detect auto-clickers.</li><li>Includes detection for rapid-fire chat spam.</li></ul>
Client-Side Integrity	<ul><li>Performs secure, nonce-based checks of the client's CoreGui for injected GUIs.</li><li>Scans the client's global environment (_G) and metatables for signs of exploit injectors.</li><li>Times out and flags clients that fail to respond to integrity checks.</li></ul>
Installation
1. File Structure

Place the system's four scripts into your game environment as follows.

Note: The SecureRemotes folder will be generated automatically in ReplicatedStorage on first run.

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

2. Create the Loader Script

Create a new Script in ServerScriptService named AntiCheat_Loader.lua. This script boots the system.

Generated lua
-- /ServerScriptService/AntiCheat_Loader.lua

local ServerScriptService = game:GetService("ServerScriptService")

local AntiCheat = require(ServerScriptService.MM_AntiCheat)
local Config = require(ServerScriptService.MM_Config)

-- Initialize the system with your configuration
AntiCheat.Init(Config)
IGNORE_WHEN_COPYING_START
content_copy
download
Use code with caution.
Lua
IGNORE_WHEN_COPYING_END
3. Create the Client Handler

Create a new LocalScript in StarterPlayerScripts named MM_ClientHandler.lua and paste in the client-side code provided with the system files. This script is lightweight and only responds to integrity check requests from the server.

System Architecture

MM_AntiCheat.lua (Core Detection Engine): The central module that runs the main RunService.Heartbeat detection loop. It tracks player state, manages violation data, and executes configured penalties.

MM_Config.lua (Configuration Module): A centralized table of all settings. This file is used to enable/disable detections, tune thresholds, whitelist UserIDs, and define violation responses. This is the primary file for customization.

MM_Remotes.lua (Network Security Layer): Manages secure client-server communication. It provides wrapped RemoteEvent and RemoteFunction constructors and manages the nonce-based system for client-side integrity checks.

MM_ClientHandler.lua (Client-Side Integrity Handler): A minimal LocalScript that responds to server requests for environment checks (e.g., CoreGui scans). It operates on a request-response model and has no authority of its own.

Configuration

All system behavior is controlled via MM_Config.lua.

Whitelist: An array of UserIds to be ignored by all cheat detections.

ViolationLevels: A dictionary mapping violation point thresholds to actions ("KICK" or a custom function for banning).

Callbacks.OnFlag: A function that fires whenever a player is flagged. Ideal for integrating with external logging services or analytics.

API & Integration

To prevent false positives from your own game mechanics, you must inform the anti-cheat of legitimate, server-driven state changes.

Best Practices

Authorize Before You Act: Always call the authorization function before your code makes the actual change.

Update Baselines for Temporary Effects: When applying a temporary power-up (like a speed boost), use UpdateExpectedValue. When it expires, call it again to revert the expectation to the default value.

Authorizing Stat Changes

Function Signature:
AntiCheat.AuthorizeStatChange(player: Player, statName: string, newValue: any)

Example (Shop Script):

Generated lua
local AntiCheat = require(game.ServerScriptService.MM_AntiCheat)

function purchaseItem(player, itemCost)
    local stats = player.leaderstats
    if stats.Cash.Value >= itemCost then
        local newCashValue = stats.Cash.Value - itemCost
        
        -- 1. Authorize the new value before the server makes the change.
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

    -- 1. Update the expected value for the anti-cheat.
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
Weakness Scanner

The system includes a utility that runs on server startup to scan for common security flaws in your game's structure, such as:

Unprotected RemoteEvent or RemoteFunction instances in ReplicatedStorage.

Potentially sensitive ModuleScripts in client-accessible locations.

Server Scripts located in StarterPlayerScripts.

This feature provides actionable warnings in the server console to help developers harden their game's security posture.

License

This project is licensed under the MIT License. See the LICENSE file for details.

Disclaimer

This system provides a robust defense against a wide array of common exploits. However, no anti-cheat solution is infallible. It should be used as one layer in a comprehensive security strategy that includes diligent server-side validation and secure coding practices.