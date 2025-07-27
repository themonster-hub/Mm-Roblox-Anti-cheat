
##MM Anti-Cheat System

MM Anti-Cheat is a modular, server-authoritative, and reusable anti-cheat solution designed for Roblox games. Its core philosophy is to never trust the client. All critical detection logic runs on the server, making it compliant with FilteringEnabled and resistant to client-side tampering.

This system is designed not only to catch cheaters but also to help developers identify and fix common security vulnerabilities in their own game scripts through its "Weakness Detection" feature.

✅ Features

The system includes over 35 detections and security features, categorized for clarity.

Movement & Physics

Speed Hacks: Detects players moving faster than their allowed WalkSpeed.

Swim Speed Hacks: Detects players swimming faster than the configured limit.

Teleporting: Flags players for covering impossibly large distances instantly.

NoClip / Phasing: Detects players passing through solid, collidable objects.

High Jumps: Flags players for achieving excessive vertical velocity.

Infinite Jump: Detects players jumping more frequently than physically possible.

State Bypassing: Catches players who prevent their HumanoidStateType from changing (e.g., avoiding death).

Vehicle Fling: Detects players being flung at extreme speeds after exiting a vehicle seat.

Character & Stats

Health Tampering: Prevents players from setting their health higher than the server expects (God Mode).

MaxHealth Tampering: Prevents players from increasing their MaxHealth property.

Unauthorized Stat Changes: Protects leaderstats values (like Cash, Kills) from being changed by the client.

WalkSpeed/JumpPower Tampering: Detects and reverts changes to core humanoid properties.

Fake Body Parts: Detects the addition of unauthorized Humanoid or HumanoidRootPart instances.

Body Part Size Tampering: Flags players for resizing body parts (e.g., making the head smaller).

Invisibility Hacks: Detects players making their character parts transparent.

Character Parent Tampering: Detects when a player's character model is moved out of workspace.

Tool Spoofing: Flags the addition of unauthorized tools to the character.

Accessory Spam: Prevents players from equipping an excessive number of accessories to lag the server.

Animation Spoofing: Flags the use of animations not whitelisted in the configuration.

Remote & Network

RemoteEvent Spam: Tracks and throttles excessive RemoteEvent fires from a single client.

RemoteFunction Abuse: Wraps RemoteFunction invocations to prevent errors and spam.

Auto-Clicker: Detects an unnaturally high click rate on ClickDetector objects.

Chat Spam: Detects and flags players who send chat messages too quickly.

Client-Side Integrity

GUI Injection: Securely checks the client's CoreGui for unauthorized ScreenGui instances.

Executor Detection: Checks for common global variables and metatable changes associated with exploit injectors.

Secure Client Checks: Uses a token-based (nonce) system to prevent exploiters from spoofing "all-clear" responses to integrity checks.

🔧 Setup Instructions

Setting up the system takes less than 5 minutes.

1. File Structure

Place the four provided scripts in your game's hierarchy as shown below:

Generated code
game
├── ReplicatedStorage
│   └── SecureRemotes (Folder - will be created automatically)
│
├── ServerScriptService
│   ├── MM_AntiCheat.lua (ModuleScript)
│   ├── MM_Config.lua (ModuleScript)
│   ├── MM_Remotes.lua (ModuleScript)
│   └── AntiCheat_Loader.lua (Script)  <-- You must create this
│
└── StarterPlayer
    └── StarterPlayerScripts
        └── MM_ClientHandler.lua (LocalScript)  <-- You must create this

2. Create the Loader Script

In ServerScriptService, create a new Script and name it AntiCheat_Loader.lua. Paste the following code into it. This script initializes the entire system.

Generated lua
-- AntiCheat_Loader.lua

local ServerScriptService = game:GetService("ServerScriptService")

-- Require the modules
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
3. Create the Client Handler Script

In StarterPlayer > StarterPlayerScripts, create a new LocalScript and name it MM_ClientHandler.lua. Paste the code from the MM_ClientHandler.lua (Refined) section of the previous response. This script is responsible for responding to server-side integrity checks.

That's it! The system is now active and protecting your game.

⚙️ How It Works (Architecture)

The system is split into three main server modules and one client handler.

MM_AntiCheat.lua (The Brain): This is the core of the system. It runs a Heartbeat loop on the server to monitor every player's state, position, and properties. It manages player data, handles the flagging logic, and takes action based on violation levels defined in the config.

