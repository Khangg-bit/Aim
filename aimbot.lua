--[[
    PRO AIMBOT V4 - Camera di chuyển theo đầu địch khi trong vòng tròn
    Delta Executor - Hoạt động chính xác
--]]

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local UserInputService = game:GetService("UserInputService")

-- Settings
local FOV = 120 -- Kích thước vòng tròn (pixel)
local Smoothness = 0.08 -- Độ mượt (0-1, càng thấp càng nhanh)
local AimPart = "Head" -- Head hoặc HumanoidRootPart
local VisibleCheck = true -- Kiểm tra tường
local TeamCheck = true -- Không aim đồng đội

-- ============================================
-- TẠO VÒNG TRÒN FOV GIỮA MÀN HÌNH
-- ============================================
local FOVGui = Instance.new("ScreenGui")
FOVGui.Name = "AimbotFOV"
FOVGui.Parent = game:GetService("CoreGui")
FOVGui.ResetOnSpawn = false
FOVGui.IgnoreGuiInset = true
FOVGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local Circle = Instance.new("Frame")
Circle.Size = UDim2.new(0, FOV * 2, 0, FOV * 2)
Circle.Position = UDim2.new(0.5, -FOV, 0.5, -FOV)
Circle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Circle.BackgroundTransparency = 0.85
Circle.BorderSizePixel = 0
Circle.Parent = FOVGui

local CircleCorner = Instance.new("UICorner")
CircleCorner.CornerRadius = UDim.new(1, 0)
CircleCorner.Parent = Circle

local Stroke = Instance.new("UIStroke")
Stroke.Thickness = 2
Stroke.Color = Color3.fromRGB(255, 255, 255)
Stroke.Transparency = 0.4
Stroke.Parent = Circle

-- ============================================
-- KIỂM TRA TƯỜNG BẰNG RAYCAST
-- ============================================
local function IsWallBetween(targetPos)
    local char = LocalPlayer.Character
    if not char then return true end
    
    local head = char:FindFirstChild("Head")
    if not head then return true end
    
    local rayParams = RaycastParams.new()
    rayParams.FilterDescendantsInstances = {char}
    rayParams.FilterType = Enum.RaycastFilterType.Blacklist
    
    local dir = (targetPos - head.Position).Unit
    local dist = (targetPos - head.Position).Magnitude
    
    local ray = Workspace:Raycast(head.Position, dir * dist, rayParams)
    
    if ray then
        local hitParent = ray.Instance
        -- Kiểm tra xem ray có trúng chính target character không
        local targetChar = nil
        for _, player in pairs(Players:GetPlayers()) do
            if player.Character and ray.Instance:IsDescendantOf(player.Character) then
                targetChar = player.Character
                break
            end
        end
        if targetChar then
            return false -- Trúng người chơi, không phải tường
        end
        return true -- Trúng tường
    end
    
    return false -- Không trúng gì
end

-- ============================================
-- TÌM ĐẦU ĐỊCH GẦN TÂM NHẤT TRONG FOV
-- ============================================
local function GetTargetInFOV()
    local char = LocalPlayer.Character
    if not char then return nil end
    
    local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    local bestTarget = nil
    local bestDist = FOV + 1

    for _, player in pairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        
        local targetChar = player.Character
        if not targetChar then continue end
        
        local humanoid = targetChar:FindFirstChild("Humanoid")
        if not humanoid or humanoid.Health <= 0 then continue end
        
        -- Team check
        if TeamCheck and LocalPlayer.Team and player.Team == LocalPlayer.Team then
            continue
        end
        
        -- Lấy phần cần aim
        local targetPart
        if AimPart == "Head" then
            targetPart = targetChar:FindFirstChild("Head")
        else
            targetPart = targetChar:FindFirstChild("HumanoidRootPart")
        end
        
        if not targetPart then continue end
        
        -- Lấy vị trí 2D trên màn hình
        local screenPos, onScreen = Camera:WorldToScreenPoint(targetPart.Position)
        
        if onScreen then
            local distFromCenter = (Vector2.new(screenPos.X, screenPos.Y) - screenCenter).Magnitude
            
            -- Trong vòng tròn FOV?
            if distFromCenter <= FOV then
                -- Wall check
                if VisibleCheck and IsWallBetween(targetPart.Position) then
                    continue
                end
                
                -- Chọn mục tiêu gần tâm nhất
                if distFromCenter < bestDist then
                    bestDist = distFromCenter
                    bestTarget = targetPart
                end
            end
        end
    end
    
    return bestTarget
end

-- ============================================
-- AIMBOT LOOP - DI CHUYỂN CAMERA THEO ĐẦU
-- ============================================
local CurrentTarget = nil

RunService.RenderStepped:Connect(function(deltaTime)
    local target = GetTargetInFOV()
    
    if target then
        CurrentTarget = target
        
        -- Đổi màu vòng tròn -> ĐỎ
        Stroke.Color = Color3.fromRGB(255, 30, 30)
        Stroke.Transparency = 0.2
        Circle.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
        Circle.BackgroundTransparency = 0.75
        
        -- TÍNH TOÁN CAMERA DI CHUYỂN THEO ĐẦU
        local cameraPos = Camera.CFrame.Position
        local targetPos = target.Position
        
        -- Tạo CFrame mới: vị trí camera giữ nguyên, hướng nhìn vào đầu
        local newLookVector = (targetPos - cameraPos).Unit
        local newCFrame = CFrame.new(cameraPos, cameraPos + newLookVector)
        
        -- Lerp mượt
        Camera.CFrame = Camera.CFrame:Lerp(newCFrame, Smoothness)
        
    else
        CurrentTarget = nil
        
        -- Reset màu trắng
        Stroke.Color = Color3.fromRGB(255, 255, 255)
        Stroke.Transparency = 0.4
        Circle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        Circle.BackgroundTransparency = 0.85
    end
end)

-- ============================================
-- THẢ MỤC TIÊU KHI CHẾT
-- ============================================
coroutine.wrap(function()
    while task.wait(0.3) do
        if CurrentTarget then
            local parent = CurrentTarget.Parent
            if not parent then
                CurrentTarget = nil
            else
                local hum = parent:FindFirstChild("Humanoid")
                if not hum or hum.Health <= 0 then
                    CurrentTarget = nil
                end
            end
        end
    end
end)()

-- ============================================
-- THÔNG BÁO
-- ============================================
print("=================================")
print("🎯 AIMBOT V4 ACTIVATED!")
print("✅ Vòng tròn: " .. FOV .. "px")
print("✅ Aim: " .. AimPart)
print("✅ Wall Check: " .. tostring(VisibleCheck))
print("✅ Team Check: " .. tostring(TeamCheck))
print("✅ Camera di chuyển theo đầu địch")
print("=================================")