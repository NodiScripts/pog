-- Untitled Simulator: Pog Egg auto-opener
-- Repeats the exact request captured from your manual hatch.
-- Uses normal currency and server-side eligibility checks.
-- No overlapping requests.

local Players = game:GetService("Players")

assert(
    game.PlaceId == 110473356042040,
    "Run this in Untitled Simulator."
)

local player = Players.LocalPlayer
assert(player, "Run this on the client.")

local playerGui = player:WaitForChild("PlayerGui")

-- Prevent duplicate copies from running simultaneously.
local GUI_NAME = "NodiPogAutoOpener"

assert(
    not playerGui:FindFirstChild(GUI_NAME),
    "Pog auto-opener is already loaded. Use its existing controls."
)

local remotes = workspace:WaitForChild("__REMOTES", 10)
assert(remotes, "__REMOTES not found.")

local gameRemotes = remotes:WaitForChild("Game", 10)
assert(gameRemotes, "Game remotes not found.")

local shop = gameRemotes:WaitForChild("Shop", 10)
assert(
    shop and shop:IsA("RemoteFunction"),
    "Shop RemoteFunction not found."
)

local DELAY_AFTER_RESPONSE = 0.005
local CAPTURED_AMOUNT = 8

local running = false
local busy = false
local alive = true
local completedCalls = 0

local gui = Instance.new("ScreenGui")
gui.Name = GUI_NAME
gui.ResetOnSpawn = false
gui.Parent = playerGui

local frame = Instance.new("Frame")
frame.Size = UDim2.fromOffset(310, 190)
frame.Position = UDim2.new(0.5, -155, 0.5, -95)
frame.BackgroundColor3 = Color3.fromRGB(25, 25, 32)
frame.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = frame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -16, 0, 36)
title.Position = UDim2.fromOffset(8, 4)
title.BackgroundTransparency = 1
title.Text = "Pog Egg Auto-Opener"
title.TextColor3 = Color3.new(1, 1, 1)
title.TextSize = 19
title.Parent = frame

local status = Instance.new("TextLabel")
status.Size = UDim2.new(1, -20, 0, 62)
status.Position = UDim2.fromOffset(10, 40)
status.BackgroundTransparency = 1
status.TextWrapped = true
status.Text = "Stopped. Starting will repeatedly spend MoonCoins."
status.TextColor3 = Color3.fromRGB(220, 220, 230)
status.TextSize = 14
status.Parent = frame

local toggle = Instance.new("TextButton")
toggle.Size = UDim2.fromOffset(180, 38)
toggle.Position = UDim2.fromOffset(10, 115)
toggle.BackgroundColor3 = Color3.fromRGB(45, 125, 80)
toggle.TextColor3 = Color3.new(1, 1, 1)
toggle.TextSize = 16
toggle.Text = "Start purchases"
toggle.Parent = frame

local close = Instance.new("TextButton")
close.Size = UDim2.fromOffset(100, 38)
close.Position = UDim2.fromOffset(200, 115)
close.BackgroundColor3 = Color3.fromRGB(110, 45, 50)
close.TextColor3 = Color3.new(1, 1, 1)
close.TextSize = 16
close.Text = "Close"
close.Parent = frame

local note = Instance.new("TextLabel")
note.Size = UDim2.new(1, -16, 0, 26)
note.Position = UDim2.fromOffset(8, 158)
note.BackgroundTransparency = 1
note.Text = "Stop cannot undo an already-sent purchase."
note.TextColor3 = Color3.fromRGB(190, 190, 200)
note.TextSize = 12
note.Parent = frame

local function setStatus(text)
    if alive then
        status.Text = text
    end
end

local function refreshButton()
    if not alive then
        return
    end

    if running then
        toggle.Text = "Stop"
    elseif busy then
        toggle.Text = "Stopping..."
    else
        toggle.Text = "Start purchases"
    end
end

toggle.Activated:Connect(function()
    if running then
        running = false
        setStatus("Stopping after the current request returns.")
        refreshButton()
        return
    end

    if busy or not alive then
        return
    end

    running = true
    busy = true
    refreshButton()

    task.spawn(function()
        while alive and running do
            setStatus(
                "Opening Pog eggs...\nCompleted requests: "
                .. completedCalls
            )

            local results = table.pack(pcall(function()
                return shop:InvokeServer(
                    "Buy",
                    "Eggs",
                    "Pog",
                    CAPTURED_AMOUNT
                )
            end))

            if not results[1] then
                running = false
                setStatus("Request error: " .. tostring(results[2]))
                break
            end

            -- Stop on an explicit rejection.
            -- Other return formats have not been verified.
            if results[2] == false then
                running = false
                setStatus(
                    "Server rejected the request. Check currency, "
                    .. "inventory space, unlocks, or cooldown."
                )
                break
            end

            completedCalls = completedCalls + 1

            if not running or not alive then
                break
            end

            task.wait(DELAY_AFTER_RESPONSE)
        end

        busy = false

        if alive then
            refreshButton()

            if status.Text == "Stopping after the current request returns." then
                setStatus(
                    "Stopped.\nCompleted requests: " .. completedCalls
                )
            end
        end
    end)
end)

gui.Destroying:Connect(function()
    alive = false
    running = false
end)

close.Activated:Connect(function()
    gui:Destroy()
end)
