-- ========================================================
-- 📱 UTILITY HUB - MOBILE VERSION
-- ปรับสำหรับมือถือ: แตะค้างเพื่อล็อกเป้า / แตะปุ่มเพื่อเปิดเมนู
-- ========================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local hasDrawing, Drawing = pcall(function() return Drawing end)
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- ⚙️ ตั้งค่า ปรับได้ตามชอบ
local Settings = {
    UI = { Open = true, Position = UDim2.new(0.02, 0, 0.08, 0) },
    Combat = {
        Aimbot = {
            Enabled = false,
            Smoothness = 0.4,
            AimPart = "Head",
            MaxDistance = 100,
            FOV = 90
        }
    },
    Movement = { NoClip = { Enabled = false } },
    Visuals = { ESP = { Enabled = false } }
}

local State = {
    UIElements = {},
    ESPObjects = {},
    OriginalCollisions = {},
    LastAimTime = 0,
    IsAiming = false,
    IsTouching = false
}

-- 🔍 คำนวณมุม FOV
local function GetAngleBetween(vector1, vector2)
    return math.acos(math.clamp(vector1.Unit:Dot(vector2.Unit), -1, 1))
end

local function IsInFOV(targetPos, fovDegrees)
    local camCF = Camera.CFrame
    local camDir = camCF.LookVector
    local toTarget = (targetPos - camCF.Position).Unit
    local angle = math.de(GetAngleBetween(camDir, toTarget))
    return angle <= fovDegrees
end

-- 🎯 หาเป้าหมาย
local function GetClosestTarget()
    if not Settings.Combat.Aimbot.Enabled or not State.IsAiming then return nil end
    
    local now = os.clock()
    if now - State.LastAimTime < 0.016 then return nil end
    State.LastAimTime = now

    local closest, smallestAngle = nil, math.huge
    local camPos = Camera.CFrame.Position

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local hum = player.Character:FindFirstChild("Humanoid")
            local part = player.Character:FindFirstChild(Settings.Combat.Aimbot.AimPart)
            local root = player.Character:FindFirstChild("HumanoidRootPart")
            
            if hum and hum.Health > 0 and part and root then
                local dist = (camPos - root.Position).Magnitude
                if dist > Settings.Combat.Aimbot.MaxDistance then continue end
                if not IsInFOV(part.Position, Settings.Combat.Aimbot.FOV) then continue end

                local dirToTarget = (part.Position - camPos).Unit
                local angle = math.de(GetAngleBetween(Camera.CFrame.LookVector, dirToTarget))
                
                if angle < smallestAngle then
                    smallestAngle = angle
                    closest = part
                end
            end
        end
    end
    return closest
end

-- 🎨 สร้างปุ่มเปิด-ปิด
local function CreateToggle(parent, name, category, configKey)
    local Container = Instance.new("Frame")
    Container.Size = UDim2.new(1, 0, 0, 50)
    Container.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
    Container.Parent = parent
    Instance.new("UICorner", Container).CornerRadius = UDim.new(0, 10)

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, -70, 1, 0)
    Label.Position = UDim2.new(0, 15, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Text = name
    Label.TextColor3 = Color3.fromRGB(230, 230, 230)
    Label.Font = Enum.Font.GothamMedium
    Label.TextSize = 14
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Container

    local ToggleBtn = Instance.new("TextButton")
    ToggleBtn.Size = UDim2.new(0, 52, 0, 28)
    ToggleBtn.Position = UDim2.new(1, -62, 0.5, -14)
    ToggleBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 75)
    ToggleBtn.AutoLocalize = false
    ToggleBtn.Text = ""
    ToggleBtn.Parent = Container
    Instance.new("UICorner", ToggleBtn).CornerRadius = UDim.new(0, 14)

    local Indicator = Instance.new("Frame")
    Indicator.Size = UDim2.new(0, 22, 0, 22)
    Indicator.Position = UDim2.new(0, 3, 0.5, -11)
    Indicator.BackgroundColor3 = Color3.fromRGB(140, 140, 140)
    Indicator.Parent = ToggleBtn
    Instance.new("UICorner", Indicator).CornerRadius = UDim.new(0, 11)

    local function GetState()
        if category == "Combat" then return Settings.Combat[configKey].Enabled end
        if category == "Movement" then return Settings.Movement[configKey].Enabled end
        if category == "Visuals" then return Settings.Visuals[configKey].Enabled end
        return false
    end

    local function UpdateUI()
        local isOn = GetState()
        ToggleBtn.BackgroundColor3 = isOn and Color3.fromRGB(50, 180, 255) or Color3.fromRGB(70, 70, 75)
        Indicator.Position = isOn and UDim2.new(1, -25, 0.5, -11) or UDim2.new(0, 3, 0.5, -11)
        Indicator.BackgroundColor3 = isOn and Color3.new(1, 1, 1) or Color3.fromRGB(160, 160, 160)
    end

    ToggleBtn.MouseButton1Click:Connect(function()
        if category == "Combat" then Settings.Combat[configKey].Enabled = not Settings.Combat[configKey].Enabled
        elseif category == "Movement" then Settings.Movement[configKey].Enabled = not Settings.Movement[configKey].Enabled
        elseif category == "Visuals" then
            Settings.Visuals[configKey].Enabled = not Settings.Visuals[configKey].Enabled
            if not Settings.Visuals[configKey].Enabled then
                for _, objs in pairs(State.ESPObjects) do
                    if objs.Box then objs.Box.Visible = false end
                    if objs.DistText then objs.DistText.Visible = false end
                end
            end
        end
        UpdateUI()
    end)

    UpdateUI()
    return Container
