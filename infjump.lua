--[[
    INF JUMP GUI - Small, Draggable, Stable
    Red = OFF | Green = ON
    Works after death/respawn
    PC & Mobile compatible
    Delta Executor
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

-- Main button (draggable)
local Button = Instance.new("TextButton")
Button.Size = UDim2.new(0, 110, 0, 40)
Button.Position = UDim2.new(0, 10, 0, 10)
Button.BackgroundColor3 = Color3.fromRGB(200, 50, 50) -- Red = OFF
Button.BorderSizePixel = 0
Button.Text = "INF JUMP: OFF"
Button.TextColor3 = Color3.fromRGB(255, 255, 255)
Button.TextSize = 14
Button.Font = Enum.Font.GothamBold
Button.AutoButtonColor = false
Button.Draggable = true
Button.Parent = Gui

Instance.new("UICorner", Button).CornerRadius = UDim.new(0, 8)

-- ============================================
-- INF JUMP FUNCTION
-- ============================================
local function DoJump()
    local char = LocalPlayer.Character
    if not char then return end
    
    local humanoid = char:FindFirstChild("Humanoid")
    if not humanoid then return end
    
    -- Only jump if not already in a state that prevents jumping
    local state = humanoid:GetState()
    if state == Enum.HumanoidStateType.Dead then return end
    if state == Enum.HumanoidStateType.Physics then return end
    
    -- Force jump
    humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
end

-- ============================================
-- SETUP JUMP CONNECTION
-- ============================================
local function SetupJumpConnection()
    -- Disconnect old connection if exists
    if JumpConnection then
        JumpConnection:Disconnect()
        JumpConnection = nil
    end
    
    -- Create new connection
    JumpConnection = UserInputService.JumpRequest:Connect(function()
        if InfJumpEnabled then
            DoJump()
        end
    end)
end

-- ============================================
-- ENABLE / DISABLE
-- ============================================
local function EnableInfJump()
    InfJumpEnabled = true
    Button.BackgroundColor3 = Color3.fromRGB(40, 180, 60) -- Green = ON
    Button.Text = "INF JUMP: ON"
    SetupJumpConnection()
end

local function DisableInfJump()
    InfJumpEnabled = false
    Button.BackgroundColor3 = Color3.fromRGB(200, 50, 50) -- Red = OFF
    Button.Text = "INF JUMP: OFF"
end

-- ============================================
-- BUTTON CLICK
-- ============================================
Button.MouseButton1Click:Connect(function()
    if InfJumpEnabled then
        DisableInfJump()
    else
        EnableInfJump()
    end
end)

-- ============================================
-- RESPAWN HANDLER - Reconnect after death
-- ============================================
LocalPlayer.CharacterAdded:Connect(function(char)
    -- Wait for character to fully load
    task.wait(0.2)
    
    -- If inf jump is enabled, reconnect the jump listener
    if InfJumpEnabled then
        SetupJumpConnection()
    end
end)

-- ============================================
-- INIT
-- ============================================
print("=================================")
print("✅ INF JUMP LOADED")
print("🔴 Red = OFF")
print("🟢 Green = ON")
print("🖱️ Drag to move")
print("📱 PC & Mobile supported")
print("🔄 Works after respawn")
print("=================================")