
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- =========================================================
-- WINDOW
-- =========================================================
local Window = Rayfield:CreateWindow({
    Name = "Universal Script Hub (Merged)",
    LoadingTitle = "Utility Hub",
    LoadingSubtitle = "Fly, Speed, Jump, ESP, Many Tools",
    ConfigurationSaving = {
        Enabled = false,
        FolderName = nil,
        FileName = "ScriptHubConfig"
    }
})

-- =========================================================
-- CREATE TABS
-- =========================================================
local MovementTab = Window:CreateTab("Movement", "rocket")
local VisualsTab  = Window:CreateTab("Visuals", "eye")
local PlayerTab   = Window:CreateTab("Player", "user")
local UtilityTab  = Window:CreateTab("Utility", "wrench")
local TrollTab    = Window:CreateTab("Troll", "skull")
local CombatTab   = Window:CreateTab("Combat", "sword")

-- =========================================================
-- SERVICES & LOCALS
-- =========================================================
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local TeleportService = game:GetService("TeleportService")
local mouse = LocalPlayer:GetMouse()

-- =========================================================
-- HELPER UTIL
-- =========================================================
local function safeFindCharacter(plr)
    return plr and plr.Character
end

local function getRoot(char)
    if not char then return nil end
    return char:FindFirstChild("HumanoidRootPart") or char:FindFirstChildWhichIsA("BasePart")
end

local function notify(title, message, dur)
    pcall(function()
        if Rayfield and Rayfield.Notify then
            Rayfield:Notify({
                Title = title or "Notice",
                Content = message or "",
                Duration = dur or 4
            })
        else
            warn((title or "Notice") .. ": " .. tostring(message))
        end
    end)
end


-- =========================================================
-- ORIGINAL ESP (Friend = Green | Enemy = Red)
-- =========================================================
local espFolder = Instance.new("Folder", game.CoreGui)
espFolder.Name = "ESPFolder"
local espEnabled = false

local function updateESPColor(highlight, player)
    if not highlight or not player then return end
    if player.Team and game.Players.LocalPlayer.Team then
        if player.Team == game.Players.LocalPlayer.Team then
            highlight.FillColor = Color3.fromRGB(0, 255, 0) -- Friend
        else
            highlight.FillColor = Color3.fromRGB(255, 0, 0) -- Enemy
        end
    else
        highlight.FillColor = Color3.fromRGB(255, 0, 0)
    end
end

local function createESP(player)
    if player == LocalPlayer then return end
    if not player.Character then return end
    if espFolder:FindFirstChild(player.Name .. "_ESP") then return end

    local highlight = Instance.new("Highlight")
    highlight.Name = player.Name .. "_ESP"
    highlight.Adornee = player.Character
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = espFolder

    updateESPColor(highlight, player)

    player:GetPropertyChangedSignal("Team"):Connect(function()
        updateESPColor(highlight, player)
    end)

    player.CharacterAdded:Connect(function(char)
        task.wait(1)
        if espEnabled then
            highlight.Adornee = char
            updateESPColor(highlight, player)
        end
    end)
end

VisualsTab:CreateToggle({
    Name = "ESP Players",
    CurrentValue = false,
    Callback = function(state)
        espEnabled = state
        espFolder:ClearAllChildren()
        if state then
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr.Character then createESP(plr) end
            end
        end
    end,
})

Players.PlayerAdded:Connect(function(plr)
    if espEnabled then
        plr.CharacterAdded:Connect(function()
            task.wait(1)
            if espEnabled then createESP(plr) end
        end)
    end
end)

-- =========================================================
-- ORIGINAL MOVEMENT FLY + ANIMATIONS (preserved)
-- =========================================================
local savedSpeed = 50
local flying = false
local flySpeed = savedSpeed
local forwardHold = 0
local inputFlags = { forward = false, back = false, left = false, right = false, up = false, down = false }

local bodyVelocity = Instance.new("BodyVelocity")
bodyVelocity.MaxForce = Vector3.new(1e5, 1e5, 1e5)

local bodyGyro = Instance.new("BodyGyro")
bodyGyro.MaxTorque = Vector3.new(1e5, 1e5, 1e5)

local humanoid, HRP
local function getChar()
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    humanoid = char:WaitForChild("Humanoid")
    HRP = char:WaitForChild("HumanoidRootPart")
end
getChar()
LocalPlayer.CharacterAdded:Connect(getChar)

local function newAnim(id)
    local anim = Instance.new("Animation")
    anim.AnimationId = "rbxassetid://" .. id
    return anim
end

