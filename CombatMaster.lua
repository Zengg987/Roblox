local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "Kid Destroyer",
   LoadingTitle = "I Love Dominate Kid",
   LoadingSubtitle = "by Diddy",
   Theme = "Dark", -- Using Dark theme for better visuals
   ToggleUIKeybind = "K" -- Use Enum.KeyCode for robustness
})
local MainTab = Window:CreateTab("Main", "gamepad")

Rayfield:Notify({
   Title = "Script Loaded!",
   Content = "Press Right-Shift to open/close the menu.",
   Duration = 10,
   Image = "info"
})

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- Config
local Aimbot_Enabled = false
local Aimbot_Radius = 100
local Friends = {}
local Aliases = {}

-- ESP Using Highlight
local espFolder = Instance.new("Folder", game.CoreGui)
espFolder.Name = "ESPFolder"
local espEnabled = false

local function updateESPColor(highlight, player)
    if not highlight or not player then return end
    if player.Team and LocalPlayer.Team then
        highlight.FillColor = (player.Team == LocalPlayer.Team) and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
    else
        highlight.FillColor = Color3.fromRGB(255, 0, 0)
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

-- Aimbot Functions
local function IsEnemy(player)
    if not player or player == LocalPlayer then return false end
    if table.find(Friends, player.Name) or table.find(Aliases, player.Name) then return false end
    if player.Team and LocalPlayer.Team and player.Team == LocalPlayer.Team then return false end
    return true
end

local function GetClosestEnemy(radius)
    local closestPlayer, shortestDistance = nil, radius + 1
    for _, player in ipairs(Players:GetPlayers()) do
        if IsEnemy(player) and player.Character and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0 then
            local head = player.Character:FindFirstChild("Head")
            if head then
                local dist = (LocalPlayer.Character.Head.Position - head.Position).magnitude
                if dist < shortestDistance and dist <= radius then
                    closestPlayer, shortestDistance = player, dist
                end
            end
        end
    end
    return closestPlayer
end

local function AimAt(targetPlayer)
    if targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("Head") then
        Camera.CFrame = CFrame.new(Camera.CFrame.Position, targetPlayer.Character.Head.Position)
    end
end

-- Main Loop
RunService.RenderStepped:Connect(function()
    if Aimbot_Enabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Head") then
        local target = GetClosestEnemy(Aimbot_Radius)
        if target then
            AimAt(target)
        end
    end
end)

-- UI Section: ESP
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

-- UI Section: Aimbot
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
    Name = "Aimbot Trace Radius",
    Range = {0, 500},
    Increment = 5,
    Suffix = "Studs",
    CurrentValue = Aimbot_Radius,
    Callback = function(Value)
        Aimbot_Radius = Value
        Rayfield:Notify({
            Title = "Aimbot Radius",
            Content = "Aimbot trace radius set to " .. Value .. " studs.",
            Duration = 2,
            Image = "move"
        })
    end,
})

-- UI Section: Friend/Alias Management
local ExclusionsSection = MainTab:CreateSection("Exclusions (Friends/Aliases)")
MainTab:CreateInput({
    Name = "Add Friend",
    PlaceholderText = "Enter player name",
    Callback = function(Text)
        if Text ~= "" then
            table.insert(Friends, Text)
            Rayfield:Notify({
                Title = "Friend Added",
                Content = Text .. " will be ignored by Aimbot/ESP.",
                Duration = 3,
                Image = "user-plus"
            })
        end
    end,
})
MainTab:CreateInput({
    Name = "Add Alias",
    PlaceholderText = "Enter player name",
    Callback = function(Text)
        if Text ~= "" then
            table.insert(Aliases, Text)
            Rayfield:Notify({
                Title = "Alias Added",
                Content = Text .. " will be ignored by Aimbot/ESP.",
                Duration = 3,
                Image = "user-plus"
            })
        end
    end,
})
MainTab:CreateButton({
    Name = "Clear All Exclusions",
    Callback = function()
        Friends, Aliases = {}, {}
        Rayfield:Notify({
            Title = "Exclusions Cleared",
            Content = "All friends and aliases have been removed.",
            Duration = 3,
            Image = "trash"
        })
    end,
})
