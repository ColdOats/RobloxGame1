local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local config = require(ReplicatedStorage:WaitForChild("MiningConfig"))
local mineRemote = ReplicatedStorage:WaitForChild("SwingAtOre")
local mouse = player:GetMouse()
local characterConnections = {}
local pickaxeConnection

local function bindCharacter(character)
    for _, connection in ipairs(characterConnections) do connection:Disconnect() end
    table.clear(characterConnections)
    if pickaxeConnection then pickaxeConnection:Disconnect(); pickaxeConnection = nil end

    local function watchTool()
        if pickaxeConnection then pickaxeConnection:Disconnect(); pickaxeConnection = nil end
        local tool = character:FindFirstChildOfClass("Tool")
        if not tool or tool:GetAttribute("MiningPickaxe") ~= true then return end
        pickaxeConnection = tool.Activated:Connect(function()
            local target = mouse.Target
            local camera = workspace.CurrentCamera
            if camera and UserInputService:GetLastInputType().Name:match("^Gamepad") then
                local viewport = camera.ViewportSize
                local look = camera:ViewportPointToRay(viewport.X / 2, viewport.Y / 2)
                local options = RaycastParams.new()
                options.FilterDescendantsInstances = {character}
                local hit = workspace:Raycast(look.Origin, look.Direction * 32, options)
                target = hit and hit.Instance
            end
            if target and CollectionService:HasTag(target, "MineableOre") then
                mineRemote:FireServer(target)
            end
        end)
    end

    local function changed(child)
        if child:IsA("Tool") then watchTool() end
    end
    table.insert(characterConnections, character.ChildAdded:Connect(changed))
    table.insert(characterConnections, character.ChildRemoved:Connect(changed))
    watchTool()
end
player.CharacterAdded:Connect(bindCharacter)
if player.Character then bindCharacter(player.Character) end

local mint = Color3.fromRGB(106, 236, 202)
local gold = Color3.fromRGB(255, 197, 110)
local ink = Color3.fromRGB(22, 35, 38)
local slate = Color3.fromRGB(38, 58, 61)
local soft = Color3.fromRGB(184, 207, 205)
local white = Color3.fromRGB(242, 247, 254)

local function create(className, parent, properties)
    local instance = Instance.new(className)
    for key, value in pairs(properties) do
        instance[key] = value
    end
    instance.Parent = parent
    return instance
end

local function round(parent, radius)
    create("UICorner", parent, { CornerRadius = UDim.new(0, radius) })
end

local function text(parent, value, size, color, position, dimensions, bold)
    return create("TextLabel", parent, {
        BackgroundTransparency = 1, Text = value, TextSize = size, TextColor3 = color,
        Font = bold and Enum.Font.GothamBold or Enum.Font.Gotham,
        Position = position, Size = dimensions, TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
    })
end

local offset = UDim2.fromOffset
local panelWidth, foldedHeight = 302, 62
local bodyTop = 65
local gui = create("ScreenGui", player:WaitForChild("PlayerGui"), {
    Name = "MiningHUD", ResetOnSpawn = false,
})
local panel = create("Frame", gui, {
    Position = offset(12, 12), Size = offset(panelWidth, foldedHeight), BackgroundColor3 = ink, BorderSizePixel = 0,
})
round(panel, 14)
create("UIStroke", panel, { Color = slate, Thickness = 1.5 })
local scale = create("UIScale", panel, {})

text(panel, "Crystal Mining", 17, white, offset(14, 4), offset(172, 35), true)
local glance = text(panel, "", 13, gold, offset(14, 39), offset(274, 18), true)
local function button(parent, caption, position, size)
    local control = create("TextButton", parent, {
        Text = caption, Position = position, Size = size, BackgroundColor3 = slate,
        TextColor3 = white, TextSize = 14, Font = Enum.Font.GothamBold, BorderSizePixel = 0,
    })
    round(control, 8)
    return control
end

local collapse = button(panel, "Open", offset(241, 6), offset(48, 34))
local mute = button(panel, "Sound", offset(177, 6), offset(58, 34))
local muted = false
mute.Activated:Connect(function()
    muted = not muted
    mute.Text = muted and "Muted" or "Sound"
    mute.TextColor3 = muted and soft or mint
end)
local body = create("Frame", panel, {
    BackgroundTransparency = 1, Position = offset(12, bodyTop), Size = offset(278, 250), Visible = false,
})
local statusTab = button(body, "Status", offset(0, 0), offset(44, 30))
local forgeTab = button(body, "Tools", offset(47, 0), offset(44, 30))
local bagsTab = button(body, "Bags", offset(94, 0), offset(44, 30))
local ordersTab = button(body, "Orders", offset(141, 0), offset(44, 30))
local cratesTab = button(body, "Crates", offset(188, 0), offset(44, 30))
local cavesTab = button(body, "Caves", offset(235, 0), offset(43, 30))
for _, tab in ipairs({statusTab, forgeTab, bagsTab, ordersTab, cratesTab, cavesTab}) do
    tab.TextSize = 12
end
local status = create("Frame", body, {
    BackgroundTransparency = 1, Position = offset(0, 39), Size = offset(278, 224),
})
local function catalog(parent, top, height)
    local scroll = create("ScrollingFrame", parent, {
        Position = offset(0, top), Size = offset(278, height), BackgroundTransparency = 1,
        BorderSizePixel = 0, ScrollBarThickness = 4, ScrollBarImageColor3 = soft,
        ScrollingDirection = Enum.ScrollingDirection.Y, AutomaticCanvasSize = Enum.AutomaticSize.Y,
        CanvasSize = offset(0, 0), Visible = false,
    })
    create("UIListLayout", scroll, { Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder })
    return scroll