local animations = {
    forward = newAnim(90872539),
    up = newAnim(90872539),
    right1 = newAnim(136801964),
    right2 = newAnim(142495255),
    left1 = newAnim(136801964),
    left2 = newAnim(142495255),
    flyLow1 = newAnim(97169019),
    flyLow2 = newAnim(282574440),
    flyFast = newAnim(282574440),
    back1 = newAnim(136801964),
    back2 = newAnim(106772613),
    back3 = newAnim(42070810),
    back4 = newAnim(214744412),
    down = newAnim(233322916),
    idle1 = newAnim(97171309)
}

local tracks = {}
local function loadAnimations()
    if humanoid then
        for name, anim in pairs(animations) do
            tracks[name] = humanoid:LoadAnimation(anim)
        end
    end
end
loadAnimations()

local function stopAll()
    for _, track in pairs(tracks) do
        pcall(function() track:Stop() end)
    end
end

local function startFlying()
    flying = true
    forwardHold = 0
    flySpeed = savedSpeed
    pcall(function() bodyVelocity.Parent = HRP; bodyGyro.Parent = HRP end)
    if humanoid then humanoid.PlatformStand = true end
end

local function stopFlying()
    flying = false
    pcall(function() bodyVelocity.Parent = nil; bodyGyro.Parent = nil end)
    if humanoid then humanoid.PlatformStand = false end
    stopAll()
end

-- input handling (base)
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.W then inputFlags.forward = true end
    if input.KeyCode == Enum.KeyCode.S then inputFlags.back = true end
    if input.KeyCode == Enum.KeyCode.A then inputFlags.left = true end
    if input.KeyCode == Enum.KeyCode.D then inputFlags.right = true end
    if input.KeyCode == Enum.KeyCode.E then inputFlags.up = true end
    if input.KeyCode == Enum.KeyCode.Q then inputFlags.down = true end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.W then inputFlags.forward = false end
    if input.KeyCode == Enum.KeyCode.S then inputFlags.back = false end
    if input.KeyCode == Enum.KeyCode.A then inputFlags.left = false end
    if input.KeyCode == Enum.KeyCode.D then inputFlags.right = false end
    if input.KeyCode == Enum.KeyCode.E then inputFlags.up = false end
    if input.KeyCode == Enum.KeyCode.Q then inputFlags.down = false end
end)

RunService.RenderStepped:Connect(function(dt)
    if not flying then return end
    if not HRP then return end

    if not inputFlags.forward then forwardHold = 0 end

    local dir = Vector3.zero
    local camCF = Camera.CFrame

    if inputFlags.forward then dir += camCF.LookVector end
    if inputFlags.back then dir -= camCF.LookVector end
    if inputFlags.left then dir -= camCF.RightVector end
    if inputFlags.right then dir += camCF.RightVector end
    if inputFlags.up then dir += Vector3.yAxis end
    if inputFlags.down then dir -= Vector3.yAxis end

    if dir.Magnitude > 0 then dir = dir.Unit end

    bodyVelocity.Velocity = dir * flySpeed
    bodyGyro.CFrame = camCF

    -- animation logic
    if inputFlags.up then
        if not tracks.up.IsPlaying then stopAll(); tracks.up:Play() end
    elseif inputFlags.down then
        if not tracks.down.IsPlaying then stopAll(); tracks.down:Play() end
    elseif inputFlags.left then
        if not tracks.left1.IsPlaying then
            stopAll()
            tracks.left1:Play(); tracks.left1.TimePosition = 2.0; tracks.left1:AdjustSpeed(0)
            tracks.left2:Play(); tracks.left2.TimePosition = 0.5; tracks.left2:AdjustSpeed(0)
        end
    elseif inputFlags.right then
        if not tracks.right1.IsPlaying then
            stopAll()
            tracks.right1:Play(); tracks.right1.TimePosition = 1.1; tracks.right1:AdjustSpeed(0)
            tracks.right2:Play(); tracks.right2.TimePosition = 0.5; tracks.right2:AdjustSpeed(0)
        end
    elseif inputFlags.back then
        if not tracks.back1.IsPlaying then
            stopAll()
            tracks.back1:Play(); tracks.back1.TimePosition = 5.3; tracks.back1:AdjustSpeed(0)
            tracks.back2:Play(); tracks.back2:AdjustSpeed(0)
            tracks.back3:Play(); tracks.back3.TimePosition = 0.8; tracks.back3:AdjustSpeed(0)
            tracks.back4:Play(); tracks.back4.TimePosition = 1; tracks.back4:AdjustSpeed(0)
        end
    elseif inputFlags.forward then
        forwardHold += dt
        if forwardHold >= 3 then
            if not tracks.flyFast.IsPlaying then
                stopAll()
                flySpeed = savedSpeed * 1.3
                tracks.flyFast:Play(); tracks.flyFast:AdjustSpeed(0.05)
            end
        else
            if not tracks.flyLow1.IsPlaying then
                stopAll()
                flySpeed = savedSpeed
                tracks.flyLow1:Play()
                tracks.flyLow2:Play()
            end
        end
    else
        if not tracks.idle1.IsPlaying then
            stopAll()
            tracks.idle1:Play(); tracks.idle1:AdjustSpeed(0)
        end
    end
end)

