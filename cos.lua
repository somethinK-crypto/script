-- [[ OMNI CORE v18.2.3 - NOCLIP FIX + DRAGGABLE TP MENU + ANTI-RAGDOLL + FULLBRIGHT + ANTI-GRAB ]]
-- Fixed: Noclip now restores collisions upon deactivation
-- Added: Draggable header for Teleport Menu
-- Added: Anti-Ragdoll system
-- Added: Fullbright system
-- Added: Anti-Grab & Anti-Control (blocks foreign BodyMovers, Welds, Anchors, Fling, Sit)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local settings = {
    noclip = false,
    godlyNoclip = false,
    fly = false,
    speed = false,
    force1st = false,
    force3rd = false,
    invisibility = false,
    killaura = false,
    esp = false,
    auraRange = 20,
    flySpeed = 100,
    speedValue = 100,
    antiragdoll = false,
    fullbright = false,
    antigrab = false,
    brightnessValue = 5
}

local connections = {}
local espObjects = {}
local invisParts = {}
local originalLighting = {}

-- UTILITY FUNCTIONS
local function clearConnection(name)
    if connections[name] then
        connections[name]:Disconnect()
        connections[name] = nil
    end
end

local function getCharacter()
    return player.Character or player.CharacterAdded:Wait()
end

local function getHumanoid(char)
    return char and char:FindFirstChildOfClass("Humanoid")
end

local function getRootPart(char)
    return char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso"))
end

-- UI SETUP
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "OMNI_PRO_V18_FINAL"
ScreenGui.ResetOnSpawn = false
pcall(function() ScreenGui.Parent = game:GetService("CoreGui") end)
if not ScreenGui.Parent then ScreenGui.Parent = player:WaitForChild("PlayerGui") end

-- MAIN FRAME
local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 320, 0, 540)
MainFrame.Position = UDim2.new(0.5, -160, 0.5, -270)
MainFrame.BackgroundColor3 = Color3.fromRGB(10, 11, 14)
MainFrame.BorderSizePixel = 0
MainFrame.Visible = false
MainFrame.ClipsDescendants = true
MainFrame.ZIndex = 10

local corner = Instance.new("UICorner", MainFrame)
corner.CornerRadius = UDim.new(0, 10)

local mainStroke = Instance.new("UIStroke", MainFrame)
mainStroke.Thickness = 1.5
mainStroke.Color = Color3.fromRGB(35, 38, 45)
mainStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

local AccentBar = Instance.new("Frame", MainFrame)
AccentBar.Size = UDim2.new(1, 0, 0, 3)
AccentBar.BackgroundColor3 = Color3.fromRGB(0, 120, 255)
AccentBar.BorderSizePixel = 0
AccentBar.ZIndex = 11

local TitleLabel = Instance.new("TextLabel", MainFrame)
TitleLabel.Size = UDim2.new(1, 0, 0, 50)
TitleLabel.Position = UDim2.new(0, 15, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "OMNI <font color='#0078FF'>PRO</font> v18.2.3"
TitleLabel.RichText = true
TitleLabel.TextColor3 = Color3.new(1, 1, 1)
TitleLabel.TextSize = 16
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.ZIndex = 11

local Scroll = Instance.new("ScrollingFrame", MainFrame)
Scroll.Size = UDim2.new(1, -20, 1, -70)
Scroll.Position = UDim2.new(0, 10, 0, 60)
Scroll.BackgroundTransparency = 1
Scroll.BorderSizePixel = 0
Scroll.ScrollBarThickness = 0
Scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
Scroll.ZIndex = 11

local UIList = Instance.new("UIListLayout", Scroll)
UIList.Padding = UDim.new(0, 8)
UIList.SortOrder = Enum.SortOrder.LayoutOrder

-- TOGGLE BUTTON
local ToggleBtn = Instance.new("TextButton", ScreenGui)
ToggleBtn.Size = UDim2.new(0, 50, 0, 50)
ToggleBtn.Position = UDim2.new(0.05, 0, 0.4, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(15, 16, 20)
ToggleBtn.Text = "O"
ToggleBtn.TextColor3 = Color3.fromRGB(0, 120, 255)
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.TextSize = 20
ToggleBtn.ZIndex = 100
Instance.new("UICorner", ToggleBtn).CornerRadius = UDim.new(1, 0)
local tStroke = Instance.new("UIStroke", ToggleBtn)
tStroke.Color = Color3.fromRGB(35, 38, 45)
tStroke.Thickness = 2

-- DRAG LOGIC (Toggle Button)
local dragging, dragStart, startPos, hasMoved = false, nil, nil, false
ToggleBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging, dragStart, startPos, hasMoved = true, input.Position, ToggleBtn.Position, false
    end
end)
UIS.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        if delta.Magnitude > 5 then hasMoved = true end
        ToggleBtn.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)
