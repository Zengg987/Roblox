local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "Universal Script Hub",
    LoadingTitle = "Utility Hub",
    LoadingSubtitle = "Fly, Speed, Jump, ESP",
    ConfigurationSaving = {
        Enabled = false,
        FolderName = nil,
        FileName = "ScriptHubConfig"
    }
})

-- ======================
-- CREATE TABS
-- ======================
local MovementTab = Window:CreateTab("Movement", "rocket")
local VisualsTab = Window:CreateTab("Visuals", "eye")
local PlayerTab = Window:CreateTab("Player", "user")
local UtilityTab = Window:CreateTab("Utility", "wrench")
local TrollTab   = Window:CreateTab("Troll", "skull")

---------------------------------------------------------
-- MOVEMENT TAB
---------------------------------------------------------
-- Fly
local flying = false
local flySpeed = 50
local flyConnection

local function startFlying()
    local player = game.Players.LocalPlayer
    local char = player.Character or player.CharacterAdded:Wait()
    local hum = char:WaitForChild("HumanoidRootPart")

    flying = true
    flyConnection = game:GetService("RunService").RenderStepped:Connect(function()
        local cam = workspace.CurrentCamera
        local move = Vector3.new()

        if game.UserInputService:IsKeyDown(Enum.KeyCode.W) then
            move = move + cam.CFrame.LookVector
        end
        if game.UserInputService:IsKeyDown(Enum.KeyCode.S) then
            move = move - cam.CFrame.LookVector
        end
        if game.UserInputService:IsKeyDown(Enum.KeyCode.A) then
            move = move - cam.CFrame.RightVector
        end
        if game.UserInputService:IsKeyDown(Enum.KeyCode.D) then
            move = move + cam.CFrame.RightVector
        end
        if game.UserInputService:IsKeyDown(Enum.KeyCode.Space) then
            move = move + Vector3.new(0,1,0)
        end
        if game.UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
            move = move - Vector3.new(0,1,0)
        end

        hum.Velocity = move.Magnitude > 0 and move.Unit * flySpeed or Vector3.zero
    end)
end

local function stopFlying()
    flying = false
    if flyConnection then flyConnection:Disconnect() end
    local char = game.Players.LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        char.HumanoidRootPart.Velocity = Vector3.zero
    end
end

MovementTab:CreateToggle({
    Name = "Fly",
    CurrentValue = false,
    Callback = function(Value)
        if Value then startFlying() else stopFlying() end
    end,
})

MovementTab:CreateSlider({
    Name = "Fly Speed",
    Range = {10, 300},
    Increment = 5,
    CurrentValue = 50,
    Callback = function(Value)
        flySpeed = Value
    end,
})

-- WalkSpeed
local humanoid = game.Players.LocalPlayer.Character:WaitForChild("Humanoid")

MovementTab:CreateSlider({
    Name = "WalkSpeed",
    Range = {16, 200},
    Increment = 1,
    CurrentValue = 16,
    Callback = function(Value)
        humanoid.WalkSpeed = Value
    end,
})

-- Jump Power
MovementTab:CreateSlider({
    Name = "Jump Power",
    Range = {50, 300},
    Increment = 5,
    CurrentValue = 50,
    Callback = function(Value)
        humanoid.JumpPower = Value
    end,
})

-- Infinite Jump
local infiniteJumpEnabled = false
local userInput = game:GetService("UserInputService")

userInput.JumpRequest:Connect(function()
    if infiniteJumpEnabled then
        local char = game.Players.LocalPlayer.Character
        if char and char:FindFirstChild("Humanoid") then
            char.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end)

MovementTab:CreateToggle({
    Name = "Infinite Jump",
    CurrentValue = false,
    Callback = function(Value)
        infiniteJumpEnabled = Value
    end,
})

-- Noclip
local noclip = false
local noclipConnection

local function startNoclip()
    noclip = true
    noclipConnection = game:GetService("RunService").Stepped:Connect(function()
        local char = game.Players.LocalPlayer.Character
        if char then
            for _, v in ipairs(char:GetDescendants()) do
                if v:IsA("BasePart") then
                    v.CanCollide = false
                end
            end
        end
    end)
end

local function stopNoclip()
    noclip = false
    if noclipConnection then noclipConnection:Disconnect() end
end

MovementTab:CreateToggle({
    Name = "Noclip",
    CurrentValue = false,
    Callback = function(Value)
        if Value then startNoclip() else stopNoclip() end
    end,
})