-- =========================================================
-- GUI: Movement Controls (existing)
-- =========================================================
MovementTab:CreateToggle({
    Name = "Fly",
    CurrentValue = false,
    Callback = function(state)
        if state then startFlying() else stopFlying() end
    end,
})

MovementTab:CreateSlider({
    Name = "Fly Speed",
    Range = {10, 200},
    Increment = 5,
    Suffix = "Speed",
    CurrentValue = savedSpeed,
    Callback = function(v)
        savedSpeed = v
        if flying then flySpeed = v end
    end,
})

MovementTab:CreateSlider({
    Name = "WalkSpeed",
    Range = {16, 200},
    Increment = 2,
    Suffix = "Speed",
    CurrentValue = 16,
    Callback = function(v)
        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = v end
    end,
})

MovementTab:CreateSlider({
    Name = "JumpPower",
    Range = {50, 300},
    Increment = 5,
    Suffix = "Power",
    CurrentValue = 50,
    Callback = function(v)
        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.JumpPower = v end
    end,
})

-- infinite jump UI improved (connect once)
do
    local infJumpEnabled = false
    local infConn
    MovementTab:CreateToggle({
        Name = "Infinite Jump",
        CurrentValue = false,
        Callback = function(state)
            infJumpEnabled = state
            if infConn then infConn:Disconnect() infConn = nil end
            if state then
                infConn = UserInputService.JumpRequest:Connect(function()
                    local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                    if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
                end)
            end
        end,
    })
end

-- Improved Noclip with proper connection handling
local noclipConnection = nil
local noclipEnabled = false

MovementTab:CreateToggle({
    Name = "Noclip",
    CurrentValue = false,
    Callback = function(state)
        noclipEnabled = state
        if state then
            if noclipConnection then noclipConnection:Disconnect() end
            noclipConnection = RunService.Stepped:Connect(function()
                local char = LocalPlayer.Character
                if not char then return end
                for _, v in pairs(char:GetDescendants()) do
                    if v:IsA("BasePart") then
                        v.CanCollide = false
                    end
                end
            end)
        else
            if noclipConnection then noclipConnection:Disconnect() noclipConnection = nil end
            local char = LocalPlayer.Character
            if char then
                for _, v in pairs(char:GetDescendants()) do
                    if v:IsA("BasePart") then
                        v.CanCollide = true
                    end
                end
            end
        end
    end,
})

-- =========================================================
-- ADDITIONAL MOVEMENT FEATURES (from source)
-- =========================================================

-- CFrame Fly (alternative fly mode)
local cframeFlyEnabled = false
local cfFlySpeed = 100
local cfFlyConnection

MovementTab:CreateToggle({
    Name = "CFrame Fly (alt)",
    CurrentValue = false,
    Callback = function(state)
        cframeFlyEnabled = state
        if state then
            cfFlyConnection = RunService.RenderStepped:Connect(function()
                local char = LocalPlayer.Character
                local root = getRoot(char)
                if not root then return end

                local move = Vector3.new()
                local cam = Camera.CFrame

                if UserInputService:IsKeyDown(Enum.KeyCode.W) then move += cam.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then move -= cam.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then move -= cam.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then move += cam.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.Space) then move += Vector3.new(0,1,0) end
                if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then move -= Vector3.new(0,1,0) end

                if move.Magnitude > 0 then
                    local target = root.Position + move.Unit * cfFlySpeed * RunService.RenderStepped:Wait()
                    root.CFrame = CFrame.new(target, target + cam.LookVector)
                end
            end)
        else
            if cfFlyConnection then cfFlyConnection:Disconnect() cfFlyConnection = nil end
        end
    end,
})

MovementTab:CreateSlider({
    Name = "CFrameFly Speed",
    Range = {20, 800},
    Increment = 10,
    Suffix = "spd",
    CurrentValue = cfFlySpeed,
    Callback = function(v) cfFlySpeed = v end
})

