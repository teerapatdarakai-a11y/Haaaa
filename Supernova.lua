-- ========================================================
-- 🚀 UTILITY HUB - ULTIMATE PRO (NON-BLOCKING ASYNC LOAD)
-- ========================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = workspace
local Camera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
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

-- เตรียมวงกลม FOV ล่วงหน้าแบบปลอดภัย
local FOVCircle = nil
pcall(function()
    FOVCircle = Drawing.new("Circle")
    FOVCircle.Visible = false
    FOVCircle.Transparency = 0.7
    FOVCircle.Thickness = 1
    FOVCircle.Filled = false
end)

-- ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
-- ส่วนสร้าง UI (แยกการทำงานไม่ให้กวน Main Thread)
-- ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
local UI = {}

function UI:CreateWindow()
    if PlayerGui:FindFirstChild("FullFunctionalHub") then
        PlayerGui.FullFunctionalHub:Destroy()
    end

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "FullFunctionalHub"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.Parent = PlayerGui

    local FloatBtn = Instance.new("TextButton")
    FloatBtn.Name = "FloatingButton"
    FloatBtn.Size = UDim2.new(0, 45, 0, 45)
    FloatBtn.Position = UDim2.new(0.02, 0, 0.15, 0)
    FloatBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
    FloatBtn.Text = "⚡"
    FloatBtn.TextColor3 = Color3.fromRGB(255, 220, 50)
    FloatBtn.TextSize = 20
    FloatBtn.Font = Enum.Font.GothamBold
    FloatBtn.Draggable = true
    FloatBtn.Parent = ScreenGui

    local FloatCorner = Instance.new("UICorner")
    FloatCorner.CornerRadius = UDim.new(0, 10)
    FloatCorner.Parent = FloatBtn

    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = UDim2.new(0, 280, 0, 420)
    MainFrame.Position = Settings.UI.Position
    MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    MainFrame.BorderSizePixel = 0
    MainFrame.Active = true
    MainFrame.Draggable = true
    MainFrame.Parent = ScreenGui

    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(0, 8)
    UICorner.Parent = MainFrame

    local TitleBar = Instance.new("Frame")
    TitleBar.Name = "TitleBar"
    TitleBar.Size = UDim2.new(1, 0, 0, 35)
    TitleBar.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
    TitleBar.BorderSizePixel = 0
    TitleBar.Parent = MainFrame

    local TitleCorner = Instance.new("UICorner")
    TitleCorner.CornerRadius = UDim.new(0, 8)
    TitleCorner.Parent = TitleBar

    local TitleText = Instance.new("TextLabel")
    TitleText.Name = "Title"
    TitleText.Size = UDim2.new(1, -10, 1, 0)
    TitleText.Position = UDim2.new(0, 10, 0, 0)
    TitleText.BackgroundTransparency = 1
    TitleText.Text = "🔥 Utility Hub - Non-Blocking"
    TitleText.TextColor3 = Color3.new(1, 1, 1)
    TitleText.TextXAlignment = Enum.TextXAlignment.Left
    TitleText.Font = Enum.Font.GothamBold
    TitleText.TextSize = 14
    TitleText.Parent = TitleBar

    local Content = Instance.new("ScrollingFrame")
    Content.Name = "Content"
    Content.Size = UDim2.new(1, -16, 1, -45)
    Content.Position = UDim2.new(0, 8, 0, 40)
    Content.BackgroundTransparency = 1
    Content.ScrollBarThickness = 3
    Content.ScrollBarColor3 = Color3.fromRGB(80, 80, 90)
    Content.CanvasSize = UDim2.new(0, 0, 0, 400)
    Content.Parent = MainFrame

    local Layout = Instance.new("UIListLayout")
    Layout.Padding = UDim.new(0, 6)
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
    Container.Size = UDim2.new(1, 0, 0, 32)
    Container.BackgroundColor3 = Color3.fromRGB(42, 42, 50)
    Container.BorderSizePixel = 0
    Container.Parent = parent

    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 6)
    Corner.Parent = Container

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, -45, 1, 0)
    Label.Position = UDim2.new(0, 10, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Text = name
    Label.TextColor3 = Color3.new(0.9, 0.9, 0.9)
    Label.Font = Enum.Font.Gotham
    Label.TextSize = 13
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Container

    local ToggleBtn = Instance.new("TextButton")
    ToggleBtn.Size = UDim2.new(0, 32, 0, 20)
    ToggleBtn.Position = UDim2.new(1, -40, 0.5, -10)
    ToggleBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 90)
    ToggleBtn.BorderSizePixel = 0
    ToggleBtn.Text = ""
    ToggleBtn.Parent = Container

    local BtnCorner = Instance.new("UICorner")
    BtnCorner.CornerRadius = UDim.new(0, 4)
    BtnCorner.Parent = ToggleBtn

    local Indicator = Instance.new("Frame")
    Indicator.Size = UDim2.new(0, 14, 0, 14)
    Indicator.Position = UDim2.new(0, 3, 0.5, -7)
    Indicator.BackgroundColor3 = Color3.fromRGB(140, 140, 150)
    Indicator.BorderSizePixel = 0
    Indicator.Parent = ToggleBtn

    local IndCorner = Instance.new("UICorner")
    IndCorner.CornerRadius = UDim.new(0, 3)
    IndCorner.Parent = Indicator

    local function UpdateUI()
        local isOn = false
        if category == "Movement" then
            isOn = Settings.Movement[configKey].Enabled
        elseif category == "Combat" then
            isOn = Settings.Combat[configKey].Enabled
        elseif category == "Visuals" then
            isOn = Settings.Visuals[configKey].Enabled
        end

        ToggleBtn.BackgroundColor3 = isOn and Color3.fromRGB(60, 130, 220) or Color3.fromRGB(80, 80, 90)
        Indicator.Position = isOn and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)
        Indicator.BackgroundColor3 = isOn and Color3.new(1, 1, 1) or Color3.fromRGB(140, 140, 150)
    end

    ToggleBtn.MouseButton1Click:Connect(function()
        if category == "Movement" then
            Settings.Movement[configKey].Enabled = not Settings.Movement[configKey].Enabled
            if configKey == "Speed" and not Settings.Movement.Speed.Enabled then
                local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
                if hum then hum.WalkSpeed = State.OriginalWalkSpeed end
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
                    if esp and esp.Remove then esp:Remove() end
                end
                State.ESPObjects = {}
            end
        end
        UpdateUI()
    end)

    UpdateUI()
