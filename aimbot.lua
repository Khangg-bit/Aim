--[[
    PRO AIMBOT V3 - Khóa đầu ngay khi trong vòng tròn
    Delta Executor - Tâm thật, khóa cứng đầu địch
--]]

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local UserInputService = game:GetService("UserInputService")

-- Settings
local FOV = 150 -- Kích thước vòng tròn (pixel)
local Smoothness = 0.1 -- Độ dính (càng thấp càng dính)
local AimPart = "Head" -- Head hoặc HumanoidRootPart
local VisibleCheck = true -- Kiểm tra tường
local TeamCheck = true -- Không aim đồng đội

-- ============================================
-- TẠO VÒNG TRÒN FOV
-- ============================================
local FOVGui = Instance.new("ScreenGui")
FOVGui.Name = "AimbotFOV"
FOVGui.Parent = game:GetService("CoreGui")
FOVGui.ResetOnSpawn = false
FOVGui.IgnoreGuiInset = true

local Circle = Instance.new("Frame")
Circle.Size = UDim2.new(0, FOV * 2, 0, FOV * 2)
Circle.Position = UDim2.new(0.5, -FOV, 0.5, -FOV)
Circle.BackgroundTransparency = 1
Circle.BorderSizePixel = 0
Circle.Parent = FOVGui

local CircleStroke = Instance.new("UIStroke")
CircleStroke.Thickness = 2
CircleStroke.Color = Color3.fromRGB(255, 255, 255)
CircleStroke.Transparency = 0.6
CircleStroke.Parent = Circle

local CircleCorner = Instance.new("UICorner")
CircleCorner.CornerRadius = UDim.new(1, 0)
CircleCorner.Parent = Circle

-- ============================================
-- KIỂM TRA TƯỜNG
-- ============================================
local function IsWallBetween(targetPos)
    local character = LocalPlayer.Character
    if not character then return true end
    
    local head = character:FindFirstChild("Head")
    if not head then return true end
    
    local rayParams = RaycastParams.new()
    rayParams.FilterDescendantsInstances = {character}
    rayParams.FilterType = Enum.RaycastFilterType.Blacklist
    
    local direction = (targetPos - head.Position).Unit
    local distance = (targetPos - head.Position).Magnitude
    
    local ray = Workspace:Raycast(head.Position, direction * distance, rayParams)
    
    return ray ~= nil
end

-- ============================================
-- TÌM ĐẦU ĐỊCH TRONG VÒNG TRÒN
-- ============================================
local function GetHeadInFOV()
    local character = LocalPlayer.Character
    if not character then return nil end
    
    local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    local bestTarget = nil
    local bestDistance = FOV

    for _, player in pairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        
        local targetChar = player.Character
        if not targetChar then continue end
        
        local targetHum = targetChar:FindFirstChild("Humanoid")
        if not targetHum or targetHum.Health <= 0 then continue end
        
        if TeamCheck and LocalPlayer.Team and player.Team == LocalPlayer.Team then
            continue
        end
        
        local targetPart
        if AimPart == "Head" then
            targetPart = targetChar:FindFirstChild("Head")
        else
            targetPart = targetChar:FindFirstChild("HumanoidRootPart")
        end
        
        if not targetPart then continue end
        
        local screenPos, onScreen = Camera:WorldToScreenPoint(targetPart.Position)
        
        if onScreen then
            local distFromCenter = (Vector2.new(screenPos.X, screenPos.Y) - screenCenter).Magnitude
            
            if distFromCenter < bestDistance then
                if VisibleCheck and IsWallBetween(targetPart.Position) then
                    continue
                end
                
                bestDistance = distFromCenter
                bestTarget = targetPart
            end
        end
    end
    
    return bestTarget
end

-- ============================================
-- AIMBOT CHÍNH
-- ============================================
local lockedTarget = nil

RunService.RenderStepped:Connect(function()
    local target = GetHeadInFOV()
    
    if target then
        lockedTarget = target
        
        -- Đổi màu đỏ khi khóa
        CircleStroke.Color = Color3.fromRGB(255, 30, 30)
        CircleStroke.Transparency = 0.3
        
        -- Khóa cứng vào đầu
        Camera.CFrame = CFrame.new(Camera.CFrame.Position, target.Position)
        
    else
        lockedTarget = nil
        
        -- Reset màu trắng
        CircleStroke.Color = Color3.fromRGB(255, 255, 255)
        CircleStroke.Transparency = 0.6
    end
end)

-- ============================================
-- THẢ AIM KHI MỤC TIÊU CHẾT
-- ============================================
coroutine.wrap(function()
    while task.wait(0.2) do
        if lockedTarget then
            local parent = lockedTarget.Parent
            if not parent then
                lockedTarget = nil
            else
                local hum = parent:FindFirstChild("Humanoid")
                if not hum or hum.Health <= 0 then
                    lockedTarget = nil
                end
            end
        end
    end
end)()

print("🎯 Aimbot Ready - Đầu địch vào vòng tròn là khóa!")