print("loading")
wait(0,1)
local v0 = game:IsLoaded()
local v1 = game:GetService("Workspace")
v1.Stores.WoodRUs.Parts.PREMIUMSELECTION.SurfaceGui.TextLabel.Text = "Dark X V5.0"
pcall(function()
    _G.玩家 = game.Players
    _G.自己 = _G.玩家.LocalPlayer
    _G.自己角色 = _G.自己.Character
    _G.自己身体 = _G.自己角色.Humanoid
    _G.自己的方块 = _G.自己角色.HumanoidRootPart
    _G.土地 = game.Workspace.Properties
    return
end)
spawn(function()
    local v2 = task.wait(0,1)
    pcall(function()
    _G.玩家 = game.Players
    _G.自己 = _G.玩家.LocalPlayer
    _G.自己角色 = _G.自己.Character
    _G.自己身体 = _G.自己角色.Humanoid
    _G.自己的方块 = _G.自己角色.HumanoidRootPart
    _G.土地 = game.Workspace.Properties
    return
end)
    return
end)
local v2, v3, v4 = game:HttpGet("https://pastebin.com/raw/gfRaKGuw")
local v5 = loadstring(v2)
local v6 = v5(v2)
wait(v3)
_G.岩浆 = nil
pcall(function()
    local v7, v8 = Workspace.Region_Volcano:GetChildren()
    local v9 = r4:FindFirstChild("Lava")
    local v10 = CFrame.new(-1675,2002, 255,002533, 1284,19983, 0,866007268, 0, 0,500031412, 0, 1, 0, -0,500031412, 0, 0,866007268)
    wait(v10)
    _G.岩浆 = r4.Lava
    v11, v12 = next(v7, v8)
    if v11 ~= nil then v8 = v11 end
    local v13 = Vector3.new(0, 0, 0)
    _G.岩浆.Size = v13
    return
end)
return _G.自己:Kick("you are using old dark x")
return ...
wait(0,2)
spawn(function()
    local v10, v11 = _G.自己.PlayerGui:GetChildren()
    local v12, v13 = r4:GetDescendants()
    local v14 = Instance.new("UICorner", r9)
    local v15 = UDim.new(0, 5)
    v14.CornerRadius = v15
    r9:Destroy()
    local v16 = r9:IsA("TextButton")
    local v17 = r9:IsA("Frame")
    local v18 = r9:IsA("ScrollingFrame")
    local v19 = Color3.fromRGB(0, 0, 0)
    r9.BackgroundColor3 = v19
    local v20 = r9:IsA("TextLabel")
    local v21 = r9:IsA("TextButton")
    local v22 = r9:IsA("TextBox")
    local v23 = Color3.fromRGB(225, 225, 225)
    r9.TextColor3 = v23
    local v24 = Color3.fromRGB(20, 20, 20)
    r9.BackgroundColor3 = v24
    v25, v26 = next(v12, v13)
    if v25 ~= nil then v13 = v25 end
    v27, v28 = next(v10, v11)
    if v27 ~= nil then v11 = v27 end
    return
end)
local v10 = game:GetService("ReplicatedStorage")
local v11 = v10:WaitForChild("LoadSaveRequests")
local v12 = v11:WaitForChild("GetMetaData")
v12:InvokeServer(_G.自己)
local v13 = {}
local v14 = game:GetService("Players")
local v15 = v14.LocalPlayer:GetMouse()
local v16 = {}
v16.传送的玩家 = nil
v16.正在飞行 = false
v16.飞行速度 = 200
v16.飞行 = false
v16.终日白天 = false
v16.终日黑夜 = false
v16.消除雾 = false
local v17 = {}
v17 = {"Generic"}
v16.选择的树 = v17
v16.带来树的数量 = 1
v16.树放置的地点 = nil
v16.大力 = false
v16.停止砍树 = false
v16.选择的锯木机 = nil
v16.存档 = 1
v16.快速加载 = false
v16.擦去的东西 = "Structure"
v16.擦去的玩家 = _G.自己.Name
v16.自动购买的地点 = nil
v16.自动购买的数量 = 1
v16.自动购买的物品 = nil
v16.自动购买停止 = false
v16.商店名字 = "All"
v16.行走速度 = 50
v16.跳跃提升 = 100
v16.复制斧头数量 = 1
v16.自动复制斧头 = false
v16.传送的玩家 = _G.自己.Name
v16.传送停止 = false
v16.物品框 = nil
v16.停止整理 = false
v16.正在处理树 = false
v16.正在整理物品 = false
v16.整理物品X = 5
v16.整理物品Z = 5
v16.木头竖着传送 = false
v16.带来幻影拿斧头 = nil
v16.汽车的颜色 = nil
v16.停止生成车 = false
v16.正在生成车 = false
v16.自动填充的树 = nil
v16.油漆的锯木机 = nil
v16.复制土地到玩家 = nil
v16.复制的存档 = nil
v16.复制基地等待加载 = false
v16.复制时间 = 1
v16.使用自己时间 = false
v16.自动获得鲨鱼 = false
v16.处理砍好的木头 = false
v16.删除所有商店物品 = false
v16.自动卖标志牌 = false
v16.杀死的玩家 = nil
v16.杀死的方法 = nil
v16.杀死的工具 = nil
v16.选择的蓝图 = "Floor2"
v16.水中无敌 = false
v16.自动砍 = false
v16.自动砍的链接 = nil
v16.有超级建造的存档 = 1
v16.复制过去的存档 = 1
v16.斧头飞行 = nil
v16.斧头掉落 = nil
v16.自动砍开启 = false
v16.自动捡斧头 = false
v16.斧头类型 = nil
v16.超级电线 = false
v16.树的大小 = "big"
v16.存档大小 = 1
v16.复制木头 = false
v16.无限跳跃 = false
v16.自动复制标志 = false
v16.复制标志的玩家 = nil
v16.自动填充的玩家 = _G.自己
v16.保存基地的玩家 = _G.自己
v16.自动建造的木头 = nil
_G.菜单 = v16
local v18 = {}
local v19 = game:GetService("Players")
local v20 = v19.LocalPlayer:GetMouse()
local v21 = {}
local v22 = {}
local v23 = {}
v18.CurrentNoti = nil
v18.CurrentColorPicker = nil
v18.CurrentTab = nil
v18.Tabs = v23
v18.flags = v22
v18.Connections = v21
v18.Destroyed = false
SwitchTab = function(p0, p1)
    return
    return
    local v24 = {}
    v24 = {p0, p1}
    upvalue_1.CurrentTab = v24
    p0.Title.TextTransparency = 0
    p0.Icon.ImageTransparency = 0
    p1.Visible = true
    return
    upvalue_0 = true
    upvalue_1.CurrentTab[2].Visible = false
    local v25 = {}
    v25.ImageTransparency = 0
    Tween(p0.Icon, 0,2, v25)
    local v26 = {}
    v26.TextTransparency = 0
    Tween(p0.Title, 0,2, v26)
    local v27 = {}
    v27.ImageTransparency = 0,65
    Tween(upvalue_1.CurrentTab[1].Icon, 0,2, v27)
    local v28 = {}
    v28.TextTransparency = 0,65
    Tween(upvalue_1.CurrentTab[1].Title, 0,2, v28)
    p1.Visible = true
    task.wait(0,2)
    local v29 = {}
    v29 = {p0, p1}
    upvalue_1.CurrentTab = v29
    upvalue_0 = false
    return
end
Drag = function(p0, p1)
    p0.InputBegan:Connect(function(p0)
    upvalue_0 = true
    upvalue_1 = p0.Position
    upvalue_2 = upvalue_3.Position
    p0.Changed:Connect(function()
    upvalue_1 = false
    return
end)
    return
end)
    nil.InputChanged:Connect(function(p0)
    upvalue_0 = p0
    return
end)
    local v24 = game:GetService("UserInputService")
    v24.InputChanged:Connect(function(p0)
    upvalue_2(p0)
    return
end)
    return
end
Pop = function(p0)
    local v24 = UDim2.new(0, 10, 0, 10)
    p0.Size = p0.Size - v24
    p0.TextSize = 0
    local v25 = {}
    v25.Size = p0.Size
    Tween(p0, 0,2, v25)
    local v26 = {}
    v26.TextSize = 15
    Tween(p0, 0,2, v26)
    task.wait(0,2)
    local v27 = {}
    v27.TextSize = 13
    Tween(p0, 0,2, v27)
    return
end
Tween = function(p0, p1, p2, ...)
    local v24 = game:GetService("TweenService")
    local v25 = TweenInfo.new(v24)
    local v26 = v24:Create(p0, v25, p2)
    v26:Play()
    return
end
v18.GetState = function(p0, p1)
    return upvalue_0.flags[p1].State
end
v18.UpdateToggle = function(p0, p1, p2)
    local v24 = upvalue_0:GetState(p1)
    local v25 = upvalue_0:GetState(p1)
    return
    print("Test1")
    upvalue_0.flags[p1]:SetState(not v24)
    return
end
v18.Create = function(p0, p1)
    assert(p1, "A title is required")
    local v24 = {}
    local v25 = Color3.fromRGB(24, 24, 24)
    v24.Background = v25
    local v26 = Color3.fromRGB(10, 10, 10)
    v24.Accent = v26
    local v27 = Color3.fromRGB(20, 20, 20)
    v24.LightContrast = v27
    local v28 = Color3.fromRGB(14, 14, 14)
    v24.DarkContrast = v28
    local v29 = Color3.fromRGB(255, 255, 255)
    v24.TextColor = v29
    local v30 = Color3.fromRGB(0, 0, 0)
    v24.Glow = v30
    pcall(function()
    local v31 = game:GetService("Players")
    local v32 = v31.LocalPlayer.PlayerGui.FindFirstChild(v31.LocalPlayer.PlayerGui, "Aurora")
    local v33 = game:GetService("Players")
    local v34 = v33.LocalPlayer.PlayerGui.FindFirstChild(v33.LocalPlayer.PlayerGui, "Aurora")
    v34:Destroy()
    local v35 = game:GetService("CoreGui")
    local v36 = v35:FindFirstChild("Aurora")
    local v37 = game:GetService("CoreGui")
    local v38 = v37:FindFirstChild("Aurora")
    v38:Destroy()
    return
end)
    local v31 = Instance.new("ScreenGui")
    local v32 = Instance.new("Frame")
    local v33 = Instance.new("UICorner")
    local v34 = Instance.new("Frame")
    local v35 = Instance.new("UICorner")
    local v36 = Instance.new("TextLabel")
    local v37 = Instance.new("Frame")
    local v38 = Instance.new("Frame")
    local v39 = Instance.new("UICorner")
    local v40 = Instance.new("Frame")
    local v41 = Instance.new("ImageLabel")
    local v42 = Instance.new("ScrollingFrame")
    local v43 = Instance.new("UIListLayout")
    local v44 = Instance.new("ScreenGui")
    v44.Name = "Close"
    local v45 = game:GetService("CoreGui")
    v44.Parent = v45
    v44.ResetOnSpawn = false
    v31.Name = "Aurora"
    local v46 = game:WaitForChild("CoreGui")
    v31.Parent = v46
    v31.ResetOnSpawn = false
    v32.Name = "Main"
    v32.Parent = v31
    v32.BackgroundColor3 = v24.Background
    v32.BorderSizePixel = 0
    local v47 = UDim2.new(0,352971852, 0, 0,3160173, 0)
    v32.Position = v47
    local v48 = UDim2.new(0, 564, 0, 340)
    v32.Size = v48
    v32.ClipsDescendants = false
    v32.Active = true
    v32.Draggable = true
    local v49 = Instance.new("TextButton")
    v49.Name = "Open"
    v49.Parent = v44
    local v50 = Color3.fromRGB(25, 25, 25)
    v49.BackgroundColor3 = v50
    local v51 = UDim2.new(0,00829315186, 0, 0,31107837, 0)
    v49.Position = v51
    local v52 = UDim2.new(0, 61, 0, 32)
    v49.Size = v52
    v49.Font = Enum.Font.SourceSans
    v49.Text = "Open/Close"
    local v53 = Color3.fromRGB(255, 255, 255)
    v49.TextColor3 = v53
    v49.TextSize = 14
    v49.Active = true
    v49.Draggable = true
    v49.MouseButton1Click:Connect(function()
    upvalue_0.Enabled = not upvalue_0.Enabled
    return
end)
    local v54 = UDim.new(0, 5)
    v33.CornerRadius = v54
    v33.Name = "MainC"
    v33.Parent = v32
    v34.Name = "Top"
    v34.Parent = v32
    v34.BackgroundColor3 = v24.Accent
    v34.BorderSizePixel = 0
    local v55 = UDim2.new(0,000134948292, 0, -0,00162963872, 0)
    v34.Position = v55
    local v56 = UDim2.new(0, 563, 0, 30)
    v34.Size = v56
    v34.ZIndex = 3
    local v57 = UDim.new(0, 5)
    v35.CornerRadius = v57
    v35.Name = "TopC"
    v35.Parent = v34
    v36.Name = "Title"
    v36.Parent = v34
    v36.BackgroundColor3 = v24.TextColor
    v36.BackgroundTransparency = 1
    v36.BorderSizePixel = 0
    local v58 = UDim2.new(1,08410582E-07, 0, 0,0333333351, 0)
    v36.Position = v58
    local v59 = UDim2.new(0, 553, 0, 27)
    v36.Size = v59
    v36.ZIndex = 3
    v36.Font = Enum.Font.GothamBold
    local v60 = string.format("  %s", p1)
    v36.Text = v60
    v36.TextColor3 = v24.TextColor
    v36.TextSize = 15
    v36.TextXAlignment = Enum.TextXAlignment.Left
    v37.Name = "TopBar"
    v37.Parent = v32
    v37.BackgroundColor3 = v24.Accent
    v37.BorderSizePixel = 0
    local v61 = UDim2.new(0,001907998, 0, 0,0513115376, 0)
    v37.Position = v61
    local v62 = UDim2.new(0, 562, 0, 12)
    v37.Size = v62
    v37.ZIndex = 2
    v38.Name = "Side"
    v38.Parent = v32
    v38.BackgroundColor3 = v24.DarkContrast
    v38.BorderSizePixel = 0
    local v63 = UDim2.new(0,001907998, 0, 0,00311943493, 0)
    v38.Position = v63
    local v64 = UDim2.new(0, 130, 0, 338)
    v38.Size = v64
    local v65 = UDim.new(0, 5)
    v39.CornerRadius = v65
    v39.Name = "SideC"
    v39.Parent = v38
    v40.Name = "SideBar"
    v40.Parent = v32
    v40.BackgroundColor3 = v24.DarkContrast
    v40.BorderSizePixel = 0
    local v66 = UDim2.new(0,211127862, 0, 0,00311943493, 0)
    v40.Position = v66
    local v67 = UDim2.new(0, 12, 0, 338)
    v40.Size = v67
    v41.Name = "Glow"
    v41.Parent = v32
    local v68 = Vector2.new(0,5, 0,5)
    v41.AnchorPoint = v68
    v41.BackgroundTransparency = 1
    v41.BorderSizePixel = 0
    local v69 = UDim2.new(0,5, 0, 0,5, 0)
    v41.Position = v69
    local v70 = UDim2.new(1, 47, 1, 47)
    v41.Size = v70
    v41.ZIndex = 0
    v41.Image = "rbxassetid://6014261993"
    local v71 = Color3.fromRGB(0, 0, 0)
    v41.ImageColor3 = v71
    v41.ImageTransparency = 0,5
    v41.ScaleType = Enum.ScaleType.Slice
    local v72 = Rect.new(49, 49, 450, 450)
    v41.SliceCenter = v72
    v42.Name = "TabHolder"
    v42.Parent = v38
    v42.Active = true
    v42.BackgroundColor3 = v24.TextColor
    v42.BackgroundTransparency = 1
    v42.BorderSizePixel = 0
    local v73 = UDim2.new(0,0384615399, 0, 0,115384616, 0)
    v42.Position = v73
    local v74 = UDim2.new(0, 119, 0, 294)
    v42.Size = v74
    v42.ZIndex = 2
    local v75 = UDim2.new(0, 0, 0, 0)
    v42.CanvasSize = v75
    v42.ScrollBarThickness = 1
    v43.Name = "TabHolderLL"
    v43.Parent = v42
    v43.SortOrder = Enum.SortOrder.LayoutOrder
    local v76 = UDim.new(0, 10)
    v43.Padding = v76
    upvalue_0.Notify = function(p0, p1, p2, p3, p4)
    assert(p1, "A title is required")
    assert(p2, "A message is required")
    local v77 = Instance.new("Frame")
    local v78 = Instance.new("UICorner")
    local v79 = Instance.new("ImageLabel")
    local v80 = Instance.new("TextLabel")
    local v81 = Instance.new("TextLabel")
    local v82 = Instance.new("ImageButton")
    local v83 = Instance.new("ImageButton")
    local v84 = Instance.new("Frame")
    local v85 = Instance.new("UICorner")
    v77.Name = "Notify"
    v77.Parent = upvalue_0
    v77.BackgroundColor3 = upvalue_1.Background
    v77.BorderSizePixel = 0
    v77.ClipsDescendants = true
    local v86 = UDim2.new(0, 0, 0, 0)
    v77.Position = v86
    local v87 = UDim2.new(0, 0, 0, 60)
    v77.Size = v87
    v77.Active = true
    v77.Draggable = true
    local v88 = UDim.new(0, 5)
    v78.CornerRadius = v88
    v78.Name = "NotifyC"
    v78.Parent = v77
    v79.Name = "Glow"
    v79.Parent = v77
    local v89 = Vector2.new(0,5, 0,5)
    v79.AnchorPoint = v89
    local v90 = Color3.fromRGB(0, 0, 0)
    v79.BackgroundColor3 = v90
    v79.BackgroundTransparency = 1
    v79.BorderSizePixel = 0
    local v91 = UDim2.new(0,5, 0, 0,5, 0)
    v79.Position = v91
    local v92 = UDim2.new(1, 47, 1, 47)
    v79.Size = v92
    v79.ZIndex = 0
    v79.Image = "rbxassetid://6014261993"
    local v93 = Color3.fromRGB(0, 0, 0)
    v79.ImageColor3 = v93
    v79.ImageTransparency = 0,5
    v79.ScaleType = Enum.ScaleType.Slice
    local v94 = Rect.new(49, 49, 450, 450)
    v79.SliceCenter = v94
    v80.Name = "Text"
    v80.Parent = v77
    v80.BackgroundTransparency = 1
    local v95 = UDim2.new(0, 10, 1, -24)
    v80.Position = v95
    local v96 = UDim2.new(1, -40, 0, 16)
    v80.Size = v96
    v80.ZIndex = 4
    v80.Font = Enum.Font.Gotham
    v80.Text = p2
    v80.TextColor3 = upvalue_1.TextColor
    v80.TextSize = 12
    v80.TextXAlignment = Enum.TextXAlignment.Left
    v81.Name = "Title"
    v81.Parent = v77
    v81.BackgroundTransparency = 1
    local v97 = UDim2.new(0, 10, 0, 8)
    v81.Position = v97
    local v98 = UDim2.new(1, -40, 0, 16)
    v81.Size = v98
    v81.ZIndex = 4
    v81.Font = Enum.Font.GothamMedium
    v81.Text = p1
    v81.TextColor3 = upvalue_1.TextColor
    v81.TextSize = 14
    v81.TextXAlignment = Enum.TextXAlignment.Left
    v82.Name = "Accept"
    v82.Parent = v77
    v82.BackgroundTransparency = 1
    local v99 = UDim2.new(1, -26, 0, 8)
    v82.Position = v99
    local v100 = UDim2.new(0, 16, 0, 16)
    v82.Size = v100
    v82.ZIndex = 4
    v82.Image = "rbxassetid://5012538259"
    v83.Name = "Decline"
    v83.Parent = v77
    v83.BackgroundTransparency = 1
    local v101 = UDim2.new(1, -26, 1, -24)
    v83.Position = v101
    local v102 = UDim2.new(0, 16, 0, 16)
    v83.Size = v102
    v83.ZIndex = 4
    v83.Image = "rbxassetid://5012538583"
    v84.Name = "Flash"
    v84.Parent = v77
    v84.BackgroundColor3 = upvalue_1.TextColor
    v84.BorderSizePixel = 0
    v84.ClipsDescendants = true
    local v103 = UDim2.new(-0,008, 0, -0,014, 0)
    v84.Position = v103
    local v104 = UDim2.new(0, 0, 0, 60)
    v84.Size = v104
    v84.ZIndex = 4
    local v105 = UDim.new(0, 5)
    v85.CornerRadius = v105
    v85.Name = "FlashC"
    v85.Parent = v84
    Drag(v77)
    local v106 = game:GetService("TextService")
    local v107, v108, v109 = Vector2.new(math.huge, 16)
    local v110 = v106:GetTextSize(v107)
    function(p0, p1)
    local v111 = {}
    v111.Size = p0.Size
    Tween(p1, 0,2, v111)
    task.wait(0,2)
    local v112 = {}
    local v113 = UDim2.new(0, 0, 0, 60)
    v112.Size = v113
    Tween(p0, 0,2, v112)
    task.wait(0,2)
    p0:Destroy()
    upvalue_0.CurrentNoti = nil
    return
end(upvalue_2.CurrentNoti, upvalue_2.CurrentNoti.Flash)
    upvalue_2.CurrentNoti = v77
    local v111 = {}
    local v112 = UDim2.new(0, v110.X + 70, 0, 60)
    v111.Size = v112
    Tween(v77, 0,3, v111)
    local v113 = {}
    local v114 = UDim2.new(0, v110.X + 70, 0, 60)
    v113.Size = v114
    Tween(v84, 0,3, v113)
    task.wait(0,3)
    local v115 = {}
    local v116 = UDim2.new(0, 0, 0, 60)
    v115.Size = v116
    Tween(v84, 0,2, v115)
    v82.MouseButton1Click:Connect(function()
    upvalue_0(true)
    upvalue_1(upvalue_2.CurrentNoti, upvalue_2.CurrentNoti.Flash)
    return
end)
    v83.MouseButton1Click:Connect(function()
    upvalue_0(false)
    upvalue_1(upvalue_2.CurrentNoti, upvalue_2.CurrentNoti.Flash)
    return
end)
    task.spawn(function()
    task.wait(10)
    upvalue_1(upvalue_2, upvalue_3)
    return
end)
    return
end
    upvalue_0.ProgressBar = function(p0, p1, p2, p3)
    assert(p1, "A name is required to create a progress bar")
    local v77 = Instance.new("Frame")
    local v78 = Instance.new("UICorner")
    local v79 = Instance.new("TextLabel")
    local v80 = Instance.new("Frame")
    local v81 = Instance.new("UICorner")
    local v82 = Instance.new("TextLabel")
    local v83 = Instance.new("ImageLabel")
    local v84 = Instance.new("Frame")
    local v85 = Instance.new("UICorner")
    local v86 = Instance.new("Frame")
    local v87 = Instance.new("UICorner")
    v77.Name = "ProgressBar"
    v77.Parent = upvalue_0
    v77.BackgroundColor3 = upvalue_1.Background
    v77.BorderSizePixel = 0
    local v88 = UDim2.new(0, 15, 0, 851)
    v77.Position = v88
    local v89 = UDim2.new(0, 0, 0, 60)
    v77.Size = v89
    v77.ClipsDescendants = true
    local v90 = UDim.new(0, 5)
    v78.CornerRadius = v90
    v78.Name = "ProgressBarC"
    v78.Parent = v77
    v79.Name = "Title"
    v79.Parent = v77
    v79.BackgroundTransparency = 1
    local v91 = UDim2.new(0, 10, 0, 8)
    v79.Position = v91
    local v92 = UDim2.new(0,936842084, -40, 0, 16)
    v79.Size = v92
    v79.ZIndex = 4
    v79.Font = Enum.Font.GothamMedium
    v79.Text = p1
    v79.TextColor3 = upvalue_1.TextColor
    v79.TextSize = 14
    v79.TextXAlignment = Enum.TextXAlignment.Left
    v80.Name = "Flash"
    v80.Parent = v77
    v80.BackgroundColor3 = upvalue_1.TextColor
    v80.BorderSizePixel = 0
    v80.ClipsDescendants = true
    local v93 = UDim2.new(-0,008, 0, -0,014, 0)
    v80.Position = v93
    local v94 = UDim2.new(0, 0, 0, 60)
    v80.Size = v94
    v80.ZIndex = 5
    local v95 = UDim.new(0, 5)
    v81.CornerRadius = v95
    v81.Name = "FlashC"
    v81.Parent = v80
    v82.Name = "Number"
    v82.Parent = v77
    v82.BackgroundTransparency = 1
    local v96 = UDim2.new(0, 156, 0, 8)
    v82.Position = v96
    local v97 = UDim2.new(0,300000012, -40, 0, 16)
    v82.Size = v97
    v82.ZIndex = 4
    v82.Font = Enum.Font.GothamMedium
    local v98, v99, v100 = tostring(100)
    local v101 = string.format(v98)
    v82.Text = v101
    v82.TextColor3 = upvalue_1.TextColor
    v82.TextSize = 14
    v82.TextXAlignment = Enum.TextXAlignment.Right
    v83.Name = "Glow"
    v83.Parent = v77
    local v102 = Vector2.new(0,5, 0,5)
    v83.AnchorPoint = v102
    local v103 = Color3.fromRGB(0, 0, 0)
    v83.BackgroundColor3 = v103
    v83.BackgroundTransparency = 1
    v83.BorderSizePixel = 0
    local v104 = UDim2.new(0,5, 0, 0,483333319, 0)
    v83.Position = v104
    local v105 = UDim2.new(1, 47, 1,0333333, 47)
    v83.Size = v105
    v83.ZIndex = 0
    v83.Image = "rbxassetid://6014261993"
    local v106 = Color3.fromRGB(0, 0, 0)
    v83.ImageColor3 = v106
    v83.ImageTransparency = 0,5
    v83.ScaleType = Enum.ScaleType.Slice
    local v107 = Rect.new(49, 49, 450, 450)
    v83.SliceCenter = v107
    v84.Name = "Inner"
    v84.Parent = v77
    v84.BackgroundColor3 = upvalue_1.LightContrast
    local v108 = UDim2.new(0,0526314974, 0, 0,683333337, 0)
    v84.Position = v108
    local v109 = UDim2.new(0, 164, 0, 4)
    v84.Size = v109
    v84.BorderSizePixel = 0
    local v110 = UDim.new(0, 10)
    v85.CornerRadius = v110
    v85.Name = "InnerC"
    v85.Parent = v84
    v86.Name = "Fill"
    v86.Parent = v84
    v86.BackgroundColor3 = upvalue_1.TextColor
    local v111 = UDim2.new(-0,00834411383, 0, -0,0666666627, 0)
    v86.Position = v111
    local v112 = UDim2.new(0, 0, 0, 4)
    v86.Size = v112
    v86.BorderSizePixel = 0
    local v113 = UDim.new(0, 10)
    v87.CornerRadius = v113
    v87.Name = "FillC"
    v87.Parent = v86
    local v114 = {}
    local v115 = v82:GetPropertyChangedSignal("Text")
    v115:Connect(function()
    local v116 = tostring(upvalue_1)
    local v117, v118, v119 = tostring(upvalue_1)
    local v120 = string.format(v117)
    upvalue_2(false)
    return
end)
    v114.UpdateProgress = function(p0, p1)
    local v116 = string.split(upvalue_1.Text, "%")
    local v117 = tonumber(v116[1])
    local v118 = string.split(upvalue_1.Text, "/")
    local v119 = math.floor(v118[1] + 1 / upvalue_2 * 100)
    local v120 = math.clamp(v118[1] + 1 / upvalue_2, 0, 1)
    local v121 = UDim2.new(v120, 0, 0, 4)
    upvalue_3:TweenSize(v121, "Out", "Sine", 0,1, false)
    local v122 = {}
    local v123 = UDim2.new(v120, 0, 0, 4)
    v122.Size = v123
    Tween(upvalue_3, 0,2, v122)
    local v124 = tostring(v118[1] + 1)
    local v125, v126, v127 = tostring(upvalue_2)
    local v128 = string.format(v125)
    upvalue_1.Text = v128
    return
end
    v114.RemoveProgressBar = function()
    upvalue_0(false)
    return
end
    function(p0)
    local v115 = {}
    local v116 = UDim2.new(0, 190, 0, 60)
    v115.Size = v116
    Tween(upvalue_0, 0,3, v115)
    local v117 = {}
    local v118 = UDim2.new(0, 190, 0, 60)
    v117.Size = v118
    Tween(upvalue_1, 0,3, v117)
    task.wait(0,3)
    local v119 = {}
    local v120 = UDim2.new(0, 0, 0, 60)
    v119.Size = v120
    Tween(upvalue_1, 0,2, v119)
    local v121 = {}
    local v122 = UDim2.new(0, 190, 0, 60)
    v121.Size = v122
    Tween(upvalue_1, 0,2, v121)
    task.wait(0,2)
    local v123 = {}
    local v124 = UDim2.new(0, 0, 0, 60)
    v123.Size = v124
    Tween(upvalue_0, 0,3, v123)
    task.wait(0,2)
    upvalue_0:Destroy()
    return
end(true)
    Drag(v77)
    return v114
end
    upvalue_0.DestroyUI = function(p0)
    return
    local v77 = typeof(v33)
    v33:Disconnect()
    v79, v80 = next(upvalue_0.Connections, v78)
    if v79 ~= nil then v78 = v79 end
    upvalue_0.Destroyed = true
    upvalue_1:Destroy()
    return
end
    upvalue_0.ToggleUI = function(p0)
    upvalue_0.Enabled = not upvalue_0.Enabled
    return
end
    Drag(v32, v34)
    local v77 = v43:GetPropertyChangedSignal("AbsoluteContentSize")
    v77:Connect(function()
    local v78 = UDim2.new(0, 0, 0, upvalue_1.AbsoluteContentSize.Y + 12)
    upvalue_0.CanvasSize = v78
    return
end)
    local v78 = {}
    v78.CreateTab = function(p0, p1, p2)
    assert(p1, "A title is required to create a tab")
    assert(p2, "An icon is required to create a tab")
    local v79 = Instance.new("TextButton")
    local v80 = Instance.new("TextLabel")
    local v81 = Instance.new("ImageLabel")
    local v82 = Instance.new("ScrollingFrame")
    local v83 = Instance.new("UIListLayout")
    v79.Name = "Tab"
    v79.Parent = upvalue_0
    v79.BackgroundTransparency = 1
    v79.BorderSizePixel = 0
    local v84 = UDim2.new(1, 0, 0, 26)
    v79.Size = v84
    v79.ZIndex = 3
    v79.AutoButtonColor = false
    v79.Font = Enum.Font.Gotham
    v79.Text = ""
    v79.TextSize = 14
    v80.Name = "Title"
    v80.Parent = v79
    local v85 = Vector2.new(0, 0,5)
    v80.AnchorPoint = v85
    v80.BackgroundTransparency = 1
    local v86 = UDim2.new(-0,145299152, 40, 0,5, 0)
    v80.Position = v86
    local v87 = UDim2.new(0,145299152, 76, 1, 0)
    v80.Size = v87
    v80.ZIndex = 3
    v80.Font = Enum.Font.Gotham
    v80.Text = p1
    v80.TextColor3 = upvalue_1.TextColor
    v80.TextSize = 12
    v80.TextTransparency = 0,65
    v80.TextXAlignment = Enum.TextXAlignment.Left
    v81.Name = "Icon"
    v81.Parent = v79
    local v88 = Vector2.new(0, 0,5)
    v81.AnchorPoint = v88
    v81.BackgroundTransparency = 1
    local v89 = UDim2.new(-0,102564111, 12, 0,5, 0)
    v81.Position = v89
    local v90 = UDim2.new(0, 17, 0, 17)
    v81.Size = v90
    v81.ZIndex = 3
    local v91 = string.format("rbxassetid://%s", p2)
    v81.Image = v91
    v81.ImageTransparency = 0,65
    v81.ScaleType = Enum.ScaleType.Fit
    v81.ImageColor3 = upvalue_1.TextColor
    local v92 = string.format("Holder_%s", p1)
    v82.Name = v92
    v82.Parent = upvalue_2
    v82.Active = true
    v82.BackgroundColor3 = upvalue_1.Background
    v82.BorderSizePixel = 0
    local v93 = UDim2.new(0,248226956, 0, 0,120588236, 0)
    v82.Position = v93
    local v94 = UDim2.new(0, 416, 0, 291)
    v82.Size = v94
    v82.ScrollBarThickness = 1
    local v95 = Color3.fromRGB(0, 0, 0)
    v82.ScrollBarImageColor3 = v95
    v82.Visible = false
    v83.Name = "HolderLL"
    v83.Parent = v82
    v83.SortOrder = Enum.SortOrder.LayoutOrder
    local v96 = UDim.new(0, 10)
    v83.Padding = v96
    local v97 = v83:GetPropertyChangedSignal("AbsoluteContentSize")
    v97:Connect(function()
    local v98 = UDim2.new(0, 0, 0, upvalue_1.AbsoluteContentSize.Y + 1)
    upvalue_0.CanvasSize = v98
    return
end)
    upvalue_3.SelectPage = function(p0, p1)
    SwitchTab(upvalue_1, upvalue_2)
    return
end
    SwitchTab(v79, v82)
    v79.MouseButton1Click:Connect(function()
    SwitchTab(upvalue_0, upvalue_1)
    return
end)
    local v98 = {}
    v98.Section = function(p0, p1)
    assert(p1, "A title is required to create a section")
    local v99 = Instance.new("Frame")
    local v100 = Instance.new("UICorner")
    local v101 = Instance.new("TextLabel")
    local v102 = Instance.new("UIListLayout")
    local v103 = Instance.new("UIPadding")
    local v104 = string.format("Section_%s", p1)
    v99.Name = v104
    v99.Parent = upvalue_0
    v99.BackgroundColor3 = upvalue_1.LightContrast
    v99.BorderSizePixel = 0
    local v105 = UDim2.new(0, 409, 0, 119)
    v99.Size = v105
    local v106 = UDim.new(0, 4)
    v100.CornerRadius = v106
    v100.Name = "SectionC"
    v100.Parent = v99
    v101.Name = "Title"
    v101.Parent = v99
    v101.BackgroundTransparency = 1
    v101.BorderSizePixel = 0
    local v107 = UDim2.new(0,0220048912, 0, -0,0309278332, 0)
    v101.Position = v107
    local v108 = UDim2.new(0,982885063, 0, 0,0182648394, 20)
    v101.Size = v108
    v101.ZIndex = 2
    v101.Font = Enum.Font.GothamMedium
    local v109 = string.format(" %s", p1)
    v101.Text = v109
    v101.TextColor3 = upvalue_1.TextColor
    v101.TextSize = 13
    v101.TextXAlignment = Enum.TextXAlignment.Left
    v102.Name = "SectionLL"
    v102.Parent = v99
    v102.SortOrder = Enum.SortOrder.LayoutOrder
    local v110 = UDim.new(0, 4)
    v102.Padding = v110
    v102.HorizontalAlignment = Enum.HorizontalAlignment.Center
    v103.Name = "SectionP"
    v103.Parent = v99
    local v111 = UDim.new(0, 4)
    v103.PaddingTop = v111
    local v112 = v102:GetPropertyChangedSignal("AbsoluteContentSize")
    v112:Connect(function()
    local v113 = UDim2.new(0, 409, 0, upvalue_1.AbsoluteContentSize.Y + 14)
    upvalue_0.Size = v113
    return
end)
    local v113 = {}
    v113.Button = function(p0, p1, p2)
    assert(p1, "a name is required to create a button")
    local v114 = Instance.new("TextButton")
    local v115 = Instance.new("UICorner")
    v114.Name = "Btn"
    v114.Parent = upvalue_0
    v114.BackgroundColor3 = upvalue_1.DarkContrast
    v114.BorderSizePixel = 0
    local v116 = UDim2.new(0,0244497284, 0, 0,115571238, 0)
    v114.Position = v116
    local v117 = UDim2.new(0,975856602, 0, 0, 30)
    v114.Size = v117
    v114.AutoButtonColor = false
    v114.Font = Enum.Font.Gotham
    v114.TextColor3 = upvalue_1.TextColor
    v114.TextSize = 13
    v114.Text = p1
    local v118 = UDim.new(0, 3)
    v115.CornerRadius = v118
    v115.Name = "BtnC"
    v115.Parent = v114
    local v119 = {}
    v119.State = v114.Text
    v119.ChangeText = function(p0, p1)
    return
    upvalue_0.Text = p1
    upvalue_1.flags[upvalue_2].State = p1
    return