-- Q/E Fly (quick ascend/descend)
local qeFlyEnabled = false
MovementTab:CreateToggle({
    Name = "QE Fly (ascend/descend)",
    CurrentValue = false,
    Callback = function(state)
        qeFlyEnabled = state
        if state then
            -- use simple upward movement when holding Q/E
            RunService.RenderStepped:Connect(function()
                if not qeFlyEnabled then return end
                local char = LocalPlayer.Character; local root = getRoot(char)
                if not root then return end
                if UserInputService:IsKeyDown(Enum.KeyCode.Q) then
                    root.CFrame = root.CFrame + Vector3.new(0, -8 * RunService.RenderStepped:Wait(), 0)
                end
                if UserInputService:IsKeyDown(Enum.KeyCode.E) then
                    root.CFrame = root.CFrame + Vector3.new(0, 8 * RunService.RenderStepped:Wait(), 0)
                end
            end)
        end
    end
})

-- Walkspeed/Jump spoof toggles (store original and restore)
local originalWalkSpeed = nil
local walkSpoofEnabled = false
MovementTab:CreateToggle({
    Name = "Spoof WalkSpeed (set & lock)",
    CurrentValue = false,
    Callback = function(state)
        walkSpoofEnabled = state
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if state then
            if hum then
                originalWalkSpeed = hum.WalkSpeed
                hum.WalkSpeed = 50 -- default spoof; user can manual slider above
            end
        else
            if hum and originalWalkSpeed then
                hum.WalkSpeed = originalWalkSpeed
                originalWalkSpeed = nil
            end
        end
    end
})

local originalJumpPower = nil
local jumpSpoofEnabled = false
MovementTab:CreateToggle({
    Name = "Spoof JumpPower (lock)",
    CurrentValue = false,
    Callback = function(state)
        jumpSpoofEnabled = state
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if state then
            if hum then
                originalJumpPower = hum.JumpPower
                hum.JumpPower = 100
            end
        else
            if hum and originalJumpPower then
                hum.JumpPower = originalJumpPower
                originalJumpPower = nil
            end
        end
    end
})

-- Gravity changer
local originalGravity = workspace.Gravity
local function setGravity(v)
    workspace.Gravity = v
end
MovementTab:CreateSlider({
    Name = "Gravity",
    Range = {0, 196},
    Increment = 1,
    Suffix = "g",
    CurrentValue = originalGravity,
    Callback = function(v) setGravity(v) end
})

-- =========================================================
-- PLAYER TAB (Godmode, tool dup, fake lag) kept & extended
-- =========================================================
local godModeEnabled = false
local godConnections = {}
local oldNamecall

local function applyGodMode(char)
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hum or not hrp then return end

    table.insert(godConnections, hum.HealthChanged:Connect(function()
        if godModeEnabled and hum.Health < hum.MaxHealth then
            hum.Health = hum.MaxHealth
        end
    end))

    table.insert(godConnections, RunService.Stepped:Connect(function()
        if godModeEnabled and hrp.Position.Y < -5 then
            hrp.Velocity = Vector3.zero
            hrp.CFrame = CFrame.new(0, 10, 0)
        end
    end))

    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            part.Touched:Connect(function(hit)
                if godModeEnabled then
                    hum.Health = hum.MaxHealth
                end
            end)
        end
    end
end

PlayerTab:CreateToggle({
    Name = "God Mode ",
    CurrentValue = false,
    Callback = function(state)
        godModeEnabled = state

        for _, con in ipairs(godConnections) do
            if typeof(con) == "RBXScriptConnection" then
                con:Disconnect()
            end
        end
        table.clear(godConnections)

        if state then
            local char = LocalPlayer.Character
            if char then applyGodMode(char) end

            table.insert(godConnections, LocalPlayer.CharacterAdded:Connect(function(newChar)
                task.wait(1)
                applyGodMode(newChar)
            end))

            -- hook remote events (anti-kill / anti-damage) - best-effort
            if not oldNamecall and hookmetamethod then
                oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
                    local method = getnamecallmethod()
                    if godModeEnabled and (self:IsA("RemoteEvent") or self:IsA("RemoteFunction")) then
                        local args = {...}
                        if tostring(self):lower():find("damage") or tostring(self):lower():find("kill") then
                            return nil
                        end
                        if method == "FireServer" or method == "InvokeServer" then
                            if typeof(args[1]) == "number" and args[1] < 0 then
                                return nil
                            end
                        end
                    end
                    return oldNamecall(self, ...)
                end)
            end
        end
    end,
})

