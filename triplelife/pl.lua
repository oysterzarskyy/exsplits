-- Triplelife Premium v2.0
-- Optimized and Fixed Version

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Teams = game:GetService("Teams")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- UI Library Loading
local function SafeLoad(url)
    local success, result = pcall(function()
        return loadstring(game:HttpGet(url))()
    end)
    if not success then 
        warn("Failed to load dependency: " .. url)
        return nil
    end
    return result
end

local Velvet = SafeLoad("https://raw.githubusercontent.com/DexCodeSX/Velvet/main/Library.lua")
local SaveManager = SafeLoad("https://raw.githubusercontent.com/DexCodeSX/Velvet/main/addons/SaveManager.lua")
local ThemeManager = SafeLoad("https://raw.githubusercontent.com/DexCodeSX/Velvet/main/addons/ThemeManager.lua")
local QuickBar = SafeLoad("https://raw.githubusercontent.com/DexCodeSX/Velvet/main/addons/QuickBar.lua")
local NotifHistory = SafeLoad("https://raw.githubusercontent.com/DexCodeSX/Velvet/main/addons/NotificationHistory.lua")

if not Velvet then return end

-- Configuration Table (Replacing _G for performance and safety)
local Config = {
    aimbot = false,
    fov = 150,
    targetPart = "Head",
    teamCheck = false,
    ignoredTeams = {},
    wallCheck = false,
    smoothing = false,
    smoothAmount = 0.1,
    showFovCircle = false,
    isAiming = false,
    espBoxes = false,
    espNames = false,
    espTracer = false,
    walkSpeedEnabled = false,
    walkSpeedValue = 16,
    jumpPowerEnabled = false,
    jumpPowerValue = 50,
    flyEnabled = false,
    flySpeed = 50,
    noClipEnabled = false
}

-- Initializing Configuration Managers
SaveManager:Bind(Velvet, "TriplelifeConfig")
ThemeManager:Bind(Velvet)
ThemeManager:LoadSaved()

local Window = Velvet:CreateWindow({
    Title = "Triplelife Premium",
    SubTitle = "v2.0 by oysterzarskyy",
    ToggleKey = Enum.KeyCode.RightShift,
    ToggleIcon = "sparkles",
})

QuickBar:Bind(Velvet, Window, { MaxPins = 5 })
NotifHistory:Bind(Velvet, Window, { MaxEntries = 50 })

-- TAB 1: COMBAT
local CombatTab = Window:AddTab("Combat", "sword")
local AimbotSection = CombatTab:AddSection("Aimbot Settings")

AimbotSection:AddToggle("Aimbot", {
    Text = "Enable Aimbot",
    Default = false,
    Callback = function(v) Config.aimbot = v end,
})

AimbotSection:AddSlider("FOV", {
    Text = "FOV Radius", Min = 10, Max = 500, Default = 150, Increment = 5,
    Callback = function(v) Config.fov = v end,
})

AimbotSection:AddToggle("ShowFOVCircle", {
    Text = "Show FOV Circle",
    Default = false,
    Callback = function(v) Config.showFovCircle = v end,
})

AimbotSection:AddDropdown("TargetPart", {
    Text = "Target Part",
    Values = { "Head", "HumanoidRootPart", "Torso" },
    Default = "Head",
    Callback = function(v) Config.targetPart = v end,
})

AimbotSection:AddToggle("WallCheck", {
    Text = "Wall Check (Visibility)",
    Default = false,
    Callback = function(v) Config.wallCheck = v end,
})

AimbotSection:AddToggle("SmoothingToggle", {
    Text = "Enable Camera Smoothing",
    Default = false,
    Callback = function(v) Config.smoothing = v end,
})

AimbotSection:AddSlider("SmoothAmount", {
    Text = "Smoothing Speed", Min = 0.01, Max = 1, Default = 0.1, Increment = 0.01,
    Callback = function(v) Config.smoothAmount = v end,
})

AimbotSection:AddToggle("TeamCheck", {
    Text = "Team Check",
    Default = false,
    Callback = function(v) Config.teamCheck = v end,
})

local teamNames = {}
for _, team in ipairs(Teams:GetTeams()) do
    table.insert(teamNames, team.Name)
end
if #teamNames == 0 then table.insert(teamNames, "No Teams Found") end

AimbotSection:AddDropdown("IgnoredTeams", {
    Text = "Ignore Teams",
    Values = teamNames,
    Default = {},
    Multi = true,
    Callback = function(v) Config.ignoredTeams = v end,
})

-- TAB 2: VISUALS
local VisualsTab = Window:AddTab("Visuals", "eye")
local EspSection = VisualsTab:AddSection("Player ESP")

EspSection:AddToggle("EspBoxes", { Text = "Bounding Boxes", Default = false, Callback = function(v) Config.espBoxes = v end })
EspSection:AddToggle("EspNames", { Text = "Show Usernames", Default = false, Callback = function(v) Config.espNames = v end })
EspSection:AddToggle("EspTracers", { Text = "Snaplines / Tracers", Default = false, Callback = function(v) Config.espTracer = v end })