end
local forge = catalog(body, 39, 188)
local bags = catalog(body, 39, 188)
local oreSummary = create("Frame", bags, {
    LayoutOrder = -1, Size = UDim2.new(1, -8, 0, 114), BackgroundColor3 = slate, BorderSizePixel = 0,
})
round(oreSummary, 8)
text(oreSummary, "Ore in your bag", 13, white, offset(9, 3), offset(245, 20), true)
local oreList = text(oreSummary, "", 12, soft, offset(9, 24), offset(247, 38))
oreList.TextWrapped = true
oreList.TextTruncate = Enum.TextTruncate.None
local recipeInfo = text(oreSummary, "", 12, mint, offset(9, 65), offset(247, 44), true)
recipeInfo.TextWrapped = true
recipeInfo.TextTruncate = Enum.TextTruncate.None
local caves = catalog(body, 39, 208)
local compassInfo = text(caves, "", 12, mint, offset(0, 0), UDim2.new(1, -9, 0, 37), true)
compassInfo.LayoutOrder = 0
compassInfo.TextWrapped = true
compassInfo.TextTruncate = Enum.TextTruncate.None
local caveRows = {}
for index, entry in ipairs(config.Zones) do
    local row = create("Frame", caves, {
        LayoutOrder = index, Size = UDim2.new(1, -8, 0, 104), BackgroundColor3 = slate, BorderSizePixel = 0,
    })
    round(row, 8)
    text(row, entry.Name, 13, entry.Color, offset(9, 4), offset(247, 20), true)
    local state = text(row, "", 12, mint, offset(9, 26), offset(250, 18), true)
    local nextStep = text(row, "", 11, soft, offset(9, 46), offset(250, 28))
    nextStep.TextWrapped = true
    nextStep.TextTruncate = Enum.TextTruncate.None
    local specimen = text(row, "", 11, gold, offset(9, 77), offset(249, 20), true)
    caveRows[index] = { State = state, NextStep = nextStep, Specimen = specimen }
end
local collection = create("Frame", body, {
    BackgroundTransparency = 1, Position = offset(0, 39), Size = offset(278, 190), Visible = false,
})
local collectionNames = {"Pets", "Skins", "Auras"}
local equip = ReplicatedStorage:WaitForChild("EquipCollection")
local premiumRemote = ReplicatedStorage:WaitForChild("PremiumAction")
local function ownsItem(crate, index)
    if index == 0 then return true end
    local entry = config[crate.Pool][index]
    if entry.Premium then
        return config.owns(player:GetAttribute("PremiumRewards") or 0, entry.Premium)
    end
    return config.owns(player:GetAttribute(crate.Pool .. "Owned") or 0, index)
end
local collectionGroups = {}
for group, crate in ipairs(config.Crates) do
    local header = button(collection, collectionNames[group], offset((group - 1) * 70, 0), offset(66, 26))
    local scroll = catalog(collection, 57, 131)
    local about = text(scroll, "", 12, gold, offset(0, 0), offset(269, 22), true)
    about.LayoutOrder = -1
    about.Text = crate.Name .. " • " .. crate.Cost .. " coins in Meadow"
    local rows = {}
    for index = 0, #config[crate.Pool] do
        local row = button(scroll, "", offset(0, 0), UDim2.new(1, -8, 0, 38))
        row.LayoutOrder = index
        row.TextXAlignment = Enum.TextXAlignment.Left
        row.TextSize = 12
        create("UIPadding", row, { PaddingLeft = UDim.new(0, 9), PaddingRight = UDim.new(0, 9) })
        rows[index] = row
        row.Activated:Connect(function()
            if ownsItem(crate, index) then
                equip:FireServer(group, index)
            end
        end)
    end
    local price = text(collection, "", 12, soft, offset(0, 29), offset(278, 25))
    price.Text = "Earned coins only • duplicates refund 50% rounded down"
    collectionGroups[group] = { Header = header, Scroll = scroll, Rows = rows, Price = price }
end
local function showCollection(selected)
    for index, group in ipairs(collectionGroups) do
        local active = index == selected
        group.Scroll.Visible = active
        group.Price.Visible = active
        group.Header.TextColor3 = active and mint or white
    end
end
local premiumHeader = button(collection, "Premium", offset(210, 0), offset(68, 26))
local wallet = text(collection, "", 13, gold, offset(0, 29), offset(278, 25), true)
local premiumScroll = catalog(collection, 56, 132)
collectionGroups[4] = { Header = premiumHeader, Scroll = premiumScroll, Price = wallet }
local topUpButtons = {}
for index, pack in ipairs(config.StarshardProducts) do
    local row = button(premiumScroll, "", offset(0, 0), UDim2.new(1, -8, 0, 34))
    row.LayoutOrder = index - #config.StarshardProducts
    row.Visible = pack.ProductId > 0 or (index == 1 and config.StarshardProducts[2].ProductId <= 0)
    row.Activated:Connect(function()
        if pack.ProductId > 0 and player:GetAttribute("PremiumReady") then
            premiumRemote:FireServer("TopUp", index)
        end
    end)
    topUpButtons[index] = row