ToggleBtn.InputEnded:Connect(function(input)
    if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
        if not hasMoved then MainFrame.Visible = not MainFrame.Visible end
        dragging = false
    end
end)

-- COMPONENT CREATORS
local function createButton(name, key, callback)
    local btn = Instance.new("TextButton", Scroll)
    btn.Size = UDim2.new(1, 0, 0, 42)
    btn.BackgroundColor3 = Color3.fromRGB(22, 24, 28)
    btn.Text = "  " .. name
    btn.TextColor3 = Color3.fromRGB(200, 200, 200)
    btn.Font = Enum.Font.GothamMedium
    btn.TextSize = 13
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.AutoButtonColor = false
    btn.ZIndex = 12
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

    local indicator = Instance.new("Frame", btn)
    indicator.Size = UDim2.new(0, 35, 0, 18)
    indicator.Position = UDim2.new(1, -45, 0.5, -9)
    indicator.BackgroundColor3 = Color3.fromRGB(40, 42, 48)
    indicator.ZIndex = 13
    Instance.new("UICorner", indicator).CornerRadius = UDim.new(1, 0)
    
    local dot = Instance.new("Frame", indicator)
    dot.Size = UDim2.new(0, 12, 0, 12)
    dot.Position = UDim2.new(0, 3, 0.5, -6)
    dot.BackgroundColor3 = Color3.fromRGB(150, 150, 150)
    dot.ZIndex = 14
    Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)

    btn.MouseButton1Click:Connect(function()
        if key ~= "none" then
            settings[key] = not settings[key]
            local enabled = settings[key]
            TweenService:Create(indicator, TweenInfo.new(0.2), {BackgroundColor3 = enabled and Color3.fromRGB(0, 120, 255) or Color3.fromRGB(40, 42, 48)}):Play()
            TweenService:Create(dot, TweenInfo.new(0.2), {
                Position = enabled and UDim2.new(1, -15, 0.5, -6) or UDim2.new(0, 3, 0.5, -6),
                BackgroundColor3 = enabled and Color3.new(1,1,1) or Color3.fromRGB(150, 150, 150)
            }):Play()
        end
        if callback then pcall(function() callback(settings[key]) end) end
    end)
end

