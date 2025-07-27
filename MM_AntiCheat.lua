local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ChatService = game:GetService("TextChatService")

local AntiCheat = {}
AntiCheat.Config = nil
AntiCheat.Remotes = nil

local playerData = {}

function AntiCheat.FlagPlayer(player, reason, points)
	if not player or not playerData[player] or AntiCheat.Config.Whitelist[player.UserId] then
		return
	end

	local data = playerData[player]
	data.violations = (data.violations or 0) + points

	warn(string.format("[MM_AntiCheat]: Flagged %s for %s. (VL: %d)", player.Name, reason, data.violations))

	if AntiCheat.Config.Callbacks.OnFlag then
		task.spawn(AntiCheat.Config.Callbacks.OnFlag, player, reason, points, data.violations)
	end

	local actionToTake
	local highestThreshold = 0
	for threshold, action in pairs(AntiCheat.Config.ViolationLevels) do
		if data.violations >= threshold and threshold > highestThreshold then
			actionToTake = action
			highestThreshold = threshold
		end
	end

	if actionToTake == "KICK" then
		player:Kick(string.format("[MM_AntiCheat]: Kicked for accumulating violations. Last reason: %s", reason))
	elseif type(actionToTake) == "function" then
		task.spawn(actionToTake, player, reason)
	end
end

function AntiCheat.AuthorizeStatChange(player, statName, newValue)
	local data = playerData[player]
	if data and data.statCache then
		data.statCache[statName] = newValue
	end
end

function AntiCheat.UpdateExpectedValue(player, propertyName, newValue)
    local data = playerData[player]
    if data and data.expectedProperties then
        data.expectedProperties[propertyName] = newValue
    end
end

local function checkMovement(player, char, hum, root, deltaTime)
	local data = playerData[player]
	local config = AntiCheat.Config

	if not data.lastPosition then
		data.lastPosition = root.Position
		return
	end

	local state = hum:GetState()
	if hum.Sit or state == Enum.HumanoidStateType.Seated or state == Enum.HumanoidStateType.PlatformStanding then
		data.lastPosition = root.Position
		return
	end

	local currentPos = root.Position
	local displacement = currentPos - data.lastPosition
	local horizontalSpeed = Vector2.new(displacement.X, displacement.Z).Magnitude / deltaTime
	local verticalSpeed = displacement.Y / deltaTime

	if config.Speed.Enabled then
		local maxSpeed = (data.expectedProperties.WalkSpeed or 16) + config.Speed.Buffer
		if state == Enum.HumanoidStateType.Swimming then
			maxSpeed = config.SwimSpeed.MaxSpeed or 16
		end
		
		if horizontalSpeed > maxSpeed then
			data.speedViolationTime = (data.speedViolationTime or 0) + deltaTime
			if data.speedViolationTime > config.Speed.GracePeriod then
				local reason = state == Enum.HumanoidStateType.Swimming and "Swim Speeding" or "Speeding"
				AntiCheat.FlagPlayer(player, reason, config.Speed.ViolationPoints)
				root.CFrame = CFrame.new(data.lastPosition)
				root.Velocity = Vector3.zero
			end
		else
			data.speedViolationTime = 0
		end
	end

	if config.Teleport.Enabled then
		local distance = displacement.Magnitude
		if distance > config.Teleport.MaxDistance and not data.inVehicle then
			AntiCheat.FlagPlayer(player, "Teleport", config.Teleport.ViolationPoints)
			root.CFrame = CFrame.new(data.lastPosition)
		else
			local rayOrigin = data.lastPosition + Vector3.new(0, 0.1, 0)
			local ray = Ray.new(rayOrigin, displacement.Unit * (distance + 0.1))
			local hit, pos = workspace:FindPartOnRayWithIgnoreList(ray, {char})
			if hit and hit.CanCollide and (pos - rayOrigin).Magnitude < distance - 1 and not hit:IsA("TrussPart") and not hit:IsA("Seat") then
				AntiCheat.FlagPlayer(player, "NoClip", config.Teleport.NoClipViolationPoints)
				root.CFrame = CFrame.new(data.lastPosition)
			end
		end
	end
	
	if config.HighJump.Enabled and state == Enum.HumanoidStateType.Freefall and verticalSpeed > config.HighJump.MaxVerticalSpeed then
		AntiCheat.FlagPlayer(player, "High Jump", config.HighJump.ViolationPoints)
	end

	if char.Parent ~= workspace and config.CharacterParent.Enabled then
		AntiCheat.FlagPlayer(player, "Character Parent Tampering", config.CharacterParent.ViolationPoints)
		player:LoadCharacter()
	end

	data.lastPosition = root.Position
