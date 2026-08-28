-- Lightweight Prison Life Optimization & Mod Suite
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- Configuration states
local autoAimEnabled = false
local aimbotEnabled = false
local autoFireEnabled = false
local selectedTargetTeam = "Enemies"
local selectedTargetPartName = "Head"

-- Gun Mod Configurations
local fireRateModEnabled = false
local customFireRateValue = 0.05
local spreadModEnabled = false
local customSpreadValue = 0
local damageModEnabled = false
local customDamageValue = 100

-- ESP & Invisibility States
local espEnabled = false
local minEspDistance = 10
local maxEspDistance = 5000
local espCache = {}
local invisibilityEnabled = false
local platformPart = nil
local originalCameraSubject = nil
local undergroundDepth = 50

-- Weapon Lists
local prioritizedWeaponNames = {
    ["M9"] = true,
    ["Taser"] = true,
    ["Handcuffs"] = true,
    ["MP5"] = true,
    ["Remington 870"] = true,
    ["Revolver"] = true,
    ["Sniper"] = true,
    ["Hammer"] = true,
    ["Crude Knife"] = true
}

local prioritizedAccessoryNames = {
    ["Light Vest"] = true
}

-- Performance & Rendering Clean-up
local function optimizePerformance()
    for _, v in ipairs(Workspace:GetDescendants()) do
        if v:IsA("Sparkles") or v:IsA("Fire") or v:IsA("Smoke") then
            v:Destroy()
        end
    end
    Workspace.DescendantAdded:Connect(function(child)
        if child:IsA("Sparkles") or child:IsA("Fire") or child:IsA("Smoke") then
            child:Destroy()
        end
    end)
end

optimizePerformance()

-- Utility Finders
local function getNearestTool()
    local character = LocalPlayer.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return nil end
    local rootPart = character.HumanoidRootPart
    local bestTool = nil
    local bestScore = -math.huge

    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Tool") or (obj:IsA("BasePart") and obj.Name == "Handle" and obj.Parent and obj.Parent:IsA("Tool")) then
            local toolInstance = obj:IsA("Tool") and obj or obj.Parent
            local targetPart = toolInstance:FindFirstChild("Handle") or toolInstance.PrimaryPart or toolInstance:FindFirstChildWhichIsA("BasePart")
            if targetPart and prioritizedWeaponNames[toolInstance.Name] then
                local distance = (rootPart.Position - targetPart.Position).Magnitude
                local score = 500 - distance
                if score > bestScore then
                    bestScore = score
                    bestTool = targetPart
                end
            end
        end
    end
    return bestTool
end

local function getNearestAccessory()
    local character = LocalPlayer.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return nil end
    local rootPart = character.HumanoidRootPart
    local bestAccessory = nil
    local bestScore = -math.huge

    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Tool") or (obj:IsA("BasePart") and obj.Name == "Handle" and obj.Parent and obj.Parent:IsA("Tool")) then
            local toolInstance = obj:IsA("Tool") and obj or obj.Parent
            local targetPart = toolInstance:FindFirstChild("Handle") or toolInstance.PrimaryPart or toolInstance:FindFirstChildWhichIsA("BasePart")
            if targetPart and prioritizedAccessoryNames[toolInstance.Name] then
                local distance = (rootPart.Position - targetPart.Position).Magnitude
                local score = 500 - distance
                if score > bestScore then
                    bestScore = score
                    bestAccessory = targetPart
                end
            end
        end
    end
    return bestAccessory
end

local function isValidTeamTarget(player)
    if player == LocalPlayer then return selectedTargetTeam == "Self" end
    if selectedTargetTeam == "Teammates" then return player.Team == LocalPlayer.Team end
    if selectedTargetTeam == "Enemies" then return player.Team ~= LocalPlayer.Team end
    return true
end

local function getNearestPlayerTarget()
    local character = LocalPlayer.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return nil end
    local rootPart = character.HumanoidRootPart
    local nearestTarget = nil
    local shortestDistance = math.huge

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and isValidTeamTarget(player) then
            local targetChar = player.Character
            if targetChar and targetChar:FindFirstChild("Humanoid") and targetChar.Humanoid.Health > 0 then
                local targetPart = targetChar:FindFirstChild(selectedTargetPartName) or targetChar:FindFirstChild("HumanoidRootPart")
                if targetPart then
                    local distance = (rootPart.Position - targetPart.Position).Magnitude
                    if distance < shortestDistance then
                        shortestDistance = distance
                        nearestTarget = targetPart
                    end
                end
            end
        end
    end
    return nearestTarget
