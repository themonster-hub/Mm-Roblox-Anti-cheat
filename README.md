# MM Anti-Cheat v1.0

![Version](https://img.shields.io/github/v/tag/author/repo?label=version&color=blue)
![License](https://img.shields.io/badge/License-Proprietary-red)
![Status](https://img.shields.io/badge/Status-Active-brightgreen)

## Overview

MM Anti-Cheat is a comprehensive, server-authoritative anti-cheat system for Roblox, featuring advanced behavior validation, network security, and physics monitoring. It is engineered on the principle of zero client trust, effectively detecting and preventing a wide range of exploits by validating all player actions against server-side expectations.

**Developer:** Your Name / Studio  
**Version:** 1.0  
**License:** Proprietary Software – Unauthorized modification, distribution, or use is strictly prohibited.

---

## Features

### Core Features

- **Server-Authoritative Architecture**: All critical logic runs on the server, making client-side bypasses exceptionally difficult.
- **Modular Detection**: Detections can be individually enabled, disabled, and configured.
- **Violation & Escalation System**: Accumulates violation points for suspicious behavior, leading to escalating punishments.
- **Secure Remote Handling**: Built-in wrappers for remotes that automatically prevent spam and abuse.
- **Weakness Scanner**: Audits the game for common security vulnerabilities and provides developer feedback.
- **Configuration-Driven**: All thresholds and settings are managed in a single, easy-to-use configuration file.
- **Developer API**: Simple functions to authorize legitimate game mechanics and prevent false positives.

### Security & Detection Features

- **Speed Hack Detection**: Monitors and validates player velocity.
- **Noclip & Phasing Detection**: Uses raycasting to prevent players from passing through solid objects.
- **Teleport Detection**: Flags and reverts impossibly large movements.
- **Infinite Jump & High Jump Detection**: Validates jump frequency and vertical velocity.
- **Flight Detection**: Inferred through a combination of noclip, high jump, and speed detection.
- **God Mode & Health Manipulation**: Prevents unauthorized health increases.
- **MaxHealth Manipulation**: Reverts unauthorized changes to a player's maximum health.
- **Stat Tampering**: Protects leaderstats values from being modified by the client.
- **Tool Spoofing & Unauthorized Equipping**: Detects tools that are not legitimately owned by the player.
- **GUI Injection Detection**: Securely scans the client's CoreGui for unauthorized interfaces.
- **Executor Detection**: Checks for global variables and metatable hooks common to exploit injectors.

---

## Installation

### Prerequisites

- Roblox Studio
- Administrative access to your Roblox game

### Setup Steps

1. **Import all files** into your Roblox game, following the structure below.
2. Place server modules in `ServerScriptService`:
   - `MM_AntiCheat.lua` (ModuleScript)
   - `MM_Config.lua` (ModuleScript)
   - `MM_Remotes.lua` (ModuleScript)
   - `AntiCheat_Loader.lua` (Script)
3. Place `MM_ClientHandler.lua` (LocalScript) in `StarterPlayerScripts`.
4. Edit `MM_Config.lua` to match your game’s settings.
5. Use the Developer API (see below) to authorize legitimate in-game actions.
6. Test thoroughly in a private server before releasing to public.

### File Structure

```
game
└── ServerScriptService/
    ├── MM_AntiCheat.lua        (ModuleScript)
    ├── MM_Config.lua           (ModuleScript)
    ├── MM_Remotes.lua          (ModuleScript)
    └── AntiCheat_Loader.lua    (Script)
└── StarterPlayer/
    └── StarterPlayerScripts/
        └── MM_ClientHandler.lua (LocalScript)
```

---

## Configuration

All configuration is done inside `MM_Config.lua`.

### Basic Configuration

```lua
-- In MM_Config.lua
Config.Whitelist = {
    [1] = true -- Whitelist admin/developer UserIDs
}

Config.ViolationLevels = {
    [50] = "KICK",
    [100] = function(player, reason)
        -- Custom ban logic (e.g., DataStore, Trello, etc.)
        print("Banning " .. player.Name .. " for: " .. reason)
    end,
}
```

### Callback Configuration

```lua
Config.Callbacks = {
    OnFlag = function(player, reason, points, totalViolations)
        -- Send a Discord webhook, log to a database, etc.
    end,

    OnKick = function(player, reason)
        -- Final data saving before a player is removed.
    end,
}
```

---

## Core Modules & API Documentation

### MM_AntiCheat (API)

The main interface for developers to communicate with the anti-cheat system.

- `AntiCheat.AuthorizeStatChange(player, statName, newValue)`  
  Authorizes a one-time change to a protected leaderstat value. **Must be called before the change occurs.**

- `AntiCheat.UpdateExpectedValue(player, propertyName, newValue)`  
  Updates the anti-cheat’s baseline expectation for a `Humanoid` property. Use this for power-ups, buffs, etc.

### MM_Remotes (API)

Secure constructors for safe remote communication.

- `Remotes.WrapRemoteEvent(name)`  
  Returns a secure `RemoteEvent` with spam detection.

- `Remotes.WrapRemoteFunction(name)`  
  Returns a secure `RemoteFunction`.

- `Remotes.SecureClickDetector(clickDetector)`  
  Adds auto-clicker detection to a given `ClickDetector`.

---

## Security Settings & Thresholds

All thresholds are defined in `MM_Config.lua`.

### Movement Thresholds

```lua
Config.Speed.Buffer = 5 -- Allowed variance above WalkSpeed
Config.Teleport.MaxDistance = 100 -- Max distance per physics step
Config.InfiniteJump.TimeThreshold = 0.2 -- Minimum time between jumps
```

### Network Thresholds

```lua
Config.Remotes.EventSpam.MaxRequests = 10 -- Max events per...
Config.Remotes.EventSpam.TimeFrame = 1    -- ...second

Config.AutoClicker.MaxClicks = 15         -- Max clicks per...
Config.AutoClicker.TimeFrame = 1          -- ...second per ClickDetector
```

---

## Punishment System

The punishment system is driven by the `ViolationLevels` table in `MM_Config.lua`.

### Violation Points

- Each offense adds a set number of `ViolationPoints`.
- Severity determines the amount (e.g., Remote Spam = 5 pts, Executor Detection = 100 pts).

### Escalation Example

```lua
-- Example: Player reaches 53 points after Remote Spam (+5)
Config.ViolationLevels = {
    [50] = "KICK",
    [100] = function(player, reason)
        -- Custom ban logic
    end
}
```

---

## Support and Contact

For issues or questions:

**Developer:** Nobody knows... 
**Version:** 1.0  
**Last Updated:** 7-12-25

---

## License

This anti-cheat system is **proprietary software**. All code and assets are the intellectual property of the developer.  
**Unauthorized use, modification, reproduction, or distribution is strictly prohibited** and may result in legal action or permanent bans from associated games.