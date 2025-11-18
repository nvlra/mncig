-- ================================
-- SIMPLE MOBILE LOGGER
-- Lightweight debug tool for mobile
-- ================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer

-- ====== STORAGE ======
local savedPositions = {}
local remoteLogs = {}
local LoggingEnabled = true

-- ====== UTILITY FUNCTIONS ======
local function GetTimestamp()
    return os.date("%H:%M:%S")
end

local function GetPlayerPosition()
    local char = LocalPlayer.Character
    if not char then return nil end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    return hrp.Position
end

local function FormatVector3(vec)
    return string.format("Vector3.new(%.2f, %.2f, %.2f)", vec.X, vec.Y, vec.Z)
end

-- ====== NOTIFICATION SYSTEM ======
local function CreateNotification(title, message, duration)
    local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
    
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "LoggerNotif"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.Parent = PlayerGui
    
    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(0, 300, 0, 80)
    Frame.Position = UDim2.new(1, -320, 0, 20)
    Frame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    Frame.BorderSizePixel = 0
    Frame.Parent = ScreenGui
    
    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 10)
    Corner.Parent = Frame
    
    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, -20, 0, 25)
    Title.Position = UDim2.new(0, 10, 0, 10)
    Title.BackgroundTransparency = 1
    Title.Text = title
    Title.TextColor3 = Color3.fromRGB(255, 255, 255)
    Title.TextSize = 16
    Title.Font = Enum.Font.GothamBold
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Parent = Frame
    
    local Message = Instance.new("TextLabel")
    Message.Size = UDim2.new(1, -20, 0, 35)
    Message.Position = UDim2.new(0, 10, 0, 35)
    Message.BackgroundTransparency = 1
    Message.Text = message
    Message.TextColor3 = Color3.fromRGB(200, 200, 200)
    Message.TextSize = 13
    Message.Font = Enum.Font.Gotham
    Message.TextXAlignment = Enum.TextXAlignment.Left
    Message.TextWrapped = true
    Message.Parent = Frame
    
    -- Animate in
    Frame.Position = UDim2.new(1, 20, 0, 20)
    local tweenIn = TweenService:Create(Frame, TweenInfo.new(0.3), {
        Position = UDim2.new(1, -320, 0, 20)
    })
    tweenIn:Play()
    
    -- Animate out
    task.delay(duration or 3, function()
        local tweenOut = TweenService:Create(Frame, TweenInfo.new(0.3), {
            Position = UDim2.new(1, 20, 0, 20)
        })
        tweenOut:Play()
        tweenOut.Completed:Wait()
        ScreenGui:Destroy()
    end)
end

-- ====== REMOTE LOGGER ======
local function SetupRemoteLogger()
    local oldNamecall
    oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
        local method = getnamecallmethod()
        local args = {...}
        
        if LoggingEnabled then
            if method == "FireServer" and self:IsA("RemoteEvent") then
                local logData = {
                    time = GetTimestamp(),
                    type = "RemoteEvent",
                    name = self.Name,
                    path = self:GetFullName(),
                    args = args
                }
                table.insert(remoteLogs, logData)
                
                print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
                print("[Remote] FireServer -", self.Name)
                print("Path:", self:GetFullName())
                local success, encoded = pcall(function()
                    return HttpService:JSONEncode(args)
                end)
                if success then
                    print("Args:", encoded)
                else
                    print("Args: [Complex data - cannot encode]")
                    for i, arg in ipairs(args) do
                        print("  Arg", i, ":", typeof(arg), tostring(arg))
                    end
                end
                print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            end
            
            if method == "InvokeServer" and self:IsA("RemoteFunction") then
                local logData = {
                    time = GetTimestamp(),
                    type = "RemoteFunction",
                    name = self.Name,
                    path = self:GetFullName(),
                    args = args
                }
                table.insert(remoteLogs, logData)
                
                print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
                print("[Remote] InvokeServer -", self.Name)
                print("Path:", self:GetFullName())
                print("Args:", HttpService:JSONEncode(args))
                print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            end
        end
        
        return oldNamecall(self, ...)
    end)
    
    print("[Logger] Remote Logger Active")
end

-- ====== CREATE SIMPLE GUI ======
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MobileLogger"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- Main Frame
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 350, 0, 450)
MainFrame.Position = UDim2.new(0.5, -175, 0.5, -225)
MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local Corner = Instance.new("UICorner")
Corner.CornerRadius = UDim.new(0, 12)
Corner.Parent = MainFrame

-- Header
local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 50)
Header.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
Header.BorderSizePixel = 0
Header.Parent = MainFrame

local HeaderCorner = Instance.new("UICorner")
HeaderCorner.CornerRadius = UDim.new(0, 12)
HeaderCorner.Parent = Header