end

-- Optimized ESP Loop
RunService.RenderStepped:Connect(function()
    local character = LocalPlayer.Character
    local rootPart = character and character:FindFirstChild("HumanoidRootPart")

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local pChar = player.Character
            local pRoot = pChar and pChar:FindFirstChild("HumanoidRootPart")
            local highlight = espCache[player]
            
            if not highlight and pChar then
                highlight = Instance.new("Highlight")
                highlight.Adornee = pChar
                highlight.Parent = pChar
                espCache[player] = highlight
            end

            if espEnabled and rootPart and pRoot and pChar then
                local distance = (rootPart.Position - pRoot.Position).Magnitude
                if distance >= minEspDistance and distance <= maxEspDistance then
                    highlight.Enabled = true
                    local teamColor = player.Team and player.Team.TeamColor.Color or Color3.fromRGB(255, 255, 255)
                    highlight.FillColor = teamColor
                    highlight.OutlineColor = teamColor
                    highlight.FillTransparency = 0.5
                else
                    highlight.Enabled = false
                end
            elseif highlight then
                highlight.Enabled = false
            end
        end
    end
end)

-- Underground Platform & Invisibility Loop
RunService.RenderStepped:Connect(function()
    local character = LocalPlayer.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local rootPart = character and character:FindFirstChild("HumanoidRootPart")

    if invisibilityEnabled and rootPart then
        if not platformPart or not platformPart.Parent then
            platformPart = Instance.new("Part")
            platformPart.Size = Vector3.new(10, 1, 10)
            platformPart.Anchored = true
            platformPart.Transparency = 0.5
            platformPart.BrickColor = BrickColor.new("Really black")
            platformPart.Parent = Workspace
        end
        platformPart.CFrame = CFrame.new(rootPart.Position - Vector3.new(0, undergroundDepth + 3, 0))
        if Camera.CameraSubject ~= humanoid and humanoid then
            originalCameraSubject = Camera.CameraSubject
            Camera.CameraSubject = humanoid
        end
    else
        if platformPart then
            platformPart:Destroy()
            platformPart = nil
        end
        if originalCameraSubject and Camera then
            Camera.CameraSubject = originalCameraSubject
            originalCameraSubject = nil
        end
    end
end)

-- Aimbot Loop
RunService.RenderStepped:Connect(function()
    if autoAimEnabled or aimbotEnabled then
        local targetPart = getNearestPlayerTarget()
        if targetPart then
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, targetPart.Position)
        end
    end
end)

-- Gun Mod Processor Loop
RunService.Heartbeat:Connect(function()
    local character = LocalPlayer.Character
    if character then
        for _, tool in ipairs(character:GetChildren()) do
            if tool:IsA("Tool") then
                if fireRateModEnabled then
                    local val = tool:FindFirstChild("FireRate") or tool:FindFirstChild("Cooldown")
                    if val and val:IsA("NumberValue") then val.Value = customFireRateValue end
                end
                if spreadModEnabled then
                    local val = tool:FindFirstChild("Spread") or tool:FindFirstChild("Epsilon")
                    if val and val:IsA("NumberValue") then val.Value = customSpreadValue end
                end
                if damageModEnabled then
                    local val = tool:FindFirstChild("Damage") or tool:FindFirstChild("BaseDamage")
                    if val and val:IsA("NumberValue") then val.Value = customDamageValue end
                end
                if autoFireEnabled then
                    local val = tool:FindFirstChild("Auto") or tool:FindFirstChild("Automatic")
                    if val and val:IsA("BoolValue") then val.Value = true end
                end
            end
        end
    end
end)

-- UI Library Integration
local library = loadstring(game:HttpGet("https://raw.githubusercontent.com/bigdanix/elegant-ui-libs/refs/heads/main/millenium/source"))()
local window = library:window({name = "pris", suffix = "lim", gameInfo = "optimized prison life"})

