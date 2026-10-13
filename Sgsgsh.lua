-- ========================================================
-- 🚀 UTILITY HUB - FLY SPEED START AT 4 VERSION
-- ========================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = workspace
local Camera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local hasDrawing, Drawing = pcall(function() return Drawing end)
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local Settings = {
    UI = {
        Open = true,
        Position = UDim2.new(0.5, -170, 0.5, -220)
    },
    Movement = {
        Speed = { Enabled = false, Value = 16, Min = 1, Max = 200 },
        FlySpeed = { Value = 4, Min = 4, Max = 200 }, -- ✅ เริ่มที่ 4, ปรับได้ตั้งแต่ 4-200
        Fly = { Enabled = false, VerticalSensitivity = 0.8 },
        NoClip = { Enabled = false }
    },
    Combat = {
        Aimbot = { Enabled = false, Smoothness = 0.25, AimPart = "Head" },
        FOV = { Enabled = true, Radius = 150, Min = 20, Max = 400, Color = Color3.fromRGB(255, 255, 255) }
    },
    Visuals = {
        ESP = { Enabled = false }
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
    OriginalCollisions = {},
    CharacterAdded = false
}

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

-- สร้างแถบเลื่อน
function UI:CreateSlider(parent, name, getValue, setValue, minVal, maxVal, defaultVal)
    local Container = Instance.new("Frame")
    Container.Size = UDim2.new(1, 0, 0, 44)
    Container.BackgroundColor3 = Color3.fromRGB(42, 42, 50)
    Container.Parent = parent
    Instance.new("UICorner", Container).CornerRadius = UDim.new(0, 6)

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, -10, 0, 16)
    Label.Position = UDim2.new(0, 8, 0, 2)
    Label.BackgroundTransparency = 1
    Label.Text = name .. ": " .. defaultVal
    Label.TextColor3 = Color3.new(0.92, 0.92, 0.92)
    Label.Font = Enum.Font.GothamMedium
    Label.TextSize = 11
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Container

    local BarBg = Instance.new("Frame")
    BarBg.Size = UDim2.new(1, -16, 0, 10)
    BarBg.Position = UDim2.new(0, 8, 0, 26)
    BarBg.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
    BarBg.Parent = Container
    Instance.new("UICorner", BarBg).CornerRadius = UDim.new(0, 4)

    local BarFill = Instance.new("Frame")
    BarFill.Size = UDim2.new((defaultVal - minVal) / (maxVal - minVal), 0, 1, 0)
    BarFill.Position = UDim2.new(0, 0, 0, 0)
    BarFill.BackgroundColor3 = Color3.fromRGB(60, 150, 240)
    BarFill.Parent = BarBg
    Instance.new("UICorner", BarFill).CornerRadius = UDim.new(0, 4)

    local function UpdateValue(newVal)
        newVal = math.clamp(newVal, minVal, maxVal)
        setValue(newVal)
        Label.Text = name .. ": " .. math.floor(newVal)
        BarFill.Size = UDim2.new((newVal - minVal) / (maxVal - minVal), 0, 1, 0)
        if FOVCircle and name == "ขนาด FOV" then FOVCircle.Radius = newVal end
    end

    local dragging = false
    BarBg.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true end end)
    BarBg.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local pos = BarBg.AbsolutePosition
            local size = BarBg.AbsoluteSize
            local percent = math.clamp((input.Position.X - pos.X) / size.X, 0, 1)
            UpdateValue(minVal + percent * (maxVal - minVal))
        end
    end)

    return Container
end