end
local premiumButtons = {}
for index, crate in ipairs(config.PremiumCrates) do
    local row = button(premiumScroll, "", offset(0, 0), UDim2.new(1, -8, 0, 49))
    row.TextSize = 12
    row.TextWrapped = true
    row.LayoutOrder = index
    row.Activated:Connect(function()
        if player:GetAttribute("PremiumReady") and not config.owns(player:GetAttribute("PremiumRewards") or 0, index) then
            premiumRemote:FireServer("Open", index)
        end
    end)
    premiumButtons[index] = row
end
showCollection(1)
for index, group in ipairs(collectionGroups) do
    group.Header.Activated:Connect(function() showCollection(index) end)
end
local orders = create("Frame", body, {
    BackgroundTransparency = 1, Position = offset(0, 39), Size = offset(278, 190), Visible = false,
})
local orderTitle = text(orders, "", 16, mint, offset(0, 0), offset(278, 25), true)
local orderZone = text(orders, "", 13, soft, offset(0, 28), offset(278, 22))
local orderNodes = text(orders, "", 13, white, offset(0, 53), offset(278, 23))
local orderSales = text(orders, "", 13, white, offset(0, 79), offset(278, 23))
local orderReward = text(orders, "", 14, gold, offset(0, 108), offset(278, 23), true)
local orderHint = text(orders, "", 13, mint, offset(0, 137), offset(278, 36))
orderHint.TextWrapped = true
orderHint.TextTruncate = Enum.TextTruncate.None

local zone = text(status, "", 14, white, offset(0, 0), offset(278, 20), true)
local satchel = text(status, "", 16, white, offset(0, 25), offset(278, 24), true)
local bag = text(status, "", 13, soft, offset(0, 54), offset(278, 17))
local track = create("Frame", status, {
    Position = offset(0, 77), Size = offset(278, 8), BorderSizePixel = 0, BackgroundColor3 = slate,
})
round(track, 4)
local fill = create("Frame", track, { Size = UDim2.fromScale(0, 1), BackgroundColor3 = mint, BorderSizePixel = 0 })
round(fill, 4)
local pickLabel = text(status, "", 13, white, offset(0, 95), offset(278, 19), true)
local nextPick = text(status, "", 12, soft, offset(0, 118), offset(278, 17))
local petLabel = text(status, "", 12, soft, offset(0, 141), offset(278, 17))
local progress = text(status, "", 12, soft, offset(0, 164), offset(278, 17))

local guideCard = create("Frame", status, {
    Position = offset(0, 184), Size = offset(278, 38), BackgroundColor3 = slate, BorderSizePixel = 0,
    Visible = false,
})
round(guideCard, 8)
local guide = text(guideCard, "", 12, mint, offset(10, 0), offset(258, 38), true)
guide.TextWrapped = true
guide.TextTruncate = Enum.TextTruncate.None
local trail = create("BillboardGui", gui, {
    Name = "MeadowWaypoint", Size = offset(210, 36), StudsOffsetWorldSpace = Vector3.new(0, 7, 0),
    AlwaysOnTop = true, MaxDistance = 115, Enabled = false,
})
local trailLabel = text(trail, "", 13, mint, offset(0, 0), UDim2.fromScale(1, 1), true)
trailLabel.TextXAlignment = Enum.TextXAlignment.Center
trailLabel.TextWrapped = true
trailLabel.TextTruncate = Enum.TextTruncate.None
trailLabel.BackgroundColor3 = ink
trailLabel.BackgroundTransparency = .1
round(trailLabel, 8)
local descentTracker = text(gui, "", 13, gold, UDim2.new(.5, 0, 1, -135), offset(251, 46), true)
descentTracker.AnchorPoint = Vector2.new(.5, 1)
descentTracker.TextXAlignment = Enum.TextXAlignment.Center
descentTracker.BackgroundColor3 = ink
descentTracker.BackgroundTransparency = .1
descentTracker.TextWrapped = true
descentTracker.TextTruncate = Enum.TextTruncate.None
descentTracker.Visible = false
round(descentTracker, 8)
local function refreshDescentTimer()
    local deadline = player:GetAttribute("DescentDeadline") or 0
    descentTracker.Visible = deadline > workspace:GetServerTimeNow()
    if not descentTracker.Visible then return end
    task.spawn(function()
        while player:GetAttribute("DescentDeadline") == deadline do
            local seconds = math.ceil(deadline - workspace:GetServerTimeNow())
            if seconds <= 0 then
                descentTracker.Visible = false
                return
            end
            local stage = player:GetAttribute("DescentStage")
            local count = player:GetAttribute("DescentCount") or 0
            local goal = if stage == 2 then "Bank the haul or press on"
                elseif stage == 4 then "Claim the Heartstone cache"
                elseif stage == 3 then (count == 2 and "Extract a seam yourself" or "Heartstone seams " .. count .. "/2")
                else (count == 2 and "Log a stake yourself" or "Survey stakes " .. count .. "/2")
            descentTracker.Text = "Heartstone Descent  •  " .. seconds .. "s\n" .. goal
            task.wait(.25)
        end
    end)
end
player:GetAttributeChangedSignal("DescentDeadline"):Connect(refreshDescentTimer)
refreshDescentTimer()