end

-- 🖥️ สร้าง UI หลัก
local function CreateUI()
    if PlayerGui:FindFirstChild("UtilityHub") then PlayerGui.UtilityHub:Destroy() end

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "UtilityHub"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.Parent = PlayerGui

    -- 📱 ปุ่มลอย เปิด-ปิดเมนู (ใหญ่พอแตะง่าย)
    local FloatBtn = Instance.new("TextButton")
    FloatBtn.Name = "FloatBtn"
    FloatBtn.Size = UDim2.new(0, 55, 0, 55)
    FloatBtn.Position = UDim2.new(0.01, 0, 0.45, -27)
    FloatBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
    FloatBtn.Text = "⚙️"
    FloatBtn.TextSize = 24
    FloatBtn.Font = Enum.Font.GothamBold
    FloatBtn.AutoLocalize = false
    FloatBtn.Parent = ScreenGui
    Instance.new("UICorner", FloatBtn).CornerRadius = UDim.new(0, 14)

    -- หน้าต่างหลัก
    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = UDim2.new(0, 280, 0, 260)
    MainFrame.Position = Settings.UI.Position
    MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    MainFrame.BorderSizePixel = 0
    MainFrame.Visible = Settings.UI.Open
    MainFrame.Parent = ScreenGui
    Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 14)

    -- แถบหัวเรื่อง
    local TitleBar = Instance.new("Frame")
    TitleBar.Size = UDim2.new(1, 0, 0, 55)
    TitleBar.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
    TitleBar.Parent = MainFrame
    Instance.new("UICorner", TitleBar).CornerRadius = UDim.new(0, 14)

    local TitleText = Instance.new("TextLabel")
    TitleText.Size = UDim2.new(1, -60, 1, 0)
    TitleText.Position = UDim2.new(0, 15, 0, 0)
    TitleText.BackgroundTransparency = 1
    TitleText.Text = "🔥 Utility Hub [มือถือ]"
    TitleText.TextColor3 = Color3.fromRGB(255, 255, 255)
    TitleText.Font = Enum.Font.GothamBold
    TitleText.TextSize = 16
    TitleText.TextXAlignment = Enum.TextXAlignment.Left
    TitleText.Parent = TitleBar

    -- ปุ่มปิด
    local CloseBtn = Instance.new("TextButton")
    CloseBtn.Size = UDim2.new(0, 40, 0, 40)
    CloseBtn.Position = UDim2.new(1, -50, 0.5, -20)
    CloseBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
    CloseBtn.Text = "✕"
    CloseBtn.TextColor3 = Color3.new(1, 1, 1)
    CloseBtn.TextSize = 16
    CloseBtn.Font = Enum.Font.GothamBold
    CloseBtn.AutoLocalize = false
    CloseBtn.Parent = TitleBar
    Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 10)

    CloseBtn.MouseButton1Click:Connect(function()
        Settings.UI.Open = false
        MainFrame.Visible = false
    end)

    -- คำแนะนำมือถือ
    local HelpLabel = Instance.new("TextLabel")
    HelpLabel.Size = UDim2.new(1, -30, 0, 40)
    HelpLabel.Position = UDim2.new(0, 15, 0, 60)
    HelpLabel.BackgroundTransparency = 1
    HelpLabel.Text = "👆 แตะค้างบนจอ = ล็อกเป้า\n⚙️ แตะปุ่มด้านข้าง = เปิด/ปิดเมนู"
    HelpLabel.TextColor3 = Color3.fromRGB(120, 200, 255)
    HelpLabel.Font = Enum.Font.Gotham
    HelpLabel.TextSize = 11
    HelpLabel.TextWrapped = true
    HelpLabel.Parent = MainFrame

    -- พื้นที่ใส่ปุ่ม
    local Content = Instance.new("Frame")
    Content.Name = "Content"
    Content.Size = UDim2.new(1, -30, 1, -110)
    Content.Position = UDim2.new(0, 15, 0, 105)
    Content.BackgroundTransparency = 1
    Content.Parent = MainFrame

    local Layout = Instance.new("UIListLayout")
    Layout.Padding = UDim.new(0, 12)
    Layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    Layout.VerticalAlignment = Enum.VerticalAlignment.Top
    Layout.Parent = Content

    -- 3 ปุ่มหลัก
    CreateToggle(Content, "🎯 ล็อกเป้าหมาย (Aimbot)", "Combat", "Aimbot")
    CreateToggle(Content, "🔨 ทะลุผนัง", "Movement", "NoClip")
    CreateToggle(Content, "👁️ มองทะลุ (กล่อง+ระยะ)", "Visuals", "ESP")

    -- เปิด-ปิดเมนู ด้วยปุ่มลอย
    FloatBtn.MouseButton1Click:Connect(function()
        Settings.UI.Open = not Settings.UI.Open
        MainFrame.Visible = Settings.UI.Open
    end)

    State.UIElements = { MainFrame = MainFrame, FloatBtn = FloatBtn }