-- Tool duplicator (unchanged)
local function duplicateTools()
    local char = LocalPlayer.Character
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if not backpack then return end

    local allTools = {}
    for _, tool in ipairs(backpack:GetChildren()) do
        if tool:IsA("Tool") then
            table.insert(allTools, tool)
        end
    end
    if char then
        for _, tool in ipairs(char:GetChildren()) do
            if tool:IsA("Tool") then
                table.insert(allTools, tool)
            end
        end
    end

    if #allTools == 0 then
        warn("No tools found to duplicate.")
        return
    end

    for _, tool in ipairs(allTools) do
        local clone = tool:Clone()
        clone.Parent = backpack
    end
end

PlayerTab:CreateButton({
    Name = "Duplicate Tools (Clone All)",
    Callback = function()
        duplicateTools()
        notify("Duplicate Tools", "Cloned tools to Backpack", 3)
    end,
})

-- Fake lag (kept) + Lag Switch simple toggle
local fakeLagEnabled = false
local fakeLagConnection
local storedCFrame

PlayerTab:CreateToggle({
    Name = "Fake Lag / Desync",
    CurrentValue = false,
    Callback = function(state)
        fakeLagEnabled = state

        if fakeLagEnabled then
            fakeLagConnection = RunService.Stepped:Connect(function()
                local char = LocalPlayer.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if not hrp then return end

                if not storedCFrame then
                    storedCFrame = hrp.CFrame
                end

                if tick() % 1 < 0.2 then
                    hrp.CFrame = storedCFrame
                else
                    storedCFrame = hrp.CFrame
                end
            end)
        else
            if fakeLagConnection then fakeLagConnection:Disconnect() fakeLagConnection = nil end
            storedCFrame = nil
        end
    end,
})

-- Simple lag-switch toggle (blocks network by anchoring HRP occasionally)
local lagSwitchEnabled = false
local lagSwitchConn
PlayerTab:CreateToggle({
    Name = "Lag Switch (spam anchor)",
    CurrentValue = false,
    Callback = function(state)
        lagSwitchEnabled = state
        if state then
            lagSwitchConn = RunService.Heartbeat:Connect(function()
                local char = LocalPlayer.Character; local hrp = getRoot(char)
                if not hrp then return end
                hrp.Anchored = true
                task.wait(0.05)
                hrp.Anchored = false
                task.wait(0.5)
            end)
        else
            if lagSwitchConn then lagSwitchConn:Disconnect() lagSwitchConn = nil end
        end
    end,
})

-- =========================================================
-- TROLL TAB (existing + extra features)
-- =========================================================
local selectedPlayer = nil
local loopKilling = false
local annoyEnabled = false

TrollTab:CreateToggle({
    Name = "Annoy Mode",
    CurrentValue = false,
    Callback = function(state)
        annoyEnabled = state
        if state then
            task.spawn(function()
                while annoyEnabled and selectedPlayer and selectedPlayer.Character and selectedPlayer.Character:FindFirstChild("HumanoidRootPart") do
                    local hrp = selectedPlayer.Character.HumanoidRootPart
                    local action = math.random(1, 4)

                    if action == 1 then
                        local lp = LocalPlayer
                        local myhrp = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
                        if myhrp then
                            local bp = Instance.new("BodyPosition", myhrp)
                            bp.MaxForce = Vector3.new(1e9, 1e9, 1e9)
                            bp.P = 1e5
                            bp.Position = hrp.Position + Vector3.new(0, 5, 0)
                            game:GetService("Debris"):AddItem(bp, 0.3)
                        end

                    elseif action == 2 then
                        local lp = LocalPlayer
                        local myhrp = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
                        if myhrp then
                            hrp.CFrame = myhrp.CFrame * CFrame.new(0, 3, 0)
                        end

                    elseif action == 3 then
                        hrp.Anchored = not hrp.Anchored

                    elseif action == 4 then
                        -- small teleport glitch
                        hrp.CFrame = hrp.CFrame + Vector3.new(math.random(-5,5), math.random(0,5), math.random(-5,5))
                    end

                    task.wait(math.random(1, 3))
                end
            end)
        end
    end,
})

local function getPlayerNames()
    local names = {}
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            table.insert(names, plr.Name)
        end
    end
    return names
end

local PlayerDropdown = TrollTab:CreateDropdown({
    Name = "Select Player",
    Options = getPlayerNames(),
    CurrentOption = nil,
    Flag = "PlayerDropdown",
    Callback = function(option)
        selectedPlayer = game.Players:FindFirstChild(option)
    end,
})

TrollTab:CreateButton({
    Name = "Refresh Player List",
    Callback = function()
        PlayerDropdown:Set(getPlayerNames())
    end,
})

