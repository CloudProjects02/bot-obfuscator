--[[
   luaRURAPE https://discord.gg/9vVsmvRNRd
    took 23682ms to log everything
   usage: .l
   links
    (none captured)
]]
local httpres_1 = game:HttpGet("https://raw.githubusercontent.com/Bruhiscrazy/codespaces-blank/refs/heads/main/Bruhui")
local load_2 = loadstring(game:HttpGet("https://raw.githubusercontent.com/Bruhiscrazy/codespaces-blank/refs/heads/main/Bruhui"))()
local MakeWindow_3 = load_2:MakeWindow({
HidePremium = false,
Name = "FTAP Hub",
SaveConfig = false
})
local MakeTab_4 = MakeWindow_3:MakeTab({
PremiumOnly = false,
Name = "Scanner",
Icon = "rbxassetid://4483345998"
})
local MakeTab_5 = MakeWindow_3:MakeTab({
Name = "Reach/Grabs",
Icon = "rbxassetid://13255969414"
})
local MakeTab_6 = MakeWindow_3:MakeTab({
Name = "Player",
Icon = "rbxassetid://6031075927"
})
local Players_7 = game:GetService("Players")
local RunService_8 = game:GetService("RunService")
local UserInputService_9 = game:GetService("UserInputService")
local AddLabel_10 = MakeTab_4:AddLabel("some executers may not work for some scripts so use VPN")
local AddLabel_11 = MakeTab_4:AddLabel("staffs has better scripts then you dont attack")
local AddLabel_12 = MakeTab_4:AddLabel("they have test scripts or they can kick you if using their scripts")
local AddLabel_13 = MakeTab_4:AddLabel("they dont have admin to this script")
local AddLabel_14 = MakeTab_4:AddLabel("This script is very weak and wait for ui to load dont spam")
local AddLabel_15 = MakeTab_4:AddLabel("BLITZ,VERBAL,POSRAL,COSMIC STAFF WATCH scanner button")
local AddButton_16 = MakeTab_4:AddButton({
Name = "🔍 Refresh Scan",
Callback = function(...)
local MakeNotification_17 = load_2:MakeNotification({
Time = 2,
Name = "Scanning",
Content = "Scanning all players..."
})
local MakeNotification_18 = load_2:MakeNotification({
Time = 3,
Name = "✅ Safe",
Content = "No admins detected!"
})
local SetText_19 = AddLabel_15:SetText("✅ No staff found")
local SetText_20 = AddLabel_10:SetText("✅ Safe")
local MakeNotification_21 = load_2:MakeNotification({
Time = 2,
Name = "Scan Complete",
Content = "Checked 1 players"
})
end
})
local AddButton_22 = MakeTab_4:AddButton({
Name = "Ftap Blitz (Key system)",
Callback = function(...)
local httpres_23 = game:HttpGet("https://rawscripts.net/raw/Fling-Things-and-People-FTAP-BLITZ-43504")
local load_24 = loadstring(game:HttpGet("https://rawscripts.net/raw/Fling-Things-and-People-FTAP-BLITZ-43504"))()
local MakeNotification_25 = load_2:MakeNotification({
Time = 2,
Name = "✅ Loaded",
Content = "Script Ftap Blitz!"
})
end
})
local AddButton_26 = MakeTab_4:AddButton({
Name = "👁️Verbal New OP Hub (keyless + CustomMenu)",
Callback = function(...)
local httpres_27 = game:HttpGet("https://raw.githubusercontent.com/VerbalHubz/scripts/refs/heads/main/op%20hub")
local load_28 = loadstring(game:HttpGet("https://raw.githubusercontent.com/VerbalHubz/scripts/refs/heads/main/op%20hub"))()
local MakeNotification_29 = load_2:MakeNotification({
Time = 2,
Name = "✅ Loaded",
Content = "Script Verbal OP Hub!"
})
end
})
local AddButton_30 = MakeTab_4:AddButton({
Name = "VerbalV3 Old (keyless)",
Callback = function(...)
local httpres_31 = game:HttpGet("https://raw.githubusercontent.com/VerbalHubz/Verbal-Hub/refs/heads/main/Verbal%20Hub%20V3")
local load_32 = loadstring(game:HttpGet("https://raw.githubusercontent.com/VerbalHubz/Verbal-Hub/refs/heads/main/Verbal%20Hub%20V3"))()
local MakeNotification_33 = load_2:MakeNotification({
Time = 2,
Name = "✅ Loaded",
Content = "Script Verbal!"
})
end
})
local AddButton_34 = MakeTab_4:AddButton({
Name = "RuHub (Key: escooter)",
Callback = function(...)
local httpres_35 = game:HttpGet("https://rawscripts.net/raw/Fling-Things-and-People-RuHUB-OP-FTAP-SCRIPT-UPDATED-39324")
local load_36 = loadstring(game:HttpGet("https://rawscripts.net/raw/Fling-Things-and-People-RuHUB-OP-FTAP-SCRIPT-UPDATED-39324"))()
local MakeNotification_37 = load_2:MakeNotification({
Time = 2,
Name = "✅ Loaded",
Content = "Script RuHub!"
})
end
})
local AddButton_38 = MakeTab_4:AddButton({
Name = "Posral (IP Grabber maybe) (KeySystem)",
Callback = function(...)
local httpres_39 = game:HttpGet("https://rawscripts.net/raw/Fling-Things-and-People-Posral-79224")
local load_40 = loadstring(game:HttpGet("https://rawscripts.net/raw/Fling-Things-and-People-Posral-79224"))()
local MakeNotification_41 = load_2:MakeNotification({
Time = 2,
Name = "✅ Loaded",
Content = "Script Posral!"
})
end
})
local AddButton_42 = MakeTab_4:AddButton({
Name = "YukiHub (Exposes you in chat) (keyless)",
Callback = function(...)
local httpres_43 = game:HttpGet("https://rawscripts.net/raw/Fling-Things-and-People-Yuki-Hub-Ftap-BETA-75713")
local load_44 = loadstring(game:HttpGet("https://rawscripts.net/raw/Fling-Things-and-People-Yuki-Hub-Ftap-BETA-75713"))()
local MakeNotification_45 = load_2:MakeNotification({
Time = 2,
Name = "✅ Loaded",
Content = "Script YukiHub beta!"
})
end
})
local AddButton_46 = MakeTab_4:AddButton({
Name = "Comisc Hub (Exposes you in chat) (keyless)",
Callback = function(...)
local httpres_47 = game:HttpGet("https://rawscripts.net/raw/Fling-Things-and-People-CRACKED-COSMICHUB-FTAP-73528")
local load_48 = loadstring(game:HttpGet("https://rawscripts.net/raw/Fling-Things-and-People-CRACKED-COSMICHUB-FTAP-73528"))()
local MakeNotification_49 = load_2:MakeNotification({
Time = 2,
Name = "✅ Loaded",
Content = "Script CosmicHub!"
})
end
})
local AddButton_50 = MakeTab_4:AddButton({
Name = "Phoenix Hub (Free version) (keyless)",
Callback = function(...)
local httpres_51 = game:HttpGet("https://raw.githubusercontent.com/kiberblogr-coder/phoenix-hub/main/hub.lua")
local load_52 = loadstring(game:HttpGet("https://raw.githubusercontent.com/kiberblogr-coder/phoenix-hub/main/hub.lua"))()
local MakeNotification_53 = load_2:MakeNotification({
Time = 2,
Name = "✅ Loaded",
Content = "Script Phoenix!"
})
end
})
local AddButton_54 = MakeTab_4:AddButton({
Name = "K Hub (Key: ftap k hub beta)",
Callback = function(...)
local httpres_55 = game:HttpGet("https://rawscripts.net/raw/Fling-Things-and-People-Ftap-k-hub-73977")
local load_56 = loadstring(game:HttpGet("https://rawscripts.net/raw/Fling-Things-and-People-Ftap-k-hub-73977"))()
local MakeNotification_57 = load_2:MakeNotification({
Time = 2,
Name = "✅ Loaded",
Content = "Script K Hub!"
})
end
})
local AddButton_58 = MakeTab_4:AddButton({
Name = "SRV9 (key system)",
Callback = function(...)
local httpres_59 = game:HttpGet("https://rawscripts.net/raw/Fling-Things-and-People-SRV9-Fling-Things-and-people-55961")
local load_60 = loadstring(game:HttpGet("https://rawscripts.net/raw/Fling-Things-and-People-SRV9-Fling-Things-and-people-55961"))()
local MakeNotification_61 = load_2:MakeNotification({
Time = 2,
Name = "✅ Loaded",
Content = "Script SRV9!"
})
end
})
local AddButton_62 = MakeTab_4:AddButton({
Name = "BloodyV2 (Exposes you in chat) (keyless)",
Callback = function(...)
local httpres_63 = game:HttpGet("https://rawscripts.net/raw/Fling-Things-and-People-*-V2-62163")
local load_64 = loadstring(game:HttpGet("https://rawscripts.net/raw/Fling-Things-and-People-*-V2-62163"))()
local MakeNotification_65 = load_2:MakeNotification({
Time = 2,
Name = "✅ Loaded",
Content = "Script bloodyV2!"
})
end
})
local AddButton_66 = MakeTab_4:AddButton({
Name = "TcoHub (Key system)",
Callback = function(...)
local httpres_67 = game:HttpGet("https://rawscripts.net/raw/Fling-Things-and-People-tco-hub-75571")
local load_68 = loadstring(game:HttpGet("https://rawscripts.net/raw/Fling-Things-and-People-tco-hub-75571"))()
local MakeNotification_69 = load_2:MakeNotification({
Time = 2,
Name = "✅ Loaded",
Content = "Script tcohub!"
})
end
})
local AddButton_70 = MakeTab_4:AddButton({
Name = "Mobile Tab in air",
Callback = function(...)
local httpres_71 = game:HttpGet("https://rawscripts.net/raw/Fling-Things-and-People-tab-button-by-Camakatikk-63397")
local load_72 = loadstring(game:HttpGet("https://rawscripts.net/raw/Fling-Things-and-People-tab-button-by-Camakatikk-63397"))()
local MakeNotification_73 = load_2:MakeNotification({
Time = 2,
Name = "✅ Loaded",
Content = "Script Tab!"
})
end
})
local AddButton_74 = MakeTab_4:AddButton({
Name = "IY script",
Callback = function(...)
local httpres_75 = game:HttpGet("https://rawscripts.net/raw/Universal-Script-Infinite-yield-73483")
local load_76 = loadstring(game:HttpGet("https://rawscripts.net/raw/Universal-Script-Infinite-yield-73483"))()
local MakeNotification_77 = load_2:MakeNotification({
Time = 2,
Name = "✅ Loaded",
Content = "Script IY!"
})
end
})
local conn_78 = Players_7.PlayerAdded:Connect(function(player)
local SetText_79 = AddLabel_15:SetText("✅ No staff found")
local SetText_80 = AddLabel_10:SetText("✅ Safe")
end)
local conn_81 = Players_7.PlayerRemoving:Connect(function(player)
local SetText_82 = AddLabel_15:SetText("✅ No staff found")
local SetText_83 = AddLabel_10:SetText("✅ Safe")
end)
local Players_7 = game:GetService("Players")
local workspace = game:GetService("Workspace")
local UserInputService_9 = game:GetService("UserInputService")
local RunService_8 = game:GetService("RunService")
local Debris_84 = game:GetService("Debris")
local ReplicatedStorage_85 = game:GetService("ReplicatedStorage")
local ScreenGui_86 = Instance.new("ScreenGui")
ScreenGui_86.ResetOnSpawn = false
local ImageButton_87 = Instance.new("ImageButton")
ImageButton_87.Size = UDim2.new(0, 0, 45, 0)
ImageButton_87.Position = UDim2.new(1, 0, - 70, 0)
ImageButton_87.Image = "rbxassetid://97166444"
ImageButton_87.ImageTransparency = 0.2
ImageButton_87.BackgroundTransparency = 1
ImageButton_87.ImageColor3 = Color3.fromRGB(142, 142, 142)
ImageButton_87.Visible = false
ImageButton_87.Parent = ScreenGui_86
local ImageLabel_88 = Instance.new("ImageLabel")
ImageLabel_88.Size = UDim2.new(1, 0, 0, 0)
ImageLabel_88.Image = "rbxassetid://9603831913"
ImageLabel_88.BackgroundTransparency = 1
ImageLabel_88.Parent = ImageButton_87
local ImageButton_89 = Instance.new("ImageButton")
ImageButton_89.Size = UDim2.new(0, 0, 45, 0)
ImageButton_89.Position = UDim2.new(1, 0, - 70, 0)
ImageButton_89.Image = "rbxassetid://97166444"
ImageButton_89.ImageTransparency = 0.2
ImageButton_89.BackgroundTransparency = 1
ImageButton_89.ImageColor3 = Color3.fromRGB(142, 142, 142)
ImageButton_89.Visible = false
ImageButton_89.Parent = ScreenGui_86
local ImageLabel_90 = Instance.new("ImageLabel")
ImageLabel_90.Size = UDim2.new(1, 0, 0, 0)
ImageLabel_90.Image = "rbxassetid://9603826756"
ImageLabel_90.BackgroundTransparency = 1
ImageLabel_90.Parent = ImageButton_89
local conn_91 = workspace.ChildAdded:Connect(function(child)
end)
local conn_92 = workspace.ChildRemoved:Connect(function(child)
end)
local conn_93 = ImageButton_87.InputBegan:Connect(function(input, gameProcessed)
end)
local conn_94 = ImageButton_87.InputEnded:Connect(function(input, gameProcessed)
end)
local conn_95 = ImageButton_89.InputBegan:Connect(function(input, gameProcessed)
end)
local conn_96 = ImageButton_89.InputEnded:Connect(function(input, gameProcessed)
end)
local conn_97 = UserInputService_9.InputChanged:Connect(function(input, gameProcessed)
end)
local AddLabel_98 = MakeTab_5:AddLabel("dm for source dont ask for my whole script")
local AddLabel_99 = MakeTab_5:AddLabel("dont turn off the gamepass reach it wont work when killed")
local AddToggle_100 = MakeTab_5:AddToggle({
Callback = function(...)
end,
Name = "Reach (Free Gamepass 30 Studs)",
Default = false
})
local AddSection_101 = MakeTab_5:AddSection({
Name = "Further extend"
})
local AddToggle_102 = MakeTab_5:AddToggle({
Callback = function(...)
ImageButton_87.Visible = nil
ImageButton_87.Active = nil
ImageButton_89.Visible = nil
ImageButton_89.Active = nil
end,
Name = "Further Extend",
Default = false
})
local AddSlider_103 = MakeTab_5:AddSlider({
Min = 3,
Name = "Extend Amount",
ValueName = "Studs",
Max = 25,
Increment = 1,
Callback = function(...)
end,
Default = 3
})
local AddSection_104 = MakeTab_5:AddSection({
Name = "Throw"
})
local AddSlider_105 = MakeTab_5:AddSlider({
Min = 100,
Name = "Super Throw",
ValueName = "Power",
Max = 10000,
Increment = 50,
Callback = function(...)
end,
Default = 1000
})
local AddToggle_106 = MakeTab_5:AddToggle({
Callback = function(...)
end,
Name = "Enable Super Throw",
Default = false
})
local AddSection_107 = MakeTab_5:AddSection({
Name = "Silent aim"
})
local AddToggle_108 = MakeTab_5:AddToggle({
Callback = function(...)
end,
Name = "Enable Silent Aim",
Default = false
})
local AddSlider_109 = MakeTab_5:AddSlider({
Min = 1,
Name = "Silent Aim Distance",
ValueName = "Studs",
Max = 50,
Increment = 1,
Callback = function(...)
end,
Default = 30
})
local AddSection_110 = MakeTab_6:AddSection({
Name = "Movement"
})
local Players_7 = game:GetService("Players")
local RunService_8 = game:GetService("RunService")
local UserInputService_9 = game:GetService("UserInputService")
local AddToggle_111 = MakeTab_6:AddToggle({
Callback = function(...)
end,
Name = "Walkspeed",
Default = false
})
local AddSlider_112 = MakeTab_6:AddSlider({
Min = 1,
Name = "Speed Multiplier",
Max = 50,
Increment = 1,
Callback = function(...)
end,
Default = 5
})
local AddToggle_113 = MakeTab_6:AddToggle({
Callback = function(...)
end,
Name = "Infinite Jump",
Default = false
})
local AddSlider_114 = MakeTab_6:AddSlider({
Min = 50,
Name = "Jump Power",
Max = 500,
Increment = 10,
Callback = function(...)
end,
Default = 100
})
local AddToggle_115 = MakeTab_6:AddToggle({
Callback = function(...)
end,
Name = "Noclip",
Default = false
})
local MakeTab_116 = MakeWindow_3:MakeTab({
Name = "⭐️Invincibility",
Icon = "rbxassetid://4483362458"
})
local Players_7 = game:GetService("Players")
local ReplicatedStorage_85 = game:GetService("ReplicatedStorage")
local conn_117 = Character.DescendantAdded:Connect(function(desc)
end)
local conn_118 = Head.ChildAdded:Connect(function(child)
end)
local conn_119 = LocalPlayer.CharacterAdded:Connect(function(character)
local conn_120 = Model.DescendantAdded:Connect(function(desc)
end)
local conn_121 = Head.ChildAdded:Connect(function(child)
end)
end)
local ok_1, err_2 = pcall(function()
local AddSection_122 = MakeTab_116:AddSection({
Name = "Counter Attack Protection"
})
local AddToggle_123 = MakeTab_116:AddToggle({
Callback = function(...)
end,
Name = "Auto Counter Attack",
Default = false
})
local AddDropdown_124 = MakeTab_116:AddDropdown({
Callback = function(...)
end,
Options = {"Repulsion", "Freeze", "Death", "Kick"},
Name = "Counter Mode",
Default = "Repulsion"
})
end)
local AddSection_125 = MakeTab_116:AddSection({
Name = "Anti"
})
local Players_7 = game:GetService("Players")
local workspace = game:GetService("Workspace")
local ReplicatedStorage_85 = game:GetService("ReplicatedStorage")
local RunService_8 = game:GetService("RunService")