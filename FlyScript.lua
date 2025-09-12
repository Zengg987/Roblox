local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- =========================================================
-- WINDOW
-- =========================================================
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
-- ESP SYSTEM (Friend = Green | Enemy = Red)
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
    if player == game.Players.LocalPlayer then return end
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
            for _, plr in ipairs(game.Players:GetPlayers()) do
                if plr.Character then createESP(plr) end
            end
        end
    end,
})

game.Players.PlayerAdded:Connect(function(plr)
    if espEnabled then
        plr.CharacterAdded:Connect(function()
            task.wait(1)
            if espEnabled then createESP(plr) end
        end)
    end
end)


-- =========================================================
-- MOVEMENT
-- =========================================================
local savedSpeed = 50
local flying = false
local flySpeed = savedSpeed
local forwardHold = 0
local inputFlags = { forward = false, back = false, left = false, right = false, up = false, down = false }

local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local lp = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local bodyVelocity = Instance.new("BodyVelocity")
bodyVelocity.MaxForce = Vector3.new(1e5, 1e5, 1e5)

local bodyGyro = Instance.new("BodyGyro")
bodyGyro.MaxTorque = Vector3.new(1e5, 1e5, 1e5)

local humanoid, HRP
local function getChar()
    local char = lp.Character or lp.CharacterAdded:Wait()
    humanoid = char:WaitForChild("Humanoid")
    HRP = char:WaitForChild("HumanoidRootPart")
end
getChar()
lp.CharacterAdded:Connect(getChar)

-- animations setup
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
        track:Stop()
    end
end

local function startFlying()
    flying = true
    forwardHold = 0
    flySpeed = savedSpeed
    bodyVelocity.Parent = HRP
    bodyGyro.Parent = HRP
    humanoid.PlatformStand = true
end

local function stopFlying()
    flying = false
    bodyVelocity.Parent = nil
    bodyGyro.Parent = nil
    humanoid.PlatformStand = false
    stopAll()
end

-- input handling
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

-- GUI controls
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
        local hum = game.Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
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
        local hum = game.Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.JumpPower = v end
    end,
})

MovementTab:CreateToggle({
    Name = "Infinite Jump",
    CurrentValue = false,
    Callback = function(state)
        game.UserInputService.JumpRequest:Connect(function()
            if state then
                local hum = game.Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                hum:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end)
    end,
})

MovementTab:CreateToggle({
    Name = "Noclip",
    CurrentValue = false,
    Callback = function(state)
        local char = game.Players.LocalPlayer.Character
        if state then
            game:GetService("RunService").Stepped:Connect(function()
                for _, v in pairs(char:GetDescendants()) do
                    if v:IsA("BasePart") then
                        v.CanCollide = false
                    end
                end
            end)
        end
    end,
})

-- =========================================================
-- PLAYER
-- =========================================================
PlayerTab:CreateToggle({
    Name = "Godmode (Humanoid Immortal)",
    CurrentValue = false,
    Callback = function(state)
        local hum = game.Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.Name = state and "GodHumanoid" or "Humanoid"
        end
    end,
})

-- =========================================================
-- TROLL TAB
-- =========================================================

local selectedPlayer = nil
local loopKilling = false
-- Annoy Mode
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
                    local action = math.random(1, 3)

                    if action == 1 then
                        -- fling
                        local lp = game.Players.LocalPlayer
                        local myhrp = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
                        if myhrp then
                            local bp = Instance.new("BodyPosition", myhrp)
                            bp.MaxForce = Vector3.new(1e9, 1e9, 1e9)
                            bp.P = 1e5
                            bp.Position = hrp.Position + Vector3.new(0, 5, 0)
                            game:GetService("Debris"):AddItem(bp, 0.3)
                        end

                    elseif action == 2 then
                        -- bring
                        local lp = game.Players.LocalPlayer
                        local myhrp = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
                        if myhrp then
                            hrp.CFrame = myhrp.CFrame * CFrame.new(0, 3, 0)
                        end

                    elseif action == 3 then
                        -- freeze / unfreeze toggle
                        hrp.Anchored = not hrp.Anchored
                    end

                    task.wait(math.random(1, 3)) -- random delay for chaos
                end
            end)
        end
    end,
})

-- Dropdown to select target player
local function getPlayerNames()
    local names = {}
    for _, plr in ipairs(game.Players:GetPlayers()) do
        if plr ~= game.Players.LocalPlayer then
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

-- Refresh player list button
TrollTab:CreateButton({
    Name = "Refresh Player List",
    Callback = function()
        PlayerDropdown:Set(getPlayerNames())
    end,
})

-- Fling
TrollTab:CreateButton({
    Name = "Fling Player",
    Callback = function()
        if selectedPlayer and selectedPlayer.Character and selectedPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local lp = game.Players.LocalPlayer
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

-- Freeze
TrollTab:CreateButton({
    Name = "Freeze Player",
    Callback = function()
        if selectedPlayer and selectedPlayer.Character and selectedPlayer.Character:FindFirstChild("HumanoidRootPart") then
            selectedPlayer.Character.HumanoidRootPart.Anchored = true
        end
    end,
})

-- Unfreeze
TrollTab:CreateButton({
    Name = "Unfreeze Player",
    Callback = function()
        if selectedPlayer and selectedPlayer.Character and selectedPlayer.Character:FindFirstChild("HumanoidRootPart") then
            selectedPlayer.Character.HumanoidRootPart.Anchored = false
        end
    end,
})

-- Bring Player
TrollTab:CreateButton({
    Name = "Bring Player",
    Callback = function()
        if selectedPlayer and selectedPlayer.Character and selectedPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local lp = game.Players.LocalPlayer
            local hrp = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                selectedPlayer.Character.HumanoidRootPart.CFrame = hrp.CFrame * CFrame.new(0, 3, 0)
            end
        end
    end,
})

-- Loop Kill
TrollTab:CreateToggle({
    Name = "Loop Kill",
    CurrentValue = false,
    Callback = function(state)
        loopKilling = state
        if state then
            task.spawn(function()
                while loopKilling and selectedPlayer and selectedPlayer.Character do
                    local char = selectedPlayer.Character
                    local hum = char:FindFirstChildOfClass("Humanoid")
                    if hum then
                        hum.Health = 0
                    end
                    task.wait(1)
                end
            end)
        end
    end,
})

-- =========================================================
-- UTILITY
-- =========================================================
UtilityTab:CreateButton({
    Name = "Teleport Tool",
    Callback = function()
        local tool = Instance.new("Tool", game.Players.LocalPlayer.Backpack)
        tool.RequiresHandle = false
        tool.Name = "Teleport Tool"
        tool.Activated:Connect(function()
            local mouse = game.Players.LocalPlayer:GetMouse()
            game.Players.LocalPlayer.Character:MoveTo(mouse.Hit.p)
        end)
    end,
})

UtilityTab:CreateToggle({
    Name = "Anti-AFK",
    CurrentValue = false,
    Callback = function(state)
        local vu = game:GetService("VirtualUser")
        if state then
            game.Players.LocalPlayer.Idled:Connect(function()
                vu:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
                task.wait(1)
                vu:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
            end)
        end
    end,
})

-- =========================================================
-- COMBAT
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
            end
        end
    end,
})
