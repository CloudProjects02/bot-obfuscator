-- ts file was dumped and decoded by luarurape - manually by Larpadius
--======================================================
-- GABBY'S DOLLHOUSE TYCOON • AUTO FARM (SAFE v1)
-- ✅ Token logger REMOVED
-- ✅ Fixed FireServer/InvokeServer bugs
-- ✅ Proper toggle loops
-- ✅ XYPHRIX v7.1 blue theme
--======================================================
local LibURL = "https://pastebin.com/raw/kfPd3eCL"
local LibSource = nil
pcall(function() LibSource = game:HttpGet(LibURL) end)
if not LibSource then
	pcall(function() LibSource = request({Url = LibURL, Method = "GET"}).Body end)
end
if not LibSource then warn("❌ Failed to load library") return end

local ok, err = pcall(function()
	local Players = game:GetService("Players")
	local Workspace = game:GetService("Workspace")
	local RS = game:GetService("ReplicatedStorage")
	local TweenService = game:GetService("TweenService")
	local VirtualUser = game:GetService("VirtualUser")
	local Player = Players.LocalPlayer
	local lp = Player

	local Lib = loadstring(LibSource)()
	Lib:CreateWindow("XYPHRIX HUB", "GABBY TYCOON")

	-- ============ STATE ============
	local AutoMainHouse = false
	local AutoAquarium = false
	local AutoLoot = false
	local AutoATM = false
	local AutoTicket = false
	local RunId = 0

	local function GetHRP()
		local c = Player.Character
		return c and c:FindFirstChild("HumanoidRootPart")
	end

	-- ============ SAFE FIRE HELPER ============
	local function SafeFire(remote, ...)
		if not remote then return false end
		local args = {...}
		return pcall(function()
			if remote:IsA("RemoteEvent") then
				remote:FireServer(unpack(args))
			elseif remote:IsA("RemoteFunction") then
				remote:InvokeServer(unpack(args))
			end
		end)
	end

	-- ============ AUTO BUILD: MAIN HOUSE ============
	local function BuildMainHouse()
		local remote = RS:FindFirstChild("TycoonManager_UpgradeBuilding")
		if not remote then
			Lib:Notify("❌", "Remote not found", 2)
			return
		end
		local mainHouse = Workspace:FindFirstChild("World") and Workspace.World:FindFirstChild("Tycoon") and Workspace.World.Tycoon:FindFirstChild("MainHouse")
		if not mainHouse then
			Lib:Notify("❌", "MainHouse not found", 2)
			return
		end
		local built = 0
		for _, folder in ipairs(mainHouse:GetChildren()) do
			if folder:IsA("Folder") then
				for _, building in ipairs(folder:GetChildren()) do
					if building:IsA("Mo

-- Fragment 1
del") then
						if SafeFire(remote, building.Name) then
							built = built + 1
						end
						task.wait(0.1)
					end
				end
			end
		end
		Lib:Notify("🏠", "Built " .. built .. " parts", 2)
	end

	-- ============ AUTO BUILD: AQUARIUM ============
	local function BuildAquarium()
		local remote = RS:FindFirstChild("TycoonManager_UpgradeBuilding")
		if not remote then return end
		local aquarium = Workspace:FindFirstChild("World") and Workspace.World:FindFirstChild("Tycoon") and Workspace.World.Tycoon:FindFirstChild("Aquarium")
		if not aquarium then return end
		local built = 0
		for _, folder in ipairs(aquarium:GetChildren()) do
			if folder:IsA("Folder") then
				for _, building in ipairs(folder:GetChildren()) do
					if building:IsA("Model") then
						if SafeFire(remote, building.Name) then
							built = built + 1
						end
						task.wait(0.1)
					end
				end
			end
		end
		Lib:Notify("🐠", "Built " .. built .. " aquarium parts", 2)
	end

	-- ============ AUTO COLLECT: LOOT COINS ============
	local function CollectLoot()
		local remote = RS:FindFirstChild("TGSWorldLoot_ClaimLoot")
		if not remote then return end
		local pickups = Workspace:FindFirstChild("World") and Workspace.World:FindFirstChild("Pickups") and Workspace.World.Pickups:FindFirstChild("Coins")
		if not pickups then return 0 end
		local collected = 0
		for _, coin in ipairs(pickups:GetChildren()) do
			if coin:IsA("BasePart") then
				if SafeFire(remote, coin) then
					collected = collected + 1
				end
			end
		end
		return collected
	end

	-- ============ AUTO COLLECT: ATM ============
	local function CollectATM()
		local remote = RS:FindFirstChild("ATM_Claim")
		if remote then
			SafeFire(remote)
			return true
		end
		return false
	end

	-- ============ AUTO COLLECT: UGC TICKETS ============
	local function CollectTickets()
		local hrp = GetHRP()
		if not hrp then return 0 end
		local ugcBits = Workspace:FindFirstChild("World") and Workspace.World:FindFirstChild("UGC") and Workspace.World.UGC:FindFirstChild("UGCBits")
		if not ugcBits then return 0 end
		local collected = 0
		for _, bit in ipairs(ugcBits:GetChildren()) do
			if bit:IsA("BasePart") then
				pcall(function()
					hrp.CFrame = bit.CFrame + Vector3.new(0, 3, 0)
				end)
				task.wait(0.2)
				collected = collected + 1
			end
		end
	

-- Fragment 2
	return collected
	end

	-- ============ TOGGLE LOOPS ============
	local function StartMainHouseLoop()
		local myRunId = RunId
		task.spawn(function()
			while AutoMainHouse and RunId == myRunId do
				BuildMainHouse()
				task.wait(2)
			end
		end)
	end

	local function StartAquariumLoop()
		local myRunId = RunId
		task.spawn(function()
			while AutoAquarium and RunId == myRunId do
				BuildAquarium()
				task.wait(2)
			end
		end)
	end

	local function StartLootLoop()
		local myRunId = RunId
		task.spawn(function()
			while AutoLoot and RunId == myRunId do
				local n = CollectLoot()
				if n > 0 then Lib:Notify("🪙", "Collected " .. n .. " coins", 1.5) end
				task.wait(1)
			end
		end)
	end

	local function StartATMLoop()
		local myRunId = RunId
		task.spawn(function()
			while AutoATM and RunId == myRunId do
				if CollectATM() then Lib:Notify("💳", "ATM claimed", 1.5) end
				task.wait(5)
			end
		end)
	end

	local function StartTicketLoop()
		local myRunId = RunId
		task.spawn(function()
			while AutoTicket and RunId == myRunId do
				local n = CollectTickets()
				if n > 0 then Lib:Notify("🎫", "Collected " .. n .. " tickets", 1.5) end
				task.wait(3)
			end
		end)
	end

	-- ============ ANTI-AFK ============
	task.spawn(function()
		Player.Idled:Connect(function()
			pcall(function()
				VirtualUser:CaptureController()
				VirtualUser:ClickButton2(Vector2.new())
			end)
		end)
	end)

	-- ============ GUI: FARM TAB ============
	local FarmPage = Lib:CreatePage("Farm", "🚀")
	Lib:Section(FarmPage, "⚠ SAFE VERSION")
	Lib:Card(FarmPage, "Token logger removed!\nScript by HAFIY", 45)

	Lib:Section(FarmPage, "AUTO BUILD")
	Lib:Toggle(FarmPage, "Auto Build MainHouse", false, function(on)
		AutoMainHouse = on
		RunId = RunId + 1
		if on then StartMainHouseLoop() end
		Lib:Notify("🏠", on and "ON" or "OFF", 1.5)
	end)

	Lib:Toggle(FarmPage, "Auto Build Aquarium", false, function(on)
		AutoAquarium = on
		RunId = RunId + 1
		if on then StartAquariumLoop() end
		Lib:Notify("🐠", on and "ON" or "OFF", 1.5)
	end)

	Lib:Section(FarmPage, "AUTO COLLECT")
	Lib:Toggle(FarmPage, "Auto Loot Coins", false, function(on)
		AutoLoot = on
		RunId = RunId + 1
		if on then StartLootLoop() end
		Lib:Notify("🪙", on and "ON" or "OFF", 1.5)
	end)

	Lib:Toggle(FarmPage, "Auto ATM", f

-- Fragment 3
alse, function(on)
		AutoATM = on
		RunId = RunId + 1
		if on then StartATMLoop() end
		Lib:Notify("💳", on and "ON" or "OFF", 1.5)
	end)

	Lib:Toggle(FarmPage, "Auto UGC Tickets", false, function(on)
		AutoTicket = on
		RunId = RunId + 1
		if on then StartTicketLoop() end
		Lib:Notify("🎫", on and "ON" or "OFF", 1.5)
	end)

	Lib:Section(FarmPage, "MANUAL ACTIONS")
	Lib:Button(FarmPage, "🏠 Build MainHouse Now", function() BuildMainHouse() end)
	Lib:Button(FarmPage, "🐠 Build Aquarium Now", function() BuildAquarium() end)
	Lib:Button(FarmPage, "🪙 Collect Loot Now", function()
		local n = CollectLoot()
		Lib:Notify("🪙", "Collected " .. n, 2)
	end)
	Lib:Button(FarmPage, "💳 Claim ATM Now", function()
		CollectATM()
		Lib:Notify("💳", "ATM claimed", 2)
	end)

	Lib:Section(FarmPage, "PORTAL")
	Lib:Button(FarmPage, "🌀 Server Hop", function()
		Lib:Notify("🌀", "Hopping...", 2)
		task.wait(1)
		local TPS = game:GetService("TeleportService")
		local Http = game:GetService("HttpService")
		local servers = {}
		local url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"
		pcall(function()
			local data = Http:JSONDecode(game:HttpGet(url))
			for _, s in ipairs(data.data) do
				if s.playing < s.maxPlayers and s.id ~= game.JobId then
					table.insert(servers, s.id)
				end
			end
		end)
		if #servers > 0 then
			TPS:TeleportToPlaceInstance(game.PlaceId, servers[math.random(1, #servers)], lp)
		else
			Lib:Notify("❌", "No servers found", 2)
		end
	end)

	-- ============ SETTINGS TAB ============
	local SettingsPage = Lib:CreatePage("Settings", "⚙")
	Lib:Section(SettingsPage, "THEME")
	Lib:Dropdown(SettingsPage, "Theme", {"Blue", "Dark", "Light"}, "Blue", function(v) Lib:SetTheme(v) end)

	-- ============ CREDITS TAB ============
	local CreditsPage = Lib:CreatePage("Credits", "💙")
	Lib:Section(CreditsPage, "ABOUT")
	Lib:Card(CreditsPage, "Gabby's Dollhouse Tycoon\nSafe Auto-Farm v1\n\nScript by HAFIY\n💬 discord.gg/QmzgK8Ct", 80)
	Lib:Button(CreditsPage, "📋 Copy Discord", function()
		if setclipboard then
			setclipboard("https://discord.gg/QmzgK8Ct")
			Lib:Notify("📋", "Copied!", 2)
		end
	end)

	Lib:Notify("💙 Gabby Tycoon", "Safe version loaded!", 3)
end)
if not ok then warn("❌ FAILED:", err) end

-- VM instruction bytes (hex-decoded)
12 a6 00 00 17 53 00 00 12 a6 00 01 17 53 00 01 12 a6 00 02 17 53 00 02 12 a6 00 03 17 53 00 03 02 c3 00 00 02 c3 00 01 26 18 17 53 00 04 02 c3 00 04 02 c3 00 02 26 18 17 53 00 04 02 c3 00 04 02 c3 00 03 26 18 17 53 00 04 02 c3 00 04 0e a9 00 88