end

-- 👁️ มองทะลุ
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
                    if dist > 150 then goto continue end
                    local height = math.abs(rPos.Y - hPos.Y) * 2.5
                    local width = height * 0.6
                    local centerX = rPos.X
                    local centerY = (rPos.Y + hPos.Y) / 2

                    local objs = State.ESPObjects[idx]
                    if not objs then
                        objs = { Box = Drawing.new("Square"), DistText = Drawing.new("Text") }
                        objs.Box.Thickness = 1.5; objs.Box.Filled = false; objs.Box.Color = Color3.fromRGB(50, 255, 50)
                        objs.DistText.Center = true; objs.DistText.Outline = true; objs.DistText.Font = 2
                        objs.DistText.Size = 12; objs.DistText.Color = Color3.new(1, 1, 1)
                        State.ESPObjects[idx] = objs
                    end

                    objs.Box.Visible = true
                    objs.Box.Size = Vector2.new(width, height)
                    objs.Box.Position = Vector2.new(centerX - width/2, centerY - height/2)
                    objs.DistText.Visible = true
                    objs.DistText.Position = Vector2.new(centerX, centerY - height/2 - 15)
                    objs.DistText.Text = dist .. "m"
                    idx += 1
                end
                ::continue::
            end
        end
    end
    for i = idx, #State.ESPObjects do
        local objs = State.ESPObjects[i]
        if objs then if objs.Box then objs.Box.Visible = false end; if objs.DistText then objs.DistText.Visible = false end end
    end
end

-- 📱 ตรวจจับการแตะหน้าจอ
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    -- แตะหน้าจอค้าง = ล็อกเป้า
    if input.UserInputType == Enum.UserInputType.Touch then
        State.IsTouching = true
        State.IsAiming = true
    end
end)

UserInputService.InputEnded:Connect(function(input, gp)
    if gp then return end
    -- ปล่อยนิ้ว = หยุดล็อก
    if input.UserInputType == Enum.UserInputType.Touch then
        State.IsTouching = false
        State.IsAiming = false
    end
end)

-- 🔄 ลูปหลัก
RunService.RenderStepped:Connect(function(dt)
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChild("Humanoid")
    if not hum then return end

    -- ทะลุผนัง
    if Settings.Movement.NoClip.Enabled then
        for _, part in ipairs(char:GetChildren()) do
            if part:IsA("BasePart") then
                if State.OriginalCollisions[part] == nil then State.OriginalCollisions[part] = part.CanCollide end
                part.CanCollide = false
            end
        end
    else
        for part, orig in pairs(State.OriginalCollisions) do if part then part.CanCollide = orig end end
        table.clear(State.OriginalCollisions)
    end

    -- ล็อกเป้า
    local target = GetClosestTarget()
    if target then
        local aimPos = target.Position
        local camPos = Camera.CFrame.Position
        local desired = CFrame.new(camPos, aimPos)
        local smooth = math.clamp(Settings.Combat.Aimbot.Smoothness * dt * 60, 0.03, 1)
        Camera.CFrame = Camera.CFrame:Lerp(desired, smooth)
    end
end)

RunService.RenderStepped:Connect(UpdateESP)

LocalPlayer.CharacterAdded:Connect(function() State.OriginalCollisions = {} end)

-- เริ่มทำงาน
CreateUI()

print("✅ โหลดสำเร็จ! [เวอร์ชันมือถือ]")
print("👆 แตะค้างบนจอเพื่อล็อกเป้า ปล่อยเพื่อหยุด")
print("⚙️ แตะปุ่ม ⚙️ ด้านซ้ายเพื่อเปิด/ปิดเมนู")