end

-- ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
-- ส่วน Core Logic (Aimbot, Fly, NoClip, ESP)
-- ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
local function GetCharacter()
    return LocalPlayer.Character
end

local function GetRoot()
    local c = GetCharacter()
    return c and c:FindFirstChild("HumanoidRootPart")
end

local function GetHumanoid()
    local c = GetCharacter()
    return c and c:FindFirstChild("Humanoid")
end

local flyConnection
local function ToggleFly(enabled)
    local root = GetRoot()
    if not root then return end

    if root:FindFirstChild("HubFlyVelocity") then root.HubFlyVelocity:Destroy() end
    if root:FindFirstChild("HubFlyGyro") then root.HubFlyGyro:Destroy() end
    if flyConnection then 
        flyConnection:Disconnect() 
        flyConnection = nil
    end

    if enabled then
        local bv = Instance.new("BodyVelocity")
        bv.Name = "HubFlyVelocity"
        bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
        bv.Velocity = Vector3.new(0, 0, 0)
        bv.Parent = root

        local bg = Instance.new("BodyGyro")
        bg.Name = "HubFlyGyro"
        bg.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
        bg.CFrame = Camera.CFrame
        bg.Parent = root

        flyConnection = RunService.RenderStepped:Connect(function()
            if not Settings.Movement.Fly.Enabled then 
                if bv then bv:Destroy() end
                if bg then bg:Destroy() end
                if flyConnection then flyConnection:Disconnect() end
                return 
            end

            bg.CFrame = Camera.CFrame
            local moveDir = Vector3.new()
            
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + Camera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - Camera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - Camera.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + Camera.CFrame.RightVector end

            bv.Velocity = moveDir * Settings.Movement.Fly.Speed
        end)
    end