local function createSlider(name, min, max, settingKey, callback)
    local frame = Instance.new("Frame", Scroll)
    frame.Size = UDim2.new(1, 0, 0, 60)
    frame.BackgroundColor3 = Color3.fromRGB(18, 20, 24)
    frame.ZIndex = 12
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 6)

    local label = Instance.new("TextLabel", frame)
    label.Size = UDim2.new(1, -20, 0, 30)
    label.Position = UDim2.new(0, 10, 0, 5)
    label.BackgroundTransparency = 1
    label.Text = name .. ": " .. (settings[settingKey] or min)
    label.TextColor3 = Color3.fromRGB(160, 160, 160)
    label.Font = Enum.Font.GothamMedium
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.ZIndex = 13

    local bar = Instance.new("Frame", frame)
    bar.Size = UDim2.new(0.9, 0, 0, 4)
    bar.Position = UDim2.new(0.05, 0, 0, 42)
    bar.BackgroundColor3 = Color3.fromRGB(40, 42, 48)
    bar.ZIndex = 13
    Instance.new("UICorner", bar)

    local fill = Instance.new("Frame", bar)
    local initialPercent = (settings[settingKey] - min) / (max - min)
    fill.Size = UDim2.new(initialPercent, 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(0, 120, 255)
    fill.ZIndex = 14
    Instance.new("UICorner", fill)

    local function update(input)
        local pos = math.clamp((input.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
        fill.Size = UDim2.new(pos, 0, 1, 0)
        local val = math.floor(min + (max - min) * pos)
        settings[settingKey] = val
        label.Text = name .. ": " .. val
        if callback then callback(val) end
    end

    local draggingSlider = false
    bar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then 
            draggingSlider = true 
            update(input) 
        end
    end)
    UIS.InputChanged:Connect(function(input)
        if draggingSlider and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then 
            update(input) 
        end
    end)
    UIS.InputEnded:Connect(function(input) 
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then 
            draggingSlider = false 
        end 
    end)
end

-- CAMERA FORCE SYSTEM
local function setupCameraMode()
    clearConnection("camera1st")
    clearConnection("camera3rd")
    
    local char = getCharacter()
    local hum = getHumanoid(char)
    
    if not hum then return end
    
    if settings.force1st then
        settings.force3rd = false
        player.CameraMaxZoomDistance = 0.5
        player.CameraMinZoomDistance = 0.5
        
        connections.camera1st = RunService.RenderStepped:Connect(function()
            if hum and hum.Parent then
                hum.CameraOffset = Vector3.new(0, 0, 0)
                camera.CFrame = camera.CFrame
            else
                clearConnection("camera1st")
            end
        end)
        
    elseif settings.force3rd then
        settings.force1st = false
        player.CameraMaxZoomDistance = 15
        player.CameraMinZoomDistance = 10
        
        connections.camera3rd = RunService.RenderStepped:Connect(function()
            if camera.Focus and (camera.Focus.Position - camera.CFrame.Position).Magnitude < 1 then
                hum.CameraOffset = Vector3.new(0, 2, 8)
            end
        end)
        
    else
        player.CameraMaxZoomDistance = 128
        player.CameraMinZoomDistance = 0.5
        if hum then
            hum.CameraOffset = Vector3.new(0, 0, 0)
        end
    end
end

local function toggleForce1st(state)
    if state then
        settings.force3rd = false
    end
    setupCameraMode()
end

local function toggleForce3rd(state)
    if state then
        settings.force1st = false
    end
    setupCameraMode()
end

-- INVISIBILITY SYSTEM
local function setupInvisibility(state)
    clearConnection("invisibility")
    
    local char = getCharacter()
    if not char then return end
    
    -- Przywróć widoczność
    for _, data in pairs(invisParts) do
        if data.part and data.part.Parent then
            data.part.Transparency = data.originalTransparency
            if data.part:IsA("MeshPart") or data.part:IsA("Part") then
                data.part.LocalTransparencyModifier = data.originalTransparency
            end
        end
    end
    
    for _, acc in pairs(char:GetChildren()) do
        if acc:IsA("Accessory") and acc:FindFirstChild("Handle") then
            acc.Handle.Transparency = 0
        end
    end
    
    local head = char:FindFirstChild("Head")
    if head and head:FindFirstChild("InvisiFace") then
        head.InvisiFace:Destroy()
        if head:FindFirstChild("OriginalFace") then
            head.OriginalFace.Name = "face"
        end
    end
    
    invisParts = {}
    
    if not state then return end
    
    -- WŁĄCZ NIEWIDZIALNOŚĆ
    for _, part in pairs(char:GetDescendants()) do
        if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
            table.insert(invisParts, {
                part = part,
                originalTransparency = part.Transparency
            })
            part.Transparency = 1
            part.LocalTransparencyModifier = 1
        end
    end
    
    for _, acc in pairs(char:GetChildren()) do
        if acc:IsA("Accessory") and acc:FindFirstChild("Handle") then
            acc.Handle.Transparency = 1
        end
    end
    
    if head and head:FindFirstChild("face") then
        head.face.Name = "OriginalFace"
        head.OriginalFace.Transparency = 1
        local invisFace = Instance.new("Decal", head)
        invisFace.Name = "InvisiFace"
        invisFace.Transparency = 1
    end
    
    connections.invisibility = RunService.Stepped:Connect(function()
        if not char or not char.Parent then
            clearConnection("invisibility")
            return
        end
        
        for _, part in pairs(char:GetDescendants()) do
            if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                part.Transparency = 1
                part.LocalTransparencyModifier = 1
            end
        end
        
        for _, acc in pairs(char:GetChildren()) do
            if acc:IsA("Accessory") and acc:FindFirstChild("Handle") then
                acc.Handle.Transparency = 1
            end
        end
        
        if head and head:FindFirstChild("OriginalFace") then
            head.OriginalFace.Transparency = 1
        end
    end)
end

local function toggleInvisibility(state)
    setupInvisibility(state)
end

-- FLY SYSTEM
local function setupFly(char)
    clearConnection("fly")

    local hrp = getRootPart(char)
    local hum = getHumanoid(char)

    if not hrp or not hum then return end

    for _, v in pairs(hrp:GetChildren()) do
        if v:IsA("BodyVelocity") or v:IsA("BodyGyro") then
            v:Destroy()
        end
    end

    if not settings.fly then
        hum.PlatformStand = false
        return
    end

    local bv = Instance.new("BodyVelocity", hrp)
    local bg = Instance.new("BodyGyro", hrp)

    bv:SetAttribute("OMNI", true)
    bg:SetAttribute("OMNI", true)

    bv.MaxForce = Vector3.new(1e9, 1e9, 1e9)
    bg.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
    bg.P = 9e4

    connections.fly = RunService.RenderStepped:Connect(function()
        if not hrp or not hrp.Parent or not hum or not hum.Parent then
            clearConnection("fly")
            return
        end

        hum.PlatformStand = true
        bg.CFrame = camera.CFrame

        local camCF = camera.CFrame
        local _, yaw, _ = camCF:ToEulerAnglesYXZ()
        local yawCFrame = CFrame.Angles(0, yaw, 0)
        local flatLook = yawCFrame.LookVector
        local flatRight = yawCFrame.RightVector

        -- Extract horizontal input from MoveDirection (PC + mobile joystick)
        local inputZ = hum.MoveDirection:Dot(flatLook)
        local inputX = hum.MoveDirection:Dot(flatRight)

        -- Reconstruct movement with full camera orientation (including pitch)
        local moveDir = camCF.LookVector * inputZ + camCF.RightVector * inputX

        -- Vertical: Space/Shift (PC) + Jump button (mobile)
        if UIS:IsKeyDown(Enum.KeyCode.Space) or hum.Jump then
            moveDir = moveDir + camCF.UpVector
        end
        if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then
            moveDir = moveDir - camCF.UpVector
        end

        if moveDir.Magnitude > 0.1 then
            bv.Velocity = moveDir.Unit * settings.flySpeed
        else
            bv.Velocity = Vector3.zero
        end
    end)
end

local function toggleFly(state)
    settings.fly = state
    local char = getCharacter()
    if char then
        setupFly(char)
    end
end

-- SPEED SYSTEM
local function setupSpeed(char)
    local hum = getHumanoid(char)
    if not hum then return end
    
    if settings.speed then
        hum.WalkSpeed = settings.speedValue
    else
        hum.WalkSpeed = 16
    end
end

local function setupSpeedLoop(char)
    clearConnection("speedLoop")

    if not settings.speed then return end

    local hum = getHumanoid(char)
    if not hum then return end

    connections.speedLoop = RunService.Heartbeat:Connect(function()
        if not hum or not hum.Parent then
            clearConnection("speedLoop")
            return
        end

        if settings.speed then
            hum.WalkSpeed = settings.speedValue
        end
    end)
end

local function toggleSpeed(state)
    settings.speed = state
    local char = getCharacter()
    if char then
        setupSpeed(char)
        if state then
            setupSpeedLoop(char)
        else
            clearConnection("speedLoop")
        end
    end
end

-- NOCLIP SYSTEM (POPRAWIONY)
local function setupNoclip()
    clearConnection("noclip")
    clearConnection("godlyNoclip")
    
    local char = player.Character
    
    -- Jeśli noclip został wyłączony, przywracamy kolizję
    if not settings.noclip and not settings.godlyNoclip then
        if char then
            for _, part in pairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = true
                end
            end
        end
        return 
    end
    
    local connName = settings.godlyNoclip and "godlyNoclip" or "noclip"
    
    connections[connName] = RunService.Stepped:Connect(function()
        if not char or not char.Parent then 
            clearConnection(connName)
            return 
        end
        
        for _, part in pairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
        
        if settings.godlyNoclip then
            local hum = getHumanoid(char)
            if hum then
                pcall(function()
                    hum:ChangeState(Enum.HumanoidStateType.Physics)
                end)
            end
        end
    end)
end

local function toggleNoclip(state)
    if state then
        settings.godlyNoclip = false
    end
    setupNoclip()
end

local function toggleGodlyNoclip(state)
    if state then
        settings.noclip = false
    end
    setupNoclip()
end

-- ANTI-RAGDOLL SYSTEM
local function setupAntiRagdoll(char)
    clearConnection("antiragdoll")
    
    if not settings.antiragdoll then return end
    
    local hum = getHumanoid(char)
    if not hum then return end
    
    -- Blokuj stany ragdoll
    local blockedStates = {
        Enum.HumanoidStateType.FallingDown,
        Enum.HumanoidStateType.Ragdoll,
        Enum.HumanoidStateType.GettingUp
    }
    
    connections.antiragdoll = RunService.Heartbeat:Connect(function()
        if not hum or not hum.Parent then
            clearConnection("antiragdoll")
            return
        end
        
        local currentState = hum:GetState()
        for _, state in ipairs(blockedStates) do
            if currentState == state then
                pcall(function()
                    hum:ChangeState(Enum.HumanoidStateType.Running)
                end)
                hum.PlatformStand = false
                break
            end
        end
        
        -- Dodatkowo: ustawiamy AutoRotate i PlatformStand
        pcall(function()
            hum.AutoRotate = true
            hum.PlatformStand = false
        end)
    end)
    
    -- Nasłuchuj zmian stanu
    hum.StateChanged:Connect(function(_, newState)
        if not settings.antiragdoll then return end
        for _, state in ipairs(blockedStates) do
            if newState == state then
                pcall(function()
                    hum:ChangeState(Enum.HumanoidStateType.Running)
                end)
                hum.PlatformStand = false
                break
            end
        end
    end)
end

local function toggleAntiRagdoll(state)
    settings.antiragdoll = state
    if state then
        local char = getCharacter()
        if char then
            setupAntiRagdoll(char)
        end
    else
        clearConnection("antiragdoll")
    end
end

-- FULLBRIGHT SYSTEM
local function setupFullbright()
    clearConnection("fullbright")
    
    if not settings.fullbright then
        -- Przywróć oryginalne ustawienia
        for prop, val in pairs(originalLighting) do
            pcall(function()
                Lighting[prop] = val
            end)
        end
        return
    end
    
    -- Zapisz oryginalne wartości (tylko raz)
    if not originalLighting.Brightness then
        originalLighting = {
            Brightness = Lighting.Brightness,
            ClockTime = Lighting.ClockTime,
            FogEnd = Lighting.FogEnd,
            FogStart = Lighting.FogStart,
            GlobalShadows = Lighting.GlobalShadows,
            OutdoorAmbient = Lighting.OutdoorAmbient,
            Ambient = Lighting.Ambient
        }
    end
    
    -- Ustaw pełne oświetlenie
    Lighting.Brightness = settings.brightnessValue
    Lighting.ClockTime = 12
    Lighting.FogEnd = 999999
    Lighting.FogStart = 0
    Lighting.GlobalShadows = false
    Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
    Lighting.Ambient = Color3.fromRGB(255, 255, 255)
    
    -- Ciągła aktualizacja (na wypadek zmian przez grę)
    connections.fullbright = RunService.Heartbeat:Connect(function()
        if not settings.fullbright then return end
        Lighting.Brightness = settings.brightnessValue
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 999999
        Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
        Lighting.Ambient = Color3.fromRGB(255, 255, 255)
    end)
end

local function toggleFullbright(state)
    settings.fullbright = state
    setupFullbright()
end

-- ANTI-GRAB & ANTI-CONTROL SYSTEM
local function setupAntiGrab(char)
    clearConnection("antigrab")
    
    if not settings.antigrab then return end
    if not char then return end
    
    local hrp = getRootPart(char)
    local hum = getHumanoid(char)
    if not hrp or not hum then return end
    
    local lastPos = hrp.Position
    local lastCFrame = hrp.CFrame
    
    connections.antigrab = RunService.Heartbeat:Connect(function()
        if not char or not char.Parent then
            clearConnection("antigrab")
            return
        end
        
        -- 1. Anti-Anchor: odanchorowuj wszystkie części naszego charakteru
        for _, part in pairs(char:GetDescendants()) do
            if part:IsA("BasePart") and part.Anchored then
                part.Anchored = false
            end
        end
        
        -- 2. Anti-BodyMovers: niszcz obce BodyMovers (nie oznaczone OMNI)
        for _, part in pairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                for _, child in pairs(part:GetChildren()) do
                    if (child:IsA("BodyVelocity") or child:IsA("BodyPosition") or 
                        child:IsA("BodyGyro") or child:IsA("BodyThrust") or 
                        child:IsA("RocketPropulsion")) and not child:GetAttribute("OMNI") then
                        child:Destroy()
                    end
                end
            end
        end
        
        -- 3. Anti-Weld/Grab: rozwalamy weldy z obcymi graczami
        for _, weld in pairs(char:GetDescendants()) do
            if weld:IsA("Weld") or weld:IsA("WeldConstraint") or weld:IsA("Motor6D") then
                local hasForeign = false
                
                local p0 = weld.Part0
                local p1 = weld.Part1
                
                if p0 and not p0:IsDescendantOf(char) then
                    local model = p0:FindFirstAncestorOfClass("Model")
                    if model and Players:GetPlayerFromCharacter(model) and Players:GetPlayerFromCharacter(model) ~= player then
                        hasForeign = true
                    end
                end
                
                if p1 and not p1:IsDescendantOf(char) then
                    local model = p1:FindFirstAncestorOfClass("Model")
                    if model and Players:GetPlayerFromCharacter(model) and Players:GetPlayerFromCharacter(model) ~= player then
                        hasForeign = true
                    end
                end
                
                if hasForeign then
                    weld:Destroy()
                end
            end
        end
        
        -- 4. Anti-PlatformStand / Anti-Sit: blokujemy blokowanie ruchów
        if hum.PlatformStand then
            hum.PlatformStand = false
        end
        if hum.Sit then
            hum.Sit = false
        end
        hum.AutoRotate = true
        
        -- 5. Anti-Fling: resetujemy gwałtowną prędkość
        if hrp.AssemblyLinearVelocity.Magnitude > 500 or hrp.AssemblyAngularVelocity.Magnitude > 500 then
            hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
            hrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
        end
        
        -- 6. Anti-Teleport: jeśli ktoś nas teleportuje gwałtownie (>300 studów w 1 klatce)
        -- Pomijamy gdy używamy własnych systemów ruchu lub latamy
        if not settings.fly and not settings.noclip and not settings.godlyNoclip then
            local currentPos = hrp.Position
            local dist = (currentPos - lastPos).Magnitude
            
            -- Sprawdź czy to nagły teleport (a nie normalny ruch/spadek)
            if dist > 300 and hum.MoveDirection.Magnitude < 0.1 then
                -- Przywróć ostatnią znaną pozycję
                hrp.CFrame = lastCFrame
            else
                lastPos = currentPos
                lastCFrame = hrp.CFrame
            end
        else
            lastPos = hrp.Position
            lastCFrame = hrp.CFrame
        end
    end)
end

local function toggleAntiGrab(state)
    settings.antigrab = state
    if state then
        local char = getCharacter()
        if char then
            setupAntiGrab(char)
        end
    else
        clearConnection("antigrab")
    end
end

-- ESP SYSTEM
local function clearESP()
    for _, obj in pairs(espObjects) do
        if obj and obj.Parent then
            obj:Destroy()
        end
    end
    espObjects = {}
end

local function updateESP()
    if not settings.esp then
        clearESP()
        return
    end
    
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= player and p.Character then
            local char = p.Character
            local existing = char:FindFirstChild("OmniESP")
            
            if not existing then
                local h = Instance.new("Highlight", char)
                h.Name = "OmniESP"
                h.FillColor = Color3.fromRGB(0, 120, 255)
                h.FillTransparency = 0.6
                h.OutlineColor = Color3.fromRGB(255, 255, 255)
                h.OutlineTransparency = 0.4
                table.insert(espObjects, h)
            end
        end
    end
end

local function toggleESP(state)
    if state then
        connections.esp = RunService.Heartbeat:Connect(updateESP)
    else
        clearConnection("esp")
        clearESP()
    end
end

-- KILL AURA SYSTEM
local function performKillAura()
    local char = getCharacter()
    local hrp = getRootPart(char)
    local myHum = getHumanoid(char)
    
    if not hrp or not myHum then return end
    
    local tool = char:FindFirstChildOfClass("Tool")
    if not tool then
        for _, item in pairs(player.Backpack:GetChildren()) do
            if item:IsA("Tool") then
                myHum:EquipTool(item)
                tool = item
                break
            end
        end
    end
    
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= player and p.Character then
            local enemyHrp = getRootPart(p.Character)
            local enemyHum = getHumanoid(p.Character)
            
            if enemyHrp and enemyHum and enemyHum.Health > 0 then
                local distance = (hrp.Position - enemyHrp.Position).Magnitude
                
                if distance <= settings.auraRange then
                    if tool and tool:FindFirstChild("Handle") then
                        pcall(function()
                            tool:Activate()
                        end)
                    end
                    
                    pcall(function()
                        for _, v in pairs(tool:GetDescendants()) do
                            if v:IsA("RemoteEvent") or v:IsA("RemoteFunction") then
                                v:FireServer(enemyHum)
                            end
                        end
                    end)
                end
            end
        end
    end
end

local function toggleKillAura(state)
    clearConnection("killaura")
    
    if state then
        connections.killaura = RunService.Heartbeat:Connect(function()
            pcall(performKillAura)
        end)
    end
end

-- CHARACTER RESPAWN HANDLER
local function onCharacterAdded(char)
    task.wait(0.5)
    
    if settings.fly then setupFly(char) end
    if settings.speed then 
        setupSpeed(char) 
        setupSpeedLoop(char)
    end
    if settings.noclip or settings.godlyNoclip then setupNoclip() end
    if settings.force1st or settings.force3rd then setupCameraMode() end
    if settings.invisibility then setupInvisibility(true) end
    if settings.antiragdoll then setupAntiRagdoll(char) end
    if settings.antigrab then setupAntiGrab(char) end
end

player.CharacterAdded:Connect(onCharacterAdded)

-- UI BUTTONS
createButton("✈ Flight System", "fly", toggleFly)
createSlider("Fly Speed", 10, 3000, "flySpeed", nil)

createButton("🏃 Super Speed", "speed", toggleSpeed)
createSlider("Speed Value", 16, 500, "speedValue", function(val)
    if settings.speed then
        local char = getCharacter()
        local hum = getHumanoid(char)
        if hum then hum.WalkSpeed = val end
    end
end)

createButton("👻 Standard Noclip", "noclip", toggleNoclip)
createButton("🌟 Godly Physics Bypass", "godlyNoclip", toggleGodlyNoclip)

createButton("👁 Force 1st Person", "force1st", toggleForce1st)
createButton("🎥 Force 3rd Person", "force3rd", toggleForce3rd)

createButton("💨 Invisibility", "invisibility", toggleInvisibility)

createButton("🦴 Anti-Ragdoll", "antiragdoll", toggleAntiRagdoll)
createButton("☀ Fullbright", "fullbright", toggleFullbright)
createSlider("Brightness", 1, 20, "brightnessValue", function(val)
    if settings.fullbright then
        Lighting.Brightness = val
    end
end)
createButton("🛡️ Anti-Grab & Control", "antigrab", toggleAntiGrab)

createButton("⚔ Kill Aura", "killaura", toggleKillAura)
createSlider("Aura Range", 5, 50, "auraRange", nil)

createButton("🎨 Player Visuals (ESP)", "esp", toggleESP)

-- TELEPORT MENU (DRAGGABLE)
createButton("📍 Teleport to Player", "none", function()
    if ScreenGui:FindFirstChild("TPMenu") then 
        ScreenGui.TPMenu:Destroy() 
        return 
    end
    
    local pFrame = Instance.new("Frame", ScreenGui)
    pFrame.Name = "TPMenu"
    pFrame.Size = UDim2.new(0, 220, 0, 320)
    
    local screenWidth = camera.ViewportSize.X
    local mainPos = MainFrame.AbsolutePosition
    local targetX = mainPos.X + MainFrame.AbsoluteSize.X + 10
    if targetX + 220 > screenWidth then targetX = mainPos.X - 230 end
    
    pFrame.Position = UDim2.new(0, targetX, 0, mainPos.Y)
    pFrame.BackgroundColor3 = Color3.fromRGB(12, 13, 17)
    pFrame.ZIndex = 60
    Instance.new("UICorner", pFrame)
    
    local s = Instance.new("UIStroke", pFrame)
    s.Color = Color3.fromRGB(0, 120, 255)
    s.Thickness = 1.8

    -- DRAG HEADER
    local dragHeader = Instance.new("Frame", pFrame)
    dragHeader.Size = UDim2.new(1, 0, 0, 30)
    dragHeader.BackgroundColor3 = Color3.fromRGB(18, 20, 24)
    dragHeader.BorderSizePixel = 0
    dragHeader.ZIndex = 65
    Instance.new("UICorner", dragHeader)
    
    local headerTitle = Instance.new("TextLabel", dragHeader)
    headerTitle.Size = UDim2.new(1, -10, 1, 0)
    headerTitle.Position = UDim2.new(0, 10, 0, 0)
    headerTitle.BackgroundTransparency = 1
    headerTitle.Text = "Teleport Menu"
    headerTitle.TextColor3 = Color3.fromRGB(200, 200, 200)
    headerTitle.Font = Enum.Font.GothamBold
    headerTitle.TextSize = 12
    headerTitle.TextXAlignment = Enum.TextXAlignment.Left
    headerTitle.ZIndex = 66

    -- DRAG LOGIC
    local d_dragging, d_dragStart, d_startPos
    dragHeader.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            d_dragging = true
            d_dragStart = input.Position
            d_startPos = pFrame.Position
        end
    end)
    UIS.InputChanged:Connect(function(input)
        if d_dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - d_dragStart
            pFrame.Position = UDim2.new(d_startPos.X.Scale, d_startPos.X.Offset + delta.X, d_startPos.Y.Scale, d_startPos.Y.Offset + delta.Y)
        end
    end)
    dragHeader.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then 
            d_dragging = false 
        end
    end)

    local sc = Instance.new("ScrollingFrame", pFrame)
    sc.Size = UDim2.new(1, -10, 1, -40)
    sc.Position = UDim2.new(0, 5, 0, 35)
    sc.BackgroundTransparency = 1
    sc.ScrollBarThickness = 3
    sc.ScrollBarImageColor3 = Color3.fromRGB(0, 120, 255)
    sc.ZIndex = 61
    sc.CanvasSize = UDim2.new(0, 0, 0, 0)
    
    local l = Instance.new("UIListLayout", sc)
    l.Padding = UDim.new(0, 6)
    l.HorizontalAlignment = Enum.HorizontalAlignment.Center

    l:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        sc.CanvasSize = UDim2.new(0, 0, 0, l.AbsoluteContentSize.Y + 10)
    end)

    local function refreshPlayerList()
        for _, child in pairs(sc:GetChildren()) do
            if child:IsA("TextButton") then child:Destroy() end
        end
        
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= player then
                local b = Instance.new("TextButton", sc)
                b.Size = UDim2.new(0.9, 0, 0, 38)
                b.BackgroundColor3 = Color3.fromRGB(28, 30, 36)
                b.Text = (p.DisplayName or p.Name) .. " (@" .. p.Name .. ")"
                b.TextColor3 = Color3.new(1, 1, 1)
                b.Font = Enum.Font.GothamMedium
                b.TextSize = 11
                b.ZIndex = 62
                Instance.new("UICorner", b).CornerRadius = UDim.new(0, 4)
                
                b.MouseButton1Click:Connect(function()
                    local targetChar = p.Character
                    local targetHrp = getRootPart(targetChar)
                    local myChar = getCharacter()
                    local myHrp = getRootPart(myChar)
                    
                    if targetHrp and myHrp then
                        myHrp.CFrame = targetHrp.CFrame * CFrame.new(0, 0, 3)
                    end
                    pFrame:Destroy()
                end)
            end
        end
    end
    
    refreshPlayerList()
    
    local playerConn1 = Players.PlayerAdded:Connect(refreshPlayerList)
    local playerConn2 = Players.PlayerRemoving:Connect(refreshPlayerList)
    
    pFrame.Destroying:Connect(function()
        playerConn1:Disconnect()
        playerConn2:Disconnect()
    end)
