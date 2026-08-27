-- pris lim - prison life mod

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- Configuration states
local autoAimEnabled = false
local aimbotEnabled = false
local autoFireEnabled = false
local selectedTargetTeam = "Enemies" -- Options: "Enemies", "Teammates", "Self"
local selectedTargetPartName = "Head" -- Options: "Head", "HumanoidRootPart"

-- Gun Mod Configurations
local fireRateModEnabled = false
local customFireRateValue = 0.05
local spreadModEnabled = false
local customSpreadValue = 0
local damageModEnabled = false
local customDamageValue = 100

-- ESP Configurations
local espEnabled = false
local minEspDistance = 500
local maxEspDistance = 3000
local espCache = {}

-- Invisibility / Underground Platform Features
local invisibilityEnabled = false
local platformPart = nil
local originalCameraSubject = nil
local undergroundDepth = 50

-- Primary / Weapon Tools List
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

-- Accessory Tools List
local prioritizedAccessoryNames = {
    ["Light Vest"] = true
}

-- Function to find the nearest weapon/tool
local function getNearestTool()
    local character = LocalPlayer.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return nil end
    
    local rootPart = character.HumanoidRootPart
    local bestTool = nil
    local bestScore = -math.huge

    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Tool") or (obj:IsA("BasePart") and obj.Name == "Handle" and obj.Parent and obj.Parent:IsA("Tool")) then
            local toolInstance = obj:IsA("Tool") and obj or obj.Parent
            local targetPart = toolInstance:FindFirstChild("Handle") or toolInstance.PrimaryPart or (toolInstance:IsA("Model") and toolInstance:FindFirstChildWhichIsA("BasePart"))
            
            if targetPart then
                local distance = (rootPart.Position - targetPart.Position).Magnitude
                local toolName = toolInstance.Name
                
                if prioritizedWeaponNames[toolName] then
                    local score = 500 - distance
                    if score > bestScore then
                        bestScore = score
                        bestTool = targetPart
                    end
                end
            end
        end
    end

    return bestTool
end

-- Function to find the nearest accessory tool
local function getNearestAccessory()
    local character = LocalPlayer.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return nil end
    
    local rootPart = character.HumanoidRootPart
    local bestAccessory = nil
    local bestScore = -math.huge

    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Tool") or (obj:IsA("BasePart") and obj.Name == "Handle" and obj.Parent and obj.Parent:IsA("Tool")) then
            local toolInstance = obj:IsA("Tool") and obj or obj.Parent
            local targetPart = toolInstance:FindFirstChild("Handle") or toolInstance.PrimaryPart or (toolInstance:IsA("Model") and toolInstance:FindFirstChildWhichIsA("BasePart"))
            
            if targetPart then
                local distance = (rootPart.Position - targetPart.Position).Magnitude
                local toolName = toolInstance.Name
                
                if prioritizedAccessoryNames[toolName] then
                    local score = 500 - distance
                    if score > bestScore then
                        bestScore = score
                        bestAccessory = targetPart
                    end
                end
            end
        end
    end

    return bestAccessory
end

-- Function to determine if a player matches the target team filter
local function isValidTeamTarget(player)
    if player == LocalPlayer then
        return selectedTargetTeam == "Self"
    end
    
    if selectedTargetTeam == "Teammates" then
        return player.Team == LocalPlayer.Team
    elseif selectedTargetTeam == "Enemies" then
        return player.Team ~= LocalPlayer.Team
    end
    
    return true
end

-- Function to find the nearest valid player character based on team and targeting part
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

-- Helper to get team color for ESP
local function getPlayerTeamColor(player)
    if player.Team then
        return player.Team.TeamColor.Color
    end
    return Color3.fromRGB(255, 255, 255)
end

-- ESP Management Loop (Range 500 - 3000 studs, Team Colored)
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
                    highlight.FillColor = getPlayerTeamColor(player)
                    highlight.OutlineColor = getPlayerTeamColor(player)
                    highlight.FillTransparency = 0.5
                else
                    highlight.Enabled = false
                end
            else
                if highlight then
                    highlight.Enabled = false
                end
            end
        end
    end
end)

-- Invisibility / Underground Platform Loop Handler
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

        local targetPos = rootPart.Position - Vector3.new(0, undergroundDepth, 0)
        platformPart.CFrame = CFrame.new(targetPos - Vector3.new(0, 3, 0))

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

-- Camera Auto-Aim RenderStepped Hook
RunService.RenderStepped:Connect(function()
    if autoAimEnabled then
        local targetPart = getNearestPlayerTarget()
        if targetPart then
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, targetPart.Position)
        end
    end
end)