-- Teleport Tool
local function giveTeleportTool()
    local tool = Instance.new("Tool")
    tool.RequiresHandle = false
    tool.Name = "Click TP"
    tool.Activated:Connect(function()
        local mouse = game.Players.LocalPlayer:GetMouse()
        local char = game.Players.LocalPlayer.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            char.HumanoidRootPart.CFrame = CFrame.new(mouse.Hit.p + Vector3.new(0, 3, 0))
        end
    end)
    tool.Parent = game.Players.LocalPlayer.Backpack
end

MovementTab:CreateButton({
    Name = "Give Teleport Tool",
    Callback = function()
        giveTeleportTool()
    end,
})

---------------------------------------------------------
-- VISUALS TAB
---------------------------------------------------------
local espFolder = Instance.new("Folder", game.CoreGui)
espFolder.Name = "ESPFolder"
local espEnabled = false

local function createESP(player)
    if player == game.Players.LocalPlayer then return end
    local highlight = Instance.new("Highlight")
    highlight.Parent = espFolder
    highlight.Adornee = player.Character
    highlight.FillColor = Color3.fromRGB(255, 0, 0)
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Name = player.Name .. "_ESP"
end

local function disableESP()
    espEnabled = false
    espFolder:ClearAllChildren()
end

VisualsTab:CreateToggle({
    Name = "ESP Players",
    CurrentValue = false,
    Callback = function(Value)
        if Value then
            espEnabled = true
            for _, player in ipairs(game.Players:GetPlayers()) do
                if player.Character then createESP(player) end
            end
        else
            disableESP()
        end
    end,
})

-- Fullbright
local lighting = game:GetService("Lighting")
local oldValues = {}
local fullbright = false

local function enableFullbright()
    fullbright = true
    oldValues.Brightness = lighting.Brightness
    oldValues.Ambient = lighting.Ambient
    oldValues.ClockTime = lighting.ClockTime
    lighting.Brightness = 2
    lighting.Ambient = Color3.new(1,1,1)
    lighting.ClockTime = 12
end

local function disableFullbright()
    fullbright = false
    if oldValues.Brightness then
        lighting.Brightness = oldValues.Brightness
        lighting.Ambient = oldValues.Ambient
        lighting.ClockTime = oldValues.ClockTime
    end
end

VisualsTab:CreateToggle({
    Name = "Fullbright",
    CurrentValue = false,
    Callback = function(Value)
        if Value then enableFullbright() else disableFullbright() end
    end,
})

---------------------------------------------------------
-- PLAYER TAB
---------------------------------------------------------
-- GodMode
local godEnabled = false
local godConnection

local function startGodMode()
    godEnabled = true
    local player = game.Players.LocalPlayer
    local char = player.Character or player.CharacterAdded:Wait()
    local hum = char:WaitForChild("Humanoid")

    godConnection = game:GetService("RunService").Heartbeat:Connect(function()
        if hum and hum.Health > 0 then
            hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
            hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
            hum:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
            if hum.Health < hum.MaxHealth then
                hum.Health = hum.MaxHealth
            end
        end
    end)
end

local function stopGodMode()
    godEnabled = false
    if godConnection then godConnection:Disconnect() end
end

PlayerTab:CreateToggle({
    Name = "GodMode",
    CurrentValue = false,
    Callback = function(Value)
        if Value then startGodMode() else stopGodMode() end
    end,
})

-- Anti AFK
local antiAFK = false
local vu = game:GetService("VirtualUser")

PlayerTab:CreateToggle({
    Name = "Anti AFK",
    CurrentValue = false,
    Callback = function(Value)
        antiAFK = Value
        if Value then
            game.Players.LocalPlayer.Idled:Connect(function()
                if antiAFK then
                    vu:CaptureController()
                    vu:ClickButton2(Vector2.new())
                end
            end)
        end
    end,
})

---------------------------------------------------------
-- UTILITY TAB
---------------------------------------------------------
local waypointX, waypointY, waypointZ = 0,0,0

UtilityTab:CreateInput({
    Name = "X Coordinate",
    PlaceholderText = "Enter X",
    Callback = function(Text) waypointX = tonumber(Text) or 0 end,
})

UtilityTab:CreateInput({
    Name = "Y Coordinate",
    PlaceholderText = "Enter Y",
    Callback = function(Text) waypointY = tonumber(Text) or 0 end,
})

UtilityTab:CreateInput({
    Name = "Z Coordinate",
    PlaceholderText = "Enter Z",
    Callback = function(Text) waypointZ = tonumber(Text) or 0 end,
})

