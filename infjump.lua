--[[
    INF JUMP GUI - Small & Draggable
    Red = OFF | Green = ON
    Delta Executor Compatible
--]]

-- Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

-- State
local InfJumpEnabled = false
local JumpConnection = nil

-- ============================================
-- CREATE GUI
-- ============================================
local Gui = Instance.new("ScreenGui")
Gui.Name = "InfJumpGui"
Gui.Parent = game:GetService("CoreGui")
Gui.ResetOnSpawn = false
Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- Main frame (draggable)
local Frame = Instance.new("TextButton")
Frame.Size = UDim2.new(0, 100, 0, 40)
Frame.Position = UDim2.new(0, 10, 0, 10)
Frame.BackgroundColor3 = Color3.fromRGB(200, 50, 50) -- Red = OFF
Frame.BorderSizePixel = 0
Frame.Text = "INF JUMP: OFF"
Frame.TextColor3 = Color3.fromRGB(255, 255, 255)
Frame.TextSize = 14
Frame.Font = Enum.Font.GothamBold
Frame.AutoButtonColor = false
Frame.Draggable = true
Frame.Parent = Gui

Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 8)

-- ============================================
-- INF JUMP LOGIC
-- ============================================
local function EnableInfJump()
    InfJumpEnabled = true
    Frame.BackgroundColor3 = Color3.fromRGB(40, 180, 60) -- Green = ON
    Frame.Text = "INF JUMP: ON"
    
    JumpConnection = UserInputService.JumpRequest:Connect(function()
        if InfJumpEnabled then
            local char = LocalPlayer.Character
            if char then
                local humanoid = char:FindFirstChild("Humanoid")
                if humanoid and humanoid:GetState() ~= Enum.HumanoidStateType.Freefall then
                    humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                end
            end
        end
    end)
end

local function DisableInfJump()
    InfJumpEnabled = false
    Frame.BackgroundColor3 = Color3.fromRGB(200, 50, 50) -- Red = OFF
    Frame.Text = "INF JUMP: OFF"
    
    if JumpConnection then
        JumpConnection:Disconnect()
        JumpConnection = nil
    end
end

-- ============================================
-- BUTTON CLICK
-- ============================================
Frame.MouseButton1Click:Connect(function()
    if InfJumpEnabled then
        DisableInfJump()
    else
        EnableInfJump()
    end
end)

-- ============================================
-- RESPAWN HANDLER
-- ============================================
LocalPlayer.CharacterAdded:Connect(function()
    if InfJumpEnabled then
        -- Reconnect after respawn
        if JumpConnection then
            JumpConnection:Disconnect()
        end
        JumpConnection = UserInputService.JumpRequest:Connect(function()
            if InfJumpEnabled then
                local char = LocalPlayer.Character
                if char then
                    local humanoid = char:FindFirstChild("Humanoid")
                    if humanoid and humanoid:GetState() ~= Enum.HumanoidStateType.Freefall then
                        humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                    end
                end
            end
        end)
    end
end)

-- ============================================
-- INIT
-- ============================================
print("✅ Inf Jump GUI Loaded")
print("📌 Red = OFF | Green = ON")
print("🖱️ Drag to move | Click to toggle")