MM_Config.lua (The Control Panel): This module contains all user-configurable settings. You can enable/disable any feature, adjust sensitivity (e.g., speed buffer, spam rate), whitelist admin UserIDs, and define custom actions like kicking or banning. This is the main file you will edit.

MM_Remotes.lua (The Gatekeeper): This module secures all communication between the client and server. It provides wrapper functions for creating secure RemoteEvents and RemoteFunctions that automatically handle spam detection. It is also responsible for initiating client-side checks using a secure token system to prevent spoofed responses.

MM_ClientHandler.lua (The Client Agent): This lightweight LocalScript listens for requests from the server (sent via MM_Remotes). When requested, it will scan CoreGui or the global environment for signs of exploits and report the findings back, along with the secure token it was given.

🛠️ Configuration and Integration Guide

To get the most out of the system, you should configure it for your game's specific needs.

Editing the MM_Config.lua file:

Whitelist: Add the UserId of developers and administrators to make them immune to the anti-cheat.

ViolationLevels: This table defines what happens when a player's violation score reaches a certain point. You can use the default "KICK" action or define a custom function for banning.

Generated lua
Config.ViolationLevels = {
    [50] = "KICK",
    [100] = function(player, reason)
        -- Your custom ban logic here
        -- e.g., MyBanModule:Ban(player.UserId, "Accumulated Violations: " .. reason)
    end,
}
IGNORE_WHEN_COPYING_START
content_copy
download
Use code with caution.
Lua
IGNORE_WHEN_COPYING_END

Callbacks: Use the OnFlag callback to log cheat detections to a Discord webhook or your own analytics service.

ProtectedStats: Add the names of your leaderstats values (e.g., "Cash", "XP") to this table to protect them from client-side changes.

Integrating with Your Game Scripts

For the anti-cheat to work perfectly with your game's mechanics (like power-ups or shops), you must tell it when a change is legitimate.

1. Authorizing Stat Changes (e.g., giving cash)

Before your server script changes a protected leaderstat, you must authorize it.

Generated lua
-- In your server script (e.g., a shop script)
local AntiCheat = require(game.ServerScriptService.MM_AntiCheat)

function givePlayerMoney(player, amount)
    local leaderstats = player.leaderstats
    local newAmount = leaderstats.Cash.Value + amount
    
    -- Tell the anti-cheat that this change is valid BEFORE you make it
    AntiCheat.AuthorizeStatChange(player, "Cash", newAmount)
    
    -- Now, make the change
    leaderstats.Cash.Value = newAmount
end
IGNORE_WHEN_COPYING_START
content_copy
download
Use code with caution.
Lua
IGNORE_WHEN_COPYING_END

2. Authorizing Property Changes (e.g., a speed boost power-up)

If a script changes a player's WalkSpeed, MaxHealth, etc., you must update the anti-cheat's expected value.

Generated lua
-- In your power-up server script
local AntiCheat = require(game.ServerScriptService.MM_AntiCheat)

function applySpeedBoost(player)
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end
    
    local newSpeed = 32 -- The new, faster speed
    
    -- Tell the anti-cheat to expect this new value
    AntiCheat.UpdateExpectedValue(player, "WalkSpeed", newSpeed)
    
    -- Now, apply the speed boost
    humanoid.WalkSpeed = newSpeed
end
IGNORE_WHEN_COPYING_START
content_copy
download
Use code with caution.
Lua
IGNORE_WHEN_COPYING_END

3. Securing Your Remotes

To protect your own RemoteEvents and RemoteFunctions from spammers, wrap them using the MM_Remotes module.

Generated lua
-- In a server script where you define remotes
local Remotes = require(game.ServerScriptService.MM_Remotes)

-- This creates a secure remote event inside the "SecureRemotes" folder
local MySecureEvent = Remotes.WrapRemoteEvent("MyEventName")

-- Connect to it just like a normal remote event
MySecureEvent:Connect(function(player, arg1, arg2)
    -- This code will only run if the player is not spamming the remote.
    print(player.Name .. " sent: " .. arg1, arg2)
end)
IGNORE_WHEN_COPYING_START
content_copy
download
Use code with caution.
Lua
IGNORE_WHEN_COPYING_END
⚠️ Disclaimer

No anti-cheat system is 100% foolproof. This system provides a very strong, server-authoritative defense against a wide range of common exploits. However, dedicated cheaters will always look for new ways to bypass protections. Use this system as a powerful layer of security, but always continue to practice safe coding and secure your game logic on the server.