
local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local UIS = game:GetService("UserInputService")
local vim = game:GetService("VirtualInputManager")
local gs = game:GetService("GuiService")

local Player = Players.LocalPlayer
local pg = Player:WaitForChild("PlayerGui")

local SAVE_FILE = "ChallengeHub_Settings.json"
local STEP_DELAY = 1
local RESPONSE_WAIT = 2

-- ป้องกันสคริปต์เก่าทำงานซ้อน
local env = (getgenv and getgenv()) or _G
env.ChallengeHubRun = (env.ChallengeHubRun or 0) + 1
local RUN = env.ChallengeHubRun
local function alive()
    return env.ChallengeHubRun == RUN
end

if env.ChallengeHubWindow then
    pcall(function()
        env.ChallengeHubWindow:Destroy()
    end)
end

-- ==================================================
-- Settings
-- ==================================================
local settings = {
    autoChallenge = true,
    autoLeave = true,
    autoBuy = true,
    mode = "Both",
    capsule = "Off",
}

pcall(function()
    if isfile and isfile(SAVE_FILE) then
        local data = HttpService:JSONDecode(readfile(SAVE_FILE))

        if data.mode == "Coins" or data.mode == "Gems" or data.mode == "Both" then
            settings.mode = data.mode
        end

        if data.capsule == "Off" or data.capsule == "Gems" then
            settings.capsule = data.capsule
        end

        if type(data.autoChallenge) == "boolean" then
            settings.autoChallenge = data.autoChallenge
        end

        if type(data.autoLeave) == "boolean" then
            settings.autoLeave = data.autoLeave
        end

        if type(data.autoBuy) == "boolean" then
            settings.autoBuy = data.autoBuy
        end
    end
end)

local function saveSettings()
    pcall(function()
        if writefile then
            writefile(SAVE_FILE, HttpService:JSONEncode(settings))
        end
    end)
end

