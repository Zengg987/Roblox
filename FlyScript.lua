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
PLAYER
-- =========================================================
local godModeEnabled = false
local godConnections = {}
local oldNamecall

local function applyGodMode(char)
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hum or not hrp then return end

    -- Keep health locked
    table.insert(godConnections, hum.HealthChanged:Connect(function()
        if godModeEnabled and hum.Health < hum.MaxHealth then
            hum.Health = hum.MaxHealth
        end
    end))

    -- Block void kill / fall damage
    table.insert(godConnections, game:GetService("RunService").Stepped:Connect(function()
        if godModeEnabled and hrp.Position.Y < -5 then
            hrp.Velocity = Vector3.zero
            hrp.CFrame = CFrame.new(0, 10, 0)
        end
    end))

    -- Block kill parts / traps
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

        -- cleanup old connections
        for _, con in ipairs(godConnections) do
            if typeof(con) == "RBXScriptConnection" then
                con:Disconnect()
            end
        end
        table.clear(godConnections)

        if state then
            local char = game.Players.LocalPlayer.Character
            if char then applyGodMode(char) end

            -- auto reapply on respawn
            table.insert(godConnections, game.Players.LocalPlayer.CharacterAdded:Connect(function(newChar)
                task.wait(1)
                applyGodMode(newChar)
            end))

            -- hook remote events (anti-kill / anti-damage)
            if not oldNamecall then
                oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
                    local method = getnamecallmethod()
                    if godModeEnabled and self:IsA("RemoteEvent") or self:IsA("RemoteFunction") then
                        local args = {...}
                        -- detect kill/damage attempts
                        if tostring(self):lower():find("damage") or tostring(self):lower():find("kill") then
                            return nil -- block it
                        end
                        if method == "FireServer" or method == "InvokeServer" then
                            -- stop remote that sets health
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
-- =========================================================
-- ANTI-COOLDOWN (Multi-approach)
-- =========================================================
local antiCdEnabled = false
local antiCdConnections = {}
local oldNamecall = nil
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- helper: sanitize arg tables by zeroing cooldown-like fields
local function sanitizeArgs(args)
    for i, v in ipairs(args) do
        -- if arg is a table, try to zero common cooldown keys
        if type(v) == "table" then
            for k, val in pairs(v) do
                local keyLower = tostring(k):lower()
                if keyLower:find("cool") or keyLower:find("cd") or keyLower:find("delay") or keyLower:find("time") then
                    pcall(function() v[k] = 0 end)
                end
            end
        elseif type(v) == "number" then
            -- if numeric and looks like a cooldown (positive, reasonable), set to 0
            if v > 0 and v < 60 then
                args[i] = 0
            end
        end
    end
    return args
end

-- hook metamethod to intercept remote calls and sanitize
local function enableNamecallHook()
    if oldNamecall then return end
    oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
        local method = getnamecallmethod()
        if antiCdEnabled and (self:IsA("RemoteEvent") or self:IsA("RemoteFunction")) then
            local args = {...}
            local ok, newArgs = pcall(function() return sanitizeArgs(args) end)
            if ok and newArgs then
                if method == "FireServer" then
                    return oldNamecall(self, table.unpack(newArgs))
                elseif method == "InvokeServer" then
                    return oldNamecall(self, table.unpack(newArgs))
                end
            end
        end
        return oldNamecall(self, ...)
    end)
end

local function disableNamecallHook()
    if oldNamecall then
        -- We can't safely restore original hookmetamethod pointer in many exploit environments.
        -- Some exploit environments let you store the original and restore; if so, restore here.
        -- For safety, just nil it so future enables re-hook.
        oldNamecall = nil
    end
end

