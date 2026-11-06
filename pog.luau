-- Untitled Simulator: Pog + Halloween Tier 6 auto-opener
-- Uses captured purchase calls; spends normal game currency.
-- Untested in-game. No overlapping requests or cooldown bypass.
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
assert(game.PlaceId == 110473356042040, "Run this in Untitled Simulator.")
local player = Players.LocalPlayer
assert(player, "Run this on the client.")
local pg = player:WaitForChild("PlayerGui")
local NAME = "NodiPogAutoOpener"
assert(not pg:FindFirstChild(NAME), "Close the existing opener before loading this version.")
local remotes = workspace:WaitForChild("__REMOTES", 10)
assert(remotes, "__REMOTES not found.")
local folder = remotes:WaitForChild("Game", 10)
assert(folder, "Game remotes not found.")
local shop = folder:WaitForChild("Shop", 10)
assert(shop and shop:IsA("RemoteFunction"), "Shop RemoteFunction not found.")
local DELAY_AFTER_RESPONSE = 0.005
local AMOUNT = 8
local selected = "Pog"
local running, busy, alive = false, false, true
local completed = 0
local connections = {}
local gui = Instance.new("ScreenGui")
gui.Name = NAME
gui.ResetOnSpawn = false
gui.DisplayOrder = 10000
local frame = Instance.new("Frame")
frame.AnchorPoint = Vector2.new(0.5, 0.5)
frame.Position = UDim2.fromScale(0.5, 0.5)
frame.Size = UDim2.new(0.9, 0, 0, 265)
frame.BackgroundColor3 = Color3.fromRGB(25, 25, 32)
frame.Parent = gui
local limit = Instance.new("UISizeConstraint")
limit.MaxSize = Vector2.new(390, 265)
limit.Parent = frame
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 40)
title.BackgroundColor3 = Color3.fromRGB(60, 40, 85)
title.TextColor3 = Color3.new(1, 1, 1)
title.TextSize = 16
title.Text = "Pog / Halloween Tier 6 - drag here"
title.Active = true
title.Parent = frame
local status = Instance.new("TextLabel")
status.Size = UDim2.new(1, -16, 0, 65)
status.Position = UDim2.fromOffset(8, 94)
status.BackgroundTransparency = 1
status.TextColor3 = Color3.new(1, 1, 1)
status.TextSize = 14
status.TextWrapped = true
status.Text = "Selected: Pog. Starting repeatedly spends game currency."
status.Parent = frame
local function button(text, x, y)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0.5, -12, 0, 38)
    b.Position = UDim2.new(x, 6, 0, y)
    b.BackgroundColor3 = Color3.fromRGB(65, 65, 95)
    b.TextColor3 = Color3.new(1, 1, 1)
    b.TextSize = 14
    b.Text = text
    b.Parent = frame
    return b
end
local pog = button("Pog", 0, 48)
local halloween = button("Halloween Tier 6", 0.5, 48)
local toggle = button("Start purchases", 0, 166)
local close = button("Close", 0.5, 166)
local note = Instance.new("TextLabel")
note.Size = UDim2.new(1, -16, 0, 45)
note.Position = UDim2.fromOffset(8, 211)
note.BackgroundTransparency = 1
note.TextColor3 = Color3.fromRGB(190, 190, 205)
note.TextSize = 12
note.TextWrapped = true
note.Text = "Stop before switching eggs. Stop cannot undo a sent purchase. Counts are returned requests, not verified hatches."
note.Parent = frame
local function setStatus(text) if alive then status.Text = text end end
local function refresh()
    if alive then toggle.Text = running and "Stop" or busy and "Stopping..." or "Start purchases" end
end
local function selectEgg(name)
    if busy then setStatus("Stop and wait for the current request before switching eggs.") return end
    selected = name
    completed = 0
    setStatus("Selected: " .. name .. ". Starting repeatedly spends game currency.")
end
pog.Activated:Connect(function() selectEgg("Pog") end)
halloween.Activated:Connect(function() selectEgg("Halloween Tier 6") end)
toggle.Activated:Connect(function()
    if running then
        running = false
        setStatus("Stopping after the current request returns.")
        refresh()
        return
    end
    if busy or not alive then return end
    running, busy = true, true
    local egg = selected
    refresh()
    task.spawn(function()
        local failure
        while alive and running do
            setStatus("Opening: " .. egg .. "\nCompleted requests: " .. completed)
            local ok, result = pcall(function()
                return shop:InvokeServer("Buy", "Eggs", egg, AMOUNT)
            end)
            if not ok then failure = "Request error: " .. tostring(result) running = false break end
            if result == false then
                failure = "Server rejected the request. Check currency, space, unlocks, or cooldown."
                running = false
                break
            end
            completed = completed + 1
            if alive and running then task.wait(DELAY_AFTER_RESPONSE) end
        end
        busy = false
        refresh()
        setStatus(failure or ("Stopped: " .. egg .. "\nCompleted requests: " .. completed))
    end)
end)
local dragging, touch, inputStart, positionStart
connections[#connections + 1] = title.InputBegan:Connect(function(input)
    local mouse = input.UserInputType == Enum.UserInputType.MouseButton1
    local isTouch = input.UserInputType == Enum.UserInputType.Touch
    if dragging or not (mouse or isTouch) then return end
    dragging = true
    touch = isTouch and input or nil
    inputStart, positionStart = input.Position, frame.Position
end)
connections[#connections + 1] = UIS.InputChanged:Connect(function(input)
    if not dragging then return end
    if (not touch and input.UserInputType == Enum.UserInputType.MouseMovement) or input == touch then
        local delta = input.Position - inputStart
        frame.Position = UDim2.new(positionStart.X.Scale, positionStart.X.Offset + delta.X, positionStart.Y.Scale, positionStart.Y.Offset + delta.Y)
    end
end)
connections[#connections + 1] = UIS.InputEnded:Connect(function(input)
    if input == touch or (not touch and input.UserInputType == Enum.UserInputType.MouseButton1) then dragging, touch = false, nil end
end)
close.Activated:Connect(function() gui:Destroy() end)
gui.Destroying:Connect(function()
    alive, running = false, false
    for _, connection in ipairs(connections) do connection:Disconnect() end
end)
gui.Parent = pg
