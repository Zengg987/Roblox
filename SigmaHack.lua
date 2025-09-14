local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "Sigma Script",
   LoadingTitle = "Only Sigma Use This!",
   LoadingSubtitle = "by Zen",
   Theme = "Dark", -- Using Dark theme for better visuals
   ToggleUIKeybind = "K"-- Use Enum.KeyCode for robustness
})

local MainTab = Window:CreateTab("Main", "gamepad") -- LUDICE ICON: gamepad

-- Add a notification to inform the user how to open the menu
Rayfield:Notify({
   Title = "Script Loaded!",
   Content = "Press Right-Shift to open/close the menu.",
   Duration = 10,
   Image = "info" -- Lucide icon
})

-- --- PLAYER SECTION ---
local PlayerSection = MainTab:CreateSection("Player")

-- Local Player Reference
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local RootPart = Character:WaitForChild("HumanoidRootPart")

-- WalkSpeed Toggle and Slider
local WalkSpeedEnabled = false
local OriginalWalkSpeed = Humanoid.WalkSpeed
MainTab:CreateToggle({
   Name = "WalkSpeed Toggle",
   CurrentValue = false,
   Flag = "WalkSpeedToggle",
   Callback = function(Value)
       WalkSpeedEnabled = Value
       if not Value then
           Humanoid.WalkSpeed = OriginalWalkSpeed
       else
           Humanoid.WalkSpeed = Rayfield.Flags["WalkSpeedSlider"] or 16 -- Apply current slider value if enabled
       end
   end,
})

MainTab:CreateSlider({
   Name = "WalkSpeed Slider",
   Range = {16, 200},
   Increment = 1,
   Suffix = " studs/s",
   CurrentValue = 16,
   Flag = "WalkSpeedSlider",
   Callback = function(Value)
       if WalkSpeedEnabled then
           Humanoid.WalkSpeed = Value
       end
   end,
})

-- JumpPower Toggle and Slider
local JumpPowerEnabled = false
local OriginalJumpPower = Humanoid.JumpPower
MainTab:CreateToggle({
   Name = "JumpPower Toggle",
   CurrentValue = false,
   Flag = "JumpPowerToggle",
   Callback = function(Value)
       JumpPowerEnabled = Value
       if not Value then
           Humanoid.JumpPower = OriginalJumpPower
       else
           Humanoid.JumpPower = Rayfield.Flags["JumpPowerSlider"] or 50 -- Apply current slider value if enabled
       end
   end,
})

MainTab:CreateSlider({
   Name = "JumpPower Slider",
   Range = {50, 500},
   Increment = 5,
   Suffix = " studs",
   CurrentValue = 50,
   Flag = "JumpPowerSlider",
   Callback = function(Value)
       if JumpPowerEnabled then
           Humanoid.JumpPower = Value
       end
   end,
})

-- God Mode Toggle
local GodModeEnabled = false
local Connection_GodMode
MainTab:CreateToggle({
   Name = "God Mode",
   CurrentValue = false,
   Flag = "GodModeToggle",
   Callback = function(Value)
       GodModeEnabled = Value
       if Value then
           -- Make character invulnerable
           Character.Humanoid.Health = 100
           Connection_GodMode = Character.Humanoid.HealthChanged:Connect(function(health)
               if health < 100 then
                   Character.Humanoid.Health = 100
               end
           end)
       else
           -- Disable invulnerability
           if Connection_GodMode then
               Connection_GodMode:Disconnect()
               Connection_GodMode = nil
           end
       end
   end,
})

-- NoClip Toggle
local NoClipEnabled = false
local OriginalCanCollide = {}
local function setCanCollide(part, value)
    if part and part:IsA("BasePart") then
        OriginalCanCollide[part] = part.CanCollide
        part.CanCollide = value
    end
end

local function restoreCanCollide(part)
    if part and OriginalCanCollide[part] ~= nil then
        part.CanCollide = OriginalCanCollide[part]
        OriginalCanCollide[part] = nil
    end
end

MainTab:CreateToggle({
    Name = "NoClip",
    CurrentValue = false,
    Flag = "NoClipToggle",
    Callback = function(Value)
        NoClipEnabled = Value
        if Value then
            for _, part in ipairs(Character:GetChildren()) do
                setCanCollide(part, false)
            end
        else
            for _, part in ipairs(Character:GetChildren()) do
                restoreCanCollide(part)
            end
        end
    end,
})

-- Invisiblity Toggle
local InvisibleEnabled = false
local OriginalTransparency = {}
MainTab:CreateToggle({
   Name = "Invisibility",
   CurrentValue = false,
   Flag = "InvisibleToggle",
   Callback = function(Value)
       InvisibleEnabled = Value
       for _, part in ipairs(Character:GetChildren()) do
           if part:IsA("BasePart") or part:IsA("Decal") or part:IsA("MeshPart") or part:IsA("SpecialMesh") then
               if Value then
                   OriginalTransparency[part] = part.Transparency
                   part.Transparency = 1
               else
                   if OriginalTransparency[part] then
                       part.Transparency = OriginalTransparency[part]
                       OriginalTransparency[part] = nil
                   end
               end
           end
       end
   end,
})