-- Rapid-fire any remote inside a tool when tool is activated
local function patchToolRapidFire(tool)
    if not tool or not tool:IsA("Tool") then return end
    if tool:FindFirstChild("__antiCdPatched") then return end
    local mark = Instance.new("BoolValue")
    mark.Name = "__antiCdPatched"
    mark.Parent = tool

    local function findRemotes(container)
        local remotes = {}
        for _, v in ipairs(container:GetDescendants()) do
            if v:IsA("RemoteEvent") or v:IsA("RemoteFunction") then
                table.insert(remotes, v)
            end
        end
        return remotes
    end

    local remotes = findRemotes(tool)

    local conn
    conn = tool.Activated:Connect(function()
        if not antiCdEnabled then return end
        -- try to remove local debounce flags inside the tool
        for _, v in ipairs(tool:GetDescendants()) do
            if v:IsA("BoolValue") and tostring(v.Name):lower():find("deb") then
                pcall(function() v.Value = false end)
            elseif v:IsA("NumberValue") or v:IsA("IntValue") then
                local nameL = tostring(v.Name):lower()
                if nameL:find("cool") or nameL:find("cd") then
                    pcall(function() v.Value = 0 end)
                end
            end
        end

        -- fire remotes quickly (small burst)
        for _, r in ipairs(remotes) do
            -- spawn so one remote doesn't block others
            task.spawn(function()
                for i = 1, 4 do -- burst count; tweak if needed
                    if not antiCdEnabled then break end
                    pcall(function()
                        if r:IsA("RemoteEvent") then
                            r:FireServer()
                        elseif r:IsA("RemoteFunction") then
                            -- safe: only call if it won't block main thread too long
                            local ok = pcall(function() r:InvokeServer() end)
                        end
                    end)
                    task.wait(0.05) -- tiny spacing
                end
            end)
        end
    end)

    antiCdConnections[#antiCdConnections+1] = conn
end

-- Remove/zero local debounce-like objects on tools/character
local function removeLocalDebounces(instance)
    for _, v in ipairs(instance:GetDescendants()) do
        if v:IsA("BoolValue") then
            local n = tostring(v.Name):lower()
            if n:find("deb") or n:find("canuse") then
                pcall(function() v.Value = false end)
            end
        elseif v:IsA("NumberValue") or v:IsA("IntValue") then
            local n = tostring(v.Name):lower()
            if n:find("cool") or n:find("cd") or n:find("delay") then
                pcall(function() v.Value = 0 end)
            end
        end
    end
end

-- watch for new tools and patch them
local function watchTools()
    -- patch existing
    for _, tool in ipairs(LocalPlayer.Backpack:GetChildren()) do
        if tool:IsA("Tool") then
            patchToolRapidFire(tool)
            removeLocalDebounces(tool)
        end
    end
    -- patch tools when added to backpack
    antiCdConnections[#antiCdConnections+1] = LocalPlayer.Backpack.ChildAdded:Connect(function(child)
        if antiCdEnabled and child:IsA("Tool") then
            task.wait(0.1)
            patchToolRapidFire(child)
            removeLocalDebounces(child)
        end
    end)
    -- patch tools equipped in character
    antiCdConnections[#antiCdConnections+1] = LocalPlayer.CharacterAdded:Connect(function(char)
        task.wait(0.5)
        for _, tool in ipairs(char:GetChildren()) do
            if tool:IsA("Tool") then
                patchToolRapidFire(tool)
                removeLocalDebounces(tool)
            end
        end
        -- also clean debounces on character
        removeLocalDebounces(char)
    end)
end

-- main toggle
PlayerTab:CreateToggle({
    Name = "Anti-Cooldown",
    CurrentValue = false,
    Callback = function(state)
        antiCdEnabled = state

        -- cleanup previous connectors
        for _, con in ipairs(antiCdConnections) do
            if typeof(con) == "RBXScriptConnection" then
                pcall(function() con:Disconnect() end)
            end
        end
        antiCdConnections = {}

        if antiCdEnabled then
            -- hook namecall
            pcall(enableNamecallHook)

            -- patch current tools, watch for new ones
            watchTools()

            -- aggressively zero common debounce objects in character every so often
            antiCdConnections[#antiCdConnections+1] = RunService.Heartbeat:Connect(function()
                if not antiCdEnabled then return end
                local char = LocalPlayer.Character
                if char then
                    removeLocalDebounces(char)
                    -- also force any humanoid-based cd-like properties
                    local hum = char:FindFirstChildOfClass("Humanoid")
                    if hum then
                        -- if the game uses any custom NumberValues on Humanoid, try to nuke them (best-effort)
                        for _, v in ipairs(hum:GetChildren()) do
                            if v:IsA("NumberValue") or v:IsA("IntValue") then
                                local n = tostring(v.Name):lower()
                                if n:find("cool") or n:find("cd") then
                                    pcall(function() v.Value = 0 end)
                                end
                            end
                        end
                    end
                end
            end)
        else
            -- disable hook (best-effort)
            pcall(disableNamecallHook)

            -- disconnect residual connections
            for _, con in ipairs(antiCdConnections) do
                if typeof(con) == "RBXScriptConnection" then
                    pcall(function() con:Disconnect() end)
                end
            end
            antiCdConnections = {}
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