TrollTab:CreateButton({
    Name = "Fling Player",
    Callback = function()
        if selectedPlayer and selectedPlayer.Character and selectedPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local lp = LocalPlayer
            local hrp = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                task.spawn(function()
                    local bp = Instance.new("BodyPosition", hrp)
                    bp.MaxForce = Vector3.new(1e9, 1e9, 1e9)
                    bp.P = 1e5
                    for i = 1, 50 do
                        bp.Position = selectedPlayer.Character.HumanoidRootPart.Position + Vector3.new(0, 5, 0)
                        task.wait(0.05)
                    end
                    bp:Destroy()
                end)
            end
        end
    end,
})

TrollTab:CreateButton({
    Name = "Freeze Player",
    Callback = function()
        if selectedPlayer and selectedPlayer.Character and selectedPlayer.Character:FindFirstChild("HumanoidRootPart") then
            selectedPlayer.Character.HumanoidRootPart.Anchored = true
        end
    end,
})

TrollTab:CreateButton({
    Name = "Unfreeze Player",
    Callback = function()
        if selectedPlayer and selectedPlayer.Character and selectedPlayer.Character:FindFirstChild("HumanoidRootPart") then
            selectedPlayer.Character.HumanoidRootPart.Anchored = false
        end
    end,
})

TrollTab:CreateButton({
    Name = "Bring Player",
    Callback = function()
        if selectedPlayer and selectedPlayer.Character and selectedPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local lp = LocalPlayer
            local hrp = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                selectedPlayer.Character.HumanoidRootPart.CFrame = hrp.CFrame * CFrame.new(0, 3, 0)
            end
        end
    end,
})

TrollTab:CreateToggle({
    Name = "Loop Kill (target)",
    CurrentValue = false,
    Callback = function(state)
        loopKilling = state
        if state then
            task.spawn(function()
                while loopKilling and selectedPlayer and selectedPlayer.Character do
                    local char = selectedPlayer.Character
                    local hum = char:FindFirstChildOfClass("Humanoid")
                    if hum then hum.Health = 0 end
                    task.wait(1)
                end
            end)
        end
    end,
})

-- Extra: Orbit player (make selected player orbit around our HRP)
TrollTab:CreateToggle({
    Name = "Orbit Target",
    CurrentValue = false,
    Callback = function(state)
        if state then
            task.spawn(function()
                while PlayerDropdown:Get() and Players:FindFirstChild(PlayerDropdown:Get()) and TrollTab.Flags and TrollTab.Flags["OrbitTarget"] == nil do
                    -- placeholder to satisfy UI; Rayfield doesn't expose flag directly in this context
                    task.wait(0.3)
                end
            end)
        end
    end
})

-- =========================================================
-- UTILITY TAB (Teleport tool, anti-afk, click-TP/delete, mouse TP, copy pos, waypoints)
-- =========================================================

UtilityTab:CreateButton({
    Name = "Teleport Tool",
    Callback = function()
        local tool = Instance.new("Tool", LocalPlayer.Backpack)
        tool.RequiresHandle = false
        tool.Name = "Teleport Tool"
        tool.Activated:Connect(function()
            local mouse = LocalPlayer:GetMouse()
            if LocalPlayer.Character then
                LocalPlayer.Character:MoveTo(mouse.Hit.p)
            end
        end)
        notify("Teleport Tool", "Placed Teleport Tool in Backpack", 3)
    end,
})

-- Anti-AFK (improved single connection)
do
    local antiAfkConn
    UtilityTab:CreateToggle({
        Name = "Anti-AFK",
        CurrentValue = false,
        Callback = function(state)
            if antiAfkConn then antiAfkConn:Disconnect() antiAfkConn = nil end
            if state then
                local vu = game:GetService("VirtualUser")
                antiAfkConn = LocalPlayer.Idled:Connect(function()
                    vu:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
                    task.wait(1)
                    vu:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
                end)
            end
        end,
    })
end