local HeaderFix = Instance.new("Frame")
HeaderFix.Size = UDim2.new(1, 0, 0, 12)
HeaderFix.Position = UDim2.new(0, 0, 1, -12)
HeaderFix.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
HeaderFix.BorderSizePixel = 0
HeaderFix.Parent = Header

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -100, 1, 0)
Title.Position = UDim2.new(0, 15, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "📱 Mobile Logger"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 18
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Header

-- Close Button
local CloseButton = Instance.new("TextButton")
CloseButton.Size = UDim2.new(0, 35, 0, 35)
CloseButton.Position = UDim2.new(1, -45, 0, 7.5)
CloseButton.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
CloseButton.Text = "X"
CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseButton.TextSize = 16
CloseButton.Font = Enum.Font.GothamBold
CloseButton.BorderSizePixel = 0
CloseButton.Parent = Header

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 8)
CloseCorner.Parent = CloseButton

CloseButton.MouseButton1Click:Connect(function()
    MainFrame.Visible = false
end)

-- Content Frame
local Content = Instance.new("ScrollingFrame")
Content.Size = UDim2.new(1, -20, 1, -70)
Content.Position = UDim2.new(0, 10, 0, 60)
Content.BackgroundTransparency = 1
Content.BorderSizePixel = 0
Content.ScrollBarThickness = 4
Content.Parent = MainFrame

local ContentLayout = Instance.new("UIListLayout")
ContentLayout.Padding = UDim.new(0, 10)
ContentLayout.SortOrder = Enum.SortOrder.LayoutOrder
ContentLayout.Parent = Content

-- ====== BUTTON CREATOR ======
local function CreateButton(text, callback)
    local Button = Instance.new("TextButton")
    Button.Size = UDim2.new(1, 0, 0, 45)
    Button.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
    Button.Text = text
    Button.TextColor3 = Color3.fromRGB(255, 255, 255)
    Button.TextSize = 15
    Button.Font = Enum.Font.GothamBold
    Button.BorderSizePixel = 0
    Button.Parent = Content
    
    local BtnCorner = Instance.new("UICorner")
    BtnCorner.CornerRadius = UDim.new(0, 8)
    BtnCorner.Parent = Button
    
    Button.MouseButton1Click:Connect(callback)
    
    return Button
end

local function CreateInput(placeholder, callback)
    local Input = Instance.new("TextBox")
    Input.Size = UDim2.new(1, 0, 0, 45)
    Input.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    Input.PlaceholderText = placeholder
    Input.Text = ""
    Input.TextColor3 = Color3.fromRGB(255, 255, 255)
    Input.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
    Input.TextSize = 14
    Input.Font = Enum.Font.Gotham
    Input.BorderSizePixel = 0
    Input.ClearTextOnFocus = false
    Input.Parent = Content
    
    local InputCorner = Instance.new("UICorner")
    InputCorner.CornerRadius = UDim.new(0, 8)
    InputCorner.Parent = Input
    
    local InputPadding = Instance.new("UIPadding")
    InputPadding.PaddingLeft = UDim.new(0, 12)
    InputPadding.PaddingRight = UDim.new(0, 12)
    InputPadding.Parent = Input
    
    Input.FocusLost:Connect(function()
        if Input.Text ~= "" then
            callback(Input.Text)
        end
    end)
    
    return Input
end

local function CreateLabel(text)
    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, 0, 0, 30)
    Label.BackgroundTransparency = 1
    Label.Text = text
    Label.TextColor3 = Color3.fromRGB(200, 200, 200)
    Label.TextSize = 13
    Label.Font = Enum.Font.Gotham
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.TextWrapped = true
    Label.Parent = Content
    
    local LabelPadding = Instance.new("UIPadding")
    LabelPadding.PaddingLeft = UDim.new(0, 5)
    LabelPadding.Parent = Label
    
    return Label
end

-- ====== CREATE UI ELEMENTS ======
CreateLabel("📍 Position Logger")

local locationInput = CreateInput("Location name (e.g. Spawn Island)", function() end)

