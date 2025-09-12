local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- Window utama
local Window = Rayfield:CreateWindow({
    Name = "Fly Script",
    LoadingTitle = "Fly Control",
    LoadingSubtitle = "with Rayfield",
    ConfigurationSaving = {
        Enabled = false,
        FolderName = nil,
        FileName = "FlyConfig"
    }
})

-- Tab utama (pakai icon lucide, misal "airplay")
local MainTab = Window:CreateTab("Main", "airplay")
local FlySection = MainTab:CreateSection("Fly Controls")

-- ====== Fly Core ====== --
local savedSpeed = 50
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local HRP = character:WaitForChild("HumanoidRootPart")
local Camera = workspace.CurrentCamera

local baseSpeed = savedSpeed
local flySpeed = baseSpeed
local flying = false
local forwardHold = 0
local inputFlags = { forward=false, back=false, left=false, right=false, up=false, down=false }

local bodyVelocity = Instance.new("BodyVelocity")
bodyVelocity.MaxForce = Vector3.new(1e5, 1e5, 1e5)

local bodyGyro = Instance.new("BodyGyro")
bodyGyro.MaxTorque = Vector3.new(1e5, 1e5, 1e5)

local function startFlying()
    flying = true
    forwardHold = 0
    flySpeed = baseSpeed
    bodyVelocity.Parent = HRP
    bodyGyro.Parent = HRP
    humanoid.PlatformStand = true
end

local function stopFlying()
    flying = false
    bodyVelocity.Parent = nil
    bodyGyro.Parent = nil
    humanoid.PlatformStand = false
end

-- ====== Rayfield UI Elements ====== --

-- Toggle Fly
MainTab:CreateToggle({
    Name = "Fly",
    CurrentValue = false,
    Flag = "FlyToggle",
    Callback = function(Value)
        if Value then
            startFlying()
        else
            stopFlying()
        end
    end,
})

-- Input Speed
MainTab:CreateInput({
    Name = "Fly Speed",
    PlaceholderText = tostring(baseSpeed),
    RemoveTextAfterFocusLost = false,
    Callback = function(Text)
        local num = tonumber(Text)
        if num and num > 0 then
            baseSpeed = num
            savedSpeed = num
            if flying then flySpeed = baseSpeed end
        end
    end,
})

-- ====== Input Movement ====== --
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

-- ====== Render Loop ====== --
RunService.RenderStepped:Connect(function(dt)
    if not flying then return end

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
end)