local chainTracker = text(gui, "", 13, gold, UDim2.new(1, -12, 0, 96), offset(166, 31), true)
chainTracker.AnchorPoint = Vector2.new(1, 0)
chainTracker.TextXAlignment = Enum.TextXAlignment.Center
chainTracker.BackgroundColor3 = ink
chainTracker.BackgroundTransparency = .1
chainTracker.Visible = false
round(chainTracker, 8)
local function refreshChainTimer()
    local deadline = player:GetAttribute("VeinChainDeadline") or 0
    chainTracker.Visible = deadline > workspace:GetServerTimeNow()
    if not chainTracker.Visible then return end
    task.spawn(function()
        while player:GetAttribute("VeinChainDeadline") == deadline do
            local timeLeft = math.max(0, math.ceil(deadline - workspace:GetServerTimeNow()))
            if timeLeft == 0 then
                chainTracker.Visible = false
                return
            end
            local progress = player:GetAttribute("VeinChainCount") or 0
            chainTracker.Text = string.format("Vein chain %d/%d  •  %ds", progress, config.GeodeHunt.Chain, timeLeft)
            task.wait(.25)
        end
    end)
end
player:GetAttributeChangedSignal("VeinChainDeadline"):Connect(refreshChainTimer)
refreshChainTimer()

