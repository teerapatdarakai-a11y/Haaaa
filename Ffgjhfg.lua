-- ========================================================
-- 🚀 UTILITY HUB - FULLY FUNCTIONAL VERSION
-- ========================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = workspace
local Camera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- ตรวจสอบ Drawing Library
local hasDrawing, Drawing = pcall(function() return Drawing end)
if not hasDrawing then
    warn("⚠️ Drawing library ไม่พร้อมใช้งาน — ฟีเจอร์ ESP และ FOV อาจไม่แสดงผลในบาง Executor")
end

local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local Settings = {
    UI = {
        Open = true,
        Position = UDim2.new(0.02, 0, 0.3, 0)
    },
    Movement = {
        Speed = { Enabled = false, Value = 32 },
        Fly = { Enabled = false, Speed = 50 },
        NoClip = { Enabled = false }
    },
    Combat = {
        Aimbot = { Enabled = false, Smoothness = 0.25, AimPart = "Head" },
        FOV = { Enabled = true, Radius = 150, Color = Color3.fromRGB(255, 255, 255) }
    },
    Visuals = {
        ESP = { Enabled = false },
        ShowNames = true,
        ShowDistance = true
    },
    Keybinds = {
        ToggleUI = Enum.KeyCode.RightShift
    }
}

local State = {
    Connections = {},
    UIElements = {},
    ESPObjects = {},
    OriginalWalkSpeed = 16,
    OriginalCollisions = {}
}

-- สร้าง FOV Circle
local FOVCircle = nil
if hasDrawing then
    FOVCircle = Drawing.new("Circle")
    FOVCircle.Visible = false
    FOVCircle.Transparency = 0.7
    FOVCircle.Thickness = 1
    FOVCircle.Filled = false
    FOVCircle.Radius = Settings.Combat.FOV.Radius
    FOVCircle.Color = Settings.Combat.FOV.Color
end

local UI = {}

function UI:CreateWindow()
    if PlayerGui:FindFirstChild("UtilityHub") then
        PlayerGui.UtilityHub:Destroy()
    end

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "UtilityHub"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.Parent = PlayerGui

    -- ปุ่มลอย ⚡
    local FloatBtn = Instance.new("TextButton")
    FloatBtn.Name = "FloatingButton"
    FloatBtn.Size = UDim2.new(0, 50, 0, 50)
    FloatBtn.Position = UDim2.new(0.02, 0, 0.15, 0)
    FloatBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
    FloatBtn.Text = "⚡"
    FloatBtn.TextColor3 = Color3.fromRGB(255, 220, 50)
    FloatBtn.TextSize = 22
    FloatBtn.Font = Enum.Font.GothamBold
    FloatBtn.Draggable = true
    FloatBtn.AutoLocalize = false
    FloatBtn.Parent = ScreenGui

    Instance.new("UICorner", FloatBtn).CornerRadius = UDim.new(0, 12)

    -- หน้าต่างหลัก
    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = UDim2.new(0, 300, 0, 420)
    MainFrame.Position = Settings.UI.Position
    MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    MainFrame.BorderSizePixel = 0
    MainFrame.Active = true
    MainFrame.Draggable = true
    MainFrame.Visible = Settings.UI.Open
    MainFrame.Parent = ScreenGui

    Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 8)

    -- แถบหัวเรื่อง
    local TitleBar = Instance.new("Frame")
    TitleBar.Size = UDim2.new(1, 0, 0, 40)
    TitleBar.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
    TitleBar.Parent = MainFrame
    Instance.new("UICorner", TitleBar).CornerRadius = UDim.new(0, 8)

    local TitleText = Instance.new("TextLabel")
    TitleText.Size = UDim2.new(1, -50, 1, 0)
    TitleText.Position = UDim2.new(0, 12, 0, 0)
    TitleText.BackgroundTransparency = 1
    TitleText.Text = "🔥 Utility Hub (Fixed)"
    TitleText.TextColor3 = Color3.new(1, 1, 1)
    TitleText.Font = Enum.Font.GothamBold
    TitleText.TextSize = 14
    TitleText.TextXAlignment = Enum.TextXAlignment.Left
    TitleText.Parent = TitleBar

    -- ปุ่มปิด ✕
    local CloseBtn = Instance.new("TextButton")
    CloseBtn.Size = UDim2.new(0, 30, 0, 30)
    CloseBtn.Position = UDim2.new(1, -35, 0.5, -15)
    CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
    CloseBtn.Text = "✕"
    CloseBtn.TextColor3 = Color3.new(1, 1, 1)
    CloseBtn.TextSize = 14
    CloseBtn.Font = Enum.Font.GothamBold
    CloseBtn.AutoLocalize = false
    CloseBtn.Parent = TitleBar
    Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 6)

    CloseBtn.MouseButton1Click:Connect(function()
        Settings.UI.Open = false
        MainFrame.Visible = false
    end)

    -- พื้นที่เนื้อหา
    local Content = Instance.new("ScrollingFrame")
    Content.Name = "Content"
    Content.Size = UDim2.new(1, -16, 1, -55)
    Content.Position = UDim2.new(0, 8, 0, 48)
    Content.BackgroundTransparency = 1
    Content.ScrollBarThickness = 4
    Content.ScrollBarColor3 = Color3.fromRGB(80, 80, 90)
    Content.CanvasSize = UDim2.new(0, 0, 0, 460)
    Content.AutomaticCanvasSize = Enum.AutomaticSize.Y
    Content.ScrollingEnabled = true
    Content.Parent = MainFrame

    local Layout = Instance.new("UIListLayout")
    Layout.Padding = UDim.new(0, 8)
    Layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    Layout.VerticalAlignment = Enum.VerticalAlignment.Top
    Layout.Parent = Content

    State.UIElements = {
        ScreenGui = ScreenGui,
        MainFrame = MainFrame,
        Content = Content,
        FloatBtn = FloatBtn
    }

    return Content
