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
local flying = false
local flySpeed = 50

MovementTab:CreateToggle({
    Name = "Fly",
    CurrentValue = false,
    Callback = function(state)
        flying = state
        local lp = game.Players.LocalPlayer
        local char = lp.Character or lp.CharacterAdded:Wait()
        local hum = char:FindFirstChildOfClass("Humanoid")

        if state then
            task.spawn(function()
                while flying do
                    local cam = workspace.CurrentCamera.CFrame
                    local vel = Vector3.zero
                    if game.UserInputService:IsKeyDown(Enum.KeyCode.W) then vel += cam.LookVector end
                    if game.UserInputService:IsKeyDown(Enum.KeyCode.S) then vel -= cam.LookVector end
                    if game.UserInputService:IsKeyDown(Enum.KeyCode.A) then vel -= cam.RightVector end
                    if game.UserInputService:IsKeyDown(Enum.KeyCode.D) then vel += cam.RightVector end
                    hum:Move(vel * flySpeed, true)
                    task.wait()
                end
            end)
        end
    end,
})

MovementTab:CreateSlider({
    Name = "Fly Speed",
    Range = {10, 200},
    Increment = 5,
    Suffix = "Speed",
    CurrentValue = flySpeed,
    Callback = function(v) flySpeed = v end,
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
