if not game:IsLoaded() then
    game.Loaded:Wait()
end

task.wait(1)

local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Beamxz123/ui-roblox/main/WindLoader.lua"))()

local Window = WindUI:CreateWindow({
    Title = "Blox Spin",
    Icon = "book-image",
    Author = "By AU",
    Folder = "Blox Spin",
    Size = UDim2.fromOffset(500, 400),
    Transparent = true,
    Theme = "Dark",
    SideBarWidth = 160,
    HasOutline = false,
})

local Tabs = {
    Main = Window:Tab({ Title = "Auto Walk", Icon = "credit-card", Desc = "Auto Walk" }),
}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PathfindingService = game:GetService("PathfindingService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Net = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Core"):WaitForChild("Net"))
local UI = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Core"):WaitForChild("UI"))
local isAutoWalkActive = false
local PoliceTarget = Vector3.new(-598, 258, -169)

local ModulesFolder = ReplicatedStorage:WaitForChild("Modules")
local GameFolder = ModulesFolder:WaitForChild("Game")
local Modules = {
    ["Sprint"] = require(GameFolder.Sprint)
}

local old = Modules["Sprint"].consume_stamina
Modules["Sprint"].consume_stamina = function(...)
    return true
end

RunService.RenderStepped:Connect(function()
    if isAutoWalkActive then
        Modules["Sprint"].sprinting.set(true)
    end
end)

local function findPath(startPos, endPos)
    local path = PathfindingService:CreatePath({
        AgentRadius = 3,
        AgentHeight = 5,
        AgentCanJump = true,
        AgentJumpHeight = 30,
        AgentMaxSlope = 60,
        WaypointSpacing = 2
    })
    path:ComputeAsync(startPos, endPos)
    if path.Status == Enum.PathStatus.Success then
        return path:GetWaypoints()
    else
        return nil
    end
end

local function walkPath(path)
    local Character = LocalPlayer.Character
    if not Character then return end
    local Humanoid = Character:FindFirstChild("Humanoid")
    local HRP = Character:FindFirstChild("HumanoidRootPart")
    if not Humanoid or not HRP then return end
    if not path or #path == 0 then return end

    for i, waypoint in ipairs(path) do
        if not isAutoWalkActive then
            if Humanoid and HRP then
                Humanoid:MoveTo(HRP.Position)
            end
            return
        end

        Humanoid.WalkSpeed = 24
        Humanoid:MoveTo(waypoint.Position)

        if waypoint.Action == Enum.PathWaypointAction.Jump then
            Humanoid.AutoJumpEnabled = false
            Humanoid.UseJumpPower = true
            Humanoid.JumpPower = 40
            Humanoid.PlatformStand = false
            Humanoid.Jump = true
        end

        local startPos = HRP.Position
        local lastDistance = (startPos - waypoint.Position).Magnitude
        local stuckTime = tick()
        local jumped = false

        while true do
            if not isAutoWalkActive then
                if Humanoid and HRP then
                    Humanoid:MoveTo(HRP.Position)
                end
                return
            end

            local currentDistance = (HRP.Position - waypoint.Position).Magnitude
            if currentDistance < 5 then
                break
            end

            Humanoid.WalkSpeed = 24

            if not Humanoid or Humanoid.Health <= 0 or not HRP or not HRP.Parent then
                return
            end

            if tick() - stuckTime > 1.5 and not jumped then
                Humanoid.AutoJumpEnabled = false
                Humanoid.UseJumpPower = true
                Humanoid.JumpPower = 40
                Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                Humanoid.Jump = true
                jumped = true
            end

            if tick() - stuckTime > 3 and math.abs(lastDistance - currentDistance) < 0.5 then
                return
            end

            lastDistance = currentDistance
            task.wait(0.1)
        end

        if not Humanoid or Humanoid.Health <= 0 or not HRP or not HRP.Parent then
            return
        end
    end
end

