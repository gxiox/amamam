--// Challenge Hub
--// Auto Challenge + Auto Leave + Auto Buy
--// Input method: GuiService.SelectedObject + VirtualInputManager Enter
--// For testing in your own Roblox experience.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Fluent UI
local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripting/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripting/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripting/Fluent/master/Addons/InterfaceManager.lua"))()

local Window = Fluent:CreateWindow({
    Title = "Challenge Hub",
    SubTitle = "Auto Challenge + Auto Buy",
    TabWidth = 150,
    Size = UDim2.fromOffset(500, 340),
    Acrylic = false,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

local Tabs = {
    Challenge = Window:AddTab({ Title = "Challenge", Icon = "swords" }),
    AutoBuy = Window:AddTab({ Title = "Auto Buy", Icon = "shopping-cart" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
}

local SettingsFile = "ChallengeHub_Settings.json"
local settings = {
    autoChallenge = true,
    autoLeave = true,
    autoBuy = true,
    mode = "Both",
    capsule = "Off"
}

pcall(function()
    if isfile and isfile(SettingsFile) then
        local saved = HttpService:JSONDecode(readfile(SettingsFile))
        for k, v in pairs(saved) do settings[k] = v end
    end
end)

local function saveSettings()
    pcall(function()
        if writefile then writefile(SettingsFile, HttpService:JSONEncode(settings)) end
    end)
end

local running = true
local leaveCount = 0
local statusChallenge = "Idle"
local statusLeave = "Idle"
local statusBuy = "Idle"
local AUTO_BUY_INTERVAL = 1
local RESPONSE_WAIT = 2

local function getPath(root, path)
    local current = root
    for name in string.gmatch(path, "[^%.]+") do
        if not current then return nil end
        current = current:FindFirstChild(name)
    end
    return current
end

local function isShown(obj)
    if not obj then return false end
    local current = obj
    while current and current ~= PlayerGui do
        if current:IsA("GuiObject") and not current.Visible then return false end
        if current:IsA("LayerCollector") and not current.Enabled then return false end
        current = current.Parent
    end
    return true
end

local function findButton(root)
    if not root then return nil end
    if root:IsA("GuiButton") then return root end
    for _, item in ipairs(root:GetDescendants()) do
        if item:IsA("GuiButton") then return item end
    end
    return nil
end

local function pressGui(root, keepSelected)
    local btn = findButton(root)
    if not btn or not isShown(btn) then return false end
    pcall(function() btn.Selectable = true end)
    GuiService.SelectedObject = btn
    task.wait(0.2)
    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
    task.wait(0.1)
    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Return, false, game)
    if not keepSelected then
        task.wait(0.1)
        pcall(function() if GuiService.SelectedObject == btn then GuiService.SelectedObject = nil end end)
    end
    return true
end

local function getCreateBtn()
    return getPath(PlayerGui, "PlayGUI.CreateLobbyFrame.Container.CreateBtn")
end
local function getRegularMode()
    return getPath(PlayerGui, "Challengs.Main.Mode.Regular")
end
local function getSelectModeBtn()
    return getPath(PlayerGui, "Challengs.Main.Container.RegularCard.SelectBtn")
end
local function getPlayBtn()
    return getPath(PlayerGui, "PlayGUI.PlayFrame.ContainerBtn.PlayBtn")
end
local function getCancelBtn()
    return getPath(PlayerGui, "PlayGUI.PlayFrame.ContainerBtn.CancelBtn")
end
local function getLeaveBtn()
    return getPath(PlayerGui, "EndGame.EndGameFrame.Buttons.LeaveBtn")
end

local function waitForVisible(getter, timeout)
    local start = os.clock()
    repeat
        local obj = getter()
        if obj and isShown(obj) then return obj end
        task.wait(0.25)
    until os.clock() - start >= (timeout or 10) or not running
    return nil
end

local function step1_warp()
    local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local hrp = character:FindFirstChild("HumanoidRootPart") or character:WaitForChild("HumanoidRootPart", 5)
    if not hrp then return false end
    hrp.CFrame = CFrame.new(-153.951294, 88.5093994, 207.579758, 0.81894803, 0, -0.573867679, 0, 1, 0, 0.573867679, 0, 0.81894803)
    task.wait(1)
    return true
end

local function step2_create()
    local root = waitForVisible(getCreateBtn, 10)
    if not root then return false end
    return pressGui(root, false)
end

local function step3_regular()
    local root = waitForVisible(getRegularMode, 10)
    if not root then return false end
    return pressGui(root, false)
end

local function enteredDungeon()
    local leave = getLeaveBtn()
    if leave and isShown(leave) then return true end
    local play = getPlayBtn()
    if not play or not isShown(play) then return true end
    return false
end

local function step4_5_7_loop()
    while running and settings.autoChallenge do
        statusChallenge = "Step 4: Select Regular"
        local selectBtn = waitForVisible(getSelectModeBtn, 10)
        if selectBtn then pressGui(selectBtn, false) end
        task.wait(0.4)

        statusChallenge = "Step 5: Play"
        local playBtn = waitForVisible(getPlayBtn, 10)
        if not playBtn then
            task.wait(0.5)
        else
            pressGui(playBtn, false) -- press Play once only
            local startedAt = os.clock()
            while running and os.clock() - startedAt < RESPONSE_WAIT do
                if enteredDungeon() then
                    statusChallenge = "Entered dungeon"
                    return true
                end
                task.wait(0.2)
            end
            if enteredDungeon() then
                statusChallenge = "Entered dungeon"
                return true
            end
        end

        statusChallenge = "Step 7: Cancel and retry"
        local cancelBtn = waitForVisible(getCancelBtn, 5)
        if cancelBtn then pressGui(cancelBtn, false) end
        waitForVisible(getSelectModeBtn, 8)
        task.wait(0.4)
    end
    return false
end

-- Challenge controller: no cooldown; after leaving, start the next lobby cycle.
task.spawn(function()
    while running do
        if settings.autoChallenge then
            statusChallenge = "Step 1: Warp"
            step1_warp()
            if not settings.autoChallenge then task.wait(0.5) continue end

            statusChallenge = "Step 2: Create lobby"
            if not step2_create() then task.wait(1) continue end

            statusChallenge = "Step 3: Select Regular"
            if not step3_regular() then task.wait(1) continue end

            local previousLeaveCount = leaveCount
            local entered = step4_5_7_loop()
            if entered then
                statusChallenge = "Waiting in dungeon"
                if settings.autoLeave then
                    while running and settings.autoChallenge and leaveCount == previousLeaveCount do task.wait(0.5) end
                else
                    waitForVisible(getLeaveBtn, 60)
                    while running and settings.autoChallenge do
                        local leave = getLeaveBtn()
                        if leave and not isShown(leave) then break end
                        task.wait(1)
                    end
                end
            end
            statusChallenge = "Preparing next lobby"
            task.wait(1)
        else
            statusChallenge = "Disabled"
            task.wait(1)
        end
    end
end)

-- Auto Leave using the same keyboard/selection input method.
task.spawn(function()
    while running do
        if settings.autoLeave then
            local btn = getLeaveBtn()
            if btn and isShown(btn) then
                statusLeave = "Leaving..."
                if pressGui(btn, false) then
                    leaveCount += 1
                    task.wait(2)
                else
                    task.wait(0.5)
                end
            else
                statusLeave = "Waiting for end screen"
                task.wait(0.5)
            end
        else
            statusLeave = "Disabled"
            task.wait(1)
        end
    end
end)

-- Auto Buy remotes (preserved Coins / Gems / Both options).
task.spawn(function()
    while running do
        if settings.autoBuy then
            local remotes = ReplicatedStorage:FindFirstChild("Remotes")
            local buyRemote = remotes and remotes:FindFirstChild("BuyItem")
            if buyRemote then
                local currencies = settings.mode == "Both" and {"Coins", "Gems"} or {settings.mode}
                for _, currency in ipairs(currencies) do
                    pcall(function() buyRemote:InvokeServer("Trait", 1, currency) end)
                end
                if settings.capsule == "On" then
                    pcall(function() buyRemote:InvokeServer("Mystery Capsule", 1, settings.mode == "Gems" and "Gems" or "Coins") end)
                end
                statusBuy = "Running"
            else
                statusBuy = "BuyItem remote not found"
            end
            task.wait(AUTO_BUY_INTERVAL)
        else
            statusBuy = "Disabled"
            task.wait(1)
        end
    end
end)

-- Challenge controls
Tabs.Challenge:AddToggle("AutoChallenge", {
    Title = "เปิด Auto Challenge",
    Default = settings.autoChallenge,
    Callback = function(value) settings.autoChallenge = value; saveSettings() end
})
Tabs.Challenge:AddParagraph({ Title = "Challenge Status", Content = "สถานะจะแสดงในหน้าต่างนี้เมื่อกดรีเฟรช" })
Tabs.Challenge:AddButton({ Title = "ดูสถานะ Challenge", Callback = function() Fluent:Notify({ Title = "Challenge Hub", Content = statusChallenge, Duration = 4 }) end })
Tabs.Challenge:AddToggle("AutoLeave", {
    Title = "เปิด Auto Leave",
    Default = settings.autoLeave,
    Callback = function(value) settings.autoLeave = value; saveSettings() end
})
Tabs.Challenge:AddButton({ Title = "ดูสถานะ Leave", Callback = function() Fluent:Notify({ Title = "Auto Leave", Content = statusLeave, Duration = 4 }) end })

-- Auto Buy controls
Tabs.AutoBuy:AddDropdown("BuyMode", {
    Title = "สกุลเงินที่ใช้ซื้อ",
    Values = {"Coins", "Gems", "Both"},
    Multi = false,
    Default = settings.mode,
    Callback = function(value) settings.mode = value; saveSettings() end
})
Tabs.AutoBuy:AddToggle("MysteryCapsule", {
    Title = "ซื้อ Mystery Capsule",
    Default = settings.capsule == "On",
    Callback = function(value) settings.capsule = value and "On" or "Off"; saveSettings() end
})
Tabs.AutoBuy:AddToggle("AutoBuy", {
    Title = "เปิด Auto Buy",
    Default = settings.autoBuy,
    Callback = function(value) settings.autoBuy = value; saveSettings() end
})
Tabs.AutoBuy:AddButton({ Title = "ดูสถานะ Auto Buy", Callback = function() Fluent:Notify({ Title = "Auto Buy", Content = statusBuy, Duration = 4 }) end })

Tabs.Settings:AddButton({ Title = "บันทึกการตั้งค่า", Callback = function() saveSettings(); Fluent:Notify({ Title = "Challenge Hub", Content = "บันทึกการตั้งค่าแล้ว", Duration = 3 }) end })

SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({})
InterfaceManager:SetFolder("ChallengeHub")
SaveManager:SetFolder("ChallengeHub")
InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)

-- Floating UI toggle. UI does not auto-minimize after execution.
local floating = Instance.new("ScreenGui")
floating.Name = "ChallengeHubToggle"
floating.ResetOnSpawn = false
floating.Parent = PlayerGui

local toggleButton = Instance.new("TextButton")
toggleButton.Name = "ToggleButton"
toggleButton.Size = UDim2.fromOffset(44, 44)
toggleButton.Position = UDim2.new(0, 20, 0.5, -22)
toggleButton.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleButton.Text = "UI"
toggleButton.TextSize = 16
toggleButton.Font = Enum.Font.GothamBold
toggleButton.BorderSizePixel = 0
toggleButton.Active = true
toggleButton.Draggable = true
toggleButton.Parent = floating
Instance.new("UICorner", toggleButton).CornerRadius = UDim.new(0, 10)

toggleButton.Activated:Connect(function()
    Window:Minimize()
end)

Window:SelectTab(1)
Fluent:Notify({ Title = "Challenge Hub", Content = "โหลดสคริปต์แล้ว — UI จะไม่ย่อเอง", Duration = 4 })