-- Advanced Aimbot Hook (Mouse/View Snap)
RunService.RenderStepped:Connect(function()
    if aimbotEnabled then
        local targetPart = getNearestPlayerTarget()
        if targetPart then
            local camPos = Camera.CFrame.Position
            Camera.CFrame = CFrame.new(camPos, targetPart.Position)
        end
    end
end)

-- Gun Mod Modifications Loop (Requires Re-equipping tool)
RunService.Heartbeat:Connect(function()
    local character = LocalPlayer.Character
    if character then
        for _, tool in ipairs(character:GetChildren()) do
            if tool:IsA("Tool") then
                -- Fire Rate Modification
                if fireRateModEnabled then
                    local fireRateValue = tool:FindFirstChild("FireRate") or tool:FindFirstChild("Cooldown")
                    if fireRateValue and fireRateValue:IsA("NumberValue") then
                        fireRateValue.Value = customFireRateValue
                    end
                end

                -- Spread / Accuracy Modification
                if spreadModEnabled then
                    local spreadValue = tool:FindFirstChild("Spread") or tool:FindFirstChild("Epsilon") or tool:FindFirstChild("MinSpread")
                    if spreadValue and spreadValue:IsA("NumberValue") then
                        spreadValue.Value = customSpreadValue
                    end
                end

                -- Damage Modification
                if damageModEnabled then
                    local damageValue = tool:FindFirstChild("Damage") or tool:FindFirstChild("BaseDamage")
                    if damageValue and damageValue:IsA("NumberValue") then
                        damageValue.Value = customDamageValue
                    end
                end

                -- Auto-Fire Conversion
                if autoFireEnabled then
                    local autoValue = tool:FindFirstChild("Auto") or tool:FindFirstChild("Automatic")
                    if autoValue and autoValue:IsA("BoolValue") then
                        autoValue.Value = true
                    end
                end
            end
        end
    end
end)

-- Simulated Auto-Fire Click Trigger Loop
task.spawn(function()
    while true do
        if autoFireEnabled then
            local character = LocalPlayer.Character
            if character then
                local tool = character:FindFirstChildOfClass("Tool")
                if tool then
                    pcall(function()
                        tool:Activate()
                    end)
                end
            end
        end
        task.wait(0.05)
    end
end)

local library = loadstring(game:HttpGet("https://raw.githubusercontent.com/bigdanix/elegant-ui-libs/refs/heads/main/millenium/source"))()
local window = library:window({name = "pris", suffix = "lim", gameInfo = "prison life mod"})

window:seperator({name = "Main Navigation"})

-- Tab 1: Operations Hub
local enemiesTab, teammatesTab, selfTab = window:tab({name = "Operations", tabs = {"Enemies", "Teammates", "Self"}})
for _, tab in {enemiesTab, teammatesTab, selfTab} do 
    local column = tab:column({})
    
    local sectionWeapons = column:section({name = "Equipment Acquisition", default = true, toggle = false})
    local vectorWeaponsEnabled = false
    sectionWeapons:toggle({name = "Auto-Vector to Nearest Weapon", seperator = true, callback = function(bool)
        vectorWeaponsEnabled = bool
        task.spawn(function()
            while vectorWeaponsEnabled do
                local character = LocalPlayer.Character
                local rootPart = character and character:FindFirstChild("HumanoidRootPart")
                if rootPart then
                    local targetTool = getNearestTool()
                    if targetTool then
                        rootPart.CFrame = CFrame.new(targetTool.Position + Vector3.new(0, 3, 0))
                    end
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
                local character = LocalPlayer.Character
                local rootPart = character and character:FindFirstChild("HumanoidRootPart")
                if rootPart then
                    local targetAccessory = getNearestAccessory()
                    if targetAccessory then
                        rootPart.CFrame = CFrame.new(targetAccessory.Position + Vector3.new(0, 3, 0))
                    end
                end
                task.wait(0.2)
            end
        end)
    end})
end