CreateButton("💾 Save Current Position", function()
    local pos = GetPlayerPosition()
    if not pos then
        CreateNotification("Error", "Character not found", 3)
        return
    end
    
    local name = locationInput.Text
    if name == "" then
        name = "Location " .. (#savedPositions + 1)
    end
    
    local posData = {
        name = name,
        position = pos,
        formatted = FormatVector3(pos),
        time = GetTimestamp()
    }
    
    table.insert(savedPositions, posData)
    
    print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    print("[Position Saved]")
    print("Name:", posData.name)
    print("Position:", posData.formatted)
    print("Time:", posData.time)
    print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    
    CreateNotification("Position Saved", posData.name, 2)
    locationInput.Text = ""
end)

CreateButton("📍 Show Current Position", function()
    local pos = GetPlayerPosition()
    if pos then
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("[Current Position]")
        print("Formatted:", FormatVector3(pos))
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        CreateNotification("Position Logged", "Check console", 2)
    else
        CreateNotification("Error", "Character not found", 3)
    end
end)

CreateLabel("━━━━━━━━━━━━━━━━━━━━━━━━")
CreateLabel("📊 Data Export")

CreateButton("📋 Show All Positions", function()
    if #savedPositions == 0 then
        CreateNotification("Empty", "No positions saved", 2)
        return
    end
    
    print("\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    print("    SAVED POSITIONS")
    print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    
    for i, pos in ipairs(savedPositions) do
        print(string.format("\n[%d] %s", i, pos.name))
        print("   ", pos.formatted)
        print("   Time:", pos.time)
    end
    
    print("\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
    CreateNotification("Positions Listed", #savedPositions .. " locations", 2)
end)

CreateButton("📤 Export Lua Code", function()
    if #savedPositions == 0 then
        CreateNotification("Empty", "No data to export", 2)
        return
    end
    
    print("\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    print("   COPY THIS CODE:")
    print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
    
    print("local Locations = {")
    for i, pos in ipairs(savedPositions) do
        print(string.format('    ["%s"] = %s,', pos.name, pos.formatted))
    end
    print("}")
    
    print("\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
    CreateNotification("Exported", "Copy from console", 3)
end)

CreateButton("📡 Show Last 10 Remotes", function()
    local count = math.min(10, #remoteLogs)
    
    if count == 0 then
        CreateNotification("Empty", "No remotes logged", 2)
        return
    end
    
    print("\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    print("    LAST 10 REMOTES")
    print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    
    local startIdx = math.max(1, #remoteLogs - 9)
    for i = startIdx, #remoteLogs do
        local log = remoteLogs[i]
        print(string.format("\n[%s] %s - %s", log.time, log.type, log.name))
        print("   Path:", log.path)
    end
    
    print("\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
    CreateNotification("Remotes Listed", count .. " calls", 2)
end)

CreateButton("📋 List Unique Remotes", function()
    local unique = {}
    
    for _, log in ipairs(remoteLogs) do
        if not unique[log.path] then
            unique[log.path] = {
                name = log.name,
                type = log.type,
                count = 0
            }
        end
        unique[log.path].count = unique[log.path].count + 1
    end
    
    print("\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    print("    UNIQUE REMOTES")
    print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    
    for path, data in pairs(unique) do
        print(string.format("\n[%s] %s", data.type, data.name))
        print("   Path:", path)
        print("   Called:", data.count, "times")
    end
    
    print("\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
    CreateNotification("Unique Remotes", "Check console", 2)
end)

CreateLabel("━━━━━━━━━━━━━━━━━━━━━━━━")
CreateLabel("🖥️ Console Control")

CreateButton("🖥️ Open Console", function()
    pcall(function()
        game:GetService("StarterGui"):SetCore("DevConsoleVisible", true)
    end)
    CreateNotification("Console", "Opened", 2)
end)

CreateButton("❌ Close Console", function()
    pcall(function()
        game:GetService("StarterGui"):SetCore("DevConsoleVisible", false)
    end)
    CreateNotification("Console", "Closed", 2)
end)

CreateButton("🧹 Clear Console", function()
    rconsoleclear()
    print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    print("[Console Cleared]")
    print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    CreateNotification("Console", "Cleared", 2)
end)

CreateLabel("━━━━━━━━━━━━━━━━━━━━━━━━")

CreateButton("🗑️ Clear All Data", function()
    savedPositions = {}
    remoteLogs = {}
    CreateNotification("Data Cleared", "All logs deleted", 2)
end)

-- Update canvas size
ContentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    Content.CanvasSize = UDim2.new(0, 0, 0, ContentLayout.AbsoluteContentSize.Y + 10)
end)

-- ====== TOGGLE BUTTON ======
local ToggleButton = Instance.new("TextButton")
ToggleButton.Size = UDim2.new(0, 60, 0, 60)
ToggleButton.Position = UDim2.new(0, 10, 0.5, -30)
ToggleButton.BackgroundColor3 = Color3.fromRGB(50, 150, 255)
ToggleButton.Text = "📱"
ToggleButton.TextSize = 28
ToggleButton.Font = Enum.Font.GothamBold
ToggleButton.BorderSizePixel = 0
ToggleButton.Parent = ScreenGui

local ToggleCorner = Instance.new("UICorner")
ToggleCorner.CornerRadius = UDim.new(1, 0)
ToggleCorner.Parent = ToggleButton

ToggleButton.MouseButton1Click:Connect(function()
    MainFrame.Visible = not MainFrame.Visible
end)

-- Make toggle button draggable
local dragging = false
local dragInput, mousePos, framePos

ToggleButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        mousePos = input.Position
        framePos = ToggleButton.Position
        
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

ToggleButton.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

game:GetService("UserInputService").InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - mousePos
        ToggleButton.Position = UDim2.new(
            framePos.X.Scale,
            framePos.X.Offset + delta.X,
            framePos.Y.Scale,
            framePos.Y.Offset + delta.Y
        )
    end
end)

-- ====== INITIALIZE ======
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

-- Setup logger
SetupRemoteLogger()

-- Auto open console
task.delay(0.5, function()
    pcall(function()
        game:GetService("StarterGui"):SetCore("DevConsoleVisible", true)
    end)
end)

print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
print("  📱 MOBILE LOGGER LOADED")
print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
print("✅ Remote Logger Active")
print("✅ UI Loaded")
print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
print("Tap blue button to open menu")
print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

CreateNotification("Logger Ready", "Tap 📱 button to open", 5)