UtilityTab:CreateButton({
    Name = "Teleport to Waypoint",
    Callback = function()
        local char = game.Players.LocalPlayer.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            char.HumanoidRootPart.CFrame = CFrame.new(waypointX, waypointY, waypointZ)
        end
    end,
})

-- Loop Heal / Damage
local loopHeal = false
local loopDamage = false
local loopDamageTarget = nil
local loopConnection
local damageDropdown

local function getPlayerNames()
    local names = {}
    for _, plr in ipairs(game.Players:GetPlayers()) do
        if plr ~= game.Players.LocalPlayer then
            table.insert(names, plr.Name)
        end
    end
    return names
end

-- Normal Dropdown (auto-refreshing)
damageDropdown = UtilityTab:CreateDropdown({
    Name = "Select Target",
    Options = getPlayerNames(),
    CurrentOption = "",
    Callback = function(Option)
        loopDamageTarget = game.Players:FindFirstChild(Option)
    end,
})

-- Auto-update player list when someone joins/leaves
local function refreshDamageDropdown()
    if damageDropdown then
        damageDropdown:Set({Options = getPlayerNames(), CurrentOption = ""})
    end
end

game.Players.PlayerAdded:Connect(refreshDamageDropdown)
game.Players.PlayerRemoving:Connect(refreshDamageDropdown)

-- Loop logic
local function startLoop()
    if loopConnection then loopConnection:Disconnect() end
    loopConnection = game:GetService("RunService").Heartbeat:Connect(function()
        local lp = game.Players.LocalPlayer
        local char = lp.Character
        if loopHeal and char and char:FindFirstChild("Humanoid") then
            char.Humanoid.Health = char.Humanoid.MaxHealth
        end
        if loopDamage and loopDamageTarget and loopDamageTarget.Character then
            local hum = loopDamageTarget.Character:FindFirstChild("Humanoid")
            if hum then hum.Health = hum.Health - 5 end
        end
    end)
end

UtilityTab:CreateToggle({
    Name = "Loop Heal",
    CurrentValue = false,
    Callback = function(Value)
        loopHeal = Value
        startLoop()
    end,
})

UtilityTab:CreateToggle({
    Name = "Loop Damage Target",
    CurrentValue = false,
    Callback = function(Value)
        loopDamage = Value
        startLoop()
    end,
})


---------------------------------------------------------
-- TROLL TAB
---------------------------------------------------------
local trollTarget = nil
local trollDropdown

local function refreshTrollTargets()
    local names = {}
    for _, plr in ipairs(game.Players:GetPlayers()) do
        if plr ~= game.Players.LocalPlayer then
            table.insert(names, plr.Name)
        end
    end
    if trollDropdown then
        trollDropdown:Set({Options = names, CurrentOption = ""})
    end
    return names
end

trollDropdown = TrollTab:CreateDropdown({
    Name = "Select Target",
    Options = refreshTrollTargets(),
    CurrentOption = "",
    Callback = function(Option)
        trollTarget = game.Players:FindFirstChild(Option)
    end,
})

game.Players.PlayerAdded:Connect(function() refreshTrollTargets() end)
game.Players.PlayerRemoving:Connect(function() refreshTrollTargets() end)

-- Fling Target
TrollTab:CreateButton({
    Name = "Fling Target",
    Callback = function()
        if trollTarget and trollTarget.Character and trollTarget.Character:FindFirstChild("HumanoidRootPart") then
            local hrp = game.Players.LocalPlayer.Character.HumanoidRootPart
            local targetHrp = trollTarget.Character.HumanoidRootPart
            hrp.CFrame = targetHrp.CFrame
            task.spawn(function()
                for i = 1, 100 do
                    hrp.Velocity = Vector3.new(9999, 9999, 9999)
                    task.wait(0.05)
                end
            end)
        end
    end,
})

-- Sit Spam
local sitSpamming = false
TrollTab:CreateToggle({
    Name = "Sit Spam",
    CurrentValue = false,
    Callback = function(Value)
        sitSpamming = Value
        task.spawn(function()
            while sitSpamming do
                local char = game.Players.LocalPlayer.Character
                if char and char:FindFirstChild("Humanoid") then
                    char.Humanoid.Sit = true
                    task.wait(0.3)
                    char.Humanoid.Sit = false
                end
                task.wait(0.3)
            end
        end)
    end,
})

-- Fake Lag
local fakeLagEnabled = false
TrollTab:CreateToggle({
    Name = "Fake Lag",
    CurrentValue = false,
    Callback = function(Value)
        fakeLagEnabled = Value
        local char = game.Players.LocalPlayer.Character
        if not char then return end
        local hrp = char:WaitForChild("HumanoidRootPart")
        task.spawn(function()
            while fakeLagEnabled do
                hrp.Anchored = true
                task.wait(1)
                hrp.Anchored = false
                task.wait(0.2)
            end
        end)
    end,
})