end

local function GetClosestTarget()
    local closestTarget = nil
    local shortestDist = Settings.Combat.FOV.Radius
    local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local targetChar = player.Character
            local humanoid = targetChar:FindFirstChild("Humanoid")
            local targetPart = targetChar:FindFirstChild(Settings.Combat.Aimbot.AimPart)

            if humanoid and humanoid.Health > 0 and targetPart then
                local screenPoint, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
                if onScreen then
                    local screenDist = (Vector2.new(screenPoint.X, screenPoint.Y) - screenCenter).Magnitude
                    if screenDist < shortestDist then
                        shortestDist = screenDist
                        closestTarget = targetPart
                    end
                end
            end
        end
    end
    return closestTarget
end

local function UpdateFOV()
    if FOVCircle then
        if Settings.Combat.FOV.Enabled and Settings.Combat.Aimbot.Enabled then
            FOVCircle.Visible = true
            FOVCircle.Radius = Settings.Combat.FOV.Radius
            FOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
            FOVCircle.Color = Settings.Combat.FOV.Color
        else
            FOVCircle.Visible = false
        end
    end
end

local function UpdateESP()
    if not Settings.Visuals.ESP.Enabled then
        for _, esp in pairs(State.ESPObjects) do
            esp.Visible = false
        end
        return
    end

    local index = 1
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local char = player.Character
            local rootPart = char:FindFirstChild("HumanoidRootPart")
            local humanoid = char:FindFirstChild("Humanoid")

            if rootPart and humanoid and humanoid.Health > 0 then
                local vector, onScreen = Camera:WorldToViewportPoint(rootPart.Position)
                if onScreen then
                    local dist = (Camera.CFrame.Position - rootPart.Position).Magnitude
                    local textObj = State.ESPObjects[index]

                    if not textObj then
                        textObj = Drawing.new("Text")
                        textObj.Center = true
                        textObj.Outline = true
                        textObj.Font = 2
                        textObj.Size = 14
                        textObj.Color = Color3.fromRGB(255, 255, 255)
                        State.ESPObjects[index] = textObj
                    end

                    textObj.Visible = true
                    textObj.Position = Vector2.new(vector.X, vector.Y)
                    textObj.Text = player.Name .. " [" .. math.floor(dist) .. "m]"
                    index = index + 1
                end
            end
        end
    end

    for i = index, #State.ESPObjects do
        if State.ESPObjects[i] then
            State.ESPObjects[i].Visible = false
        end
    end
end

-- ลูปหลักรันเบื้องหลัง
RunService.Heartbeat:Connect(function(deltaTime)
    local char = GetCharacter()
    local hum = GetHumanoid()
    if not char or not hum then return end

    if Settings.Movement.Speed.Enabled then
        hum.WalkSpeed = Settings.Movement.Speed.Value
    end

    if Settings.Movement.NoClip.Enabled then
        for _, part in ipairs(char:GetChildren()) do
            if part:IsA("BasePart") then
                if State.OriginalCollisions[part] == nil then
                    State.OriginalCollisions[part] = part.CanCollide
                end
                part.CanCollide = false
            end
        end
    end

    if Settings.Combat.Aimbot.Enabled then
        local target = GetClosestTarget()
        if target then
            local targetCFrame = CFrame.new(Camera.CFrame.Position, target.Position)
            local smoothFactor = math.clamp(Settings.Combat.Aimbot.Smoothness * (deltaTime * 60), 0.05, 1)
            Camera.CFrame = Camera.CFrame:Lerp(targetCFrame, smoothFactor)
        end
    end
end)

RunService.RenderStepped:Connect(function()
    UpdateESP()
    UpdateFOV()
end)

