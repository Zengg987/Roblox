local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "Kid Destroyer",
    LoadingTitle = "I Love Dominate Kid",
    LoadingSubtitle = "by Diddy",
    Theme = "AmberGlow",
    ToggleUIKeybind = "K"
})
local MainTab = Window:CreateTab("Main", "gamepad")

Rayfield:Notify({
    Title = "Script Loaded!",
    Content = "Press Right-Shift to open/close the menu.",
    Duration = 10,
    Image = "info"
})

--// Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

--// Config
local Aimbot_Enabled = false
local Aimbot_Radius = 100
local Aimbot_Smoothness = 0.15
local Ignore_Teammates = true
local Ignore_Walls = true
local Friends, Aliases = {}, {}

--// ESP
local espFolder = Instance.new("Folder", game.CoreGui)
espFolder.Name = "ESPFolder"
local espEnabled = false

--// Visibility Check
local function IsVisible(targetPart)
    if not targetPart then return false end
    if not Ignore_Walls then return true end -- skip check if disabled

    local origin = Camera.CFrame.Position
    local ignoreList = {LocalPlayer.Character, targetPart.Parent}
    local parts = Camera:GetPartsObscuringTarget({targetPart.Position}, ignoreList)

    return #parts == 0
end

--// ESP Color Update
local function updateESPColor(highlight, player)
    if not highlight or not player or not player.Character then return end
    local head = player.Character:FindFirstChild("Head")
    if not head then return end

    local baseColor = Color3.fromRGB(255, 0, 0)
    if Ignore_Teammates and player.Team and LocalPlayer.Team then
        baseColor = (player.Team == LocalPlayer.Team)
            and Color3.fromRGB(0, 255, 0)
            or Color3.fromRGB(255, 0, 0)
    end

    if Ignore_Walls and not IsVisible(head) then
        highlight.FillColor = Color3.fromRGB(150, 150, 150) -- gray if blocked
    else
        highlight.FillColor = baseColor
    end
end

local function createESP(player)
    if player == LocalPlayer or not player.Character then return end
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

Players.PlayerAdded:Connect(function(plr)
    if espEnabled then
        plr.CharacterAdded:Connect(function()
            task.wait(1)
            if espEnabled then createESP(plr) end
        end)
    end
end)

--// Aimbot
local function IsEnemy(player)
    if not player or player == LocalPlayer then return false end
    if table.find(Friends, player.Name) or table.find(Aliases, player.Name) then return false end
    if Ignore_Teammates and player.Team and LocalPlayer.Team and player.Team == LocalPlayer.Team then return false end
    return true
end

local function GetClosestEnemy(radius)
    local closestPlayer, shortestDistance = nil, radius + 1
    for _, player in ipairs(Players:GetPlayers()) do
        if IsEnemy(player) and player.Character and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0 then
            local head = player.Character:FindFirstChild("Head")
            if head then
                local dist = (LocalPlayer.Character.Head.Position - head.Position).magnitude
                if dist < shortestDistance and dist <= radius and IsVisible(head) then
                    closestPlayer, shortestDistance = player, dist
                end
            end
        end
    end
    return closestPlayer
end

local function AimAt(targetPlayer)
    if targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("Head") then
        local headPos = targetPlayer.Character.Head.Position
        local targetCFrame = CFrame.new(Camera.CFrame.Position, headPos)
        Camera.CFrame = Camera.CFrame:Lerp(targetCFrame, Aimbot_Smoothness)

        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local root = LocalPlayer.Character.HumanoidRootPart
            local lookVector = (headPos - root.Position).unit
            local bodyCFrame = CFrame.new(root.Position, root.Position + lookVector)
            root.CFrame = root.CFrame:Lerp(bodyCFrame, Aimbot_Smoothness)
        end
    end
end

--// Main Loop
RunService.RenderStepped:Connect(function()
    if Aimbot_Enabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Head") then
        local target = GetClosestEnemy(Aimbot_Radius)
        if target then
            AimAt(target)
        end
    end

    if espEnabled then
        for _, esp in ipairs(espFolder:GetChildren()) do
            local plrName = esp.Name:gsub("_ESP", "")
            local plr = Players:FindFirstChild(plrName)
            if plr then
                updateESPColor(esp, plr)
            end
        end
    end
end)

--// UI Section: ESP
MainTab:CreateToggle({
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
        Rayfield:Notify({
            Title = "ESP Status",
            Content = "ESP is now " .. (state and "Enabled" or "Disabled"),
            Duration = 3,
            Image = state and "check" or "x"
        })
    end,
})

--// UI Section: Aimbot
local AimbotSection = MainTab:CreateSection("Aimbot Options")
MainTab:CreateToggle({
    Name = "Toggle Aimbot",
    CurrentValue = false,
    Callback = function(Value)
        Aimbot_Enabled = Value
        Rayfield:Notify({
            Title = "Aimbot Status",
            Content = "Aimbot is now " .. (Value and "Enabled" or "Disabled"),
            Duration = 3,
            Image = Value and "check" or "x"
        })
    end,
})
MainTab:CreateSlider({
    Name = "Aimbot Radius (Studs)",
    Range = {0, 500},
    Increment = 5,
    CurrentValue = Aimbot_Radius,
    Callback = function(Value)
        Aimbot_Radius = Value
    end,
})
MainTab:CreateSlider({
    Name = "Aimbot Smoothness",
    Range = {0.01, 1},
    Increment = 0.01,
    CurrentValue = Aimbot_Smoothness,
    Callback = function(Value)
        Aimbot_Smoothness = Value
    end,
})
MainTab:CreateToggle({
    Name = "Ignore Teammates",
    CurrentValue = Ignore_Teammates,
    Callback = function(Value)
        Ignore_Teammates = Value
    end,
})
MainTab:CreateToggle({
    Name = "Ignore Behind Walls",
    CurrentValue = Ignore_Walls,
    Callback = function(Value)
        Ignore_Walls = Value
    end,
})

--// UI Section: Friend/Alias
local ExclusionsSection = MainTab:CreateSection("Exclusions (Friends/Aliases)")
MainTab:CreateInput({
    Name = "Add Friend",
    PlaceholderText = "Enter player name",
    Callback = function(Text)
        if Text ~= "" then table.insert(Friends, Text) end
    end,
})
MainTab:CreateInput({
    Name = "Add Alias",
    PlaceholderText = "Enter player name",
    Callback = function(Text)
        if Text ~= "" then table.insert(Aliases, Text) end
    end,
})
MainTab:CreateButton({
    Name = "Clear All Exclusions",
    Callback = function()
        Friends, Aliases = {}, {}
    end,
})
