local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "Kid Destroyer",
   LoadingTitle = "I Love Dominate Kid",
   LoadingSubtitle = "by Diddy",
   Theme = "Dark", -- Using Dark theme for better visuals
   ToggleUIKeybind = Enum.KeyCode.RightShift -- Use Enum.KeyCode for robustness
})

local MainTab = Window:CreateTab("Main", "gamepad") -- LUDICE ICON: gamepad

-- Add a notification to inform the user how to open the menu
Rayfield:Notify({
   Title = "Script Loaded!",
   Content = "Press Right-Shift to open/close the menu.",
   Duration = 10,
   Image = "info" -- Lucide icon
})

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

-- Configuration Variables
local ESP_Enabled = false
local Aimbot_Enabled = false
local Aimbot_Radius = 100 -- Default aimbot trace radius
local ESP_Boxes = {} -- Table to store ESP box references for cleanup

-- Local Player
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- Aimbot Functions
local function GetClosestPlayer(radius)
    local closestPlayer = nil
    local shortestDistance = radius + 1 -- Initialize with a value greater than radius

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0 then
            local head = player.Character:FindFirstChild("Head")
            if head then
                local distance = (LocalPlayer.Character.Head.Position - head.Position).magnitude
                if distance < shortestDistance and distance <= radius then
                    closestPlayer = player
                    shortestDistance = distance
                end
            end
        end
    end
    return closestPlayer
end

local function AimAt(targetPlayer)
    if targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("Head") then
        local headPosition = targetPlayer.Character.Head.Position
        Camera.CFrame = CFrame.new(Camera.CFrame.Position, headPosition)
    end
end

-- ESP Functions
local function CreateESPBox(character)
    local box = Instance.new("BoxHandleAdornment")
    box.Adornee = character
    box.Color3 = Color3.fromRGB(255, 0, 0) -- Red color for enemies
    box.Transparency = 0.5
    box.AlwaysOnTop = true
    box.ZIndex = 5
    box.Parent = Workspace.CurrentCamera
    box.Visible = true

    -- Function to update box position and size
    local function UpdateBox()
        if character and character:FindFirstChild("HumanoidRootPart") then
            local hrp = character.HumanoidRootPart
            local head = character:FindFirstChild("Head")
            local torso = character:FindFirstChild("Torso") -- For height approximation

            if head and hrp and torso then
                local headPos = head.Position
                local hrpPos = hrp.Position

                local height = (headPos.Y - hrpPos.Y) * 2
                local width = head.Size.X * 1.5
                local depth = head.Size.Z * 1.5

                box.CFrame = CFrame.new(hrpPos.X, hrpPos.Y + (height / 2), hrpPos.Z)
                box.Size = Vector3.new(width, height, depth)
            else
                box.Visible = false
            end
        else
            box.Visible = false
        end
    end

    return box, UpdateBox
end

local function UpdateESP()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0 then
            if not ESP_Boxes[player.Name] then
                local box, updateFunc = CreateESPBox(player.Character)
                ESP_Boxes[player.Name] = {box = box, updateFunc = updateFunc}
            end
            ESP_Boxes[player.Name].box.Visible = true
            ESP_Boxes[player.Name].updateFunc()
        else
            if ESP_Boxes[player.Name] then
                ESP_Boxes[player.Name].box:Destroy()
                ESP_Boxes[player.Name] = nil
            end
        end
    end

    -- Clean up boxes for players who left
    for playerName, boxData in pairs(ESP_Boxes) do
        local found = false
        for _, player in ipairs(Players:GetPlayers()) do
            if player.Name == playerName then
                found = true
                break
            end
        end
        if not found then
            boxData.box:Destroy()
            ESP_Boxes[playerName] = nil
        end
    end
end

local function ClearESP()
    for _, boxData in pairs(ESP_Boxes) do
        boxData.box:Destroy()
    end
    ESP_Boxes = {}
end

-- Main Loop
RunService.RenderStepped:Connect(function()
    if ESP_Enabled then
        UpdateESP()
    else
        ClearESP()
    end

    if Aimbot_Enabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Head") then
        local target = GetClosestPlayer(Aimbot_Radius)
        if target then
            AimAt(target)
        end
    end
end)


-- UI Section for ESP
local EspSection = MainTab:CreateSection("ESP Options")

MainTab:CreateToggle({
    Name = "Toggle ESP",
    CurrentValue = false,
    Flag = "ESP_Toggle",
    Callback = function(Value)
        ESP_Enabled = Value
        if not ESP_Enabled then
            ClearESP() -- Clear ESP boxes immediately when disabled
        end
        Rayfield:Notify({
            Title = "ESP Status",
            Content = "ESP is now " .. (Value and "Enabled" or "Disabled"),
            Duration = 3,
            Image = Value and "check" or "x"
        })
    end,
})

-- UI Section for Aimbot
local AimbotSection = MainTab:CreateSection("Aimbot Options")

MainTab:CreateToggle({
    Name = "Toggle Aimbot",
    CurrentValue = false,
    Flag = "Aimbot_Toggle",
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
    Range = {0, 500}, -- Max radius of 500 studs
    Increment = 5,
    Suffix = "Studs",
    CurrentValue = Aimbot_Radius,
    Flag = "Aimbot_Radius_Slider",
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

-- Ensure cleanup when script is unloaded (though not common in exploits)
game:GetService("Debris"):AddItem(Window, 0)
Window.Parent = nil -- Detach UI from game tree on unload
