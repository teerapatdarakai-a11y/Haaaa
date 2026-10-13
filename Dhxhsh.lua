-- ========================================================
-- 🚀 UTILITY HUB - ESP WITH DISTANCE ONLY (NO NAME)
-- มีเพียง: Aimbot / ทะลุผนัง / มองทะลุ(กล่องเขียว+ระยะ)
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
        Position = UDim2.new(0.5, -150, 0.5, -110)
    },
    Combat = {
        Aimbot = { Enabled = false, Smoothness = 0.25, AimPart = "Head" }
    },
    Movement = {
        NoClip = { Enabled = false }
    },
    Visuals = {
        ESP = { Enabled = false }
    },
    Keybinds = {
        ToggleUI = Enum.KeyCode.RightShift
    }
}

local State = {
    UIElements = {},
    ESPObjects = {},
    OriginalCollisions = {},
    CharacterAdded = false
}

local UI = {}

-- สร้างปุ่มเปิดปิด
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
        if category == "Combat" then return Settings.Combat[configKey].Enabled end
        if category == "Movement" then return Settings.Movement[configKey].Enabled end
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
        if category == "Combat" then
            Settings.Combat[configKey].Enabled = not Settings.Combat[configKey].Enabled
        elseif category == "Movement" then
            Settings.Movement[configKey].Enabled = not Settings.Movement[configKey].Enabled
        elseif category == "Visuals" then
            Settings.Visuals[configKey].Enabled = not Settings.Visuals[configKey].Enabled
            if not Settings.Visuals.ESP.Enabled then
                for _, objs in pairs(State.ESPObjects) do
                    if objs.Box then objs.Box.Visible = false end
                    if objs.DistText then objs.DistText.Visible = false end
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
    MainFrame.Size = UDim2.new(0, 300, 0, 190)
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
    TitleText.Text = "🔥 Utility Hub"
    TitleText.TextColor3 = Color3.new(1, 1, 1)
    TitleText.Font = Enum.Font.GothamBold
    TitleText.TextSize = 14
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

local function GetCharacter() return LocalPlayer.Character end
local function GetHumanoid() local c = GetCharacter() return c and c:FindFirstChild("Humanoid") end

-- ล็อกเป้าหมาย
local function GetClosestTarget()
    if not Settings.Combat.Aimbot.Enabled then return nil end
    local closest, minDist = nil, 200
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

-- มองทะลุ: กล่องเขียว + ระยะ ❌ ไม่มีชื่อ ✅
local function UpdateESP()
    if not hasDrawing or not Settings.Visuals.ESP.Enabled then
        for _, objs in pairs(State.ESPObjects) do
            if objs.Box then objs.Box.Visible = false end
            if objs.DistText then objs.DistText.Visible = false end
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
                            DistText = Drawing.new("Text")
                        }
                        objs.Box.Thickness = 1.5
                        objs.Box.Filled = false
                        objs.Box.Color = Color3.fromRGB(50, 255, 50)
                        objs.DistText.Center = true
                        objs.DistText.Outline = true
                        objs.DistText.Font = 2
                        objs.DistText.Size = 12
                        objs.DistText.Color = Color3.new(1, 1, 1)
                        State.ESPObjects[idx] = objs
                    end
                    
                    objs.Box.Visible = true
                    objs.Box.Size = Vector2.new(width, height)
                    objs.Box.Position = Vector2.new(centerX - width/2, centerY - height/2)
                    
                    objs.DistText.Visible = true
                    objs.DistText.Position = Vector2.new(centerX, centerY - height/2 - 15)
                    objs.DistText.Text = dist .. " m"
                    
                    idx += 1
                end
            end
        end
    end
    for i = idx, #State.ESPObjects do
        local objs = State.ESPObjects[i]
        if objs then
            if objs.Box then objs.Box.Visible = false end
            if objs.DistText then objs.DistText.Visible = false end
        end
    end
end

-- หลักการทำงาน
RunService.Heartbeat:Connect(function(dt)
    local hum = GetHumanoid()
    local char = GetCharacter()
    if not hum or not char then return end

    -- ทะลุผนัง
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

    -- ล็อกเป้าหมาย
    local target = GetClosestTarget()
    if target then
        local aimPos = target.Position
        local camPos = Camera.CFrame.Position
        local desired = CFrame.new(camPos, aimPos)
        local smooth = math.clamp(Settings.Combat.Aimbot.Smoothness * dt * 60, 0.01, 1)
        Camera.CFrame = Camera.CFrame:Lerp(desired, smooth)
    end
end)

RunService.RenderStepped:Connect(UpdateESP)

LocalPlayer.CharacterAdded:Connect(function()
    State.OriginalCollisions = {}
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

    UI:AddToggle(Content, "ล็อกเป้าหมาย (Aimbot)", "Combat", "Aimbot")
    UI:AddToggle(Content, "ทะลุผนัง", "Movement", "NoClip")
    UI:AddToggle(Content, "มองทะลุ (กล่องเขียว+ระยะ)", "Visuals", "ESP")

    print("✅ โหลดสำเร็จ! ESP แสดงกล่อง+ระยะ ไม่มีชื่อ")
end)

UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Settings.Keybinds.ToggleUI then
        ToggleUI()
    end
end)
