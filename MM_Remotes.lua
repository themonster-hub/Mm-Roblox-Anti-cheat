local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Remotes = {}
local AntiCheat
local Config
local SecureFolder

local remotePlayerData = {}
local clickDetectorData = {}
local pendingClientChecks = {}

local ClientCheckRequest
local ClientCheckResponse

local function onPlayerRemoving(player)
	remotePlayerData[player] = nil
	pendingClientChecks[player] = nil

	for _, data in pairs(clickDetectorData) do
		data[player] = nil
	end
end

local function checkSpam(player, remoteName)
	if not Config.Remotes.EventSpam.Enabled then return true end

	local data = remotePlayerData[player]
	if not data then
		data = { requests = {} }
		remotePlayerData[player] = data
	end

	if not data.requests[remoteName] then
		data.requests[remoteName] = {}
	end

	local now = os.clock()
	local requests = data.requests[remoteName]
	local timeFrame = Config.Remotes.EventSpam.TimeFrame
	local maxRequests = Config.Remotes.EventSpam.MaxRequests

	for i = #requests, 1, -1 do
		if now - requests[i] > timeFrame then
			table.remove(requests, i)
		else
			break
		end
	end

	table.insert(requests, now)

	if #requests > maxRequests then
		AntiCheat.FlagPlayer(player, "Remote Spam (" .. remoteName .. ")", Config.Remotes.EventSpam.ViolationPoints)
		return false
	end

	return true
end

function Remotes.WrapRemoteEvent(name)
	local remote = Instance.new("RemoteEvent")
	remote.Name = name
	remote.Parent = SecureFolder

	local wrapper = {}
	function wrapper:Connect(callback)
		remote.OnServerEvent:Connect(function(player, ...)
			if checkSpam(player, name) then
				local success, err = pcall(callback, player, ...)
				if not success then
					warn("[MM_Remotes] Error in " .. name .. " event: " .. tostring(err))
				end
			end
		end)
	end
	
	function wrapper:FireAllClients(...)
		remote:FireAllClients(...)
	end
	
	function wrapper:FireClient(player, ...)
		remote:FireClient(player, ...)
	end
	
	return wrapper
end

function Remotes.WrapRemoteFunction(name)
	local remote = Instance.new("RemoteFunction")
	remote.Name = name
	remote.Parent = SecureFolder

	local wrapper = {}
	function wrapper:SetCallback(callback)
		remote.OnServerInvoke = function(player, ...)
			if checkSpam(player, name) then
				local success, result = pcall(callback, player, ...)
				if not success then
					warn("[MM_Remotes] Error in " .. name .. " function: " .. tostring(result))
					return nil
				end
				return result
			else
				return nil
			end
		end
	end
	return wrapper
end

function Remotes.SecureClickDetector(clickDetector)
	if not clickDetector:IsA("ClickDetector") then
		warn("[MM_Remotes] SecureClickDetector expected a ClickDetector, got", clickDetector:GetFullName())
		return
	end
    if clickDetector:GetAttribute("MMSecured") then return end

	clickDetectorData[clickDetector] = clickDetectorData[clickDetector] or {}
	
	clickDetector.MouseClick:Connect(function(player)
		if not Config.AutoClicker.Enabled then return end

		local data = clickDetectorData[clickDetector]
		data[player] = data[player] or {}
		
		local now = os.clock()
		local requests = data[player]
		local timeFrame = Config.AutoClicker.TimeFrame
		local maxRequests = Config.AutoClicker.MaxClicks

		for i = #requests, 1, -1 do
			if now - requests[i] > timeFrame then table.remove(requests, i) else break end
		end
		
		table.insert(requests, now)
		
		if #requests > maxRequests then
			AntiCheat.FlagPlayer(player, "Auto-Clicker", Config.AutoClicker.ViolationPoints)
		end
	end)
    clickDetector:SetAttribute("MMSecured", true)
end

local function handleClientResponse(player, nonce, checkType, result)
	local pending = pendingClientChecks[player]
	if not (pending and pending[nonce] and pending[nonce] == checkType) then
		AntiCheat.FlagPlayer(player, "Invalid Client Response", 50)
		return
	end

	pending[nonce] = nil
	
	if checkType == "GuiCheck" then
		if Config.GuiInjection.Enabled and result == true then
			AntiCheat.FlagPlayer(player, "GUI Injection", Config.GuiInjection.ViolationPoints)
		end
	elseif checkType == "ExecutorCheck" then
		if Config.ExecutorDetection.Enabled and result == true then
			AntiCheat.FlagPlayer(player, "Executor Environment", Config.ExecutorDetection.ViolationPoints)
		end
	end
end

function Remotes.RequestClientCheck(player, checkType)
	local nonce = math.random(1, 1e9)
	pendingClientChecks[player] = pendingClientChecks[player] or {}
	pendingClientChecks[player][nonce] = checkType
	
	ClientCheckRequest:FireClient(player, checkType, nonce)
	
	task.delay(10, function()
		if pendingClientChecks[player] and pendingClientChecks[player][nonce] then
			pendingClientChecks[player][nonce] = nil
			AntiCheat.FlagPlayer(player, "No Client Response", 25)
		end
	end)
end

function Remotes.Init(AC)
	AntiCheat = AC
	Config = AntiCheat.Config

	SecureFolder = ReplicatedStorage:FindFirstChild(Config.Remotes.SecureRemotesFolder)
	if not SecureFolder then
		SecureFolder = Instance.new("Folder")
		SecureFolder.Name = Config.Remotes.SecureRemotesFolder
		SecureFolder.Parent = ReplicatedStorage
	end

	ClientCheckRequest = Remotes.WrapRemoteEvent("MM_ClientCheckRequest")
	ClientCheckResponse = Remotes.WrapRemoteFunction("MM_ClientCheckResponse")
	
	ClientCheckResponse:SetCallback(handleClientResponse)

	Players.PlayerAdded:Connect(function(player) pendingClientChecks[player] = {} end)
	Players.PlayerRemoving:Connect(onPlayerRemoving)
end

return Remotes