window:seperator({name = "Main Navigation"})

local enemiesTab, teammatesTab, selfTab = window:tab({name = "Operations", tabs = {"Enemies", "Teammates", "Self"}})
for _, tab in {enemiesTab, teammatesTab, selfTab} do 
    local column = tab:column({})
    
    local sectionWeapons = column:section({name = "Equipment Acquisition", default = true, toggle = false})
    local vectorWeaponsEnabled = false
    sectionWeapons:toggle({name = "Auto-Vector to Nearest Weapon", seperator = true, callback = function(bool)
        vectorWeaponsEnabled = bool
        task.spawn(function()
            while vectorWeaponsEnabled do
                local rootPart = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if rootPart then
                    local targetTool = getNearestTool()
                    if targetTool then rootPart.CFrame = CFrame.new(targetTool.Position + Vector3.new(0, 3, 0)) end
                end
                task.wait(0.2)
            end
        end)
    end})

    local sectionAccessories = column:section({name = "Accessory Acquisition", default = true, toggle = false})
    local vectorAccessoriesEnabled = false
    sectionAccessories:toggle({name = "Auto-Vector to Nearest Accessory", seperator = true, callback = function(bool)
        vectorAccessoriesEnabled = bool
        task.spawn(function()
            while vectorAccessoriesEnabled do
                local rootPart = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if rootPart then
                    local targetAccessory = getNearestAccessory()
                    if targetAccessory then rootPart.CFrame = CFrame.new(targetAccessory.Position + Vector3.new(0, 3, 0)) end
                end
                task.wait(0.2)
            end
        end)
    end})
end

-- Combat Systems Tab
local enemiesTab2, teammatesTab2, selfTab2 = window:tab({name = "Combat Systems", tabs = {"Enemies", "Teammates", "Self"}})
for _, tab in {enemiesTab2, teammatesTab2, selfTab2} do 
    local column = tab:column({})
    local sectionCamera = column:section({name = "Camera Targeting System", default = true})
    
    sectionCamera:toggle({name = "Enable Camera Auto-Aim", seperator = true, callback = function(bool) autoAimEnabled = bool end})
    sectionCamera:toggle({name = "Enable Aimbot", seperator = true, callback = function(bool) aimbotEnabled = bool end})
    sectionCamera:dropdown({name = "Target Team Filter", items = {"Enemies", "Teammates", "Self"}, default = "Enemies", multi = false, seperator = true, callback = function(selected) selectedTargetTeam = selected end})
    sectionCamera:dropdown({name = "Target Anatomy Part", items = {"Head", "HumanoidRootPart"}, default = "Head", multi = false, seperator = true, callback = function(selected) selectedTargetPartName = selected end})

    local sectionFireRate = column:section({name = "Weapon Enhancements & Gun Mods", default = true})
    sectionFireRate:label({name = "Notice", info = "Re-equip your weapon after toggling modifications!"})
    sectionFireRate:toggle({name = "Enable Fire Rate Modifier", seperator = true, callback = function(bool) fireRateModEnabled = bool end})
    sectionFireRate:toggle({name = "Enable Zero Spread", seperator = true, callback = function(bool) spreadModEnabled = bool end})
    sectionFireRate:toggle({name = "Enable Damage Modifier", seperator = true, callback = function(bool) damageModEnabled = bool end})
    sectionFireRate:toggle({name = "Enable Auto-Fire", seperator = true, callback = function(bool) autoFireEnabled = bool end})
end

-- World Utilities Tab
local enemiesTab3, teammatesTab3, selfTab3 = window:tab({name = "World Utilities", tabs = {"Enemies", "Teammates", "Self"}})
for _, tab in {enemiesTab3, teammatesTab3, selfTab3} do 
    local column = tab:column({})
    local sectionEnv = column:section({name = "Environment Telemetry", default = true})
    sectionEnv:toggle({name = "Enable Underground Invisibility Platform", seperator = true, callback = function(bool) invisibilityEnabled = bool end})
    sectionEnv:toggle({name = "Enable Entity ESP", seperator = true, callback = function(bool) espEnabled = bool end})
end

library:init_config(window)