end

function UI:AddToggle(parent, name, category, configKey)
    local Container = Instance.new("Frame")
    Container.Size = UDim2.new(1, 0, 0, 38)
    Container.BackgroundColor3 = Color3.fromRGB(42, 42, 50)
    Container.Parent = parent
    Instance.new("UICorner", Container).CornerRadius = UDim.new(0, 6)

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, -55, 1, 0)
    Label.Position = UDim2.new(0, 12, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Text = name
    Label.TextColor3 = Color3.new(0.9, 0.9, 0.9)
    Label.Font = Enum.Font.Gotham
    Label.TextSize = 13
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Container

    local ToggleBtn = Instance.new("TextButton")
    ToggleBtn.Size = UDim2.new(0, 44, 0, 24)
    ToggleBtn.Position = UDim2.new(1, -52, 0.5, -12)
    ToggleBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 90)
    ToggleBtn.AutoLocalize = false
    ToggleBtn.Text = ""
    ToggleBtn.Parent = Container
    Instance.new("UICorner", ToggleBtn).CornerRadius = UDim.new(0, 4)

    local Indicator = Instance.new("Frame")
    Indicator.Size = UDim2.new(0, 18, 0, 18)
    Indicator.Position = UDim2.new(0, 3, 0.5, -9)
    Indicator.BackgroundColor3 = Color3.fromRGB(140, 140, 150)
    Indicator.Parent = ToggleBtn
    Instance.new("UICorner", Indicator).CornerRadius = UDim.new(0, 3)

    local function GetState()
        if category == "Movement" then return Settings.Movement[configKey].Enabled end
        if category == "Combat" then return Settings.Combat[configKey].Enabled end
        if category == "Visuals" then return Settings.Visuals[configKey].Enabled end
        return false
    end

    local function UpdateUI()
        local isOn = GetState()
        ToggleBtn.BackgroundColor3 = isOn and Color3.fromRGB(60, 130, 220) or Color3.fromRGB(80, 80, 90)
        Indicator.Position = isOn and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9)
        Indicator.BackgroundColor3 = isOn and Color3.new(1, 1, 1) or Color3.fromRGB(140, 140, 150)
    end

    ToggleBtn.MouseButton1Click:Connect(function()
        if category == "Movement" then
            Settings.Movement[configKey].Enabled = not Settings.Movement[configKey].Enabled
            if configKey == "Speed" then
                local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
                if hum and not Settings.Movement.Speed.Enabled then
                    hum.WalkSpeed = State.OriginalWalkSpeed
                end
            elseif configKey == "NoClip" and not Settings.Movement.NoClip.Enabled then
                local char = LocalPlayer.Character
                if char then
                    for _, part in ipairs(char:GetChildren()) do
                        if part:IsA("BasePart") and State.OriginalCollisions[part] ~= nil then
                            part.CanCollide = State.OriginalCollisions[part]
                        end
                    end
                end
                State.OriginalCollisions = {}
            end
        elseif category == "Combat" then
            Settings.Combat[configKey].Enabled = not Settings.Combat[configKey].Enabled
        elseif category == "Visuals" then
            Settings.Visuals[configKey].Enabled = not Settings.Visuals[configKey].Enabled
            if configKey == "ESP" and not Settings.Visuals.ESP.Enabled then
                for _, esp in pairs(State.ESPObjects) do
                    if esp then esp.Visible = false end
                end
            end
        end
        UpdateUI()
    end)

    UpdateUI()
end

local function GetCharacter() return LocalPlayer.Character end
local function GetRoot() local c = GetCharacter() return c and c:FindFirstChild("HumanoidRootPart") end
local function GetHumanoid() local c = GetCharacter() return c and c:FindFirstChild("Humanoid") end