-- สร้างปุ่มเปิดปิด
function UI:AddToggle(parent, name, category, configKey)
    local Container = Instance.new("Frame")
    Container.Size = UDim2.new(1, 0, 0, 32)
    Container.BackgroundColor3 = Color3.fromRGB(42, 42, 50)
    Container.Parent = parent
    Instance.new("UICorner", Container).CornerRadius = UDim.new(0, 6)

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, -55, 1, 0)
    Label.Position = UDim2.new(0, 12, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Text = name
    Label.TextColor3 = Color3.new(0.92, 0.92, 0.92)
    Label.Font = Enum.Font.GothamMedium
    Label.TextSize = 12
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Container

    local ToggleBtn = Instance.new("TextButton")
    ToggleBtn.Size = UDim2.new(0, 40, 0, 20)
    ToggleBtn.Position = UDim2.new(1, -46, 0.5, -10)
    ToggleBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 90)
    ToggleBtn.AutoLocalize = false
    ToggleBtn.Text = ""
    ToggleBtn.Parent = Container
    Instance.new("UICorner", ToggleBtn).CornerRadius = UDim.new(0, 4)

    local Indicator = Instance.new("Frame")
    Indicator.Size = UDim2.new(0, 14, 0, 14)
    Indicator.Position = UDim2.new(0, 3, 0.5, -7)
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
        ToggleBtn.BackgroundColor3 = isOn and Color3.fromRGB(60, 150, 240) or Color3.fromRGB(80, 80, 90)
        Indicator.Position = isOn and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)
        Indicator.BackgroundColor3 = isOn and Color3.new(1, 1, 1) or Color3.fromRGB(140, 140, 150)
    end

    ToggleBtn.MouseButton1Click:Connect(function()
        if category == "Movement" then
            Settings.Movement[configKey].Enabled = not Settings.Movement[configKey].Enabled
            if configKey == "Speed" then
                local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
                if hum then
                    if Settings.Movement.Speed.Enabled then
                        hum.WalkSpeed = Settings.Movement.Speed.Value
                    else
                        hum.WalkSpeed = State.OriginalWalkSpeed
                    end
                end
            elseif configKey == "Fly" then
                ToggleFly(Settings.Movement.Fly.Enabled)
            end
        elseif category == "Combat" then
            Settings.Combat[configKey].Enabled = not Settings.Combat[configKey].Enabled
        elseif category == "Visuals" then
            Settings.Visuals[configKey].Enabled = not Settings.Visuals[configKey].Enabled
            if configKey == "ESP" and not Settings.Visuals.ESP.Enabled then
                for _, objs in pairs(State.ESPObjects) do
                    if objs.Box then objs.Box.Visible = false end
                    if objs.Name then objs.Name.Visible = false end
                end
            end
        end
        UpdateUI()
    end)

    UpdateUI()
end

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
    FloatBtn.Position = UDim2.new(0.02, 0, 0.4, 0)
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
    MainFrame.Size = UDim2.new(0, 340, 0, 520)
    MainFrame.Position = Settings.UI.Position
    MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    MainFrame.BorderSizePixel = 0
    MainFrame.Active = true
    MainFrame.Draggable = true
    MainFrame.Visible = Settings.UI.Open
    MainFrame.Parent = ScreenGui

    Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 10)

    -- แถบหัวเรื่อง
    local TitleBar = Instance.new("Frame")
    TitleBar.Size = UDim2.new(1, 0, 0, 40)
    TitleBar.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
    TitleBar.Parent = MainFrame
    Instance.new("UICorner", TitleBar).CornerRadius = UDim.new(0, 10)

    local TitleText = Instance.new("TextLabel")
    TitleText.Size = UDim2.new(1, -50, 1, 0)
    TitleText.Position = UDim2.new(0, 12, 0, 0)
    TitleText.BackgroundTransparency = 1
    TitleText.Text = "🔥 Utility Hub (Fly Start: 4)"
    TitleText.TextColor3 = Color3.new(1, 1, 1)
    TitleText.Font = Enum.Font.GothamBold
    TitleText.TextSize = 13
    TitleText.TextXAlignment = Enum.TextXAlignment.Left
    TitleText.Parent = TitleBar

    -- ปุ่มปิด ✕
    local CloseBtn = Instance.new("TextButton")
    CloseBtn.Size = UDim2.new(0, 28, 0, 28)
    CloseBtn.Position = UDim2.new(1, -35, 0.5, -14)
    CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
    CloseBtn.Text = "✕"
    CloseBtn.TextColor3 = Color3.new(1, 1, 1)
    CloseBtn.TextSize = 13
    CloseBtn.Font = Enum.Font.GothamBold
    CloseBtn.AutoLocalize = false
    CloseBtn.Parent = TitleBar
    Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 6)

    CloseBtn.MouseButton1Click:Connect(function()
        Settings.UI.Open = false
        MainFrame.Visible = false
    end)

    -- พื้นที่เนื้อหา
    local Content = Instance.new("Frame")
    Content.Name = "Content"
    Content.Size = UDim2.new(1, -16, 1, -48)
    Content.Position = UDim2.new(0, 8, 0, 44)
    Content.BackgroundTransparency = 1
    Content.ClipsDescendants = false
    Content.Parent = MainFrame

    local Layout = Instance.new("UIListLayout")
    Layout.Padding = UDim.new(0, 4)
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

local function GetCharacter() return LocalPlayer.Character end
local function GetRoot() local c = GetCharacter() return c and c:FindFirstChild("HumanoidRootPart") end
local function GetHumanoid() local c = GetCharacter() return c and c:FindFirstChild("Humanoid") end

