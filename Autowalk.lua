if not game:IsLoaded() then
    game.Loaded:Wait()
end

local GuiService = game:GetService("GuiService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local LocalPlayer = game:GetService("Players").LocalPlayer

local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

-- ฟังก์ชันกดปุ่ม
local function Click_Button(button)
    if button then
        GuiService.SelectedCoreObject = button
        task.wait(0.1)
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
        task.wait(0.1)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Return, false, game)
        task.wait(0.1)
        GuiService.SelectedCoreObject = nil
    end
end

-- ฟังก์ชันรอกดปุ่ม Play และ Skip
local function WaitForGameStart()
    -- รอกด Play
    if LocalPlayer.PlayerGui:FindFirstChild("SplashScreenGui") then
        repeat task.wait(1)
            pcall(function()
                local playButton = LocalPlayer.PlayerGui.SplashScreenGui.Frame:FindFirstChild("PlayButton")
                Click_Button(playButton)
            end)
        until not LocalPlayer.PlayerGui:FindFirstChild("SplashScreenGui")
        task.wait(1)
    end

    -- รอกด Skip
    local charCreator = LocalPlayer.PlayerGui:FindFirstChild("CharacterCreator")
    if charCreator and charCreator.Enabled then
        repeat task.wait(1)
            pcall(function()
                local skipButton = charCreator:FindFirstChild("MenuFrame") and charCreator.MenuFrame:FindFirstChild("AvatarMenuSkipButton")
                Click_Button(skipButton)
            end)
        until not charCreator.Enabled
        task.wait(3.5)
    end
end

-- หันกล้องไปทางตำแหน่งเป้าหมาย
local function lookAtPosition(targetPosition)
    local camera = workspace.CurrentCamera
    local player = game:GetService("Players").LocalPlayer
    local character = player.Character or player.CharacterAdded:Wait()
    local hrp = character:WaitForChild("HumanoidRootPart")

    camera.CameraType = Enum.CameraType.Scriptable
    local camPosition = hrp.Position + Vector3.new(0, 2, 0) -- กล้องสูงกว่าหัวเล็กน้อย
    local direction = (targetPosition - camPosition).Unit
    camera.CFrame = CFrame.new(camPosition, camPosition + direction)
    task.wait(0.1)
    camera.CameraType = Enum.CameraType.Custom
end

local function pressConfirmButton_Universal()
    for i,v in pairs(game:GetService("Players").LocalPlayer.PlayerGui:GetChildren()) do
        for i2,v2 in pairs(v:GetChildren()) do
            for i3,v3 in pairs(v2:GetChildren()) do
                if v3:FindFirstChild("Title") and v3:FindFirstChild("Options") and v3:FindFirstChild("Folder") then
                    for i4,v4 in pairs(v3:GetChildren()) do
                        if v4.Name == "Options" then
                            for i5,v5 in pairs(v4:GetChildren()) do
                                if v5.ClassName == "TextButton" and v5:FindFirstChild("IconPadder") then
                                    local close = v5
                                    game:GetService("GuiService").SelectedObject = close
                                    if game:GetService("GuiService").SelectedObject == close then
                                        local VirtualInputManager = game:GetService("VirtualInputManager")
                                        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
                                        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Return, false, game)
                                        task.wait(0.5)
                                        game:GetService("GuiService").SelectedObject = nil
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end

-- เรียกใช้งานการรอ UI เกมก่อนแสดง WindUI
WaitForGameStart()

