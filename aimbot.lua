--[[
    PRO AIMBOT - Head Lock, Wall Check, FOV Circle
    Delta Executor - Không GUI, chỉ có vòng tròn FOV
    Tự động khóa đầu, kiểm tra tường, dừng khi mục tiêu chết
--]]

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- Settings
local FOV = 120 -- Kích thước vòng tròn FOV (pixel)
local Smoothness = 0.4 -- Độ mượt khi aim (0-1, càng thấp càng mượt)
local AimPart = "Head" -- Bộ phận aim: "Head" hoặc "HumanoidRootPart"
local VisibleCheck = true -- Kiểm tra tường
local TeamCheck = true -- Không aim đồng đội
local ShowFOV = true -- Hiện vòng tròn FOV

-- ============================================
-- TẠO VÒNG TRÒN FOV (DẠNG GUI - LUÔN HIỆN)
-- ============================================
local FOVGui = Instance.new("ScreenGui")
FOVGui.Name = "AimbotFOV"
FOVGui.Parent = game:GetService("CoreGui")
FOVGui.ResetOnSpawn = false
FOVGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local FOVFrame = Instance.new("Frame")
FOVFrame.Size = UDim2.new(0, FOV * 2, 0, FOV * 2)
FOVFrame.Position = UDim2.new(0.5, -FOV, 0.5, -FOV)
FOVFrame.BackgroundTransparency = 1
FOVFrame.BorderSizePixel = 0
FOVFrame.Parent = FOVGui

-- Vòng tròn chính
local Circle = Instance.new("ImageLabel")
Circle.Size = UDim2.new(1, 0, 1, 0)
Circle.BackgroundTransparency = 1
Circle.Image = "rbxassetid://266543268" -- Circle image
Circle.ImageColor3 = Color3.fromRGB(255, 255, 255)
Circle.ImageTransparency = 0.7
Circle.Parent = FOVFrame

-- Chấm tâm
local Dot = Instance.new("Frame")
Dot.Size = UDim2.new(0, 8, 0, 8)
Dot.Position = UDim2.new(0.5, -4, 0.5, -4)
Dot.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
Dot.BorderSizePixel = 0
Dot.Parent = FOVFrame
Instance.new("UICorner", Dot).CornerRadius = UDim.new(0, 4)

-- Crosshair lines
local function CreateLine(rotation)
    local line = Instance.new("Frame")
    line.Size = UDim2.new(0, 20, 0, 1)
    line.Position = UDim2.new(0.5, -10, 0.5, 0)
    line.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
    line.BorderSizePixel = 0
    line.Rotation = rotation
    line.Parent = FOVFrame
    return line
end

CreateLine(0)
CreateLine(90)
CreateLine(180)
CreateLine(270)

-- ============================================
-- KIỂM TRA TƯỜNG (RAYCAST)
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
    
    if ray then
        -- Có vật cản
        return true
    end
    
    return false
end

-- ============================================
-- KIỂM TRA MỤC TIÊU TRONG FOV
-- ============================================
local function GetBestTarget()
    local character = LocalPlayer.Character
    if not character then return nil end
    
    local localHead = character:FindFirstChild("Head")
    if not localHead then return nil end
    
    local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    local closestTarget = nil
    local closestDistance = FOV -- Chỉ nhận mục tiêu trong FOV
    
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
        
        local targetPart
        if AimPart == "Head" then
            targetPart = targetChar:FindFirstChild("Head")
        else
            targetPart = targetChar:FindFirstChild("HumanoidRootPart")
        end
        
        if not targetPart then continue end
        
        -- Kiểm tra vị trí trên màn hình
        local screenPos, onScreen = Camera:WorldToScreenPoint(targetPart.Position)
        
        if onScreen then
            local distFromCenter = (Vector2.new(screenPos.X, screenPos.Y) - screenCenter).Magnitude
            
            if distFromCenter < closestDistance then
                -- Wall check
                if VisibleCheck and IsWallBetween(targetPart.Position) then
                    continue
                end
                
                closestDistance = distFromCenter
                closestTarget = targetPart
            end
        end
    end
    
    return closestTarget
end

-- ============================================
-- AIMBOT LOOP
-- ============================================
local currentTarget = nil

RunService.RenderStepped:Connect(function(deltaTime)
    -- Tìm mục tiêu mới
    local target = GetBestTarget()
    
    if target then
        currentTarget = target
        
        -- Đổi màu vòng tròn thành đỏ khi có mục tiêu
        Circle.ImageColor3 = Color3.fromRGB(255, 50, 50)
        Circle.ImageTransparency = 0.5
        
        -- Tính toán vị trí aim
        local targetPos = target.Position
        local cameraPos = Camera.CFrame.Position
        
        -- Tạo CFrame mới nhìn vào mục tiêu
        local lookAt = CFrame.new(cameraPos, targetPos)
        
        -- Lerp mượt
        local smoothFactor = math.min(1, Smoothness / (deltaTime * 60))
        Camera.CFrame = Camera.CFrame:Lerp(lookAt, smoothFactor)
        
    else
        -- Không có mục tiêu, reset màu
        currentTarget = nil
        Circle.ImageColor3 = Color3.fromRGB(255, 255, 255)
        Circle.ImageTransparency = 0.7
    end
end)

-- ============================================
-- KIỂM TRA MỤC TIÊU CHẾT
-- ============================================
coroutine.wrap(function()
    while task.wait(0.5) do
        if currentTarget then
            local parent = currentTarget.Parent
            if not parent then
                currentTarget = nil
            else
                local humanoid = parent:FindFirstChild("Humanoid")
                if not humanoid or humanoid.Health <= 0 then
                    currentTarget = nil
                end
            end
        end
    end
end)()

-- ============================================
-- KHỞI TẠO
-- ============================================
print("=================================")
print("🎯 PRO AIMBOT ACTIVATED!")
print("✅ FOV Circle: " .. FOV .. "px")
print("✅ Aim Part: " .. AimPart)
print("✅ Wall Check: " .. tostring(VisibleCheck))
print("✅ Team Check: " .. tostring(TeamCheck))
print("=================================")