end
    upvalue_2.flags[p1] = v119
    v114.MouseButton1Click:Connect(function()
    return
    upvalue_0 = true
    Pop(upvalue_1)
    spawn(upvalue_2)
    upvalue_0 = false
    return
end)
    return v114
end
    v113.Label = function(p0, p1)
    assert(p1, "A name is required to create a label")
    local v114 = Instance.new("TextLabel")
    local v115 = Instance.new("UICorner")
    local v116 = Instance.new("UIPadding")
    v114.Name = "Label"
    v114.Parent = upvalue_0
    v114.BackgroundColor3 = upvalue_1.DarkContrast
    v114.BorderSizePixel = 0
    local v117 = UDim2.new(0,0120716793, 0, 0,340642005, 0)
    v114.Position = v117
    local v118 = UDim2.new(0,975856662, 0, -0,010416667, 30)
    v114.Size = v118
    v114.Font = Enum.Font.Gotham
    v114.Text = p1
    v114.TextWrapped = true
    v114.TextColor3 = upvalue_1.TextColor
    v114.TextSize = 12
    v114.TextYAlignment = Enum.TextYAlignment.Top
    local v119 = UDim.new(0, 3)
    v115.CornerRadius = v119
    v115.Name = "LabelC"
    v115.Parent = v114
    v116.Parent = v114
    local v120 = UDim.new(0, 5)
    v116.PaddingLeft = v120
    local v121 = UDim.new(0, 5)
    v116.PaddingTop = v121
    local v122 = UDim.new(0, 5)
    v116.PaddingRight = v122
    local v123 = UDim2.new(v114.Size.X.Scale, v114.Size.X.Offset, 0, math.huge)
    v114.Size = v123
    local v124 = UDim2.new(v114.Size.X.Scale, v114.Size.X.Offset, 0, v114.TextBounds.Y + 12)
    v114.Size = v124
    return v114
end
    v113.Toggle = function(p0, p1, p2, p3)
    assert(p1, "A name is required to create a toggle")
    local v114 = Instance.new("TextButton")
    local v115 = Instance.new("UICorner")
    local v116 = Instance.new("Frame")
    local v117 = Instance.new("UICorner")
    local v118 = Instance.new("Frame")
    local v119 = Instance.new("UICorner")
    v114.Name = "Toggle"
    v114.Parent = upvalue_0
    v114.BackgroundColor3 = upvalue_1.DarkContrast
    v114.BorderSizePixel = 0
    local v120 = UDim2.new(0,0244497284, 0, 0,115571238, 0)
    v114.Position = v120
    local v121 = UDim2.new(0,975856602, 0, 0, 30)
    v114.Size = v121
    v114.AutoButtonColor = false
    v114.Font = Enum.Font.Gotham
    local v122 = string.format("  %s", p1)
    v114.Text = v122
    v114.TextColor3 = upvalue_1.TextColor
    v114.TextSize = 13
    v114.TextXAlignment = Enum.TextXAlignment.Left
    local v123 = UDim.new(0, 3)
    v115.CornerRadius = v123
    v115.Name = "ToggleC"
    v115.Parent = v114
    v116.Name = "Inner"
    v116.Parent = v114
    v116.BackgroundColor3 = upvalue_1.LightContrast
    v116.BorderSizePixel = 0
    local v124 = UDim2.new(0,877277315, 0, 0,166969255, 0)
    v116.Position = v124
    local v125 = UDim2.new(0, 41, 0, 19)
    v116.Size = v125
    v116.ZIndex = 3
    local v126 = UDim.new(1, 0)
    v117.CornerRadius = v126
    v117.Name = "InnerC"
    v117.Parent = v116
    v118.Name = "Circle"
    v118.Parent = v116
    v118.BackgroundColor3 = upvalue_1.TextColor
    v118.BorderSizePixel = 0
    local v127 = UDim2.new(0,100000001, 0, 0,158000007, 0)
    v118.Position = v127
    local v128 = UDim2.new(0, 13, 0, 13)
    v118.Size = v128
    v118.ZIndex = 3
    local v129 = UDim.new(5, 0)
    v119.CornerRadius = v129
    v119.Name = "CircleC"
    v119.Parent = v118
    local v130 = {}
    v130.State = false
    v130.SetState = function(p0, p1)
    return "State is already set"
    local v131 = {}
    local v132 = UDim2.new(0,1, 0, 0,158, 0)
    v131.Position = v132
    Tween(upvalue_2, 0,2, v131)
    task.wait(0,2)
    upvalue_0.flags[upvalue_1].State = not upvalue_0.flags[upvalue_1].State
    upvalue_3(not upvalue_0.flags[upvalue_1].State)
    return
end
    upvalue_2.flags[p1] = v130
    upvalue_2.flags[p1]:SetState(true)
    v114.MouseButton1Click:Connect(function()
    upvalue_0.flags[upvalue_1].SetState(upvalue_0.flags[upvalue_1])
    return
end)
    return
end
    v113.TextBox = function(p0, p1, p2, p3)
    assert(p1, "A name is required to create a textbox")
    assert(p2, "Default text is required to create a textbox")
    local v114 = Instance.new("TextButton")
    local v115 = Instance.new("UICorner")
    local v116 = Instance.new("TextBox")
    local v117 = Instance.new("UICorner")
    local v118 = Instance.new("UIListLayout")
    local v119 = Instance.new("UIPadding")
    v114.Name = "TextBox"
    v114.Parent = upvalue_0
    v114.BackgroundColor3 = upvalue_1.DarkContrast
    v114.BorderSizePixel = 0
    local v120 = UDim2.new(0,0244497284, 0, 0,115571238, 0)
    v114.Position = v120
    local v121 = UDim2.new(0,975856602, 0, 0, 30)
    v114.Size = v121
    v114.AutoButtonColor = false
    v114.Font = Enum.Font.Gotham
    local v122 = string.format("  %s", p1)
    v114.Text = v122
    v114.TextColor3 = upvalue_1.TextColor
    v114.TextSize = 13
    v114.TextXAlignment = Enum.TextXAlignment.Left
    local v123 = UDim.new(0, 3)
    v115.CornerRadius = v123
    v115.Name = "TextBoxC"
    v115.Parent = v114
    v116.Name = "Input"
    v116.Parent = v114
    v116.BackgroundColor3 = upvalue_1.LightContrast
    v116.ClipsDescendants = true
    local v124 = UDim2.new(0, 280, 0, 7)
    v116.Position = v124
    local v125 = UDim2.new(0, 111, 0, 16)
    v116.Size = v125
    v116.ZIndex = 3
    v116.Font = Enum.Font.GothamMedium
    v116.Text = p2
    v116.TextColor3 = upvalue_1.TextColor
    v116.TextSize = 12
    local v126 = UDim.new(0, 3)
    v117.CornerRadius = v126
    v117.Name = "InputC"
    v117.Parent = v116
    v118.Name = "TextBoxLL"
    v118.Parent = v114
    v118.HorizontalAlignment = Enum.HorizontalAlignment.Right
    v118.SortOrder = Enum.SortOrder.LayoutOrder
    v118.VerticalAlignment = Enum.VerticalAlignment.Center
    v119.Name = "TextBoxP"
    v119.Parent = v114
    local v127 = UDim.new(0, 8)
    v119.PaddingRight = v127
    v116.FocusLost:Connect(function()
    upvalue_0.Text = upvalue_1
    upvalue_2(upvalue_0.Text)
    return
end)
    return v114