-- ===== Aim Helper (visual-only) =====
-- toggled in VisualsTab, does NOT move camera or fire
local aimHelperEnabled = false
local aimGui = Instance.new("ScreenGui")
aimGui.Name = "AimHelperGui"
aimGui.ResetOnSpawn = false
aimGui.Parent = game.CoreGui

local aimDot = Instance.new("Frame")
aimDot.Name = "AimDot"
aimDot.Size = UDim2.new(0, 14, 0, 14)
aimDot.AnchorPoint = Vector2.new(0.5, 0.5)
aimDot.BackgroundTransparency = 0
aimDot.BorderSizePixel = 0
aimDot.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
aimDot.Visible = false
aimDot.Parent = aimGui
aimDot.ZIndex = 9999
aimDot.Rotation = 0
aimDot:SetAttribute("IsIndicator", true)

local aimLabel = Instance.new("TextLabel")
aimLabel.Name = "AimLabel"
aimLabel.Size = UDim2.new(0, 180, 0, 24)
aimLabel.AnchorPoint = Vector2.new(0.5, -0.7)
aimLabel.BackgroundTransparency = 1
aimLabel.TextColor3 = Color3.new(1,1,1)
aimLabel.TextStrokeTransparency = 0.6
aimLabel.TextScaled = true
aimLabel.Font = Enum.Font.SourceSansSemibold
aimLabel.Visible = false
aimLabel.Parent = aimGui
aimLabel.ZIndex = 9999
aimLabel:SetAttribute("IsIndicatorText", true)

