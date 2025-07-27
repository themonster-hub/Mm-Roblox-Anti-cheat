local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")

local secureFolderName = "SecureRemotes"
local secureFolder = ReplicatedStorage:WaitForChild(secureFolderName)

local clientCheckRequest = secureFolder:WaitForChild("MM_ClientCheckRequest")
local clientCheckResponse = secureFolder:WaitForChild("MM_ClientCheckResponse")

local function checkForInjectedGuis()
	local success, guis = pcall(function() return CoreGui:GetChildren() end)
	if not success then return true end

	for _, gui in ipairs(guis) do
		if gui:IsA("ScreenGui") and not gui.ResetOnSpawn then
			return true
		end
	end
	return false
end

local function checkForExecutorGlobals()
	local suspiciousGlobals = {
		"getgenv", "getrenv", "getsenv", "getmenv", "getreg", "getclipboard",
		"setclipboard", "writefile", "readfile", "appendfile", "isfilesynced",
		"delfile", "listfiles", "queue_on_teleport", "loadstring", "setthreadidentity",
		"is_synapse_function", "identifyexecutor", "is_fluxus_function", "Drawing", "Orion"
	}
	for _, name in ipairs(suspiciousGlobals) do
		if rawget(_G, name) then
			return true
		end
	end
	
	local mt = getrawmetatable(game)
	if mt and not mt.__metatable then
		return true
	end
	
	return false
end

clientCheckRequest.OnClientEvent:Connect(function(checkType, nonce)
	local result = false
	if checkType == "GuiCheck" then
		result = checkForInjectedGuis()
	elseif checkType == "ExecutorCheck" then
		result = checkForExecutorGlobals()
	end
	
	clientCheckResponse:InvokeServer(nonce, checkType, result)
end)