-- โหลดและแสดง WindUI
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
    Main = Window:Tab({ Title = "Main", Icon = "credit-card", Desc = "Auto Walk" }),
    Secondary = Window:Tab({ Title = "Secondary", Icon = "credit-card", Desc = "Auto Walk" }),
}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PathfindingService = game:GetService("PathfindingService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer
local Net = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Core"):WaitForChild("Net"))
local UI = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Core"):WaitForChild("UI"))
local VirtualInputManager = game:GetService("VirtualInputManager")
local isAutoWalkActive = false
local lockedPosition = Vector3.new(-565, 256, 168)
local TARGET_POINTS = {
    FIRST_TARGET = Vector3.new(-451, 254, 28),
    SECOND_TARGET = Vector3.new(-536, 254, 52),
    THIRD_TARGET = Vector3.new(-541, 256, 139),
    FOURTH_TARGET = Vector3.new(-512, 256, 165)
}

local currentTargetIndex = 1

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

local function updateStatus(message)
    print(message)
end

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

        Humanoid:MoveTo(waypoint.Position)

        if waypoint.Action == Enum.PathWaypointAction.Jump then
            Humanoid.AutoJumpEnabled = false
            Humanoid.UseJumpPower = true
            Humanoid.JumpPower = 30
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
            if currentDistance < 5 then -- Reached the current waypoint
                break
            end

            Humanoid.WalkSpeed = 29

            if not Humanoid or Humanoid.Health <= 0 or not HRP or not HRP.Parent then
                return
            end

            if tick() - stuckTime > 1.5 and not jumped then
                Humanoid.AutoJumpEnabled = false
                Humanoid.UseJumpPower = true
                Humanoid.JumpPower = 30
                Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                Humanoid.Jump = true
                jumped = true
            end

            -- Check if stuck
            if tick() - stuckTime > 1.5 and math.abs(lastDistance - currentDistance) < 0.5 then
                 warn("Player appears stuck, attempting to continue or recalculate path.")
                 break -- Break the inner while loop, the outer for loop will move to the next waypoint or finish
            end

            lastDistance = currentDistance
            task.wait(0.1)
        end

        if not Humanoid or Humanoid.Health <= 0 or not HRP or not HRP.Parent then
            return
        end
    end
end

local function TweenTo(pos)
    updateStatus("กำลังเดินไปตำแหน่ง: " .. tostring(pos))
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local hrp = char:WaitForChild("HumanoidRootPart")
    local dist = (hrp.Position - pos).Magnitude
    local tween = TweenService:Create(hrp, TweenInfo.new(dist / 18, Enum.EasingStyle.Linear), {CFrame = CFrame.new(pos)})
    tween:Play()
    
    -- เช็คว่ายังทำงานอยู่หรือไม่
    while tween.PlaybackState ~= Enum.PlaybackState.Completed and isAutoWalkActive do
        RunService.Heartbeat:Wait()
    end
    
    -- หยุดการเคลื่อนที่ถ้าการทำงานถูกยกเลิก
    if not isAutoWalkActive and tween.PlaybackState ~= Enum.PlaybackState.Completed then
        tween:Cancel()
    end
    
    return tween.PlaybackState == Enum.PlaybackState.Completed
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

local props = workspace:WaitForChild("Map"):WaitForChild("Props")

local function configurePrompt(prompt)
    if prompt:IsA("ProximityPrompt") then
        prompt.MaxActivationDistance = 30
        prompt.RequiresLineOfSight = false
    end
end

-- ตั้งค่า ProximityPrompt ที่มีอยู่แล้ว
for _, item in ipairs(props:GetDescendants()) do
    configurePrompt(item)
end

-- ตั้งค่าสำหรับ ProximityPrompt ที่ถูกเพิ่มในอนาคต
props.DescendantAdded:Connect(configurePrompt)


-- Function to find and activate the ProximityPrompt near the target
local function activatePromptNearTarget(targetPosition, maxDistance)
    local Character = LocalPlayer.Character
    if not Character then return end
    local HRP = Character:FindFirstChild("HumanoidRootPart")
    if not HRP then return end

    local prompts = workspace:GetDescendants()
    for _, obj in ipairs(prompts) do
        if obj:IsA("ProximityPrompt") and obj.Parent:IsA("BasePart") then
            local distanceToTarget = (obj.Parent.Position - targetPosition).Magnitude

            if distanceToTarget < maxDistance then
                local distanceToPlayer = (HRP.Position - obj.Parent.Position).Magnitude
                local maxActivation = obj.MaxActivationDistance + 1 or 10

                if distanceToPlayer <= maxActivation then
                    -- ปิด RequiresLineOfSight เพื่อให้ไม่ต้องเห็น
                    obj.RequiresLineOfSight = false

                    -- รอให้ Prompt ถูก Enabled ก่อน
                    local timeout = 3
                    local start = tick()
                    while not obj.Enabled and tick() - start < timeout do
                        task.wait(0.05)
                    end

                    -- รออีกนิดเพื่อให้ prompt ปรากฏจริง
                    task.wait(0.2)

                    print("Activating prompt:", obj.Name)
                    -- จำลองการกด E
                    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
                    task.wait(0.2)
                    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
                    
                    task.wait(0.5) -- รอผลลัพธ์
                    
                    -- ลองอีกครั้งเพื่อความแน่นอน
                    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
                    task.wait(0.2)
                    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)

                    return true
                end
            end
        end
    end

    warn("No suitable ProximityPrompt found or it's not ready.")
    return false
end


local function waitUntilATMReadyWithPrompt(maxDistance, timeout)
    local startTime = tick()
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end

    while tick() - startTime <= timeout do
        for _, atm in ipairs(workspace.Map.Props:GetChildren()) do
            if atm:IsA("Model") and atm.Name == "ATM" then
                local dist = (hrp.Position - atm:GetPivot().Position).Magnitude
                if dist <= maxDistance then
                    -- ตรวจว่าหน้าจอ ATM ฟื้นหรือยัง
                    local available = false
                    for _, part in ipairs(atm:GetChildren()) do
                        if part:IsA("BasePart") then
                            local screen = part:FindFirstChild("Screen")
                            if screen and screen:IsA("SurfaceGui") then
                                if screen.Enabled == false then
                                    available = true
                                    break
                                end
                            end
                        end
                    end

                    -- ถ้าใช้ได้แล้ว → หา Prompt
                    if available then
                        for _, d in ipairs(atm:GetDescendants()) do
                            if d:IsA("ProximityPrompt") and d.Enabled then
                                print("🟢 ATM พร้อมแล้ว และ Prompt โผล่ → กด E")
                                VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
                                task.wait(0.1)
                                VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
                                return true
                            end
                        end
                    else
                        print("⏳ ATM ยังถูก Hack อยู่...")
                    end
                end
            end
        end
        task.wait(0.5)
    end

    warn("❌ รอ ATM/Prompt ไม่สำเร็จในเวลา")
    return false
end