for _, tab in {enemiesTab, teammatesTab, selfTab} do 
    local column = tab:column({})
    local sectionOverview = column:section({name = "Visual Render Configuration", default = true, toggle = false})
    sectionOverview:label({name = "Module Overview", info = "Configure entity visibility states, bounding box rendering parameters, and real-time situational tracking variables."})
    
    local page = tab:sub_tab({order = -10000, size = 2})
    
    for i = 1, 2 do 
        local subColumn = page:column({})
        local sectionTarget = subColumn:section({name = "Target Rendering", default = true})
        sectionTarget:toggle({name = "Enable Entity ESP", seperator = true, callback = function(bool) 
            espEnabled = bool
        end})
        sectionTarget:toggle({name = "Bypass Obstruction Checks", seperator = true})
        
        local shareFeedToggle = sectionTarget:toggle({name = "Team Share Feed", seperator = true})
        shareFeedToggle:colorpicker({})

        local configToggle = sectionTarget:toggle({name = "Identifier Configuration", seperator = true})
        configToggle:colorpicker({})
        local sub_section = configToggle:settings({})
        sub_section:toggle({name = "Display Names Visibility", seperator = true})
        sub_section:dropdown({name = "Typography Font", items = {"ProggyTiny", "MonoSpace", "Tahoma"}, default = "MonoSpace", seperator = true})
        sub_section:colorpicker({name = "Primary Accent Color", seperator = true})
        sub_section:keybind({name = "Trigger Hotkey", callback = function(bool) print(bool) end, info = "Assign a dedicated activation shortcut for quick tactical toggling."})

        local equipmentToggle = sectionTarget:toggle({name = "Equipment Identifier", seperator = true, info = "Monitors current weapon states and loadout statuses across active participants."})
        equipmentToggle:colorpicker({})
        
        sectionTarget:dropdown({name = "Status Flags", items = {"Scoped", "Flashed", "Knocked", "Touched"}, default = {"Scoped", "Flashed", "Knocked"}, multi = true, seperator = true})
        
        local telemetryToggle = sectionTarget:toggle({name = "Advanced Telemetry", seperator = false})
        telemetryToggle:colorpicker({})
    end
end 

-- Tab 2: Combat Systems
local enemiesTab2, teammatesTab2, selfTab2 = window:tab({name = "Combat Systems", tabs = {"Enemies", "Teammates", "Self"}})
for _, tab in {enemiesTab2, teammatesTab2, selfTab2} do 
    local column = tab:column({})
    local sectionCamera = column:section({name = "Camera Targeting System", default = true})
    
    sectionCamera:toggle({name = "Enable Camera Auto-Aim", seperator = true, callback = function(bool)
        autoAimEnabled = bool
    end})

    sectionCamera:toggle({name = "Enable Aimbot", seperator = true, callback = function(bool)
        aimbotEnabled = bool
    end})
    
    sectionCamera:dropdown({name = "Target Team Filter", items = {"Enemies", "Teammates", "Self"}, default = "Enemies", multi = false, seperator = true, callback = function(selected)
        selectedTargetTeam = selected
    end})

    sectionCamera:dropdown({name = "Target Anatomy Part", items = {"Head", "HumanoidRootPart"}, default = "Head", multi = false, seperator = true, callback = function(selected)
        selectedTargetPartName = selected
    end})

    local sectionFireRate = column:section({name = "Weapon Enhancements & Gun Mods", default = true})
    sectionFireRate:label({name = "Important Notice", info = "You must re-equip your gun after toggling or changing these settings for modifications to apply properly!"})
    
    sectionFireRate:toggle({name = "Enable Fire Rate Modifier", seperator = true, callback = function(bool)
        fireRateModEnabled = bool
    end})

    sectionFireRate:toggle({name = "Enable Zero Spread / Max Accuracy", seperator = true, callback = function(bool)
        spreadModEnabled = bool
    end})

    sectionFireRate:toggle({name = "Enable Damage Modifier", seperator = true, callback = function(bool)
        damageModEnabled = bool
    end})

    sectionFireRate:toggle({name = "Enable Auto-Fire", seperator = true, callback = function(bool)
        autoFireEnabled = bool
    end})

    for i = 1, 2 do 
        local subColumn = tab:column({})
        local sectionEngagement = subColumn:section({name = "Engagement Controls", default = true})
        sectionEngagement:toggle({name = "Enable Entity ESP", seperator = true, callback = function(bool) print(bool) end})
        sectionEngagement:toggle({name = "Bypass Obstruction Checks", seperator = true})
        
        local shareFeedToggle2 = sectionEngagement:toggle({name = "Team Share Feed", seperator = true})
        shareFeedToggle2:colorpicker({})

        local configToggle2 = sectionEngagement:toggle({name = "Identifier Configuration", seperator = true})
        configToggle2:colorpicker({})
        local sub_section2 = configToggle2:settings({})
        sub_section2:toggle({name = "Display Names Visibility", seperator = true})
        sub_section2:dropdown({name = "Typography Font", items = {"ProggyTiny", "MonoSpace", "Tahoma"}, default = "MonoSpace", seperator = true})
        sub_section2:colorpicker({name = "Primary Accent Color", seperator = true})
        sub_section2:keybind({name = "Trigger Hotkey", callback = function(bool) print(bool) end, info = "Assign a dedicated activation shortcut for quick tactical toggling."})

        local equipmentToggle2 = sectionEngagement:toggle({name = "Equipment Identifier", seperator = true, info = "Monitors current weapon states and loadout statuses across active participants."})
        equipmentToggle2:colorpicker({})
        
        sectionEngagement:dropdown({name = "Status Flags", items = {"Scoped", "Flashed", "Knocked", "Touched"}, default = {"Scoped", "Flashed", "Knocked"}, multi = true, seperator = true})
        
        local telemetryToggle2 = sectionEngagement:toggle({name = "Advanced Telemetry", seperator = false})
        telemetryToggle2:colorpicker({})
    end
