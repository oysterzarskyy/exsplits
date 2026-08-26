-- Made by @oysterzarskyy on github
-- uses documentation on windui, credits!
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TextChatService = game:GetService("TextChatService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local localPlayer = Players.LocalPlayer
local flyEnabled = false
local flySpeed = 50
local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
WindUI:SetFont("rbxassetid://12187365559") --  Mukta by @Roblox, link: https://create.roblox.com/store/asset/12187365559/Mukta?pageNumber=0&pagePosition=12
WindUI:SetNotificationLower(true)

local Window =
    WindUI:CreateWindow(
    {
        Title = "latefl1es", -- window title
        Icon = "door-open", -- lucide icon or "rbxassetid://" or URL. optional
        Author = "by oysterzarskkyy", -- window subtitle. optional
        Theme = "Dark", -- library theme
        Resizable = true, -- the ability to rezize window
        HideSearchBar = false, -- hide search bar
        ScrollBarEnabled = true -- scrollbars that are located to the right of the scroll frame
    }
)
-- ai thinks it can beat maximum overdrive in bypassing prompts that a baby could do
local Tab =
    Window:Tab(
    {
        Title = "Fly",
        Icon = "drone"
    }
)

-- Fly Toggle
Tab:Toggle(
    {
        Title = "Enable Fly",
        Default = false,
        Callback = function(state)
            flyEnabled = state
            local character = localPlayer.Character
            if not character or not character:FindFirstChild("HumanoidRootPart") then
                return
            end

            local rootPart = character.HumanoidRootPart
            local humanoid = character:FindFirstChildOfClass("Humanoid")

            if flyEnabled then
                if humanoid then
                    humanoid.PlatformStand = true
                end

                -- Create physics body movers for smooth floating
                local attachment = Instance.new("Attachment", rootPart)
                attachment.Name = "FlyAttachment"

                local linearVelocity = Instance.new("LinearVelocity", rootPart)
                linearVelocity.Name = "FlyVelocity"
                linearVelocity.Attachment0 = attachment
                linearVelocity.MaxForce = math.huge
                linearVelocity.VectorVelocity = Vector3.zero

                -- Movement update loop
                local connection
                connection =
                    RunService.RenderStepped:Connect(
                    function()
                        if not flyEnabled or not character.Parent then
                            connection:Disconnect()
                            if attachment then
                                attachment:Destroy()
                            end
                            if linearVelocity then
                                linearVelocity:Destroy()
                            end
                            if humanoid then
                                humanoid.PlatformStand = false
                            end
                            return
                        end

                        local camera = workspace.CurrentCamera
                        local moveDirection = Vector3.zero

                        -- Keyboard controls (WASD / Arrow Keys)
                        if UserInputService:IsKeyDown(Enum.KeyCode.W) or UserInputService:IsKeyDown(Enum.KeyCode.Up) then
                            moveDirection = moveDirection + camera.CFrame.LookVector
                        end
                        if UserInputService:IsKeyDown(Enum.KeyCode.S) or UserInputService:IsKeyDown(Enum.KeyCode.Down) then
                            moveDirection = moveDirection - camera.CFrame.LookVector
                        end
                        if UserInputService:IsKeyDown(Enum.KeyCode.D) or UserInputService:IsKeyDown(Enum.KeyCode.Right) then
                            moveDirection = moveDirection + camera.CFrame.RightVector
                        end
                        if UserInputService:IsKeyDown(Enum.KeyCode.A) or UserInputService:IsKeyDown(Enum.KeyCode.Left) then
                            moveDirection = moveDirection - camera.CFrame.RightVector
                        end
                        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                            moveDirection = moveDirection + Vector3.new(0, 1, 0)
                        end
                        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
                            moveDirection = moveDirection - Vector3.new(0, 1, 0)
                        end

                        if moveDirection.Magnitude > 0 then
                            linearVelocity.VectorVelocity = moveDirection.Unit * flySpeed
                        else
                            linearVelocity.VectorVelocity = Vector3.zero
                        end
                    end
                )
            else
                if humanoid then
                    humanoid.PlatformStand = false
                end
                local root = character:FindFirstChild("HumanoidRootPart")
                if root then
                    if root:FindFirstChild("FlyVelocity") then
                        root.FlyVelocity:Destroy()
                    end
                    if root:FindFirstChild("FlyAttachment") then
                        root.FlyAttachment:Destroy()
                    end
                end
            end
        end
    }
)

-- Speed Modifier Slider
Tab:Slider(
    {
        Title = "Fly Speed",
        Value = {Min = 16, Max = 200, Default = 50},
        Callback = function(value)
            flySpeed = value
        end
    }
)

-- ==================== INF JUMP TAB ====================
local infJumpEnabled = false

local InfJumpTab =
    Window:Tab(
    {
        Title = "Inf Jump",
        Icon = "feather" -- Or any other preferred icon like "activity" / "chevrons-up"
    }
)

InfJumpTab:Toggle(
    {
        Title = "Enable Inf Jump",
        Default = false,
        Callback = function(state)
            infJumpEnabled = state
        end
    }
)

-- Inf Jump Input Listener
UserInputService.JumpRequest:Connect(
    function()
        if infJumpEnabled then
            local character = localPlayer.Character
            if character then
                local humanoid = character:FindFirstChildOfClass("Humanoid")
                if humanoid then
                    humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                end
            end
        end
    end
)

-- ==================== OWNERSHIP VERIFICATION ====================
local isOwner = false
if game.CreatorType == Enum.CreatorType.User then
    isOwner = (localPlayer.UserId == game.CreatorId)
elseif game.CreatorType == Enum.CreatorType.Group then
    isOwner = localPlayer:IsInGroup(game.CreatorId) and (localPlayer:GetRankInGroup(game.CreatorId) == 255)
end

-- ==================== CHAT HELPER FUNCTION ====================
local function sendChatMessage(message)
    pcall(
        function()
            if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
                local textChannel = TextChatService.TextChannels:FindFirstChild("RBXGeneral")
                if textChannel then
                    textChannel:SendAsync(message)
                end
            else
                game:GetService("ReplicatedStorage").DefaultChatSystemChatEvents.SayMessageRequest:FireServer(
                    message,
                    "All"
                )
            end
        end
    )
end

-- ==================== OWNER TAB ====================
local OwnerTab =
    Window:Tab(
    {
        Title = "Owner Panel",
        Icon = "crown"
    }
)

if isOwner then
    -- Fly Function Logic
    local flyActive = false
    local flySpeed = 50
    local RunService = game:GetService("RunService")
    local UserInputService = game:GetService("UserInputService")

    OwnerTab:Toggle(
        {
            Title = "Server Owner Fly",
            Default = false,
            Callback = function(state)
                flyActive = state
                local character = localPlayer.Character
                if not character or not character:FindFirstChild("HumanoidRootPart") then
                    return
                end

                local rootPart = character.HumanoidRootPart
                local humanoid = character:FindFirstChildOfClass("Humanoid")

                if flyActive then
                    if humanoid then
                        humanoid.PlatformStand = true
                    end
                    local attachment = Instance.new("Attachment", rootPart)
                    attachment.Name = "OwnerFlyAtt"
                    local linearVelocity = Instance.new("LinearVelocity", rootPart)
                    linearVelocity.Name = "OwnerFlyVel"
                    linearVelocity.Attachment0 = attachment
                    linearVelocity.MaxForce = math.huge
                    linearVelocity.VectorVelocity = Vector3.zero

                    local connection
                    connection =
                        RunService.RenderStepped:Connect(
                        function()
                            if not flyActive or not character.Parent then
                                connection:Disconnect()
                                if attachment then
                                    attachment:Destroy()
                                end
                                if linearVelocity then
                                    linearVelocity:Destroy()
                                end
                                if humanoid then
                                    humanoid.PlatformStand = false
                                end
                                return
                            end

                            local camera = workspace.CurrentCamera
                            local moveDir = Vector3.zero
                            if UserInputService:IsKeyDown(Enum.KeyCode.W) then
                                moveDir = moveDir + camera.CFrame.LookVector
                            end
                            if UserInputService:IsKeyDown(Enum.KeyCode.S) then
                                moveDir = moveDir - camera.CFrame.LookVector
                            end
                            if UserInputService:IsKeyDown(Enum.KeyCode.D) then
                                moveDir = moveDir + camera.CFrame.RightVector
                            end
                            if UserInputService:IsKeyDown(Enum.KeyCode.A) then
                                moveDir = moveDir - camera.CFrame.RightVector
                            end
                            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                                moveDir = moveDir + Vector3.new(0, 1, 0)
                            end
                            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
                                moveDir = moveDir - Vector3.new(0, 1, 0)
                            end

                            if moveDir.Magnitude > 0 then
                                linearVelocity.VectorVelocity = moveDir.Unit * flySpeed
                            else
                                linearVelocity.VectorVelocity = Vector3.zero
                            end
                        end
                    )
                else
                    if humanoid then
                        humanoid.PlatformStand = false
                    end
                    if rootPart:FindFirstChild("OwnerFlyVel") then
                        rootPart.OwnerFlyVel:Destroy()
                    end
                    if rootPart:FindFirstChild("OwnerFlyAtt") then
                        rootPart.OwnerFlyAtt:Destroy()
                    end
                end
            end
        }
    )

    OwnerTab:Slider(
        {
            Title = "Fly Speed",
            Value = {Min = 16, Max = 300, Default = 50},
            Callback = function(val)
                flySpeed = val
            end
        }
    )

    -- Inf Jump Function Logic
    local infJumpActive = false
    OwnerTab:Toggle(
        {
            Title = "Server Owner Inf Jump",
            Default = false,
            Callback = function(state)
                infJumpActive = state
            end
        }
    )

    UserInputService.JumpRequest:Connect(
        function()
            if isOwner and infJumpActive then
                local character = localPlayer.Character
                if character then
                    local humanoid = character:FindFirstChildOfClass("Humanoid")
                    if humanoid then
                        humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                    end
                end
            end
        end
    )

    -- God Mode Function Logic
    OwnerTab:Toggle(
        {
            Title = "Server Owner God Mode",
            Default = false,
            Callback = function(state)
                local character = localPlayer.Character
                if character then
                    local humanoid = character:FindFirstChildOfClass("Humanoid")
                    if humanoid then
                        if state then
                            humanoid.MaxHealth = math.huge
                            humanoid.Health = math.huge
                        else
                            humanoid.MaxHealth = 100
                            humanoid.Health = 100
                        end
                    end
                end
            end
        }
    )
else
    -- Non-Owner Trap Logic: Adds dummy buttons that trigger the warning chat message
    local function triggerDenied()
        sendChatMessage("❌ Not Game Owner, who is thinking of adding ss functions to an foss script?")
    end

    OwnerTab:Toggle(
        {
            Title = "Server Owner Fly",
            Default = false,
            Callback = function(state)
                triggerDenied()
            end
        }
    )

    OwnerTab:Slider(
        {
            Title = "Fly Speed",
            Value = {Min = 16, Max = 300, Default = 50},
            Callback = function(val)
                triggerDenied()
            end
        }
    )

    OwnerTab:Toggle(
        {
            Title = "Server Owner Inf Jump",
            Default = false,
            Callback = function(state)
                triggerDenied()
            end
        }
    )

    OwnerTab:Toggle(
        {
            Title = "Server Owner God Mode",
            Default = false,
            Callback = function(state)
                triggerDenied()
            end
        }
    )
end