local function forceConfirmClick()
    for i,v in pairs(game:GetService("Players").LocalPlayer.PlayerGui:GetChildren()) do
        for i2,v2 in pairs(v:GetChildren()) do
            for i3,v3 in pairs(v2:GetChildren()) do
                if v3:FindFirstChild("Title") and v3:FindFirstChild("Options") and v3:FindFirstChild("Folder") then
                    for i4,v4 in pairs(v3:GetChildren()) do
                        if v4.Name == "Options" then
                            for i5,v5 in pairs(v4:GetChildren()) do
                                if v5.ClassName == "TextButton" and v5:FindFirstChild("IconPadder") then
                                    local close = v5
                                    game:GetService("GuiService").SelectedObject = close
                                    if game:GetService("GuiService").SelectedObject == close then
                                        local VirtualInputManager = game:GetService("VirtualInputManager")
                                        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
                                        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Return, false, game)
                                        task.wait(0.5)
                                        game:GetService("GuiService").SelectedObject = nil
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end


local function DepositAllMoney()
    local player = game:GetService("Players").LocalPlayer
    local playerGui = player:WaitForChild("PlayerGui")
    local GuiService = game:GetService("GuiService")
    local VirtualInputManager = game:GetService("VirtualInputManager")
    local UI_upvr = require(game:GetService("ReplicatedStorage").Modules.Core.UI)

    -- กดปุ่ม ATMDepositButton
    for _, gui in pairs(playerGui:GetChildren()) do
        for _, subGui in pairs(gui:GetChildren()) do
            for _, panel in pairs(subGui:GetChildren()) do
                if panel:FindFirstChild("Title") and panel:FindFirstChild("Options") and not panel:FindFirstChild("Folder") then
                    local options = panel:FindFirstChild("Options")
                    if options then
                        for _, button in pairs(options:GetChildren()) do
                            if button.Name == "ATMDepositButton" and subGui.Visible then
                                GuiService.SelectedObject = button
                                VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
                                VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Return, false, game)
                                task.wait(0.5)
                                GuiService.SelectedObject = nil
                            end
                        end
                    end
                end
            end
        end
    end

    task.wait(0.5)

    -- ใส่เงินทั้งหมดลง TextBox
    local moneyText = UI_upvr.get("HandBalanceLabel", true)
    repeat task.wait() until moneyText and moneyText.ContentText and moneyText.ContentText ~= ""
    local cleanAmount = moneyText.ContentText:gsub("%D", "")

    local foundTextBox = nil
    for _, g1 in ipairs(playerGui:GetChildren()) do
        for _, g2 in ipairs(g1:GetChildren()) do
            for _, g3 in ipairs(g2:GetChildren()) do
                local options = g3:FindFirstChild("Options")
                if options then
                    local frame = options:FindFirstChild("Frame")
                    if frame then
                        for _, obj in ipairs(frame:GetChildren()) do
                            if obj:IsA("TextBox") then
                                foundTextBox = obj
                                break
                            end
                        end
                    end
                end
                if foundTextBox then break end
            end
            if foundTextBox then break end
        end
        if foundTextBox then break end
    end

    if foundTextBox then
        foundTextBox:CaptureFocus()
        task.wait(0.1)
        foundTextBox.Text = cleanAmount
        foundTextBox:ReleaseFocus()
        task.wait(0.2)

        task.spawn(function() forceConfirmClick() end)
        task.spawn(function() task.wait(0.3) forceConfirmClick() end)
    end

    for _, g1 in pairs(playerGui:GetChildren()) do
        for _, g2 in pairs(g1:GetChildren()) do
            for _, g3 in pairs(g2:GetChildren()) do
                if g3:FindFirstChild("Title") and g3:FindFirstChild("Options") and g3:FindFirstChild("Folder") then
                    local options = g3:FindFirstChild("Options")
                    for _, btn in pairs(options:GetChildren()) do
                        if btn.ClassName == "TextButton" and btn:FindFirstChild("IconPadder") then
                            GuiService.SelectedObject = btn
                            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
                            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Return, false, game)
                            task.wait(0.3)
                            GuiService.SelectedObject = nil
                        end
                    end
                end
            end
        end
    end
end