local flyConnection, flyObjects = nil, {}
function ToggleFly(enabled)
    local root = GetRoot()
    if not root then return end

    for _, obj in pairs(flyObjects) do if obj then obj:Destroy() end end
    table.clear(flyObjects)
    if flyConnection then flyConnection:Disconnect() flyConnection = nil end

    if enabled then
        local bv = Instance.new("BodyVelocity")
        bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        bv.Velocity = Vector3.new()
        bv.P = 1200
        bv.Parent = root
        table.insert(flyObjects, bv)

        local bg = Instance.new("BodyGyro")
        bg.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
        bg.CFrame = Camera.CFrame
        bg.P = 6000
        bg.Parent = root
        table.insert(flyObjects, bg)

        flyConnection = RunService.RenderStepped:Connect(function()
            if not Settings.Movement.Fly.Enabled then
                if flyConnection then flyConnection:Disconnect() end
                for _, obj in pairs(flyObjects) do if obj then obj:Destroy() end end
                table.clear(flyObjects)
                return
            end

            bg.CFrame = CFrame.new(Vector3.new(), Camera.CFrame.LookVector * Vector3.new(1, 0, 1))

            local moveDir = Vector3.new()
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir += Camera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir -= Camera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir -= Camera.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir += Camera.CFrame.RightVector end

            -- หันจอขึ้น=บินขึ้น หันลง=บินลง
            local lookY = Camera.CFrame.LookVector.Y
            moveDir += Vector3.new(0, -lookY * Settings.Movement.Fly.VerticalSensitivity, 0)

            if moveDir.Magnitude > 0 then moveDir = moveDir.Unit end
            bv.Velocity = moveDir * Settings.Movement.FlySpeed.Value
        end)
    end
end

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

local function UpdateFOV()
    if not FOVCircle then return end
    FOVCircle.Visible = Settings.Combat.FOV.Enabled
    if FOVCircle.Visible then
        FOVCircle.Position = Camera.ViewportSize / 2
    end
end

-- ESP กล่องสีเขียว
local function UpdateESP()
    if not hasDrawing or not Settings.Visuals.ESP.Enabled then
        for _, objs in pairs(State.ESPObjects) do
            if objs.Box then objs.Box.Visible = false end
            if objs.Name then objs.Name.Visible = false end
        end
        return
    end

    local idx = 1
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local root = player.Character:FindFirstChild("HumanoidRootPart")
            local hum = player.Character:FindFirstChild("Humanoid")
            local head = player.Character:FindFirstChild("Head")
            if root and hum and hum.Health > 0 and head then
                local rPos, rOnScreen = Camera:WorldToViewportPoint(root.Position)
                local hPos, hOnScreen = Camera:WorldToViewportPoint(head.Position)
                
                if rOnScreen and hOnScreen then
                    local dist = math.floor((Camera.CFrame.Position - root.Position).Magnitude)
                    local height = math.abs(rPos.Y - hPos.Y) * 2.5
                    local width = height * 0.6
                    local centerX = rPos.X
                    local centerY = (rPos.Y + hPos.Y) / 2
                    
                    local objs = State.ESPObjects[idx]
                    if not objs then
                        objs = {
                            Box = Drawing.new("Square"),
                            Name = Drawing.new("Text")
                        }
                        objs.Box.Thickness = 1.5
                        objs.Box.Filled = false
                        objs.Box.Color = Color3.fromRGB(50, 255, 50)
                        objs.Name.Center = true
                        objs.Name.Outline = true
                        objs.Name.Font = 2
                        objs.Name.Size = 12
                        objs.Name.Color = Color3.new(1, 1, 1)
                        State.ESPObjects[idx] = objs
                    end
                    
                    objs.Box.Visible = true
                    objs.Box.Size = Vector2.new(width, height)
                    objs.Box.Position = Vector2.new(centerX - width/2, centerY - height/2)
                    
                    objs.Name.Visible = true
                    objs.Name.Position = Vector2.new(centerX, centerY - height/2 - 15)
                    objs.Name.Text = string.format("%s | %d m", player.Name, dist)
                    
                    idx += 1
                end
            end
        end
    end
    for i = idx, #State.ESPObjects do
        local objs = State.ESPObjects[i]
        if objs then
            if objs.Box then objs.Box.Visible = false end
            if objs.Name then objs.Name.Visible = false end
        end
    end
end