-- ระบบบิน (Fly) ที่ใช้งานได้จริง
local flyConnection, flyObjects = nil, {}
local function ToggleFly(enabled)
    local root = GetRoot()
    if not root then return end

    for _, obj in pairs(flyObjects) do if obj then obj:Destroy() end end
    table.clear(flyObjects)
    if flyConnection then flyConnection:Disconnect() flyConnection = nil end

    if enabled then
        local bv = Instance.new("BodyVelocity")
        bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        bv.Velocity = Vector3.new()
        bv.Parent = root
        table.insert(flyObjects, bv)

        local bg = Instance.new("BodyGyro")
        bg.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
        bg.CFrame = Camera.CFrame
        bg.Parent = root
        table.insert(flyObjects, bg)

        flyConnection = RunService.RenderStepped:Connect(function()
            if not Settings.Movement.Fly.Enabled then
                if flyConnection then flyConnection:Disconnect() end
                for _, obj in pairs(flyObjects) do if obj then obj:Destroy() end end
                table.clear(flyObjects)
                return
            end

            bg.CFrame = Camera.CFrame
            local moveDir = Vector3.new()
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir += Camera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir -= Camera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir -= Camera.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir += Camera.CFrame.RightVector end
            if moveDir.Magnitude > 0 then moveDir = moveDir.Unit end
            bv.Velocity = moveDir * Settings.Movement.Fly.Speed
        end)
    end
end

-- ระบบหาเป้าหมาย Aimbot
local function GetClosestTarget()
    if not Settings.Combat.Aimbot.Enabled then return nil end
    local closest, minDist = nil, Settings.Combat.FOV.Radius
    local screenCenter = Camera.ViewportSize / 2

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local hum = player.Character:FindFirstChild("Humanoid")
            local part = player.Character:FindFirstChild(Settings.Combat.Aimbot.AimPart)
            if hum and hum.Health > 0 and part then
                local sp, onScreen = Camera:WorldToViewportPoint(part.Position)
                if onScreen then
                    local dist = (Vector2.new(sp.X, sp.Y) - screenCenter).Magnitude
                    if dist < minDist then
                        minDist = dist
                        closest = part
                    end
                end
            end
        end
    end
    return closest
end

-- อัปเดตวง FOV
local function UpdateFOV()
    if not FOVCircle then return end
    FOVCircle.Visible = Settings.Combat.FOV.Enabled and Settings.Combat.Aimbot.Enabled
    if FOVCircle.Visible then
        FOVCircle.Position = Camera.ViewportSize / 2
        FOVCircle.Radius = Settings.Combat.FOV.Radius
    end
end

-- อัปเดต ESP มองทะลุ
local function UpdateESP()
    if not hasDrawing or not Settings.Visuals.ESP.Enabled then
        for _, txt in pairs(State.ESPObjects) do if txt then txt.Visible = false end end
        return
    end

    local idx = 1
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local root = player.Character:FindFirstChild("HumanoidRootPart")
            local hum = player.Character:FindFirstChild("Humanoid")
            if root and hum and hum.Health > 0 then
                local sp, onScreen = Camera:WorldToViewportPoint(root.Position)
                if onScreen then
                    local dist = math.floor((Camera.CFrame.Position - root.Position).Magnitude)
                    local txt = State.ESPObjects[idx]
                    if not txt then
                        txt = Drawing.new("Text")
                        txt.Center = true
                        txt.Outline = true
                        txt.Font = 2
                        txt.Size = 13
                        txt.Color = Color3.new(1, 1, 1)
                        State.ESPObjects[idx] = txt
                    end
                    txt.Visible = true
                    txt.Position = Vector2.new(sp.X, sp.Y)
                    txt.Text = string.format("%s\n%d m", player.Name, dist)
                    idx += 1
                end
            end
        end
    end
    for i = idx, #State.ESPObjects do
        if State.ESPObjects[i] then State.ESPObjects[i].Visible = false end
    end
end

-- ลูปหลักการทำงาน (Heartbeat)
RunService.Heartbeat:Connect(function(dt)
    local hum = GetHumanoid()
    local char = GetCharacter()
    if not hum or not char then return end

    if State.OriginalWalkSpeed == 16 then
        State.OriginalWalkSpeed = hum.WalkSpeed
    end

    -- ปรับความเร็ว
    hum.WalkSpeed = Settings.Movement.Speed.Enabled and Settings.Movement.Speed.Value or State.OriginalWalkSpeed

    -- ระบบ NoClip (ทะลุผนัง)
    if Settings.Movement.NoClip.Enabled then
        for _, part in ipairs(char:GetChildren()) do
            if part:IsA("BasePart") then
                if State.OriginalCollisions[part] == nil then
                    State.OriginalCollisions[part] = part.CanCollide
                end
                part.CanCollide = false
            end
        end
    else
        for part, orig in pairs(State.OriginalCollisions) do
            if part then part.CanCollide = orig end
        end
        table.clear(State.OriginalCollisions)
    end

    -- ระบบ Aimbot ทำงานจริง
    local target = GetClosestTarget()
    if target then
        local aimPos = target.Position
        local camPos = Camera.CFrame.Position
        local desired = CFrame.new(camPos, aimPos)
        local smooth = math.clamp(Settings.Combat.Aimbot.Smoothness * dt * 60, 0.01, 1)
        Camera.CFrame = Camera.CFrame:Lerp(desired, smooth)
    end
end)