-- ฟังก์ชันใหม่สำหรับเดินไปยังเป้าหมายทีละจุด
local function ExecuteWalkToTargets()
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

    -- เรียงลำดับจุดเป้าหมาย
    local targetPoints = {
        TARGET_POINTS.FIRST_TARGET,
        TARGET_POINTS.SECOND_TARGET,
        TARGET_POINTS.THIRD_TARGET,
        TARGET_POINTS.FOURTH_TARGET
    }
    
    local start = tick()
    
    -- วนลูปผ่านแต่ละจุดเป้าหมาย
    for i, targetPos in ipairs(targetPoints) do
        if not isAutoWalkActive then break end
        
        local startPos = HRP.Position
        updateStatus("กำลังเดินไปจุดที่ " .. i .. ": " .. tostring(targetPos))
        
        -- จุด 1-2 ใช้ walkPath, จุด 3-4 ใช้ Tween
        if i >= 3 then  -- จุดที่ 3 และ 4 ใช้ TweenTo
            print("ใช้ TweenTo ไปยังจุดที่ " .. i)
            local success = TweenTo(targetPos)
            if not success then break end
        else  -- จุดที่ 1 และ 2 ใช้ walkPath
            print("ใช้ walkPath ไปยังจุดที่ " .. i)
            local pathToTarget = findPath(startPos, targetPos)
            local drawnMarkers = {}
            
            if pathToTarget and #pathToTarget > 0 then
                drawnMarkers = drawPath(pathToTarget)
                walkPath(pathToTarget)
                cleanupMarkers(drawnMarkers)
            else
                cleanupMarkers(drawnMarkers)
                warn("Failed to find a path to target #" .. i)
                break
            end
        end
        
        -- ตรวจสอบว่าถึงจุดหมายหรือไม่
        if (HRP.Position - targetPos).Magnitude > 10 then
            warn("Failed to reach target #" .. i)
            break
        end
        
        -- พิจารณาทำงานเพิ่มเติมเมื่อถึงจุดสุดท้าย
        if i == #targetPoints and isAutoWalkActive then
            task.wait(0.5)
            print("Reached final target, attempting to activate prompt...")
            local promptActivated = waitUntilATMReadyWithPrompt(50, 60)
            
            if promptActivated then
                print("ProximityPrompt activated at final target.")
                
                if promptActivated then
                    print("ProximityPrompt activated at final target.")

                    -- เริ่ม ATMWithdraw + TextBox + CONFIRM
                    local player = game:GetService("Players").LocalPlayer
                    local playerGui = player:WaitForChild("PlayerGui")
                    local GuiService = game:GetService("GuiService")
                    local VirtualInputManager = game:GetService("VirtualInputManager")

                    for _, gui in pairs(playerGui:GetChildren()) do
                        for _, subGui in pairs(gui:GetChildren()) do
                            for _, panel in pairs(subGui:GetChildren()) do
                                if panel:FindFirstChild("Title") and panel:FindFirstChild("Options") and not panel:FindFirstChild("Folder") then
                                    local options = panel:FindFirstChild("Options")
                                    if options then
                                        for _, button in pairs(options:GetChildren()) do
                                            if button.Name == "ATMWithdrawButton" and subGui.Visible then
                                                GuiService.SelectedObject = button
                                                if GuiService.SelectedObject == button then
                                                    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
                                                    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Return, false, game)
                                                    task.wait(0.5)
                                                    GuiService.SelectedObject = nil
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end

                    local foundTextBox = nil
                    for _, g1 in ipairs(playerGui:GetChildren()) do
                        for _, g2 in ipairs(g1:GetChildren()) do
                            for _, g3 in ipairs(g2:GetChildren()) do
                                local options = g3:FindFirstChild("Options")
                                if options then
                                    local frame = options:FindFirstChild("Frame")
                                    if frame then
                                        for _, obj in ipairs(frame:GetChildren()) do
                                            if obj:IsA("TextBox") then
                                                foundTextBox = obj
                                                break
                                            end
                                        end
                                    end
                                end
                                if foundTextBox then break end
                            end
                            if foundTextBox then break end
                        end
                        if foundTextBox then break end
                    end

                    if foundTextBox then
                        foundTextBox:CaptureFocus()
                        task.wait(0.1)
                        foundTextBox.Text = "600000"
                        foundTextBox:ReleaseFocus()
                        task.wait(0.2)
                    end

                    task.spawn(function() pressConfirmButton_Universal() end)
                    task.spawn(function() task.wait(0.3) pressConfirmButton_Universal() end)

                    local nextPoint = Vector3.new(-565, 256, 168)
                    local success = TweenTo(nextPoint)
                    if success then
                        print("✅ ไปยังจุดใหม่เรียบร้อยแล้ว:", nextPoint)
                        lockedToPosition = true
                    else
                        warn("❌ ล้มเหลวในการไปยังจุดใหม่")
                    end 
                end
            end
        end
        
        -- รอเล็กน้อยก่อนไปจุดถัดไป
        task.wait(0.5)
    end
    
    print("Walk cycle completed in " .. (tick() - start) .. " seconds")
end

local function GetClosestATM()
    local Character = LocalPlayer.Character
    if not Character then return nil end
    local HRP = Character:FindFirstChild("HumanoidRootPart")
    if not HRP then return nil end

    local closestATM = nil
    local shortestDistance = math.huge

    for _, atm in ipairs(workspace.Map.Props:GetChildren()) do
        if atm:IsA("Model") and atm.Name == "ATM" then
            local dist = (HRP.Position - atm:GetPivot().Position).Magnitude

            -- เงื่อนไขว่าใช้ได้: ถ้า SurfaceGui ที่ชื่อ "Screen" ถูกปิด (Enabled = false)
            local usable = false
            for _, part in ipairs(atm:GetChildren()) do
                if part:IsA("BasePart") then
                    local screen = part:FindFirstChild("Screen")
                    if screen and screen:IsA("SurfaceGui") and screen.Enabled == false then
                        usable = true
                        break
                    end
                end
            end

            if usable and dist < shortestDistance then
                shortestDistance = dist
                closestATM = atm
            end
        end
    end

    return closestATM
end

local function pressConfirmButton()
    local playerGui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
    local GuiService = game:GetService("GuiService")
    local VirtualInputManager = game:GetService("VirtualInputManager")

    for _, g1 in pairs(playerGui:GetChildren()) do
        for _, g2 in pairs(g1:GetChildren()) do
            for _, g3 in pairs(g2:GetChildren()) do
                if g3:FindFirstChild("Title") and g3:FindFirstChild("Options") and g3:FindFirstChild("Folder") then
                    local options = g3:FindFirstChild("Options")
                    for _, btn in pairs(options:GetChildren()) do
                        if btn.ClassName == "TextButton" and btn:FindFirstChild("IconPadder") then
                            GuiService.SelectedObject = btn
                            if GuiService.SelectedObject == btn then
                                VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
                                VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Return, false, game)
                                task.wait(0.3)
                                GuiService.SelectedObject = nil
                            end
                        end
                    end
                end
            end
        end
    end
end