end

local function checkProperties(player, hum, char)
	local data = playerData[player]
	local config = AntiCheat.Config

	if config.WalkSpeed.Enabled and hum.WalkSpeed > data.expectedProperties.WalkSpeed then
		AntiCheat.FlagPlayer(player, "WalkSpeed Tamper", config.WalkSpeed.ViolationPoints)
		hum.WalkSpeed = data.expectedProperties.WalkSpeed
	end

	if config.JumpPower.Enabled and (hum.JumpPower > data.expectedProperties.JumpPower or hum.JumpHeight > data.expectedProperties.JumpHeight) then
		AntiCheat.FlagPlayer(player, "Jump Tamper", config.JumpPower.ViolationPoints)
		hum.JumpPower = data.expectedProperties.JumpPower
		hum.JumpHeight = data.expectedProperties.JumpHeight
	end
	
	if config.MaxHealth.Enabled and hum.MaxHealth > data.expectedProperties.MaxHealth then
		AntiCheat.FlagPlayer(player, "MaxHealth Tamper", config.MaxHealth.ViolationPoints)
		hum.MaxHealth = data.expectedProperties.MaxHealth
	end
	
	if config.BodyPartSize.Enabled then
		local head = char:FindFirstChild("Head")
		if head and head.Size ~= data.expectedProperties.HeadSize then
			AntiCheat.FlagPlayer(player, "Head Size Tamper", config.BodyPartSize.ViolationPoints)
			head.Size = data.expectedProperties.HeadSize
		end
	end
end

local function checkStats(player)
	if not AntiCheat.Config.Stats.Enabled then return end
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then return end
	local data = playerData[player]
	local config = AntiCheat.Config

	for _, statName in ipairs(config.Stats.ProtectedStats) do
		local statObj = leaderstats:FindFirstChild(statName)
		if statObj then
			local serverValue = data.statCache[statName]
			if serverValue and statObj.Value ~= serverValue then
				AntiCheat.FlagPlayer(player, "Stat Tamper: "..statName, config.Stats.ViolationPoints)
				statObj.Value = serverValue
			end
		end
	end
end

