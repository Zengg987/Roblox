local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "Kid Destroyer",
   LoadingTitle = "I Love Dominate Kid",
   LoadingSubtitle = "by Diddy",
   Theme = "Dark",
   ToggleUIKeybind = Enum.KeyCode.K
})
local MainTab = Window:CreateTab("Main", "gamepad")

Rayfield:Notify({
   Title = "Script Loaded!",
   Content = "Press K to open/close the menu.",
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
local Friends, Aliases = {}, {}
local TeamCheck = true
local IncludeBots = true

-- ESP
local espFolder = Instance.new("Folder", game.CoreGui)
espFolder.Name = "ESPFolder"
local espEnabled = false

-- Detect Same Team
local function IsSameTeam(entity)
    if not entity or not LocalPlayer then return false end
    if entity:IsA("Player") then
        if entity.Team and LocalPlayer.Team and entity.Team == LocalPlayer.Team then return true end
        if entity.TeamColor and LocalPlayer.TeamColor and entity.TeamColor == LocalPlayer.TeamColor then return true end
        local tag = entity:FindFirstChild("Team") or entity:FindFirstChild("team") or entity:FindFirstChild("TeamTag")
        if tag and tag.Value then
            local myTeamName = LocalPlayer.Team and LocalPlayer.Team.Name or tostring(LocalPlayer.TeamColor)
            if tostring(tag.Value):lower() == tostring(myTeamName):lower() then return true end
        end
    elseif entity:IsA("Model") then
        local tag = entity:FindFirstChild("Team") or entity:FindFirstChild("Faction")
        if tag and tag.Value and LocalPlayer.Team then
            if tostring(tag.Value):lower() == tostring(LocalPlayer.Team.Name):lower() then return true end
        end
    end
    return false
end

local function IsEnemy(entity)
    if not entity or entity == LocalPlayer then return false end
    if entity:IsA("Player") and (table.find(Friends, entity.Name) or table.find(Aliases, entity.Name)) then return false end
    if TeamCheck and IsSameTeam(entity) then return false end
    return true
end

local function updateESPColor(highlight, entity)
    if not highlight or not entity then return end
    if entity:IsA("Player") and (table.find(Friends, entity.Name) or table.find(Aliases, entity.Name)) then
        highlight.FillColor = Color3.fromRGB(0, 255, 0)
    elseif entity:IsA("Player") and TeamCheck and IsSameTeam(entity) then
        highlight.FillColor = Color3.fromRGB(0, 170, 255)
    elseif entity:IsA("Model") and entity:FindFirstChild("Humanoid") then
        highlight.FillColor = Color3.fromRGB(255, 255, 0)
    else
        highlight.FillColor = Color3.fromRGB(255, 0, 0)
    end
end

local function createESP(entity)
    local name = entity:IsA("Player") and entity.Name or entity.Name .. "_BOT"
    if espFolder:FindFirstChild(name .. "_ESP") then return end
    local adornee = entity:IsA("Player") and entity.Character or entity
    if not adornee or not adornee:FindFirstChild("HumanoidRootPart") then return end
    local highlight = Instance.new("Highlight")
    highlight.Name = name .. "_ESP"
    highlight.Adornee = adornee
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = espFolder
    updateESPColor(highlight, entity)
end

-- Aimbot Config
local AimBone = "Head"
local AimSmooth = 0.18
local AimFOV = 55
local PredictionFactor = 0.15
local JitterAmount = 0.02
local AimDelay = 0
local lastAimTime = 0

local function angleBetween(a, b)
    local dot = a:Dot(b)
    dot = math.clamp(dot, -1, 1)
    return math.deg(math.acos(dot))
end

local function getAimPart(entity)
    if not entity then return nil end
    if entity:IsA("Player") then
        local char = entity.Character
        if not char then return nil end
        if AimBone == "Head" and char:FindFirstChild("Head") then return char.Head end
        if char:FindFirstChild(AimBone) then return char[AimBone] end
        return char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char:FindFirstChildWhichIsA("BasePart")
    elseif entity:IsA("Model") then
        if AimBone == "Head" and entity:FindFirstChild("Head") then return entity.Head end
        if entity:FindFirstChild(AimBone) then return entity[AimBone] end
        return entity:FindFirstChild("HumanoidRootPart") or entity:FindFirstChild("Torso") or entity:FindFirstChildWhichIsA("BasePart")
    end
    return nil
end

-- Weighted Scoring
local Weights = {Distance = 0.6, Angle = 0.4, Health = 0.0}
local Presets = {
    Aggressive = {Distance = 0.2, Angle = 0.6, Health = 0.2},
    Stealth    = {Distance = 0.5, Angle = 0.3, Health = 0.2},
    Safe       = {Distance = 0.7, Angle = 0.2, Health = 0.1}
}
local function ApplyPreset(name)
    if Presets[name] then
        Weights = {Distance = Presets[name].Distance, Angle = Presets[name].Angle, Health = Presets[name].Health}
        Rayfield:Notify({Title = "Preset Applied", Content = "Aimbot preset: " .. name, Duration = 3, Image = "sliders"})
    end
end

local function ScoreTarget(entity, part)
    if not entity or not part then return -math.huge end
    local camPos = Camera.CFrame.Position
    local toTarget = (part.Position - camPos)
    local dist = toTarget.Magnitude
    local distanceScore = 1 - math.clamp(dist / Aimbot_Radius, 0, 1)
    local ang = angleBetween(Camera.CFrame.LookVector, toTarget.Unit)
    local angleScore = 1 - math.clamp(ang / AimFOV, 0, 1)
    local health = 100
    if entity:IsA("Player") and entity.Character and entity.Character:FindFirstChild("Humanoid") then
        health = entity.Character.Humanoid.Health
    elseif entity:IsA("Model") and entity:FindFirstChild("Humanoid") then
        health = entity.Humanoid.Health
    end
    local healthScore = 1 - math.clamp(health / 100, 0, 1)
    return distanceScore * Weights.Distance + angleScore * Weights.Angle + healthScore * Weights.Health
end

local function GetBestTarget(radius)
    local best, bestScore = nil, -math.huge
    for _, plr in ipairs(Players:GetPlayers()) do
        if IsEnemy(plr) and plr.Character and plr.Character:FindFirstChild("Humanoid") and plr.Character.Humanoid.Health > 0 then
            local part = getAimPart(plr)
            if part then
                local dist = (LocalPlayer.Character.Head.Position - part.Position).Magnitude
                if dist <= radius then
                    local score = ScoreTarget(plr, part)
                    if score > bestScore then best, bestScore = plr, score end
                end
            end
        end
    end
    if IncludeBots then
        for _, model in ipairs(workspace:GetChildren()) do
            if model:IsA("Model") and model:FindFirstChild("Humanoid") and model:FindFirstChild("Head") and not Players:GetPlayerFromCharacter(model) then
                if IsEnemy(model) then
                    local part = getAimPart(model)
                    if part then
                        local dist = (LocalPlayer.Character.Head.Position - part.Position).Magnitude
                        if dist <= radius then
                            local score = ScoreTarget(model, part)
                            if score > bestScore then best, bestScore = model, score end
                        end
                    end
                end
            end
        end
    end
    return best
end

local function SmoothAimAt(entity)
    local part = getAimPart(entity)
    if not part then return end
    local vel = (part:IsA("BasePart") and part.AssemblyLinearVelocity) or Vector3.new(0,0,0)
    local predicted = part.Position + (vel * PredictionFactor)
    if JitterAmount > 0 then
        predicted = predicted + Vector3.new((math.random()-0.5)*JitterAmount,(math.random()-0.5)*JitterAmount,(math.random()-0.5)*JitterAmount)
    end
    local camPos = Camera.CFrame.Position
    local toTarget = predicted - camPos
    if toTarget.Magnitude <= 0 then return end
    local ang = angleBetween(Camera.CFrame.LookVector, toTarget.Unit)
    if AimFOV > 0 and ang > AimFOV then return end
    if AimDelay > 0 and (tick() - lastAimTime) < AimDelay then return end
    Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(camPos, predicted), math.clamp(AimSmooth, 0, 1))
    lastAimTime = tick()
end

RunService:BindToRenderStep("SmartAimbot", Enum.RenderPriority.Camera.Value + 1, function()
    if not Aimbot_Enabled then return end
    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("Head") then return end
    local target = GetBestTarget(Aimbot_Radius)
    if target then SmoothAimAt(target) end
end)

-- UI
MainTab:CreateToggle({Name="ESP Players/Bots",CurrentValue=false,Callback=function(state)
    espEnabled=state espFolder:ClearAllChildren()
    if state then
        for _,plr in ipairs(Players:GetPlayers()) do if plr.Character then createESP(plr) end end
        if IncludeBots then for _,m in ipairs(workspace:GetChildren()) do if m:IsA("Model") and m:FindFirstChild("Humanoid") and m:FindFirstChild("Head") and not Players:GetPlayerFromCharacter(m) then createESP(m) end end end
    end
end})

MainTab:CreateSection("Aimbot Options")
MainTab:CreateToggle({Name="Toggle Aimbot",CurrentValue=false,Callback=function(v)Aimbot_Enabled=v end})
MainTab:CreateSlider({Name="Aimbot Trace Radius",Range={0,500},Increment=5,Suffix="Studs",CurrentValue=Aimbot_Radius,Callback=function(v)Aimbot_Radius=v end})
MainTab:CreateToggle({Name="Enable Team Check",CurrentValue=TeamCheck,Callback=function(v)TeamCheck=v end})
MainTab:CreateToggle({Name="Include Bots/NPCs",CurrentValue=IncludeBots,Callback=function(v)IncludeBots=v end})

MainTab:CreateSection("Aimbot Presets")
MainTab:CreateDropdown({Name="Select Preset",Options={"Aggressive","Stealth","Safe"},CurrentOption="Stealth",Callback=function(opt)ApplyPreset(opt) end})

MainTab:CreateSection("Manual Weight Tuning")
MainTab:CreateSlider({Name="Distance Weight",Range={0,100},Increment=5,CurrentValue=Weights.Distance*100,Callback=function(v)Weights.Distance=v/100 end})
MainTab:CreateSlider({Name="Angle Weight",Range={0,100},Increment=5,CurrentValue=Weights.Angle*100,Callback=function(v)Weights.Angle=v/100 end})
MainTab:CreateSlider({Name="Health Weight",Range={0,100},Increment=5,CurrentValue=Weights.Health*100,Callback=function(v)Weights.Health=v/100 end})

MainTab:CreateSection("Stealth Aim Settings")
MainTab:CreateDropdown({Name="Aim Bone",Options={"Head","HumanoidRootPart","Torso"},CurrentOption=AimBone,Callback=function(opt)AimBone=opt end})
MainTab:CreateSlider({Name="Aim Smooth",Range={0,100},Increment=1,CurrentValue=math.floor(AimSmooth*100),Callback=function(v)AimSmooth=math.clamp(v/100,0,1) end})
MainTab:CreateSlider({Name="Aim FOV",Range={5,180},Increment=1,CurrentValue=AimFOV,Callback=function(v)AimFOV=v end})
MainTab:CreateSlider({Name="Prediction Factor",Range={0,100},Increment=1,CurrentValue=math.floor(PredictionFactor*100),Callback=function(v)PredictionFactor=v/100 end})
MainTab:CreateSlider({Name="Jitter Amount (cm)",Range={0,200},Increment=1,CurrentValue=math.floor(JitterAmount*100),Callback=function(v)JitterAmount=v/100 end})
MainTab:CreateSlider({Name="Aim Delay (ms)",Range={0,1000},Increment=10,CurrentValue=math.floor(AimDelay*1000),Callback=function(v)AimDelay=v/1000 end})

MainTab:CreateSection("Exclusions (Friends/Aliases)")
MainTab:CreateInput({Name="Add Friend",PlaceholderText="Enter player name",Callback=function(t)if t~="" then table.insert(Friends,t)end end})
MainTab:CreateInput({Name="Add Alias",PlaceholderText="Enter player name",Callback=function(t)if t~="" then table.insert(Aliases,t)end end})
MainTab:CreateButton({Name="Clear All Exclusions",Callback=function()Friends,Aliases={},{ } end})