-- ==================================================
-- UI เดิม Fluent
-- ==================================================
local Window = Fluent:CreateWindow({
    Title = "Challenge Hub",
    SubTitle = "Auto Challenge + Auto Buy",
    TabWidth = 130,
    Size = UDim2.fromOffset(500, 340),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

env.ChallengeHubWindow = Window

local Tabs = {
    Challenge = Window:AddTab({
        Title = "Challenge",
        Icon = "swords"
    }),

    Buy = Window:AddTab({
        Title = "Auto Buy",
        Icon = "shopping-cart"
    }),

    Settings = Window:AddTab({
        Title = "Settings",
        Icon = "settings"
    })
}

InterfaceManager:SetLibrary(Fluent)
InterfaceManager:SetFolder("ChallengeHub")
InterfaceManager:BuildInterfaceSection(Tabs.Settings)

-- Challenge toggle
local ChallengeToggle = Tabs.Challenge:AddToggle("AutoChallenge", {
    Title = "เปิด Auto Challenge (วนจนเข้าได้)",
    Default = settings.autoChallenge
})

local ChStatusP = Tabs.Challenge:AddParagraph({
    Title = "สถานะ Auto Challenge",
    Content = "กำลังเตรียม..."
})

local function setChStatus(t)
    pcall(function()
        ChStatusP:SetDesc(t)
    end)
end

ChallengeToggle:OnChanged(function(v)
    settings.autoChallenge = v
    saveSettings()
    setChStatus(v and "กำลังเริ่มระบบ..." or "ปิดอยู่")
end)

-- Auto Leave toggle
local LeaveToggle = Tabs.Challenge:AddToggle("AutoLeave", {
    Title = "Auto Leave (กดออกตอนจบด่าน)",
    Default = settings.autoLeave
})

local LeaveStatusP = Tabs.Challenge:AddParagraph({
    Title = "สถานะออกด่าน",
    Content = "รอปุ่มออก..."
})

local function setLeaveStatus(t)
    pcall(function()
        LeaveStatusP:SetDesc(t)
    end)
end

LeaveToggle:OnChanged(function(v)
    settings.autoLeave = v
    saveSettings()
    setLeaveStatus(v and "รอปุ่มออก..." or "ปิดอยู่")
end)

-- Auto Buy dropdown
local ModeDropdown = Tabs.Buy:AddDropdown("RerollMode", {
    Title = "Reroll (Trait)",
    Values = {"Coins", "Gems", "Both"},
    Multi = false,
    Default = settings.mode
})

ModeDropdown:OnChanged(function(v)
    if v == "Coins" or v == "Gems" or v == "Both" then
        settings.mode = v
        saveSettings()
    end
end)

local CapsuleToggle = Tabs.Buy:AddToggle("Capsule", {
    Title = "ซื้อ Mystery Capsule (Gems)",
    Default = settings.capsule == "Gems"
})

CapsuleToggle:OnChanged(function(v)
    settings.capsule = v and "Gems" or "Off"
    saveSettings()
end)

local BuyToggle = Tabs.Buy:AddToggle("AutoBuy", {
    Title = "เปิด Auto Buy (ทุก 1 วินาที)",
    Default = settings.autoBuy
})

BuyToggle:OnChanged(function(v)
    settings.autoBuy = v
    saveSettings()
end)

local BuyStatusP = Tabs.Buy:AddParagraph({
    Title = "สถานะ Auto Buy",
    Content = "รอ..."
})

local function setBuyStatus(t)
    pcall(function()
        BuyStatusP:SetDesc(t)
    end)
end

-- ==================================================
-- Helpers
-- ==================================================
local function isShown(obj)
    local p = obj

    while p and p ~= pg do
        if p:IsA("GuiObject") and not p.Visible then
            return false
        end

        if p:IsA("LayerCollector") and not p.Enabled then
            return false
        end

        p = p.Parent
    end

    return p == pg
end

-- ใช้ root เป็นปุ่มก่อน แล้วค้นหา GuiButton ภายใน
-- ให้ตรงกับโค้ดทดสอบที่ผ่านแล้ว
local function findButton(root)
    if not root then
        return nil
    end

    if root:IsA("GuiButton") then
        return root
    end

    for _, obj in ipairs(root:GetDescendants()) do
        if obj:IsA("GuiButton") then
            return obj
        end
    end

    return nil
end

-- กด VIM + Enter เท่านั้น ไม่มี mouse click
local function pressGui(root, keepSelected)
    if not root then
        warn("[VIM] ไม่พบ GUI")
        return false
    end

    local btn = findButton(root)

    if not btn then
        warn("[VIM] ไม่พบ GuiButton:", root:GetFullName())
        return false
    end

    if not isShown(btn) then
        warn("[VIM] ปุ่มยังไม่แสดง:", btn:GetFullName())
        return false
    end

    btn.Selectable = true
    gs.SelectedObject = btn

    task.wait(0.2)

    vim:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
    task.wait(0.1)
    vim:SendKeyEvent(false, Enum.KeyCode.Return, false, game)

    if not keepSelected then
        gs.SelectedObject = nil
    end

    print("[VIM] ส่ง Enter:", btn:GetFullName())
    return true
end

local function getPlayBtn()
    local gui = pg:FindFirstChild("PlayGUI")
    local frame = gui and gui:FindFirstChild("PlayFrame")
    local container = frame and frame:FindFirstChild("ContainerBtn")

    return container and container:FindFirstChild("PlayBtn")
end

local function getCancelBtn()
    local gui = pg:FindFirstChild("PlayGUI")
    local frame = gui and gui:FindFirstChild("PlayFrame")
    local container = frame and frame:FindFirstChild("ContainerBtn")

    return container and container:FindFirstChild("CancelBtn")
end

local function getSelectModeBtn()
    local challenges = pg:FindFirstChild("Challengs")
    local main = challenges and challenges:FindFirstChild("Main")
    local container = main and main:FindFirstChild("Container")
    local card = container and container:FindFirstChild("RegularCard")

    return card and card:FindFirstChild("SelectBtn")
end

local function findLeaveBtn()
    local eg = pg:FindFirstChild("EndGame")
    local frame = eg and eg:FindFirstChild("EndGameFrame")
    local buttons = frame and frame:FindFirstChild("Buttons")
    local root = buttons and buttons:FindFirstChild("LeaveBtn")

    if not root then
        return nil
    end

    if root:IsA("GuiButton") and isShown(root) and root.AbsoluteSize.X > 0 then
        return root
    end

    for _, obj in ipairs(root:GetDescendants()) do
        if obj:IsA("GuiButton")
            and isShown(obj)
            and obj.AbsoluteSize.X > 0
            and obj.AbsoluteSize.Y > 0 then
            return obj
        end
    end

    return nil
end

local function waitForVisible(getter, timeout)
    local started = os.clock()

    repeat
        if not alive() then
            return nil
        end

        local obj = getter()

        if obj and isShown(obj) then
            return obj
        end

        task.wait(0.2)
    until os.clock() - started >= timeout

    return nil
end

-- ==================================================
-- ขั้น 1: วาร์ป
-- ==================================================
local function step1_warp()
    local character = Player.Character or Player.CharacterAdded:Wait()
    local root = character:WaitForChild("HumanoidRootPart")

    root.CFrame = CFrame.new(
        -153.951294, 88.5093994, 207.579758,
        0.81894803, 0, -0.573867679,
        0, 1, 0,
        0.573867679, 0, 0.81894803
    )

    print("[Challenge] วาร์ปแล้ว")
end

-- ==================================================
-- ขั้น 2: สร้าง Lobby ด้วย VIM
-- ==================================================
local function step2_create()
    local gui = pg:WaitForChild("PlayGUI", 10)
    if not gui then
        warn("[Challenge] ไม่พบ PlayGUI")
        return false
    end

    local frame = gui:WaitForChild("CreateLobbyFrame", 10)
    if not frame then
        warn("[Challenge] ไม่พบ CreateLobbyFrame")
        return false
    end

    local container = frame:WaitForChild("Container", 5)
    local btn = container and container:WaitForChild("CreateBtn", 5)

    if not btn then
        warn("[Challenge] ไม่พบ CreateBtn")
        return false
    end

    return pressGui(btn, false)
end

-- ==================================================
-- ขั้น 3: เลือก Regular ด้วย VIM
-- ==================================================
local function step3_selectMode()
    local challenges = pg:WaitForChild("Challengs", 10)
    local main = challenges and challenges:WaitForChild("Main", 5)
    local mode = main and main:WaitForChild("Mode", 5)
    local regular = mode and mode:WaitForChild("Regular", 5)

    if not regular then
        warn("[Challenge] ไม่พบ Regular")
        return false
    end

    return pressGui(regular, true)
end

-- ==================================================
-- ขั้น 4: เลือกโหมดที่สร้างไว้
-- ==================================================
local function step4_createMode()
    local root = getSelectModeBtn()

    if not root then
        warn("[Challenge] ไม่พบ RegularCard.SelectBtn")
        return false
    end

    return pressGui(root, true)
end

-- ==================================================
-- ขั้น 5: กด Play เพียงครั้งเดียว
-- ==================================================
local function step5_play()
    local root = waitForVisible(getPlayBtn, 10)

    if not root then
        warn("[Challenge] รอ PlayBtn แล้วไม่พบ")
        return false
    end

    return pressGui(root, true)
end

-- ==================================================
-- ขั้น 7: Cancel ระหว่างรอด่านเปิด
-- ==================================================
local function step7_cancel()
    local root = waitForVisible(getCancelBtn, 5)

    if not root then
        warn("[Challenge] ไม่พบ CancelBtn สำหรับยกเลิก")
        return false
    end

    return pressGui(root, false)
end

-- ==================================================
-- ตรวจว่ากำลังเข้าเล่นแล้วหรือยัง
-- ==================================================
local function enteredDungeon()
    if findLeaveBtn() then
        return true
    end

    local play = getPlayBtn()

    -- เมื่อ PlayBtn หายไปหลังส่งคำสั่ง ถือว่าเปลี่ยนหน้าหรือเข้าเล่นแล้ว
    if not play or not isShown(play) then
        return true
    end

    return false
end

-- ==================================================
-- วนขั้น 4 -> 5 -> 7 จนเข้าเล่นได้
-- ==================================================
local function step4_5_7_loop()
    while alive() and settings.autoChallenge do
        setChStatus("ขั้น 4: เลือกโหมด")

        local selected = step4_createMode()

        if not selected then
            task.wait(1)
            continue
        end

        task.wait(STEP_DELAY)

        if not alive() or not settings.autoChallenge then
            return false
        end

        setChStatus("ขั้น 5: กด Play")

        local played = step5_play()

        if not played then
            task.wait(1)
            continue
        end

        -- ให้เกมมีเวลาตอบสนองก่อนตัดสินว่าเข้าได้หรือไม่
        local started = os.clock()

        while alive()
            and settings.autoChallenge
            and os.clock() - started < RESPONSE_WAIT do

            if enteredDungeon() then
                setChStatus("เข้าเล่นแล้ว รอจบด่าน...")
                return true
            end

            task.wait(0.2)
        end

        if enteredDungeon() then
            setChStatus("เข้าเล่นแล้ว รอจบด่าน...")
            return true
        end

        -- ยังไม่เข้า: Cancel แล้วกลับไปขั้น 4
        setChStatus("เข้าไม่ได้: ขั้น 7 Cancel")

        local cancelled = step7_cancel()

        if cancelled then
            task.wait(STEP_DELAY)

            -- รอให้หน้ารายการโหมดกลับมา
            waitForVisible(getSelectModeBtn, 8)
        else
            task.wait(1)
        end
    end

    return false
end

-- ==================================================
-- ขั้น 6: Auto Leave ด้วย VIM
-- ==================================================
local leaving = false
local leaveCount = 0

task.spawn(function()
    while alive() do
        task.wait(0.4)

        if settings.autoLeave and not leaving then
            local btn = findLeaveBtn()

            if btn then
                leaving = true
                setLeaveStatus("เจอปุ่ม Leave กำลังกด...")

                task.wait(0.5)

                for i = 1, 5 do
                    if not alive() then
                        break
                    end

                    btn = findLeaveBtn()

                    if not btn then
                        break
                    end

                    pressGui(btn, false)
                    task.wait(1.2)
                end

                leaveCount += 1
                setLeaveStatus("ออกจากด่านแล้ว")

                leaving = false
                task.wait(2)
            end
        end
    end
end)

-- ==================================================
-- Auto Challenge controller
-- ไม่มี cooldown 30 นาที
-- ==================================================
task.spawn(function()
    while alive() do
        if not settings.autoChallenge then
            setChStatus("ปิดอยู่")
            task.wait(0.5)
            continue
        end

        local ok, err = pcall(function()
            setChStatus("ขั้น 1: วาร์ป")
            step1_warp()
            task.wait(STEP_DELAY)

            if not alive() or not settings.autoChallenge then
                return
            end

            setChStatus("ขั้น 2: สร้าง Lobby")

            if not step2_create() then
                task.wait(1)
                return
            end

            task.wait(STEP_DELAY)

            if not alive() or not settings.autoChallenge then
                return
            end

            setChStatus("ขั้น 3: เลือก Regular")

            if not step3_selectMode() then
                task.wait(1)
                return
            end

            task.wait(STEP_DELAY)

            -- จำจำนวน Leave ก่อนเริ่มรอบเข้าเล่น
            local previousLeaveCount = leaveCount

            local entered = step4_5_7_loop()

            if not entered then
                return
            end

            -- รอให้ Auto Leave จบรอบก่อนเริ่ม Lobby ใหม่
            setChStatus("เข้าเล่นแล้ว รอจบด่านและออกจากด่าน")

            if settings.autoLeave then
                while alive() and settings.autoChallenge do
                    if leaveCount > previousLeaveCount then
                        break
                    end
                    task.wait(0.5)
                end
            else
                -- หากปิด Auto Leave ให้รอผู้เล่นออกเอง
                local sawEndGame = false

                while alive() and settings.autoChallenge do
                    if findLeaveBtn() then
                        sawEndGame = true
                    elseif sawEndGame then
                        break
                    end

                    task.wait(0.5)
                end
            end
        end)

        if not ok then
            warn("[Challenge] Error:", tostring(err))
            setChStatus("เกิดข้อผิดพลาด ดู Console (F9)")
        end

        task.wait(1)
    end
end)

-- ==================================================
-- Auto Buy Trait (คงระบบเดิม)
-- ==================================================
local BuyRemote

local function buyItem(item, currency)
    local ok, result = pcall(function()
        if not BuyRemote then
            local remotes = ReplicatedStorage:WaitForChild("Remotes", 10)

            if not remotes then
                error("ไม่พบ Remotes")
            end

            BuyRemote = remotes:WaitForChild("BuyItem", 10)

            if not BuyRemote then
                error("ไม่พบ BuyItem")
            end
        end

        return BuyRemote:InvokeServer(item, 1, currency)
    end)

    if not ok then
        warn("[AutoBuy] " .. item .. " (" .. currency .. "): " .. tostring(result))
        setBuyStatus("ERROR - ดู Console (F9)")
    end
end

local function purchaseSelected()
    local mode = settings.mode

    if mode == "Coins" or mode == "Both" then
        buyItem("Trait", "Coins")
    end

    if mode == "Gems" or mode == "Both" then
        buyItem("Trait", "Gems")
    end

    if settings.capsule == "Gems" then
        buyItem("MysteryCapsule", "Gems")
    end
end

task.spawn(function()
    while alive() do
        if settings.autoBuy then
            setBuyStatus(("กำลังทำงาน | Reroll: %s | Capsule: %s"):format(
                settings.mode,
                settings.capsule == "Gems" and "Gems" or "OFF"
            ))

            purchaseSelected()
        else
            setBuyStatus("หยุดอยู่")
        end

        task.wait(1)
    end
end)

-- ==================================================
-- ปุ่ม UI ลอยเดิม: ลากได้ แตะเพื่อย่อ/เปิด
-- ==================================================
do
    local Parent = (gethui and gethui()) or pg
    local old = Parent:FindFirstChild("ChallengeHubToggle")

    if old then
        old:Destroy()
    end

    local TGui = Instance.new("ScreenGui")
    TGui.Name = "ChallengeHubToggle"
    TGui.ResetOnSpawn = false
    TGui.IgnoreGuiInset = true
    TGui.DisplayOrder = 1000
    TGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    TGui.Parent = Parent

    local Btn = Instance.new("TextButton")
    Btn.Name = "ToggleBtn"
    Btn.Size = UDim2.new(0, 44, 0, 44)
    Btn.Position = UDim2.new(0, 10, 0, 70)
    Btn.BackgroundColor3 = Color3.fromRGB(65, 105, 190)
    Btn.BorderSizePixel = 0
    Btn.Text = "UI"
    Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    Btn.TextSize = 14
    Btn.Font = Enum.Font.GothamBold
    Btn.AutoButtonColor = true
    Btn.Active = true
    Btn.Parent = TGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = Btn

    local function toggleUI()
        pcall(function()
            Window:Minimize()
        end)
    end

    local dragging, moved = false, false
    local dragStart, startPos

    Btn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then

            dragging = true
            moved = false
            dragStart = input.Position
            startPos = Btn.Position
        end
    end)

    UIS.InputChanged:Connect(function(input)
        if dragging
            and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then

            local d = input.Position - dragStart

            if d.Magnitude > 8 then
                moved = true
            end

            if moved then
                Btn.Position = UDim2.new(
                    startPos.X.Scale, startPos.X.Offset + d.X,
                    startPos.Y.Scale, startPos.Y.Offset + d.Y
                )
            end
        end
    end)

    UIS.InputEnded:Connect(function(input)
        if dragging
            and (input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch) then

            dragging = false

            if not moved then
                toggleUI()
            end
        end
    end)
end


-- ==================================================
-- เริ่มต้น: เปิด UI ไว้ ไม่ย่อเองหลังรัน
-- ==================================================
Window:SelectTab(1)
setChStatus(settings.autoChallenge and "กำลังเริ่มระบบ..." or "ปิดอยู่")

print("[Challenge Hub] โหลดเสร็จแล้ว - UI จะไม่ย่ออัตโนมัติ")
