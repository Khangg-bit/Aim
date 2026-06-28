--[[
    CLEAN AIMBOT - No GUI, FOV Circle Only
    Delta Executor Compatible
--]]

-- ============================================
-- SETTINGS - EDIT HERE
-- ============================================
local ENABLED = true                    -- true = on, false = off
local AIM_KEY = Enum.KeyCode.Q         -- nil = always on
local AIM_PART = "Head"                -- "Head" or "HumanoidRootPart"
local SMOOTHNESS = 0.06                -- 0.01 (snappy) - 1 (smooth)
local FOV_SIZE = 130                   -- circle radius in pixels
local FOV_COLOR = Color3.fromRGB(255, 255, 255)
local FOV_LOCKED_COLOR = Color3.fromRGB(255, 50, 50)
local FOV_ALPHA = 0.6
local WALL_CHECK = true
local TEAM_CHECK = true
local ALIVE_CHECK = true

-- ============================================
-- SERVICES
-- ============================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- ============================================
-- FOV CIRCLE (NO GUI BUTTONS)
-- ============================================
local Gui = Instance.new("ScreenGui")
Gui.Parent = game:GetService("CoreGui")
Gui.ResetOnSpawn = false
Gui.IgnoreGuiInset = true
Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local Circle = Instance.new("Frame")
Circle.Size = UDim2.new(0, FOV_SIZE * 2, 0, FOV_SIZE * 2)
Circle.Position = UDim2.new(0.5, -FOV_SIZE, 0.5, -FOV_SIZE)
Circle.BackgroundColor3 = FOV_COLOR
Circle.BackgroundTransparency = 0.9
Circle.BorderSizePixel = 0
Circle.Parent = Gui
Instance.new("UICorner", Circle).CornerRadius = UDim.new(1, 0)

local Stroke = Instance.new("UIStroke")
Stroke.Thickness = 2
Stroke.Color = FOV_COLOR
Stroke.Transparency = FOV_ALPHA
Stroke.Parent = Circle

-- ============================================
-- HELPERS
-- ============================================
local function wallCheck(targetPos)
    if not WALL_CHECK then return false end
    local char = LocalPlayer.Character
    if not char then return true end
    local head = char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
    if not head then return true end

    local rayParams = RaycastParams.new()
    rayParams.FilterDescendantsInstances = {char}
    rayParams.FilterType = Enum.RaycastFilterType.Blacklist
    local dir = (targetPos - head.Position).Unit
    local dist = (targetPos - head.Position).Magnitude
    local ray = Workspace:Raycast(head.Position, dir * dist, rayParams)

    if ray then
        for _, plr in pairs(Players:GetPlayers()) do
            if plr.Character and ray.Instance:IsDescendantOf(plr.Character) then
                return false
            end
        end
        return true
    end
    return false
end

local function isAlive(part)
    if not ALIVE_CHECK then return true end
    if not part or not part.Parent then return false end
    local hum = part.Parent:FindFirstChild("Humanoid")
    return hum and hum.Health > 0
end

local function getTarget()
    local char = LocalPlayer.Character
    if not char then return nil end
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    local best, bestDist = nil, FOV_SIZE + 1

    for _, plr in pairs(Players:GetPlayers()) do
        if plr == LocalPlayer then continue end
        local targetChar = plr.Character
        if not targetChar then continue end
        if TEAM_CHECK and LocalPlayer.Team and plr.Team == LocalPlayer.Team then continue end
        local part = targetChar:FindFirstChild(AIM_PART)
        if not part then continue end
        if not isAlive(part) then continue end

        local sp, onScreen = Camera:WorldToScreenPoint(part.Position)
        if not onScreen then continue end
        local dist = (Vector2.new(sp.X, sp.Y) - center).Magnitude
        if dist > FOV_SIZE then continue end
        if wallCheck(part.Position) then continue end

        if dist < bestDist then
            bestDist = dist
            best = part
        end
    end
    return best
end

-- ============================================
-- AIMBOT LOOP
-- ============================================
local target = nil

RunService.RenderStepped:Connect(function()
    if not ENABLED then
        Stroke.Color = FOV_COLOR
        Stroke.Transparency = FOV_ALPHA
        Circle.BackgroundColor3 = FOV_COLOR
        Circle.BackgroundTransparency = 0.9
        target = nil
        return
    end

    local aiming = (AIM_KEY and UserInputService:IsKeyDown(AIM_KEY)) or (not AIM_KEY)
    if not aiming then
        Stroke.Color = FOV_COLOR
        Stroke.Transparency = FOV_ALPHA
        Circle.BackgroundColor3 = FOV_COLOR
        Circle.BackgroundTransparency = 0.9
        target = nil
        return
    end

    target = getTarget()

    if target and isAlive(target) then
        Stroke.Color = FOV_LOCKED_COLOR
        Stroke.Transparency = 0.2
        Circle.BackgroundColor3 = FOV_LOCKED_COLOR
        Circle.BackgroundTransparency = 0.85

        local camPos = Camera.CFrame.Position
        local dir = (target.Position - camPos).Unit
        local goal = CFrame.new(camPos, camPos + dir)
        Camera.CFrame = Camera.CFrame:Lerp(goal, SMOOTHNESS)
    else
        Stroke.Color = FOV_COLOR
        Stroke.Transparency = FOV_ALPHA
        Circle.BackgroundColor3 = FOV_COLOR
        Circle.BackgroundTransparency = 0.9
        target = nil
    end
end)

-- ============================================
-- CLEANUP ON RESPAWN
-- ============================================
LocalPlayer.CharacterAdded:Connect(function()
    target = nil
end)

print("Aimbot Ready | FOV: " .. FOV_SIZE .. "px | Key: " .. (AIM_KEY and tostring(AIM_KEY) or "Always"))