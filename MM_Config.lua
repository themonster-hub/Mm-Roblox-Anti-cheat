--[[
	MM_Config.lua
	Description: Configuration for the MM_AntiCheat system.
	All thresholds, toggles, and custom actions are defined here.
--]]

local Config = {}

--============================================================================--
--=                          GLOBAL SETTINGS                               =--
--============================================================================--

-- A list of UserIds that are immune to the anti-cheat. Useful for developers/admins.
Config.Whitelist = {
	[1] = true, -- Roblox
	-- [1234567] = true, -- Example UserId
}

-- Defines actions to take when a player's violation points reach a certain level.
-- Actions can be "KICK" or a custom function.
-- The custom function receives the player object and the last reason for the flag.
Config.ViolationLevels = {
	[50] = "KICK",
	-- [100] = function(player, reason)
	--	-- Custom ban logic here (e.g., using DataStore2 or a web API)
	--	print("Banning "..player.Name.." for: "..reason)
	-- end,
}

-- Callbacks allow you to hook into anti-cheat events for custom logging or analytics.
Config.Callbacks = {
	-- Called every time a player is flagged for any reason.
	-- Useful for logging to Discord, a data store, or an analytics service.
	OnFlag = function(player, reason, points, totalViolations)
		-- Example: print(string.format("LOG: %s flagged for %s (+%d points). Total: %d", player.Name, reason, points, totalViolations))
	end,
	
	-- Called just before a player is kicked by the system.
	OnKick = function(player, reason)
		-- Example: Save the player's data before they are kicked.
		print(player.Name .. " is being kicked for: " .. reason)
	end,
}


--============================================================================--
--=                         DETECTION MODULES                              =--
--============================================================================--
-- Each module can be toggled and has its own settings.
-- ViolationPoints: How many points are added to a player's violation level when flagged.

-- 1. Speed Hacks
Config.Speed = {
	Enabled = true,
	ViolationPoints = 10,
	Buffer = 5, -- How much faster than their WalkSpeed a player can go before being flagged.
	GracePeriod = 0.5, -- How long (in seconds) they can be over the speed limit before it counts.
}

-- 2. Teleport / Fly / NoClip
Config.Teleport = {
	Enabled = true,
	ViolationPoints = 25,
	NoClipViolationPoints = 15,
	MaxDistance = 100, -- Max distance a player can travel in a very short time.
}

-- 3 & 4. Remote Spammer / Abuser (Settings for MM_Remotes.lua)
Config.Remotes = {
	EventSpam = {
		Enabled = true,
		ViolationPoints = 5,
		MaxRequests = 10, -- Max requests per...
		TimeFrame = 1, -- ...second.
	},
	FunctionAbuse = {
		Enabled = true,
		ViolationPoints = 50, -- Invoking functions with wrong arguments is more severe.
	},
	-- The name of a folder in ReplicatedStorage where your secure remotes are kept.
	-- The Weakness Detector will use this to find unprotected remotes.
	SecureRemotesFolder = "SecureRemotes",
}

-- 5. Health Tampering (God Mode / Insta-Heal)
Config.Health = {
	Enabled = true,
	ViolationPoints = 20,
}

-- 6. Unauthorized Stat Changes (e.g., leaderstats)
Config.Stats = {
	Enabled = true,
	ViolationPoints = 50,
	ProtectedStats = {
		"Cash",
		"Coins",
		"Kills",
		"Wins",
		-- Add any leaderstat value names you want to protect here
	},
}

-- 7. WalkSpeed Manipulation
Config.WalkSpeed = {
	Enabled = true,
	ViolationPoints = 10,
}

-- 8. JumpPower / JumpHeight Manipulation
Config.JumpPower = {
	Enabled = true,
	ViolationPoints = 10,
}

-- 9. Infinite Jump
Config.InfiniteJump = {
	Enabled = true,
	ViolationPoints = 5,
	TimeThreshold = 0.2, -- Minimum time required between jumps.
}