end 

-- Tab 3: World Utilities
local enemiesTab3, teammatesTab3, selfTab3 = window:tab({name = "World Utilities", tabs = {"Enemies", "Teammates", "Self"}})
for _, tab in {enemiesTab3, teammatesTab3, selfTab3} do 
    local column = tab:column({})
    local sectionEnv = column:section({name = "Environment Telemetry", default = true})
    
    sectionEnv:toggle({name = "Enable Underground Invisibility Platform", seperator = true, callback = function(bool)
        invisibilityEnabled = bool
    end})

    sectionEnv:toggle({name = "Enable Entity ESP", seperator = true, callback = function(bool) print(bool) end})
    sectionEnv:toggle({name = "Bypass Obstruction Checks", seperator = true})
    
    local sharedEspToggle = sectionEnv:toggle({name = "Shared ESP", seperator = true})
    sharedEspToggle:colorpicker({})

    local configToggle3 = sectionEnv:toggle({name = "Identifier Configuration", seperator = true})
    configToggle3:colorpicker({})
    local sub_section3 = configToggle3:settings({})
    sub_section3:toggle({name = "Display Names Visibility", seperator = true})
    sub_section3:dropdown({name = "Font Name", items = {"ProggyTiny", "MonoSpace", "Tahoma"}, default = "MonoSpace", seperator = true})
    sub_section3:colorpicker({name = "Primary Accent Color", seperator = true})
    sub_section3:keybind({name = "Keybind", callback = function(bool) print(bool) end, info = "Assign a dedicated activation shortcut for quick tactical toggling."})

    local equipmentToggle3 = sectionEnv:toggle({name = "Equipment Identifier", seperator = true, info = "Monitors current weapon states and loadout statuses across active participants."})
    equipmentToggle3:colorpicker({})
    
    sectionEnv:dropdown({name = "Status Flags", items = {"Scoped", "Flashed", "Knocked", "Touched"}, default = {"Scoped", "Flashed", "Knocked"}, multi = true, seperator = true})
    
    local telemetryToggle3 = sectionEnv:toggle({name = "Advanced Telemetry", seperator = false})
    telemetryToggle3:colorpicker({})
end 

-- Tab 4: Diagnostics & Config
local enemiesTab4, teammatesTab4, selfTab4 = window:tab({name = "Diagnostics", tabs = {"Enemies", "Teammates", "Self"}})
for _, tab in {enemiesTab4, teammatesTab4, selfTab4} do 
    local column = tab:column({})

    for i = 1, 2 do 
        local sectionDiag = column:section({name = "System Diagnostics", default = true, size = 0.5})
        sectionDiag:toggle({name = "Enable Entity ESP", seperator = true, callback = function(bool) print(bool) end})
        sectionDiag:toggle({name = "Bypass Obstruction Checks", seperator = true})
        
        local sharedEspToggle2 = sectionDiag:toggle({name = "Shared ESP", seperator = true})
        sharedEspToggle2:colorpicker({})

        local nameToggle = sectionDiag:toggle({name = "Name", seperator = true})
        nameToggle:colorpicker({})
        local sub_section4 = nameToggle:settings({})
        sub_section4:toggle({name = "Show Display Names", seperator = true})
        sub_section4:dropdown({name = "Font Name", items = {"ProggyTiny", "MonoSpace", "Tahoma"}, default = "MonoSpace", seperator = true})
        sub_section4:colorpicker({name = "Another Colorpicker why not", seperator = true})
        sub_section4:keybind({name = "Keybind", callback = function(bool) print(bool) end, info = "Hello there this is a paragraph.."})

        local weaponToggle = sectionDiag:toggle({name = "Weapon", seperator = true, info = "Monitors weapon loadouts."})
        weaponToggle:colorpicker({})
        
        sectionDiag:dropdown({name = "Flags", items = {"Scoped", "Flashed", "Knocked", "Touched"}, default = {"Scoped", "Flashed", "Knocked"}, multi = true, seperator = true})
        
        local otherToggle = sectionDiag:toggle({name = "Other Shit", seperator = false})
        otherToggle:colorpicker({})
    end 
end 

library:init_config(window)