local function onCharacterAdded(player, character)
	local humanoid = character:WaitForChild("Humanoid", 10)
	if not humanoid or not playerData[player] then return end

	local data = playerData[player]
	local config = AntiCheat.Config
	
	if data.charConnections then
		for _, conn in pairs(data.charConnections) do
			conn:Disconnect()
		end
	end
	data.charConnections = {}
    data.expectedProperties = {}
    data.accessoryCount = 0

	data.expectedProperties.WalkSpeed = humanoid.WalkSpeed
	data.expectedProperties.JumpPower = humanoid.JumpPower
	data.expectedProperties.JumpHeight = humanoid.JumpHeight
	data.expectedProperties.MaxHealth = humanoid.MaxHealth
	data.lastHealth = humanoid.Health
	if character:FindFirstChild("Head") then
		data.expectedProperties.HeadSize = character.Head.Size
	end
	
	data.inVehicle = false

	if config.InfiniteJump.Enabled then
		data.charConnections.jump = humanoid.StateChanged:Connect(function(_, new)
			if new == Enum.HumanoidStateType.Jumping then
				local now = tick()
				if now - (data.lastJumpTime or 0) < config.InfiniteJump.TimeThreshold then
					AntiCheat.FlagPlayer(player, "Infinite Jump", config.InfiniteJump.ViolationPoints)
				end
				data.lastJumpTime = now
			end
			
			if new == Enum.HumanoidStateType.Seated then
				data.inVehicle = true
			elseif data.inVehicle then
				data.inVehicle = false
				local root = character:FindFirstChild("HumanoidRootPart")
				if root and root.AssemblyLinearVelocity.Magnitude > config.VehicleFling.MaxExitSpeed then
					AntiCheat.FlagPlayer(player, "Vehicle Fling", config.VehicleFling.ViolationPoints)
				end
			end
		end)
	end

	if config.Health.Enabled then
		data.charConnections.health = humanoid:GetPropertyChangedSignal("Health"):Connect(function()
			if humanoid.Health > data.lastHealth then
				AntiCheat.FlagPlayer(player, "Health Tamper", config.Health.ViolationPoints)
				humanoid.Health = data.lastHealth
			else
				data.lastHealth = humanoid.Health
			end
		end)
	end
	
	if config.CharacterTampering.Enabled then
		data.charConnections.childAdded = character.ChildAdded:Connect(function(child)
			if child:IsA("Tool") then
				AntiCheat.FlagPlayer(player, "Tool Spoofing", config.CharacterTampering.ViolationPoints)
				child:Destroy()
			elseif child:IsA("Humanoid") or child.Name == "HumanoidRootPart" then
				AntiCheat.FlagPlayer(player, "Character Duplication", config.CharacterTampering.ViolationPoints)
				child:Destroy()
			elseif child:IsA("BodyMover") and config.BodyMover.Enabled then
				AntiCheat.FlagPlayer(player, "BodyMover Abuse", config.BodyMover.ViolationPoints)
				child:Destroy()
			elseif child:IsA("Accessory") then
				data.accessoryCount = data.accessoryCount + 1
				if data.accessoryCount > config.AccessorySpam.MaxCount then
					AntiCheat.FlagPlayer(player, "Accessory Spam", config.AccessorySpam.ViolationPoints)
					child:Destroy()
				end
			end
		end)
		
		data.charConnections.childRemoved = character.ChildRemoved:Connect(function(child)
			if child.Name == "HumanoidRootPart" then
				AntiCheat.FlagPlayer(player, "RootPart Deletion", config.CharacterTampering.ViolationPoints)
				player:LoadCharacter()
			end
		end)
	end

	if config.StateBypass.Enabled then
		data.charConnections.died = humanoid.Died:Connect(function()
			task.delay(0.5, function()
				if humanoid and humanoid.Health <= 0 and humanoid:GetState() ~= Enum.HumanoidStateType.Dead then
					AntiCheat.FlagPlayer(player, "Anti-Death State Bypass", config.StateBypass.ViolationPoints)
				end
			end)
		end)
	end
	
	if config.AnimationSpoof.Enabled and humanoid:FindFirstChild("Animator") then
		local animator = humanoid:FindFirstChild("Animator")
		data.charConnections.anim = animator.AnimationPlayed:Connect(function(track)
			if not table.find(config.AnimationSpoof.AllowedIDs, track.Animation.AnimationId) then
				AntiCheat.FlagPlayer(player, "Animation Spoofing", config.AnimationSpoof.ViolationPoints)
				track:Stop()
			end
		end)
	end
end

local function onPlayerAdded(player)
	playerData[player] = {
		violations = 0, statCache = {}, lastJumpTime = 0, speedViolationTime = 0,
		connections = {}, chatHistory = {},
	}
	
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats and AntiCheat.Config.Stats.Enabled then
		for _, statName in ipairs(AntiCheat.Config.Stats.ProtectedStats) do
			local statObj = leaderstats:FindFirstChild(statName)
			if statObj then playerData[player].statCache[statName] = statObj.Value end
		end
	end

	playerData[player].connections.charAdded = player.CharacterAdded:Connect(function(char)
		onCharacterAdded(player, char)
	end)
	if player.Character then onCharacterAdded(player, player.Character) end

	if AntiCheat.Config.ChatSpam.Enabled and ChatService then
		playerData[player].connections.chatted = ChatService.MessagePosted:Connect(function(message)
			if message.TextSource == player then
				local now = tick()
				table.insert(playerData[player].chatHistory, now)
				
				local recentMessages = 0
				for i = #playerData[player].chatHistory, 1, -1 do
					if now - playerData[player].chatHistory[i] <= AntiCheat.Config.ChatSpam.TimeFrame then
						recentMessages = recentMessages + 1
					else
						table.remove(playerData[player].chatHistory, i)
					end
				end
				
				if recentMessages > AntiCheat.Config.ChatSpam.MaxMessages then
					AntiCheat.FlagPlayer(player, "Chat Spam", AntiCheat.Config.ChatSpam.ViolationPoints)
				end
			end
		end)
	end