local lastFlyState = false
RunService.RenderStepped:Connect(function()
    if lastFlyState ~= Settings.Movement.Fly.Enabled then
        lastFlyState = Settings.Movement.Fly.Enabled
        ToggleFly(lastFlyState)
    end
end)

local function ToggleUI()
    Settings.UI.Open = not Settings.UI.Open
    if State.UIElements.MainFrame then
        State.UIElements.MainFrame.Visible = Settings.UI.Open
    end
end

-- ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
-- ส่วนสำคัญ: ใช้ task.spawn โหลดแบบไม่ค้าง (Non-Blocking Async)
-- ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
task.spawn(function()
    local Content = UI:CreateWindow()

    task.delay(1, function()
        local hum = GetHumanoid()
        if hum then State.OriginalWalkSpeed = hum.WalkSpeed end
    end)

    if State.UIElements.FloatBtn then
        State.UIElements.FloatBtn.MouseButton1Click:Connect(function()
            ToggleUI()
        end)
    end

    local SecCombat = Instance.new("TextLabel")
    SecCombat.Size = UDim2.new(1, 0, 0, 20)
    SecCombat.BackgroundTransparency = 1
    SecCombat.Text = "🎯 ระบบต่อสู้ (Combat & Aimbot)"
    SecCombat.TextColor3 = Color3.fromRGB(255, 160, 160)
    SecCombat.Font = Enum.Font.GothamBold
    SecCombat.TextSize = 12
    SecCombat.TextXAlignment = Enum.TextXAlignment.Left
    SecCombat.Parent = Content

    UI:AddToggle(Content, "เปิด Aimbot ล็อกเป้าหมาย", "Combat", "Aimbot")
    UI:AddToggle(Content, "แสดงวงกลม FOV (รัศมีล็อก)", "Combat", "FOV")

    local SecMovement = Instance.new("TextLabel")
    SecMovement.Size = UDim2.new(1, 0, 0, 20)
    SecMovement.BackgroundTransparency = 1
    SecMovement.Text = "🏃 การเคลื่อนที่ (Movement)"
    SecMovement.TextColor3 = Color3.fromRGB(160, 180, 255)
    SecMovement.Font = Enum.Font.GothamBold
    SecMovement.TextSize = 12
    SecMovement.TextXAlignment = Enum.TextXAlignment.Left
    SecMovement.Parent = Content

    UI:AddToggle(Content, "เพิ่มความเร็ว (Speed)", "Movement", "Speed")
    UI:AddToggle(Content, "โหมดบิน (Fly)", "Movement", "Fly")
    UI:AddToggle(Content, "ทะลุผนัง (NoClip)", "Movement", "NoClip")

    local SecVisuals = Instance.new("TextLabel")
    SecVisuals.Size = UDim2.new(1, 0, 0, 20)
    SecVisuals.BackgroundTransparency = 1
    SecVisuals.Text = "👁️ การมองเห็น (Visuals)"
    SecVisuals.TextColor3 = Color3.fromRGB(160, 180, 255)
    SecVisuals.Font = Enum.Font.GothamBold
    SecVisuals.TextSize = 12
    SecVisuals.TextXAlignment = Enum.TextXAlignment.Left
    SecVisuals.Parent = Content

    UI:AddToggle(Content, "เปิด ESP (มองทะลุ)", "Visuals", "ESP")

    local Info = Instance.new("TextLabel")
    Info.Size = UDim2.new(1, 0, 0, 25)
    Info.BackgroundTransparency = 1
    Info.Text = "แตะปุ่ม ⚡ หรือกด ⇧ Shift ขวา เพื่อเปิด/ปิด UI"
    Info.TextColor3 = Color3.fromRGB(110, 110, 120)
    Info.Font = Enum.Font.Gotham
    Info.TextSize = 10
    Info.Parent = Content

    print("✅ โหลด Utility Hub (Non-Blocking Pro Edition) สำเร็จทันทีโดยไม่ค้าง!")
end)

UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Settings.Keybinds.ToggleUI then
        ToggleUI()
    end
end)