-- Click TP & Click Delete (hold keys + click)
do
    local CLICK_TP_ENABLED = false
    local CLICK_DEL_ENABLED = false
    local CLICK_TP_KEYCODE = Enum.KeyCode.LeftShift
    local CLICK_DEL_KEYCODE = Enum.KeyCode.LeftControl

    mouse.Button1Down:Connect(function()
        if CLICK_TP_ENABLED and UserInputService:IsKeyDown(CLICK_TP_KEYCODE) then
            pcall(function()
                local char = LocalPlayer.Character
                if not char then return end
                local root = getRoot(char)
                if not root then return end
                local hit = mouse.Hit.Position
                root.CFrame = CFrame.new(hit.X, hit.Y + 3, hit.Z)
            end)
        end

        if CLICK_DEL_ENABLED and UserInputService:IsKeyDown(CLICK_DEL_KEYCODE) then
            pcall(function()
                local target = mouse.Target
                if not target then return end
                local model = target:FindFirstAncestorOfClass("Model")
                if model and Players:FindFirstChild(model.Name) then
                    local hum = model:FindFirstChildOfClass("Humanoid")
                    if hum then hum.Health = 0 end
                    return
                end
                if model and model ~= workspace then
                    pcall(function() model:Destroy() end)
                else
                    pcall(function() target:Destroy() end)
                end
            end)
        end
    end)

    MovementTab:CreateToggle({
        Name = "Click TP (hold Shift + click)",
        CurrentValue = false,
        Callback = function(state) CLICK_TP_ENABLED = state end,
    })

    MovementTab:CreateToggle({
        Name = "Click Delete (hold Ctrl + click)",
        CurrentValue = false,
        Callback = function(state) CLICK_DEL_ENABLED = state end,
    })
end

-- Mouse TP (one-shot teleport)
UtilityTab:CreateButton({
    Name = "Mouse TP (instant)",
    Callback = function()
        local char = LocalPlayer.Character
        local root = getRoot(char)
        if not root then notify("Mouse TP", "Missing character/root", 3); return end
        local pos = mouse.Hit.Position
        root.CFrame = CFrame.new(pos.X, pos.Y + 3, pos.Z)
    end,
})

-- Get Position (notify) & Copy Position (clipboard)
UtilityTab:CreateButton({
    Name = "Get Position (notify)",
    Callback = function()
        local char = LocalPlayer.Character
        local root = getRoot(char)
        if not root then notify("Get Position", "No root found", 3); return end
        local pos = root.Position
        local roundedPos = math.floor(pos.X) .. ", " .. math.floor(pos.Y) .. ", " .. math.floor(pos.Z)
        notify("Current Position", roundedPos, 5)
    end,
})

UtilityTab:CreateButton({
    Name = "Copy Position",
    Callback = function()
        local char = LocalPlayer.Character
        local root = getRoot(char)
        if not root then notify("Copy Position", "No root found", 3); return end
        local pos = root.Position
        local roundedPos = math.floor(pos.X) .. ", " .. math.floor(pos.Y) .. ", " .. math.floor(pos.Z)
        pcall(function()
            if setclipboard then setclipboard(roundedPos)
            elseif toclipboard then toclipboard(roundedPos)
            end
        end)
        notify("Copy Position", roundedPos, 3)
    end,
})