-- 10, 14 & more. Character & Body Part Tampering
Config.CharacterTampering = {
	Enabled = true,
	ViolationPoints = 50,
}

-- 11. Auto-Clicker (Excessive Interaction Rate)
Config.AutoClicker = {
	Enabled = true,
	ViolationPoints = 2,
	MaxClicks = 15, -- Max clicks per...
	TimeFrame = 1, -- ...second on a single ClickDetector.
}

-- 12. GUI Injection Detection (Client-side check)
Config.GuiInjection = {
	Enabled = true,
	ViolationPoints = 50,
	-- This check is initiated by the server, but runs on the client via MM_Remotes.
	-- It checks CoreGui for unexpected ScreenGuis.
}

-- 13. HumanoidStateType Bypass
Config.StateBypass = {
	Enabled = true,
	ViolationPoints = 25,
}

-- 15. Executor Detection (Client-side check)
Config.ExecutorDetection = {
	Enabled = true,
	ViolationPoints = 100,
	-- This check is initiated by the server, but runs on the client via MM_Remotes.
	-- It checks for common global environment variables set by exploit injectors.
}

--============================================================================--
--=                      ADDITIONAL DETECTION MODULES                      =--
--============================================================================--

-- 16. High Jump / Jump Hacks
Config.HighJump = {
	Enabled = true,
	ViolationPoints = 15,
	MaxVerticalSpeed = 100, -- Max upward velocity during a jump.
}

-- 17. God Mode (Client-side damage refusal)
Config.GodMode = {
	Enabled = true,
	ViolationPoints = 25,
}

-- 18. MaxHealth Manipulation
Config.MaxHealth = {
	Enabled = true,
	ViolationPoints = 20,
}

-- 19. Body Part Size Tampering (e.g., small head for smaller hitbox)
Config.BodyPartSize = {
	Enabled = true,
	ViolationPoints = 15,
}

-- 20. Character Parent Tampering (e.g., parenting character to nil to hide)
Config.CharacterParent = {
	Enabled = true,
	ViolationPoints = 50,
}

-- 21. Chat Spam
Config.ChatSpam = {
	Enabled = true,
	ViolationPoints = 2,
	MaxMessages = 5, -- Max messages in...
	TimeFrame = 3, -- ...seconds.
}

-- 22. BodyMover Abuse (e.g., adding BodyVelocity to fly)
Config.BodyMover = {
	Enabled = true,
	ViolationPoints = 25,
}

-- 23. Accessory Spam
Config.AccessorySpam = {
	Enabled = true,
	ViolationPoints = 5,
	MaxCount = 15, -- Max accessories a player can wear at once.
}

-- 24. Vehicle Fling
Config.VehicleFling = {
	Enabled = true,
	ViolationPoints = 15,
	MaxExitSpeed = 150, -- Max speed a player can have immediately after exiting a seat.
}

-- 25. Animation Spoofing
Config.AnimationSpoof = {
	Enabled = true,
	ViolationPoints = 10,
	AllowedIDs = { -- Add legitimate animation IDs used in your game here
		"rbxassetid://180435571", -- Default Walk
		"rbxassetid://180435792", -- Default Run
		-- etc.
	}
}

-- 26. Swim Speed Hacks
Config.SwimSpeed = {
	Enabled = true,
	ViolationPoints = 10,
	MaxSpeed = 25,
}

-- 27. Invisibility / Transparency Hacks
Config.Transparency = {
	Enabled = false, -- CAUTION: Enable only if you don't have scripts that change player transparency.
	ViolationPoints = 20,
}

-- 28-35 are covered implicitly or by the remotes module (e.g., remote function abuse, fake UI, etc.)

--============================================================================--
--=                      SYSTEM & DEBUGGING                                =--
--============================================================================--

-- Scans the game for common security weaknesses and prints warnings to the console.
Config.WeaknessDetection = {
	Enabled = true,
}

return Config