end
    v113.KeyBind = function(p0, p1, p2, p3)
    assert(p1, "A name is required to create a keybind")
    assert(p2, "A default key is required to create a keybind")
    local v114 = Instance.new("TextButton")
    local v115 = Instance.new("UICorner")
    local v116 = Instance.new("TextButton")
    local v117 = Instance.new("UICorner")
    local v118 = Instance.new("UIListLayout")
    local v119 = Instance.new("UIPadding")
    v114.Name = "KeyBind"
    v114.Parent = upvalue_0
    v114.BackgroundColor3 = upvalue_1.DarkContrast
    v114.BorderSizePixel = 0
    local v120 = UDim2.new(0,0244497284, 0, 0,115571238, 0)
    v114.Position = v120
    local v121 = UDim2.new(0,975856602, 0, 0, 30)
    v114.Size = v121
    v114.AutoButtonColor = false
    v114.Font = Enum.Font.Gotham
    local v122 = string.format("  %s", p1)
    v114.Text = v122
    v114.TextColor3 = upvalue_1.TextColor
    v114.TextSize = 13
    v114.TextXAlignment = Enum.TextXAlignment.Left
    local v123 = UDim.new(0, 3)
    v115.CornerRadius = v123
    v115.Name = "TextBoxC"
    v115.Parent = v114
    v116.Name = "Input"
    v116.Parent = v114
    v116.BackgroundColor3 = upvalue_1.LightContrast
    v116.ClipsDescendants = true
    local v124 = UDim2.new(0, 280, 0, 7)
    v116.Position = v124
    local v125 = UDim2.new(0, 111, 0, 16)
    v116.Size = v125
    v116.ZIndex = 3
    v116.AutoButtonColor = false
    v116.Font = Enum.Font.GothamMedium
    v116.Text = p2
    v116.TextColor3 = upvalue_1.TextColor
    v116.TextSize = 12
    local v126 = UDim.new(0, 3)
    v117.CornerRadius = v126
    v117.Name = "InputC"
    v117.Parent = v116
    v118.Name = "KeyBindLL"
    v118.Parent = v114
    v118.HorizontalAlignment = Enum.HorizontalAlignment.Right
    v118.SortOrder = Enum.SortOrder.LayoutOrder
    v118.VerticalAlignment = Enum.VerticalAlignment.Center
    v119.Name = "KeyBindP"
    v119.Parent = v114
    local v127 = UDim.new(0, 8)
    v119.PaddingRight = v127
    local v128 = {}
    v128.Return = true
    v128.Space = true
    v128.Tab = true
    v128.Backquote = true
    v128.CapsLock = true
    v128.Escape = true
    v128.Unknown = true
    local v129 = {}
    v129.RightControl = "Right Ctrl"
    v129.LeftControl = "Left Ctrl"
    v129.LeftShift = "Left Shift"
    v129.RightShift = "Right Shift"
    v129.Semicolon = ";"
    v129.Quote = "\""
    v129.LeftBracket = "["
    v129.RightBracket = "]"
    v129.Equals = "="
    v129.Minus = "-"
    v129.RightAlt = "Right Alt"
    v129.LeftAlt = "Left Alt"
    local v130 = typeof(p2)
    local v131 = game:GetService("UserInputService")
    local v132 = v131.InputBegan:Connect(function(p0, p1)
    return
    return
    return
    return
    upvalue_2(upvalue_1.Name)
    return
end)
    upvalue_2.Connections[#upvalue_2.Connections + 1] = v132
    v116.MouseButton1Click:Connect(function()
    upvalue_0.Text = "..."
    task.wait(p1)
    local v133 = game.UserInputService.InputEnded.Wait(game.UserInputService.InputEnded)
    upvalue_0.Text = upvalue_1
    return
    local v134 = tostring(v133.KeyCode.Name)
    upvalue_0.Text = upvalue_1
    return
    local v135 = tostring(v133.KeyCode.Name)
    upvalue_3 = Enum.KeyCode[v135]
    local v136 = tostring(v133.KeyCode.Name)
    local v137 = tostring(v133.KeyCode.Name)
    upvalue_0.Text = v137
    return
end)
    return v114
end
    v113.Slider = function(p0, p1, p2, p3, p4, p5, p6)
    assert(p1, "A name is required to create a slider")
    local v114 = Instance.new("TextButton")
    local v115 = Instance.new("UICorner")
    local v116 = Instance.new("TextLabel")
    local v117 = Instance.new("TextBox")
    local v118 = Instance.new("TextLabel")
    local v119 = Instance.new("Frame")
    local v120 = Instance.new("UICorner")
    local v121 = Instance.new("Frame")
    local v122 = Instance.new("UICorner")
    local v123 = Instance.new("Frame")
    local v124 = Instance.new("UICorner")
    v114.Name = "Slider"
    v114.Parent = upvalue_0
    v114.BackgroundColor3 = upvalue_1.DarkContrast
    v114.BorderSizePixel = 0
    local v125 = UDim2.new(-0,0195600521, 0, 0,136772648, 0)
    v114.Position = v125
    local v126 = UDim2.new(0,976000011, 0, 0, 50)
    v114.Size = v126
    v114.AutoButtonColor = false
    v114.Font = Enum.Font.Gotham
    v114.Text = ""
    v114.TextColor3 = upvalue_1.TextColor
    v114.TextSize = 13
    v114.TextXAlignment = Enum.TextXAlignment.Left
    local v127 = UDim.new(0, 3)
    v115.CornerRadius = v127
    v115.Name = "SliderC"
    v115.Parent = v114
    v116.Name = "Title"
    v116.Parent = v114
    v116.BackgroundTransparency = 1
    local v128 = UDim2.new(0, 8, 0, 6)
    v116.Position = v128
    local v129 = UDim2.new(0,740490735, 0, 0, 16)
    v116.Size = v129
    v116.ZIndex = 3
    v116.Font = Enum.Font.Gotham
    v116.Text = p1
    v116.TextColor3 = upvalue_1.TextColor
    v116.TextSize = 13
    v116.TextTransparency = 0,1
    v116.TextXAlignment = Enum.TextXAlignment.Left
    v117.Name = "Number"
    v117.Parent = v114
    v117.BackgroundTransparency = 1
    v117.BorderSizePixel = 0
    local v130 = UDim2.new(1,00250506, -30, 0, 6)
    v117.Position = v130
    local v131 = UDim2.new(0, 20, 0, 16)
    v117.Size = v131
    v117.ZIndex = 3
    v117.Font = Enum.Font.GothamMedium
    local v132 = tostring(1)
    v117.Text = v132
    v117.TextColor3 = upvalue_1.TextColor
    v117.TextSize = 12
    v117.TextXAlignment = Enum.TextXAlignment.Right
    v118.Name = "Outer"
    v118.Parent = v114
    v118.BackgroundTransparency = 1
    local v133 = Color3.fromRGB(27, 42, 53)
    v118.BorderColor3 = v133
    local v134 = UDim2.new(0, 9, 0, 28)
    v118.Position = v134
    local v135 = UDim2.new(1,00751531, -20, 0, 16)
    v118.Size = v135
    v118.ZIndex = 3
    v118.Text = ""
    v119.Name = "Inner"
    v119.Parent = v118
    v119.BackgroundColor3 = upvalue_1.LightContrast
    v119.BorderSizePixel = 0
    local v136 = UDim2.new(-0,00263030501, 0, 0,375, 0)
    v119.Position = v136
    local v137 = UDim2.new(1, 0, 0, 4)
    v119.Size = v137
    v119.ZIndex = 3
    local v138 = UDim.new(0, 10)
    v120.CornerRadius = v138
    v120.Name = "InnerC"
    v120.Parent = v119
    v121.Name = "Fill"
    v121.Parent = v119
    v121.BackgroundColor3 = upvalue_1.TextColor
    v121.BorderSizePixel = 0
    local v139 = UDim2.new(0,00012392737, 0, 0, 0)
    v121.Position = v139
    local v140 = UDim2.new(0,379879832, 0, 0, 4)
    v121.Size = v140
    v121.ZIndex = 3
    local v141 = UDim.new(0, 10)
    v122.CornerRadius = v141
    v122.Name = "FillC"
    v122.Parent = v121
    v123.Name = "Circle"
    v123.Parent = v121
    v123.BackgroundColor3 = upvalue_1.TextColor
    local v142 = UDim2.new(0,979818106, 0, -0,75, 0)
    v123.Position = v142
    local v143 = UDim2.new(0, 10, 0, 10)
    v123.Size = v143
    v123.ZIndex = 3
    v123.Transparency = 1
    local v144 = UDim.new(0, 9999)
    v124.CornerRadius = v144
    v124.Name = "CircleC"
    v124.Parent = v123
    local v145 = {}
    v145.SetState = function(p0, p1)
    local v146 = math.clamp(p1 - upvalue_2 / upvalue_3 - upvalue_2, 0, 1)
    local v147, v148, v149 = tostring(upvalue_2 + upvalue_3 - upvalue_2 * v146)
    local v150, v151, v152 = string.format(v147)
    local v153 = tonumber(v150)
    local v154 = math.floor(upvalue_2 + upvalue_3 - upvalue_2 * v146)
    local v155 = tostring(v154)
    upvalue_5.Text = v155
    local v156 = {}
    local v157 = UDim2.new(v146, 0, 1, 0)
    v156.Size = v157
    Tween(upvalue_6, 0,1, v156)
    local v158, v159, v160 = tonumber(v154)
    upvalue_7(v158)
    return
end
    v145:SetState(1)
    local v146 = {}
    v146[""] = true
    v146["-"] = true
    v118.InputBegan:Connect(function(p0)
    local v147 = {}
    v147.Transparency = 0
    Tween(upvalue_0, 0,2, v147)
    upvalue_1:SetState()
    upvalue_2 = true
    return
end)
    local v147 = game:GetService("UserInputService")
    v147.InputEnded:Connect(function(p0)
    upvalue_0 = false
    task.wait(1)
    local v148 = {}
    v148.Transparency = 1
    Tween(upvalue_1, 0,2, v148)
    return
end)
    local v148 = game:GetService("UserInputService")
    v148.InputChanged:Connect(function(p0)
    upvalue_1:SetState()
    return
end)
    v118.InputBegan:Connect(function(p0)
    local v149 = {}
    v149.Transparency = 0
    Tween(upvalue_0, 0,2, v149)
    upvalue_1:SetState()
    upvalue_2 = true
    return
end)
    local v149 = game:GetService("UserInputService")
    v149.InputEnded:Connect(function(p0)
    upvalue_0 = false
    task.wait(1)
    local v150 = {}
    v150.Transparency = 1
    Tween(upvalue_1, 0,2, v150)
    return
end)
    local v150 = game:GetService("UserInputService")
    v150.InputChanged:Connect(function(p0)
    upvalue_1:SetState()
    return
end)
    v117.Focused:Connect(function()
    upvalue_0 = true
    return
end)
    v117.FocusLost:Connect(function()
    local v151 = tonumber(upvalue_0.Text)
    upvalue_0.Text = upvalue_1
    local v152 = tonumber(upvalue_0.Text)
    upvalue_3:SetState(upvalue_2)
    upvalue_4 = false
    return
end)
    local v151 = v117:GetPropertyChangedSignal("Text")
    v151:Connect(function()
    return
    return
    local v152 = tonumber(upvalue_1.Text)
    upvalue_1.Text = ""
    local v153 = tonumber(upvalue_1.Text)
    upvalue_3:SetState(upvalue_2)
    local v154, v155, v156 = tonumber(upvalue_1.Text)
    upvalue_3:SetState(v154)
    return
end)
    return v145
end
    v113.DropDown = function(p0, p1, p2, p3, p4, p5)
    local v114 = {}
    assert(p1, "a name is required to create a dropdown")
    local v115 = Instance.new("TextButton")
    local v116 = Instance.new("UICorner")
    local v117 = Instance.new("TextBox")
    local v118 = Instance.new("ImageButton")
    local v119 = Instance.new("Frame")
    local v120 = Instance.new("UICorner")
    local v121 = Instance.new("ScrollingFrame")
    local v122 = Instance.new("UIListLayout")
    v115.Name = "DropDown"
    v115.Parent = upvalue_0
    v115.BackgroundColor3 = upvalue_1.DarkContrast
    v115.BorderSizePixel = 0
    local v123 = UDim2.new(0,0244497284, 0, 0,115571238, 0)
    v115.Position = v123
    local v124 = UDim2.new(0,975856602, 0, 0, 30)
    v115.Size = v124
    v115.AutoButtonColor = false
    v115.Font = Enum.Font.Gotham
    v115.Text = ""
    v115.TextColor3 = upvalue_1.TextColor
    v115.TextSize = 13
    v115.TextXAlignment = Enum.TextXAlignment.Left
    local v125 = UDim.new(0, 3)
    v116.CornerRadius = v125
    v116.Name = "DropDownC"
    v116.Parent = v115
    v117.Name = "Search"
    v117.Parent = v115
    local v126 = Vector2.new(0, 0,5)
    v117.AnchorPoint = v126
    v117.BackgroundTransparency = 1
    local v127 = UDim2.new(-0,00751628308, 10, 0,5, 1)
    v117.Position = v127
    local v128 = UDim2.new(1,00501084, -42, 1, 0)
    v117.Size = v128
    v117.ZIndex = 3
    v117.Font = Enum.Font.Gotham
    v117.Text = p1
    v117.TextColor3 = upvalue_1.TextColor
    v117.TextSize = 13
    v117.TextTransparency = 0,1
    v117.TextXAlignment = Enum.TextXAlignment.Left
    v117.ClipsDescendants = true
    v118.Name = "Arrow"
    v118.Parent = v115
    v118.BackgroundTransparency = 1
    v118.BorderSizePixel = 0
    local v129 = UDim2.new(1,00501096, -28, 0,5, -9)
    v118.Position = v129
    local v130 = UDim2.new(0, 18, 0, 18)
    v118.Size = v130
    v118.ZIndex = 3
    v118.Image = "rbxassetid://5012539403"
    local v131 = Rect.new(2, 2, 298, 298)
    v118.SliceCenter = v131
    v118.ImageColor3 = upvalue_1.TextColor
    v119.Name = "DropdownHolder"
    v119.Parent = upvalue_0
    v119.BackgroundColor3 = upvalue_1.Background
    v119.BorderSizePixel = 0
    v119.ClipsDescendants = true
    local v132 = UDim2.new(0,0120000485, 0, 0,430878669, 0)
    v119.Position = v132
    local v133 = UDim2.new(0,976000011, 0, 0, 0)
    v119.Size = v133
    v119.Visible = false
    local v134 = UDim.new(0, 3)
    v120.CornerRadius = v134
    v120.Name = "DropdownHolderC"
    v120.Parent = v119
    v121.Name = "OptionHolder"
    v121.Parent = v119
    v121.Active = true
    v121.BackgroundColor3 = upvalue_1.TextColor
    v121.BackgroundTransparency = 1
    v121.BorderSizePixel = 0
    local v135 = UDim2.new(0,0100202896, 0, 0,0178573243, 0)
    v121.Position = v135
    local v136 = UDim2.new(0, 388, 0, 132)
    v121.Size = v136
    local v137 = UDim2.new(0, 0, 0, 0)
    v121.CanvasSize = v137
    v121.ScrollBarThickness = 1
    local v138 = Color3.fromRGB(0, 0, 0)
    v121.ScrollBarImageColor3 = v138
    v122.Name = "OptionHolderLL"
    v122.Parent = v121
    v122.SortOrder = Enum.SortOrder.LayoutOrder
    local v139 = UDim.new(0, 4)
    v122.Padding = v139
    local v140 = {}
    local v141 = function()
    local v141 = {}
    local v142 = game:GetService("Players")
    local v143, v144 = v142:GetChildren()
    table.insert(v141, p5.Name)
    v145, v146 = next(v143, v144)
    if v145 ~= nil then v144 = v145 end
    return v141
end(r26)
    v140.AddOption = function(p0, p1)
    local v142 = Instance.new("TextButton")
    local v143 = Instance.new("UICorner")
    local v144 = Instance.new("UIPadding")
    v142.Name = "Option"
    v142.Parent = upvalue_0
    v142.BackgroundColor3 = upvalue_1.DarkContrast
    v142.BorderSizePixel = 0
    local v145 = UDim2.new(0,976405919, 0, 0, 30)
    v142.Size = v145
    v142.AutoButtonColor = false
    v142.Font = Enum.Font.Gotham
    v142.Text = p1
    v142.TextColor3 = upvalue_1.TextColor
    v142.TextSize = 13
    v142.TextXAlignment = Enum.TextXAlignment.Left
    v142.TextTransparency = 0
    local v146 = UDim.new(0, 3)
    v143.CornerRadius = v146
    v143.Name = "OptionC"
    v143.Parent = v142
    v144.Name = "OptionP"
    v144.Parent = v142
    local v147 = UDim.new(0, 8)
    v144.PaddingLeft = v147
    v142.MouseButton1Click:Connect(function()
    upvalue_0.Text = upvalue_3.Text
    upvalue_4(upvalue_3.Text)
    upvalue_5(upvalue_3.Text)
    return
end)
    return
end
    v140.SetOptions = function(p0, p1)
    local v142, v143 = upvalue_0:GetChildren()
    local v144 = function()
    return
end:IsA("TextButton")
    function()
    return
end:Destroy()
    v145, v146 = next(v142, v143)
    if v145 ~= nil then v143 = v145 end
    upvalue_1:AddOption(v146)
    v148, v149 = next(p1, v147)
    if v148 ~= nil then v147 = v148 end
    return
end
    v117.Focused:Connect(function()
    upvalue_0 = true
    return
end)
    v117.FocusLost:Connect(function()
    local v142 = SetSearchText(upvalue_0)
    upvalue_0.Text = v142
    upvalue_0.Text = upvalue_1
    local v143 = upvalue_0.Text.sub(upvalue_0.Text, 1, 8)
    return
    upvalue_2 = false
    return
end)
    local v142 = v117:GetPropertyChangedSignal("Text")
    v142:Connect(function()
    return
    local v143 = upvalue_1.Text.sub(upvalue_1.Text, 1, 8)
    return
    return
    upvalue_4(upvalue_1.Text)
    return
end)
    local v143 = v122:GetPropertyChangedSignal("AbsoluteContentSize")
    v143:Connect(function()
    local v144 = UDim2.new(0, 0, 0, upvalue_1.AbsoluteContentSize.Y + 1)
    upvalue_0.CanvasSize = v144
    return
end)
    v118.MouseButton1Click:Connect(function()
    local v144, v145, v146 = upvalue_2(p3)
    upvalue_1:SetOptions(v144)
    upvalue_3(upvalue_1)
    return
end)
    v140:SetOptions(v114)
    return v140
end
    return v113
end
    return v98
end
    return v78
end
local v24, v25, v26 = v18:Create("Dark X V5.0")
_G.提醒 = function(p0)
    upvalue_0:Notify("Dark X", p0, false)
    return
end
local v27 = _G.自己:GetMouse()
_G.鼠标 = v27
_G.飞行 = function(p0)
    wait(v15)
    local v28 = _G.自己角色:FindFirstChild("Head")
    local v29 = _G.自己角色:FindFirstChild("Humanoid")
    local v30 = {}
    v30.f = 0
    v30.b = 0
    v30.l = 0
    v30.r = 0
    local v31 = {}
    v31.f = 0
    v31.b = 0
    v31.l = 0
    v31.r = 0
    _G.自己身体.PlatformStand = true
    CarFly = _G.自己身体.SeatPart
    local v32 = Instance.new("Weld", _G.自己的方块)
    local v33 = Instance.new("Weld", _G.自己身体.SeatPart)
    v32.Part0 = _G.自己的方块
    v32.Part1 = _G.自己身体.SeatPart
    v33.Part0 = _G.自己的方块
    v33.Part1 = _G.自己身体.SeatPart
    Fly = function()
    local v34 = Instance.new("BodyGyro", _G.自己的方块)
    v34.P = 90000
    local v35 = Vector3.new(9000000000, 9000000000, 9000000000)
    v34.maxTorque = v35
    v34.CFrame = _G.自己的方块.CFrame
    local v36 = Instance.new("BodyVelocity", _G.自己的方块)
    local v37 = Vector3.new(0, 0,1, 0)
    v36.Velocity = v37
    local v38 = Vector3.new(9000000000, 9000000000, 9000000000)
    v36.maxForce = v38
    wait(9000000000)
    local v39 = CFrame.new(upvalue_0.l + upvalue_0.r, upvalue_0.f + upvalue_0.b * 0,2, 0)
    v36.Velocity = game.Workspace.CurrentCamera.CoordinateFrame.lookVector * upvalue_0.f + upvalue_0.b + game.Workspace.CurrentCamera.CoordinateFrame * v39.p - game.Workspace.CurrentCamera.CoordinateFrame.p * upvalue_1 - 50
    local v40 = {}
    v40.f = upvalue_0.f
    v40.b = upvalue_0.b
    v40.l = upvalue_0.l
    v40.r = upvalue_0.r
    upvalue_2 = v40
    local v41 = CFrame.new(upvalue_2.l + upvalue_2.r, upvalue_2.f + upvalue_2.b * 0,2, 0)
    v36.Velocity = game.Workspace.CurrentCamera.CoordinateFrame.lookVector * upvalue_2.f + upvalue_2.b + game.Workspace.CurrentCamera.CoordinateFrame * v41.p - game.Workspace.CurrentCamera.CoordinateFrame.p * upvalue_1 - 50
    local v42 = Vector3.new(0, 0,1, 0)
    v36.Velocity = v42
    local v43 = math.rad(upvalue_0.f + upvalue_0.b * 50 * upvalue_1 - 50 / upvalue_1)
    local v44 = CFrame.Angles(-v43, 0, 0)
    v34.CFrame = game.Workspace.CurrentCamera.CoordinateFrame * v44
    local v45 = {}
    v45.F = 0
    v45.B = 0
    v45.L = 0
    v45.R = 0
    local v46 = {}
    v46.F = 0
    v46.B = 0
    v46.L = 0
    v46.R = 0
    v34:Destroy()
    v36:Destroy()
    pcall(function()
    local v47, v48 = _G.自己身体.SeatPart:GetChildren()
    v46:Destroy()
    v49, v50 = next(v47, v48)
    if v49 ~= nil then v48 = v49 end
    local v51, v52 = _G.自己的方块:GetChildren()
    local v53 = v50:IsA("Weld")
    v50:Destroy()
    v54, v55 = next(v51, v52)
    if v54 ~= nil then v52 = v54 end
    local v56 = CFrame.new(CarFly.CFrame.p)
    _G.自己的方块.CFrame = v56
    return
end)
    _G.自己身体.PlatformStand = false
    return
end
    _G.鼠标.KeyDown:Connect(function(p0)
    local v34 = p0:lower()
    isWDown = true
    upvalue_0.f = 1
    local v35 = p0:lower()
    isADown = true
    upvalue_0.l = -1
    local v36 = p0:lower()
    isSDown = true
    upvalue_0.b = -1
    local v37 = p0:lower()
    isSDown = true
    upvalue_0.r = 1
    return
end)
    _G.鼠标.KeyUp:Connect(function(p0)
    local v34 = p0:lower()
    isWDown = false
    upvalue_0.f = 0
    local v35 = p0:lower()
    isADown = false
    upvalue_0.l = 0
    local v36 = p0:lower()
    isSDown = false
    upvalue_0.b = 0
    local v37 = p0:lower()
    isDDown = false
    upvalue_0.r = 0
    return
end)
    _G.菜单.正在飞行 = false
    _G.自己身体.PlatformStand = false
    _G.菜单.正在飞行 = true
    Fly(_G.鼠标.KeyUp)
    return
end
_G.拉东西 = game.ReplicatedStorage.Interaction.ClientIsDragging
_G.穿 = nil
_G.穿墙 = function(p0)
    _G.穿:Disconnect()
    _G.穿 = nil
    return
    local v28 = game:GetService("RunService")
    local v29 = v28.Stepped:connect(function()
    local v29, v30 = _G.自己角色:GetChildren()
    local v31 = "RunService":IsA("Part")
    local v32 = "RunService":IsA("BasePart")
    "RunService".CanCollide = false
    v33, v34 = next(v29, v30)
    if v33 ~= nil then v30 = v33 end
    return
end)
    _G.穿 = v29
    return
end
_G.获得工具的伤害 = function(p0)
    local v28 = require(game.ReplicatedStorage.AxeClasses["AxeClass_" .. p0.ToolName.Value])
    return v28.new(game.ReplicatedStorage.AxeClasses["AxeClass_" .. p0.ToolName.Value])
    return ...
end
_G.传送 = function(p0)
    spawn(function()
    wait(nil)
    _G.自己身体.SeatPart.Parent:PivotTo(upvalue_0)
    _G.拉东西:FireServer(_G.自己身体.SeatPart.Parent.Main)
    1 = 1 + 1
    if 1 <= 20 then
    -- continue loop (PC + -19)
    end
    return
end)
    _G.自己角色:PivotTo(p0)
    return
end
_G.获得工具 = function()
    local v28 = {}
    local v29, v30 = _G.自己.Backpack:GetChildren()
    local v31 = v24:IsA("Tool")
    table.insert(v28, v24)
    v32, v33 = next(v29, v30)
    if v32 ~= nil then v30 = v32 end
    local v34 = _G.自己角色:FindFirstChildOfClass("Tool")
    local v35, v36, v37 = _G.自己角色:FindFirstChildOfClass("Tool")
    table.insert(v35)
    return nil
    return v28
end
_G.检查斧头 = function(p0)
    _G.木头种类 = p0
    local v28 = _G.获得工具(v15)
    return _G.提醒("you need one axe")
    return ...
    local v32 = _G.获得工具的伤害(v24)
    return _G.提醒("you need one end times axe")
    return ...
    return v24, v32.SpecialTrees[_G.木头种类].Damage
    return _G.提醒("you need one end times axe")
    return ...
    return v24, v32.Damage
    v40, v41 = next(v28, v39)
    if v40 ~= nil then v39 = v40 end
    return
end
_G.找木头 = function(p0)
    local v28 = {}
    local v29, v30 = Workspace:GetChildren()
    local v31, v32 = v24:GetChildren()
    local v33 = _G:FindFirstChild("TreeClass")
    local v34 = tostring(_G.TreeClass.Value)
    local v35 = _G:FindFirstChild("Owner")
    local v36 = _G:FindFirstChild("WoodSection")
    local v37, v38 = _G:GetChildren()
    local v39 = r16:FindFirstChild("ID")
    table.insert(v28, _G)
    v40, v41 = next(v37, v38)
    if v40 ~= nil then v38 = v40 end
    v42, v43 = next(v31, v32)
    if v42 ~= nil then v32 = v42 end
    v44, v45 = next(v29, v30)
    if v44 ~= nil then v30 = v44 end
    return false
    return v28
end
_G.获得适合的木头 = function(p0)
    local v28 = _G.找木头(p0)
    return false
    local v29, v30 = function(p0)
    local v28 = p0:FindFirstChildOfClass("MeshPart")
    local v29 = p0:FindFirstChildOfClass("MeshPart")
    p0.PrimaryPart = v29
    return
    local v30 = p0:FindFirstChildOfClass("Part")
    local v31 = p0:FindFirstChildOfClass("MeshPart")
    local v32 = p0:FindFirstChild("Main")
    p0.PrimaryPart = v32
    return
end:GetChildren()
    v31, v32 = next(v29, v30)
    if v31 ~= nil then v30 = v31 end
    v34, v35 = next(v28, v33)
    if v34 ~= nil then v33 = v34 end
    local v36, v37 = function(p0)
    local v28 = p0:FindFirstChildOfClass("MeshPart")
    local v29 = p0:FindFirstChildOfClass("MeshPart")
    p0.PrimaryPart = v29
    return
    local v30 = p0:FindFirstChildOfClass("Part")
    local v31 = p0:FindFirstChildOfClass("MeshPart")
    local v32 = p0:FindFirstChild("Main")
    p0.PrimaryPart = v32
    return
end:GetChildren()
    return v35
    v38, v39 = next(v36, v37)
    if v38 ~= nil then v37 = v38 end
    return
end
_G.砍 = function(p0, p1, p2, p3, p4)
    local v28 = game:GetService("ReplicatedStorage")
    local v29 = {}
    v29.tool = p1
    local v30 = Vector3.new(-1, 0, 0)
    v29.faceVector = v30
    v29.height = 0,3
    v29.sectionId = 1
    v29.hitPoints = p4
    v29.cooldown = -14
    v29.cuttingClass = "Axe"
    v28.Interaction.RemoteProxy:FireServer(p0, v29)
    return
end
local v28 = game.Workspace.ChildAdded:Connect(function(p0)
    local v28 = p0:IsA("Part")
    local v29 = p0:WaitForChild("BodyPosition")
    local v30 = p0:WaitForChild("BodyGyro")
    local v31 = BrickColor.new("Really red")
    p0.BrickColor = v31
    local v32 = p0:WaitForChild("BodyPosition")
    v32.P = 100500
    local v33 = p0:WaitForChild("BodyPosition")
    v33.D = 1040
    local v34 = p0:WaitForChild("BodyPosition")
    local v35 = Vector3.new(90000, 90000, 90000)
    v34.MaxForce = v35 * math.huge
    local v36 = p0:WaitForChild("BodyGyro")
    v36.P = 1400
    local v37 = p0:WaitForChild("BodyGyro")
    v37.D = 1040
    local v38 = p0:WaitForChild("BodyGyro")
    local v39 = Vector3.new(9000, 9000, 9000)
    v38.MaxTorque = v39 * math.huge
    local v40 = BrickColor.new("Deep blue")
    p0.BrickColor = v40
    local v41 = p0:WaitForChild("BodyPosition")
    v41.P = 10000
    local v42 = p0:WaitForChild("BodyPosition")
    v42.D = 800
    local v43 = p0:WaitForChild("BodyPosition")
    local v44 = Vector3.new(1, 1, 1)
    v43.MaxForce = v44 * 17000
    local v45 = p0:WaitForChild("BodyGyro")
    v45.P = 1200
    local v46 = p0:WaitForChild("BodyGyro")
    v46.D = 140
    local v47 = p0:WaitForChild("BodyGyro")
    local v48 = Vector3.new(1, 1, 1)
    v47.MaxTorque = v48 * 200
    return
end)
_G.自己克隆的方块 = nil
_G.带来树 = function(p0)
    _G.树的种类 = p0
    local v29, v30 = _G.检查斧头(_G.树的种类)
    _G.伤害 = v30
    _G.斧头 = v29
    return
    local v31 = _G.获得适合的木头(_G.树的种类)
    _G.木头 = v31
    _G.树加入 = nil
    _G.树砍好了 = false
    return _G.提醒("not find " .. _G.树的种类)
    return ...
    local v35 = Workspace.LogModels.ChildAdded:Connect(function(p0)
    p0:WaitForChild("Owner", 60)
    p0:WaitForChild("Owner", 60)
    local v35 = p0:WaitForChild("WoodSection", 60)
    p0.PrimaryPart = v35
    local v36 = p0:WaitForChild("Owner", 60)
    _G.树砍好了 = true
    upvalue_0(p0, _G.菜单.树放置的地点)
    local v37 = game:GetService("ReplicatedStorage")
    local v38 = _G.自己.Backpack:FindFirstChild("Tool")
    local v39 = _G.自己角色:FindFirstChild("Tool")
    v37.Interaction.ClientInteracted:FireServer(v39, "Drop tool", _G.菜单.树放置的地点)
    _G.自己身体.Health = 0
    wait(v37.Interaction.ClientInteracted)
    wait(v37.Interaction.ClientInteracted)
    local v40 = _G.自己角色:FindFirstChild("Head")
    _G.传送(_G.菜单.树放置的地点)
    wait(2)
    pcall(function()
    upvalue_0:Disconnect()
    upvalue_0 = nil
    return
end)
    pcall(function()
    _G.树加入.Disconnect(_G.树加入)
    _G.树加入 = nil
    return
end)
    return
end)
    _G.树加入 = v35
    local v36 = game.Workspace.PlayerModels.ChildAdded:Connect(function(p0)
    p0:WaitForChild("Owner")
    local v36 = p0:FindFirstChild("ToolName")
    local v37 = tostring(p0.ToolName.Value)
    local v38 = p0:WaitForChild("Owner")
    wait(_G.自己)
    local v39 = _G.自己角色:FindFirstChild("Head")
    wait(0,1)
    local v40 = {}
    v40[1] = p0
    v40[2] = "Pick up tool"
    local v41 = game:GetService("ReplicatedStorage")
    local v42 = v41:WaitForChild("Interaction")
    local v43 = v42:WaitForChild("ClientInteracted")
    local v44, v45, v46 = unpack(v40)
    v43:FireServer(v44)
    return
end)
    upvalue_1 = v36
    local v37 = Instance.new("Part", game.Workspace)
    v37.CanCollide = false
    v37.Anchored = true
    local v38 = Color3.fromRGB(0, 217, 255)
    v37.Color = v38
    v37.Transparency = 1
    local v39 = Vector3.new(2, 2, 2)
    v37.Size = v39
    v37.CFrame = _G.自己的方块.CFrame
    v37.Material = Enum.Material.Marble
    v37.Name = "Part"
    local v40 = game:GetService("Workspace")
    v40.CurrentCamera.CameraSubject = v37
    local v41, v42, v43 = CFrame.new(-1456,40442, 433,399719, 1285,89697)
    _G.传送(v41)
    pcall(function()
    firetouchinterest(_G.自己的方块, _G.岩浆, 0)
    firetouchinterest(_G.自己的方块, _G.岩浆, 1)
    return
end)
    task.wait(function()
    firetouchinterest(_G.自己的方块, _G.岩浆, 0)
    firetouchinterest(_G.自己的方块, _G.岩浆, 1)
    return
end)
    local v44 = _G.自己的方块:FindFirstChild("LavaFire")
    wait(_G.自己的方块)
    local v45 = CFrame.new(-1675,2002, 255,002533, 1284,19983, 0,866007268, 0, 0,500031412, 0, 1, 0, -0,500031412, 0, 0,866007268)
    _G.岩浆.CFrame = v45
    local v46 = _G.自己的方块:FindFirstChild("LavaFire")
    v46:Destroy()
    local v47 = _G.自己角色.Torso:Clone()
    v47.Name = "HumanoidRootPart"
    v47.Transparency = 1
    v47.Parent = _G.自己角色
    pcall(function()
    upvalue_0:Destroy()
    return
end)
    local v48 = game:GetService("Workspace")
    v48.CurrentCamera.CameraSubject = _G.自己身体
    spawn(function()
    game["Run Service"].Heartbeat.wait(game["Run Service"].Heartbeat)
    local v49 = _G.自己角色.FindFirstChild(_G.自己角色, "Head")
    local v50 = Vector3.new(3, 5, 0)
    _G.传送(_G.木头.CFrame + v50)
    return
end)
    local v49 = _G.自己角色:FindFirstChild("Head")
    task.wait(_G.自己角色)
    local v50 = _G.自己角色:FindFirstChild("Head")
    local v51 = _G.自己角色:FindFirstChildOfClass("Tool")
    wait(_G.自己角色)
    local v52, v53 = _G.检查斧头(_G.树的种类)
    _G.伤害 = v53
    _G.斧头 = v52
    spawn(function()
    _G.砍(_G.木头.Parent.CutEvent, _G.斧头, 1, 0,3, _G.伤害)
    return
end)
    task.wait(function()
    _G.砍(_G.木头.Parent.CutEvent, _G.斧头, 1, 0,3, _G.伤害)
    return
end)
    _G.树加入:Disconnect()
    _G.树加入 = nil
    return
end
local v29 = game:GetService("Lighting")
_G.灯光 = v29
_G.加载保存服务器 = game.ReplicatedStorage.LoadSaveRequests
_G.是否可以加载 = function()
    local v30 = _G.加载保存服务器.ClientMayLoad.InvokeServer(_G.加载保存服务器.ClientMayLoad, _G.自己)
    _G.提醒("Load is on cooldown. Waiting...")
    wait("Load is on cooldown. Waiting...")
    local v31 = _G.加载保存服务器.ClientMayLoad.InvokeServer(_G.加载保存服务器.ClientMayLoad, _G.自己)
    return true
end
_G.加载 = function(p0)
    _G.是否可以加载(v15)
    wait(v15)
    _G.加载保存服务器.RequestLoad:InvokeServer(p0, _G.自己)
    return
end
_G.保存基地 = function(p0)
    upvalue_0:Notify("Dark X", "Are you sure you want to replace all existing data", true, function()
    _G.加载保存服务器.RequestSave.InvokeServer(_G.加载保存服务器.RequestSave, upvalue_0, _G.自己)
    _G.提醒("Slot saved successfully")
    return
end)
    return
end
_G.扩大土地 = function(p0)
    local v30, v31 = _G.土地:GetChildren()
    local v32 = v24:FindFirstChild("Owner")
    v33, v34 = next(v30, v31)
    if v33 ~= nil then v31 = v33 end
    local v35 = game:GetService("ReplicatedStorage")
    v35.PropertyPurchasing.ClientExpandedProperty:FireServer(v24, p0)
    return
end
_G.擦除选择的物品 = function()
    _G.擦除 = false
    local v30, v31 = game.Workspace.PlayerModels:GetChildren()
    local v32 = v20:FindFirstChild("Owner")
    local v33 = tostring(v20.Owner.Value)
    local v34 = v20:FindFirstChild("Type")
    _G.擦除 = true
    game.ReplicatedStorage.Interaction.DestroyStructure:FireServer(v20)
    task.wait(game.ReplicatedStorage.Interaction.DestroyStructure)
    task.wait(game.ReplicatedStorage.Interaction.DestroyStructure)
    v35, v36 = next(v30, v31)
    if v35 ~= nil then v31 = v35 end
    _G.提醒("Failed to find a selected type")
    return
end
_G.收档 = function()
    _G.加载(math.huge)
    return
end
_G.卖标志 = function()
    local v30, v31 = game.Workspace.PlayerModels:GetChildren()
    local v32 = v20:FindFirstChild("Owner")
    local v33 = v20:FindFirstChild("ItemName")
    local v34 = CFrame.new(v20.Main.CFrame.p)
    local v35 = Vector3.new(0, 0, 2)
    _G.传送(v34 + v35)
    game.ReplicatedStorage.Interaction.ClientInteracted:FireServer(v20, "Take down sold sign")
    _G.拉东西:FireServer(v20)
    local v36 = CFrame.new(314,54, -0,5, 86,823)
    v20.Main.CFrame = v36
    game["Run Service"].Heartbeat:wait()
    1 = 1 + 1
    if 1 <= 30 then
    -- continue loop (PC + -19)
    end
    v37, v38 = next(v30, v31)
    if v37 ~= nil then v31 = v37 end
    return
end
_G.检查斧头是否最大 = function()
    local v30, v31 = _G.自己.Backpack:GetChildren()
    local v32 = nil:IsA("Tool")
    v33, v34 = next(v30, v31)
    if v33 ~= nil then v31 = v33 end
    local v35 = _G.自己角色:FindFirstChildOfClass("Tool")
    print(0 + 1 + 1)
    return true
    return
end
local v30, v31 = Workspace:GetChildren()
local v32, v33 = r17:GetChildren()
local v34 = r22:FindFirstChild("TreeClass")
local v35 = r22:FindFirstChild("Owner")
local v36 = tostring(r22.TreeClass.Value)
local v37 = tostring(r22.TreeClass.Value)
local v38 = tostring(r22.Owner.Value)
local v39 = r22:FindFirstChild("WoodSection")
_G.提醒("Find Spooky /SpookyNeon wood")
v40, v41 = next(v32, v33)
if v40 ~= nil then v33 = v40 end
v42, v43 = next(v30, v31)
if v42 ~= nil then v31 = v42 end
spawn(function()
    local v44 = task.wait(20)
    local v45, v46 = Workspace:GetChildren()
    local v47, v48 = v20:GetChildren()
    local v49 = function(p0)
    local v28 = p0:FindFirstChildOfClass("MeshPart")
    local v29 = p0:FindFirstChildOfClass("MeshPart")
    p0.PrimaryPart = v29
    return
    local v30 = p0:FindFirstChildOfClass("Part")
    local v31 = p0:FindFirstChildOfClass("MeshPart")
    local v32 = p0:FindFirstChild("Main")
    p0.PrimaryPart = v32
    return
end:FindFirstChild("TreeClass")
    local v50 = function(p0)
    local v28 = p0:FindFirstChildOfClass("MeshPart")
    local v29 = p0:FindFirstChildOfClass("MeshPart")
    p0.PrimaryPart = v29
    return
    local v30 = p0:FindFirstChildOfClass("Part")
    local v31 = p0:FindFirstChildOfClass("MeshPart")
    local v32 = p0:FindFirstChild("Main")
    p0.PrimaryPart = v32
    return
end:FindFirstChild("Owner")
    local v51 = tostring(function(p0)
    local v28 = p0:FindFirstChildOfClass("MeshPart")
    local v29 = p0:FindFirstChildOfClass("MeshPart")
    p0.PrimaryPart = v29
    return
    local v30 = p0:FindFirstChildOfClass("Part")
    local v31 = p0:FindFirstChildOfClass("MeshPart")
    local v32 = p0:FindFirstChild("Main")
    p0.PrimaryPart = v32
    return
end.TreeClass.Value)
    local v52 = tostring(function(p0)
    local v28 = p0:FindFirstChildOfClass("MeshPart")
    local v29 = p0:FindFirstChildOfClass("MeshPart")
    p0.PrimaryPart = v29
    return
    local v30 = p0:FindFirstChildOfClass("Part")
    local v31 = p0:FindFirstChildOfClass("MeshPart")
    local v32 = p0:FindFirstChild("Main")
    p0.PrimaryPart = v32
    return
end.TreeClass.Value)
    local v53 = tostring(function(p0)
    local v28 = p0:FindFirstChildOfClass("MeshPart")
    local v29 = p0:FindFirstChildOfClass("MeshPart")
    p0.PrimaryPart = v29
    return
    local v30 = p0:FindFirstChildOfClass("Part")
    local v31 = p0:FindFirstChildOfClass("MeshPart")
    local v32 = p0:FindFirstChild("Main")
    p0.PrimaryPart = v32
    return
end.Owner.Value)
    local v54 = function(p0)
    local v28 = p0:FindFirstChildOfClass("MeshPart")
    local v29 = p0:FindFirstChildOfClass("MeshPart")
    p0.PrimaryPart = v29
    return
    local v30 = p0:FindFirstChildOfClass("Part")
    local v31 = p0:FindFirstChildOfClass("MeshPart")
    local v32 = p0:FindFirstChild("Main")
    p0.PrimaryPart = v32
    return
end:FindFirstChild("WoodSection")
    _G.提醒("Find Spooky /SpookyNeon wood")
    v55, v56 = next(v47, v48)
    if v55 ~= nil then v48 = v55 end
    v57, v58 = next(v45, v46)
    if v57 ~= nil then v46 = v57 end
    return
end)
spawn(function()
    local v44 = task.wait(v13)
    _G.收档(v13)
    local v45 = _G.获得土地(v13)
    local v46 = Vector3.new(0, 3, 0)
    game.ReplicatedStorage.PropertyPurchasing.ClientPurchasedProperty:FireServer(v45, v45.OriginSquare.CFrame.p + v46)
    _G.加载(_G.菜单.存档)
    _G.卖标志(_G.菜单.存档)
    return
end)
spawn(function()
    local v44 = task.wait(v13)
    _G.收档(v13)
    local v45 = _G.获得土地(v13)
    pcall(function()
    local v46 = Vector3.new(0, 3, 0)
    game.ReplicatedStorage.PropertyPurchasing.ClientPurchasedProperty.FireServer(game.ReplicatedStorage.PropertyPurchasing.ClientPurchasedProperty, upvalue_0, upvalue_0.OriginSquare.CFrame.p + v46)
    return
end)
    _G.收档(function()
    local v46 = Vector3.new(0, 3, 0)
    game.ReplicatedStorage.PropertyPurchasing.ClientPurchasedProperty.FireServer(game.ReplicatedStorage.PropertyPurchasing.ClientPurchasedProperty, upvalue_0, upvalue_0.OriginSquare.CFrame.p + v46)
    return
end)
    local v46, v47 = game.Workspace.PlayerModels:GetChildren()
    local v48 = nil:FindFirstChild("ItemName")
    nil:WaitForChild("Owner")
    local v49 = nil:WaitForChild("Owner")
    local v50 = nil:WaitForChild("Owner")
    local v51 = CFrame.new(nil.Main.CFrame.p)
    local v52 = Vector3.new(0, 3, 2)
    _G.传送(v51 + v52)
    game.ReplicatedStorage.Interaction.ClientInteracted:FireServer(nil, "Take down sold sign")
    game.ReplicatedStorage.Interaction.ClientInteracted:FireServer(nil, "Take down sold sign")
    wait(game.ReplicatedStorage.Interaction.ClientInteracted)
    _G.拉东西:FireServer(nil)
    _G.拉东西:FireServer(nil)
    local v53 = Vector3.new(0, 5, 0)
    nil:PivotTo(game.Players[_G.菜单.复制标志的玩家].Character.HumanoidRootPart.CFrame + v53)
    task.wait(nil)
    1 = 1 + 1
    if 1 <= 30 then
    -- continue loop (PC + -27)
    end
    v54, v55 = next(v46, v47)
    if v54 ~= nil then v47 = v54 end
    task.wait(v46)
    return
end)
_G.卖木头 = function()
    local v44 = game:GetService("Workspace")
    local v45, v46 = v44.LogModels:GetChildren()
    local v47 = function(p0)
    local v28 = p0:FindFirstChildOfClass("MeshPart")
    local v29 = p0:FindFirstChildOfClass("MeshPart")
    p0.PrimaryPart = v29
    return
    local v30 = p0:FindFirstChildOfClass("Part")
    local v31 = p0:FindFirstChildOfClass("MeshPart")
    local v32 = p0:FindFirstChild("Main")
    p0.PrimaryPart = v32
    return
end:FindFirstChild("Owner")
    _G.传送(function(p0)
    local v28 = p0:FindFirstChildOfClass("MeshPart")
    local v29 = p0:FindFirstChildOfClass("MeshPart")
    p0.PrimaryPart = v29
    return
    local v30 = p0:FindFirstChildOfClass("Part")
    local v31 = p0:FindFirstChildOfClass("MeshPart")
    local v32 = p0:FindFirstChild("Main")
    p0.PrimaryPart = v32
    return
end.WoodSection.CFrame)
    _G.拉东西:FireServer(function(p0)
    local v28 = p0:FindFirstChildOfClass("MeshPart")
    local v29 = p0:FindFirstChildOfClass("MeshPart")
    p0.PrimaryPart = v29
    return
    local v30 = p0:FindFirstChildOfClass("Part")
    local v31 = p0:FindFirstChildOfClass("MeshPart")
    local v32 = p0:FindFirstChild("Main")
    p0.PrimaryPart = v32
    return
end)
    local v48, v49, v50 = CFrame.new(315, 0, 85,4999924)
    function(p0)
    local v28 = p0:FindFirstChildOfClass("MeshPart")
    local v29 = p0:FindFirstChildOfClass("MeshPart")
    p0.PrimaryPart = v29
    return
    local v30 = p0:FindFirstChildOfClass("Part")
    local v31 = p0:FindFirstChildOfClass("MeshPart")
    local v32 = p0:FindFirstChild("Main")
    p0.PrimaryPart = v32
    return
end:PivotTo(v48)
    game["Run Service"].Heartbeat:wait()
    1 = 1 + 1
    if 1 <= 20 then
    -- continue loop (PC + -19)
    end
    task.wait(0,3)
    local v51, v52, v53 = CFrame.new(315, 0, 85,4999924)
    _G.传送(v51)
    local v54, v55 = function(p0)
    local v28 = p0:FindFirstChildOfClass("MeshPart")
    local v29 = p0:FindFirstChildOfClass("MeshPart")
    p0.PrimaryPart = v29
    return
    local v30 = p0:FindFirstChildOfClass("Part")
    local v31 = p0:FindFirstChildOfClass("MeshPart")
    local v32 = p0:FindFirstChild("Main")
    p0.PrimaryPart = v32
    return
end:GetChildren()
    spawn(function()
    local v56, v57, v58 = CFrame.new(315, 0, 85,4999924)
    _G.传送(v56)
    _G.拉东西:FireServer(upvalue_0)
    local v59, v60, v61 = CFrame.new(315, 0, 85,4999924)
    upvalue_1:PivotTo(v59)
    game["Run Service"].Heartbeat:wait()
    1 = 1 + 1
    if 1 <= 20 then
    -- continue loop (PC + -29)
    end
    return
end)
    game["Run Service"].Heartbeat:wait()
    v56, v57 = next(v54, v55)
    if v56 ~= nil then v55 = v56 end
    task.wait(v54)
    v58, v59 = next(v45, v46)
    if v58 ~= nil then v46 = v58 end
    task.wait(v45)
    1 = 1 + 1
    if 1 <= 10 then
    -- continue loop (PC + -91)
    end
    _G.传送(85,4999924)
    return
end
spawn(function()
    local v44 = task.wait(v13)
    spawn(function()
    _G.自己身体.JumpPower = _G.菜单.跳跃提升
    return
end)
    _G.灯光.TimeOfDay = "12:00:00"
    _G.灯光.Brightness = 2
    _G.灯光.TimeOfDay = "2:00:00"
    _G.灯光.FogEnd = 1000000
    spawn(function()
    local v45, v46 = _G.自己.Backpack:GetChildren()
    local v47 = nil:IsA("Tool")
    v48, v49 = next(v45, v46)
    if v48 ~= nil then v46 = v48 end
    local v50 = _G.自己角色:FindFirstChildOfClass("Tool")
    wait(1)
    _G.自己身体.Health = 0
    _G.提醒("your have too much axe")
    return
end)
    local v45 = _G.菜单.油漆的锯木机.FindFirstChild(_G.菜单.油漆的锯木机, "Particles")
    _G.提醒("maybe you move your sawmill or destroy please reselect")
    _G.菜单.油漆的锯木机 = nil
    _G.锯木机.Text = "not select"
    local v46 = _G.菜单.选择的锯木机.FindFirstChild(_G.菜单.选择的锯木机, "Particles")
    _G.提醒("maybe you move your sawmill or destroy please reselect")
    _G.菜单.选择的锯木机 = nil
    _G.处理树锯木机.Text = "not select"
    spawn(function()
    local v47 = game:GetService("Workspace")
    local v48, v49 = v47.Stores:GetChildren()
    spawn(function()
    local v50, v51 = upvalue_0:GetChildren()
    local v52 = v20:FindFirstChild("Owner")
    spawn(function()
    upvalue_0(function()
    upvalue_0.Main.CanCollide = false
    local v53 = Vector3.new(10000000000000, 10000000000000, 10000000000000)
    upvalue_0.Main.Velocity = v53
    task.wait(0,1)
    1 = 1 + 1
    if 1 <= 20 then
    -- continue loop (PC + -14)
    end
    return
end)
    return
end)
    v53, v54 = v20(v50, v51)
    if v53 ~= nil then v51 = v53 end
    return
end)
    v50, v51 = v20(v48, v49)
    if v50 ~= nil then v49 = v50 end
    wait(v48)
    return
end)
    spawn(function()
    local v47 = _G.检查斧头是否最大(function()
    local v47 = game:GetService("Workspace")
    local v48, v49 = v47.Stores:GetChildren()
    spawn(function()
    local v50, v51 = upvalue_0:GetChildren()
    local v52 = v20:FindFirstChild("Owner")
    spawn(function()
    upvalue_0(function()
    upvalue_0.Main.CanCollide = false
    local v53 = Vector3.new(10000000000000, 10000000000000, 10000000000000)
    upvalue_0.Main.Velocity = v53
    task.wait(0,1)
    1 = 1 + 1
    if 1 <= 20 then
    -- continue loop (PC + -14)
    end
    return
end)
    return
end)
    v53, v54 = v20(v50, v51)
    if v53 ~= nil then v51 = v53 end
    return
end)
    v50, v51 = v20(v48, v49)
    if v50 ~= nil then v49 = v50 end
    wait(v48)
    return
end)
    local v48, v49 = workspace.PlayerModels:GetChildren()
    local v50 = v20:FindFirstChild("Owner")
    local v51 = v20:FindFirstChild("ToolName")
    local v52 = tostring(v20.ToolName.Value)
    local v53 = {}
    v53[1] = v20
    v53[2] = "Pick up tool"
    local v54 = game:GetService("ReplicatedStorage")
    local v55 = v54:WaitForChild("Interaction")
    local v56 = v55:WaitForChild("ClientInteracted")
    local v57, v58, v59 = unpack(v53)
    v56:FireServer(v57)
    v60, v61 = next(v48, v49)
    if v60 ~= nil then v49 = v60 end
    return
end)
    return
end)
local v44 = v24:CreateTab("Player", "5012544693")
local v45 = v44:Section("Player")
spawn(function()
    wait(v13)
    wait(v13)
    local v46 = _G.自己身体.GetPropertyChangedSignal(_G.自己身体, "WalkSpeed")
    upvalue_0(v46, function()
    _G.自己身体.WalkSpeed = upvalue_0
    return
end)
    return
end)
local v46 = _G.自己身体:GetPropertyChangedSignal("WalkSpeed")
v46:Connect(function()
    _G.自己身体.WalkSpeed = upvalue_0
    return
end)
v45:Slider("WalkSpeed", 50, 16, 500, false, function(p0)
    upvalue_0 = p0
    _G.自己身体.WalkSpeed = upvalue_0
    return
end)
v45:Slider("JumpPower", 100, 60, 500, false, function(p0)
    _G.菜单.跳跃提升 = p0
    return
end)
v45:Slider("HipHeight", 0, 0, 500, false, function(p0)
    _G.自己身体.HipHeight = p0
    return
end)
v45:Slider("Zoom Distance", 100, 1, 2000, false, function(p0)
    _G.自己.CameraMaxZoomDistance = p0
    return
end)
v45:Slider("FOV", 70, 70, 150, false, function(p0)
    game.Workspace.Camera.FieldOfView = p0
    return
end)
v45:Slider("Fly Speed", 200, 50, 500, false, function(p0)
    _G.菜单.飞行速度 = p0
    return
end)
v45:KeyBind("Fly Key", "Q", function()
    _G.菜单.飞行 = true
    _G.飞行(true)
    _G.菜单.飞行 = false
    _G.飞行(false)
    return
end)
v45:Toggle("NoClip", false, function(p0)
    _G.穿墙(p0)
    return
end)
v45:Toggle("Infinite Jump", false, function(p0)
    local v47 = game:GetService("UserInputService")
    local v48 = v47.JumpRequest:Connect(function()
    _G.自己身体.ChangeState(_G.自己身体, "Jumping")
    return
end)
    _G.菜单.无限跳跃 = v48
    _G.菜单.无限跳跃:Disconnect()
    _G.菜单.无限跳跃 = nil
    return
end)
v45:Toggle("Light", false, function(p0)
    local v47 = Instance.new("PointLight", _G.自己角色.Head)
    _G.发光 = v47
    _G.发光.Name = "dark"
    _G.发光.Range = 150
    _G.发光.Brightness = 1,7
    pcall(function()
    _G.自己角色.Head.dark.Destroy(_G.自己角色.Head.dark)
    return
end)
    return
end)
v45:Button("Safe Death", function()
    local v47, v48, v49 = CFrame.new(0, -380, 0)
    _G.传送(v47)
    return
end)
local v47 = v44:Section("Tp")
local v48 = {}
v47:DropDown("Select the player", v48, true, false, function(p0)
    _G.菜单.传送的玩家 = p0
    return
end)
v47:Button("Tp to Base", function()
    _G.基地 = nil
    local v49, v50 = _G.土地:GetChildren()
    local v51 = tostring(v20.Owner.Value)
    _G.基地 = v20
    local v52 = Vector3.new(0, 5, 0)
    _G.传送(v20.OriginSquare.CFrame + v52)
    v53, v54 = next(v49, v50)
    if v53 ~= nil then v50 = v53 end
    _G.提醒("Player Not Have Base")
    return
end)
v47:Button("Tp to Player", function()
    _G.传送(_G.玩家[_G.菜单.传送的玩家].Character.HumanoidRootPart.CFrame)
    return
end)
local v49 = {}
v49 = {"Spawn", "Wood R Us", "Land Store", "Bridge", "Dock", "Palm", "Cave", "The Den", "Volcano", "Swamp", "Fancy Furnishings", "Boxed Cars", "Links Logic", "Bobs Shack", "Fine Arts Store", "Ice Mountain", "Shrine Of Sight", "Strange Man", "Volcano Win", "Ski Lodge", "Fur Wood"}
v47:DropDown("Tp To Place", v49, false, false, function(p0)
    local v50, v51, v52 = CFrame.new(270, 4, 60)
    _G.传送(v50)
    local v53, v54, v55 = CFrame.new(174, 10,5, 66)
    _G.传送(v53)
    local v56, v57, v58 = CFrame.new(270, 3, -98)
    _G.传送(v56)
    local v59, v60, v61 = CFrame.new(112, 37, -892)
    _G.传送(v59)
    local v62, v63, v64 = CFrame.new(1136, 0, -206)
    _G.传送(v62)
    local v65, v66, v67 = CFrame.new(2614, -4, -34)
    _G.传送(v65)
    local v68, v69, v70 = CFrame.new(3590, -177, 415)
    _G.传送(v68)
    local v71, v72, v73 = CFrame.new(-1588, 623, 1069)
    _G.传送(v71)
    local v74, v75, v76 = CFrame.new(-1216, 131, -822)
    _G.传送(v74)
    local v77, v78, v79 = CFrame.new(486, 3, -1722)
    _G.传送(v77)
    local v80, v81, v82 = CFrame.new(509, 3, -1458)
    _G.传送(v80)
    local v83, v84, v85 = CFrame.new(1487, 415, 3259)
    _G.传送(v83)
    local v86, v87, v88 = CFrame.new(4615, 7, -794)
    _G.传送(v86)
    local v89, v90, v91 = CFrame.new(292, 8, -2544)
    _G.传送(v89)
    local v92, v93, v94 = CFrame.new(5217, -166, 721)
    _G.传送(v92)
    local v95, v96, v97 = CFrame.new(-1608, 195, 928)
    _G.传送(v95)
    local v98, v99, v100 = CFrame.new(1071, 16, 1141)
    _G.传送(v98)
    local v101, v102, v103 = CFrame.new(-1667, 349, 1474)
    _G.传送(v101)
    local v104, v105, v106 = CFrame.new(1244, 59, 2290)
    _G.传送(v104)
    local v107, v108, v109 = CFrame.new(-1080, -5, -942)
    _G.传送(v107)
    local v110, v111, v112 = CFrame.new(330,259735, 45,7998505, 1943,30823, 0,972010553, -8,07546598E-08, 0,234937176, 7,63610259E-08, 1, 2,77986647E-08, -0,234937176, -9,08055142E-09, 0,972010553)
    _G.传送(v110)
    return
end)
local v50 = v44:Section("funny")
v50:Toggle("Fire", false, function(p0)
    local v51 = Instance.new("Fire", _G.自己角色.Head)
    local v52 = _G.自己角色.Head:FindFirstChild("Fire")
    v52:Destroy()
    return
end)
v50:Toggle("Sparkles", false, function(p0)
    local v51 = Instance.new("Sparkles", _G.自己角色.Head)
    local v52 = _G.自己角色.Head:FindFirstChild("Sparkles")
    v52:Destroy()
    return
end)
_G.自动拿鲨鱼斧头 = nil
_G.自动拿鲨鱼斧头 = function(p0)
    local v51 = game.Workspace.PlayerModels.ChildAdded:Connect(function(p0)
    local v51 = p0:WaitForChild("Main", 60)
    local v52 = v51:FindFirstChild("Mesh")
    wait(v51)
    local v53 = p0:FindFirstChild("ToolName")
    _G.提醒("Calming Rukiryaxe")
    _G.传送(p0.Main.CFrame)
    task.wait(p0.Main.CFrame)
    _G.拉东西:FireServer(p0)
    game.ReplicatedStorage.Interaction.ClientInteracted:FireServer(p0, "Pick up tool")
    local v54 = tostring(p0.Parent)
    _G.传送(_G.自己的方块.CFrame)
    return
end)
    _G.自动拿鲨鱼斧头 = v51
    pcall(function()
    _G.自动拿鲨鱼斧头.Disconnect(_G.自动拿鲨鱼斧头)
    _G.自动拿鲨鱼斧头 = nil
    return
end)
    return
end
local v51 = Instance.new("ScreenGui")
local v52 = Instance.new("Frame")
local v53 = Instance.new("UICorner")
local v54 = Instance.new("ScrollingFrame")
local v55 = Instance.new("UIGridLayout")
v51.Name = "DarkX"
local v56 = game:GetService("RunService")
local v57 = v56:IsStudio()
local v58 = game.Players.LocalPlayer:WaitForChild("PlayerGui")
local v59 = game:WaitForChild("CoreGui")
v51.Parent = v59
v51.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
v51.Enabled = false
v52.Name = "MainC"
v52.Parent = v51
local v60 = Color3.fromRGB(39, 39, 39)
v52.BackgroundColor3 = v60
local v61 = Color3.fromRGB(0, 0, 0)
v52.BorderColor3 = v61
v52.BorderSizePixel = 0
local v62 = UDim2.new(0,382168919, 0, 0,256493509, 0)
v52.Position = v62
local v63 = UDim2.new(0, 451, 0, 450)
v52.Size = v63
v52.Active = true
v52.Draggable = true
local v64 = UDim.new(0, 5)
v53.CornerRadius = v64
v53.Name = "MainC"
v53.Parent = v52
v54.Name = "Holder"
v54.Parent = v52
v54.Active = true
local v65 = Color3.fromRGB(255, 255, 255)
v54.BackgroundColor3 = v65
v54.BackgroundTransparency = 1
local v66 = Color3.fromRGB(0, 0, 0)
v54.BorderColor3 = v66
v54.BorderSizePixel = 0
local v67 = UDim2.new(0,0133037698, 0, 0,0222222228, 0)
v54.Position = v67
local v68 = UDim2.new(0, 437, 0, 431)
v54.Size = v68
v54.ScrollBarThickness = 3
v55.Name = "HolderC"
v55.Parent = v54
v55.SortOrder = Enum.SortOrder.LayoutOrder
local v69 = v55:GetPropertyChangedSignal("AbsoluteContentSize")
v69:Connect(function()
    local v70 = UDim2.new(0, 0, 0, upvalue_1.AbsoluteContentSize.Y + 14)
    upvalue_0.CanvasSize = v70
    return
end)
CreateSlot = function(p0)
    assert(p0, "An immage is required")
    local v70 = Instance.new("ImageLabel")
    local v71 = Instance.new("UICorner")
    v70.Name = "ImageSlot"
    v70.Parent = upvalue_0
    local v72 = Color3.fromRGB(29, 29, 29)
    v70.BackgroundColor3 = v72
    local v73 = Color3.fromRGB(0, 0, 0)
    v70.BorderColor3 = v73
    v70.BorderSizePixel = 0
    local v74 = UDim2.new(0, 0, 0,00928074215, 0)
    v70.Position = v74
    local v75 = UDim2.new(0, 100, 0, 100)
    v70.Size = v75
    local v76 = UDim.new(0, 5)
    v71.CornerRadius = v76
    v71.Name = "ImageSlotC"
    v71.Parent = v70
    v70.Image = ""
    return
end
local v70 = game:GetService("ReplicatedStorage")
local v71, v72 = v70.ClientItemInfo:GetChildren()
local v73 = 0:FindFirstChild("ItemImage")
CreateSlot(0.ItemImage.Value)
v74, v75 = next(v71, v72)
if v74 ~= nil then v72 = v74 end
local v76 = v24:CreateTab("World", "6034287522")
local v77 = v76:Section("World")
v77:Toggle("Always Day", false, function(p0)
    _G.菜单.终日白天 = p0
    return
end)
v77:Toggle("Always Night", false, function(p0)
    _G.菜单.终日黑夜 = p0
    return
end)
v77:Toggle("Remove Fog", false, function(p0)
    _G.菜单.消除雾 = p0
    return
end)
_G.灯光.GlobalShadows = false
local v78 = v77:Toggle("Always Shadows", true, function(p0)
    _G.灯光.GlobalShadows = p0
    return
end)
v77:Toggle("Walk On Water", false, function(p0)
    local v79, v80 = game.Workspace.Water:GetChildren()
    nil.CanCollide = p0
    v81, v82 = next(v79, v80)
    if v81 ~= nil then v80 = v81 end
    local v83, v84 = game.Workspace.Bridge.VerticalLiftBridge.WaterModel:GetChildren()
    local v85 = v82:IsA("BasePart")
    v82.CanCollide = p0
    v86, v87 = next(v83, v84)
    if v86 ~= nil then v84 = v86 end
    return
end)
v77:Toggle("Remove Water", false, function(p0)
    local v79, v80 = game.Workspace.Water:GetChildren()
    nil.Transparency = 1
    nil.Transparency = 0
    v81, v82 = next(v79, v80)
    if v81 ~= nil then v80 = v81 end
    return
end)
v77:Button("Remove Volcano Boulders", function()
    local v79 = game:GetService("Workspace")
    v79.Region_Volcano.PartSpawner.Destroy(v79.Region_Volcano.PartSpawner)
    return
end)
v77:Toggle("Bridge", false, function(p0)
    local v79 = game:GetService("Workspace")
    local v80, v81 = v79.Bridge.VerticalLiftBridge.Lift:GetChildren()
    local v82 = Vector3.new(0, -26, 0)
    nil.CFrame = nil.CFrame + v82
    local v83 = Vector3.new(0, 26, 0)
    nil.CFrame = nil.CFrame + v83
    v84, v85 = next(v80, v81)
    if v84 ~= nil then v81 = v84 end
    return
end)
v77:Toggle("Auto Calm Rukiryaxe ", false, function(p0)
    _G.自动拿鲨鱼斧头(p0)
    _G.菜单.自动拿鲨鱼斧头 = p0
    return
end)
v77:Toggle("Water Gold Mode ", false, function(p0)
    _G.菜单.水中无敌 = p0
    return
end)
v77:Toggle("Leaked item  ", false, function(p0)
    upvalue_0.Enabled = p0
    return
end)
v77:Button("Bring Swamp Bridge", function()
    local v79 = game:GetService("Workspace")
    local v80 = v79.Region_Mountainside.SlabRegen:FindFirstChild("Slab")
    v80.PrimaryPart = v80.PushMe
    wait("Slab")
    _G.拉东西:FireServer(v80.PrimaryPart)
    v80:PivotTo(_G.自己的方块.CFrame)
    _G.拉东西:FireServer(v80.Slider)
    task.wait(_G.拉东西)
    1 = 1 + 1
    if 1 <= 6 then
    -- continue loop (PC + -17)
    end
    return
end)
_G.处理树 = function(p0)
    local v79, v80 = _G.检查斧头(p0.TreeClass.Value)
    _G.伤害 = v80
    _G.斧头 = v79
    return _G.提醒("you need one axe")
    return ...
    local v84 = Vector3.new(0,7, 0, 0)
    _G.锯木机 = _G.菜单.选择的锯木机.Particles.CFrame + v84
    _G.保留 = nil
    local v85, v86 = p0:GetChildren()
    local v87 = tostring(p0.TreeClass.Value)
    local v88 = tostring(p0.TreeClass.Value)
    local v89 = 0:GetChildren()
    v91, v92 = next(v89, v90)
    if v91 ~= nil then v90 = v91 end
    local v93 = v92:WaitForChild("ID")
    local v94 = v92:FindFirstChild("ChildIDs")
    local v95 = v94:GetChildren()
    local v96 = v92:FindFirstChild("ParentID")
    _G.保留 = _G.保留
    v98, v99 = next(v89, v97)
    if v98 ~= nil then v97 = v98 end
    local v100 = 0:WaitForChild("ID")
    local v101 = 0:FindFirstChild("ChildIDs")
    local v102 = v101:GetChildren()
    local v103 = 0:FindFirstChild("ParentID")
    _G.保留 = _G.保留
    wait(_G.保留.Size.Z)
    _G.保留 = 0
    v104, v105 = next(v85, v86)
    if v104 ~= nil then v86 = v104 end
    _G.烧毁 = nil
    local v106, v107 = _G.保留.Parent:GetChildren()
    local v108 = v105:WaitForChild("ID")
    wait(_G.保留.ParentID.Value)
    _G.烧毁 = v105
    v109, v110 = next(v106, v107)
    if v109 ~= nil then v107 = v109 end
    return _G.提醒("cant mod this wood")
    return ...
    local v114 = Instance.new("BoxHandleAdornment", _G.保留)
    v114.Name = "Selection"
    v114.Adornee = v114.Parent
    v114.AlwaysOnTop = true
    v114.ZIndex = 0
    v114.Size = v114.Parent.Size
    v114.Transparency = 0
    local v115 = BrickColor.new("Lime green")
    v114.Color = v115
    _G.菜单.飞行 = true
    spawn(function()
    _G.飞行(true)
    return
end)
    _G.旧的飞行速度 = _G.菜单.飞行速度
    _G.菜单.飞行速度 = 0
    _G.传送(p0.WoodSection.CFrame)
    spawn(function()
    _G.拉东西.FireServer(_G.拉东西, upvalue_0)
    local v116, v117, v118 = CFrame.new(-1665,86548, 355,800415, 1478,47742)
    upvalue_0:PivotTo(v116)
    pcall(function()
    spawn(function()
    local v119 = Vector3.new(0, 0, 0)
    _G.岩浆.Size = v119
    local v120 = Vector3.new(0, 0, 0)
    _G.岩浆.Size = v120
    return
end)
    _G.岩浆.CFrame = _G.烧毁.CFrame
    local v119 = Vector3.new(0, 0, 0)
    _G.岩浆.Size = v119
    local v120 = Vector3.new(0, 0, 0)
    _G.岩浆.Size = v120
    local v121 = Vector3.new(0, 0, 0)
    _G.岩浆.Size = v121
    return
end)
    return
end)
    game["Run Service"].Heartbeat:wait()
    local v116 = _G.烧毁:FindFirstChild("LavaFire")
    local v117 = CFrame.new(-1675,2002, 255,002533, 1284,19983, 0,866007268, 0, 0,500031412, 0, 1, 0, -0,500031412, 0, 0,866007268)
    _G.岩浆.CFrame = v117
    local v118 = _G.烧毁:FindFirstChild("LavaFire")
    v118:Destroy()
    _G.烧毁.AncestryChanged:Connect(function()
    upvalue_0 = true
    return
end)
    _G.拉东西:FireServer(false)
    _G.拉东西:FireServer(false)
    local v119 = Vector3.new(0, 0, 0)
    false.WoodSection.Velocity = v119
    local v120 = Vector3.new(0, 0, 0)
    false.WoodSection.RotVelocity = v120
    local v121, v122, v123 = CFrame.new(-904, 150, -3396)
    false:PivotTo(v121)
    _G.拉东西:FireServer(false)
    task.wait(_G.拉东西)
    1 = 1 + 1
    if 1 <= 30 then
    -- continue loop (PC + -38)
    end
    _G.传送(_G.烧毁.CFrame)
    _G.拉东西:FireServer(false)
    local v124, v125, v126 = CFrame.new(315, 5, 85,4999924)
    _G.烧毁:PivotTo(v124)
    _G.拉东西:FireServer(false)
    game["Run Service"].Heartbeat:wait()
    _G.完成 = false
    local v127 = game:GetService("Workspace")
    local v128 = v127.LogModels.ChildAdded:Connect(function(p0)
    local v128 = p0:WaitForChild("Owner", 1)
    _G.完成 = true
    return
end)
    _G.菜单.飞行 = false
    spawn(function()
    _G.飞行(false)
    return
end)
    _G.菜单.飞行速度 = _G.旧的飞行速度
    local v129 = CFrame.new(false.WoodSection.CFrame.p)
    local v130 = Vector3.new(3, 0, 0)
    _G.传送(v129 + v130)
    spawn(function()
    _G.拉东西.FireServer(_G.拉东西, upvalue_0)
    local v131 = Vector3.new(upvalue_0)
    _G.保留.Velocity = v131
    local v132 = Vector3.new(upvalue_0)
    _G.保留.RotVelocity = v132
    _G.保留.PivotTo(_G.保留, _G.锯木机)
    game["Run Service"].Heartbeat.wait(game["Run Service"].Heartbeat)
    return
end)
    local v131 = CFrame.new(false.WoodSection.CFrame.p)
    local v132 = Vector3.new(5, 0, 0)
    _G.传送(v131 + v132)
    _G.砍(false.CutEvent, _G.斧头, 1, 0,3, _G.伤害)
    game["Run Service"].Heartbeat:wait()
    v128:Disconnect()
    _G.传送(_G.自己.Character.HumanoidRootPart.CFrame)
    return
end
local v79 = v24:CreateTab("Wood", "6034503369")
local v80 = v79:Section("Bring Tree")
local v81 = {}
v81 = {"Generic", "GoldSwampy", "CaveCrawler", "Cherry", "Frost", "Volcano", "Oak", "Walnut", "Birch", "SnowGlow", "Pine", "GreenSwampy", "Koa", "Palm", "LoneCave", "Spooky", "SpookyNeon"}
v80:DropDown("Select Tree", v81, false, false, function(p0)
    _G.菜单.选择的树 = p0
    return
end)
local v82 = {}
v82 = {"Largest", "Smallest"}
v80:DropDown("Select TreeGetMethod", v82, false, false, function(p0)
    _G.菜单.树的大小 = "big"
    _G.菜单.树的大小 = "Smallest"
    return
end)
v80:TextBox("Tree Amount", "1", function(p0)
    local v83 = tonumber(p0)
    _G.菜单.带来树的数量 = v83
    return
end)
v80:Button("Bring", function()
    _G.菜单.树放置的地点 = _G.自己的方块.CFrame
    _G.菜单.停止砍树 = false
    _G.带来树(_G.菜单.选择的树)
    task.wait(_G.菜单.选择的树)
    1 = 1 + 1
    if 1 <= _G.菜单.带来树的数量 then
    -- continue loop (PC + -10)
    end
    _G.传送(_G.菜单.树放置的地点)
    return
end)
v80:Button("Abort", function()
    _G.菜单.停止砍树 = true
    return
end)
v80:Button("tp to Spooky /SpookyNeon  tree", function()
    local v83, v84 = Workspace:GetChildren()
    local v85, v86 = v20:GetChildren()
    local v87 = function(p0)
    local v28 = p0:FindFirstChildOfClass("MeshPart")
    local v29 = p0:FindFirstChildOfClass("MeshPart")
    p0.PrimaryPart = v29
    return
    local v30 = p0:FindFirstChildOfClass("Part")
    local v31 = p0:FindFirstChildOfClass("MeshPart")
    local v32 = p0:FindFirstChild("Main")
    p0.PrimaryPart = v32
    return
end:FindFirstChild("TreeClass")
    local v88 = function(p0)
    local v28 = p0:FindFirstChildOfClass("MeshPart")
    local v29 = p0:FindFirstChildOfClass("MeshPart")
    p0.PrimaryPart = v29
    return
    local v30 = p0:FindFirstChildOfClass("Part")
    local v31 = p0:FindFirstChildOfClass("MeshPart")
    local v32 = p0:FindFirstChild("Main")
    p0.PrimaryPart = v32
    return
end:FindFirstChild("Owner")
    local v89 = tostring(function(p0)
    local v28 = p0:FindFirstChildOfClass("MeshPart")
    local v29 = p0:FindFirstChildOfClass("MeshPart")
    p0.PrimaryPart = v29
    return
    local v30 = p0:FindFirstChildOfClass("Part")
    local v31 = p0:FindFirstChildOfClass("MeshPart")
    local v32 = p0:FindFirstChild("Main")
    p0.PrimaryPart = v32
    return
end.TreeClass.Value)
    local v90 = tostring(function(p0)
    local v28 = p0:FindFirstChildOfClass("MeshPart")
    local v29 = p0:FindFirstChildOfClass("MeshPart")
    p0.PrimaryPart = v29
    return
    local v30 = p0:FindFirstChildOfClass("Part")
    local v31 = p0:FindFirstChildOfClass("MeshPart")
    local v32 = p0:FindFirstChild("Main")
    p0.PrimaryPart = v32
    return
end.TreeClass.Value)
    local v91 = tostring(function(p0)
    local v28 = p0:FindFirstChildOfClass("MeshPart")
    local v29 = p0:FindFirstChildOfClass("MeshPart")
    p0.PrimaryPart = v29
    return
    local v30 = p0:FindFirstChildOfClass("Part")
    local v31 = p0:FindFirstChildOfClass("MeshPart")
    local v32 = p0:FindFirstChild("Main")
    p0.PrimaryPart = v32
    return
end.Owner.Value)
    local v92 = function(p0)
    local v28 = p0:FindFirstChildOfClass("MeshPart")
    local v29 = p0:FindFirstChildOfClass("MeshPart")
    p0.PrimaryPart = v29
    return
    local v30 = p0:FindFirstChildOfClass("Part")
    local v31 = p0:FindFirstChildOfClass("MeshPart")
    local v32 = p0:FindFirstChild("Main")
    p0.PrimaryPart = v32
    return
end:FindFirstChild("WoodSection")
    _G.传送(function(p0)
    local v28 = p0:FindFirstChildOfClass("MeshPart")
    local v29 = p0:FindFirstChildOfClass("MeshPart")
    p0.PrimaryPart = v29
    return
    local v30 = p0:FindFirstChildOfClass("Part")
    local v31 = p0:FindFirstChildOfClass("MeshPart")
    local v32 = p0:FindFirstChild("Main")
    p0.PrimaryPart = v32
    return
end.WoodSection.CFrame)
    v93, v94 = next(v85, v86)
    if v93 ~= nil then v86 = v93 end
    v95, v96 = next(v83, v84)
    if v95 ~= nil then v84 = v95 end
    return
end)
_G.选择锯木机 = function()
    _G.提醒("Click one  Sawmill")
    local v83 = _G.鼠标.Button1Up:Connect(function()
    wait(_G.鼠标.Button1Up.Connect)
    local v83 = _G.鼠标.Target.Parent:FindFirstChild("Settings")
    local v84 = _G.鼠标.Target.Parent.Settings:FindFirstChild("DimZ")
    upvalue_0 = _G.鼠标.Target.Parent
    _G.提醒("Sawmill Selected")
    local v85 = _G.鼠标.Target.Parent.Parent:FindFirstChild("Settings")
    local v86 = _G.鼠标.Target.Parent.Parent.Settings:FindFirstChild("DimZ")
    upvalue_0 = _G.鼠标.Target.Parent.Parent
    _G.提醒("Sawmill Selected")
    return
end)
    task.wait(0,1)
    v83:Disconnect()
    return v51
end
local v83 = v79:Section("Mod")
local v84 = v83:Label("Please Selecet one Sawmill")
_G.处理树锯木机 = v84
v83:Button("select Sawmill", function()
    local v85 = _G.选择锯木机(v15)
    _G.菜单.选择的锯木机 = v85
    _G.处理树锯木机.Text = "Selected"
    return
end)
v83:Button("Mod Wood", function()
    return _G.提醒("select Sawmail At First")
    return ...
    return _G.提醒("you are using this feature")
    return ...
    _G.菜单.正在处理树 = true
    _G.提醒("Click one Wood ")
    local v91 = _G.鼠标.Button1Up:Connect(function()
    wait(_G.鼠标.Button1Up.Connect)
    local v91 = _G.鼠标.Target.Parent:FindFirstChild("Owner")
    local v92 = _G.鼠标.Target.Parent:FindFirstChild("WoodSection")
    local v93 = _G.鼠标.Target.Parent:FindFirstAncestor("TreeRegion")
    local v94 = _G.鼠标.Target.Parent:FindFirstChild("RootCut")
    wait(_G.鼠标.Target.Parent)
    upvalue_0 = _G.鼠标.Target.Parent
    _G.提醒("Wood Selected")
    return
end)
    task.wait(0,1)
    v91:Disconnect()
    _G.处理树(nil)
    _G.菜单.正在处理树 = false
    return
end)
v83:Button("Mod Sawmill", function()
    local v85 = _G.自己.PlayerBlueprints.Blueprints.FindFirstChild(_G.自己.PlayerBlueprints.Blueprints, "Floor2")
    local v86 = game.Workspace.PlayerModels.ChildAdded.connect(game.Workspace.PlayerModels.ChildAdded, function(p0)
    spawn(function()
    local v86 = game:GetService("ReplicatedStorage")
    v86.Interaction.ClientInteracted.FireServer(v86.Interaction.ClientInteracted, upvalue_0, "Open box")
    return
end)
    return
end)
    _G.自动购买v2("Floor2", 1)
    wait(1)
    v86:Disconnect()
    local v87 = _G.菜单.选择的锯木机.Conveyor.Model:GetChildren()
    local v88 = _G.菜单.选择的锯木机.ItemName.Value:match("Sawmill4L")
    #v87 = #v87 + 1
    if #v87 <= #v87 then
    -- continue loop (PC + -3)
    end
    local v89 = Vector3.new(0, 1,5, false)
    local v90 = CFrame.new(v87[v24].CFrame.p + v89)
    local v91 = math.rad(45)
    local v92 = math.rad(90)
    local v93, v94, v95 = math.rad(45)
    local v96 = CFrame.Angles(v93)
    game.ReplicatedStorage.PlaceStructure.ClientPlacedBlueprint:FireServer("Floor2", v90 * v96, _G.自己)
    task.wait(1,5)
    1 = 1 + 1
    if 1 <= 4 then
    -- continue loop (PC + -83)
    end
    return
end)
v83:Button("Max Sawmill Settings", function()
    return _G.提醒("select Sawmail At First")
    return ...
    local v88 = game:GetService("ReplicatedStorage")
    v88.Interaction.RemoteProxy:FireServer(_G.菜单.选择的锯木机.ButtonRemote_XUp)
    task.wait(1)
    local v89 = game:GetService("ReplicatedStorage")
    v89.Interaction.RemoteProxy:FireServer(_G.菜单.选择的锯木机.ButtonRemote_YUp)
    task.wait(1)
    1 = 1 + 1
    if 1 <= 20 then
    -- continue loop (PC + -33)
    end
    return
end)
v83:Button("Lowest Sawmill Settings", function()
    return _G.提醒("select Sawmail At First")
    return ...
    local v88 = game:GetService("ReplicatedStorage")
    v88.Interaction.RemoteProxy:FireServer(_G.菜单.选择的锯木机.ButtonRemote_XDown)
    task.wait(1)
    local v89 = game:GetService("ReplicatedStorage")
    v89.Interaction.RemoteProxy:FireServer(_G.菜单.选择的锯木机.ButtonRemote_YDown)
    task.wait(1)
    1 = 1 + 1
    if 1 <= 20 then
    -- continue loop (PC + -33)
    end
    return
end)
_G.拿蛋 = function()
    local v85, v86 = Workspace:GetChildren()
    local v87, v88 = v24:GetChildren()
    local v89 = v28:FindFirstChild("TreeClass")
    local v90 = tostring(v28.TreeClass.Value)
    local v91 = v28:FindFirstChild("Owner")
    local v92 = v28:FindFirstChild("WoodSection")
    local v93, v94 = v28:GetChildren()
    local v95 = v53:FindFirstChild("ID")
    local v96 = v53.ChildIDs:GetChildren()
    v97, v98 = next(v93, v94)
    if v97 ~= nil then v94 = v97 end
    v99, v100 = next(v87, v88)
    if v99 ~= nil then v88 = v99 end
    v101, v102 = next(v85, v86)
    if v101 ~= nil then v86 = v101 end
    local v103 = Workspace.LogModels.ChildAdded:Connect(function(p0)
    p0:WaitForChild("Owner", 60)
    p0:WaitForChild("Owner", 60)
    local v103 = p0:WaitForChild("WoodSection", 60)
    p0.PrimaryPart = v103
    local v104 = p0:WaitForChild("Owner", 60)
    local v105 = tostring(p0.TreeClass.Value)
    upvalue_0 = true
    _G.传送(p0.WoodSection.CFrame)
    upvalue_1(p0, workspace.Egger.Pedestal.Zone.CFrame)
    local v106 = Vector3.new(5, 0, 0)
    _G.传送(workspace.Egger.Pedestal.Zone.CFrame + v106)
    return
end)
    local v104, v105 = _G.检查斧头("Oak")
    game["Run Service"].Heartbeat:wait()
    local v106 = Vector3.new(3, 0, 0)
    _G.传送(upvalue_0.CFrame + v106)
    _G.砍(upvalue_0.Parent.CutEvent, v104, upvalue_0.ID.Value, upvalue_0.Size.Y - 4 / upvalue_0.Size.X * upvalue_0.Size.X + 0,01, v105)
    v103:Disconnect()
    local v107 = workspace.PlayerModels.ChildAdded:Connect(function(p0)
    p0:WaitForChild("Owner", 60)
    p0:WaitForChild("Owner", 60)
    local v107 = p0:WaitForChild("Main", 60)
    p0.PrimaryPart = v107
    local v108 = p0:WaitForChild("Owner", 60)
    local v109 = tostring(p0.ItemName.Value)
    upvalue_0 = true
    wait(1)
    _G.传送(p0.Main.CFrame)
    upvalue_1(p0, upvalue_2)
    _G.传送(upvalue_2)
    return
end)
    wait(function(p0)
    p0:WaitForChild("Owner", 60)
    p0:WaitForChild("Owner", 60)
    local v107 = p0:WaitForChild("Main", 60)
    p0.PrimaryPart = v107
    local v108 = p0:WaitForChild("Owner", 60)
    local v109 = tostring(p0.ItemName.Value)
    upvalue_0 = true
    wait(1)
    _G.传送(p0.Main.CFrame)
    upvalue_1(p0, upvalue_2)
    _G.传送(upvalue_2)
    return
end)
    v107:Disconnect()
    return
end
_G.自动赚钱 = function(p0)
    _G.已经处理好 = false
    local v85 = game.Workspace.LogModels.ChildAdded:Connect(function(p0)
    local v85 = p0:WaitForChild("Owner", 60)
    local v86 = p0:FindFirstChild("WoodSection")
    p0.PrimaryPart = v86
    _G.卖木板 = nil
    _G.已经处理好 = false
    _G.处理树(p0)
    local v87 = game.Workspace.PlayerModels.ChildAdded:connect(function(p0)
    local v87 = p0:FindFirstChild("Owner")
    local v88 = p0:FindFirstChild("TreeClass")
    local v89 = p0:FindFirstChild("WoodSection")
    wait(p0)
    local v90 = p0:FindFirstChild("TreeClass")
    _G.传送(p0.WoodSection.CFrame)
    _G.拉东西:FireServer(p0)
    task.wait(_G.拉东西)
    1 = 1 + 1
    if 1 <= 10 then
    -- continue loop (PC + -9)
    end
    local v91, v92, v93 = CFrame.new(315, 0, 84)
    p0:PivotTo(v91)
    game.ReplicatedStorage.TestPing:InvokeServer()
    game.ReplicatedStorage.TestPing:InvokeServer()
    task.wait(game.ReplicatedStorage.TestPing)
    1 = 1 + 1
    if 1 <= 2 then
    -- continue loop (PC + -35)
    end
    local v94, v95, v96 = CFrame.new(315, 0, 84)
    _G.传送(v94)
    _G.已经处理好 = true
    wait(0,2)
    _G.已经处理好 = false
    pcall(function()
    _G.卖木板.Disconnect(_G.卖木板)
    _G.卖木板 = nil
    return
end)
    return
end)
    _G.卖木板 = v87
    _G.卖木头(v87)
    _G.已经处理好 = true
    return
end)
    _G.树的加入 = v85
    local v86 = task.wait(0,1)
    _G.已经处理好 = false
    _G.带来树(_G.菜单.选择的树)
    task.wait(_G.菜单.选择的树)
    _G.已经处理好 = false
    _G.已经处理好 = false
    task.wait(0,2)
    _G.树的加入:Disconnect()
    _G.树的加入 = nil
    return
end
_G.砍好了 = false
_G.自动砍 = function(p0)
    _G.菜单.自动砍:Disconnect()
    _G.菜单.自动砍的链接:Disconnect()
    return
    local v85 = game:GetService("Workspace")
    local v86 = v85.LogModels.ChildAdded:Connect(function(p0)
    local v86 = p0:WaitForChild("Owner")
    _G.砍好了 = true
    return
end)
    _G.菜单.自动砍的链接 = v86
    local v87 = _G.鼠标.Button1Up:Connect(function()
    local v87 = tostring(_G.鼠标.Target.Parent.Owner.Value)
    _G.选择的木头 = _G.鼠标.Target
    _G.砍好了 = false
    local v88 = _G.选择的木头.CFrame:pointToObjectSpace(_G.鼠标.Hit.p)
    _G.砍的地方 = v88.Y + _G.选择的木头.Size.Y / 2
    local v89, v90 = _G.检查斧头(_G.选择的木头.Parent.TreeClass.Value)
    _G.伤害 = v90
    _G.斧头 = v89
    return _G.提醒("you need one axe")
    return ...
    _G.砍(_G.选择的木头.Parent.CutEvent, _G.斧头, _G.选择的木头.ID.Value, _G.砍的地方, _G.伤害)
    task.wait(_G.选择的木头.Parent.CutEvent)
    _G.砍好了 = false
    _G.提醒("Finished Cutting")
    return
end)
    _G.菜单.自动砍 = v87
    return
end
v83:Button("Get egg", function()
    _G.拿蛋(v13)
    return
end)
v83:Toggle("Auto Farm", false, function(p0)
    _G.自动赚钱(p0)
    return
end)
v83:Toggle("Mod Cut Wood", false, function(p0)
    return _G.提醒("select Sawmail At First")
    return ...
    _G.菜单.处理砍好的木头 = p0
    return
end)
local v85 = v79:Section("Misc")
v85:Toggle("One Unit Cutter", false, function(p0)
    _G.木板加入:Disconnect()
    _G.砍树:Disconnect()
    return
    _G.被砍木板 = nil
    local v86 = game:GetService("Workspace")
    local v87 = v86.PlayerModels.ChildAdded:Connect(function(p0)
    local v87 = p0:WaitForChild("TreeClass")
    local v88 = p0:WaitForChild("WoodSection")
    _G.被砍木板 = p0
    task.wait(p0)
    return
end)
    _G.木板加入 = v87
    local v88 = _G.鼠标.Button1Up:Connect(function()
    _G.被砍木板 = _G.鼠标.Target.Parent
    local v88 = Vector3.new(0, 3, -3)
    _G.传送(_G.鼠标.Target.CFrame + v88)
    local v89, v90 = _G.检查斧头(_G.被砍木板.TreeClass.Value)
    _G.伤害 = v90
    _G.斧头 = v89
    _G.砍(_G.被砍木板.CutEvent, _G.斧头, 1, 1, _G.伤害)
    local v91 = _G.被砍木板:FindFirstChild("Cut")
    local v92 = _G.被砍木板:FindFirstChild("Cut")
    local v93 = Vector3.new(0, 3, -3)
    _G.传送(v92.CFrame + v93)
    task.wait(v92.CFrame + v93)
    return
end)
    _G.砍树 = v88
    return
end)
v85:Button("Cut Tree Joints", function()
    _G.提醒("Click one Wood")
    local v86 = _G.鼠标.Button1Up:Connect(function()
    wait(_G.鼠标.Button1Up.Connect)
    local v86 = _G.鼠标.Target.Parent:FindFirstChild("Owner")
    local v87 = _G.鼠标.Target.Parent:FindFirstChild("WoodSection")
    local v88 = _G.鼠标.Target.Parent:FindFirstAncestor("TreeRegion")
    local v89 = _G.鼠标.Target.Parent:FindFirstChild("RootCut")
    wait(_G.鼠标.Target.Parent)
    upvalue_0 = _G.鼠标.Target.Parent
    _G.提醒("Clicked")
    return
end)
    task.wait(0,1)
    v86:Disconnect()
    local v87 = {}
    _G.需要被砍的树 = v87
    local v88, v89 = function(p0, p1)
    upvalue_0(p0)
    spawn(function()
    local v28 = Vector3.new(0, 0, 0)
    upvalue_0.PrimaryPart.Velocity = v28
    local v29 = Vector3.new(0, 0, 0)
    upvalue_0.PrimaryPart.RotVelocity = v29
    game.ReplicatedStorage.TestPing:InvokeServer()
    task.wait(game.ReplicatedStorage.TestPing)
    1 = 1 + 1
    if 1 <= 10 then
    -- continue loop (PC + -27)
    end
    return
end)
    local v28 = identifyexecutor(function()
    local v28 = Vector3.new(0, 0, 0)
    upvalue_0.PrimaryPart.Velocity = v28
    local v29 = Vector3.new(0, 0, 0)
    upvalue_0.PrimaryPart.RotVelocity = v29
    game.ReplicatedStorage.TestPing:InvokeServer()
    task.wait(game.ReplicatedStorage.TestPing)
    1 = 1 + 1
    if 1 <= 10 then
    -- continue loop (PC + -27)
    end
    return
end)
    print(p0.PrimaryPart)
    game.ReplicatedStorage.Interaction.ClientIsDragging:FireServer(p0)
    task.wait(0,2)
    local v29 = isnetworkowner(p0.PrimaryPart)
    game.ReplicatedStorage.Interaction.ClientIsDragging:FireServer(p0)
    local v30 = p0:FindFirstChild("WoodSection")
    p0.PrimaryPart.CFrame = p1
    p0:PivotTo(p1)
    return
    local v31 = tostring(p0.Parent)
    game.ReplicatedStorage.Interaction.ClientIsDragging:FireServer(p0)
    upvalue_0(p0)
    p0.PrimaryPart.CFrame = p1
    game.ReplicatedStorage.TestPing:InvokeServer()
    task.wait(game.ReplicatedStorage.TestPing)
    1 = 1 + 1
    if 1 <= 6 then
    -- continue loop (PC + -21)
    end
    return
    game.ReplicatedStorage.Interaction.ClientIsDragging:FireServer(p0)
    local v32 = p0:FindFirstChild("WoodSection")
    upvalue_0(p0)
    p0.PrimaryPart.CFrame = p1
    p0:PivotTo(p1)
    game.ReplicatedStorage.TestPing:InvokeServer()
    task.wait(game.ReplicatedStorage.TestPing)
    1 = 1 + 1
    if 1 <= 3 then
    -- continue loop (PC + -30)
    end
    return
end:GetChildren()
    local v90 = v24:FindFirstChild("Tree Weld")
    table.insert(_G.需要被砍的树, v24)
    v91, v92 = next(v88, v89)
    if v91 ~= nil then v89 = v91 end
    local v93, v94 = _G.检查斧头(function(p0, p1)
    upvalue_0(p0)
    spawn(function()
    local v28 = Vector3.new(0, 0, 0)
    upvalue_0.PrimaryPart.Velocity = v28
    local v29 = Vector3.new(0, 0, 0)
    upvalue_0.PrimaryPart.RotVelocity = v29
    game.ReplicatedStorage.TestPing:InvokeServer()
    task.wait(game.ReplicatedStorage.TestPing)
    1 = 1 + 1
    if 1 <= 10 then
    -- continue loop (PC + -27)
    end
    return
end)
    local v28 = identifyexecutor(function()
    local v28 = Vector3.new(0, 0, 0)
    upvalue_0.PrimaryPart.Velocity = v28
    local v29 = Vector3.new(0, 0, 0)
    upvalue_0.PrimaryPart.RotVelocity = v29
    game.ReplicatedStorage.TestPing:InvokeServer()
    task.wait(game.ReplicatedStorage.TestPing)
    1 = 1 + 1
    if 1 <= 10 then
    -- continue loop (PC + -27)
    end
    return
end)
    print(p0.PrimaryPart)
    game.ReplicatedStorage.Interaction.ClientIsDragging:FireServer(p0)
    task.wait(0,2)
    local v29 = isnetworkowner(p0.PrimaryPart)
    game.ReplicatedStorage.Interaction.ClientIsDragging:FireServer(p0)
    local v30 = p0:FindFirstChild("WoodSection")
    p0.PrimaryPart.CFrame = p1
    p0:PivotTo(p1)
    return
    local v31 = tostring(p0.Parent)
    game.ReplicatedStorage.Interaction.ClientIsDragging:FireServer(p0)
    upvalue_0(p0)
    p0.PrimaryPart.CFrame = p1
    game.ReplicatedStorage.TestPing:InvokeServer()
    task.wait(game.ReplicatedStorage.TestPing)
    1 = 1 + 1
    if 1 <= 6 then
    -- continue loop (PC + -21)
    end
    return
    game.ReplicatedStorage.Interaction.ClientIsDragging:FireServer(p0)
    local v32 = p0:FindFirstChild("WoodSection")
    upvalue_0(p0)
    p0.PrimaryPart.CFrame = p1
    p0:PivotTo(p1)
    game.ReplicatedStorage.TestPing:InvokeServer()
    task.wait(game.ReplicatedStorage.TestPing)
    1 = 1 + 1
    if 1 <= 3 then
    -- continue loop (PC + -30)
    end
    return
end.TreeClass.Value)
    _G.伤害 = v94
    _G.斧头 = v93
    return _G["you need one axe"]
    local v95 = game:GetService("Workspace")
    local v96 = v95.LogModels.ChildAdded:Connect(function(p0)
    p0:WaitForChild("Owner")
    upvalue_0 = true
    return
end)
    local v97 = CFrame.new(_G.需要被砍的树.Parent.WoodSection.CFrame.p)
    local v98 = Vector3.new(3, 0, 0)
    _G.传送(v97 - v98)
    local v99, v100 = _G.检查斧头(_G.需要被砍的树.Parent.TreeClass.Value)
    _G.伤害 = v100
    _G.斧头 = v99
    _G.砍(_G.需要被砍的树.Parent.CutEvent, _G.斧头, _G.需要被砍的树.ID.Value, _G.需要被砍的树.Size.Y - 0,1, _G.伤害)
    game["Run Service"].Heartbeat:wait()
    task.wait(0,1)
    v102, v103 = next(_G.需要被砍的树, v101)
    if v102 ~= nil then v101 = v102 end
    pcall(function()
    upvalue_0:Disconnect()
    upvalue_0 = nil
    return
end)
    return
end)
v85:Toggle("Auto Chop", false, function(p0)
    _G.菜单.自动砍开启 = p0
    _G.自动砍(p0)
    return
end)
v85:Toggle("Hard Dragger", false, function(p0)
    _G.菜单.大力 = p0
    return
end)
v85:Toggle("View phantom tree", false, function(p0)
    local v86, v87 = game.Workspace:GetChildren()
    local v88 = v24:FindFirstChildOfClass("Model")
    game.Workspace.Camera.CameraSubject = v24.Model.WoodSection
    v89, v90 = next(v86, v87)
    if v89 ~= nil then v87 = v89 end
    return _G.提醒("Not Found Phantom Tree ")
    return ...
    game.Workspace.Camera.CameraSubject = _G.自己身体
    return
end)
_G.点击卖木板 = nil
_G.鼠标移动 = nil
v85:Toggle("Click to Sell Plank", false, function(p0)
    local v86 = Instance.new("SelectionBox", game.Workspace.PlayerModels)
    _G.点击卖木头选择框 = v86
    local v87 = _G.鼠标.Move:Connect(function()
    _G.点击 = _G.鼠标.Target
    local v87 = _G.点击.Parent.FindFirstChild(_G.点击.Parent, "Owner")
    local v88 = _G.点击.Parent.FindFirstChild(_G.点击.Parent, "TreeClass")
    local v89 = _G.点击.FindFirstAncestor(_G.点击, "PlayerModels")
    _G.点击卖木头选择框.LineThickness = 0,1
    _G.点击卖木头选择框.Adornee = _G.鼠标.Target
    local v90 = Color3.new(1, 0, 0)
    _G.点击卖木头选择框.Color3 = v90
    _G.点击卖木头选择框.Adornee = game.Workspace.PlayerModels
    return
end)
    _G.鼠标移动 = v87
    local v88 = _G.鼠标.Button1Up:Connect(function()
    _G.点击2 = _G.鼠标.Target
    local v88 = _G.点击2.Parent.FindFirstChild(_G.点击2.Parent, "Owner")
    local v89 = _G.点击2.Parent.FindFirstChild(_G.点击2.Parent, "TreeClass")
    local v90 = _G.点击2.Parent.FindFirstAncestor(_G.点击2.Parent, "PlayerModels")
    local v91 = _G.点击2.Parent.FindFirstChild(_G.点击2.Parent, "WoodSection")
    _G.传送(_G.点击2.Parent.WoodSection.CFrame)
    spawn(function()
    local v92 = _G.点击2.Parent:FindFirstChild("Owner")
    local v93 = _G.点击2.Parent:FindFirstChild("TreeClass")
    local v94 = _G.点击2.Parent:FindFirstAncestor("PlayerModels")
    local v95 = _G.点击2.Parent:FindFirstChild("WoodSection")
    pcall(function()
    _G.拉东西.FireServer(_G.拉东西, _G.点击2.Parent)
    local v96, v97, v98 = CFrame.new(315, 0, 85,4999924)
    _G.点击2.Parent.PivotTo(v96)
    return
end)
    game["Run Service"].Heartbeat:wait()
    1 = 1 + 1
    if 1 <= 30 then
    -- continue loop (PC + -50)
    end
    return
end)
    wait(0,2)
    _G.传送(_G.自己的方块.CFrame)
    task.wait(0,5)
    _G.点击2.Anchored = true
    return
end)
    _G.点击卖木板 = v88
    pcall(function()
    _G.点击卖木头选择框.Destroy(_G.点击卖木头选择框)
    return
end)
    _G.点击卖木板:Disconnect()
    _G.鼠标移动:Disconnect()
    _G.点击卖木板 = nil
    _G.鼠标移动 = nil
    return
end)
v85:Button("Bring All Tree", function()
    local v86 = game:GetService("Workspace")
    local v87, v88 = v86.LogModels:GetChildren()
    local v89 = nil:FindFirstChild("Owner")
    _G.传送(nil.WoodSection.CFrame)
    _G.拉东西:FireServer(nil)
    nil:PivotTo(_G.自己的方块.CFrame)
    local v90 = game:GetService("RunService")
    v90.Stepped:wait()
    1 = 1 + 1
    if 1 <= 20 then
    -- continue loop (PC + -16)
    end
    task.wait(20)
    v91, v92 = next(v87, v88)
    if v91 ~= nil then v88 = v91 end
    task.wait(v87)
    _G.传送(_G.自己的方块.CFrame)
    _G.提醒("Done")
    return
end)
v85:Button("Sell All Tree", function()
    _G.卖木头(v13)
    _G.提醒("Done")
    return
end)
v85:Button("Bring All Plank", function()
    local v86, v87 = game.Workspace.PlayerModels:GetChildren()
    local v88 = nil:findFirstChild("Owner")
    local v89, v90 = nil:GetChildren()
    _G.传送(function(p0, p1)
    upvalue_0(p0)
    spawn(function()
    local v28 = Vector3.new(0, 0, 0)
    upvalue_0.PrimaryPart.Velocity = v28
    local v29 = Vector3.new(0, 0, 0)
    upvalue_0.PrimaryPart.RotVelocity = v29
    game.ReplicatedStorage.TestPing:InvokeServer()
    task.wait(game.ReplicatedStorage.TestPing)
    1 = 1 + 1
    if 1 <= 10 then
    -- continue loop (PC + -27)
    end
    return
end)
    local v28 = identifyexecutor(function()
    local v28 = Vector3.new(0, 0, 0)
    upvalue_0.PrimaryPart.Velocity = v28
    local v29 = Vector3.new(0, 0, 0)
    upvalue_0.PrimaryPart.RotVelocity = v29
    game.ReplicatedStorage.TestPing:InvokeServer()
    task.wait(game.ReplicatedStorage.TestPing)
    1 = 1 + 1
    if 1 <= 10 then
    -- continue loop (PC + -27)
    end
    return
end)
    print(p0.PrimaryPart)
    game.ReplicatedStorage.Interaction.ClientIsDragging:FireServer(p0)
    task.wait(0,2)
    local v29 = isnetworkowner(p0.PrimaryPart)
    game.ReplicatedStorage.Interaction.ClientIsDragging:FireServer(p0)
    local v30 = p0:FindFirstChild("WoodSection")
    p0.PrimaryPart.CFrame = p1
    p0:PivotTo(p1)
    return
    local v31 = tostring(p0.Parent)
    game.ReplicatedStorage.Interaction.ClientIsDragging:FireServer(p0)
    upvalue_0(p0)
    p0.PrimaryPart.CFrame = p1
    game.ReplicatedStorage.TestPing:InvokeServer()
    task.wait(game.ReplicatedStorage.TestPing)
    1 = 1 + 1
    if 1 <= 6 then
    -- continue loop (PC + -21)
    end
    return
    game.ReplicatedStorage.Interaction.ClientIsDragging:FireServer(p0)
    local v32 = p0:FindFirstChild("WoodSection")
    upvalue_0(p0)
    p0.PrimaryPart.CFrame = p1
    p0:PivotTo(p1)
    game.ReplicatedStorage.TestPing:InvokeServer()
    task.wait(game.ReplicatedStorage.TestPing)
    1 = 1 + 1
    if 1 <= 3 then
    -- continue loop (PC + -30)
    end
    return
end.CFrame)
    _G.拉东西:FireServer(nil)
    nil:PivotTo(_G.自己的方块.CFrame)
    local v91 = game:GetService("RunService")
    v91.Stepped:wait()
    1 = 1 + 1
    if 1 <= 30 then
    -- continue loop (PC + -16)
    end
    v92, v93 = next(v89, v90)
    if v92 ~= nil then v90 = v92 end
    task.wait(v89)
    v94, v95 = next(v86, v87)
    if v94 ~= nil then v87 = v94 end
    _G.传送(_G.自己的方块.CFrame)
    _G.提醒("Done")
    return
end)
v85:Button("Sell All Plank", function()
    local v86, v87 = game.Workspace.PlayerModels:GetChildren()
    local v88 = nil:findFirstChild("Owner")
    local v89, v90 = nil:GetChildren()
    _G.传送(function(p0, p1)
    upvalue_0(p0)
    spawn(function()
    local v28 = Vector3.new(0, 0, 0)
    upvalue_0.PrimaryPart.Velocity = v28
    local v29 = Vector3.new(0, 0, 0)
    upvalue_0.PrimaryPart.RotVelocity = v29
    game.ReplicatedStorage.TestPing:InvokeServer()
    task.wait(game.ReplicatedStorage.TestPing)
    1 = 1 + 1
    if 1 <= 10 then
    -- continue loop (PC + -27)
    end
    return
end)
    local v28 = identifyexecutor(function()
    local v28 = Vector3.new(0, 0, 0)
    upvalue_0.PrimaryPart.Velocity = v28
    local v29 = Vector3.new(0, 0, 0)
    upvalue_0.PrimaryPart.RotVelocity = v29
    game.ReplicatedStorage.TestPing:InvokeServer()
    task.wait(game.ReplicatedStorage.TestPing)
    1 = 1 + 1
    if 1 <= 10 then
    -- continue loop (PC + -27)
    end
    return
end)
    print(p0.PrimaryPart)
    game.ReplicatedStorage.Interaction.ClientIsDragging:FireServer(p0)
    task.wait(0,2)
    local v29 = isnetworkowner(p0.PrimaryPart)
    game.ReplicatedStorage.Interaction.ClientIsDragging:FireServer(p0)
    local v30 = p0:FindFirstChild("WoodSection")
    p0.PrimaryPart.CFrame = p1
    p0:PivotTo(p1)
    return
    local v31 = tostring(p0.Parent)
    game.ReplicatedStorage.Interaction.ClientIsDragging:FireServer(p0)
    upvalue_0(p0)
    p0.PrimaryPart.CFrame = p1
    game.ReplicatedStorage.TestPing:InvokeServer()
    task.wait(game.ReplicatedStorage.TestPing)
    1 = 1 + 1
    if 1 <= 6 then
    -- continue loop (PC + -21)
    end
    return
    game.ReplicatedStorage.Interaction.ClientIsDragging:FireServer(p0)
    local v32 = p0:FindFirstChild("WoodSection")
    upvalue_0(p0)
    p0.PrimaryPart.CFrame = p1
    p0:PivotTo(p1)
    game.ReplicatedStorage.TestPing:InvokeServer()
    task.wait(game.ReplicatedStorage.TestPing)
    1 = 1 + 1
    if 1 <= 3 then
    -- continue loop (PC + -30)
    end
    return
end.CFrame)
    spawn(function()
    _G.拉东西:FireServer(upvalue_0)
    local v91, v92, v93 = CFrame.new(315, 0, 84)
    upvalue_0:PivotTo(v91)
    task.wait(upvalue_0)
    1 = 1 + 1
    if 1 <= 100 then
    -- continue loop (PC + -18)
    end
    return
end)
    v91, v92 = next(v89, v90)
    if v91 ~= nil then v90 = v91 end
    task.wait(0,5)
    task.wait(0,5)
    v93, v94 = next(v86, v87)
    if v93 ~= nil then v87 = v93 end
    _G.传送(nil)
    _G.提醒("Done")
    return
end)
_G.获得土地 = function()
    local v86, v87 = _G.土地:GetChildren()
    local v88 = nil:FindFirstChild("Owner")
    v89, v90 = next(v86, v87)
    if v89 ~= nil then v87 = v89 end
    return nil
end
_G.正在选择土地 = _G.自己.PlayerGui.PropertyPurchasingGUI.PropertyPurchasingClient
local v86 = getsenv(_G.正在选择土地)
_G.选择的环境 = v86
_G.旧的点击 = _G.选择的环境.enterPurchaseMode
local v87 = getsenv(_G.正在选择土地)
v87.enterPurchaseMode = function(...)
    return _G.旧的点击(v87)
    return ...
    setupvalue(_G.选择的环境.rotate, 3, 0)
    local v91, v92, v93 = _G.获得土地(nil)
    setupvalue(v91)
    return
end
local v88 = v24:CreateTab("Slot", "6031090999")
local v89 = v88:Section("Slot")
v89:Slider("select slot", 1, 1, 6, false, function(p0)
    _G.菜单.存档 = p0
    return
end)
v89:Toggle("Fast Load", false, function(p0)
    _G.菜单.快速加载 = p0
    return
end)
v89:Button("Load Base", function()
    _G.加载(_G.菜单.存档)
    return
end)
v89:Button("Save Base", function()
    _G.保存基地(_G.菜单.存档)
    return
end)
v89:Button("Sell Sold Sign", function()
    _G.卖标志(v13)
    return
end)
v89:Toggle("Auto Farm Sold Sign", false, function(p0)
    _G.菜单.自动卖标志牌 = p0
    return
end)
local v90 = v88:Section("Sold Sign")
local v91 = {}
v90:DropDown("Select the player", v91, true, false, function(p0)
    _G.菜单.复制标志的玩家 = p0
    return
end)
v90:Toggle("Sold Sign Dupe", false, function(p0)
    _G.菜单.自动复制标志 = p0
    return
end)
local v92 = {}
v92 = {"-240, 19, 204, 1, 0, 0, 0, 1, 0, 0, 0, 1", "-61, 19, 526, 1, 0, 0, 0, 1, 0, 0, 0, 1"}
FindHillPlot = function()
    local v93, v94 = Workspace.Properties:GetChildren()
    local v95 = v20:FindFirstChild("Owner")
    local v96, v97, v98 = tostring(v20.OriginSquare.CFrame)
    local v99 = table.find(v96)
    return v20
    v100, v101 = next(v93, v94)
    if v100 ~= nil then v94 = v100 end
    return false
end
local v93 = game:GetService("ReplicatedStorage")
local v94 = v93:WaitForChild("LoadSaveRequests")
local v95 = v94:WaitForChild("GetMetaData")
local v96 = v95:InvokeServer(_G.自己)
_G.复制物品 = function(p0)
    _G.是否可以加载(v15)
    task.spawn(function()
    local v97 = game:GetService("ReplicatedStorage")
    v97.LoadSaveRequests.RequestLoad.InvokeServer(v97.LoadSaveRequests.RequestLoad, _G.菜单.存档, _G.自己)
    return
end)
    local v97 = FindHillPlot(function()
    local v97 = game:GetService("ReplicatedStorage")
    v97.LoadSaveRequests.RequestLoad.InvokeServer(v97.LoadSaveRequests.RequestLoad, _G.菜单.存档, _G.自己)
    return
end)
    local v98 = Color3.fromRGB(225, 0, 0)
    v97.OriginSquare.Color = v98
    task.wait(v98)
    local v99 = Workspace.Effects:FindFirstChild("StructureModel")
    task.spawn(function()
    local v100 = game:GetService("ReplicatedStorage")
    v100.PropertyPurchasing.ClientPurchasedProperty.FireServer(v100.PropertyPurchasing.ClientPurchasedProperty, upvalue_0, upvalue_0.OriginSquare.Position)
    return
end)
    local v100, v101 = Workspace.Effects.StructureModel:GetChildren()
    local v102 = v88:IsA("Model")
    v103, v104 = next(v100, v101)
    if v103 ~= nil then v101 = v103 end
    local v105 = tick(v101)
    wait(v103)
    local v106 = tick(v103)
    local v107 = tick(v104)
    wait(v102)
    local v108 = tick(v102)
    local v109 = {}
    local v110 = {}
    local v111 = {}
    local v112, v113 = workspace.Effects.StructureModel:GetChildren()
    local v114 = v53:IsA("Model")
    local v115, v116 = v53:GetChildren()
    local v117 = v96.Parent:GetChildren()
    local v118 = table.find(v111, v96.Parent)
    local v119 = v96:FindFirstChild("Mesh")
    table.insert(v111, v96.Parent)
    local v120 = table.find(v110, v96.Parent)
    local v121 = v96.Parent:GetChildren()
    table.insert(v110, v96.Parent)
    local v122 = table.find(v111, v96.Parent)
    table.insert(v111, v96.Parent)
    local v123 = table.find(v109, v96.Parent)
    table.insert(v109, v96.Parent)
    local v124 = table.find(v110, v96.Parent)
    local v125 = v96.Parent:GetChildren()
    table.insert(v110, v96.Parent)
    local v126 = table.find(v111, v96.Parent)
    table.insert(v111, v96.Parent)
    local v127 = table.find(v109, v96.Parent)
    table.insert(v109, v96.Parent)
    v128, v129 = next(v115, v116)
    if v128 ~= nil then v116 = v128 end
    v130, v131 = next(v112, v113)
    if v130 ~= nil then v113 = v130 end
    local v132 = math.floor(#v109 / 40)
    local v133 = math.floor(#v110 / 500)
    local v134 = math.floor(#v111 / 1000)
    local v135 = math.floor(v106 - v105 * 50 + v108 - v107 * 50 / 2)
    local v136 = game:GetService("ReplicatedStorage")
    local v137 = v136:WaitForChild("LoadSaveRequests")
    local v138 = v137:WaitForChild("GetMetaData")
    local v139 = v138:InvokeServer(_G.自己)
    local v140 = {}
    v140[#v140 + 1] = v139[v129].SaveMeta[#v139[v129].SaveMeta].NumKeys
    1 = 1 + 1
    if 1 <= #v139 then
    -- continue loop (PC + -19)
    end
    local v141 = math.floor(v132 + v133 + v134 / v135)
    return _G.提醒("Data size is to low !!!")
    return ...
    Workspace.PlayerModels.ChildAdded:Connect(function(p0)
    local v145 = p0:WaitForChild("Owner", 1)
    local v146 = p0:FindFirstChild("ItemName")
    upvalue_0 = upvalue_0 - 1
    return
end)
    task.wait(Workspace.PlayerModels.ChildAdded)
    spawn(function()
    _G.自己.remove(_G.自己)
    return
end)
    game:Shutdown()
    return
end
local v97 = v88:Section("Dupe Slot")
v97:Toggle("Dupe Wood", false, function(p0)
    _G.菜单.复制木头 = p0
    return
end)
v97:Button("Center Dupe", function()
    _G.复制物品(false)
    return
end)
v97:Button("Max Land Dupe", function()
    _G.复制物品(true)
    return
end)
v97:Button("Remove Ownership", function()
    _G.加载(math.huge)
    _G.提醒("done")
    return
end)
local v98 = v88:Section("Dupe Power")
v98:Slider("Power slot", 1, 1, 6, false, function(p0)
    _G.菜单.有超级建造的存档 = p0
    return
end)
v98:Button("Dupe Power To Build With ease", function()
    return _G.提醒("You need to own the power to be able to dupe it")
    return ...
    _G.加载(_G.菜单.有超级建造的存档)
    task.wait(_G.菜单.有超级建造的存档)
    _G.加载(math.huge)
    wait(math.huge)
    local v102 = _G.获得土地(math.huge)
    local v103 = Vector3.new(0, 3, 0)
    _G.传送(v102.OriginSquare.CFrame + v103)
    local v104 = Vector3.new(0, 3, 0)
    game.ReplicatedStorage.PropertyPurchasing.ClientPurchasedProperty:FireServer(v102, v102.OriginSquare.CFrame.p + v104)
    _G.提醒("now save your slot")
    return
end)
local v99 = v88:Section("Land")
v99:Button("Free Land", function()
    local v100 = _G.获得土地(v13)
    local v101 = Vector3.new(0, 3, 0)
    _G.传送(v100.OriginSquare.CFrame + v101)
    local v102 = Vector3.new(0, 3, 0)
    game.ReplicatedStorage.PropertyPurchasing.ClientPurchasedProperty:FireServer(v100, v100.OriginSquare.CFrame.p + v102)
    return
end)
v99:Button("Free Land(buy it but free)", function()
    setidentity(2)
    local v100 = getsenv(_G.自己.PlayerGui.PropertyPurchasingGUI.PropertyPurchasingClient)
    v100.enterPurchaseMode(0)
    return
end)
v99:Button("Max Land", function()
    local v100, v101 = _G.土地:GetChildren()
    local v102 = nil:FindFirstChild("Owner")
    v103, v104 = next(v100, v101)
    if v103 ~= nil then v101 = v103 end
    local v105 = _G.获得土地(v100)
    local v106 = Vector3.new(0, 3, 0)
    _G.传送(v105.OriginSquare.CFrame + v106)
    local v107 = Vector3.new(0, 3, 0)
    game.ReplicatedStorage.PropertyPurchasing.ClientPurchasedProperty:FireServer(v105, v105.OriginSquare.CFrame.p + v107)
    wait(0,5)
    local v108, v109, v110 = CFrame.new(nil.OriginSquare.Position.X + 40, nil.OriginSquare.Position.Y, nil.OriginSquare.Position.Z)
    _G.扩大土地(v108)
    local v111, v112, v113 = CFrame.new(nil.OriginSquare.Position.X - 40, nil.OriginSquare.Position.Y, nil.OriginSquare.Position.Z)
    _G.扩大土地(v111)
    local v114, v115, v116 = CFrame.new(nil.OriginSquare.Position.X, nil.OriginSquare.Position.Y, nil.OriginSquare.Position.Z + 40)
    _G.扩大土地(v114)
    local v117, v118, v119 = CFrame.new(nil.OriginSquare.Position.X, nil.OriginSquare.Position.Y, nil.OriginSquare.Position.Z - 40)
    _G.扩大土地(v117)
    local v120, v121, v122 = CFrame.new(nil.OriginSquare.Position.X + 40, nil.OriginSquare.Position.Y, nil.OriginSquare.Position.Z + 40)
    _G.扩大土地(v120)
    local v123, v124, v125 = CFrame.new(nil.OriginSquare.Position.X + 40, nil.OriginSquare.Position.Y, nil.OriginSquare.Position.Z - 40)
    _G.扩大土地(v123)
    local v126, v127, v128 = CFrame.new(nil.OriginSquare.Position.X - 40, nil.OriginSquare.Position.Y, nil.OriginSquare.Position.Z + 40)
    _G.扩大土地(v126)
    local v129, v130, v131 = CFrame.new(nil.OriginSquare.Position.X - 40, nil.OriginSquare.Position.Y, nil.OriginSquare.Position.Z - 40)
    _G.扩大土地(v129)
    local v132, v133, v134 = CFrame.new(nil.OriginSquare.Position.X + 80, nil.OriginSquare.Position.Y, nil.OriginSquare.Position.Z)
    _G.扩大土地(v132)
    local v135, v136, v137 = CFrame.new(nil.OriginSquare.Position.X - 80, nil.OriginSquare.Position.Y, nil.OriginSquare.Position.Z)
    _G.扩大土地(v135)
    local v138, v139, v140 = CFrame.new(nil.OriginSquare.Position.X, nil.OriginSquare.Position.Y, nil.OriginSquare.Position.Z + 80)
    _G.扩大土地(v138)
    local v141, v142, v143 = CFrame.new(nil.OriginSquare.Position.X, nil.OriginSquare.Position.Y, nil.OriginSquare.Position.Z - 80)
    _G.扩大土地(v141)
    local v144, v145, v146 = CFrame.new(nil.OriginSquare.Position.X + 80, nil.OriginSquare.Position.Y, nil.OriginSquare.Position.Z + 80)
    _G.扩大土地(v144)
    local v147, v148, v149 = CFrame.new(nil.OriginSquare.Position.X + 80, nil.OriginSquare.Position.Y, nil.OriginSquare.Position.Z - 80)
    _G.扩大土地(v147)
    local v150, v151, v152 = CFrame.new(nil.OriginSquare.Position.X - 80, nil.OriginSquare.Position.Y, nil.OriginSquare.Position.Z + 80)
    _G.扩大土地(v150)
    local v153, v154, v155 = CFrame.new(nil.OriginSquare.Position.X - 80, nil.OriginSquare.Position.Y, nil.OriginSquare.Position.Z - 80)
    _G.扩大土地(v153)
    local v156, v157, v158 = CFrame.new(nil.OriginSquare.Position.X + 40, nil.OriginSquare.Position.Y, nil.OriginSquare.Position.Z + 80)
    _G.扩大土地(v156)
    local v159, v160, v161 = CFrame.new(nil.OriginSquare.Position.X - 40, nil.OriginSquare.Position.Y, nil.OriginSquare.Position.Z + 80)
    _G.扩大土地(v159)
    local v162, v163, v164 = CFrame.new(nil.OriginSquare.Position.X + 80, nil.OriginSquare.Position.Y, nil.OriginSquare.Position.Z + 40)
    _G.扩大土地(v162)
    local v165, v166, v167 = CFrame.new(nil.OriginSquare.Position.X + 80, nil.OriginSquare.Position.Y, nil.OriginSquare.Position.Z - 40)
    _G.扩大土地(v165)
    local v168, v169, v170 = CFrame.new(nil.OriginSquare.Position.X - 80, nil.OriginSquare.Position.Y, nil.OriginSquare.Position.Z + 40)
    _G.扩大土地(v168)
    local v171, v172, v173 = CFrame.new(nil.OriginSquare.Position.X - 80, nil.OriginSquare.Position.Y, nil.OriginSquare.Position.Z - 40)
    _G.扩大土地(v171)
    local v174, v175, v176 = CFrame.new(nil.OriginSquare.Position.X + 40, nil.OriginSquare.Position.Y, nil.OriginSquare.Position.Z - 80)
    _G.扩大土地(v174)
    local v177, v178, v179 = CFrame.new(nil.OriginSquare.Position.X - 40, nil.OriginSquare.Position.Y, nil.OriginSquare.Position.Z - 80)
    _G.扩大土地(v177)
    return
end)
_G.土地艺术 = false
v99:Toggle("Land Art", false, function(p0)
    _G.土地艺术 = p0
    local v100 = {}
    local v101, v102 = _G.土地:GetChildren()
    local v103 = v99:FindFirstChild("Owner")
    local v104 = v99:IsA("Part")
    table.insert(v100, v99.CFrame)
    v105, v106 = next(v101, v102)
    if v105 ~= nil then v102 = v105 end
    return _G.提醒("u need  a land ")
    return ...
    local v110 = {}
    local v111 = CFrame.new(v99.OriginSquare.Position.X + 40, v99.OriginSquare.Position.Y, v99.OriginSquare.Position.Z)
    local v112 = CFrame.new(v99.OriginSquare.Position.X - 40, v99.OriginSquare.Position.Y, v99.OriginSquare.Position.Z)
    local v113 = CFrame.new(v99.OriginSquare.Position.X, v99.OriginSquare.Position.Y, v99.OriginSquare.Position.Z + 40)
    local v114 = CFrame.new(v99.OriginSquare.Position.X, v99.OriginSquare.Position.Y, v99.OriginSquare.Position.Z - 40)
    local v115 = CFrame.new(v99.OriginSquare.Position.X + 40, v99.OriginSquare.Position.Y, v99.OriginSquare.Position.Z + 40)
    local v116 = CFrame.new(v99.OriginSquare.Position.X + 40, v99.OriginSquare.Position.Y, v99.OriginSquare.Position.Z - 40)
    local v117 = CFrame.new(v99.OriginSquare.Position.X - 40, v99.OriginSquare.Position.Y, v99.OriginSquare.Position.Z + 40)
    local v118 = CFrame.new(v99.OriginSquare.Position.X - 40, v99.OriginSquare.Position.Y, v99.OriginSquare.Position.Z - 40)
    local v119 = CFrame.new(v99.OriginSquare.Position.X + 80, v99.OriginSquare.Position.Y, v99.OriginSquare.Position.Z)
    local v120 = CFrame.new(v99.OriginSquare.Position.X - 80, v99.OriginSquare.Position.Y, v99.OriginSquare.Position.Z)
    local v121 = CFrame.new(v99.OriginSquare.Position.X, v99.OriginSquare.Position.Y, v99.OriginSquare.Position.Z + 80)
    local v122 = CFrame.new(v99.OriginSquare.Position.X, v99.OriginSquare.Position.Y, v99.OriginSquare.Position.Z - 80)
    local v123 = CFrame.new(v99.OriginSquare.Position.X + 80, v99.OriginSquare.Position.Y, v99.OriginSquare.Position.Z + 80)
    local v124 = CFrame.new(v99.OriginSquare.Position.X + 80, v99.OriginSquare.Position.Y, v99.OriginSquare.Position.Z - 80)
    local v125 = CFrame.new(v99.OriginSquare.Position.X - 80, v99.OriginSquare.Position.Y, v99.OriginSquare.Position.Z + 80)
    local v126 = CFrame.new(v99.OriginSquare.Position.X - 80, v99.OriginSquare.Position.Y, v99.OriginSquare.Position.Z - 80)
    local v127 = CFrame.new(v99.OriginSquare.Position.X + 40, v99.OriginSquare.Position.Y, v99.OriginSquare.Position.Z + 80)
    local v128 = CFrame.new(v99.OriginSquare.Position.X - 40, v99.OriginSquare.Position.Y, v99.OriginSquare.Position.Z + 80)
    local v129 = CFrame.new(v99.OriginSquare.Position.X + 80, v99.OriginSquare.Position.Y, v99.OriginSquare.Position.Z + 40)
    local v130 = CFrame.new(v99.OriginSquare.Position.X + 80, v99.OriginSquare.Position.Y, v99.OriginSquare.Position.Z - 40)
    local v131 = CFrame.new(v99.OriginSquare.Position.X - 80, v99.OriginSquare.Position.Y, v99.OriginSquare.Position.Z + 40)
    local v132 = CFrame.new(v99.OriginSquare.Position.X - 80, v99.OriginSquare.Position.Y, v99.OriginSquare.Position.Z - 40)
    local v133 = CFrame.new(v99.OriginSquare.Position.X + 40, v99.OriginSquare.Position.Y, v99.OriginSquare.Position.Z - 80)
    local v134, v135, v136 = CFrame.new(v99.OriginSquare.Position.X - 40, v99.OriginSquare.Position.Y, v99.OriginSquare.Position.Z - 80)
    local v137 = Instance.new("Folder", game.Workspace)
    v137.Name = "darkprview"
    local v138 = table.find(v100, v116)
    local v139 = v99.OriginSquare:Clone()
    v139.Parent = v137
    v139.CFrame = v116
    v139.Name = "Dark"
    v139.Transparency = 0,5
    v141, v142 = next(v110, v140)
    if v141 ~= nil then v140 = v141 end
    local v143 = Instance.new("SelectionBox", v99)
    local v144 = _G.鼠标.Move:Connect(function()
    upvalue_0.LineThickness = 0,1
    upvalue_0.Adornee = _G.鼠标.Target
    return
end)
    local v145 = _G.鼠标.Button1Down:Connect(function()
    game.ReplicatedStorage.PropertyPurchasing.ClientExpandedProperty.FireServer(game.ReplicatedStorage.PropertyPurchasing.ClientExpandedProperty, upvalue_0, _G.鼠标.Target.CFrame)
    _G.鼠标.Target.Destroy(_G.鼠标.Target)
    return
end)
    task.wait(function()
    game.ReplicatedStorage.PropertyPurchasing.ClientExpandedProperty.FireServer(game.ReplicatedStorage.PropertyPurchasing.ClientExpandedProperty, upvalue_0, _G.鼠标.Target.CFrame)
    _G.鼠标.Target.Destroy(_G.鼠标.Target)
    return
end)
    local v146, v147 = Workspace:GetChildren()
    v120:Destroy()
    v148, v149 = next(v146, v147)
    if v148 ~= nil then v147 = v148 end
    v144:Disconnect()
    v145:Disconnect()
    v143:Destroy()
    return
end)
_G.点击获得土地 = false
_G.点击土地 = nil
v99:Toggle("Click to Get Land", false, function(p0)
    _G.点击获得土地 = p0
    local v100 = _G.鼠标.Button1Down:Connect(function()
    local v100 = _G.鼠标.Target.Parent.FindFirstChild(_G.鼠标.Target.Parent, "Owner")
    local v101 = _G.鼠标.Target.Parent.FindFirstChild(_G.鼠标.Target.Parent, "Owner")
    local v102 = Vector3.new(0, 3, 0)
    _G.传送(_G.鼠标.Target.Parent.OriginSquare.CFrame + v102)
    local v103 = Vector3.new(0, 3, 0)
    game.ReplicatedStorage.PropertyPurchasing.ClientPurchasedProperty.FireServer(game.ReplicatedStorage.PropertyPurchasing.ClientPurchasedProperty, _G.鼠标.Target.Parent, _G.鼠标.Target.Parent.OriginSquare.CFrame.p + v103)
    _G.提醒("Done")
    _G.提醒("This Land already Have Owner")
    return
end)
    _G.点击土地 = v100
    _G.点击土地:Disconnect()
    _G.点击土地 = nil
    return
end)
_G.复制斧头 = function()
    _G.是否可以加载(v13)
    wait(v13)
    _G.飞行(false)
    _G.菜单.飞行 = false
    _G.自己身体.UnequipTools(_G.自己身体)
    local v100, v101, v102 = CFrame.new(0, -380, 0)
    _G.传送(v100)
    wait(v100)
    local v103 = _G.自己角色.FindFirstChild(_G.自己角色, "Head")
    _G.加载(_G.自己.CurrentSaveSlot.Value)
    local v104 = game:GetService("Workspace")
    v104.CurrentCamera.CameraSubject = _G.自己角色
    task.wait(_G.自己角色)
    return
end
_G.获得所有斧头 = function()
    local v100 = {}
    local v101 = game:GetService("ReplicatedStorage")
    local v102, v103 = v101.AxeClasses:GetChildren()
    local v104 = string.split(nil.Name, "AxeClass_")
    table.insert(v100, v104[2])
    v105, v106 = next(v102, v103)
    if v105 ~= nil then v103 = v105 end
    return v100
end
v99:Toggle("Wire Mod", false, function(p0)
    _G.菜单.超级电线 = p0
    return
end)
local v100 = v88:Section("Axe")
local v101 = _G.获得所有斧头("获得所有斧头")
v100:DropDown("Select the Axe", v101, false, false, function(p0)
    _G.菜单.斧头类型 = p0
    return
end)
v100:Toggle("Auto Pick Up Axe", false, function(p0)
    _G.菜单.自动捡斧头 = p0
    return
end)
local v102 = v88:Section("Axe Dupe")
v102:TextBox("Amount", "1", function(p0)
    local v103 = tonumber(p0)
    _G.菜单.复制斧头数量 = v103
    return
end)
v102:Button("Dupe Axe", function()
    _G.复制斧头(nil)
    1 = 1 + 1
    if 1 <= _G.菜单.复制斧头数量 then
    -- continue loop (PC + -4)
    end
    return
end)
v102:Toggle("Auto Dupe Axe", false, function(p0)
    _G.菜单.自动复制斧头 = p0
    _G.复制斧头(v15)
    return
end)
local v103 = v88:Section("Wipe")
local v104 = {}
v103:DropDown("Select the player", v104, true, false, function(p0)
    _G.菜单.擦去的玩家 = p0
    return
end)
local v105 = {}
v105 = {"Structure", "Blueprint", "Wire", "Tool", "Furniture", "Loose Item", "Gift", "Plank"}
v103:DropDown("Select the Type", v105, false, false, function(p0)
    _G.菜单.擦去的东西 = p0
    _G.菜单.擦去的东西 = "TreeClass"
    return
end)
v103:Button("Wipe", function()
    _G.擦除选择的物品(v13)
    return
end)
_G.点击删除物品 = nil
v103:Toggle("Click to Delete", false, function(p0)
    local v106 = _G.鼠标.Button1Down:Connect(function()
    local v106 = _G.鼠标.Target.Parent.FindFirstChild(_G.鼠标.Target.Parent, "Owner")
    local v107 = _G.鼠标.Target.Parent:FindFirstChild("Owner")
    local v108 = tostring(v107.Value)
    game.ReplicatedStorage.Interaction.DestroyStructure.FireServer(game.ReplicatedStorage.Interaction.DestroyStructure, _G.鼠标.Target.Parent)
    task.wait(game.ReplicatedStorage.Interaction.DestroyStructure)
    return
end)
    _G.点击删除物品 = v106
    _G.点击删除物品:Disconnect()
    _G.点击删除物品 = nil
    return
end)
local v106 = {}
local v107 = {}
v107.Character = game.Workspace.Stores.WoodRUs.Thom
v107.Name = "Thom"
local v108 = tonumber(7)
v107.ID = v108
v106.WoodRus = v107
local v109 = {}
v109.Character = game.Workspace.Stores.FurnitureStore.Corey
v109.Name = "Corey"
local v110 = tonumber(8)
v109.ID = v110
v106.FurnitureStore = v109
local v111 = {}
v111.Character = game.Workspace.Stores.CarStore.Jenny
v111.Name = "Jenny"
local v112 = tonumber(9)
v111.ID = v112
v106.CarStore = v111
local v113 = {}
v113.Character = game.Workspace.Stores.ShackShop.Bob
v113.Name = "Bob"
local v114 = tonumber(10)
v113.ID = v114
v106.ShackShop = v113
local v115 = {}
v115.Character = game.Workspace.Stores.FineArt.Timothy
v115.Name = "Timothy"
local v116 = tonumber(11)
v115.ID = v116
v106.FineArt = v115
local v117 = {}
v117.Character = game.Workspace.Stores.LogicStore.Lincoln
v117.Name = "Lincoln"
local v118 = tonumber(12)
v117.ID = v118
v106.LogicStore = v117
_G.获得商场id = v106
_G.找到物品 = function(p0)
    local v119, v120 = game.Workspace.Stores:GetChildren()
    local v121 = v88:FindFirstChild("Box")
    local v122, v123 = v88:GetChildren()
    local v124, v125 = v88:GetChildren()
    local v126 = Vector3.new(0, 0,6, 0)
    local v127 = Vector3.new(0, 0,6, 0)
    local v128 = Vector3.new(0, 0,6, 0)
    local v129 = Vector3.new(0, 0,6, 0)
    local v130 = Vector3.new(0, 0,6, 0)
    local v131 = Vector3.new(0, 0,6, 0)
    v132, v133 = next(v124, v125)
    if v132 ~= nil then v125 = v132 end
    return nil, _G.获得商场id.LogicStore, game.Workspace.Stores.LogicStore.Counter.CFrame + v131
    v134, v135 = next(v122, v123)
    if v134 ~= nil then v123 = v134 end
    v136, v137 = next(v119, v120)
    if v136 ~= nil then v120 = v136 end
    return
end
_G.传送物品 = nil
_G.买 = function(p0)
    local v119, v120, v121 = _G.找到物品(p0)
    _G.收银台 = v121
    _G.商人id = v120
    _G.物品 = v119
    _G.提醒("Wait for the item to refresh")
    task.wait("Wait for the item to refresh")
    local v122, v123, v124 = _G.找到物品(p0)
    _G.收银台 = v124
    _G.商人id = v123
    _G.物品 = v122
    local v125 = Vector3.new(1, -3, 1)
    _G.传送(_G.物品.Main.CFrame - v125)
    upvalue_0(_G.物品, _G.收银台)
    spawn(function()
    local v126 = Vector3.new(5, 0, 5)
    _G.传送(_G.收银台 + v126)
    return
end)
    wait(function()
    local v126 = Vector3.new(5, 0, 5)
    _G.传送(_G.收银台 + v126)
    return
end)
    game.ReplicatedStorage.NPCDialog.PlayerChatted:InvokeServer(_G.商人id, "ConfirmPurchase")
    wait(game.ReplicatedStorage.NPCDialog.PlayerChatted)
    local v126 = _G.物品:FindFirstChild("BoxItemName")
    return
end
_G.传送物品 = nil
_G.自动购买v2 = function(p0, p1, p2, p3)
    _G.自动数量 = p1
    _G.自动数量 = 9000000000
    local v119 = _G.商品价格(p0, p1)
    return _G.提醒("you not have enough money")
    return ...
    local v123 = game.Workspace.PlayerModels.ChildAdded:Connect(function(p0)
    p0:WaitForChild("Owner", 60)
    pcall(function()
    local v123 = game:GetService("ReplicatedStorage")
    v123.Interaction.ClientIsDragging:FireServer(upvalue_0)
    upvalue_0:PivotTo(_G.菜单.自动购买的地点)
    local v124 = game:GetService("RunService")
    v124.Stepped:wait()
    1 = 1 + 1
    if 1 <= 15 then
    -- continue loop (PC + -23)
    end
    upvalue_1 = true
    return
end)
    return
end)
    _G.传送物品 = v123
    _G.数量 = 0
    _G.买(false)
    _G.数量 = _G.数量 + 1
    local v124 = tostring(_G.数量)
    local v125 = tostring(p1)
    _G.自己.PlayerGui.MoneyDisplayGui.Text.Text = "Autobuying:" .. v124 .. "/" .. v125
    task.wait("Autobuying:" .. v124 .. "/" .. v125)
    task.wait("Autobuying:" .. v124 .. "/" .. v125)
    1 = 1 + 1
    if 1 <= _G.自动数量 then
    -- continue loop (PC + -40)
    end
    wait(_G.自动数量)
    local v126 = tostring(_G.自己.leaderstats.Money.Value)
    _G.自己.PlayerGui.MoneyDisplayGui.Text.Text = v126
    spawn(function()
    pcall(function()
    _G.传送物品.Disconnect(_G.传送物品)
    _G.传送物品 = nil
    return
end)
    return
end)
    return
end
_G.获得商品名字 = function()
    local v119 = {}
    _G.全部商品 = v119
    local v120, v121 = game.Workspace.Stores:GetChildren()
    local v122 = v20:FindFirstChild("Box")
    local v123, v124 = v20:GetChildren()
    local v125 = table.find(_G.全部商品, function(p0)
    local v28 = p0:FindFirstChildOfClass("MeshPart")
    local v29 = p0:FindFirstChildOfClass("MeshPart")
    p0.PrimaryPart = v29
    return
    local v30 = p0:FindFirstChildOfClass("Part")
    local v31 = p0:FindFirstChildOfClass("MeshPart")
    local v32 = p0:FindFirstChild("Main")
    p0.PrimaryPart = v32
    return
end.BoxItemName.Value)
    table.insert(_G.全部商品, function(p0)
    local v28 = p0:FindFirstChildOfClass("MeshPart")
    local v29 = p0:FindFirstChildOfClass("MeshPart")
    p0.PrimaryPart = v29
    return
    local v30 = p0:FindFirstChildOfClass("Part")
    local v31 = p0:FindFirstChildOfClass("MeshPart")
    local v32 = p0:FindFirstChild("Main")
    p0.PrimaryPart = v32
    return
end.BoxItemName.Value)
    v126, v127 = next(v123, v124)
    if v126 ~= nil then v124 = v126 end
    v128, v129 = next(v120, v121)
    if v128 ~= nil then v121 = v128 end
    return _G.全部商品
end
_G.商品价格 = function(p0, p1)
    _G.价格 = 0
    local v119, v120 = game.ReplicatedStorage.ClientItemInfo:GetChildren()
    local v121 = v24:FindFirstChild("Price")
    _G.价格 = v24.Price.Value * p1
    v122, v123 = next(v119, v120)
    if v122 ~= nil then v120 = v122 end
    return _G.价格
end
_G.升级物品名字 = function()
    local v119 = _G.获得商品名字(v15)
    _G.所有物品 = v119
    local v120 = {}
    local v121 = _G.商品价格("BagOfSand", 1)
    local v122 = _G.商品价格("CanOfWorms", 1)
    local v123 = _G.商品价格("LightBulb", 1)
    v120 = {"Rukiryaxe--" .. v121 + v122 + v123}
    _G.商品的价格 = v120
    local v124 = _G.商品价格(v123, 1)
    table.insert(_G.商品的价格, v123 .. "--" .. v124)
    v126, v127 = next(_G.所有物品, v125)
    if v126 ~= nil then v125 = v126 end
    return _G.商品的价格
end
_G.获得所有商店名字 = function()
    local v119 = {}
    v119 = {"All"}
    _G.商店名字 = v119
    local v120, v121 = game.Workspace.Stores:GetChildren()
    local v122 = v20:FindFirstChild("Counter")
    table.insert(_G.商店名字, v20.Name)
    v123, v124 = next(v120, v121)
    if v123 ~= nil then v121 = v123 end
    return _G.商店名字
end
_G.获得商店物品 = function(p0)
    return _G.升级物品名字(v15)
    return ...
    local v122 = {}
    _G.名字 = v122
    local v123, v124 = game.Workspace.Stores:GetChildren()
    local v125 = nil:FindFirstChild("Box")
    local v126, v127 = nil:GetChildren()
    local v128, v129 = nil:GetChildren()
    local v130 = table.find(_G.名字, v52.BoxItemName.Value)
    table.insert(_G.名字, v52.BoxItemName.Value)
    v131, v132 = next(v128, v129)
    if v131 ~= nil then v129 = v131 end
    local v133, v134 = nil:GetChildren()
    local v135 = table.find(_G.名字, v132.BoxItemName.Value)
    table.insert(_G.名字, v132.BoxItemName.Value)
    v136, v137 = next(v133, v134)
    if v136 ~= nil then v134 = v136 end
    local v138, v139 = nil:GetChildren()
    local v140 = table.find(_G.名字, v137.BoxItemName.Value)
    table.insert(_G.名字, v137.BoxItemName.Value)
    v141, v142 = next(v138, v139)
    if v141 ~= nil then v139 = v141 end
    local v143, v144 = nil:GetChildren()
    local v145 = table.find(_G.名字, v142.BoxItemName.Value)
    table.insert(_G.名字, v142.BoxItemName.Value)
    v146, v147 = next(v143, v144)
    if v146 ~= nil then v144 = v146 end
    local v148, v149 = nil:GetChildren()
    local v150 = table.find(_G.名字, v147.BoxItemName.Value)
    table.insert(_G.名字, v147.BoxItemName.Value)
    v151, v152 = next(v148, v149)
    if v151 ~= nil then v149 = v151 end
    local v153, v154 = nil:GetChildren()
    local v155 = table.find(_G.名字, v152.BoxItemName.Value)
    table.insert(_G.名字, v152.BoxItemName.Value)
    v156, v157 = next(v153, v154)
    if v156 ~= nil then v154 = v156 end
    v158, v159 = next(v126, v127)
    if v158 ~= nil then v127 = v158 end
    v160, v161 = next(v123, v124)
    if v160 ~= nil then v124 = v160 end
    return _G.名字
end
_G.升级选择的物品名字 = function(p0)
    local v119 = {}
    _G.物品 = v119
    return _G.获得商店物品(p0)
    return ...
    local v123 = _G.获得商店物品(p0)
    local v124 = _G.商品价格(v24, 1)
    table.insert(_G.物品, v24 .. "--" .. v124)
    v126, v127 = next(v123, v125)
    if v126 ~= nil then v125 = v126 end
    return _G.物品
end
local v119 = v24:CreateTab("Auto Buy ", "6031289461")
local v120 = v119:Section("Auto Buy")
local v121 = _G.获得所有商店名字("获得所有商店名字")
v120:DropDown("Select Store", v121, false, false, function(p0)
    _G.菜单.商店名字 = p0
    local v122, v123, v124 = _G.升级选择的物品名字(_G.菜单.商店名字)
    _G.物品选择:SetOptions(v122)
    return
end)
local v122 = _G.升级选择的物品名字(_G.菜单.商店名字)
local v123 = v120:DropDown("Select Item", v122, false, false, function(p0)
    _G.菜单.自动购买的物品 = p0
    return
end)
_G.物品选择 = v123
v120:TextBox("Amount", "1", function(p0)
    local v124 = tonumber(p0)
    _G.菜单.自动购买的数量 = v124
    return
end)
v120:Button("Buy", function()
    _G.菜单.自动购买停止 = false
    _G.菜单.自动购买的地点 = _G.自己的方块.CFrame
    local v124 = string.split(_G.菜单.自动购买的物品, "--")
    local v125 = _G.商品价格("BagOfSand", 1)
    local v126 = _G.商品价格("CanOfWorms", 1)
    local v127 = _G.商品价格("LightBulb", 1)
    return _G.提醒("you not have enough money")
    return ...
    local v131 = game.Workspace.PlayerModels.ChildAdded:Connect(function(p0)
    p0:WaitForChild("Owner", 60)
    wait(1)
    local v131 = tostring(p0.Owner.Value)
    local v132 = tostring(_G.自己)
    local v133 = p0:FindFirstChild("PurchasedBoxItemName")
    local v134 = tostring(p0.PurchasedBoxItemName.Value)
    local v135 = tostring(p0.PurchasedBoxItemName.Value)
    local v136 = tostring(p0.PurchasedBoxItemName.Value)
    local v137 = game:GetService("ReplicatedStorage")
    v137.Interaction.ClientInteracted:FireServer(p0, "Open box")
    return
end)
    _G.自动打开盒子 = v131
    _G.拿斧头 = nil
    local v132 = game.Workspace.PlayerModels.ChildAdded:Connect(function(p0)
    local v132 = p0:WaitForChild("Main", 60)
    local v133 = v132:FindFirstChild("Mesh")
    wait(v132)
    local v134 = p0:FindFirstChild("ToolName")
    _G.提醒("Calming Rukiryaxe")
    _G.传送(p0.Main.CFrame)
    task.wait(p0.Main.CFrame)
    _G.拉东西:FireServer(p0)
    game.ReplicatedStorage.Interaction.ClientInteracted:FireServer(p0, "Pick up tool")
    local v135 = tostring(p0.Parent)
    _G.传送(_G.自己的方块.CFrame)
    pcall(function()
    _G.自动打开盒子.Disconnect(_G.自动打开盒子)
    _G.自动打开盒子 = nil
    _G.拿斧头.Disconnect(_G.拿斧头)
    _G.拿斧头 = nil
    return
end)
    return
end)
    _G.拿斧头 = v132
    local v133 = CFrame.new(319, 43, 1914)
    _G.菜单.自动购买的地点 = v133
    _G.自动购买v2("BagOfSand", 1)
    wait(1)
    local v134 = CFrame.new(317, 43, 1918)
    _G.菜单.自动购买的地点 = v134
    _G.自动购买v2("CanOfWorms", 1)
    wait(1)
    local v135 = CFrame.new(322, 43, 1916)
    _G.菜单.自动购买的地点 = v135
    _G.自动购买v2("LightBulb", 1)
    local v136 = string.split(_G.菜单.自动购买的物品, "--")
    _G.自动购买v2(v136[1], _G.菜单.自动购买的数量)
    _G.传送(_G.菜单.自动购买的地点)
    return
end)
v120:Button("Abort", function()
    _G.菜单.自动购买停止 = true
    return
end)
v120:Toggle("Loop Auto Buy", false, function(p0)
    _G.菜单.自动购买停止 = false
    _G.菜单.自动购买的地点 = _G.自己的方块.CFrame
    local v124 = string.split(_G.菜单.自动购买的物品, "--")
    _G.自动购买v2(v124[1], 0, true)
    _G.传送(_G.菜单.自动购买的地点)
    _G.菜单.自动购买停止 = true
    return
end)
local v124 = v119:Section("Other")
v124:Toggle("Auto Buy All BluePrints", false, function(p0)
    local v125 = game.Workspace.PlayerModels.ChildAdded:connect(function(p0)
    spawn(function()
    local v125 = game:GetService("ReplicatedStorage")
    v125.Interaction.ClientInteracted.FireServer(v125.Interaction.ClientInteracted, upvalue_0, "Open box")
    return
end)
    return
end)
    _G.菜单.自动购买停止 = false
    local v126, v127 = game.ReplicatedStorage.ClientItemInfo:GetChildren()
    local v128 = v24:FindFirstChild("WoodCost")
    local v129 = _G.自己.PlayerBlueprints.Blueprints:FindFirstChild(v24.Name)
    _G.自动购买v2(v24.Name, 1)
    v130, v131 = next(v126, v127)
    if v130 ~= nil then v127 = v130 end
    wait(1)
    v125:Disconnect()
    _G.菜单.自动购买停止 = true
    return
end)
v124:Button("Toll Bridge", function()
    local v125 = {}
    v125.ID = 15
    v125.Character = "name"
    v125.Name = "name"
    v125.Dialog = "Dialog"
    game.ReplicatedStorage.NPCDialog.PlayerChatted.InvokeServer(game.ReplicatedStorage.NPCDialog.PlayerChatted, v125, "ConfirmPurchase")
    return
end)
v124:Button("Ferry Ticket", function()
    local v125 = {}
    v125.ID = 13
    v125.Character = "name"
    v125.Name = "name"
    v125.Dialog = "Dialog"
    game.ReplicatedStorage.NPCDialog.PlayerChatted.InvokeServer(game.ReplicatedStorage.NPCDialog.PlayerChatted, v125, "ConfirmPurchase")
    return
end)
v124:Button("Power Of Ease", function()
    local v125 = {}
    v125.ID = 3
    v125.Character = "name"
    v125.Name = "name"
    v125.Dialog = "Dialog"
    game.ReplicatedStorage.NPCDialog.PlayerChatted.InvokeServer(game.ReplicatedStorage.NPCDialog.PlayerChatted, v125, "ConfirmPurchase")
    return
end)
local v125 = Instance.new("ScreenGui")
local v126 = Instance.new("Frame")
v125.Parent = game.CoreGui
v125.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
v126.Parent = v125
local v127 = Color3.fromRGB(4, 0, 255)
v126.BackgroundColor3 = v127
v126.BackgroundTransparency = 0,8
local v128 = Color3.new(0,09, 0,137, 0,776)
v126.BorderColor3 = v128
v126.BorderSizePixel = 2
local v129 = UDim2.new(0, 0, 0, 0)
v126.Position = v129
local v130 = UDim2.new(0, 0, 0, 0)
v126.Size = v130
v126.Name = "Lasso Tool"
_G.在框内 = function(p0, p1)
    return false
end
_G.整理鼠标移动 = nil
_G.整理鼠标点击 = nil
_G.盒子传送 = function(p0, p1, p2, p3)
    _G.菜单.停止整理 = false
    local v131 = {}
    upvalue_0 = false
    local v132 = game:GetService("Workspace")
    local v133, v134 = v132.PlayerModels:GetChildren()
    local v135 = function(p0, p1)
    upvalue_0(p0)
    spawn(function()
    local v28 = Vector3.new(0, 0, 0)
    upvalue_0.PrimaryPart.Velocity = v28
    local v29 = Vector3.new(0, 0, 0)
    upvalue_0.PrimaryPart.RotVelocity = v29
    game.ReplicatedStorage.TestPing:InvokeServer()
    task.wait(game.ReplicatedStorage.TestPing)
    1 = 1 + 1
    if 1 <= 10 then
    -- continue loop (PC + -27)
    end
    return
end)
    local v28 = identifyexecutor(function()
    local v28 = Vector3.new(0, 0, 0)
    upvalue_0.PrimaryPart.Velocity = v28
    local v29 = Vector3.new(0, 0, 0)
    upvalue_0.PrimaryPart.RotVelocity = v29
    game.ReplicatedStorage.TestPing:InvokeServer()
    task.wait(game.ReplicatedStorage.TestPing)
    1 = 1 + 1
    if 1 <= 10 then
    -- continue loop (PC + -27)
    end
    return
end)
    print(p0.PrimaryPart)
    game.ReplicatedStorage.Interaction.ClientIsDragging:FireServer(p0)
    task.wait(0,2)
    local v29 = isnetworkowner(p0.PrimaryPart)
    game.ReplicatedStorage.Interaction.ClientIsDragging:FireServer(p0)
    local v30 = p0:FindFirstChild("WoodSection")
    p0.PrimaryPart.CFrame = p1
    p0:PivotTo(p1)
    return
    local v31 = tostring(p0.Parent)
    game.ReplicatedStorage.Interaction.ClientIsDragging:FireServer(p0)
    upvalue_0(p0)
    p0.PrimaryPart.CFrame = p1
    game.ReplicatedStorage.TestPing:InvokeServer()
    task.wait(game.ReplicatedStorage.TestPing)
    1 = 1 + 1
    if 1 <= 6 then
    -- continue loop (PC + -21)
    end
    return
    game.ReplicatedStorage.Interaction.ClientIsDragging:FireServer(p0)
    local v32 = p0:FindFirstChild("WoodSection")
    upvalue_0(p0)
    p0.PrimaryPart.CFrame = p1
    p0:PivotTo(p1)
    game.ReplicatedStorage.TestPing:InvokeServer()
    task.wait(game.ReplicatedStorage.TestPing)
    1 = 1 + 1
    if 1 <= 3 then
    -- continue loop (PC + -30)
    end
    return
end:FindFirstChild(p3)
    local v136 = function(p0, p1)
    upvalue_0(p0)
    spawn(function()
    local v28 = Vector3.new(0, 0, 0)
    upvalue_0.PrimaryPart.Velocity = v28
    local v29 = Vector3.new(0, 0, 0)
    upvalue_0.PrimaryPart.RotVelocity = v29
    game.ReplicatedStorage.TestPing:InvokeServer()
    task.wait(game.ReplicatedStorage.TestPing)
    1 = 1 + 1
    if 1 <= 10 then
    -- continue loop (PC + -27)
    end
    return
end)
    local v28 = identifyexecutor(function()
    local v28 = Vector3.new(0, 0, 0)
    upvalue_0.PrimaryPart.Velocity = v28
    local v29 = Vector3.new(0, 0, 0)
    upvalue_0.PrimaryPart.RotVelocity = v29
    game.ReplicatedStorage.TestPing:InvokeServer()
    task.wait(game.ReplicatedStorage.TestPing)
    1 = 1 + 1
    if 1 <= 10 then
    -- continue loop (PC + -27)
    end
    return
end)
    print(p0.PrimaryPart)
    game.ReplicatedStorage.Interaction.ClientIsDragging:FireServer(p0)
    task.wait(0,2)
    local v29 = isnetworkowner(p0.PrimaryPart)
    game.ReplicatedStorage.Interaction.ClientIsDragging:FireServer(p0)
    local v30 = p0:FindFirstChild("WoodSection")
    p0.PrimaryPart.CFrame = p1
    p0:PivotTo(p1)
    return
    local v31 = tostring(p0.Parent)
    game.ReplicatedStorage.Interaction.ClientIsDragging:FireServer(p0)
    upvalue_0(p0)
    p0.PrimaryPart.CFrame = p1
    game.ReplicatedStorage.TestPing:InvokeServer()
    task.wait(game.ReplicatedStorage.TestPing)
    1 = 1 + 1
    if 1 <= 6 then
    -- continue loop (PC + -21)
    end
    return
    game.ReplicatedStorage.Interaction.ClientIsDragging:FireServer(p0)
    local v32 = p0:FindFirstChild("WoodSection")
    upvalue_0(p0)
    p0.PrimaryPart.CFrame = p1
    p0:PivotTo(p1)
    game.ReplicatedStorage.TestPing:InvokeServer()
    task.wait(game.ReplicatedStorage.TestPing)
    1 = 1 + 1
    if 1 <= 3 then
    -- continue loop (PC + -30)
    end
    return
end:FindFirstChild("SelectionBox")
    local v137 = function(p0, p1)
    upvalue_0(p0)
    spawn(function()
    local v28 = Vector3.new(0, 0, 0)
    upvalue_0.PrimaryPart.Velocity = v28
    local v29 = Vector3.new(0, 0, 0)
    upvalue_0.PrimaryPart.RotVelocity = v29
    game.ReplicatedStorage.TestPing:InvokeServer()
    task.wait(game.ReplicatedStorage.TestPing)
    1 = 1 + 1
    if 1 <= 10 then
    -- continue loop (PC + -27)
    end
    return
end)
    local v28 = identifyexecutor(function()
    local v28 = Vector3.new(0, 0, 0)
    upvalue_0.PrimaryPart.Velocity = v28
    local v29 = Vector3.new(0, 0, 0)
    upvalue_0.PrimaryPart.RotVelocity = v29
    game.ReplicatedStorage.TestPing:InvokeServer()
    task.wait(game.ReplicatedStorage.TestPing)
    1 = 1 + 1
    if 1 <= 10 then
    -- continue loop (PC + -27)
    end
    return
end)
    print(p0.PrimaryPart)
    game.ReplicatedStorage.Interaction.ClientIsDragging:FireServer(p0)
    task.wait(0,2)
    local v29 = isnetworkowner(p0.PrimaryPart)
    game.ReplicatedStorage.Interaction.ClientIsDragging:FireServer(p0)
    local v30 = p0:FindFirstChild("WoodSection")
    p0.PrimaryPart.CFrame = p1
    p0:PivotTo(p1)
    return
    local v31 = tostring(p0.Parent)
    game.ReplicatedStorage.Interaction.ClientIsDragging:FireServer(p0)
    upvalue_0(p0)
    p0.PrimaryPart.CFrame = p1
    game.ReplicatedStorage.TestPing:InvokeServer()
    task.wait(game.ReplicatedStorage.TestPing)
    1 = 1 + 1
    if 1 <= 6 then
    -- continue loop (PC + -21)
    end
    return
    game.ReplicatedStorage.Interaction.ClientIsDragging:FireServer(p0)
    local v32 = p0:FindFirstChild("WoodSection")
    upvalue_0(p0)
    p0.PrimaryPart.CFrame = p1
    p0:PivotTo(p1)
    game.ReplicatedStorage.TestPing:InvokeServer()
    task.wait(game.ReplicatedStorage.TestPing)
    1 = 1 + 1
    if 1 <= 3 then
    -- continue loop (PC + -30)
    end
    return
end:FindFirstChild("Owner")
    local v138 = tostring(function(p0, p1)
    upvalue_0(p0)
    spawn(function()
    local v28 = Vector3.new(0, 0, 0)
    upvalue_0.PrimaryPart.Velocity = v28
    local v29 = Vector3.new(0, 0, 0)
    upvalue_0.PrimaryPart.RotVelocity = v29
    game.ReplicatedStorage.TestPing:InvokeServer()
    task.wait(game.ReplicatedStorage.TestPing)
    1 = 1 + 1
    if 1 <= 10 then
    -- continue loop (PC + -27)
    end
    return
end)
    local v28 = identifyexecutor(function()
    local v28 = Vector3.new(0, 0, 0)
    upvalue_0.PrimaryPart.Velocity = v28
    local v29 = Vector3.new(0, 0, 0)
    upvalue_0.PrimaryPart.RotVelocity = v29
    game.ReplicatedStorage.TestPing:InvokeServer()
    task.wait(game.ReplicatedStorage.TestPing)
    1 = 1 + 1
    if 1 <= 10 then
    -- continue loop (PC + -27)
    end
    return
end)
    print(p0.PrimaryPart)
    game.ReplicatedStorage.Interaction.ClientIsDragging:FireServer(p0)
    task.wait(0,2)
    local v29 = isnetworkowner(p0.PrimaryPart)
    game.ReplicatedStorage.Interaction.ClientIsDragging:FireServer(p0)
    local v30 = p0:FindFirstChild("WoodSection")
    p0.PrimaryPart.CFrame = p1
    p0:PivotTo(p1)
    return
    local v31 = tostring(p0.Parent)
    game.ReplicatedStorage.Interaction.ClientIsDragging:FireServer(p0)
    upvalue_0(p0)
    p0.PrimaryPart.CFrame = p1
    game.ReplicatedStorage.TestPing:InvokeServer()
    task.wait(game.ReplicatedStorage.TestPing)
    1 = 1 + 1
    if 1 <= 6 then
    -- continue loop (PC + -21)
    end
    return
    game.ReplicatedStorage.Interaction.ClientIsDragging:FireServer(p0)
    local v32 = p0:FindFirstChild("WoodSection")
    upvalue_0(p0)
    p0.PrimaryPart.CFrame = p1
    p0:PivotTo(p1)
    game.ReplicatedStorage.TestPing:InvokeServer()
    task.wait(game.ReplicatedStorage.TestPing)
    1 = 1 + 1
    if 1 <= 3 then
    -- continue loop (PC + -30)
    end
    return
end.Owner.Value)
    table.insert(v131, function(p0, p1)
    upvalue_0(p0)
    spawn(function()
    local v28 = Vector3.new(0, 0, 0)
    upvalue_0.PrimaryPart.Velocity = v28
    local v29 = Vector3.new(0, 0, 0)
    upvalue_0.PrimaryPart.RotVelocity = v29
    game.ReplicatedStorage.TestPing:InvokeServer()
    task.wait(game.ReplicatedStorage.TestPing)
    1 = 1 + 1
    if 1 <= 10 then
    -- continue loop (PC + -27)
    end
    return
end)
    local v28 = identifyexecutor(function()
    local v28 = Vector3.new(0, 0, 0)
    upvalue_0.PrimaryPart.Velocity = v28
    local v29 = Vector3.new(0, 0, 0)
    upvalue_0.PrimaryPart.RotVelocity = v29
    game.ReplicatedStorage.TestPing:InvokeServer()
    task.wait(game.ReplicatedStorage.TestPing)
    1 = 1 + 1
    if 1 <= 10 then
    -- continue loop (PC + -27)
    end
    return
end)
    print(p0.PrimaryPart)
    game.ReplicatedStorage.Interaction.ClientIsDragging:FireServer(p0)
    task.wait(0,2)
    local v29 = isnetworkowner(p0.PrimaryPart)
    game.ReplicatedStorage.Interaction.ClientIsDragging:FireServer(p0)
    local v30 = p0:FindFirstChild("WoodSection")
    p0.PrimaryPart.CFrame = p1
    p0:PivotTo(p1)
    return
    local v31 = tostring(p0.Parent)
    game.ReplicatedStorage.Interaction.ClientIsDragging:FireServer(p0)
    upvalue_0(p0)
    p0.PrimaryPart.CFrame = p1
    game.ReplicatedStorage.TestPing:InvokeServer()
    task.wait(game.ReplicatedStorage.TestPing)
    1 = 1 + 1
    if 1 <= 6 then
    -- continue loop (PC + -21)
    end
    return
    game.ReplicatedStorage.Interaction.ClientIsDragging:FireServer(p0)
    local v32 = p0:FindFirstChild("WoodSection")
    upvalue_0(p0)
    p0.PrimaryPart.CFrame = p1
    p0:PivotTo(p1)
    game.ReplicatedStorage.TestPing:InvokeServer()
    task.wait(game.ReplicatedStorage.TestPing)
    1 = 1 + 1
    if 1 <= 3 then
    -- continue loop (PC + -30)
    end
    return
end)
    upvalue_1(function(p0, p1)
    upvalue_0(p0)
    spawn(function()
    local v28 = Vector3.new(0, 0, 0)
    upvalue_0.PrimaryPart.Velocity = v28
    local v29 = Vector3.new(0, 0, 0)
    upvalue_0.PrimaryPart.RotVelocity = v29
    game.ReplicatedStorage.TestPing:InvokeServer()
    task.wait(game.ReplicatedStorage.TestPing)
    1 = 1 + 1
    if 1 <= 10 then
    -- continue loop (PC + -27)
    end
    return
end)
    local v28 = identifyexecutor(function()
    local v28 = Vector3.new(0, 0, 0)
    upvalue_0.PrimaryPart.Velocity = v28
    local v29 = Vector3.new(0, 0, 0)
    upvalue_0.PrimaryPart.RotVelocity = v29
    game.ReplicatedStorage.TestPing:InvokeServer()
    task.wait(game.ReplicatedStorage.TestPing)
    1 = 1 + 1
    if 1 <= 10 then
    -- continue loop (PC + -27)
    end
    return
end)
    print(p0.PrimaryPart)
    game.ReplicatedStorage.Interaction.ClientIsDragging:FireServer(p0)
    task.wait(0,2)
    local v29 = isnetworkowner(p0.PrimaryPart)
    game.ReplicatedStorage.Interaction.ClientIsDragging:FireServer(p0)
    local v30 = p0:FindFirstChild("WoodSection")
    p0.PrimaryPart.CFrame = p1
    p0:PivotTo(p1)
    return
    local v31 = tostring(p0.Parent)
    game.ReplicatedStorage.Interaction.ClientIsDragging:FireServer(p0)
    upvalue_0(p0)
    p0.PrimaryPart.CFrame = p1
    game.ReplicatedStorage.TestPing:InvokeServer()
    task.wait(game.ReplicatedStorage.TestPing)
    1 = 1 + 1
    if 1 <= 6 then
    -- continue loop (PC + -21)
    end
    return
    game.ReplicatedStorage.Interaction.ClientIsDragging:FireServer(p0)
    local v32 = p0:FindFirstChild("WoodSection")
    upvalue_0(p0)
    p0.PrimaryPart.CFrame = p1
    p0:PivotTo(p1)
    game.ReplicatedStorage.TestPing:InvokeServer()
    task.wait(game.ReplicatedStorage.TestPing)
    1 = 1 + 1
    if 1 <= 3 then
    -- continue loop (PC + -30)
    end
    return
end)
    local v139 = Instance.new("BodyVelocity", function(p0, p1)
    upvalue_0(p0)
    spawn(function()
    local v28 = Vector3.new(0, 0, 0)
    upvalue_0.PrimaryPart.Velocity = v28
    local v29 = Vector3.new(0, 0, 0)
    upvalue_0.PrimaryPart.RotVelocity = v29
    game.ReplicatedStorage.TestPing:InvokeServer()
    task.wait(game.ReplicatedStorage.TestPing)
    1 = 1 + 1
    if 1 <= 10 then
    -- continue loop (PC + -27)
    end
    return
end)
    local v28 = identifyexecutor(function()
    local v28 = Vector3.new(0, 0, 0)
    upvalue_0.PrimaryPart.Velocity = v28
    local v29 = Vector3.new(0, 0, 0)
    upvalue_0.PrimaryPart.RotVelocity = v29
    game.ReplicatedStorage.TestPing:InvokeServer()
    task.wait(game.ReplicatedStorage.TestPing)
    1 = 1 + 1
    if 1 <= 10 then
    -- continue loop (PC + -27)
    end
    return
end)
    print(p0.PrimaryPart)
    game.ReplicatedStorage.Interaction.ClientIsDragging:FireServer(p0)
    task.wait(0,2)
    local v29 = isnetworkowner(p0.PrimaryPart)
    game.ReplicatedStorage.Interaction.ClientIsDragging:FireServer(p0)
    local v30 = p0:FindFirstChild("WoodSection")
    p0.PrimaryPart.CFrame = p1
    p0:PivotTo(p1)
    return
    local v31 = tostring(p0.Parent)
    game.ReplicatedStorage.Interaction.ClientIsDragging:FireServer(p0)
    upvalue_0(p0)
    p0.PrimaryPart.CFrame = p1
    game.ReplicatedStorage.TestPing:InvokeServer()
    task.wait(game.ReplicatedStorage.TestPing)
    1 = 1 + 1
    if 1 <= 6 then
    -- continue loop (PC + -21)
    end
    return
    game.ReplicatedStorage.Interaction.ClientIsDragging:FireServer(p0)
    local v32 = p0:FindFirstChild("WoodSection")
    upvalue_0(p0)
    p0.PrimaryPart.CFrame = p1
    p0:PivotTo(p1)
    game.ReplicatedStorage.TestPing:InvokeServer()
    task.wait(game.ReplicatedStorage.TestPing)
    1 = 1 + 1
    if 1 <= 3 then
    -- continue loop (PC + -30)
    end
    return
end.PrimaryPart)
    local v140 = Vector3.new(0, 0, 0)
    v139.Velocity = v140
    local v141 = Vector3.new(math.huge, math.huge, math.huge)
    v139.MaxForce = v141
    v139.P = 9000
    v139.Name = "freeze1"
    v142, v143 = next(v133, v134)
    if v142 ~= nil then v134 = v142 end
    local v144 = Instance.new("Part", game.Workspace)
    local v145 = math.ceil(#v131 / p1 * p2)
    local v146 = Vector3.new(v131[1].PrimaryPart.Size.X * p1, v131[1].PrimaryPart.Size.Y * v145, v131[1].PrimaryPart.Size.Z * p2)
    v144.Size = v146
    v144.Transparency = 1
    v144.CanCollide = false
    v144.Anchored = true
    v144.Name = "preview"
    local v147 = Vector3.new(-v144.Size.X / 2 + v131[1].PrimaryPart.Size.X / 2, -v144.Size.Y / 2 + v131[1].PrimaryPart.Size.Y / 2, -v144.Size.Z / 2 + v131[1].PrimaryPart.Size.Z / 2)
    local v148 = math.ceil(#v131 / p1 * p2)
    local v149 = v131[0 + 1]:Clone()
    v149.PrimaryPart.CanCollide = false
    v149.PrimaryPart.Transparency = 0,5
    local v150 = Vector3.new(0, 0, 0)
    v149.PrimaryPart.Orientation = v150
    local v151 = Vector3.new(v144.Position + v147.X + math.huge * v131[1].PrimaryPart.Size.X, v144.Position + v147.Y + p1 * p2 * v131[1].PrimaryPart.Size.Y, v144.Position + v147.Z + v78 * v131[1].PrimaryPart.Size.Z)
    v149.PrimaryPart.Position = v151
    v149.Parent = v144
    local v152 = v149:FindFirstChild("SelectionBox")
    v152:Destroy()
    local v153 = Instance.new("WeldConstraint", v149.PrimaryPart)
    v153.Part0 = v149.PrimaryPart
    v153.Part1 = v144
    local v154, v155 = v149:GetChildren()
    local v156 = v78 * v131[1].PrimaryPart.Size.Z.Name:match("Decal")
    v78 * v131[1].PrimaryPart.Size.Z.Transparency = 1
    v157, v158 = next(v154, v155)
    if v157 ~= nil then v155 = v157 end
    1 = 1 + 1
    if 1 <= p2 then
    -- continue loop (PC + -73)
    end
    1 = 1 + 1
    if 1 <= p1 then
    -- continue loop (PC + -78)
    end
    1 = 1 + 1
    if 1 <= v148 then
    -- continue loop (PC + -83)
    end
    local v159 = CFrame.new(_G.鼠标.Hit.X + p1 / 2 * v131[1].PrimaryPart.Size.X, _G.鼠标.Hit.Y + v144.Size.Y / 2, _G.鼠标.Hit.Z + p2 / 2 * v131[1].PrimaryPart.Size.Z)
    v144.CFrame = v159
    local v160 = _G.鼠标.Move:Connect(function()
    local v160 = CFrame.new(_G.鼠标.Hit.X + upvalue_1 / 2 * upvalue_2[1].PrimaryPart.Size.X, _G.鼠标.Hit.Y + upvalue_0.Size.Y / 2, _G.鼠标.Hit.Z + upvalue_3 / 2 * upvalue_2[1].PrimaryPart.Size.Z)
    upvalue_0.CFrame = v160
    return
end)
    _G.整理鼠标移动 = v160
    local v161 = _G.鼠标.Button1Down:Connect(function()
    pcall(function()
    _G.整理鼠标移动.Disconnect(_G.整理鼠标移动)
    _G.整理鼠标移动 = nil
    return
end)
    pcall(function()
    _G.整理鼠标点击.Disconnect(_G.整理鼠标点击)
    _G.整理鼠标点击 = nil
    return
end)
    _G.菜单.传送停止 = false
    local v161 = game.Workspace:FindFirstChild("preview")
    local v162, v163 = v161:GetChildren()
    local v164 = v131:FindFirstChildOfClass("Part")
    local v165 = upvalue_0[0 + 1]:FindFirstChild("ItemName")
    pcall(function()
    local v166 = upvalue_0[upvalue_1]:FindFirstChild("SelectionBox")
    v166:Destroy()
    return
end)
    _G.自己身体.PlatformStand = true
    local v166 = Instance.new("BodyPosition", upvalue_0[upvalue_0].PrimaryPart)
    local v167 = Vector3.new(100, 100, 100)
    v166.MaxForce = v167
    v166.Position = v131.PrimaryPart.Position
    v166.P = 100000
    v166.Name = "freeze2"
    local v168 = CFrame.new(upvalue_0[upvalue_0].PrimaryPart.Position.X, _G.自己的方块.Size.Y, upvalue_0[upvalue_0].PrimaryPart.Position.Z)
    local v169 = Vector3.new(2, 1, 2)
    _G.传送(v168 + v169)
    pcall(function()
    local v170 = upvalue_0[upvalue_1]:FindFirstChild("SelectionBox")
    v170:Destroy()
    return
end)
    upvalue_1(upvalue_0[upvalue_0], v131.PrimaryPart.CFrame)
    local v170 = Vector3.new(0, 0, 0)
    upvalue_0[upvalue_0].PrimaryPart.Velocity = v170
    local v171 = Vector3.new(0, 0, 0)
    upvalue_0[upvalue_0].PrimaryPart.RotVelocity = v171
    task.wait(v171)
    pcall(function()
    local v172 = upvalue_0[upvalue_1]:FindFirstChild("SelectionBox")
    v172:Destroy()
    return
end)
    pcall(function()
    upvalue_0:Destroy()
    local v172 = upvalue_1[upvalue_2].PrimaryPart.FindFirstChild(upvalue_1[upvalue_2].PrimaryPart, "freeze1")
    v172:Destroy()
    return
end)
    task.wait(function()
    upvalue_0:Destroy()
    local v172 = upvalue_1[upvalue_2].PrimaryPart.FindFirstChild(upvalue_1[upvalue_2].PrimaryPart, "freeze1")
    v172:Destroy()
    return
end)
    pcall(function()
    local v172 = game:GetService("ReplicatedStorage")
    v172.PlaceStructure.ClientPlacedStructure:FireServer(upvalue_1[upvalue_2].ItemName.Value, upvalue_0.PrimaryPart.CFrame, upvalue_1[upvalue_2].Owner.Value, nil, upvalue_1[upvalue_2], true)
    task.wait(0,1)
    return
end)
    pcall(function()
    local v172 = upvalue_0[upvalue_1]:FindFirstChild("SelectionBox")
    v172:Destroy()
    return
end)
    task.wait(function()
    local v172 = upvalue_0[upvalue_1]:FindFirstChild("SelectionBox")
    v172:Destroy()
    return
end)
    v172, v173 = next(v162, v163)
    if v172 ~= nil then v163 = v172 end
    upvalue_2 = true
    _G.菜单.停止整理 = false
    return
end)
    _G.整理鼠标点击 = v161
    task.wait(v161)
    pcall(function()
    local v162 = game:GetService("Workspace")
    local v163, v164 = v162.PlayerModels:GetChildren()
    local v165 = 0 + 1:FindFirstChild(upvalue_0)
    local v166 = 0 + 1:FindFirstChild("SelectionBox")
    local v167 = 0 + 1:FindFirstChild("Owner")
    local v168 = tostring(0 + 1.Owner.Value)
    table.insert(upvalue_2, 0 + 1)
    local v169 = 0 + 1:FindFirstChildOfClass("Part")
    0 + 1.PrimaryPart = v169
    0 + 1.PrimaryPart.BodyPosition:Destroy()
    0 + 1.PrimaryPart.BodyVelocity:Destroy()
    v170, v171 = next(v163, v164)
    if v170 ~= nil then v164 = v170 end
    return
end)
    pcall(function()
    local v162 = game:GetService("Workspace")
    local v163 = v162:FindFirstChild("preview")
    v163:Destroy()
    _G.自己身体.PlatformStand = false
    return
end)
    return
end
local v131 = v24:CreateTab("Items", "6035030083")
local v132 = v131:Section("Position")
local v133 = {}
v132:DropDown("Select the player", v133, true, false, function(p0)
    _G.菜单.传送的玩家 = p0
    return
end)
v132:Button("Set Position", function()
    pcall(function()
    game.Workspace.darkx.Destroy(game.Workspace.darkx)
    return
end)
    local v134 = Instance.new("Part", game.Workspace)
    v134.CanCollide = false
    v134.Anchored = true
    v134.Shape = Enum.PartType.Ball
    local v135 = Color3.fromRGB(0, 217, 255)
    v134.Color = v135
    v134.Transparency = 0
    local v136 = Vector3.new(2, 2, 2)
    v134.Size = v136
    v134.CFrame = _G.自己的方块.CFrame
    v134.Material = Enum.Material.Marble
    v134.Name = "darkx"
    return
end)
v132:Button("Delete Position", function()
    pcall(function()
    game.Workspace.darkx.Destroy(game.Workspace.darkx)
    return
end)
    return
end)
local v134 = v131:Section("select Item")
_G.点击选择物品 = nil
v134:Toggle("Click To Select", false, function(p0)
    local v135 = _G.鼠标.Button1Up:Connect(function()
    local v135 = _G.鼠标.Target.Parent:FindFirstChild("Owner")
    local v136 = tostring(_G.鼠标.Target.Parent.Owner.Value)
    local v137 = _G.鼠标.Target.Parent:FindFirstAncestor("PlayerModels")
    local v138 = _G.鼠标.Target.Parent:FindFirstChild("SelectionBox")
    local v139 = Instance.new("SelectionBox", _G.鼠标.Target.Parent)
    v139.LineThickness = 0,05
    v139.Adornee = _G.鼠标.Target.Parent
    local v140 = _G.鼠标.Target.Parent:FindFirstChild("SelectionBox")
    v140:Destroy()
    return
end)
    _G.点击选择物品 = v135
    _G.点击选择物品:Disconnect()
    _G.点击选择物品 = nil
    return
end)
v134:Toggle("Group Select", false, function(p0)
    local v135 = _G.鼠标.Button1Up:Connect(function()
    local v135 = _G.鼠标.Target.Parent:FindFirstChild("Owner")
    local v136 = tostring(_G.鼠标.Target.Parent.Owner.Value)
    local v137 = _G.鼠标.Target.Parent:FindFirstAncestor("PlayerModels")
    local v138 = game:GetService("Workspace")
    local v139, v140 = v138.PlayerModels:GetChildren()
    local v141 = nil:FindFirstChild("Owner")
    local v142 = tostring(nil.Owner.Value)
    local v143 = nil:FindFirstChild("ItemName")
    local v144 = _G.鼠标.Target.Parent:FindFirstChild("ItemName")
    local v145 = nil:FindFirstChild("DraggableItem")
    local v146 = nil:FindFirstChild("SelectionBox")
    local v147 = Instance.new("SelectionBox", nil)
    v147.LineThickness = 0,05
    v147.Adornee = nil
    local v148 = nil:FindFirstChild("SelectionBox")
    v148:Destroy()
    local v149 = nil:FindFirstChild("PurchasedBoxItemName")
    local v150 = _G.鼠标.Target.Parent:FindFirstChild("PurchasedBoxItemName")
    local v151 = nil:FindFirstChild("SelectionBox")
    local v152 = Instance.new("SelectionBox", nil)
    v152.LineThickness = 0,05
    v152.Adornee = nil
    local v153 = nil:FindFirstChild("SelectionBox")
    v153:Destroy()
    local v154 = nil:FindFirstChild("TreeClass")
    local v155 = _G.鼠标.Target.Parent:FindFirstChild("TreeClass")
    local v156 = nil:FindFirstChild("SelectionBox")
    local v157 = Instance.new("SelectionBox", nil)
    v157.LineThickness = 0,05
    v157.Adornee = nil
    local v158 = nil:FindFirstChild("SelectionBox")
    v158:Destroy()
    v159, v160 = next(v139, v140)
    if v159 ~= nil then v140 = v159 end
    return
end)
    _G.点击选择同类型物品 = v135
    _G.点击选择同类型物品:Disconnect()
    _G.点击选择同类型物品 = nil
    return
end)
v134:Toggle("Lasso Tool", false, function(p0)
    local v135 = game:GetService("UserInputService")
    local v136 = v135.InputBegan:Connect(function(p0)
    upvalue_0.Visible = true
    local v136 = UDim2.new(0, _G.鼠标.X, 0, _G.鼠标.Y)
    upvalue_0.Position = v136
    local v137 = game:GetService("UserInputService")
    local v138 = v137:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
    local v139 = game:GetService("UserInputService")
    local v140 = v139:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
    local v141 = game:GetService("UserInputService")
    local v142 = v141:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
    local v143 = game:GetService("RunService")
    v143.RenderStepped:wait()
    task.wait(v143.RenderStepped)
    local v144 = UDim2.new(0, _G.鼠标.X, 0, _G.鼠标.Y)
    upvalue_0.Size = v144 - upvalue_0.Position
    local v145, v146, v147 = workspace.PlayerModels:GetChildren()
    local v148, v149, v150 = pairs(v145)
    local v151 = 0:FindFirstChild("Owner")
    local v152 = tostring(0.Owner.Value)
    local v153 = 0:FindFirstChild("WoodSection")
    local v154, v155 = game.Workspace.CurrentCamera:WorldToScreenPoint(0.WoodSection.CFrame.p)
    local v156 = _G.在框内(v154, upvalue_0)
    local v157 = 0:FindFirstChild("SelectionBox")
    local v158 = Instance.new("SelectionBox", 0)
    v158.LineThickness = 0,05
    v158.Adornee = 0
    local v159 = 0:FindFirstChild("Owner")
    local v160 = tostring(0.Owner.Value)
    local v161 = 0:FindFirstChild("DraggableItem")
    local v162 = 0:FindFirstChild("PurchasedBoxItemName")
    local v163, v164 = game.Workspace.CurrentCamera:WorldToScreenPoint(0.Main.CFrame.p)
    local v165 = _G.在框内(v163, upvalue_0)
    local v166 = 0:FindFirstChild("SelectionBox")
    local v167 = Instance.new("SelectionBox", 0)
    v167.LineThickness = 0,05
    v167.Adornee = 0
    v168, v169 = v148(v149, v150)
    if v168 ~= nil then v150 = v168 end
    local v170 = UDim2.new(0, 1, 0, 1)
    upvalue_0.Size = v170
    upvalue_0.Visible = false
    return
end)
    _G.菜单.物品框 = v136
    upvalue_0.Visible = false
    _G.菜单.物品框:Disconnect()
    _G.菜单.物品框 = nil
    return
end)
v134:Button("Deselect All Item", function()
    local v135 = game:GetService("Workspace")
    local v136, v137 = v135.PlayerModels:GetChildren()
    local v138 = v20:FindFirstChild("Owner")
    local v139 = tostring(v20.Owner.Value)
    local v140 = v20:FindFirstChild("SelectionBox")
    local v141 = v20:FindFirstChild("SelectionBox")
    v141:Destroy()
    v142, v143 = next(v136, v137)
    if v142 ~= nil then v137 = v142 end
    return
end)
local v135 = v131:Section("Item")
v135:Button("Make Selected Plank Size To 1", function()
    local v136 = game:GetService("Workspace")
    local v137, v138 = v136.PlayerModels:GetChildren()
    local v139 = v20:FindFirstChild("Owner")
    local v140 = tostring(v20.Owner.Value)
    local v141 = v20:FindFirstChild("SelectionBox")
    local v142 = v20:FindFirstChild("WoodSection")
    local v143 = Vector3.new(1, 1, 1)
    v20.WoodSection.Size = v143
    v144, v145 = next(v137, v138)
    if v144 ~= nil then v138 = v144 end
    return
end)
v135:Button("Tp All Selected Item", function()
    local v136 = game.Workspace.FindFirstChild(game.Workspace, "darkx")
    return _G.提醒("Please Set Position")
    return ...
    local v140 = {}
    _G.传送的东西 = v140
    local v141 = game:GetService("Workspace")
    local v142, v143 = v141.PlayerModels:GetChildren()
    local v144 = v20:FindFirstChild("Owner")
    local v145 = tostring(v20.Owner.Value)
    local v146 = v20:FindFirstChild("SelectionBox")
    local v147 = v20:FindFirstChildOfClass("Part")
    v20.PrimaryPart = v147
    table.insert(_G.传送的东西, v20)
    v148, v149 = next(v142, v143)
    if v148 ~= nil then v143 = v148 end
    _G.菜单.传送停止 = false
    local v150 = table.insert:FindFirstChild("SelectionBox")
    v150:Destroy()
    table.insert.PrimaryPart.Anchored = false
    local v151 = table.insert:FindFirstChildOfClass("Part")
    local v152 = table.insert:FindFirstChild("WoodSection")
    local v153 = table.insert:FindFirstChild("PurchasedBoxItemName")
    table.insert.PrimaryPart.Anchored = false
    local v154 = CFrame.new(table.insert.PrimaryPart.Position.X, _G.自己的方块.Position.Y, table.insert.PrimaryPart.Position.Z)
    local v155 = Vector3.new(1, 0, 0)
    _G.传送(v154 + v155)
    local v156 = Vector3.new(0, 0, 0)
    table.insert.PrimaryPart.Velocity = v156
    local v157 = Vector3.new(0, 0, 0)
    table.insert.PrimaryPart.RotVelocity = v157
    local v158 = table.insert:FindFirstChild("WoodSection")
    upvalue_0(table.insert, game.Workspace.darkx.CFrame)
    local v159 = CFrame.Angles(-90, 0, 90)
    upvalue_0(table.insert, game.Workspace.darkx.CFrame * v159)
    upvalue_0(table.insert, game.Workspace.darkx.CFrame)
    local v160 = game:GetService("RunService")
    v160.Stepped:wait()
    task.wait(v160.Stepped)
    task.wait(v160.Stepped)
    pcall(function()
    local v161 = upvalue_0:FindFirstChild("SelectionBox")
    v161:Destroy()
    return
end)
    pcall(function()
    local v161 = upvalue_0:FindFirstChild("SelectionBox")
    v161:Destroy()
    return
end)
    pcall(function()
    local v161 = upvalue_0:FindFirstChild("ItemName")
    local v162 = game:GetService("ReplicatedStorage")
    v162.PlaceStructure.ClientPlacedStructure:FireServer(upvalue_0.ItemName.Value, game.Workspace.darkx.CFrame, upvalue_0.Owner.Value, nil, upvalue_0, true)
    task.wait(0,1)
    return
end)
    wait(function()
    local v161 = upvalue_0:FindFirstChild("ItemName")
    local v162 = game:GetService("ReplicatedStorage")
    v162.PlaceStructure.ClientPlacedStructure:FireServer(upvalue_0.ItemName.Value, game.Workspace.darkx.CFrame, upvalue_0.Owner.Value, nil, upvalue_0, true)
    task.wait(0,1)
    return
end)
    v162, v163 = next(_G.传送的东西, v161)
    if v162 ~= nil then v161 = v162 end
    _G.传送(table.insert)
    _G.菜单.飞行 = false
    spawn(function()
    _G.飞行(false)
    return
end)
    _G.穿墙(false)
    _G.菜单.飞行速度 = _G.旧的飞行速度
    return
end)
v135:Toggle("Standing Wood", false, function(p0)
    _G.菜单.木头竖着传送 = p0
    return
end)
v135:Button("Abort", function()
    _G.菜单.传送停止 = true
    return
end)
local v136 = v131:Section("Box Sort")
v136:TextBox("X", "5", function(p0)
    local v137 = tonumber(p0)
    _G.菜单.整理物品X = v137
    return
end)
v136:TextBox("Z", "5", function(p0)
    local v137 = tonumber(p0)
    _G.菜单.整理物品Z = v137
    return
end)
v136:Button("Start", function()
    local v137 = {}
    local v138 = {}
    local v139 = {}
    return _G.提醒("you are using this feature")
    return ...
    _G.菜单.正在整理物品 = true
    local v143 = game:GetService("Workspace")
    local v144, v145 = v143.PlayerModels:GetChildren()
    local v146 = function(p0)
    local v28 = p0:FindFirstChildOfClass("MeshPart")
    local v29 = p0:FindFirstChildOfClass("MeshPart")
    p0.PrimaryPart = v29
    return
    local v30 = p0:FindFirstChildOfClass("Part")
    local v31 = p0:FindFirstChildOfClass("MeshPart")
    local v32 = p0:FindFirstChild("Main")
    p0.PrimaryPart = v32
    return
end:FindFirstChild("Owner")
    local v147 = tostring(function(p0)
    local v28 = p0:FindFirstChildOfClass("MeshPart")
    local v29 = p0:FindFirstChildOfClass("MeshPart")
    p0.PrimaryPart = v29
    return
    local v30 = p0:FindFirstChildOfClass("Part")
    local v31 = p0:FindFirstChildOfClass("MeshPart")
    local v32 = p0:FindFirstChild("Main")
    p0.PrimaryPart = v32
    return
end.Owner.Value)
    local v148 = function(p0)
    local v28 = p0:FindFirstChildOfClass("MeshPart")
    local v29 = p0:FindFirstChildOfClass("MeshPart")
    p0.PrimaryPart = v29
    return
    local v30 = p0:FindFirstChildOfClass("Part")
    local v31 = p0:FindFirstChildOfClass("MeshPart")
    local v32 = p0:FindFirstChild("Main")
    p0.PrimaryPart = v32
    return
end:FindFirstChild("SelectionBox")
    local v149 = function(p0)
    local v28 = p0:FindFirstChildOfClass("MeshPart")
    local v29 = p0:FindFirstChildOfClass("MeshPart")
    p0.PrimaryPart = v29
    return
    local v30 = p0:FindFirstChildOfClass("Part")
    local v31 = p0:FindFirstChildOfClass("MeshPart")
    local v32 = p0:FindFirstChild("Main")
    p0.PrimaryPart = v32
    return
end:FindFirstChild("ItemName")
    local v150 = table.find(v138, function(p0)
    local v28 = p0:FindFirstChildOfClass("MeshPart")
    local v29 = p0:FindFirstChildOfClass("MeshPart")
    p0.PrimaryPart = v29
    return
    local v30 = p0:FindFirstChildOfClass("Part")
    local v31 = p0:FindFirstChildOfClass("MeshPart")
    local v32 = p0:FindFirstChild("Main")
    p0.PrimaryPart = v32
    return
end.ItemName.Value)
    table.insert(v138, function(p0)
    local v28 = p0:FindFirstChildOfClass("MeshPart")
    local v29 = p0:FindFirstChildOfClass("MeshPart")
    p0.PrimaryPart = v29
    return
    local v30 = p0:FindFirstChildOfClass("Part")
    local v31 = p0:FindFirstChildOfClass("MeshPart")
    local v32 = p0:FindFirstChild("Main")
    p0.PrimaryPart = v32
    return
end.ItemName.Value)
    local v151 = function(p0)
    local v28 = p0:FindFirstChildOfClass("MeshPart")
    local v29 = p0:FindFirstChildOfClass("MeshPart")
    p0.PrimaryPart = v29
    return
    local v30 = p0:FindFirstChildOfClass("Part")
    local v31 = p0:FindFirstChildOfClass("MeshPart")
    local v32 = p0:FindFirstChild("Main")
    p0.PrimaryPart = v32
    return
end:FindFirstChild("PurchasedBoxItemName")
    local v152 = table.find(v137, function(p0)
    local v28 = p0:FindFirstChildOfClass("MeshPart")
    local v29 = p0:FindFirstChildOfClass("MeshPart")
    p0.PrimaryPart = v29
    return
    local v30 = p0:FindFirstChildOfClass("Part")
    local v31 = p0:FindFirstChildOfClass("MeshPart")
    local v32 = p0:FindFirstChild("Main")
    p0.PrimaryPart = v32
    return
end.PurchasedBoxItemName.Value)
    table.insert(v137, function(p0)
    local v28 = p0:FindFirstChildOfClass("MeshPart")
    local v29 = p0:FindFirstChildOfClass("MeshPart")
    p0.PrimaryPart = v29
    return
    local v30 = p0:FindFirstChildOfClass("Part")
    local v31 = p0:FindFirstChildOfClass("MeshPart")
    local v32 = p0:FindFirstChild("Main")
    p0.PrimaryPart = v32
    return
end.PurchasedBoxItemName.Value)
    local v153 = function(p0)
    local v28 = p0:FindFirstChildOfClass("MeshPart")
    local v29 = p0:FindFirstChildOfClass("MeshPart")
    p0.PrimaryPart = v29
    return
    local v30 = p0:FindFirstChildOfClass("Part")
    local v31 = p0:FindFirstChildOfClass("MeshPart")
    local v32 = p0:FindFirstChild("Main")
    p0.PrimaryPart = v32
    return
end:FindFirstChild("TreeClass")
    local v154 = table.find(v139, function(p0)
    local v28 = p0:FindFirstChildOfClass("MeshPart")
    local v29 = p0:FindFirstChildOfClass("MeshPart")
    p0.PrimaryPart = v29
    return
    local v30 = p0:FindFirstChildOfClass("Part")
    local v31 = p0:FindFirstChildOfClass("MeshPart")
    local v32 = p0:FindFirstChild("Main")
    p0.PrimaryPart = v32
    return
end.TreeClass.Value)
    table.insert(v139, function(p0)
    local v28 = p0:FindFirstChildOfClass("MeshPart")
    local v29 = p0:FindFirstChildOfClass("MeshPart")
    p0.PrimaryPart = v29
    return
    local v30 = p0:FindFirstChildOfClass("Part")
    local v31 = p0:FindFirstChildOfClass("MeshPart")
    local v32 = p0:FindFirstChild("Main")
    p0.PrimaryPart = v32
    return
end.TreeClass.Value)
    v155, v156 = next(v144, v145)
    if v155 ~= nil then v145 = v155 end
    _G.盒子传送(v156, _G.菜单.整理物品X, _G.菜单.整理物品Z, "PurchasedBoxItemName")
    task.wait(v156)
    v158, v159 = next(v137, v157)
    if v158 ~= nil then v157 = v158 end
    _G.盒子传送(v159, _G.菜单.整理物品X, _G.菜单.整理物品Z, "ItemName")
    task.wait(v159)
    v161, v162 = next(v138, v160)
    if v161 ~= nil then v160 = v161 end
    _G.盒子传送(v162, _G.菜单.整理物品X, _G.菜单.整理物品Z, "TreeClass")
    task.wait(v162)
    v164, v165 = next(v139, v163)
    if v164 ~= nil then v163 = v164 end
    _G.菜单.正在整理物品 = false
    return
end)
v136:Button("Abort", function()
    _G.菜单.停止整理 = true
    upvalue_0 = true
    _G.自己身体.PlatformStand = false
    local v137 = game:GetService("Workspace")
    local v138 = v137:FindFirstChild("preview")
    v138:Destroy()
    pcall(function()
    _G.整理鼠标移动.Disconnect(_G.整理鼠标移动)
    _G.整理鼠标移动 = nil
    return
end)
    _G.自己身体.PlatformStand = false
    pcall(function()
    _G.菜单.正在整理物品 = false
    local v139 = game:GetService("Workspace")
    v139.CurrentCamera.CameraSubject = _G.自己身体
    return
end)
    _G.传送(oldpos)
    _G.菜单.飞行 = false
    spawn(function()
    _G.飞行(false)
    return
end)
    _G.穿墙(false)
    _G.菜单.飞行速度 = _G.旧的飞行速度
    return
end)
_G.修改汽车的属性 = function(p0, p1)
    local v137 = game:GetService("Workspace")
    local v138, v139 = v137.PlayerModels:GetChildren()
    local v140 = v24:FindFirstChild("Owner")
    local v141 = v24:FindFirstChild("Type")
    local v142 = v24:FindFirstChild("Configuration")
    v24.Configuration[p1].Value = p0
    v143, v144 = next(v138, v139)
    if v143 ~= nil then v139 = v143 end
    return
end
local v137 = v24:CreateTab("Vehicle", "6034754441")
local v138 = v137:Section("Vehicle")
v138:Slider("Vehicle Speed", 1, 1, 5, false, function(p0)
    _G.修改汽车的属性(p0, "MaxSpeed")
    return
end)
v138:Slider("Steer Angle", 0,7, 0,7, 5, true, function(p0)
    _G.修改汽车的属性(p0, "SteerAngle")
    return
end)
v138:Button("Flip Vehicle", function()
    _G.提醒("You need to sit in the vehicles driver seat")
    return
    local v139 = math.rad(-180)
    local v140 = CFrame.Angles(v139, 0, 0)
    local v141 = Vector3.new(0, 5, 0)
    _G.自己身体.SeatPart.Parent.PivotTo(_G.自己身体.SeatPart.Parent, _G.自己身体.SeatPart.Parent.PrimaryPart.CFrame * v140 + v141)
    return
end)
local v139 = v137:Section("Vehicle Spawner")
local v140 = {}
v140 = {"Medium stone grey", "Sand green", "Sand red", "Faded green", "Dark grey metallic", "Dark grey", "Earth yellow", "Earth orange", "Silver", "Brick yellow", "Dark red", "Hot pink"}
v139:DropDown("Select Color", v140, false, false, function(p0)
    _G.菜单.汽车的颜色 = p0
    return
end)
v139:Button("Start Vehicle Spawner", function()
    return _G.提醒("you are using this feature")
    return ...
    return _G.提醒("No car color selected")
    return ...
    _G.提醒("Click a spawn pad")
    _G.菜单.停止生成车 = false
    _G.生成成功 = false
    local v147 = game:GetService("Workspace")
    local v148 = v147.PlayerModels.ChildAdded:connect(function(p0)
    local v148 = p0:WaitForChild("Owner")
    local v149 = p0:WaitForChild("PaintParts")
    local v150 = p0.PaintParts:WaitForChild("Part")
    _G.生成成功 = true
    return
end)
    _G.汽车生成检测 = v148
    _G.菜单.正在生成车 = true
    _G.选择的汽车 = nil
    local v149 = _G.鼠标.Button1Up:Connect(function()
    _G.选择的汽车 = _G.鼠标.Target
    return
end)
    wait(_G.鼠标.Button1Up)
    _G.提醒("Aborted")
    local v150 = game:GetService("ReplicatedStorage")
    v150.Interaction.RemoteProxy:FireServer(_G.选择的汽车.Parent.ButtonRemote_SpawnButton)
    task.wait(1)
    v149:Disconnect()
    _G.汽车生成检测:Disconnect()
    _G.提醒("Finished spawning vehicle")
    _G.菜单.正在生成车 = false
    return
end)
v139:Button("Abort", function()
    _G.菜单.停止生成车 = true
    return
end)
_G.获得木头 = function()
    local v141 = game:GetService("Workspace")
    local v142, v143 = v141.PlayerModels:GetChildren()
    local v144 = v20:FindFirstChild("Owner")
    local v145 = v20:FindFirstChild("WoodSection")
    local v146 = tostring(v20.Owner.Value)
    local v147 = tostring(v20.TreeClass.Value)
    return v20
    v148, v149 = next(v142, v143)
    if v148 ~= nil then v143 = v148 end
    return
end
_G.填充所有蓝图 = function()
    local v141 = game:GetService("Workspace")
    local v142, v143 = v141.PlayerModels:GetChildren()
    local v144 = nil:FindFirstChild("Owner")
    local v145 = nil:FindFirstChild("Main")
    local v146 = nil:FindFirstChild("Type")
    local v147 = _G.获得木头(_G.自己)
    _G.传送(v147.WoodSection.CFrame)
    _G.拉东西:FireServer(v147)
    task.wait(_G.拉东西)
    1 = 1 + 1
    if 1 <= 5 then
    -- continue loop (PC + -9)
    end
    v147:PivotTo(nil.Main.CFrame)
    task.wait(0,1)
    1 = 1 + 1
    if 1 <= 2 then
    -- continue loop (PC + -22)
    end
    task.wait(2)
    v148, v149 = next(v142, v143)
    if v148 ~= nil then v143 = v148 end
    _G.传送(_G.自己的方块.CFrame)
    return
end
_G.油漆 = function(p0)
    return _G.提醒("select Wood At First")
    return ...
    _G.蓝图名字 = p0.ItemName.Value
    local v144 = p0:FindFirstChild("MainCFrame")
    _G.旧的地方 = p0.MainCFrame.Value
    _G.旧的地方 = p0.PrimaryPart.CFrame
    _G.木头大小 = nil
    local v145 = game:GetService("ReplicatedStorage")
    local v146, v147 = v145.ClientItemInfo:GetChildren()
    local v148, v149 = v24:GetChildren()
    _G.木头大小 = v28.Value
    v150, v151 = next(v148, v149)
    if v150 ~= nil then v149 = v150 end
    v152, v153 = next(v146, v147)
    if v152 ~= nil then v147 = v152 end
    _G.木头大小 = 1
    local v154, v155, v156 = tonumber(_G.菜单.自动填充的树)
    local v157, v158 = _G.检查斧头(v154)
    _G.伤害 = v158
    _G.斧头 = v157
    return _G.提醒("you need one axe")
    return ...
    _G.木头的大小 = nil
    _G.选择的木头 = nil
    local v162, v163 = game.Workspace:GetChildren()
    local v164, v165 = v155:GetChildren()
    local v166 = v151:FindFirstChild("WoodSection")
    local v167 = v151:FindFirstChild("TreeClass")
    local v168 = v151:FindFirstChild("TreeClass")
    local v169, v170 = v151:GetChildren()
    local v171 = v53.ChildIDs:GetChildren()
    _G.木头的大小 = v53.Size.X
    _G.选择的木头 = v53
    v172, v173 = next(v169, v170)
    if v172 ~= nil then v170 = v172 end
    v174, v175 = next(v164, v165)
    if v174 ~= nil then v165 = v174 end
    v176, v177 = next(v162, v163)
    if v176 ~= nil then v163 = v176 end
    return _G.提醒("Not Find  right tree")
    return ...
    _G.加入的木头 = nil
    local v181 = game.Workspace.LogModels.ChildAdded:connect(function(p0)
    p0:WaitForChild("Owner")
    local v181 = p0:FindFirstChild("WoodSection")
    _G.加入的木头 = p0
    return
end)
    _G.加入的树 = v181
    _G.砍的地方 = _G.木头大小 / _G.选择的木头.Size.X * _G.选择的木头.Size.X + 0,01
    game["Run Service"].Heartbeat:wait()
    local v182 = Vector3.new(4, 2, 2)
    _G.传送(_G.选择的木头.CFrame + v182)
    _G.砍(_G.选择的木头.Parent.CutEvent, _G.斧头, _G.选择的木头.ID.Value, _G.选择的木头.Size.Y - _G.砍的地方, _G.伤害)
    pcall(function()
    _G.加入的树.Disconnect(_G.加入的树)
    _G.加入的树 = nil
    return
end)
    _G.填充完成 = false
    local v183 = game.Workspace.PlayerModels.ChildAdded:Connect(function(p0)
    p0:WaitForChild("Owner")
    local v183 = p0:FindFirstChild("Type")
    local v184 = p0:FindFirstChild("BlueprintWoodClass")
    game.ReplicatedStorage.PlaceStructure.ClientPlacedStructure:FireServer(p0.ItemName.Value, _G.旧的地方, _G.自己, _G.菜单.自动填充的树, p0, true, nil)
    _G.填充完成 = true
    return
end)
    _G.检测是否成功 = v183
    local v184 = game:GetService("Workspace")
    local v185 = v184.PlayerModels.ChildAdded:connect(function(p0)
    p0:WaitForChild("Owner")
    local v185 = p0:FindFirstChild("Owner")
    local v186 = p0:FindFirstChild("WoodSection")
    task.wait(p0)
    local v187 = p0:FindFirstChild("TreeClass")
    p0.WoodSection.Anchored = true
    local v188 = {}
    v188[1] = _G.蓝图名字
    v188[2] = p0.WoodSection.CFrame
    v188[3] = _G.自己
    v188[4] = upvalue_0
    v188[5] = true
    local v189 = game:GetService("ReplicatedStorage")
    local v190 = v189:WaitForChild("PlaceStructure")
    local v191 = v190:WaitForChild("ClientPlacedBlueprint")
    local v192, v193, v194 = unpack(v188)
    v191:FireServer(v192)
    return
end)
    _G.木板加入 = v185
    _G.拉东西:FireServer(_G.加入的木头)
    _G.加入的木头:PivotTo(_G.菜单.油漆的锯木机.Particles.CFrame)
    _G.拉东西:FireServer(_G.加入的木头)
    task.wait(2)
    task.wait(2)
    pcall(function()
    _G.木板加入.Disconnect(_G.木板加入)
    _G.木板加入 = nil
    _G.检测是否成功.Disconnect(_G.检测是否成功)
    _G.检测是否成功 = nil
    return
end)
    _G.提醒("done")
    _G.传送(_G.自己的方块.CFrame)
    return
end
local v141 = v24:CreateTab("AutoBuild", "6034281908")
local v142 = v141:Section("Auto Filler")
local v143 = {}
v142:DropDown("Select the player", v143, true, false, function(p0)
    _G.菜单.自动填充的玩家 = p0
    return
end)
local v144 = {}
v144 = {"Generic", "GoldSwampy", "CaveCrawler", "Cherry", "Frost", "Volcano", "Oak", "Walnut", "Birch", "SnowGlow", "Pine", "GreenSwampy", "Koa", "Palm", "LoneCave", "Spooky", "SpookyNeon"}
v142:DropDown("Select Wood Type", v144, false, false, function(p0)
    _G.菜单.自动填充的树 = p0
    return
end)
_G.自动填充 = false
v142:Toggle("Auto Build Loops", false, function(p0)
    _G.自动填充 = p0
    local v145 = task.wait(v15)
    _G.填充所有蓝图(v15)
    return
end)
v142:Button("Fill All blueprint", function()
    _G.填充所有蓝图(v13)
    return
end)
v142:Toggle("Click to Fill", false, function(p0)
    local v145 = _G.鼠标.Button1Up:Connect(function()
    local v145 = tostring(_G.鼠标.Target.Parent.Owner.Value)
    local v146 = _G.鼠标.Target.Parent:FindFirstChild("Type")
    local v147 = _G.鼠标.Target.Parent:FindFirstChild("Main")
    local v148 = _G.获得木头(_G.鼠标.Target.Parent)
    _G.传送(v148.WoodSection.CFrame)
    _G.拉东西:FireServer(v148)
    _G.拉东西:FireServer(v148)
    task.wait(_G.拉东西)
    1 = 1 + 1
    if 1 <= 5 then
    -- continue loop (PC + -9)
    end
    v148:PivotTo(_G.鼠标.Target.Parent.Main.CFrame)
    task.wait(0,1)
    1 = 1 + 1
    if 1 <= 2 then
    -- continue loop (PC + -23)
    end
    _G.传送(_G.自己的方块.CFrame)
    return
end)
    _G.点击蓝图 = v145
    _G.点击蓝图:Disconnect()
    _G.点击蓝图 = nil
    return
end)
local v145 = v141:Section("Paint")
local v146 = v145:Label("Please Selecet one Sawmill")
_G.锯木机 = v146
v145:Button("Click To Select Sawmill", function()
    _G.提醒("Click one  Sawmill")
    local v147 = _G.鼠标.Button1Up:Connect(function()
    wait(_G.鼠标.Button1Up.Connect)
    local v147 = _G.鼠标.Target.Parent:FindFirstChild("Settings")
    local v148 = _G.鼠标.Target.Parent.Settings:FindFirstChild("DimZ")
    upvalue_0 = _G.鼠标.Target.Parent
    _G.提醒("Sawmill Selected")
    local v149 = _G.鼠标.Target.Parent.Parent:FindFirstChild("Settings")
    local v150 = _G.鼠标.Target.Parent.Parent.Settings:FindFirstChild("DimZ")
    upvalue_0 = _G.鼠标.Target.Parent.Parent
    _G.提醒("Sawmill Selected")
    return
end)
    task.wait(0,1)
    _G.菜单.油漆的锯木机 = false
    _G.锯木机.Text = "Selected"
    v147:Disconnect()
    return
end)
v145:Toggle("Paint Tool", false, function(p0)
    return _G.提醒["select Sawmail At First"]
    local v147 = _G.鼠标.Button1Up:Connect(function()
    local v147 = _G.鼠标.Target.Parent.FindFirstChild(_G.鼠标.Target.Parent, "Type")
    _G.油漆(_G.鼠标.Target.Parent)
    return
end)
    _G.点击蓝图 = v147
    _G.点击蓝图:Disconnect()
    _G.点击蓝图 = nil
    return
end)
_G.获得自己的蓝图 = function()
    local v147 = {}
    local v148, v149 = _G.自己.PlayerBlueprints.Blueprints:GetChildren()
    table.insert(v147, nil.Name)
    v150, v151 = next(v148, v149)
    if v150 ~= nil then v149 = v150 end
    return v147
end
_G.读取文件 = function(p0)
    local v147 = {}
    local v148, v149 = string.split(p0, "/")
    table.insert(v147, v24)
    v150, v151 = next(v148, v149)
    if v150 ~= nil then v149 = v150 end
    return v147
end
_G.填充蓝图 = function(p0)
    local v147 = _G.获得木头(v20)
    _G.传送(v147.WoodSection.CFrame)
    local v148, v149, v150 = _G.获得木头(nil)
    _G.拉东西:FireServer(v148)
    local v151, v152, v153 = _G.获得木头(100)
    _G.拉东西:FireServer(v151)
    task.wait(_G.拉东西)
    1 = 1 + 1
    if 1 <= 5 then
    -- continue loop (PC + -11)
    end
    local v154 = _G.获得木头(5)
    v154:PivotTo(p0.Main.CFrame)
    task.wait(0,1)
    1 = 1 + 1
    if 1 <= 2 then
    -- continue loop (PC + -27)
    end
    _G.传送(_G.自己的方块.CFrame)
    return
end
local v147 = v141:Section("Building Tool")
local v148 = {}
v147:DropDown("Select the player", v148, true, false, function(p0)
    _G.菜单.保存基地的玩家 = p0
    return
end)
_G.木头种类 = nil
local v149 = {}
local v150 = v147:DropDown("All Plank(Click to get Count)", v149, false, false, function(p0)
    _G.菜单.自动建造的木头 = p0
    local v150 = game.Workspace:FindFirstChild("Preview")
    local v151, v152 = v150:GetChildren()
    local v153 = v24:FindFirstChild("woodclass")
    v154, v155 = next(v151, v152)
    if v154 ~= nil then v152 = v154 end
    _G.提醒(0 + 1 .. " Plank")
    return
end)
_G.木头种类 = v150
v147:TextBox("Save Base", "File Name", function(p0)
    local v151, v152 = _G.土地:GetChildren()
    local v153 = tostring(v119.Owner.Value)
    v154, v155 = next(v151, v152)
    if v154 ~= nil then v152 = v154 end
    local v156, v157 = workspace.PlayerModels:GetChildren()
    local v158 = v155:FindFirstChild("Owner")
    local v159 = tostring(v155.Owner.Value)
    local v160 = v155:FindFirstChild("BlueprintWoodClass")
    local v161 = v155:FindFirstChild("MainCFrame")
    local v162 = tostring(v155.MainCFrame.Value - v119.OriginSquare.CFrame.p)
    local v163 = tostring(v155.ItemName.Value)
    local v164 = tostring(v155.BlueprintWoodClass.Value)
    v165, v166 = next(v156, v157)
    if v165 ~= nil then v157 = v165 end
    writefile(p0, "" .. "CFrame" .. v162 .. "Blueprint" .. v163 .. "Wood" .. v164 .. "/")
    _G.提醒("success")
    return
end)
_G.检查蓝图 = function()
    local v151, v152 = workspace.PlayerModels:GetChildren()
    local v153 = nil:FindFirstChild("BuildDependentWood")
    local v154 = nil:FindFirstChild("BlueprintWoodClass")
    v155, v156 = next(v151, v152)
    if v155 ~= nil then v152 = v155 end
    return false
    return true
end
v147:TextBox("load Base", "File Name", function(p0)
    pcall(function()
    local v151 = readfile(upvalue_1)
    upvalue_0 = v151
    return
end)
    return _G.提醒("not find file")
    return ...
    local v154 = game.Workspace:FindFirstChild("Preview")
    local v155 = game.Workspace:FindFirstChild("Preview")
    v155:Destroy()
    local v156 = Instance.new("Folder", game.Workspace)
    v156.Name = "Preview"
    local v157, v158 = _G.土地:GetChildren()
    v159, v160 = next(v157, v158)
    if v159 ~= nil then v158 = v159 end
    local v161 = {}
    local v162, v163 = _G.读取文件(v13)
    local v164 = v147.OriginSquare.CFrame:split("Blueprint")
    local v165 = {}
    local v166 = v164[1]:split("CFrame")
    local v167 = tostring(v166[2])
    local v168, v169 = v167:split(",")
    table.insert(v165, "CFrame")
    v170, v171 = next(v168, v169)
    if v170 ~= nil then v169 = v170 end
    local v172 = {}
    local v173 = v164[2]:split("Wood")
    table.insert(v172, v173[1])
    local v174 = game:GetService("ReplicatedStorage")
    local v175, v176 = v174.ClientItemInfo:GetChildren()
    local v177 = "Wood":FindFirstChild("ItemName")
    local v178 = tostring("Wood".ItemName.Parent)
    local v179 = "Wood":FindFirstChildOfClass("Model")
    local v180 = "Wood".Model:Clone()
    v180.Parent = v156
    v180.Name = v172[1]
    local v181 = tonumber(v165[1])
    local v182 = tonumber(v165[2])
    local v183 = tonumber(v165[3])
    local v184 = tonumber(v165[4])
    local v185 = tonumber(v165[5])
    local v186 = tonumber(v165[6])
    local v187 = tonumber(v165[7])
    local v188 = tonumber(v165[8])
    local v189 = tonumber(v165[9])
    local v190 = tonumber(v165[10])
    local v191 = tonumber(v165[11])
    local v192, v193, v194 = tonumber(v165[12])
    local v195 = CFrame.new(v192)
    v180:PivotTo(v195 + v147.OriginSquare.CFrame.p)
    local v196 = Instance.new("StringValue", v180)
    v196.Name = "woodclass"
    local v197 = v164[2]:split("Wood")
    v196.Value = v197[2]
    local v198 = v164[2]:split("Wood")
    local v199 = table.find(v161, v198[2])
    local v200 = v164[2]:split("Wood")
    table.insert(v161, v200[2])
    v201, v202 = next(v175, v176)
    if v201 ~= nil then v176 = v201 end
    v203, v204 = next(v162, v163)
    if v203 ~= nil then v163 = v203 end
    print(v161)
    _G.木头种类:SetOptions(v161)
    _G.提醒("load success")
    return
end)
v147:Button("select blueprint", function()
    local v151 = game.Workspace:FindFirstChild("Preview")
    local v152, v153 = v151:GetChildren()
    local v154 = v20:FindFirstChild("SelectionBox")
    v20:Destroy()
    v155, v156 = next(v152, v153)
    if v155 ~= nil then v153 = v155 end
    return _G.提醒("select Wood At First")
    return ...
    local v160 = game.Workspace.FindFirstChild(game.Workspace, "Preview")
    return _G.提醒("load ur file at first")
    return ...
    local v164 = game.Workspace:FindFirstChild("Preview")
    local v165, v166 = v164:GetChildren()
    local v167 = v20.Destroy:FindFirstChild("woodclass")
    local v168 = tostring(v20.Destroy.woodclass.Value)
    local v169 = Instance.new("SelectionBox", v20.Destroy)
    v169.LineThickness = 0,1
    v169.Adornee = v20.Destroy
    v170, v171 = next(v165, v166)
    if v170 ~= nil then v166 = v170 end
    _G.提醒("Click Build if u already build done and fill it then click this button again")
    return
end)
_G.基地加入蓝图 = nil
v147:Button("Build!", function()
    local v151 = game.Workspace.FindFirstChild(game.Workspace, "Preview")
    return _G.提醒("load ur file at first")
    return ...
    local v155 = {}
    local v156 = game.Workspace:FindFirstChild("Preview")
    local v157, v158 = v156:GetChildren()
    local v159 = table.find(v155, nil.Name)
    table.insert(v155, nil.Name)
    v160, v161 = next(v157, v158)
    if v160 ~= nil then v158 = v160 end
    local v162 = _G.自己.PlayerBlueprints.Blueprints:FindFirstChild(v161)
    return _G.提醒("u need " .. v161 .. " BluePrint")
    return ...
    v167, v168 = next(v155, v166)
    if v167 ~= nil then v166 = v167 end
    local v169 = game.Workspace:FindFirstChild("Preview")
    local v170, v171 = v169:GetChildren()
    local v172 = v163:FindFirstChild("SelectionBox")
    v173, v174 = next(v170, v171)
    if v173 ~= nil then v171 = v173 end
    return _G.提醒("select blueprint at first")
    return ...
    local v178 = game.Workspace.PlayerModels.ChildAdded:Connect(function(p0)
    local v178 = p0:FindFirstChild("Owner")
    local v179 = p0:FindFirstChild("BuildDependentWood")
    upvalue_0 = true
    return
end)
    _G.基地加入蓝图 = v178
    local v179, v180 = game.Workspace.Preview:GetChildren()
    local v181 = v172:IsA("Model")
    local v182 = v172:FindFirstChild("Main")
    local v183 = v172:FindFirstChild("SelectionBox")
    task.wait(v172)
    local v184 = game:GetService("ReplicatedStorage")
    local v185 = v184:WaitForChild("PlaceStructure")
    local v186 = v185:WaitForChild("ClientPlacedBlueprint")
    v186:FireServer(v172.Name, v172.Main.CFrame, _G.自己)
    v172:Destroy()
    wait(v172)
    task.wait(v172)
    v187, v188 = next(v179, v180)
    if v187 ~= nil then v180 = v187 end
    pcall(function()
    _G.基地加入蓝图.Disconnect(_G.基地加入蓝图)
    _G.基地加入蓝图 = nil
    return
end)
    return
end)
local v151 = v141:Section("BluePrint Place")
local v152 = _G.获得自己的蓝图("获得自己的蓝图")
local v153 = v151:DropDown("Select BluePrint Type", v152, false, false, function(p0)
    _G.菜单.蓝图名字 = p0
    return
end)
_G.自己.PlayerBlueprints.Blueprints.ChildAdded:Connect(function(p0)
    local v154, v155, v156 = _G.获得自己的蓝图(v20)
    upvalue_0:SetOptions(v154)
    return
end)
v151:Label("R T   to Use Rotate to Place B Abort")
v151:Button("Go!", function()
    local v154 = game.ReplicatedStorage.ClientItemInfo[_G.菜单.蓝图名字].Model:Clone()
    v154.Parent = Workspace
    v154.Name = "Dark XBlueprint"
    local v155, v156 = v154:GetChildren()
    v78.Transparency = 0
    v157, v158 = next(v155, v156)
    if v157 ~= nil then v156 = v157 end
    local v159 = {}
    local v160 = game:GetService("UserInputService")
    local v161 = v160.InputBegan:Connect(function(p0)
    upvalue_0 = true
    upvalue_1 = upvalue_1 + 1
    task.wait(Enum.KeyCode.R)
    upvalue_2 = true
    upvalue_3 = upvalue_3 + 1
    task.wait(Enum.KeyCode.T)
    return
end)
    v159.Function = v161
    local v162 = {}
    local v163 = game:GetService("UserInputService")
    local v164 = v163.InputEnded:Connect(function(p0)
    upvalue_2 = false
    upvalue_1 = false
    upvalue_0 = false
    return
end)
    v162.Function = v164
    local v165 = {}
    local v166 = game:GetService("UserInputService")
    local v167 = v166.InputBegan:Connect(function(p0)
    local v167 = game:GetService("ReplicatedStorage")
    local v168 = v167:WaitForChild("PlaceStructure")
    local v169 = v168:WaitForChild("ClientPlacedBlueprint")
    v169:FireServer(upvalue_0, upvalue_1.Main.CFrame, _G.自己)
    pcall(function()
    upvalue_0:Destroy()
    upvalue_1.Function.Disconnect(upvalue_1.Function)
    upvalue_1 = nil
    upvalue_2.Function.Disconnect(upvalue_2.Function)
    upvalue_2 = nil
    upvalue_3.Function.Disconnect(upvalue_3.Function)
    upvalue_3 = nil
    upvalue_4.Function.Disconnect(upvalue_4.Function)
    upvalue_4 = nil
    return
end)
    return
end)
    v165.Function = v167
    local v168 = {}
    local v169 = game:GetService("RunService")
    local v170 = v169.RenderStepped:Connect(function()
    return
    local v170 = CFrame.new(_G.鼠标.Hit.Position.X, _G.鼠标.Hit.Position.Y, _G.鼠标.Hit.Position.Z)
    local v171 = math.rad(upvalue_2)
    local v172, v173, v174 = math.rad(upvalue_3)
    local v175 = CFrame.Angles(v172)
    upvalue_0:PivotTo(v170 * v175)
    return
end)
    v168.Function = v170
    return
end)
local v154 = v141:Section("wire art")
v154:TextBox("Url", "", function(p0)
    local v155, v156, v157 = game:HttpGet(p0)
    local v158 = loadstring(v155)
    local v159 = v158(v155)
    upvalue_0 = v159
    return
end)
local v155 = {}
v155 = {"NeonWirePinky", "NeonWireOrange", "NeonWireRed", "NeonWireViolet", "NeonWireWhite", "NeonWireYellow", "NeonWireBlue", "NeonWireCyan", "NeonWireGreen", "IcicleWireBlue", "IcicleWireAmber", "IcicleWireRed", "IcicleWireGreen", "IcicleWireMagenta", "IcicleWireHalloween", "Wire"}
v154:DropDown("Select Wire", v155, false, false, function(p0)
    upvalue_0 = p0
    return
end)
_G.电线地点 = function(p0)
    _G.电线 = p0
    _G.距离 = 0
    local v156 = {}
    _G.返回电线 = v156
    local v157 = {}
    _G.全部电线 = v157
    table.insert(_G.全部电线, v24)
    local v158 = game:GetService("ReplicatedStorage")
    local v159 = v158.ClientItemInfo:FindFirstChild(upvalue_0)
    table.insert(_G.返回电线, _G.全部电线)
    local v160 = {}
    _G.全部电线 = v160
    _G.距离 = 0
    table.insert(_G.全部电线, v24)
    _G.距离 = v24 - v24.magnitude
    table.insert(_G.全部电线, v24)
    _G.距离 = _G.距离 + v24 - v24.magnitude
    table.insert(_G.全部电线, v24)
    v162, v163 = next(_G.电线, v161)
    if v162 ~= nil then v161 = v162 end
    table.insert(_G.返回电线, _G.全部电线)
    return _G.返回电线
end
drawLine = function(p0, p1, p2)
    local v156 = Instance.new("Part")
    v156.Anchored = true
    local v157 = CFrame.new(p0, p1)
    local v158 = CFrame.Angles(-math.pi / 2, 0, 0)
    local v159 = CFrame.new(0, p0 - p1.magnitude / 2, 0)
    v156.CFrame = v157 * v158 * v159
    local v160 = math.max(p2, 0,2)
    local v161, v162, v163 = math.max(p2, 0,2)
    local v164 = Vector3.new(v161)
    v156.Size = v164
    v156.TopSurface = Enum.SurfaceType.Smooth
    v156.BottomSurface = Enum.SurfaceType.Smooth
    local v165 = Instance.new("CylinderMesh", v156)
    local v166 = math.min(p2 / 0,2, 1)
    local v167, v168, v169 = math.min(p2 / 0,2, 1)
    local v170 = Vector3.new(v167)
    v165.Scale = v170
    return v156
end
drawBall = function(p0, p1)
    local v156 = Instance.new("Part")
    v156.Anchored = true
    v156.Shape = Enum.PartType.Ball
    local v157 = Vector3.new(1, 1, 1)
    local v158 = math.max(p1, 0,2)
    v156.Size = v157 * v158
    local v159 = CFrame.new(p0)
    v156.CFrame = v159
    v156.TopSurface = Enum.SurfaceType.Smooth
    v156.BottomSurface = Enum.SurfaceType.Smooth
    local v160 = Instance.new("SpecialMesh", v156)
    v160.MeshType = Enum.MeshType.Sphere
    local v161 = Vector3.new(1, 1, 1)
    local v162 = math.min(p1 / 0,2, 1)
    v160.Scale = v161 * v162
    v156.CanCollide = false
    return v156
end
drawEnd = function(p0, p1, p2)
    local v156 = Instance.new("Part")
    v156.Anchored = true
    v156.Shape = Enum.PartType.Cylinder
    local v157 = Vector3.new(0,4, 1, 1)
    v156.Size = v157 * p1
    local v158 = CFrame.new(p0)
    v156.CFrame = v158 * p2
    v156.TopSurface = Enum.SurfaceType.Smooth
    v156.BottomSurface = Enum.SurfaceType.Smooth
    return v156
end
v154:Button("preview", function()
    return _G.提醒("u need wire art")
    return ...
    upvalue_1 = _G.自己的方块.Position
    local v159 = Instance.new("Model")
    v159.Name = "Dark X Wire art"
    local v160, v161 = _G.电线地点(upvalue_0)
    local v162 = {}
    local v163 = Vector3.new(0, 5, 0)
    table.insert(v162, v28 + upvalue_1 + v163)
    v165, v166 = next(nil, v164)
    if v165 ~= nil then v164 = v165 end
    v159.Parent = game.Workspace
    local v167, v168, v169 = pairs(v162)
    local v170 = game:GetService("ReplicatedStorage")
    local v171 = v170.ClientItemInfo:FindFirstChild("Wire")
    local v172 = drawBall(v166, v171.OtherInfo.Thickness.Value)
    v172.Parent = v159
    v172.Name = "Point" .. v165
    v172.Parent = v159
    local v173 = game:GetService("ReplicatedStorage")
    local v174 = v173.ClientItemInfo:FindFirstChild("Wire")
    local v175 = drawLine(v166, v162[v165 + 1], v174.OtherInfo.Thickness.Value)
    v175.Parent = v159
    v175.Name = "Line" .. v165
    v175.Parent = v159
    v176, v177 = v167(v168, v169)
    if v176 ~= nil then v169 = v176 end
    local v178 = CFrame.Angles(0, 0, -math.pi / 2)
    local v179 = game:GetService("ReplicatedStorage")
    local v180 = v179.ClientItemInfo:FindFirstChild("Wire")
    local v181 = drawEnd(v162[1], v180.OtherInfo.Thickness.Value, v159.Line1.CFrame - v159.Line1.CFrame.p * v178)
    v181.Parent = v159
    local v182 = CFrame.Angles(0, 0, math.pi / 2)
    local v183 = game:GetService("ReplicatedStorage")
    local v184 = v183.ClientItemInfo:FindFirstChild("Wire")
    local v185 = drawEnd(v162[#v162], v184.OtherInfo.Thickness.Value, v159["Line" .. #v162 - 1].CFrame * v182 - v159["Line" .. #v162 - 1].CFrame * v182.p)
    v185.Parent = v159
    v186, v187 = next(v160, v161)
    if v186 ~= nil then v161 = v186 end
    return
end)
v154:Button("destroy preview", function()
    pcall(function()
    game.Workspace["Dark X Wire art"].Destroy(game.Workspace["Dark X Wire art"])
    return
end)
    upvalue_0 = nil
    return
end)
_G.检查电线 = function(p0, p1)
    local v156 = {}
    local v157, v158 = workspace.PlayerModels:GetChildren()
    local v159 = v119:FindFirstChild("Owner")
    local v160 = v119:FindFirstChild("PurchasedBoxItemName")
    local v161 = tostring(v119.PurchasedBoxItemName.Value)
    table.insert(v156, v119)
    v162, v163 = next(v157, v158)
    if v162 ~= nil then v158 = v162 end
    return #v156
    return true
end
v154:Button("put", function()
    pcall(function()
    game.Workspace["Dark X Wire art"].Destroy(game.Workspace["Dark X Wire art"])
    return
end)
    local v156 = _G.电线地点(upvalue_1)
    local v157 = _G.检查电线(upvalue_0, #v156)
    print("buy")
    _G.菜单.自动购买的地点 = _G.自己的方块.CFrame
    local v158 = _G.电线地点(upvalue_1)
    local v159 = _G.电线地点(upvalue_1)
    local v160 = _G.检查电线(upvalue_0, #v159)
    _G.自动购买v2(upvalue_0, #v158 - v160)
    task.wait(upvalue_0)
    _G.传送(_G.菜单.自动购买的地点)
    local v161, v162 = _G.电线地点(upvalue_1)
    local v163 = {}
    local v164 = Vector3.new(0, 5, 0)
    table.insert(v163, function(p0, p1)
    upvalue_0(p0)
    spawn(function()
    local v28 = Vector3.new(0, 0, 0)
    upvalue_0.PrimaryPart.Velocity = v28
    local v29 = Vector3.new(0, 0, 0)
    upvalue_0.PrimaryPart.RotVelocity = v29
    game.ReplicatedStorage.TestPing:InvokeServer()
    task.wait(game.ReplicatedStorage.TestPing)
    1 = 1 + 1
    if 1 <= 10 then
    -- continue loop (PC + -27)
    end
    return
end)
    local v28 = identifyexecutor(function()
    local v28 = Vector3.new(0, 0, 0)
    upvalue_0.PrimaryPart.Velocity = v28
    local v29 = Vector3.new(0, 0, 0)
    upvalue_0.PrimaryPart.RotVelocity = v29
    game.ReplicatedStorage.TestPing:InvokeServer()
    task.wait(game.ReplicatedStorage.TestPing)
    1 = 1 + 1
    if 1 <= 10 then
    -- continue loop (PC + -27)
    end
    return
end)
    print(p0.PrimaryPart)
    game.ReplicatedStorage.Interaction.ClientIsDragging:FireServer(p0)
    task.wait(0,2)
    local v29 = isnetworkowner(p0.PrimaryPart)
    game.ReplicatedStorage.Interaction.ClientIsDragging:FireServer(p0)
    local v30 = p0:FindFirstChild("WoodSection")
    p0.PrimaryPart.CFrame = p1
    p0:PivotTo(p1)
    return
    local v31 = tostring(p0.Parent)
    game.ReplicatedStorage.Interaction.ClientIsDragging:FireServer(p0)
    upvalue_0(p0)
    p0.PrimaryPart.CFrame = p1
    game.ReplicatedStorage.TestPing:InvokeServer()
    task.wait(game.ReplicatedStorage.TestPing)
    1 = 1 + 1
    if 1 <= 6 then
    -- continue loop (PC + -21)
    end
    return
    game.ReplicatedStorage.Interaction.ClientIsDragging:FireServer(p0)
    local v32 = p0:FindFirstChild("WoodSection")
    upvalue_0(p0)
    p0.PrimaryPart.CFrame = p1
    p0:PivotTo(p1)
    game.ReplicatedStorage.TestPing:InvokeServer()
    task.wait(game.ReplicatedStorage.TestPing)
    1 = 1 + 1
    if 1 <= 3 then
    -- continue loop (PC + -30)
    end
    return
end + upvalue_2 + v164)
    v166, v167 = next(upvalue_0, v165)
    if v166 ~= nil then v165 = v166 end
    local v168, v169 = workspace.PlayerModels:GetChildren()
    local v170 = table.insert:FindFirstChild("Owner")
    local v171 = table.insert:FindFirstChild("PurchasedBoxItemName")
    local v172 = tostring(table.insert.PurchasedBoxItemName.Value)
    v173, v174 = next(v168, v169)
    if v173 ~= nil then v169 = v173 end
    local v175 = {}
    local v176 = game:GetService("ReplicatedStorage")
    local v177 = v176:WaitForChild("ClientItemInfo")
    v175[1] = v177[upvalue_0]
    v175[2] = v163
    v175[3] = _G.自己
    v175[4] = table.insert
    v175[5] = true
    local v178 = game:GetService("ReplicatedStorage")
    local v179 = v178:WaitForChild("PlaceStructure")
    local v180 = v179:WaitForChild("ClientPlacedWire")
    local v181, v182, v183 = unpack(v175)
    v180:FireServer(v181)
    task.wait(2)
    v184, v185 = next(v161, v162)
    if v184 ~= nil then v162 = v184 end
    upvalue_2 = nil
    return
end)
_G.获得车子 = function()
    local v156 = {}
    local v157 = {}
    local v158, v159 = game.Workspace.PlayerModels:GetChildren()
    local v160 = v154:FindFirstChild("Owner")
    local v161 = v154:FindFirstChild("Seat")
    table.insert(v156, v154)
    v162, v163 = next(v158, v159)
    if v162 ~= nil then v159 = v162 end
    local v164, v165 = game.Workspace.PlayerModels:GetChildren()
    local v166 = v163:FindFirstChild("Owner")
    local v167 = v163:FindFirstChild("ButtonRemote_SpawnButton")
    local v168 = v163:FindFirstChild("SpawnButton")
    table.insert(v157, v163)
    v169, v170 = next(v164, v165)
    if v169 ~= nil then v165 = v169 end
    return v156, true
    return nil
    return v157, false
end
_G.搞玩家 = function()
    return _G.提醒("You Need An Axe To Use This Feature.")
    return ...
    local v159 = _G.获得车子(v157)
    return _G.提醒("You Need A Vehicle To Use This Feature.")
    return ...
    local v163, v164, v165 = tostring(_G.菜单.杀死的玩家)
    local v166 = _G.玩家.FindFirstChild(v163)
    return _G.提醒("Selected Player Has Left The Game!")
    return ...
    local v170 = tostring(_G.菜单.杀死的玩家)
    local v171 = tostring(_G.自己)
    return _G.提醒("You Cannot Perform This Action On Yourself!")
    return ...
    return _G.提醒("pls sit in a car")
    return ...
    return _G.提醒("Selected Player Is Seated!")
    return ...
    local v181 = tostring(_G.自己身体.SeatPart)
    return _G.提醒("You Need To Be In The Driver's Seat")
    return ...
    car = _G.自己身体.SeatPart.Parent
    local v185 = game:GetService("ReplicatedStorage")
    v185.Interaction.UpdateUserSettings:FireServer("UserPermission", _G.玩家[_G.菜单.杀死的玩家].UserId, "Sit", true)
    local v186 = math.rad(-180)
    local v187 = CFrame.Angles(v186, 0, 0)
    local v188 = Vector3.new(0, 2, 0)
    _G.传送(_G.玩家[_G.菜单.杀死的玩家].Character.PrimaryPart.CFrame * v187 + v188)
    task.wait(1)
    local v189, v190, v191 = CFrame.new(-1675, 500, 1282)
    _G.传送(v189)
    wait(1)
    game.ReplicatedStorage.Interaction.DestroyStructure:FireServer(car)
    wait(0,3)
    local v192, v193, v194 = CFrame.new(0, -50, 0)
    _G.传送(v192)
    wait(1)
    game.ReplicatedStorage.Interaction.DestroyStructure:FireServer(car)
    wait(0,3)
    _G.传送(_G.自己的方块.CFrame)
    return
end
_G.斧头飞行 = function(p0)
    _G.菜单.斧头掉落:Disconnect()
    _G.菜单.斧头飞行:Disconnect()
    return
    local v156 = game.Workspace.PlayerModels.ChildAdded:Connect(function(p0)
    local v156 = p0:WaitForChild("Owner")
    local v157 = p0:WaitForChild("Main")
    local v158 = p0:WaitForChild("ToolName")
    local v159 = Instance.new("BodyAngularVelocity", p0.Main)
    local v160 = Instance.new("BodyPosition", p0.Main)
    local v161 = Vector3.new(math.huge, math.huge, math.huge)
    v160.MaxForce = v161
    v160.Position = _G.鼠标.Hit.p
    v160.P = 1000000
    v159.P = 9000000000
    local v162 = Vector3.new(0, 9999999, 0)
    v159.MaxTorque = v162
    local v163 = Vector3.new(0, 9999999, 0)
    v159.AngularVelocity = v163
    v159.P = 9999999
    local v164 = p0:FindFirstChild("Main")
    game.ReplicatedStorage.Interaction.ClientIsDragging:FireServer(p0)
    local v165 = CFrame.new(_G.鼠标.Hit.p)
    local v166 = math.rad(20 * 0)
    local v167 = CFrame.Angles(v166, 0, 0)
    p0.Main.CFrame = v165 * v167
    task.wait(0,5)
    local v168 = p0:WaitForChild("Main")
    local v169 = game:GetService("ReplicatedStorage")
    v169.Interaction.ClientInteracted:FireServer(p0, "Pick up tool")
    _G.自己角色:WaitForChild("Tool")
    _G.自己身体:UnequipTools()
    return
end)
    _G.菜单.斧头掉落 = v156
    local v157 = _G.鼠标.Button1Up:Connect(function()
    local v157 = game:GetService("ReplicatedStorage")
    local v158 = _G.自己.Backpack:FindFirstChild("Tool")
    local v159 = _G.自己角色:FindFirstChild("Tool")
    local v160 = Vector3.new(5, 0, 0)
    v157.Interaction.ClientInteracted.FireServer(v157.Interaction.ClientInteracted, v159, "Drop tool", _G.自己.Character["Right Arm"].CFrame - v160)
    return
end)
    _G.菜单.斧头飞行 = v157
    return
end
local v156 = v24:CreateTab("Troll", "8769279408")
local v157 = v156:Section("Player")
local v158 = {}
v157:DropDown("Select the player", v158, true, false, function(p0)
    _G.菜单.杀死的玩家 = p0
    return
end)
local v159 = {}
v159 = {"Kill", "Hard Kill", "Bring"}
v157:DropDown("Method", v159, false, false, function(p0)
    _G.菜单.杀死的方法 = p0
    return
end)
local v160 = {}
v160 = {"Vehicle"}
v157:DropDown("select tool", v160, false, false, function(p0)
    _G.菜单.杀死的工具 = p0
    return
end)
v157:Button("Kill!", function()
    _G.搞玩家(v13)
    return
end)
v157:Toggle("Delete all Shop items", false, function(p0)
    _G.菜单.删除商店物品 = p0
    return
end)
v157:Toggle("Tomahawk Axe Fling", false, function(p0)
    _G.斧头飞行(p0)
    return
end)
local v161 = v24:CreateTab("Settings", "6031280882")
local v162 = v161:Section("Credits")
v162:Label("UI Made by silent ben8x")
v162:Label("Devs : silent ben8x and Thchjh")
local v163, v164 = game.CoreGui.Aurora.Main.Side.TabHolder:GetChildren()
local v165 = function(p0)
    _G.斧头飞行(p0)
    return
end:FindFirstChild("Title")
SwitchTab(function(p0)
    _G.斧头飞行(p0)
    return
end, game.CoreGui.Aurora.Main.Holder_Player)
v166, v167 = next(v163, v164)
if v166 ~= nil then v164 = v166 end
game.CoreGui.Aurora.Main.Holder_Key:Destroy()
local v168, v169 = game.CoreGui.Aurora.Main.Side.TabHolder:GetChildren()
local v170 = v167:FindFirstChild("Title")
v167:Destroy()
v171, v172 = next(v168, v169)
if v171 ~= nil then v169 = v171 end
v162:KeyBind("Toggle UI", "RightShift", function(p0)
    upvalue_0:ToggleUI()
    return
end)
_G.提醒("Dark X load success")
wait(2)
_G.提醒("our discord: https://discord.gg/6aP9akd5rX")
local v173 = hookmetamethod(game, "__namecall", function(p0, ...)
    local v173 = {}
    local v174 = getnamecallmethod(v20)
    return
    return upvalue_0(v174)
    return ...
end)
local v174 = hookmetamethod(game, "__namecall", function(...)
    local v174 = {}
    local v175 = getnamecallmethod(v18)
    local v176 = Vector3.new(0, 0, 0)
    local v177, v178, v179 = Vector3.new(0, 0, 0)
    local v180, v181, v182 = Ray.new(v177)
    rawset(v180)
    setnamecallmethod(v175)
    local v183, v184, v185 = unpack(v174)
    return upvalue_0(v183)
    return ...
end)
return