local relayTimer = text(gui, "", 14, mint, UDim2.new(1, -12, 0, 56), offset(166, 34), true)
relayTimer.AnchorPoint = Vector2.new(1, 0)
relayTimer.TextXAlignment = Enum.TextXAlignment.Center
relayTimer.BackgroundColor3 = ink
relayTimer.BackgroundTransparency = .1
relayTimer.Visible = false
round(relayTimer, 8)
local function refreshRelayTimer()
    local deadline = player:GetAttribute("RelayDeadline") or 0
    relayTimer.Visible = deadline > 0
    if deadline == 0 then return end
    task.spawn(function()
        while player:GetAttribute("RelayDeadline") == deadline do
            local seconds = math.max(0, math.ceil(deadline - workspace:GetServerTimeNow()))
            local stop = player:GetAttribute("RelayStop") or 1
            relayTimer.Text = string.format("Relay %d/%d  •  %ds", math.max(0, stop - 1), #config.Whiteout.Route, seconds)
            relayTimer.TextColor3 = seconds <= 15 and gold or mint
            if seconds == 0 then return end
            task.wait(.25)
        end
    end)
end
player:GetAttributeChangedSignal("RelayDeadline"):Connect(refreshRelayTimer)
refreshRelayTimer()

local heatPanel = create("Frame", gui, {
    AnchorPoint = Vector2.new(.5, 1), Position = UDim2.new(.5, 0, 1, -137),
    Size = offset(246, 69), BackgroundColor3 = ink, BorderSizePixel = 0, Visible = false,
})
round(heatPanel, 10)
create("UIStroke", heatPanel, { Color = slate, Thickness = 1.5 })
local heatTitle = text(heatPanel, "", 14, gold, offset(12, 5), offset(222, 20), true)
local heatTrack = create("Frame", heatPanel, {
    Position = offset(12, 31), Size = offset(222, 10), BorderSizePixel = 0, BackgroundColor3 = slate,
})
round(heatTrack, 4)
local successBand = create("Frame", heatTrack, {
    BorderSizePixel = 0, BackgroundColor3 = Color3.fromRGB(80, 173, 151),
})
round(successBand, 4)
local heatCursor = create("Frame", heatTrack, {
    AnchorPoint = Vector2.new(.5, .5), Size = offset(4, 16), BorderSizePixel = 0, BackgroundColor3 = white,
})
round(heatCursor, 2)
local heatHint = text(heatPanel, "", 12, soft, offset(12, 46), offset(222, 16), true)

local heatConnection
local function updateTempering()
    local index = player:GetAttribute("EmberStage") or 0
    local stage = config.Emberheart.Stages[index]
    heatPanel.Visible = stage ~= nil
    if heatConnection then
        heatConnection:Disconnect()
        heatConnection = nil
    end
    if not stage then return end

    heatTitle.Text = string.format("%s  •  %d/%d", stage.Name, index, #config.Emberheart.Stages)
    successBand.Position = UDim2.fromScale(stage.Low, 0)
    successBand.Size = UDim2.fromScale(stage.High - stage.Low, 1)
    local function renderHeat()
        local epoch = player:GetAttribute("EmberEpoch") or workspace:GetServerTimeNow()
        local heat = config.emberHeat(workspace:GetServerTimeNow() - epoch, stage.Period)
        local ready = heat >= stage.Low and heat <= stage.High
        heatCursor.Position = UDim2.fromScale(heat, .5)
        heatCursor.BackgroundColor3 = ready and gold or white
        heatHint.Text = ready and "Strike now!" or "Wait for the highlighted band"
        heatHint.TextColor3 = ready and gold or soft
    end
    renderHeat()
    heatConnection = RunService.RenderStepped:Connect(renderHeat)
end
player:GetAttributeChangedSignal("EmberStage"):Connect(updateTempering)
updateTempering()

local richTag = "SurveyorRichOre"
local oreMarkers = {}
local function removeOreMarker(ore)
    if not oreMarkers[ore] then return end
    oreMarkers[ore]:Destroy()
    oreMarkers[ore] = nil
end
local function addOreMarker(ore)
    if not ore:IsA("BasePart") or oreMarkers[ore] or player:GetAttribute("SurveyorLantern") ~= 1 then return end
    local marker = create("BillboardGui", gui, {
        Name = "SurveyorMarker", Adornee = ore, Size = offset(108, 24),
        StudsOffsetWorldSpace = Vector3.new(0, 6.4, 0), MaxDistance = config.SurveyorLantern.Range,
    })
    local caption = text(marker, "◆  Rich vein", 12, gold, offset(0, 0), UDim2.fromScale(1, 1), true)
    caption.TextXAlignment = Enum.TextXAlignment.Center
    caption.BackgroundColor3 = ink
    caption.BackgroundTransparency = .18
    round(caption, 7)
    oreMarkers[ore] = marker
end
local function refreshOreMarkers()
    if player:GetAttribute("SurveyorLantern") == 1 then
        for _, ore in ipairs(CollectionService:GetTagged(richTag)) do addOreMarker(ore) end
    else
        for ore in pairs(oreMarkers) do removeOreMarker(ore) end
    end
end
CollectionService:GetInstanceAddedSignal(richTag):Connect(addOreMarker)
CollectionService:GetInstanceRemovedSignal(richTag):Connect(removeOreMarker)
player:GetAttributeChangedSignal("SurveyorLantern"):Connect(refreshOreMarkers)
refreshOreMarkers()

local waypointName
local function refreshWaypoint()
    local world = workspace:FindFirstChild("CrystalWorld")
    local target
    if world and waypointName then
        if waypointName == "Mine Entrance" then
            local meadow = world:FindFirstChild("Meadow")
            target = meadow and meadow:FindFirstChild(waypointName, true)
        else
            local frozen = world:FindFirstChild(config.Zones[config.Whiteout.Zone].Name)
            target = world:FindFirstChild(waypointName) or (frozen and frozen:FindFirstChild(waypointName))
        end
    end
    trail.Adornee = target
    trail.Enabled = target ~= nil
end
workspace.DescendantAdded:Connect(function(instance)
    if waypointName and instance.Name == waypointName then
        task.defer(refreshWaypoint)
    end
end)

local function catalogRow(parent, index, name, description)
    local row = create("Frame", parent, {
        LayoutOrder = index, Size = UDim2.new(1, -8, 0, 44), BackgroundColor3 = slate, BorderSizePixel = 0,
    })
    round(row, 8)
    text(row, name, 13, white, offset(9, 3), offset(155, 20), true)
    text(row, description, 11, soft, offset(9, 23), offset(150, 15))
    local caption = text(row, "", 11, soft, offset(155, 0), offset(106, 44), true)
    caption.TextXAlignment = Enum.TextXAlignment.Right
    return caption
end
local rows, bagRows = {}, {}
for index, pick in ipairs(config.Picks) do
    rows[index] = catalogRow(forge, index, pick.Name .. " Pickaxe", pick.Power .. " mining power")
end
for index, upgrade in ipairs(config.Bags) do
    bagRows[index] = catalogRow(bags, index, upgrade.Name, upgrade.Capacity .. " base capacity")
end

local toast = create("TextLabel", gui, {
    AnchorPoint = Vector2.new(.5, 1), Position = UDim2.new(.5, 0, 1, -83),
    Size = UDim2.new(.9, 0, 0, 42), BackgroundColor3 = ink, BackgroundTransparency = .06,
    TextColor3 = white, TextSize = 14, Font = Enum.Font.GothamBold, TextWrapped = true,
    Text = "", Visible = false,
})
round(toast, 10)
create("UISizeConstraint", toast, { MaxSize = Vector2.new(490, 42) })
create("UIPadding", toast, { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) })

local pages = {
    { statusTab, status }, { forgeTab, forge }, { bagsTab, bags }, { ordersTab, orders }, { cratesTab, collection }, { cavesTab, caves },
}
local function showPage(selected)
    for _, entry in ipairs(pages) do
        local active = entry == selected
        entry[1].TextColor3 = active and ink or white
        entry[1].BackgroundColor3 = active and mint or slate
        entry[2].Visible = active
    end
end
showPage(pages[1])
for _, entry in ipairs(pages) do
    entry[1].Activated:Connect(function() showPage(entry) end)
end
local pageTop = 39
local function setExpanded(expanded)
    body.Visible = expanded
    body.Size = offset(278, pageTop + 224)
    panel.Size = offset(panelWidth, expanded and bodyTop + pageTop + 234 or foldedHeight)
    collapse.Text = expanded and "Close" or "Open"
end
collapse.Activated:Connect(function() setExpanded(not body.Visible) end)

local function number(value)
    local grouped = tostring(value):reverse():gsub("(%d%d%d)", "%1,"):reverse()
    return grouped:gsub("^,", "")
end

local fillTween
local function refresh()
    local balanceReady = player:GetAttribute("PremiumReady")
    local premiumBalance = player:GetAttribute("Starshards") or 0
    local rewards = player:GetAttribute("PremiumRewards") or 0
    wallet.Text = balanceReady and (number(premiumBalance) .. " Starshards • Robux only") or "Starshard wallet unavailable"
    for index, row in ipairs(topUpButtons) do
        local pack = config.StarshardProducts[index]
        local enabled = balanceReady and pack.ProductId > 0
        row.Text = enabled and ("Buy " .. pack.Amount .. " Starshards with Robux") or "Robux top-ups unavailable"
        row.AutoButtonColor = enabled == true
        row.TextColor3 = enabled and mint or soft
    end
    for index, crate in ipairs(config.PremiumCrates) do
        local owned = config.owns(rewards, index)
        local row = premiumButtons[index]
        row.Text = crate.Name .. " • " .. (owned and "Owned" or crate.Cost .. " Starshards")
            .. "\nGuaranteed: " .. crate.Reward
        row.AutoButtonColor = balanceReady == true and not owned
        row.TextColor3 = owned and mint or white
    end
    for group, crate in ipairs(config.Crates) do
        local selected = player:GetAttribute(crate.Equipped) or 0
        for index = 0, #config[crate.Pool] do
            local row = collectionGroups[group].Rows[index]
            local entry = config[crate.Pool][index]
            local unlocked = ownsItem(crate, index)
            local label = entry and (entry.Name .. " • " .. (entry.Premium and "Premium" or entry.Expedition and "Expedition" or entry.Specimen and "Collection" or entry.Weight .. "%")) or "Default"
            if entry and entry.Bonus then label ..= " • +" .. entry.Bonus end
            row.Text = label .. (selected == index and unlocked and "   Equipped" or unlocked and "   Equip" or "   Locked")
            row.TextColor3 = selected == index and unlocked and mint or unlocked and white or soft
            row.AutoButtonColor = unlocked and selected ~= index
        end
    end
    local balance = player:GetAttribute("Coins") or 0
    local crystals = player:GetAttribute("Crystals") or 0
    local ores = {}
    local sorted = 0
    for index, area in ipairs(config.Zones) do
        local count = player:GetAttribute(config.oreKey(index)) or 0
        sorted += count
        if count > 0 then ores[#ores + 1] = area.Ore .. " " .. number(count) end
    end
    if crystals > sorted then ores[#ores + 1] = "Unsorted " .. number(crystals - sorted) end
    oreList.Text = #ores > 0 and table.concat(ores, "  •  ") or "Your bag is empty."
    local reserve = player:GetAttribute("AmethystReserve") or 0
    recipeInfo.Text = player:GetAttribute("SurveyorLantern") == 1 and "Surveyor’s Lantern equipped"
        or string.format("Lantern: %d/%d Amethyst set aside at the Meadow workbench", reserve, config.SurveyorLantern.Cost)
    local capacity = player:GetAttribute("Capacity") or 50
    local tier = player:GetAttribute("Pick") or 1
    local pick = config.Picks[tier]
    local upgrade = config.Picks[tier + 1]
    local unlocked = config.Zones[player:GetAttribute("Zone") or 1]
    local pet = config.Pets[player:GetAttribute("Pet") or 0]
    local rebirths = player:GetAttribute("Rebirths") or 0
    local discoveries = player:GetAttribute("Discoveries") or 0
    local auras = player:GetAttribute("AurasOwned") or 0
    local unlockedZone = player:GetAttribute("Zone") or 1
    local specimens = player:GetAttribute("Specimens") or 0
    local compass = config.GeodeCompass
    compassInfo.Text = player:GetAttribute("GeodeCompass") == 1
        and ("Geode Compass equipped • +" .. compass.ExtraSeconds .. "s per link")
        or ("Geode Compass • +" .. compass.ExtraSeconds .. "s per link • " .. compass.Cost .. " coins in Meadow")
    for index, row in ipairs(caveRows) do
        local geodes = player:GetAttribute("Geodes" .. index) or 0
        local sample = config.GeodeHunt.Specimens[index]
        local found = config.owns(specimens, index)
        row.Specimen.Text = (found and sample.Name or "Specimen undiscovered") .. "  •  " .. geodes .. " geodes"
        row.Specimen.TextColor3 = found and mint or gold
        local mastery = config.CaveMastery[index]
        local mined = player:GetAttribute("CaveNodes" .. index) or 0
        local rank, extra, surveyed, trial = config.caveRank(index, mined, discoveries, auras)
        local title = rank == 2 and "Master" or rank == 1 and "Prospector" or "Unranked"
        row.State.Text = title .. (extra > 0 and ("  •  +" .. extra .. " crystals per node here") or "")
        if index > unlockedZone then
            row.NextStep.Text = "Unlock this zone from the Meadow wayshrines."
        elseif rank == 2 and index == config.MasterExpedition.Zone then
            row.NextStep.Text = player:GetAttribute("HeartstoneTrophy") == 1
                and "Heartstone Trophy earned. Display it in Meadow."
                or "Master Expedition unlocked near the lower lift."
        elseif rank == 2 then
            row.NextStep.Text = "Mastery complete. This mine’s yield bonus is permanent."
        elseif rank == 0 then
            row.NextStep.Text = string.format("Prospector: mine %d/%d nodes.", mined, mastery.Prospect)
        else
            local requirements = {}
            if mined < mastery.Master then requirements[#requirements + 1] = string.format("ore %d/%d", mined, mastery.Master) end
            if not surveyed then requirements[#requirements + 1] = "survey the landmark" end
            if not trial then requirements[#requirements + 1] = "clear " .. mastery.Trial end
            row.NextStep.Text = "Master: " .. table.concat(requirements, " • ")
        end
    end
    local bagTier = player:GetAttribute("Bag") or 1
    local completed = player:GetAttribute("Orders") or 0
    local assignedZone = player:GetAttribute("OrderZone") or 0
    local nodes = player:GetAttribute("OrderNodes") or 0
    local sales = player:GetAttribute("OrderCrystals") or 0
    local orderLocation = assignedZone > 0 and assignedZone or (player:GetAttribute("Zone") or 1)
    local guided = player:GetAttribute("GuidedOrder") == 1
    local previewFirst = assignedZone == 0 and completed == 0 and orderLocation == 1 and rebirths == 0
    local title, nodeTarget, saleTarget, reward = config.commission(completed, orderLocation, guided or previewFirst)
    local destination, instruction
    if player:GetAttribute("Zone") ~= nil then
        destination, instruction = config.meadowGuide({
            Zone = player:GetAttribute("Zone"), Rebirths = rebirths, Pick = tier, Coins = balance,
            Crystals = crystals, Capacity = capacity, Orders = completed, OrderZone = assignedZone, OrderNodes = nodes,
            OrderCrystals = sales, GuidedOrder = guided and 1 or 0,
        })
    end
    local relayStop = config.Whiteout.Route[player:GetAttribute("RelayStop") or 0]
    if relayStop and (player:GetAttribute("RelayDeadline") or 0) > 0 then
        destination, instruction = relayStop.Name, relayStop.Hint
    end
    local tide = player:GetAttribute("TideSettings")
    if not instruction and tide then
        local readings = {}
        for index, dial in ipairs(config.Tidekeeper.Dials) do
            local symbol = config.Tidekeeper.Symbols[tonumber(tide:sub(index, index))]
            if symbol then
                local name = string.gsub(dial.Name, " Dial$", "")
                readings[#readings + 1] = name .. ": " .. symbol
            end
        end
        guide.Text = table.concat(readings, "   •   ")
    else
        guide.Text = instruction or ""
    end
    guideCard.Visible = guide.Text ~= ""
    trailLabel.Text = instruction or ""
    if waypointName ~= destination then
        waypointName = destination
        refreshWaypoint()
    end
    local readyToClaim = assignedZone > 0 and nodes >= nodeTarget and sales >= saleTarget
    orderTitle.Text = title
    orderZone.Text = config.Zones[orderLocation].Name .. "  •  " .. completed .. " completed"
    orderNodes.Text = nodeTarget > 0 and string.format("Mine nodes  %d / %d", nodes, nodeTarget) or ""
    orderSales.Text = saleTarget > 0 and string.format("Sell crystals  %d / %d", sales, saleTarget) or ""
    orderReward.Text = number(reward) .. " coin reward"
    orderHint.Text = assignedZone == 0 and "Accept at Guild Commissions in Meadow."
        or readyToClaim and "Ready to claim at Guild Commissions."
        or "Return to the guild when the objectives are complete."
    for index, caption in ipairs(bagRows) do
        caption.Text = index == bagTier and "Equipped" or index < bagTier and "Replaced"
            or number(config.Bags[index].Cost) .. " coins"
        local affordable = index == bagTier + 1 and balance >= config.Bags[index].Cost
        caption.TextColor3 = (index == bagTier or affordable) and mint or soft
    end
    local surveyCount = 0
    for index in ipairs(config.Zones) do
        if bit32.btest(discoveries, bit32.lshift(1, index - 1)) then surveyCount += 1 end
    end

    zone.Text = "Unlocked through " .. unlocked.Name
    zone.TextColor3 = unlocked.Color
    glance.Text = string.format("%s coins  •  Bag %s/%s", number(balance), number(crystals), number(capacity))
    glance.TextColor3 = crystals >= capacity and gold or mint
    satchel.Text = config.Bags[bagTier].Name
    bag.Text = crystals >= capacity and "Bag full · sell at the market" or "Bag capacity"
    fill.BackgroundColor3 = crystals >= capacity and gold or mint
    if fillTween then fillTween:Cancel() end
    fillTween = TweenService:Create(fill, TweenInfo.new(.18), {
        Size = UDim2.fromScale(math.clamp(crystals / math.max(1, capacity), 0, 1), 1),
    })
    fillTween:Play()
    pickLabel.Text = pick.Name .. " Pickaxe  •  " .. pick.Power .. " power"
    nextPick.Text = upgrade and ("Forge " .. upgrade.Name .. " for " .. number(upgrade.Cost) .. " coins") or "Highest pickaxe tier forged"
    nextPick.TextColor3 = upgrade and balance >= upgrade.Cost and mint or soft
    petLabel.Text = pet and (pet.Name .. "  •  +" .. pet.Bonus .. " crystals per node") or "No pet equipped"
    progress.Text = string.format("Surveys %d/%d  •  Rebirths %s", surveyCount, #config.Zones, number(rebirths))
    for index, caption in ipairs(rows) do
        if index == tier then
            caption.Text = "In inventory"
            caption.TextColor3 = mint
        elseif index < tier then
            caption.Text = "Replaced"
            caption.TextColor3 = soft
        else
            caption.Text = number(config.Picks[index].Cost) .. " coins"
            caption.TextColor3 = index == tier + 1 and balance >= config.Picks[index].Cost and mint or soft
        end
    end
end

for _, attribute in ipairs({ "Coins", "Crystals", "Capacity", "Pick", "Zone", "Pet", "Rebirths", "Discoveries", "Bag", "Orders", "OrderZone", "OrderNodes", "OrderCrystals", "GuidedOrder",
    "PetsOwned", "SkinsOwned", "AurasOwned", "Skin", "Aura", "Starshards", "PremiumRewards", "PremiumReady", "RelayStop", "RelayDeadline", "TideSettings",
    "CaveNodes1", "CaveNodes2", "CaveNodes3", "CaveNodes4", "CaveNodes5",
    "Ore1", "Ore2", "Ore3", "Ore4", "Ore5", "SurveyorLantern", "AmethystReserve",
    "Geodes1", "Geodes2", "Geodes3", "Geodes4", "Geodes5", "Specimens", "GeodeCompass", "HeartstoneTrophy" }) do
    player:GetAttributeChangedSignal(attribute):Connect(refresh)
end
refresh()

local viewportConnection
local function watchCamera()
    if viewportConnection then viewportConnection:Disconnect() end
    local camera = workspace.CurrentCamera
    if not camera then return end
    local function layout()
        local viewport = camera.ViewportSize
        if viewport.X < 100 or viewport.Y < 100 then return end
        local compact = viewport.X < 560
        pageTop = compact and 87 or 39
        local openHeight = bodyTop + pageTop + 234
        scale.Scale = math.min(1, (viewport.X - 24) / panelWidth, (viewport.Y - 28) / openHeight)
        for index, entry in ipairs(pages) do
            local tab = entry[1]
            if compact then
                tab.Position = offset(((index - 1) % 3) * 94, math.floor((index - 1) / 3) * 42)
                tab.Size = offset(90, 38)
                tab.TextSize = 14
            else
                tab.Position = offset((index - 1) * 47, 0)
                tab.Size = offset(index == #pages and 43 or 44, 33)
                tab.TextSize = 12
            end
            entry[2].Position = offset(0, pageTop)
        end
        setExpanded(body.Visible)
    end
    viewportConnection = camera:GetPropertyChangedSignal("ViewportSize"):Connect(layout)
    layout()
end
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(watchCamera)
watchCamera()

local cues = {
    resonance1 = {"electronicpingshort.wav", .24, .83},
    resonance2 = {"electronicpingshort.wav", .24, 1.05},
    resonance3 = {"electronicpingshort.wav", .27, 1.32},
    hit = {"swordslash.wav", .13, 1.16},
    ["break"] = {"switch.wav", .24, .82},
    coins = {"electronicpingshort.wav", .19, 1.12},
    buy = {"electronicpingshort.wav", .2, 1.35},
    accept = {"switch.wav", .22, 1.1},
    reward = {"electronicpingshort.wav", .22, 1.5},
}
local sounds = {}
for key, cue in pairs(cues) do
    sounds[key] = create("Sound", SoundService, {
        Name = "Mining_" .. key, SoundId = "rbxasset://sounds/" .. cue[1],
        Volume = cue[2], PlaybackSpeed = cue[3],
    })
end

local dialogue = create("Frame", gui, {
    AnchorPoint = Vector2.new(.5, 1), Position = UDim2.new(.5, 0, 1, -83),
    Size = UDim2.new(.92, 0, 0, 112), BackgroundColor3 = ink, BorderSizePixel = 0, Visible = false,
})
round(dialogue, 12)
create("UISizeConstraint", dialogue, { MaxSize = Vector2.new(466, 112) })
create("UIStroke", dialogue, { Color = slate, Thickness = 1.5 })
local speaker = text(dialogue, "", 14, gold, offset(13, 9), UDim2.new(1, -57, 0, 23), true)
local dialogueLine = text(dialogue, "", 14, white, offset(13, 35), UDim2.new(1, -26, 0, 65))
dialogueLine.TextWrapped = true
dialogueLine.TextTruncate = Enum.TextTruncate.None
dialogueLine.TextYAlignment = Enum.TextYAlignment.Top
local closeDialogue = button(dialogue, "×", UDim2.new(1, -39, 0, 8), offset(31, 28))
local dialogueVersion = 0
closeDialogue.Activated:Connect(function()
    dialogueVersion += 1
    dialogue.Visible = false
end)

local toastVersion = 0
local toastTween
local toastEnd = UDim2.new(.5, 0, 1, -83)
ReplicatedStorage:WaitForChild("MiningAction").OnClientEvent:Connect(function(message, cue, name, role)
    if cue == "caves" then
        setExpanded(true)
        showPage(pages[6])
        return
    end
    if cue == "dialogue" then
        dialogueVersion += 1
        local version = dialogueVersion
        toast.Visible = false
        speaker.Text = name .. "  •  " .. role
        dialogueLine.Text = message
        dialogue.Visible = true
        task.delay(12, function()
            if version == dialogueVersion then dialogue.Visible = false end
        end)
        return
    end
    local sound = sounds[cue]
    if sound and not muted then
        sound.TimePosition = 0
        sound:Play()
    end
    if not message then return end
    dialogue.Visible = false
    toastVersion += 1
    local version = toastVersion
    if toastTween then toastTween:Cancel() end
    toast.Text = message
    toast.TextColor3 = cue == "reward" and gold or white
    toast.Position = toastEnd + offset(0, 12)
    toast.TextTransparency = 1
    toast.Visible = true
    toastTween = TweenService:Create(toast, TweenInfo.new(.18, Enum.EasingStyle.Quad), {
        Position = toastEnd, TextTransparency = 0,
    })
    toastTween:Play()
    task.delay(4, function()
        if version == toastVersion then toast.Visible = false end
    end)
end)