local function drawPath(path)
    local Character = LocalPlayer.Character
    if not Character or not path then return {} end
    local HRP = Character:WaitForChild("HumanoidRootPart")
    local markers = {}

    for _, waypoint in ipairs(path) do
        local marker = Instance.new("Part")
        marker.Size = Vector3.new(0.5, 0.5, 0.5)
        marker.Color = Color3.fromRGB(255, 0, 255)
        marker.Material = Enum.Material.Neon
        marker.Anchored = true
        marker.CanCollide = false
        marker.CFrame = CFrame.new(waypoint.Position + Vector3.new(0, 1, 0))
        marker.Parent = workspace
        table.insert(markers, marker)

        task.spawn(function()
            local markerPart = marker
            local currentCharacter = LocalPlayer.Character
            local currentHRP = currentCharacter and currentCharacter:FindFirstChild("HumanoidRootPart")
            if not markerPart or not markerPart.Parent then return end

            while markerPart and markerPart.Parent and currentHRP and currentHRP.Parent do
                if (currentHRP.Position - markerPart.Position).Magnitude < 6 then 
                    task.wait(0.1)
                    if markerPart and markerPart.Parent then
                        markerPart:Destroy()
                    end
                    break
                end
                task.wait(0.2)
                currentCharacter = LocalPlayer.Character
                currentHRP = currentCharacter and currentCharacter:FindFirstChild("HumanoidRootPart")
                if not currentHRP then break end
            end
        end)
    end
    return markers
end

local function blockUnassignedTilesFences()
    local root = workspace.Map.Tiles:FindFirstChild("UnassignedTile")
    if not root then return end
    for _, child in ipairs(root:GetChildren()) do
        for _, obj in ipairs(child:GetDescendants()) do
            if obj:IsA("BasePart") and obj.Name == "Part" and obj.Size.Z > 5 then
                local mod = Instance.new("PathfindingModifier")
                mod.Label = "Blocked"
                mod.Parent = obj
            end
        end
    end
end

local function destroyAllDoorSystems()
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") or obj:IsA("Folder") then
            if obj.Name == "DoorSystem" then
                obj:Destroy()
            end
        end
    end
end

local function cleanupMarkers(markerList)
    if markerList then
        for _, marker in ipairs(markerList) do
            if marker and marker.Parent then
                marker:Destroy()
            end
        end
    end
end

local function autoDepositAllMoney()
    local Money = UI.get("HandBalanceLabel", true)
    if not Money or not Money.ContentText or Money.ContentText == "" then return end
    local raw = Money.ContentText
    raw = raw:gsub("[^%d%.%-%,]", "")
    raw = raw:gsub(",", "")
    if raw == "" then return end
    local current = tonumber(raw) or 0
    if current > 0 then
        Net.get("transfer_funds", "hand", "bank", current)
        task.wait(1)
    end
end

local function ExecuteAutoWalkCycle()
    if not isAutoWalkActive then
        if LocalPlayer.Character then
            local hum = LocalPlayer.Character:FindFirstChild("Humanoid")
            if hum then
                hum:MoveTo(LocalPlayer.Character:GetPrimaryPartCFrame().Position)
            end
        end
        return
    end

    local Character = LocalPlayer.Character
    if not Character then return end
    local Humanoid = Character:FindFirstChild("Humanoid")
    local HRP = Character:FindFirstChild("HumanoidRootPart")
    if not Humanoid or not HRP or Humanoid.Health <= 0 then return end

    local startPos = HRP.Position
    local pathToTarget = findPath(startPos, PoliceTarget)
    local drawnMarkers = {}

    if pathToTarget and #pathToTarget > 0 then
        drawnMarkers = drawPath(pathToTarget)
        walkPath(pathToTarget)
        cleanupMarkers(drawnMarkers)
        if isAutoWalkActive then
            autoDepositAllMoney()
        end
    else
        cleanupMarkers(drawnMarkers)
    end
end