-- TAB 3: MOVEMENT
local MovementTab = Window:AddTab("Movement", "zap")
local PhysicsSection = MovementTab:AddSection("Character Modification")

PhysicsSection:AddToggle("SpeedToggle", { Text = "Enable Custom Speed", Default = false, Callback = function(v) Config.walkSpeedEnabled = v end })
PhysicsSection:AddSlider("SpeedSlider", { Text = "WalkSpeed Value", Min = 16, Max = 250, Default = 16, Callback = function(v) Config.walkSpeedValue = v end })
PhysicsSection:AddToggle("JumpToggle", { Text = "Enable Custom Jump", Default = false, Callback = function(v) Config.jumpPowerEnabled = v end })
PhysicsSection:AddSlider("JumpSlider", { Text = "JumpPower Value", Min = 50, Max = 500, Default = 50, Callback = function(v) Config.jumpPowerValue = v end })

local SafeSection = MovementTab:AddSection("Blatant Physics")
SafeSection:AddToggle("NoclipToggle", { Text = "Noclip (Pass Walls)", Default = false, Callback = function(v) Config.noClipEnabled = v end })

-- TAB 4: SETTINGS
local SettingsTab = Window:AddTab("Settings", "settings")
SaveManager:BuildConfigSection(SettingsTab:AddSection("Profiles"))
ThemeManager:ApplyToSection(SettingsTab:AddSection("Theme Tweaks"))

-- Utility Functions
local function copyText(text)
    local clipboardFunc = setclipboard or toclipboard or set_clipboard
    if clipboardFunc then clipboardFunc(text) end
end

-- FOV Circle Setup
local fovCircle = Drawing.new("Circle")
fovCircle.Color = Color3.fromRGB(255, 255, 255)
fovCircle.Thickness = 1
fovCircle.NumSides = 64
fovCircle.Filled = false
fovCircle.Visible = false

-- Input Handling
UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.UserInputType == Enum.UserInputType.MouseButton2 then -- Changed to Right Click for Aimbot standard
        Config.isAiming = true
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        Config.isAiming = false
    end
end)

-- Optimized Wall Check
local wallCheckParams = RaycastParams.new()
wallCheckParams.FilterType = Enum.RaycastFilterType.Exclude
wallCheckParams.IgnoreWater = true

local function IsVisible(targetPart, character)
    wallCheckParams.FilterDescendantsInstances = {LocalPlayer.Character, character}
    local rayDirection = targetPart.Position - Camera.CFrame.Position
    local raycastResult = workspace:Raycast(Camera.CFrame.Position, rayDirection, wallCheckParams)
    return raycastResult == nil
end

local function GetClosestTarget()
    local closestPlayer = nil
    local shortestDistance = Config.fov
    local mousePos = UserInputService:GetMouseLocation()

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Humanoid") then
            local char = player.Character
            local hum = char.Humanoid
            local aimPart = char:FindFirstChild(Config.targetPart)
            
            if hum.Health > 0 and aimPart then
                local teamAllowed = true
                if Config.teamCheck then
                    if player.Team == LocalPlayer.Team then teamAllowed = false end
                    if player.Team and table.find(Config.ignoredTeams, player.Team.Name) then teamAllowed = false end
                end

                if teamAllowed then
                    if not Config.wallCheck or IsVisible(aimPart, char) then
                        local screenPoint, onScreen = Camera:WorldToViewportPoint(aimPart.Position)
                        if onScreen then
                            local distance = (Vector2.new(screenPoint.X, screenPoint.Y) - mousePos).Magnitude
                            if distance < shortestDistance then
                                shortestDistance = distance
                                closestPlayer = char
                            end
                        end
                    end
                end
            end
        end
    end
    return closestPlayer
end

-- Main Loop
RunService.RenderStepped:Connect(function()
    -- FOV Update
    if Config.aimbot and Config.showFovCircle then
        local mousePos = UserInputService:GetMouseLocation()
        fovCircle.Position = mousePos
        fovCircle.Radius = Config.fov
        fovCircle.Visible = true
    else
        fovCircle.Visible = false
    end

    -- Aimbot Logic
    if Config.aimbot and Config.isAiming then
        local target = GetClosestTarget()
        if target and target:FindFirstChild(Config.targetPart) then
            local targetPart = target[Config.targetPart]
            local lookAt = CFrame.new(Camera.CFrame.Position, targetPart.Position)
            if Config.smoothing then
                Camera.CFrame = Camera.CFrame:Lerp(lookAt, Config.smoothAmount)
            else
                Camera.CFrame = lookAt
            end
        end
    end

    -- Character Mods
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("Humanoid") then
        local hum = char.Humanoid
        if Config.walkSpeedEnabled then hum.WalkSpeed = Config.walkSpeedValue end
        if Config.jumpPowerEnabled then 
            hum.UseJumpPower = true
            hum.JumpPower = Config.jumpPowerValue 
        end
        
        -- Noclip Logic (Optimized)
        if Config.noClipEnabled then
            for _, part in ipairs(char:GetChildren()) do
                if part:IsA("BasePart") then part.CanCollide = false end
            end
        end
    end
end)

copyText("https://github.com/oysterzarskyy/exsplits")