LocalPlayer.CharacterAdded:Connect(function(Character)
    autoDepositAfterDeath = true

    task.spawn(function()
        lockedToPosition = false

        local Humanoid = Character:WaitForChild("Humanoid", 10)
        local HRP = Character:WaitForChild("HumanoidRootPart", 10)
        if not Humanoid or not HRP or Humanoid.Health <= 0 then return end
        if not (isAutoWalkActive or autoDepositAfterDeath) then return end

        task.wait(1) -- รอโหลดตัวละคร

        -- 🏧 หา ATM ที่ใกล้ที่สุด
        local atm = GetClosestATM()
        if not atm then
            warn("❌ ไม่พบ ATM ใกล้ตัว")
            return
        end

        local pos = atm:GetPivot().Position

        -- 🛣 หาเส้นทางไป ATM
        local pathToATM = findPath(HRP.Position, pos)
        if not pathToATM or #pathToATM == 0 then
            warn("❌ หาเส้นทางไป ATM ไม่ได้")
            return
        end

        -- 🚶 เดินไปยัง ATM
        local markers = drawPath(pathToATM)
        walkPath(pathToATM)
        cleanupMarkers(markers)

        -- 🎯 หันกล้องไปที่ ATM ก่อนกด E
        lookAtPosition(pos)

        -- 🔘 พยายามกด Prompt
        local opened = activatePromptNearTarget(pos, 20)
        if not opened then
            warn("❌ Prompt ไม่ปรากฏ / กดไม่ติด")
            return
        end

        -- ⏳ รอ ATM พร้อมใช้งาน
        local ready = waitUntilATMReadyWithPrompt(20, 10)
        if not ready then
            warn("❌ ATM ยังไม่พร้อมหรือหมดเวลา")
            return
        end

        -- 💰 เริ่มฝากเงิน
        DepositAllMoney()

        -- ✅ กดปุ่ม Confirm สองรอบ
        task.spawn(function() task.wait(0.1) pressConfirmButton() end)
        task.spawn(function() task.wait(0.3) pressConfirmButton() end)

        -- 🎥 หันกล้องกลับ
        setCameraDirection(305.34764505661343)

        -- 🧭 เดินกลับไปจุดแรก (จุดที่ 1)
        local target1 = Vector3.new(-451, 254, 28)
        local backPath = findPath(HRP.Position, target1)
        if backPath and #backPath > 0 then
            local markers2 = drawPath(backPath)
            walkPath(backPath)
            cleanupMarkers(markers2)
        end

        -- ✅ ทุกอย่างเสร็จ → เริ่มเดินจุด 1-4 ต่อ
        autoDepositAfterDeath = false
        task.spawn(ExecuteWalkToTargets)
    end)
end)


blockUnassignedTilesFences()
destroyAllDoorSystems()

task.spawn(function()
    task.wait(5)
end)

local autoEquipFistsActive = false

local function checkAndEquipFists_Updated()
    local Character = LocalPlayer.Character
    local Backpack = LocalPlayer:FindFirstChild("Backpack")
    if not Character or not Backpack then return end

    local Humanoid = Character:FindFirstChild("Humanoid")
    if not Humanoid or Humanoid.Health <= 0 then return end

    local fistsInBackpack = Backpack:FindFirstChild("Fists")
    local fistsEquipped = Character:FindFirstChild("Fists")

    if fistsInBackpack and not fistsEquipped then
        print("🔎 พบ Fists ใน Backpack กำลังสลับใช้งาน...")
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.One, false, game)
        task.wait(0.05)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.One, false, game)
        task.wait(0.5)

        -- ตรวจสอบอีกทีหลังจากพยายามใส่
        local fistsStillInBackpack = Backpack:FindFirstChild("Fists")
        local fistsNowEquipped = Character:FindFirstChild("Fists")

        if not fistsStillInBackpack and fistsNowEquipped then
            print("✅ Equip สำเร็จ")
        else
            warn("⚠️ Equip Fists ล้มเหลว")
        end
    end
end

-- ลูปรันเมื่อเปิด toggle
task.spawn(function()
    while true do
        if autoEquipFistsActive then
            pcall(checkAndEquipFists_Updated)
        end
        task.wait(5)
    end
end)

local MainWalkActive = false

RunService.RenderStepped:Connect(function()
    if MainWalkActive then
        local sprintModule = require(game:GetService("ReplicatedStorage").Modules.Game.Sprint)
        sprintModule.sprinting.set(true)

        local Character = LocalPlayer.Character
        local Humanoid = Character and Character:FindFirstChild("Humanoid")
        if Humanoid then
            Humanoid.WalkSpeed = 29
            Humanoid:SetAttribute("TargetWalkSpeed", 29)
        end
    end
end)

RunService.RenderStepped:Connect(function()
    if lockedToPosition then
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then
            hrp.CFrame = CFrame.new(lockedPosition)
        end
    end
end)

