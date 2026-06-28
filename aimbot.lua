--[[
    PRO AIMBOT V2 - Tâm giữa màn hình, khóa đầu khi trong vòng tròn
    Delta Executor - Ghim cứng đầu địch
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
local Smoothness = 0.15 -- Độ mượt (càng thấp càng dính)
local AimPart = "Head" -- Bộ phận aim
local VisibleCheck = true -- Kiểm tra tường
local TeamCheck = true -- Không aim đồng đội

-- ============================================
-- TẠO VÒNG TRÒN FOV TÂM MÀN HÌNH
-- ============================================
local FOVGui = Instance.new("ScreenGui")
FOVGui.Name = "AimbotFOV"
FOVGui.Parent = game:GetService("CoreGui")
FOVGui.ResetOnSpawn = false
FOVGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
FOVGui.IgnoreGuiInset = true

-- Vòng tròn chính
local Circle = Instance.new("Frame")
Circle.Size = UDim2.new(0, FOV * 2, 0, FOV * 2)
Circle.Position = UDim2.new(0.5, -FOV, 0.5, -FOV)
Circle.BackgroundTransparency = 1
Circle.BorderSizePixel = 0
Circle.Parent = FOVGui

-- Viền vòng tròn (dùng UIStroke)
local CircleStroke = Instance.new("UIStroke")
CircleStroke.Thickness = 2
CircleStroke.Color = Color3.fromRGB(255, 255, 255)
CircleStroke.Transparency = 0.5
CircleStroke.Parent = Circle

local CircleCorner = Instance.new("UICorner")
CircleCorner.CornerRadius = UDim.new(1, 0)
CircleCorner.Parent = Circle

-- Chấm tâm
local Dot = Instance.new("Frame")
Dot.Size = UDim2.new(0, 10, 0, 10)
Dot.Position = UDim2.new(0.5, -5, 0.5, -5)
Dot.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
Dot.BorderSizePixel = 0
Dot.Parent = FOVGui
Instance.new("UICorner", Dot).CornerRadius = UDim.new(1, 0)

local DotStroke = Instance.new("UIStroke")
DotStroke.Thickness = 1.5
DotStroke.Color = Color3.fromRGB(255, 100, 100)
DotStroke.Parent = Dot

-- Crosshair
local function CreateCrosshairLine(rotation, length, thickness)
    local line = Instance.new("Frame")
    line.Size = UDim2.new(0, length, 0, thickness)
    line.Position = UDim2.new(0.5, -length/2, 0.5, -thickness/2)
    line.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    line.BorderSizePixel = 0
    line.Rotation = rotation
    line.Parent = FOVGui
    return line
end

CreateCrosshairLine(0, 25, 2)
CreateCrosshairLine(90, 25, 2)
CreateCrosshairLine(0, 12, 1)
CreateCrosshairLine(90, 12, 1)

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
    
    return ray ~= nil -- Có vật cản = true
end

-- ============================================
-- TÌM MỤC TIÊU TỐT NHẤT TRONG FOV
-- ============================================
local function GetTargetInFOV()
    local character = LocalPlayer.Character
    if not character then return nil end
    
    local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    local bestTarget = nil
    local bestDistance = FOV -- Phải trong vòng tròn
    
    for _, player in pairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        
        local targetChar = player.Character
        if not targetChar then continue end
        
        local targetHum = targetChar:FindFirstChild("Humanoid")
        if not targetHum or targetHum.Health <= 0 then continue end
        
        -- Team check
        if TeamCheck and LocalPlayer.Team and player.Team == LocalPlayer.Team then
            continue
        end
        
        -- Lấy phần aim
        local targetPart
        if AimPart == "Head" then
            targetPart = targetChar:FindFirstChild("Head")
        else
            targetPart = targetChar:FindFirstChild("HumanoidRootPart")
        end
        
        if not targetPart then continue end
        
        -- Lấy vị trí trên màn hình
        local screenPos, onScreen = Camera:WorldToScreenPoint(targetPart.Position)
        
        if onScreen then
            local distFromCenter = (Vector2.new(screenPos.X, screenPos.Y) - screenCenter).Magnitude
            
            -- Kiểm tra trong FOV
            if distFromCenter < bestDistance then
                -- Wall check
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
-- AIMBOT CHÍNH - GHIM CỨNG ĐẦU
-- ============================================
local lockedTarget = nil

RunService.RenderStepped:Connect(function(deltaTime)
    -- Tìm mục tiêu
    local target = GetTargetInFOV()
    
    if target then
        lockedTarget = target
        
        -- Chuyển màu đỏ khi khóa
        CircleStroke.Color = Color3.fromRGB(255, 30, 30)
        CircleStroke.Transparency = 0.2
        Dot.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
        
        -- GHIM CỨNG VÀO ĐẦU
        local targetPos = target.Position
        
        -- Tạo CFrame nhìn thẳng vào đầu
        local goalCFrame = CFrame.new(Camera.CFrame.Position, targetPos)
        
        -- Lerp mượt
        Camera.CFrame = Camera.CFrame:Lerp(goalCFrame, Smoothness)
        
    else
        lockedTarget = nil
        
        -- Reset màu trắng
        CircleStroke.Color = Color3.fromRGB(255, 255, 255)
        CircleStroke.Transparency = 0.5
        Dot.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
    end
end)

-- ============================================
-- KIỂM TRA MỤC TIÊU CHẾT - THẢ AIM
-- ============================================
coroutine.wrap(function()
    while task.wait(0.3) do
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

-- ============================================
-- THÔNG BÁO
-- ============================================
print("=================================")
print("🎯 PRO AIMBOT V2 ACTIVATED!")
print("✅ Tâm giữa màn hình")
print("✅ FOV: " .. FOV .. "px")
print("✅ Ghim cứng: " .. AimPart)
print("✅ Wall Check: ON")
print("✅ Auto unlock khi chết")
print("=================================")