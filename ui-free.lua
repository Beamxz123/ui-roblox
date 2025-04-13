-- 🌙 UI Framework (ui-framework.lua)
-- ใช้โหลดผ่าน GitHub และเรียกฟังก์ชันจากภายนอก

local library = {}

-- ⚙️ UI Container ตั้งค่าหลัก
local player = game:GetService("Players").LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "SettingsUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 350, 0, 300)
frame.Position = UDim2.new(0.5, -175, 0.5, -100)
frame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
frame.BorderSizePixel = 0
frame.AnchorPoint = Vector2.new(0.5, 0.5)
frame.Active = true
frame.Draggable = true
frame.Parent = screenGui
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)

local title = Instance.new("TextLabel", frame)
title.Text = "⚙️ Settings"
title.Font = Enum.Font.GothamBold
title.TextSize = 20
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Size = UDim2.new(1, -40, 0, 40)
title.Position = UDim2.new(0, 20, 0, 10)
title.BackgroundTransparency = 1
title.TextXAlignment = Enum.TextXAlignment.Left

local closeBtn = Instance.new("TextButton", frame)
closeBtn.Text = "X"
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 18
closeBtn.Size = UDim2.new(0, 30, 0, 30)
closeBtn.Position = UDim2.new(1, -40, 0, 10)
closeBtn.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Parent = frame
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(1, 0)
closeBtn.MouseButton1Click:Connect(function()
    frame.Visible = false
end)

local container = Instance.new("ScrollingFrame", frame)
container.Size = UDim2.new(1, -20, 1, -60)
container.Position = UDim2.new(0, 10, 0, 50)
container.BackgroundTransparency = 1
container.CanvasSize = UDim2.new(0, 0, 0, 0)
container.ScrollBarThickness = 6
container.AutomaticCanvasSize = Enum.AutomaticSize.Y
container.VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar
container.AutomaticSize = Enum.AutomaticSize.Y

local layout = Instance.new("UIListLayout", container)
layout.Padding = UDim.new(0, 10)
layout.SortOrder = Enum.SortOrder.LayoutOrder

-- ✅ ฟังก์ชันสำหรับเรียกใช้จากภายนอก
function library.CreateToggle(name, desc, callback)
    local toggleFrame = Instance.new("Frame", container)
    toggleFrame.Size = UDim2.new(1, 0, 0, 60)
    toggleFrame.BackgroundTransparency = 1

    local label = Instance.new("TextLabel", toggleFrame)
    label.Text = name
    label.Font = Enum.Font.GothamBold
    label.TextSize = 16
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.Size = UDim2.new(1, -60, 0, 20)
    label.Position = UDim2.new(0, 0, 0, 0)
    label.BackgroundTransparency = 1
    label.TextXAlignment = Enum.TextXAlignment.Left

    local descLabel = Instance.new("TextLabel", toggleFrame)
    descLabel.Text = desc
    descLabel.Font = Enum.Font.Gotham
    descLabel.TextSize = 14
    descLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
    descLabel.Size = UDim2.new(1, -60, 0, 20)
    descLabel.Position = UDim2.new(0, 0, 0, 20)
    descLabel.BackgroundTransparency = 1
    descLabel.TextXAlignment = Enum.TextXAlignment.Left

    local toggle = Instance.new("TextButton", toggleFrame)
    toggle.Size = UDim2.new(0, 40, 0, 20)
    toggle.Position = UDim2.new(1, -50, 0.5, -10)
    toggle.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    toggle.Text = ""
    toggle.TextTransparency = 1
    Instance.new("UICorner", toggle).CornerRadius = UDim.new(1, 0)

    local state = false
    toggle.MouseButton1Click:Connect(function()
        state = not state
        toggle.BackgroundColor3 = state and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(60, 60, 60)
        if callback then
            callback(state)
        end
    end)
end

return library