Tabs.Main:Toggle({
    Title = "🚶 เดินจุด 1-4 (จุด 3-4 ใช้ Tween)",
    Description = "เดินเหมือน Secondary แต่ไม่มี ATM/Prompt และต่อยศัตรูถ้าอยู่ใกล้จุดสุดท้าย",
    Value = false,
    Callback = function(state)
        isAutoWalkActive = state
        MainWalkActive = state
        autoEquipFistsActive = state

        if state then
            task.spawn(function()
                local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
                local HRP = Character:WaitForChild("HumanoidRootPart")
                local Humanoid = Character:WaitForChild("Humanoid")

                local sprintModule = require(game:GetService("ReplicatedStorage").Modules.Game.Sprint)
                sprintModule.consume_stamina = function() return true end
                sprintModule.sprinting.set(true)

                local targetPoints = {
                    Vector3.new(-451, 254, 28),
                    Vector3.new(-536, 254, 52),
                    Vector3.new(-541, 256, 139),
                    Vector3.new(-568, 256, 172),
                }

                for i, targetPos in ipairs(targetPoints) do
                    if not isAutoWalkActive then break end
                    updateStatus("ไปจุดที่ " .. i)

                    if Humanoid then
                        Humanoid.WalkSpeed = 29
                        Humanoid:SetAttribute("TargetWalkSpeed", 29)
                    end

                    if i <= 2 then
                        local path = findPath(HRP.Position, targetPos)
                        local markers = drawPath(path)
                        walkPath(path)
                        cleanupMarkers(markers)
                    else
                        local success = TweenTo(targetPos)
                        if not success then break end
                    end

                    task.wait(0.5)

                    local function boostToolAttributes(tool)
                        local DESIRED_RANGE = 15
                        local DESIRED_CONE = 360

                        local attributes = tool:GetAttributes()
                        local isMelee = false

                        for key, value in pairs(attributes) do
                            if typeof(value) == "string" and value:lower() == "melee" then
                                isMelee = true
                                break
                            end
                        end

                        if not isMelee then
                            warn("❌ ไม่ใช่อาวุธ melee → ข้าม", tool.Name)
                            return
                        end

                        for key, value in pairs(attributes) do
                            if typeof(value) == "number" then
                                if value == 60 then
                                    tool:SetAttribute(key, DESIRED_CONE)
                                elseif value == 5 then
                                    tool:SetAttribute(key, DESIRED_RANGE)
                                end
                            end
                        end
                    end

                    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
                    for _, item in ipairs(char:GetChildren()) do
                        if item:IsA("Tool") then
                            pcall(function()
                                boostToolAttributes(item)
                            end)
                        end
                    end

                    if i == 4 then                        print("📍 ถึงจุดสุดท้าย → เริ่ม Aura Attack")

                        local anchorPos = targetPos
                        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                        if not hrp then return end

                        while isAutoWalkActive do
                            local closestEnemy = nil
                            local shortestDistance = 20

                            for _, player in ipairs(Players:GetPlayers()) do
                                if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                                    local dist = (player.Character.HumanoidRootPart.Position - hrp.Position).Magnitude
                                    if dist <= shortestDistance then
                                        closestEnemy = player
                                        shortestDistance = dist
                                    end
                                end
                            end

                            if closestEnemy then
                                print("🎯 ต่อยศัตรูในระยะ")
                                VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
                                VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
                            else
                                print("🔎 ไม่พบศัตรู → ลองเก็บเงินรอบตัว")
                                                            end

                            task.wait(0.1)
                        end

                        return
                    end
                end

                print("✅ เดินครบ 4 จุดแล้ว (ไม่มี ATM)")
            end)
        else
            MainWalkActive = false
            isAutoWalkActive = false
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChild("Humanoid")
            if hum then
                hum:MoveTo(char:GetPrimaryPartCFrame().Position)
                hum.WalkSpeed = 16
            end
        end
    end
})

Tabs.Secondary:Section({ Title = "เดิน" })

-- ไม่ต้องใช้ตัวเลือกวิธีการเดิน เพราะเราจะใช้ walkPath สำหรับจุด 1-2 และ Tween สำหรับจุด 3-4