-- Player Fly Toggle
local FlyEnabled = false
local Connection_Fly
local BodyVelocity
local function StartFly()
    if FlyEnabled and RootPart and not BodyVelocity then
        BodyVelocity = Instance.new("BodyVelocity")
        BodyVelocity.MaxForce = Vector3.new(0, 40000, 0) -- Adjusted for more control
        BodyVelocity.Velocity = Vector3.new(0, 0, 0)
        BodyVelocity.Parent = RootPart

        -- Disable gravity
        Humanoid.Sit = true
        Character.Archivable = false
        for _, part in ipairs(Character:GetChildren()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
        Character.Archivable = true

        -- Input handling for flying
        Connection_Fly = game:GetService("UserInputService").InputBegan:Connect(function(input, gameProcessedEvent)
            if not gameProcessedEvent and FlyEnabled and BodyVelocity then
                if input.KeyCode == Enum.KeyCode.W then
                    BodyVelocity.Velocity = RootPart.CFrame.lookVector * 50 -- Forward speed
                elseif input.KeyCode == Enum.KeyCode.S then
                    BodyVelocity.Velocity = -RootPart.CFrame.lookVector * 50 -- Backward speed
                elseif input.KeyCode == Enum.KeyCode.A then
                    BodyVelocity.Velocity = -RootPart.CFrame.rightVector * 50 -- Left speed
                elseif input.KeyCode == Enum.KeyCode.D then
                    BodyVelocity.Velocity = RootPart.CFrame.rightVector * 50 -- Right speed
                elseif input.KeyCode == Enum.KeyCode.Space then
                    BodyVelocity.Velocity = Vector3.new(0, 50, 0) -- Up speed
                elseif input.KeyCode == Enum.KeyCode.X then
                    BodyVelocity.Velocity = Vector3.new(0, -50, 0) -- Down speed
                end
            end
        end)

        game:GetService("UserInputService").InputEnded:Connect(function(input, gameProcessedEvent)
            if not gameProcessedEvent and FlyEnabled and BodyVelocity then
                if input.KeyCode == Enum.KeyCode.W or input.KeyCode == Enum.KeyCode.S or
                   input.KeyCode == Enum.KeyCode.A or input.KeyCode == Enum.KeyCode.D or
                   input.KeyCode == Enum.KeyCode.Space or input.KeyCode == Enum.KeyCode.X then
                    BodyVelocity.Velocity = Vector3.new(0, 0, 0) -- Stop movement
                end
            end
        end)
    end
end

local function StopFly()
    if BodyVelocity then
        BodyVelocity:Destroy()
        BodyVelocity = nil
        Humanoid.Sit = false
        for _, part in ipairs(Character:GetChildren()) do
            if part:IsA("BasePart") then
                part.CanCollide = true
            end
        end
    end
    if Connection_Fly then
        Connection_Fly:Disconnect()
        Connection_Fly = nil
    end
end

MainTab:CreateToggle({
    Name = "Fly",
    CurrentValue = false,
    Flag = "FlyToggle",
    Callback = function(Value)
        FlyEnabled = Value
        if Value then
            StartFly()
        else
            StopFly()
        end
    end,
})

-- Teleport to Mouse Click
MainTab:CreateButton({
   Name = "Teleport to Mouse",
   Callback = function()
       local mouse = LocalPlayer:GetMouse()
       local target = mouse.Hit.p
       if target then
           RootPart.CFrame = CFrame.new(target) + Vector3.new(0, 5, 0) -- Teleport slightly above ground
       end
   end,
})

-- Rejoin Button
MainTab:CreateButton({
   Name = "Rejoin Server",
   Callback = function()
       game:GetService("TeleportService"):Teleport(game.PlaceId)
   end,
})

-- Respawn Button
MainTab:CreateButton({
   Name = "Respawn",
   Callback = function()
       Humanoid.Health = 0
   end,
})

-- Local Player FOV Slider
local Camera = workspace.CurrentCamera
MainTab:CreateSlider({
   Name = "Field of View (FOV)",
   Range = {1, 120},
   Increment = 1,
   Suffix = " deg",
   CurrentValue = Camera.FieldOfView,
   Flag = "FOVSlider",
   Callback = function(Value)
       Camera.FieldOfView = Value
   end,
})

-- --- WORLD SECTION ---
local WorldSection = MainTab:CreateSection("World")

-- Kill All Button
MainTab:CreateButton({
   Name = "Kill All Players",
   Callback = function()
       for _, player in ipairs(Players:GetPlayers()) do
           if player ~= LocalPlayer and player.Character and player.Character:FindFirstChildOfClass("Humanoid") then
               player.Character.Humanoid.Health = 0
               Rayfield:Notify({
                   Title = "Kill All",
                   Content = "Killed " .. player.Name,
                   Duration = 2,
                   Image = "skull"
               })
           end
       end
   end,
})

-- Loop Kill All Toggle
local KillAllLoopEnabled = false
local KillAllLoopConnection
MainTab:CreateToggle({
   Name = "Loop Kill All",
   CurrentValue = false,
   Flag = "KillAllLoopToggle",
   Callback = function(Value)
       KillAllLoopEnabled = Value
       if Value then
           KillAllLoopConnection = game:GetService("RunService").Heartbeat:Connect(function()
               for _, player in ipairs(Players:GetPlayers()) do
                   if player ~= LocalPlayer and player.Character and player.Character:FindFirstChildOfClass("Humanoid") then
                       player.Character.Humanoid.Health = 0
                   end
               end
           end)
       else
           if KillAllLoopConnection then
               KillAllLoopConnection:Disconnect()
               KillAllLoopConnection = nil
           end
       end
   end,
})

-- Remove All Limbs (Global)
MainTab:CreateButton({
    Name = "Remove All Limbs (Global)",
    Callback = function()
        for _, player in ipairs(Players:GetPlayers()) do
            if player.Character then
                for _, part in ipairs(player.Character:GetChildren()) do
                    if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                        part:Destroy()
                    end
                end
                Rayfield:Notify({
                    Title = "Removed Limbs",
                    Content = "Removed limbs for " .. player.Name,
                    Duration = 2,
                    Image = "scissors"
                })
            end
        end
    end,
})

-- Gravity Slider
MainTab:CreateSlider({
   Name = "Gravity",
   Range = {0, 196.2}, -- Default Roblox gravity is 196.2
   Increment = 1,
   Suffix = " studs/s^2",
   CurrentValue = workspace.Gravity,
   Flag = "GravitySlider",
   Callback = function(Value)
       workspace.Gravity = Value
   end,
})

-- TimeOfDay Slider
MainTab:CreateSlider({
   Name = "Time of Day",
   Range = {0, 24},
   Increment = 0.1,
   Suffix = " hours",
   CurrentValue = game:GetService("Lighting").ClockTime,
   Flag = "TimeOfDaySlider",
   Callback = function(Value)
       game:GetService("Lighting").ClockTime = Value
   end,
})

-- Set Ambient Light Color Picker
MainTab:CreateColorPicker({
    Name = "Ambient Light",
    Color = game:GetService("Lighting").Ambient,
    Flag = "AmbientLightColor",
    Callback = function(Value)
        game:GetService("Lighting").Ambient = Value
    end
})

-- Set Fog Color Picker
MainTab:CreateColorPicker({
    Name = "Fog Color",
    Color = game:GetService("Lighting").FogColor,
    Flag = "FogColor",
    Callback = function(Value)
        game:GetService("Lighting").FogColor = Value
    end
})

-- Set Fog End Slider
MainTab:CreateSlider({
   Name = "Fog End",
   Range = {0, 100000},
   Increment = 100,
   Suffix = " studs",
   CurrentValue = game:GetService("Lighting").FogEnd,
   Flag = "FogEndSlider",
   Callback = function(Value)
       game:GetService("Lighting").FogEnd = Value
   end,
})

-- Set Fog Start Slider
MainTab:CreateSlider({
   Name = "Fog Start",
   Range = {0, 100000},
   Increment = 100,
   Suffix = " studs",
   CurrentValue = game:GetService("Lighting").FogStart,
   Flag = "FogStartSlider",
   Callback = function(Value)
       game:GetService("Lighting").FogStart = Value
   end,
})

-- --- VISUALS SECTION ---
local VisualsSection = MainTab:CreateSection("Visuals")

-- ESP Toggle (Basic Box ESP)
local ESPEnabled = false
local ESPConnections = {}
local ESPBoxes = {}

-- Tracers Toggle
local TracersEnabled = false
local TracerConnections = {}
local TracerLines = {}

-- X-Ray Toggle (Highlight players through walls)
local XRayEnabled = false
local HighlightObjects = {}

-- Helper: determine if a player is an enemy
local function isEnemy(player)
    if not player or player == LocalPlayer then return false end
    -- must have a character and a humanoid with health > 0
    if not player.Character or not player.Character:FindFirstChildOfClass("Humanoid") then return false end
    local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then return false end

    -- exclude friends (pcall in case exploit environment restricts it)
    local ok, isFriend = pcall(function() return LocalPlayer:IsFriendsWith(player.UserId) end)
    if ok and isFriend then return false end

    -- exclude same team if the game uses teams
    if player.Team and LocalPlayer.Team and player.Team == LocalPlayer.Team then
        return false
    end

    return true
end

-- Clean up ESP boxes
local function destroyESPBoxes()
    for _, box in ipairs(ESPBoxes) do
        if box and box.Parent then
            box:Destroy()
        end
    end
    ESPBoxes = {}
    for _, conn in pairs(ESPConnections) do
        if conn and typeof(conn) == "RBXScriptConnection" then
            conn:Disconnect()
        end
    end
    ESPConnections = {}
end

-- Create ESP box only for enemy
local function createESPBox(targetCharacter, targetPlayer)
    if not targetCharacter or not targetCharacter:FindFirstChild("HumanoidRootPart") then return end
    if not isEnemy(targetPlayer) then return end

    local Box = Instance.new("Part")
    Box.Name = "RayfieldESPBox"
    Box.Anchored = true
    Box.CanCollide = false
    Box.Transparency = 0.7
    Box.BrickColor = BrickColor.new("Really red")
    Box.Parent = workspace.CurrentCamera -- parent to camera for local rendering

    local function updateESPBox()
        if not targetCharacter or not targetCharacter:FindFirstChild("HumanoidRootPart") or not Box or not Box.Parent then
            if Box then Box:Destroy() end
            return
        end
        local rootPart = targetCharacter:FindFirstChild("HumanoidRootPart")
        local head = targetCharacter:FindFirstChild("Head")
        local humanoid = targetCharacter:FindFirstChildOfClass("Humanoid")

        if rootPart and head and humanoid and humanoid.Health > 0 then
            local headPos = head.Position
            local rootPos = rootPart.Position

            local height = (headPos.Y - rootPos.Y) + (head.Size.Y / 2) + 0.5 -- Approximate character height
            local width = (rootPart.Size.X + rootPart.Size.Z) / 2 + 0.5 -- Approximate character width

            Box.Size = Vector3.new(width, height, width)
            Box.CFrame = CFrame.new(rootPos.X, rootPos.Y + height / 2, rootPos.Z)
        else
            if Box then Box:Destroy() end
        end
    end

    table.insert(ESPBoxes, Box)
    ESPConnections[targetCharacter] = game:GetService("RunService").Heartbeat:Connect(updateESPBox)
end

local function refreshESP()
    destroyESPBoxes()
    if ESPEnabled then
        for _, player in ipairs(Players:GetPlayers()) do
            if isEnemy(player) and player.Character then
                createESPBox(player.Character, player)
            end
        end
    end
end

-- Tracer helpers
local function destroyTracerLines()
    for _, line in ipairs(TracerLines) do
        if line and line.Parent then
            line:Destroy()
        end
    end
    TracerLines = {}
    for _, conn in pairs(TracerConnections) do
        if conn and typeof(conn) == "RBXScriptConnection" then
            conn:Disconnect()
        end
    end
    TracerConnections = {}
end

local function createTracerLine(targetCharacter, targetPlayer)
    if not targetCharacter or not targetCharacter:FindFirstChild("HumanoidRootPart") then return end
    if not isEnemy(targetPlayer) then return end

    local line = Instance.new("Part")
    line.Name = "RayfieldTracer"
    line.Anchored = true
    line.CanCollide = false
    line.Transparency = 0
    line.BrickColor = BrickColor.new("Lime green")
    line.TopSurface = Enum.SurfaceType.Smooth
    line.BottomSurface = Enum.SurfaceType.Smooth
    line.Parent = workspace.CurrentCamera
    line.Size = Vector3.new(0.1, 0.1, 0.1) -- Small initial size

    local function updateTracerLine()
        if not targetCharacter or not targetCharacter:FindFirstChild("HumanoidRootPart") or not line or not line.Parent then
            if line then line:Destroy() end
            return
        end
        local rootPart = targetCharacter.HumanoidRootPart
        local cameraPos = Camera.CFrame.p
        local targetPos = rootPart.Position

        local distance = (cameraPos - targetPos).magnitude
        local center = (cameraPos + targetPos) / 2
        local cframe = CFrame.lookAt(center, targetPos)

        line.Size = Vector3.new(0.1, 0.1, distance)
        line.CFrame = cframe * CFrame.new(0, 0, -distance/2)
    end

    table.insert(TracerLines, line)
    TracerConnections[targetCharacter] = game:GetService("RunService").RenderStepped:Connect(updateTracerLine)
end

local function refreshTracers()
    destroyTracerLines()
    if TracersEnabled then
        for _, player in ipairs(Players:GetPlayers()) do
            if isEnemy(player) and player.Character then
                createTracerLine(player.Character, player)
            end
        end
    end
end

-- Highlight helpers
local function destroyHighlights()
    for char, highlight in pairs(HighlightObjects) do
        if highlight and highlight.Parent then
            highlight:Destroy()
        end
    end
    HighlightObjects = {}
end

local function createHighlight(targetCharacter, targetPlayer)
    if not targetCharacter then return end
    if not isEnemy(targetPlayer) then return end

    local highlight = Instance.new("Highlight")
    highlight.Name = "RayfieldHighlight"
    highlight.FillColor = Color3.fromRGB(255, 0, 0) -- Red fill
    highlight.OutlineColor = Color3.fromRGB(0, 255, 255) -- Cyan outline
    highlight.FillTransparency = 0.5
    highlight.OutlineTransparency = 0
    highlight.Enabled = true
    highlight.Parent = targetCharacter

    HighlightObjects[targetCharacter] = highlight
end

local function refreshHighlights()
    destroyHighlights()
    if XRayEnabled then
        for _, player in ipairs(Players:GetPlayers()) do
            if isEnemy(player) and player.Character then
                createHighlight(player.Character, player)
            end
        end
    end
end

-- ESP Toggle wiring (updates PlayerAdded/CharacterAdded handlers safely)
MainTab:CreateToggle({
   Name = "Player ESP",
   CurrentValue = false,
   Flag = "ESPToggle",
   Callback = function(Value)
       ESPEnabled = Value
       if Value then
           -- Initial ESP creation
           refreshESP()

           -- Handle new players joining
           if ESPConnections["PlayerAdded"] then ESPConnections["PlayerAdded"]:Disconnect() end
           ESPConnections["PlayerAdded"] = Players.PlayerAdded:Connect(function(player)
               player.CharacterAdded:Connect(function(char)
                   if ESPEnabled and isEnemy(player) then
                       createESPBox(char, player)
                   end
               end)
           end)

           -- Handle character resets/respawns for existing players
           for _, player in ipairs(Players:GetPlayers()) do
               if isEnemy(player) then
                   if ESPConnections[player] then ESPConnections[player]:Disconnect() end
                   ESPConnections[player] = player.CharacterAdded:Connect(function(char)
                       if ESPEnabled and isEnemy(player) then
                           createESPBox(char, player)
                       end
                   end)
               end
           end
       else
           destroyESPBoxes()
           if ESPConnections["PlayerAdded"] then
               ESPConnections["PlayerAdded"]:Disconnect()
               ESPConnections["PlayerAdded"] = nil
           end
           for player, conn in pairs(ESPConnections) do
               if typeof(player) == "Instance" and player:IsA("Player") then
                   conn:Disconnect()
                   ESPConnections[player] = nil
               end
           end
       end
   end,
})

-- Tracers Toggle wiring
MainTab:CreateToggle({
   Name = "Player Tracers",
   CurrentValue = false,
   Flag = "TracersToggle",
   Callback = function(Value)
       TracersEnabled = Value
       if Value then
           refreshTracers()

           if TracerConnections["PlayerAdded"] then TracerConnections["PlayerAdded"]:Disconnect() end
           TracerConnections["PlayerAdded"] = Players.PlayerAdded:Connect(function(player)
               player.CharacterAdded:Connect(function(char)
                   if TracersEnabled and isEnemy(player) then
                       createTracerLine(char, player)
                   end
               end)
           end)

           for _, player in ipairs(Players:GetPlayers()) do
               if isEnemy(player) then
                   if TracerConnections[player] then TracerConnections[player]:Disconnect() end
                   TracerConnections[player] = player.CharacterAdded:Connect(function(char)
                       if TracersEnabled and isEnemy(player) then
                           createTracerLine(char, player)
                       end
                   end)
               end
           end
       else
           destroyTracerLines()
           if TracerConnections["PlayerAdded"] then
               TracerConnections["PlayerAdded"]:Disconnect()
               TracerConnections["PlayerAdded"] = nil
           end
           for player, conn in pairs(TracerConnections) do
               if typeof(player) == "Instance" and player:IsA("Player") then
                   conn:Disconnect()
                   TracerConnections[player] = nil
               end
           end
       end
   end,
})

-- X-Ray Toggle wiring
MainTab:CreateToggle({
   Name = "X-Ray (Highlight Players)",
   CurrentValue = false,
   Flag = "XRayToggle",
   Callback = function(Value)
       XRayEnabled = Value
       if Value then
           refreshHighlights()

           Players.PlayerAdded:Connect(function(player)
               player.CharacterAdded:Connect(function(char)
                   if XRayEnabled and isEnemy(player) then
                       createHighlight(char, player)
                   end
               end)
           end)

           for _, player in ipairs(Players:GetPlayers()) do
               player.CharacterAdded:Connect(function(char)
                   if XRayEnabled and isEnemy(player) then
                       createHighlight(char, player)
                   end
               end)
           end
       else
           destroyHighlights()
       end
   end,
})

-- Full Bright Toggle
local FullBrightEnabled = false
local OriginalBrightness = game:GetService("Lighting").Brightness
MainTab:CreateToggle({
   Name = "Full Bright",
   CurrentValue = false,
   Flag = "FullBrightToggle",
   Callback = function(Value)
       FullBrightEnabled = Value
       if Value then
           game:GetService("Lighting").Brightness = 2
           game:GetService("Lighting").OutdoorAmbient = Color3.new(1, 1, 1)
           game:GetService("Lighting").Ambient = Color3.new(1, 1, 1)
       else
           game:GetService("Lighting").Brightness = OriginalBrightness
           game:GetService("Lighting").OutdoorAmbient = Color3.new(0, 0, 0) -- Restore default or saved
           game:GetService("Lighting").Ambient = Color3.new(0, 0, 0) -- Restore default or saved
       end
   end,
})

-- No Fog Toggle
local NoFogEnabled = false
local OriginalFogEnd = game:GetService("Lighting").FogEnd
local OriginalFogStart = game:GetService("Lighting").FogStart
MainTab:CreateToggle({
   Name = "No Fog",
   CurrentValue = false,
   Flag = "NoFogToggle",
   Callback = function(Value)
       NoFogEnabled = Value
       if Value then
           game:GetService("Lighting").FogEnd = 1000000 -- Max out fog distance
           game:GetService("Lighting").FogStart = 999999
       else
           game:GetService("Lighting").FogEnd = OriginalFogEnd
           game:GetService("Lighting").FogStart = OriginalFogStart
       end
   end,
})

-- --- WEAPON / COMBAT SECTION ---
local WeaponSection = MainTab:CreateSection("Weapon/Combat")

-- Aimbot Toggle (Basic nearest enemy aimbot)
local AimbotEnabled = false
local AimbotConnection

local function GetNearestTarget()
    local nearestPlayer = nil
    local shortestDistance = math.huge

    for _, player in ipairs(Players:GetPlayers()) do
        if isEnemy(player) then
            if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                local distance = (RootPart.Position - player.Character.HumanoidRootPart.Position).magnitude
                if distance < shortestDistance then
                    shortestDistance = distance
                    nearestPlayer = player
                end
            end
        end
    end
    return nearestPlayer
end

MainTab:CreateToggle({
   Name = "Aimbot",
   CurrentValue = false,
   Flag = "AimbotToggle",
   Callback = function(Value)
       AimbotEnabled = Value
       if Value then
           AimbotConnection = game:GetService("RunService").RenderStepped:Connect(function()
               if AimbotEnabled then
                   local target = GetNearestTarget()
                   if target and target.Character and target.Character:FindFirstChild("Head") then
                       local targetHead = target.Character.Head
                       Camera.CFrame = CFrame.lookAt(Camera.CFrame.p, targetHead.Position)
                   end
               end
           end)
       else
           if AimbotConnection then
               AimbotConnection:Disconnect()
               AimbotConnection = nil
           end
       end
   end,
})

-- Silent Aim Toggle (Experimental placeholder)
local SilentAimEnabled = false
MainTab:CreateToggle({
   Name = "Silent Aim (Experimental)",
   CurrentValue = false,
   Flag = "SilentAimToggle",
   Callback = function(Value)
       SilentAimEnabled = Value
       if Value then
           Rayfield:Notify({
               Title = "Silent Aim",
               Content = "Silent Aim activated. Functionality depends on the game's weapon system.",
               Duration = 2,
               Image = "alert-octagon"
           })
       else
           Rayfield:Notify({
               Title = "Silent Aim",
               Content = "Silent Aim deactivated.",
               Duration = 3,
               Image = "slash"
           })
       end
   end,
})

-- Rapid Fire Toggle
local RapidFireEnabled = false
local OriginalFireRate = {}
local function SetRapidFire(tool, value)
    if not tool or not tool:IsA("Tool") then return end

    local remoteEvent = nil
    for _, child in ipairs(tool:GetChildren()) do
        if child:IsA("RemoteEvent") and (child.Name:lower():find("fire") or child.Name:lower():find("shoot")) then
            remoteEvent = child
            break
        end
    end

    if remoteEvent then
        if value then
            OriginalFireRate[tool] = true
            while RapidFireEnabled and task.wait(0.05) and tool.Parent == LocalPlayer.Character do
                pcall(function() remoteEvent:FireServer() end)
            end
        else
            OriginalFireRate[tool] = nil
        end
    end
end

MainTab:CreateToggle({
   Name = "Rapid Fire",
   CurrentValue = false,
   Flag = "RapidFireToggle",
   Callback = function(Value)
       RapidFireEnabled = Value
       if Value then
           local tool = LocalPlayer.Character:FindFirstChildOfClass("Tool")
           if tool then
               SetRapidFire(tool, true)
           end
       else
           -- Deactivation handled by loop condition
       end
   end,
})

-- Auto Heal Toggle
local AutoHealEnabled = false
local AutoHealConnection
MainTab:CreateToggle({
   Name = "Auto Heal",
   CurrentValue = false,
   Flag = "AutoHealToggle",
   Callback = function(Value)
       AutoHealEnabled = Value
       if Value then
           AutoHealConnection = game:GetService("RunService").Heartbeat:Connect(function()
               if AutoHealEnabled and Humanoid.Health < Humanoid.MaxHealth then
                   Humanoid.Health = Humanoid.MaxHealth
               end
           end)
       else
           if AutoHealConnection then
               AutoHealConnection:Disconnect()
               AutoHealConnection = nil
           end
       end
   end,
})

-- --- MISC SECTION ---
local MiscSection = MainTab:CreateSection("Miscellaneous")

-- Anti AFK
local AntiAFKEnabled = false
local AFKConnection
MainTab:CreateToggle({
   Name = "Anti AFK",
   CurrentValue = false,
   Flag = "AntiAFKToggle",
   Callback = function(Value)
       AntiAFKEnabled = Value
       if Value then
           AFKConnection = game:GetService("UserInputService").InputChanged:Connect(function(input, gameProcessedEvent)
               if input.UserInputType == Enum.UserInputType.Keyboard or input.UserInputType == Enum.UserInputType.MouseMovement then
                   -- no-op, present to keep connection
               end
           end)
           spawn(function()
               while AntiAFKEnabled do
                   task.wait(10)
                   if AntiAFKEnabled and Humanoid then
                       Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                   end
               end
           end)
       else
           if AFKConnection then
               AFKConnection:Disconnect()
               AFKConnection = nil
           end
       end
   end,
})

-- Infinite Yield Button
MainTab:CreateButton({
   Name = "Infinite Yield",
   Callback = function()
       local iy = loadstring(game:HttpGet("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"))()
       Rayfield:Notify({
           Title = "Infinite Yield",
           Content = "Attempted to load Infinite Yield. Check console for output.",
           Duration = 5,
           Image = "terminal"
       })
   end,
})

-- Server Hop Button
MainTab:CreateButton({
   Name = "Server Hop",
   Callback = function()
       local currentPlaceId = game.PlaceId
       local currentJobId = game.JobId

       local success, result = pcall(function()
           return game:GetService("HttpService"):JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" .. currentPlaceId .. "/servers/Public?limit=100"))
       end)

       if success and result and result.data then
           local servers = result.data
           local foundNewServer = false
           for _, server in ipairs(servers) do
               if server.id ~= currentJobId and server.playing < server.maxPlayers then
                   game:GetService("TeleportService"):TeleportToPlaceInstance(currentPlaceId, server.id, LocalPlayer)
                   foundNewServer = true
                   break
               end
           end
           if not foundNewServer then
               Rayfield:Notify({
                   Title = "Server Hop Failed",
                   Content = "Could not find an available server.",
                   Duration = 5,
                   Image = "wifi-off"
               })
           end
       else
           Rayfield:Notify({
               Title = "Server Hop Error",
               Content = "Failed to fetch server list. " .. (result or "Unknown error."),
               Duration = 5,
               Image = "server-crash"
           })
       end
   end,
})

-- View Server Players Button
MainTab:CreateButton({
   Name = "View Server Players",
   Callback = function()
       local playerList = {}
       for _, player in ipairs(Players:GetPlayers()) do
           table.insert(playerList, player.Name)
       end
       Rayfield:Notify({
           Title = "Current Players",
           Content = table.concat(playerList, ", "),
           Duration = 10,
           Image = "users"
       })
   end,
})

-- Crash Server (Client-side attempt)
local ServerCrashEnabled = false
local CrashConnection
MainTab:CreateToggle({
   Name = "Attempt Server Crash (Lag)",
   CurrentValue = false,
   Flag = "ServerCrashToggle",
   Callback = function(Value)
       ServerCrashEnabled = Value
       if Value then
           Rayfield:Notify({
               Title = "Server Crash Attempt",
               Content = "Warning: This may crash your own client or only cause lag.",
               Duration = 7,
               Image = "radiation"
           })
           CrashConnection = game:GetService("RunService").Heartbeat:Connect(function()
               if ServerCrashEnabled then
                   for i = 1, 100 do
                       local p = Instance.new("Part")
                       p.Size = Vector3.new(1,1,1)
                       p.Position = RootPart.Position + Vector3.new(math.random(-50,50), math.random(10,50), math.random(-50,50))
                       p.Anchored = false
                       p.CanCollide = false
                       p.Transparency = 1
                       p.Parent = workspace
                       game:GetService("Debris"):AddItem(p, 0.5)
                   end
               end
           end)
       else
           if CrashConnection then
               CrashConnection:Disconnect()
               CrashConnection = nil
           end
       end
   end,
})

-- Disable Chat
local ChatDisabled = false
local OldChatService
MainTab:CreateToggle({
   Name = "Disable Chat",
   CurrentValue = false,
   Flag = "DisableChatToggle",
   Callback = function(Value)
       ChatDisabled = Value
       local chatService = game:GetService("Chat")
       if Value then
           pcall(function()
               if chatService.ChatWindow then
                   OldChatService = chatService.ChatWindow
                   chatService.ChatWindow:Destroy()
               end
           end)
           Rayfield:Notify({
               Title = "Chat Disabled",
               Content = "The chat window has been removed.",
               Duration = 3,
               Image = "message-square-off"
           })
       else
           if OldChatService then
               OldChatService.Parent = game.CoreGui
               OldChatService = nil
           end
           Rayfield:Notify({
               Title = "Chat Enabled",
               Content = "Chat window restored.",
               Duration = 3,
               Image = "message-square-text"
           })
       end
   end,
})

-- Remove UI (CoreGui elements)
local UIRemoved = false
local OriginalCoreGuis = {}
MainTab:CreateToggle({
   Name = "Remove All UI (CoreGui)",
   CurrentValue = false,
   Flag = "RemoveUIToggle",
   Callback = function(Value)
       UIRemoved = Value
       if Value then
           for _, child in ipairs(game:GetService("CoreGui"):GetChildren()) do
               if child.Name ~= "Rayfield" then -- Don't remove our own GUI
                   OriginalCoreGuis[child] = child.Parent
                   child.Parent = nil
               end
           end
           Rayfield:Notify({
               Title = "UI Removed",
               Content = "Most CoreGui elements have been hidden.",
               Duration = 3,
               Image = "eye-off"
           })
       else
           for child, parent in pairs(OriginalCoreGuis) do
               if child and parent then
                   child.Parent = parent
               end
           end
           OriginalCoreGuis = {}
           Rayfield:Notify({
               Title = "UI Restored",
               Content = "CoreGui elements have been restored.",
               Duration = 3,
               Image = "eye"
           })
       end
   end,
})

-- Full Screen Mode
MainTab:CreateButton({
   Name = "Toggle Fullscreen",
   Callback = function()
       local guiService = game:GetService("GuiService")
       guiService.IsFullscreen = not guiService.IsFullscreen
       Rayfield:Notify({
           Title = "Fullscreen Toggled",
           Content = "Fullscreen mode " .. (guiService.IsFullscreen and "enabled" or "disabled"),
           Duration = 3,
           Image = (guiService.IsFullscreen and "maximize" or "minimize")
       })
   end,
})

-- Anti-Kick (Attempt to prevent server-side kicks by reconnecting or faking presence)
local AntiKickEnabled = false
local AntiKickConnection
MainTab:CreateToggle({
   Name = "Anti-Kick",
   CurrentValue = false,
   Flag = "AntiKickToggle",
   Callback = function(Value)
       AntiKickEnabled = Value
       if Value then
           AntiKickConnection = game:GetService("Players").LocalPlayer.ChildRemoved:Connect(function(child)
               if child == LocalPlayer.Character then
                   task.wait(1)
                   if AntiKickEnabled then
                       game:GetService("TeleportService"):Teleport(game.PlaceId)
                   end
               end
           end)
           spawn(function()
               while AntiKickEnabled do
                   task.wait(5)
                   if AntiKickEnabled then
                       local events = game:GetService("ReplicatedStorage"):GetChildren()
                       for _, event in ipairs(events) do
                           if event:IsA("RemoteEvent") then
                               pcall(function() event:FireServer() end)
                               break
                           end
                       end
                   end
               end
           end)
           Rayfield:Notify({
               Title = "Anti-Kick Enabled",
               Content = "Attempting to prevent kicks. Reliability varies.",
               Duration = 5,
               Image = "shield"
           })
       else
           if AntiKickConnection then
               AntiKickConnection:Disconnect()
               AntiKickConnection = nil
           end
           Rayfield:Notify({
               Title = "Anti-Kick Disabled",
               Content = "Anti-Kick is now off.",
               Duration = 3,
               Image = "shield-off"
           })
       end
   end,
})

-- Clear Workspace (Removes all parts/models except players)
MainTab:CreateButton({
   Name = "Clear Workspace",
   Callback = function()
       for _, child in ipairs(workspace:GetChildren()) do
           if not child:IsA("Player") and not Players:GetPlayerFromCharacter(child) and not child:IsA("Camera") and not child:IsA("Terrain") and not child:IsA("Atmosphere") and not child:IsA("Sky") then
               pcall(function() child:Destroy() end)
           end
       end
       Rayfield:Notify({
           Title = "Workspace Cleared",
           Content = "Most non-player objects removed.",
           Duration = 5,
           Image = "trash"
       })
   end,
})

-- Destroy All Tools (Global)
MainTab:CreateButton({
   Name = "Destroy All Tools (Global)",
   Callback = function()
       for _, player in ipairs(Players:GetPlayers()) do
           if player.Character then
               for _, child in ipairs(player.Character:GetChildren()) do
                   if child:IsA("Tool") then
                       pcall(function() child:Destroy() end)
                   end
               end
           end
           for _, child in ipairs(player.Backpack:GetChildren()) do
               if child:IsA("Tool") then
                   pcall(function() child:Destroy() end)
               end
           end
       end
       Rayfield:Notify({
           Title = "Tools Destroyed",
           Content = "All player tools removed.",
           Duration = 5,
           Image = "tool"
       })
   end,
})

-- Execute Custom Lua Input
MainTab:CreateInput({
   Name = "Execute Custom Lua",
   PlaceholderText = "Enter Lua code here...",
   Flag = "CustomLuaInput",
   Callback = function(Text)
       if Text ~= "" then
           local success, err = pcall(function()
               loadstring(Text)()
           end)
           if success then
               Rayfield:Notify({
                   Title = "Lua Executed",
                   Content = "Custom script executed successfully.",
                   Duration = 3,
                   Image = "check-circle"
               })
           else
               Rayfield:Notify({
                   Title = "Lua Execution Error",
                   Content = err,
                   Duration = 5,
                   Image = "x-circle"
               })
           end
       end
   end,
})

-- Script Hub Divider for visual separation
MainTab:CreateDivider()

-- Credits/Info Section
local CreditsSection = MainTab:CreateSection("Info")
MainTab:CreateButton({
   Name = "Credits",
   Callback = function()
       Rayfield:Notify({
           Title = "Script Hub by Gemini",
           Content = "This universal exploit script was generated by a Gemini AI specializing in Roblox Lua scripting. Features powered by Rayfield UI.",
           Duration = 10,
           Image = "gemini"
       })
   end,
})

-- --- END OF SCRIPT ---