LocalPlayer.CharacterAdded:Connect(function(Character)
    task.spawn(function()
        local Humanoid = Character:WaitForChild("Humanoid", 10) 
        local HRP = Character:WaitForChild("HumanoidRootPart", 10) 
        if Humanoid and HRP and Humanoid.Health > 0 then
            task.wait(0.5)
            if isAutoWalkActive then
                task.spawn(ExecuteAutoWalkCycle)
            end
        end
    end)
end)

blockUnassignedTilesFences()
destroyAllDoorSystems()

Tabs.Main:Section({ Title = "เดิน+ถอนเงิน" })

Tabs.Main:Toggle({
    Title = "🚓 เดินไปสถานีตำรวจ",
    Description = "เดินตามเส้นที่กำหนดไว้",
    Value = false,
    Callback = function(state)
        if state then
            isAutoWalkActive = true
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character:FindFirstChild("Humanoid").Health > 0 then
                task.spawn(ExecuteAutoWalkCycle)
            end
        else
            isAutoWalkActive = false
            if LocalPlayer.Character then
                local hum = LocalPlayer.Character:FindFirstChild("Humanoid")
                if hum then
                    hum:MoveTo(LocalPlayer.Character:GetPrimaryPartCFrame().Position)
                end
            end
        end
    end
})

Tabs.Main:Section({ Title = "Balances" })
local HandBalanceText = Tabs.Main:Paragraph({ Title = "Hand: <font color='#00FF00'>Loading...</font>" })
local BankBalanceText = Tabs.Main:Paragraph({ Title = "Bank: <font color='#00FF00'>Loading...</font>" })

local function formatCurrency(amount)
    local cleanNumber = amount:gsub("%D", "")
    return cleanNumber:reverse():gsub("%d%d%d", "%1,"):reverse():gsub("^,", "")
end

task.spawn(function()
    local UI_upvr = require(game:GetService("ReplicatedStorage").Modules.Core.UI)
    local Money = UI_upvr.get("HandBalanceLabel", true)
    local BankMoney = UI_upvr.get("BankBalanceLabel", true)

    repeat task.wait() until Money and Money.ContentText and Money.ContentText ~= ""
    repeat task.wait() until BankMoney and BankMoney.ContentText and BankMoney.ContentText ~= ""

    HandBalanceText:SetTitle("Hand: <font color='#00FF00'>"..formatCurrency(Money.ContentText).."</font>")
    BankBalanceText:SetTitle("Bank: <font color='#00FF00'>"..formatCurrency(BankMoney.ContentText).."</font>")

    Money:GetPropertyChangedSignal("Text"):Connect(function()
        HandBalanceText:SetTitle("Hand: <font color='#00FF00'>"..formatCurrency(Money.ContentText).."</font>")
    end)

    BankMoney:GetPropertyChangedSignal("Text"):Connect(function()
        BankBalanceText:SetTitle("Bank: <font color='#00FF00'>"..formatCurrency(BankMoney.ContentText).."</font>")
    end)
end)

Tabs.Main:Section({ Title = "Transaction" })
getgenv().BankValue = 100

Tabs.Main:Input({
    Title = "Amount",
    PlaceholderText = "Enter amount",
    Callback = function(value)
        getgenv().BankValue = tonumber(value)
    end
})

Tabs.Main:Button({
    Title = "🏧 Withdraw ตามจำนวนที่ใส่",
    Desc = "Must be near bank",
    Callback = function()
        local Net = require(game.ReplicatedStorage.Modules.Core.Net)
        Net.get("transfer_funds", "bank", "hand", getgenv().BankValue or 0)
    end
})

Tabs.Main:Button({
    Title = "🏧 Withdraw ถอนเงิน 140000",
    Desc = "Must be near bank",
    Callback = function()
        local Net = require(game.ReplicatedStorage.Modules.Core.Net)
        Net.get("transfer_funds", "bank", "hand", 140000)
    end
})

WindUI:Notify({
    Title = "Auto Walk",
    Content = "พร้อมสำหรับใช้งาน", 
    Icon = "diamond-plus",
    Duration = 5,
    Background = "rbxassetid://13511292247"
})