SecondaryToggle = Tabs.Secondary:Toggle({
    Title = "🚓 เดินไปตามจุดที่กำหนด",
    Description = "จุด 1-2 ใช้ Walk Path, จุด 3-4 ใช้ Tween และกดลง E ที่จุดสุดท้าย",
    Value = false,
    Callback = function(state)
        local Players = game:GetService("Players")
        local player = Players.LocalPlayer
        local camera = workspace.CurrentCamera
        local UserInputService = game:GetService("UserInputService")
        
        -- ตัวแปรเก็บองศาที่ต้องการให้กล้องหัน
        local targetAngle = 305.34764505661343

        -- ฟังก์ชันสำหรับตั้งค่ามุมกล้องตามองศาที่กำหนด
        local function setCameraDirection(angleDegrees)
            local character = player.Character or player.CharacterAdded:Wait()
            local hrp = character:WaitForChild("HumanoidRootPart")
            
            -- แปลงองศาเป็นเรเดียน
            local angleRadians = math.rad(angleDegrees)
            
            -- สร้าง look vector จากมุมองศา
            local lookX = math.cos(angleRadians)
            local lookZ = -math.sin(angleRadians)
            local lookVector = Vector3.new(lookX, 0, lookZ)
            
            -- บันทึกค่า CameraType เดิม
            local originalCameraType = camera.CameraType
            
            -- ตั้งค่ากล้องชั่วคราว
            camera.CameraType = Enum.CameraType.Scriptable
            
            -- ตำแหน่งของกล้อง (อิงจากตัวละคร)
            local cameraPosition = hrp.Position + Vector3.new(0, 2, 0)
            
            -- สร้าง CFrame สำหรับมุมกล้อง
            local cameraCFrame = CFrame.new(cameraPosition, cameraPosition + lookVector)
            
            -- ตั้งค่ากล้อง
            camera.CFrame = cameraCFrame
            
            -- รอสักครู่แล้วคืนค่ากล้องเป็นแบบเดิม
            task.wait(0.1)
            camera.CameraType = originalCameraType
            
            return lookVector
        end

        -- ฟังก์ชันที่แสดงผลทิศทาง
        local function getCameraDirection()
            local lookVector = camera.CFrame.LookVector
            
            -- หาองศาทิศทางในแนวราบ (XY-plane) โดยใช้ arctangent2
            local angleRadians = math.atan2(-lookVector.Z, lookVector.X)
            local angleDegrees = math.deg(angleRadians)
            
            -- ปรับองศาให้อยู่ในช่วง 0–360 องศา
            if angleDegrees < 0 then
                angleDegrees = angleDegrees + 360
            end
            
            return angleDegrees
        end

        -- ฟังก์ชันแสดงทิศตามองศา
        local function displayDirection(angle)
            if angle >= 315 or angle < 45 then
                print("→ ตะวันออก")
            elseif angle >= 45 and angle < 135 then
                print("↑ เหนือ")
            elseif angle >= 135 and angle < 225 then
                print("← ตะวันตก")
            elseif angle >= 225 and angle < 315 then
                print("↓ ใต้")
            end
        end

        -- ตัวแปรเก็บการเชื่อมต่อเมื่อตัวละครเกิดใหม่
        local characterAddedConnection

        if state then
            -- เมื่อเปิด Toggle
            isAutoWalkActive = true
            
            -- เริ่มต้นทำงานการเดินไปตามจุด
            if player.Character and 
               player.Character:FindFirstChild("Humanoid") and 
               player.Character:FindFirstChild("HumanoidRootPart") and 
               player.Character:FindFirstChild("Humanoid").Health > 0 then
                task.spawn(ExecuteWalkToTargets)
            end

            -- ปรับความเร็วตัวละคร
            task.spawn(function()
                while isAutoWalkActive do
                    local character = player.Character
                    local humanoid = character and character:FindFirstChild("Humanoid")

                    if humanoid then
                        humanoid.WalkSpeed = 29
                        humanoid:SetAttribute("TargetWalkSpeed", 29)
                    end
                    task.wait(0.1)
                end
            end)

            -- ตั้งค่ากล้องครั้งแรก
            local lookVector = setCameraDirection(targetAngle)
            
            -- แสดงทิศทางปัจจุบัน
            local currentAngle = getCameraDirection()
            print("มุมกล้องปัจจุบัน:", currentAngle, "องศา")
            displayDirection(currentAngle)
            
            -- เมื่อตัวละครเกิดใหม่ ให้หันไปทิศทางเดิม
            characterAddedConnection = player.CharacterAdded:Connect(function(character)
                task.wait(0.5) -- รอให้ตัวละครโหลดเสร็จ
                if isAutoWalkActive then
                    -- ตั้งค่าทิศทางกล้องใหม่เมื่อเกิดใหม่
                    setCameraDirection(targetAngle)
                    
                    -- ตั้งค่าความเร็วเดิน
                    local humanoid = character:WaitForChild("Humanoid")
                    humanoid.WalkSpeed = 29
                    humanoid:SetAttribute("TargetWalkSpeed", 29)
                end
            end)
            
        else
            -- เมื่อปิด Toggle
            isAutoWalkActive = false
            lockedToPosition = false
            
            -- หยุดการเดิน
            if player.Character then
                local hum = player.Character:FindFirstChild("Humanoid")
                if hum then
                    hum:MoveTo(player.Character:GetPrimaryPartCFrame().Position)
                end
            end
            
            -- ยกเลิกการเชื่อมต่อเมื่อตัวละครเกิดใหม่
            if characterAddedConnection then
                characterAddedConnection:Disconnect()
                characterAddedConnection = nil
            end

            resetCameraToCharacter()
        end
    end
})

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- ฟังก์ชันรีเซ็ตกล้องให้กลับมาติดตามตัวละคร
local function resetCameraToCharacter()
    -- ตรวจสอบว่าตัวละครมีอยู่จริง
    local character = player.Character
    if not character then
        print("ไม่พบตัวละคร กำลังรอ...")
        character = player.CharacterAdded:Wait()
    end

    -- ตรวจสอบว่ามี HumanoidRootPart
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then
        print("รอ HumanoidRootPart...")
        hrp = character:WaitForChild("HumanoidRootPart")
    end

    -- รีเซ็ตกล้องเป็นมุมมองปกติที่ติดตามตัวละคร
    camera.CameraType = Enum.CameraType.Custom
    camera.CameraSubject = character:FindFirstChildOfClass("Humanoid")
    
    -- ตั้งค่าระยะห่างกล้อง (ปรับตามความเหมาะสม)
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.CameraOffset = Vector3.new(0, 0, 0)
    end
    
    print("รีเซ็ตกล้องเรียบร้อยแล้ว")
end

-- เรียกใช้ฟังก์ชันรีเซ็ตกล้อง
resetCameraToCharacter()

-- เพิ่มตัวรับข้อมูลปุ่มกดสำหรับรีเซ็ตกล้องด้วยปุ่ม
local UserInputService = game:GetService("UserInputService")
UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.R then  -- กดปุ่ม R เพื่อรีเซ็ตกล้อง
        resetCameraToCharacter()
    end
end)