end

local function onPlayerRemoved(player)
	if playerData[player] then
		for _, conn in pairs(playerData[player].connections) do
			conn:Disconnect()
		end
        if playerData[player].charConnections then
            for _, conn in pairs(playerData[player].charConnections) do
                conn:Disconnect()
            end
        end
		playerData[player] = nil
	end
end

local function onHeartbeat(deltaTime)
	for player, data in pairs(playerData) do
		local success, err = pcall(function()
			local char = player.Character
			local hum = char and char:FindFirstChildOfClass("Humanoid")
			local root = hum and char:FindFirstChild("HumanoidRootPart")

			if char and hum and root and hum.Health > 0 then
				checkMovement(player, char, hum, root, deltaTime)
				checkProperties(player, hum, char)
				checkStats(player)
			else
				data.lastPosition = nil
			end
		end)
		if not success then
			warn("[MM_AntiCheat] Heartbeat error for " .. player.Name .. ": " .. err)
		end
	end
end

function AntiCheat.ScanForVulnerabilities()
	warn("[MM_AntiCheat]: Starting vulnerability scan...")

	local secureFolder = AntiCheat.Config.Remotes.SecureRemotesFolder
	for _, child in ipairs(ReplicatedStorage:GetDescendants()) do
		if (child:IsA("RemoteEvent") or child:IsA("RemoteFunction")) and (not secureFolder or not child:IsDescendantOf(secureFolder)) then
			warn(string.format("[WEAKNESS]: Unprotected Remote '%s'. Move to a secure folder.", child:GetFullName()))
		end
		if child:IsA("ModuleScript") and (child.Name:lower():match("server") or child.Name:lower():match("admin")) then
			warn(string.format("[WEAKNESS]: Module '%s' in ReplicatedStorage seems server-sided.", child:GetFullName()))
		end
	end
	
	local starterPlayer = game:GetService("StarterPlayer")
	for _, child in ipairs(starterPlayer.StarterPlayerScripts:GetChildren()) do
		if child:IsA("Script") then
			warn(string.format("[WEAKNESS]: Server Script '%s' in StarterPlayerScripts. Move to ServerScriptService.", child.Name))
		end
	end
	
	for _, part in ipairs(workspace:GetDescendants()) do
		if part:IsA("ClickDetector") and not part:FindFirstAncestorWhichIsA("Tool") then
			warn(string.format("[WEAKNESS]: Loose ClickDetector '%s' may be abusable by auto-clickers without server-side cooldowns.", part:GetFullName()))
		end
	end

	warn("[MM_AntiCheat]: Scan complete.")
end

function AntiCheat.Init(config)
	AntiCheat.Config = config
	
	local remotesModule = script.Parent:FindFirstChild("MM_Remotes")
	if not remotesModule then
		error("[MM_AntiCheat]: MM_Remotes.lua not found. System cannot start.")
	end
	AntiCheat.Remotes = require(remotesModule)
	AntiCheat.Remotes.Init(AntiCheat)

	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(onPlayerAdded, player)
	end
	
	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(onPlayerRemoved)
	
	RunService.Heartbeat:Connect(onHeartbeat)
	
	if AntiCheat.Config.WeaknessDetection.Enabled then
		task.delay(5, AntiCheat.ScanForVulnerabilities)
	end
	
	print("[MM_AntiCheat]: System Initialized.")
	return AntiCheat
end

return AntiCheat