RunService.Heartbeat:Connect(function(dt)
    local hum = GetHumanoid()
    local char = GetCharacter()
    if not hum or not char then return end

    -- บันทึกค่าเริ่มต้น
    if not State.CharacterAdded then
        State.OriginalWalkSpeed = 16
        State.CharacterAdded = true
    end

    -- ความเร็วเดิน
    if Settings.Movement.Speed.Enabled then
        hum.WalkSpeed = Settings.Movement.Speed.Value
    else
        hum.WalkSpeed = State.OriginalWalkSpeed
    end

    -- NoClip
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

    -- Aimbot
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

LocalPlayer.CharacterAdded:Connect(function()
    State.CharacterAdded = false
    State.OriginalCollisions = {}
    if Settings.Movement.Fly.Enabled then
        task.wait(0.15)
        ToggleFly(true)
    end
end)

local lastFly = false
RunService.RenderStepped:Connect(function()
    if lastFly ~= Settings.Movement.Fly.Enabled then
        lastFly = Settings.Movement.Fly.Enabled
        ToggleFly(lastFly)
    end
end)

local function ToggleUI()
    Settings.UI.Open = not Settings.UI.Open
    if State.UIElements.MainFrame then
        State.UIElements.MainFrame.Visible = Settings.UI.Open
    end
end

task.spawn(function()
    local Content = UI:CreateWindow()

    if State.UIElements.FloatBtn then
        State.UIElements.FloatBtn.MouseButton1Click:Connect(ToggleUI)
    end

    -- === ระบบต่อสู้ ===
    local HeaderCombat = Instance.new("TextLabel")
    HeaderCombat.Size = UDim2.new(1, 0, 0, 20)
    HeaderCombat.BackgroundTransparency = 1
    HeaderCombat.Text = "🎯 ระบบต่อสู้"
    HeaderCombat.TextColor3 = Color3.fromRGB(255, 160, 160)
    HeaderCombat.Font = Enum.Font.GothamBold
        HeaderCombat.TextSize = 11
    HeaderCombat.TextXAlignment = Enum.TextXAlignment.Left
    HeaderCombat.Parent = Content

    UI:AddToggle(Content, "ล็อกเป้าหมาย (Aimbot)", "Combat", "Aimbot")
    UI:AddToggle(Content, "แสดงวง FOV", "Combat", "FOV")
    UI:CreateSlider(Content, "ขนาด FOV",
        function() return Settings.Combat.FOV.Radius end,
        function(v) Settings.Combat.FOV.Radius = v end,
        Settings.Combat.FOV.Min, Settings.Combat.FOV.Max, Settings.Combat.FOV.Radius)

    -- === การเคลื่อนที่ ===
    local HeaderMove = Instance.new("TextLabel")
    HeaderMove.Size = UDim2.new(1, 0, 0, 20)
    HeaderMove.BackgroundTransparency = 1
    HeaderMove.Text = "🏃 การเคลื่อนที่"
    HeaderMove.TextColor3 = Color3.fromRGB(160, 180, 255)
    HeaderMove.Font = Enum.Font.GothamBold
    HeaderMove.TextSize = 11
    HeaderMove.TextXAlignment = Enum.TextXAlignment.Left
    HeaderMove.Parent = Content

    UI:AddToggle(Content, "ความเร็วเดิน", "Movement", "Speed")
    UI:CreateSlider(Content, "ค่าความเร็วเดิน",
        function() return Settings.Movement.Speed.Value end,
        function(v) Settings.Movement.Speed.Value = v end,
        Settings.Movement.Speed.Min, Settings.Movement.Speed.Max, Settings.Movement.Speed.Value)

    UI:AddToggle(Content, "โหมดบิน", "Movement", "Fly")
    UI:CreateSlider(Content, "ค่าความเร็วบิน",
        function() return Settings.Movement.FlySpeed.Value end,
        function(v) Settings.Movement.FlySpeed.Value = v end,
        Settings.Movement.FlySpeed.Min, Settings.Movement.FlySpeed.Max, Settings.Movement.FlySpeed.Value)

    UI:AddToggle(Content, "ทะลุผนัง", "Movement", "NoClip")

    -- === การมองเห็น ===
    local HeaderVis = Instance.new("TextLabel")
    HeaderVis.Size = UDim2.new(1, 0, 0, 20)
    HeaderVis.BackgroundTransparency = 1
    HeaderVis.Text = "👁️ การมองเห็น"
    HeaderVis.TextColor3 = Color3.fromRGB(160, 180, 255)
    HeaderVis.Font = Enum.Font.GothamBold
    HeaderVis.TextSize = 11
    HeaderVis.TextXAlignment = Enum.TextXAlignment.Left
    HeaderVis.Parent = Content

    UI:AddToggle(Content, "มองทะลุ (กล่องเขียว)", "Visuals", "ESP")

    print("✅ โหลดสำเร็จ! ความเร็วบินเริ่มที่ 4")
end)

UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Settings.Keybinds.ToggleUI then
        ToggleUI()
    end
end)