-- ตรวจสอบว่ากล้องยังติดตามตัวละครอยู่หรือไม่
spawn(function()
    while wait(5) do  -- ตรวจสอบทุก 5 วินาที
        if camera.CameraType ~= Enum.CameraType.Custom or 
           not camera.CameraSubject or 
           not camera.CameraSubject:IsA("Humanoid") then
            print("กล้องไม่ได้ติดตามตัวละคร กำลังรีเซ็ต...")
            resetCameraToCharacter()
        end
    end
end)

-- ✅ ปุ่มใน UI สำหรับเรียกใช้
if Tabs and Tabs.Secondary then
	Tabs.Secondary:Button({
		Title = "รีจอ",
		Description = "รีจอ",
		Callback = function()
			resetCameraToCharacter()
		end
	})
end

local pathToDelete = game.Workspace:FindFirstChild("Map"):FindFirstChild("Tiles"):FindFirstChild("ParkTile"):FindFirstChild("CityHall"):FindFirstChild("Exterior"):FindFirstChild("Hitbox")

if pathToDelete then
    pathToDelete:Destroy()
end

Tabs.Secondary:Section({ Title = "Balances" })
local HandBalanceText = Tabs.Secondary:Paragraph({ Title = "Hand: <font color='#00FF00'>Loading...</font>" })
local BankBalanceText = Tabs.Secondary:Paragraph({ Title = "Bank: <font color='#00FF00'>Loading...</font>" })

local function formatCurrency(amount)
    local cleanNumber = amount:gsub("%D", "")
    return cleanNumber:reverse():gsub("%d%d%d", "%1,"):reverse():gsub("^,", "")
end

task.spawn(function()
    local UI_upvr = require(game:GetService("ReplicatedStorage").Modules.Core.UI)
    local Money = UI_upvr.get("HandBalanceLabel", true)
    local BankMoney = UI_upvr.get("BankBalanceLabel", true)

    -- Wait until the UI elements and their text content are available
    repeat task.wait() until Money and Money.ContentText and Money.ContentText ~= ""
    repeat task.wait() until BankMoney and BankMoney.ContentText and BankMoney.ContentText ~= ""

    HandBalanceText:SetTitle("Hand: <font color='#00FF00'>"..formatCurrency(Money.ContentText).."</font>")
    BankBalanceText:SetTitle("Bank: <font color='#00FF00'>"..formatCurrency(BankMoney.ContentText).."</font>")

    -- Update balances when the text changes
    Money:GetPropertyChangedSignal("Text"):Connect(function()
        HandBalanceText:SetTitle("Hand: <font color='#00FF00'>"..formatCurrency(Money.ContentText).."</font>")
    end)

    BankMoney:GetPropertyChangedSignal("Text"):Connect(function()
        BankBalanceText:SetTitle("Bank: <font color='#00FF00'>"..formatCurrency(BankMoney.ContentText).."</font>")
    end)
end)

WindUI:Notify({
    Title = "Auto Walk",
    Content = "พร้อมสำหรับใช้งาน",
    Icon = "diamond-plus",
    Duration = 5,
    Background = "rbxassetid://13511292247"
})

local Players = game:GetService("Players")
local GuiService = game:GetService("GuiService")
local VirtualInputManager = game:GetService("VirtualInputManager")

local player = Players.LocalPlayer

-- 🔄 ฟังก์ชันเช็กว่าผู้เล่นตายอยู่หรือไม่
local function isDead()
    local char = player.Character
    if not char then return true end

    local hum = char:FindFirstChildOfClass("Humanoid")
    return (not hum) or hum.Health <= 0
end

-- 🖱️ ฟังก์ชันกดปุ่ม Respawn แบบรอ GUI 8 วิ
local function tryClickRespawn()
    print("📌 ตรวจพบว่าผู้เล่นตาย รอ 8 วิ...")
    task.wait(8)

    for _, screen in pairs(player:WaitForChild("PlayerGui"):GetChildren()) do
        for _, container in pairs(screen:GetChildren()) do
            for _, frame in pairs(container:GetChildren()) do
                local respawnFrame = frame:FindFirstChild("RespawnButtonFrame")
                if respawnFrame then
                    local button = respawnFrame:FindFirstChild("RespawnButton")
                    if button and button:IsA("TextButton") and container.Visible then
                        print("✅ เจอปุ่ม Respawn → กดเลย")
                        GuiService.SelectedObject = button
                        task.wait(0.1)
                        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
                        task.wait(0.1)
                        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Return, false, game)
                        task.wait(0.1)
                        GuiService.SelectedObject = nil
                        return
                    end
                end
            end
        end
    end

    warn("❌ ไม่เจอปุ่ม Respawn หรือยังไม่เปิด")
end

-- 🔁 ลูปตรวจสอบทุก 0.5 วินาที ว่าผู้เล่นตายหรือไม่
task.spawn(function()
    while true do
        if isDead() then
            print("☠️ ผู้เล่นตาย → เตรียมคลิก Respawn")
            tryClickRespawn()
            -- รอกว่าจะเกิดใหม่ก่อนจะตรวจอีกครั้ง
            repeat task.wait(1) until not isDead()
            print("🧍 ตัวละครเกิดใหม่แล้ว")
        end
        task.wait(0.5)
    end
end)

player.CharacterAdded:Connect(function(character)
    task.wait(2)
    resetCameraToCharacter()
end)

task.delay(1, function()
    if getgenv().AutoSecondaryWalk then
        if SecondaryToggle and typeof(SecondaryToggle.Set) == "function" then
            SecondaryToggle:Set(true)
        end
    end
end)