end)

-- SERVER HOP
createButton("🌌 Server Hop", "none", function()
    pcall(function()
        local url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"
        local success, result = pcall(function()
            return HttpService:JSONDecode(game:HttpGet(url))
        end)
        
        if success and result.data then
            for _, server in pairs(result.data) do
                if server.playing < server.maxPlayers and server.id ~= game.JobId then
                    TeleportService:TeleportToPlaceInstance(game.PlaceId, server.id, player)
                    return
                end
            end
            warn("[OMNI] No available servers found")
        else
            warn("[OMNI] Failed to fetch servers")
        end
    end)
end)

createButton("🔄 Server Rejoin", "none", function() 
    TeleportService:Teleport(game.PlaceId, player) 
end)

-- CANVAS SIZE AUTO-UPDATE
UIList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    Scroll.CanvasSize = UDim2.new(0, 0, 0, UIList.AbsoluteContentSize.Y + 20)
end)

-- CLEANUP ON SCRIPT REMOVAL
ScreenGui.Destroying:Connect(function()
    for name, conn in pairs(connections) do
        conn:Disconnect()
    end
    clearESP()
    
    -- Reset camera
    player.CameraMaxZoomDistance = 128
    player.CameraMinZoomDistance = 0.5
    local char = getCharacter()
    local hum = getHumanoid(char)
    if hum then
        hum.CameraOffset = Vector3.new(0, 0, 0)
    end
    
    -- Reset invisibility
    setupInvisibility(false)
    
    -- Reset fullbright
    settings.fullbright = false
    setupFullbright()
    
    -- Reset antigrab
    settings.antigrab = false
    clearConnection("antigrab")

    -- Reset speed loop
    clearConnection("speedLoop")
end)

print("[OMNI PRO] v18.2.3 LOADED - ALL SYSTEMS OPERATIONAL")