RunService.RenderStepped:Connect(function()
    UpdateESP()
    UpdateFOV()
end)

-- จัดการสถานะการบิน
local lastFly = false
RunService.RenderStepped:Connect(function()
    if lastFly ~= Settings.Movement.Fly.Enabled then
        lastFly = Settings.Movement.Fly.Enabled
        ToggleFly(lastFly)
    end
end)

-- เปิด/ปิด UI
local function ToggleUI()
    Settings.UI.Open = not Settings.UI.Open
    if State.UIElements.MainFrame then
        State.UIElements.MainFrame.Visible = Settings.UI.Open
    end
end

-- เริ่มต้นสร้าง UI
task.spawn(function()
    local Content = UI:CreateWindow()

    if State.UIElements.FloatBtn then
        State.UIElements.FloatBtn.MouseButton1Click:Connect(ToggleUI)
    end

    -- หมวด: Combat
    local HeaderCombat = Instance.new("TextLabel")
    HeaderCombat.Size = UDim2.new(1, 0, 0, 26)
    HeaderCombat.BackgroundTransparency = 1
    HeaderCombat.Text = "🎯 ระบบต่อสู้"
    HeaderCombat.TextColor3 = Color3.fromRGB(255, 160, 160)
    HeaderCombat.Font = Enum.Font.GothamBold
    HeaderCombat.TextSize = 12
    HeaderCombat.TextXAlignment = Enum.TextXAlignment.Left
    HeaderCombat.Parent = Content

    UI:AddToggle(Content, "ล็อกเป้าหมาย (Aimbot)", "Combat", "Aimbot")
    UI:AddToggle(Content, "แสดงวง FOV", "Combat", "FOV")

    -- หมวด: Movement
    local HeaderMove = Instance.new("TextLabel")
    HeaderMove.Size = UDim2.new(1, 0, 0, 26)
    HeaderMove.BackgroundTransparency = 1
    HeaderMove.Text = "🏃 การเคลื่อนที่"
    HeaderMove.TextColor3 = Color3.fromRGB(160, 180, 255)
    HeaderMove.Font = Enum.Font.GothamBold
    HeaderMove.TextSize = 12
    HeaderMove.TextXAlignment = Enum.TextXAlignment.Left
    HeaderMove.Parent = Content

    UI:AddToggle(Content, "ความเร็วสูง (Speed)", "Movement", "Speed")
    UI:AddToggle(Content, "โหมดบิน (Fly)", "Movement", "Fly")
    UI:AddToggle(Content, "ทะลุผนัง (NoClip)", "Movement", "NoClip")

    -- หมวด: Visuals
    local HeaderVis = Instance.new("TextLabel")
    HeaderVis.Size = UDim2.new(1, 0, 0, 26)
    HeaderVis.BackgroundTransparency = 1
    HeaderVis.Text = "👁️ การมองเห็น"
    HeaderVis.TextColor3 = Color3.fromRGB(160, 180, 255)
    HeaderVis.Font = Enum.Font.GothamBold
    HeaderVis.TextSize = 12
    HeaderVis.TextXAlignment = Enum.TextXAlignment.Left
    HeaderVis.Parent = Content

    UI:AddToggle(Content, "มองทะลุ (ESP)", "Visuals", "ESP")

    -- คำแนะนำ
    local Help = Instance.new("TextLabel")
    Help.Size = UDim2.new(1, 0, 0, 40)
    Help.BackgroundTransparency = 1
    Help.Text = "กด ⚡ หรือ ⇧ Shift ขวา เพื่อเปิด/ปิดเมนู\nกด ✕ เพื่อปิดหน้าต่าง"
    Help.TextColor3 = Color3.fromRGB(130, 130, 140)
    Help.Font = Enum.Font.Gotham
    Help.TextSize = 10
    Help.TextWrapped = true
    Help.Parent = Content

    print("✅ โหลดสำเร็จ! กดปุ่ม ⚡ เพื่อเปิดเมนู")
end)

-- ปุ่มลัดเปิด/ปิด UI
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Settings.Keybinds.ToggleUI then
        ToggleUI()
    end
end)