-- Waypoints: Add / Remove / Teleport
do
    local waypoints = {}
    UtilityTab:CreateButton({
        Name = "Save Waypoint (current pos)",
        Callback = function()
            local char = LocalPlayer.Character
            local root = getRoot(char)
            if not root then notify("Waypoint", "No root", 3); return end
            table.insert(waypoints, root.CFrame)
            notify("Waypoint", "Saved waypoint #" .. tostring(#waypoints), 3)
        end,
    })

    UtilityTab:CreateButton({
        Name = "List Waypoints",
        Callback = function()
            if #waypoints == 0 then notify("Waypoints", "No saved waypoints", 3); return end
            for i, cf in ipairs(waypoints) do
                notify("Waypoint " .. i, tostring(math.floor(cf.p.X) .. "," .. math.floor(cf.p.Y) .. "," .. math.floor(cf.p.Z)), 2)
                task.wait(0.25)
            end
        end,
    })

    UtilityTab:CreateButton({
        Name = "Teleport to Last Waypoint",
        Callback = function()
            if #waypoints == 0 then notify("Waypoints", "No saved waypoints", 3); return end
            local root = getRoot(LocalPlayer.Character)
            if root then root.CFrame = waypoints[#waypoints] end
        end,
    })

    UtilityTab:CreateButton({
        Name = "Clear Waypoints",
        Callback = function()
            waypoints = {}
            notify("Waypoints", "Cleared", 2)
        end,
    })
end

-- Rejoin / Serverhop simple controls (best-effort)
UtilityTab:CreateButton({
    Name = "Rejoin (teleport to same place)",
    Callback = function()
        pcall(function() TeleportService:Teleport(game.PlaceId, LocalPlayer) end)
    end,
})

-- =========================================================
-- COMBAT TAB (bullet noclip kept + kill-aura simple)
-- =========================================================
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
                oldRaycast = nil
            end
        end
    end,
})

-- Kill Aura (very simple; damages nearby humanoids)
do
    local killAuraEnabled = false
    local killRange = 20
    CombatTab:CreateToggle({
        Name = "Kill-Aura (nearby)",
        CurrentValue = false,
        Callback = function(state)
            killAuraEnabled = state
            if state then
                task.spawn(function()
                    while killAuraEnabled do
                        local myRoot = getRoot(LocalPlayer.Character)
                        if myRoot then
                            for _, plr in ipairs(Players:GetPlayers()) do
                                if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChildOfClass("Humanoid") then
                                    local hrp = getRoot(plr.Character)
                                    if hrp and (hrp.Position - myRoot.Position).Magnitude <= killRange then
                                        local hum = plr.Character:FindFirstChildOfClass("Humanoid")
                                        if hum then hum.Health = 0 end
                                    end
                                end
                            end
                        end
                        task.wait(0.5)
                    end
                end)
            end
        end,
    })

    CombatTab:CreateSlider({
        Name = "KillAura Range",
        Range = {5, 200},
        Increment = 1,
        Suffix = "m",
        CurrentValue = killRange,
        Callback = function(v) killRange = v end,
    })
end

-- =========================================================
-- VISUALS: FOV, Tracers, Name & Distance tags, Extra ESP types
-- =========================================================
do
    local originalFOV = Camera.FieldOfView
    VisualsTab:CreateSlider({
        Name = "Field of View",
        Range = {70, 120},
        Increment = 1,
        Suffix = "°",
        CurrentValue = originalFOV,
        Callback = function(v) Camera.FieldOfView = v end,
    })

    VisualsTab:CreateButton({
        Name = "Reset FOV",
        Callback = function() Camera.FieldOfView = originalFOV end
    })
end

-- Name+Distance tags (billboard)
local nameTagsEnabled = false
local nameTagFolder = Instance.new("Folder", game.CoreGui)
nameTagFolder.Name = "NameTags"
VisualsTab:CreateToggle({
    Name = "Name + Distance Tags",
    CurrentValue = false,
    Callback = function(state)
        nameTagsEnabled = state
        nameTagFolder:ClearAllChildren()
        if state then
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                    local billboard = Instance.new("BillboardGui")
                    billboard.Name = plr.Name .. "_tag"
                    billboard.Size = UDim2.new(0,100,0,40)
                    billboard.Adornee = plr.Character.HumanoidRootPart
                    billboard.AlwaysOnTop = true
                    local txt = Instance.new("TextLabel", billboard)
                    txt.Size = UDim2.new(1,0,1,0)
                    txt.BackgroundTransparency = 1
                    txt.Text = plr.Name
                    txt.TextScaled = true
                    billboard.Parent = nameTagFolder
                end
            end
            Players.PlayerAdded:Connect(function(plr)
                if nameTagsEnabled and plr ~= LocalPlayer then
                    task.wait(0.5)
                    if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                        local billboard = Instance.new("BillboardGui")
                        billboard.Name = plr.Name .. "_tag"
                        billboard.Size = UDim2.new(0,100,0,40)
                        billboard.Adornee = plr.Character.HumanoidRootPart
                        billboard.AlwaysOnTop = true
                        local txt = Instance.new("TextLabel", billboard)
                        txt.Size = UDim2.new(1,0,1,0)
                        txt.BackgroundTransparency = 1
                        txt.Text = plr.Name
                        txt.TextScaled = true
                        billboard.Parent = nameTagFolder
                    end
                end
            end)
        else
            nameTagFolder:ClearAllChildren()
        end
    end,
})

-- =========================================================
-- SAFE ACTIONS: Reset, Sit/Unsit, Suicide
-- =========================================================
PlayerTab:CreateButton({Name = "Reset (Humanoid:BreakJoints)", Callback = function()
    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum.Health = 0 end
    end
end})

PlayerTab:CreateButton({Name = "Sit", Callback = function()
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then hum.Sit = true end
end})

PlayerTab:CreateButton({Name = "Unsit", Callback = function()
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then hum.Sit = false end
end})

PlayerTab:CreateButton({Name = "Suicide (self)", Callback = function()
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then hum.Health = 0 end
end})

-- =========================================================
-- MISC TOOLS (from source)
-- =========================================================

-- Remove Fog toggle
VisualsTab:CreateToggle({
    Name = "Remove Fog",
    CurrentValue = false,
    Callback = function(state)
        if state then
            workspace.FogEnd = 100000
            workspace.FogStart = 0
        else
            workspace.FogEnd = 100000
            workspace.FogStart = 0
        end
    end,
})

-- Gravity reset button
MovementTab:CreateButton({Name = "Reset Gravity", Callback = function() workspace.Gravity = originalGravity notify("Gravity", "Reset",2) end})