-- Helper: returns best candidate player (nearest to center of screen and in line of sight optionally)
local function getBestTarget()
    local localPlayer = game.Players.LocalPlayer
    local cam = workspace.CurrentCamera
    if not cam then return nil end

    local best = nil
    local bestScore = math.huge

    for _, plr in ipairs(game.Players:GetPlayers()) do
        if plr ~= localPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
            local hrp = plr.Character.HumanoidRootPart
            local screenPos, onScreen = cam:WorldToViewportPoint(hrp.Position)
            if onScreen then
                -- score: distance from screen center (smaller is better)
                local dx = screenPos.X - (cam.ViewportSize.X / 2)
                local dy = screenPos.Y - (cam.ViewportSize.Y / 2)
                local distToCenter = math.sqrt(dx*dx + dy*dy)

                -- optional: occlusion check (raycast) - keeps it lightweight and safe
                local rayOrigin = cam.CFrame.Position
                local dir = (hrp.Position - rayOrigin)
                local rayParams = RaycastParams.new()
                rayParams.FilterDescendantsInstances = {localPlayer.Character}
                rayParams.FilterType = Enum.RaycastFilterType.Blacklist
                rayParams.IgnoreWater = true
                local ray = workspace:Raycast(rayOrigin, dir, rayParams)
                local visible = true
                if ray then
                    -- if something hit before the target (and it's not the target), consider occluded
                    local hitPart = ray.Instance
                    if hitPart and not hitPart:IsDescendantOf(plr.Character) then
                        visible = false
                    end
                end

                if visible and distToCenter < bestScore then
                    best = {player = plr, hrp = hrp, screen = screenPos}
                    bestScore = distToCenter
                end
            end
        end
    end

    return best
end

-- Update loop
local rs = game:GetService("RunService")
local updateConn = nil

local function startAimHelper()
    if updateConn then updateConn:Disconnect() end
    updateConn = rs.RenderStepped:Connect(function()
        if not aimHelperEnabled then return end
        local cam = workspace.CurrentCamera
        if not cam then return end

        local target = getBestTarget()
        if target then
            local sx, sy = target.screen.X, target.screen.Y
            aimDot.Position = UDim2.new(0, sx, 0, sy)
            aimDot.Visible = true

            aimLabel.Position = UDim2.new(0, sx, 0, sy - 30)
            local dist = (workspace.CurrentCamera.CFrame.Position - target.hrp.Position).Magnitude
            aimLabel.Text = string.format("%s (%.1fm)", target.player.Name, dist)
            aimLabel.Visible = true
        else
            aimDot.Visible = false
            aimLabel.Visible = false
        end
    end)
end

local function stopAimHelper()
    if updateConn then updateConn:Disconnect() updateConn = nil end
    aimDot.Visible = false
    aimLabel.Visible = false
end

-- Add toggle under VisualsTab
VisualsTab:CreateToggle({
    Name = "Aim Helper (visual only)",
    CurrentValue = false,
    Callback = function(Value)
        aimHelperEnabled = Value
        if Value then
            startAimHelper()
        else
            stopAimHelper()
        end
    end,
})

-- Auto-refresh isn't required for this visual helper because getBestTarget() reads Players live.
-- But in case you want to clear GUI on player leave/join, do:
game.Players.PlayerRemoving:Connect(function() 
    -- nothing to change for dropdowns; GUI updates automatically
end)
game.Players.PlayerAdded:Connect(function()
    -- nothing required, getBestTarget sees new players automatically
end)

---------------------------------------------------------
-- COMBAT TAB
---------------------------------------------------------
local CombatTab = Window:CreateTab("Combat", "sword")

-- Bullet No-Clip
local BulletNoClipEnabled = false
local oldRaycast

CombatTab:CreateToggle({
    Name = "Bullet No-Clip",
    CurrentValue = false,
    Callback = function(state)
        BulletNoClipEnabled = state
        if state then
            if not oldRaycast then
                oldRaycast = workspace.Raycast
                workspace.Raycast = function(self, origin, direction, params)
                    if BulletNoClipEnabled and params then
                        params.FilterType = Enum.RaycastFilterType.Blacklist
                        local ignoreList = {}
                        for _, obj in ipairs(workspace:GetChildren()) do
                            if obj:IsA("Model") and (obj.Name:lower():find("map") or obj.Name:lower():find("wall")) then
                                table.insert(ignoreList, obj)
                            end
                        end
                        params.FilterDescendantsInstances = ignoreList
                    end
                    return oldRaycast(self, origin, direction, params)
                end
            end
        else
            if oldRaycast then
                workspace.Raycast = oldRaycast
            end
        end
    end,
})

-- GodMode (Shooter Safe)
local combatGodEnabled = false
local connections = {}

local function startCombatGod()
    combatGodEnabled = true

    -- Heal humanoid constantly
    task.spawn(function()
        while combatGodEnabled do
            local char = game.Players.LocalPlayer.Character
            if char and char:FindFirstChild("Humanoid") then
                char.Humanoid.Health = char.Humanoid.MaxHealth
            end
            task.wait(0.3)
        end
    end)

    -- Block damage remotes
    local rs = game:GetService("ReplicatedStorage")
    for _, obj in ipairs(rs:GetDescendants()) do
        if obj:IsA("RemoteEvent") and (obj.Name:lower():find("damage") or obj.Name:lower():find("hit")) then
            local conn = obj.OnClientEvent:Connect(function()
                if combatGodEnabled then
                    return nil
                end
            end)
            table.insert(connections, conn)
        end
    end
end

local function stopCombatGod()
    combatGodEnabled = false
    for _, c in ipairs(connections) do
        c:Disconnect()
    end
    connections = {}
end

CombatTab:CreateToggle({
    Name = "GodMode (Shooter Safe)",
    CurrentValue = false,
    Callback = function(state)
        if state then
            startCombatGod()
        else
            stopCombatGod()
        end
    end,
})

---------------------------------------------------------
-- FIXED VISUALS ESP (friends = green, enemies = red)
---------------------------------------------------------
local function createESP(player)
    if player == game.Players.LocalPlayer then return end

    local highlight = Instance.new("Highlight")
    highlight.Name = player.Name .. "_ESP"
    highlight.Adornee = player.Character
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = espFolder

    -- Friend or enemy color
    if player.Team ~= nil and game.Players.LocalPlayer.Team ~= nil then
        if player.Team == game.Players.LocalPlayer.Team then
            highlight.FillColor = Color3.fromRGB(0, 255, 0) -- green
        else
            highlight.FillColor = Color3.fromRGB(255, 0, 0) -- red
        end
    else
        highlight.FillColor = Color3.fromRGB(255, 0, 0) -- default red
    end

    -- Update color on team change
    player:GetPropertyChangedSignal("Team"):Connect(function()
        if highlight then
            if player.Team == game.Players.LocalPlayer.Team then
                highlight.FillColor = Color3.fromRGB(0, 255, 0)
            else
                highlight.FillColor = Color3.fromRGB(255, 0, 0)
            end
        end
    end)
end

-- Refresh ESP when new players join
game.Players.PlayerAdded:Connect(function(plr)
    if espEnabled and plr.Character then
        createESP(plr)
        plr.CharacterAdded:Connect(function()
            task.wait(1)
            if espEnabled then createESP(plr) end
        end)
    end
end)


