local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local UserInputService = game:GetService("UserInputService")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ContextActionService = game:GetService("ContextActionService")
local GuiService = game:GetService("GuiService")

local player = Players.LocalPlayer
local config = require(ReplicatedStorage:WaitForChild("MiningConfig"))
local audio = require(ReplicatedStorage:WaitForChild("MiningAudio")).new(player, config.biomeAt)
require(ReplicatedStorage:WaitForChild("BiomeView")).start(player, workspace, config.biomeAt)
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

local mint = Color3.fromRGB(167, 227, 126)
local gold = Color3.fromRGB(255, 214, 129)
local ink = Color3.fromRGB(34, 38, 45)
local slate = Color3.fromRGB(60, 66, 75)
local soft = Color3.fromRGB(204, 210, 219)
local white = Color3.fromRGB(242, 247, 254)

local function create(className, parent, properties)
    local instance = Instance.new(className)
    for key, value in pairs(properties) do
        instance[key] = value
    end
    instance.Parent = parent
    return instance
end

local frameEdge = Color3.fromRGB(20, 23, 29)

local function outline(object)
    object.BorderColor3 = frameEdge
    object.BorderSizePixel = 1
end

local function text(parent, value, size, color, position, dimensions, bold)
    return create("TextLabel", parent, {
        BackgroundTransparency = 1, Text = value, TextSize = size, TextColor3 = color,
        Font = bold and Enum.Font.SourceSansBold or Enum.Font.SourceSans,
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
    Position = offset(12, 12), Size = offset(panelWidth, foldedHeight), BackgroundColor3 = ink,
    BackgroundTransparency = .43, BorderSizePixel = 0,
})
outline(panel)
create("Frame", panel, {
    Position = UDim2.fromOffset(1, 1), Size = offset(panelWidth - 2, 35), BorderSizePixel = 0,
    BackgroundColor3 = Color3.fromRGB(58, 64, 75), BackgroundTransparency = .34,
})
local scale = create("UIScale", panel, {})

text(panel, "CRYSTAL MINING", 17, white, offset(14, 4), offset(172, 35), true)
local glance = text(panel, "", 13, gold, offset(14, 39), offset(274, 18), true)
local nextObjective = text(panel, "", 12, soft, offset(14, 60), offset(274, 35), true)
nextObjective.TextWrapped = true
nextObjective.TextTruncate = Enum.TextTruncate.None
nextObjective.Visible = false
local function button(parent, caption, position, size)
    local control = create("TextButton", parent, {
        Text = caption, Position = position, Size = size, BackgroundColor3 = slate,
        TextColor3 = white, TextSize = 14, Font = Enum.Font.SourceSansBold, BorderSizePixel = 0,
    })
    outline(control)
    return control
end

local collapse = button(panel, "Menu", offset(241, 6), offset(48, 34))
local mute = button(panel, "Sound", offset(177, 6), offset(58, 34))
local guideShortcut = button(panel, "Guide", offset(177, 6), offset(58, 34))
mute.Activated:Connect(function()
    audio:setEffects(not audio.Effects)
    mute.Text = audio.Effects and "Sound effects: On" or "Sound effects: Off"
    mute.TextColor3 = audio.Effects and mint or soft
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
local guideTab = button(body, "Guide", offset(240, 0), offset(38, 30))
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
    LayoutOrder = -1, Size = UDim2.new(1, -8, 0, 140), BackgroundColor3 = slate, BorderSizePixel = 0,
})
outline(oreSummary)
text(oreSummary, "Ore in your bag", 13, white, offset(9, 3), offset(245, 20), true)
local oreList = text(oreSummary, "", 12, soft, offset(9, 24), offset(247, 38))
oreList.TextWrapped = true
oreList.TextTruncate = Enum.TextTruncate.None
local recipeInfo = text(oreSummary, "", 12, mint, offset(9, 65), offset(247, 65), true)
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
    outline(row)
    text(row, entry.Name, 13, entry.Color, offset(9, 4), offset(247, 20), true)
    local state = text(row, "", 12, mint, offset(9, 26), offset(250, 18), true)
    local nextStep = text(row, "", 11, soft, offset(9, 46), offset(250, 28))
    nextStep.TextWrapped = true
    nextStep.TextTruncate = Enum.TextTruncate.None
    local specimen = text(row, "", 11, gold, offset(9, 77), offset(249, 20), true)
    caveRows[index] = { State = state, NextStep = nextStep, Specimen = specimen }
end
local fieldGuide = create("Frame", body, {
    BackgroundTransparency = 1, Position = offset(0, 39), Size = offset(278, 224), Visible = false,
})
local guideTabs, guidePages = {}, {}
for index, caption in ipairs({"Start", "Atlas", "Display"}) do
    guideTabs[index] = button(fieldGuide, caption, offset((index - 1) * 94, 0), offset(90, 30))
    guidePages[index] = catalog(fieldGuide, 39, 178)
end
local function showGuide(index)
    for i, page in ipairs(guidePages) do
        page.Visible = i == index
        guideTabs[i].TextColor3 = i == index and mint or white
    end
end
showGuide(1)
for i, tab in ipairs(guideTabs) do
    tab.Activated:Connect(function() showGuide(i) end)
end

local diagrams = {
    {"Mine", "Take the free Meadow Mine portal. Use Mine or swing your pickaxe at ore.", "crystal"},
    {"Sell", "Trade ore for coins at the gold counter in Miners’ Services, left of Meadow’s main path.", "coins"},
    {"Forge", "Buy Iron at the blue forge for faster swings. Your first upgrade earns a 20-coin kit.", "pick"},
    {"Explore", "Unlock zones at the Meadow wayshrines. Check the Atlas for each cave’s rewards.", "portal"},
}
local function illustration(parent, kind)
    local viewport = create("ViewportFrame", parent, {
        Position = offset(7, 12), Size = offset(70, 61), BackgroundColor3 = ink,
        BorderSizePixel = 0, Ambient = Color3.fromRGB(185, 205, 201), LightColor = white,
        LightDirection = Vector3.new(-1, -1, -.5),
    })
    outline(viewport)
    local camera = create("Camera", viewport, {
        CFrame = CFrame.lookAt(Vector3.new(3.3, 2.4, 4.5), Vector3.new(0, 0, 0)), FieldOfView = 37,
    })
    viewport.CurrentCamera = camera
    local function shape(size, frame, color, style)
        local part = create("Part", viewport, {
            Size = size, CFrame = frame, Anchored = true, Color = color, Material = Enum.Material.SmoothPlastic,
        })
        if style then part.Shape = style end
    end
    if kind == "crystal" then
        for index = -1, 1 do
            shape(Vector3.new(.45, 1.4 - math.abs(index) * .42, .48),
                CFrame.new(index * .53, -.18, 0) * CFrame.Angles(0, .43, index * -.42), mint)
        end
    elseif kind == "coins" then
        for index = 0, 2 do
            shape(Vector3.new(.16, 1.16, 1.16),
                CFrame.new(index * .07, -.43 + index * .17, 0) * CFrame.Angles(0, 0, math.pi / 2),
                gold, Enum.PartType.Cylinder)
        end
        shape(Vector3.new(.14, .92, .92), CFrame.new(.52, .27, 0) * CFrame.Angles(0, .5, -.4),
            gold, Enum.PartType.Cylinder)
    elseif kind == "pick" then
        shape(Vector3.new(.22, 1.7, .24), CFrame.Angles(0, 0, -.34), Color3.fromRGB(146, 99, 62))
        shape(Vector3.new(1.38, .32, .31), CFrame.new(.29, .75, 0) * CFrame.Angles(0, 0, -.34), mint)
    else
        local frame = Color3.fromRGB(143, 119, 208)
        shape(Vector3.new(.29, 1.7, .36), CFrame.new(-.65, 0, 0), frame)
        shape(Vector3.new(.29, 1.7, .36), CFrame.new(.65, 0, 0), frame)
        shape(Vector3.new(1.6, .25, .36), CFrame.new(0, .83, 0), gold)
        shape(Vector3.new(1.19, 1.41, .09), CFrame.new(0, 0, .02), frame)
    end
    return viewport
end
for index, step in ipairs(diagrams) do
    local card = create("Frame", guidePages[1], {
        LayoutOrder = index, Size = UDim2.new(1, -8, 0, 84), BackgroundColor3 = slate, BorderSizePixel = 0,
    })
    outline(card)
    illustration(card, step[3])
    text(card, step[1], 14, white, offset(85, 7), offset(172, 22), true)
    local description = text(card, step[2], 12, soft, offset(85, 29), offset(173, 49))
    description.TextWrapped = true
    description.TextTruncate = Enum.TextTruncate.None
end

local welcomeScale
do
    local welcomeRemote = ReplicatedStorage:WaitForChild("DismissWelcome")
    local welcome = create("ScreenGui", gui.Parent, {
        Name = "MeadowWelcomeScreen", ResetOnSpawn = false, DisplayOrder = 20, Enabled = false,
        IgnoreGuiInset = true,
    })
    local shade = create("TextButton", welcome, {
        Name = "WelcomeScrim", Text = "", Modal = true, Selectable = false, AutoButtonColor = false,
        Size = UDim2.fromScale(1, 1), BorderSizePixel = 0, BackgroundColor3 = Color3.fromRGB(11, 16, 21),
        BackgroundTransparency = .23,
    })
    local card = create("Frame", shade, {
        Name = "WelcomePanel", AnchorPoint = Vector2.new(.5, .5), Position = UDim2.fromScale(.5, .5),
        Size = offset(424, 322), BackgroundColor3 = ink, Active = true,
    })
    outline(card)
    welcomeScale = create("UIScale", card, {})
    create("Frame", card, {
        Position = offset(1, 1), Size = offset(422, 55), BorderSizePixel = 0,
        BackgroundColor3 = slate,
    })
    text(card, "WELCOME TO MEADOW", 25, white, offset(14, 6), offset(395, 37), true)
    text(card, "CRYSTAL MINING SIMULATOR", 12, mint, offset(15, 39), offset(394, 16), true)
    text(card, "Fill your bag, sell the haul, and gear up for deeper caves.", 16, white,
        offset(15, 66), offset(394, 22))

    local steps = {
        {"1. Mine", "Take the free Meadow Mine portal. Walk up to ore to mine.", "crystal"},
        {"2. Sell", "Trade your haul at the gold stall in Meadow.", "coins"},
        {"3. Forge", "Buy Iron at the blue forge, then save for Amethyst Cavern.", "pick"},
    }
    for index, step in ipairs(steps) do
        local tile = create("Frame", card, {
            Name = step[3] .. " Step", Position = offset(14 + (index - 1) * 134, 97),
            Size = offset(128, 137), BackgroundColor3 = slate,
        })
        outline(tile)
        local view = illustration(tile, step[3])
        view.Size, view.Position = offset(110, 65), offset(9, 6)
        text(tile, step[1], 16, gold, offset(8, 74), offset(112, 19), true)
        local details = text(tile, step[2], 13, soft, offset(8, 93), offset(112, 39))
        details.TextWrapped = true
        details.TextTruncate = Enum.TextTruncate.None
        details.TextYAlignment = Enum.TextYAlignment.Top
    end
    local firstStop = text(card, "First stop: Guild Commissions. Follow the trail marker.", 14, mint,
        offset(14, 244), offset(395, 25), true)
    firstStop.TextWrapped = true
    local start = button(card, "Start Mining", offset(132, 274), offset(160, 36))
    start.Name = "StartMining"
    start.BackgroundColor3 = mint
    start.TextColor3 = ink
    start.TextSize = 18

    local dismissed = false
    local function showWelcome(show)
        if welcome.Enabled == show then return end
        welcome.Enabled = show
        if show then
            ContextActionService:BindActionAtPriority("MeadowWelcomeMovement", function()
                return Enum.ContextActionResult.Sink
            end, false, Enum.ContextActionPriority.High.Value + 1,
                Enum.PlayerActions.CharacterForward, Enum.PlayerActions.CharacterBackward,
                Enum.PlayerActions.CharacterLeft, Enum.PlayerActions.CharacterRight, Enum.PlayerActions.CharacterJump)
            if UserInputService:GetLastInputType().Name:match("^Gamepad") then GuiService.SelectedObject = start end
        else
            ContextActionService:UnbindAction("MeadowWelcomeMovement")
            if GuiService.SelectedObject == start then GuiService.SelectedObject = nil end
        end
    end

    local function updateWelcome()
        showWelcome(not dismissed and player:GetAttribute("WelcomeSeen") == 0)
    end
    start.Activated:Connect(function()
        dismissed = true
        showWelcome(false)
        welcomeRemote:FireServer()
    end)
    player:GetAttributeChangedSignal("WelcomeSeen"):Connect(updateWelcome)
    updateWelcome()
end

local returnRemote = ReplicatedStorage:WaitForChild("ReturnToMeadow")
local home = button(guidePages[2], "Return to Meadow", offset(0, 0), UDim2.new(1, -8, 0, 32))
home.LayoutOrder = 0
home.Visible = false
home.Activated:Connect(function()
    if home.Visible then returnRemote:FireServer() end
end)
local atlasRows = {}
for index, zone in ipairs(config.Zones) do
    local row = create("Frame", guidePages[2], {
        LayoutOrder = index, Size = UDim2.new(1, -8, 0, 70), BackgroundColor3 = slate, BorderSizePixel = 0,
    })
    outline(row)
    text(row, index == 1 and "Meadow Mine" or zone.Name, 13, zone.Color, offset(9, 3), offset(250, 21), true)
    text(row, zone.Ore .. "  •  " .. (config.CaveMastery[index].Trial or "First Haul"),
        11, soft, offset(9, 24), offset(249, 18))
    atlasRows[index] = text(row, "", 12, mint, offset(9, 43), offset(249, 20), true)
end

mute.Parent = guidePages[3]
mute.Size = UDim2.new(1, -8, 0, 36)
mute.LayoutOrder = 2
mute.Text = "Sound effects: On"
local music = button(guidePages[3], "Music: On", offset(0, 0), UDim2.new(1, -8, 0, 36))
music.LayoutOrder = 3
music.Activated:Connect(function()
    audio:setMusic(not audio.Music)
    music.Text = audio.Music and "Music: On" or "Music: Off"
    music.TextColor3 = audio.Music and mint or soft
end)
local labelsVisible = true
local labels = button(guidePages[3], "Floating names: On", offset(0, 0), UDim2.new(1, -8, 0, 36))
local displayNote = text(guidePages[3], "Hide floating names for this session. Signs, waypoints, and prompts stay visible.",
    12, soft, offset(0, 0), UDim2.new(1, -9, 0, 49))
displayNote.LayoutOrder = 1
displayNote.TextWrapped = true
displayNote.TextTruncate = Enum.TextTruncate.None
local function showWorldLabel(label) label.Enabled = labelsVisible end
labels.Activated:Connect(function()
    labelsVisible = not labelsVisible
    labels.Text = labelsVisible and "Floating names: On" or "Floating names: Off"
    for _, label in ipairs(CollectionService:GetTagged("MiningWorldLabel")) do showWorldLabel(label) end
end)
CollectionService:GetInstanceAddedSignal("MiningWorldLabel"):Connect(showWorldLabel)

local collection = create("Frame", body, {
    BackgroundTransparency = 1, Position = offset(0, 39), Size = offset(278, 190), Visible = false,
})
local collectionNames = {"Pets", "Skins", "Auras"}
local equip = ReplicatedStorage:WaitForChild("EquipCollection")
local premiumRemote = ReplicatedStorage:WaitForChild("PremiumAction")
local function ownsItem(crate, index)
    if index == 0 then return true end
    local entry = config[crate.Pool][index]
    if entry.Pass then return player:GetAttribute("PassOwned" .. entry.Pass) == true end
    if entry.Premium then
        return config.owns(player:GetAttribute("PremiumRewards") or 0, entry.Premium)
    end
    return config.owns(player:GetAttribute(crate.Pool .. "Owned") or 0, index)
end
local collectionGroups = {}
for group, crate in ipairs(config.Crates) do
    local header = button(collection, collectionNames[group], offset((group - 1) * 56, 0), offset(53, 26))
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
local premiumHeader = button(collection, "Shards", offset(168, 0), offset(53, 26))
local wallet = text(collection, "", 13, gold, offset(0, 29), offset(278, 25), true)
local premiumScroll = catalog(collection, 56, 132)
collectionGroups[4] = { Header = premiumHeader, Scroll = premiumScroll, Price = wallet }
local topUpButtons = {}
for index, pack in ipairs(config.StarshardProducts) do
    local row = button(premiumScroll, "", offset(0, 0), UDim2.new(1, -8, 0, 34))
    row.LayoutOrder = index - #config.StarshardProducts
    row.Activated:Connect(function()
        if config.StarshardSalesEnabled and pack.ProductId > 0 and player:GetAttribute("PremiumReady") then
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
        if config.StarshardSalesEnabled and player:GetAttribute("PremiumReady")
            and not config.owns(player:GetAttribute("PremiumRewards") or 0, index) then
            premiumRemote:FireServer("Open", index)
        end
    end)
    premiumButtons[index] = row
end
local passesHeader = button(collection, "Passes", offset(224, 0), offset(54, 26))
local passInfo = text(collection, config.GamePassSalesEnabled and "Permanent cosmetics • Roblox shows the Robux price"
    or "Gamepasses (in development)", 12,
    soft, offset(0, 29), offset(278, 25))
local passScroll = catalog(collection, 56, 132)
collectionGroups[5] = { Header = passesHeader, Scroll = passScroll, Price = passInfo }
local passButtons = {}
for index, pass in ipairs(config.GamePasses) do
    local row = create("Frame", passScroll, {
        LayoutOrder = index, Size = UDim2.new(1, -8, 0, 95), BackgroundColor3 = slate, BorderSizePixel = 0,
    })
    outline(row)
    local title = pass.Name .. (config.GamePassSalesEnabled and "" or " (in development)")
    text(row, title, 14, white, offset(9, 5), offset(199, 20), true)
    for slot, pool in ipairs({config.Skins, config.Auras}) do
        for _, item in ipairs(pool) do
            if item.Pass == index then
                local swatch = create("Frame", row, {
                    Position = offset(204 + slot * 15, 9), Size = offset(11, 11),
                    BackgroundColor3 = item.Color, BorderSizePixel = 0,
                })
                outline(swatch)
                break
            end
        end
    end
    local contents = text(row, pass.Finish .. " finish • " .. pass.Aura .. " aura", 11, soft,
        offset(9, 26), offset(249, 29))
    contents.TextWrapped = true
    contents.TextTruncate = Enum.TextTruncate.None
    local purchase = button(row, "", offset(9, 59), offset(241, 28))
    purchase.TextSize = 12
    purchase.Activated:Connect(function()
        if config.GamePassSalesEnabled and pass.Id > 0 and player:GetAttribute("PassOwned" .. index) ~= true then
            premiumRemote:FireServer("Pass", index)
        end
    end)
    passButtons[index] = purchase
end
for _, group in ipairs(collectionGroups) do group.Header.TextSize = 12 end
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
outline(track)
local fill = create("Frame", track, { Size = UDim2.fromScale(0, 1), BackgroundColor3 = mint, BorderSizePixel = 0 })
local pickLabel = text(status, "", 13, white, offset(0, 95), offset(278, 19), true)
local nextPick = text(status, "", 12, soft, offset(0, 118), offset(278, 17))
local petLabel = text(status, "", 12, soft, offset(0, 141), offset(278, 17))
local progress = text(status, "", 12, soft, offset(0, 164), offset(278, 17))

local guideCard = create("Frame", status, {
    Position = offset(0, 184), Size = offset(278, 38), BackgroundColor3 = slate, BorderSizePixel = 0,
    Visible = false,
})
outline(guideCard)
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
outline(trailLabel)
do
    local travelCard = create("Frame", gui, {
        Name = "TeleporterStatus", AnchorPoint = Vector2.new(.5, 1), Position = UDim2.new(.5, 0, 1, -135),
        Size = offset(252, 56), BackgroundColor3 = ink, BackgroundTransparency = .14, Visible = false,
    })
    outline(travelCard)
    local title = text(travelCard, "", 15, white, offset(10, 3), offset(232, 21), true)
    title.Name = "Destination"
    local status = text(travelCard, "", 13, gold, offset(10, 25), offset(232, 28), true)
    status.Name = "Availability"
    status.TextWrapped = true
    status.TextTruncate = Enum.TextTruncate.None
    local shown
    local function refreshTravel()
        if not shown or not shown.Parent then return end
        local pad = shown.Parent
        local index = pad:GetAttribute("TravelDestination")
        local owned = player:GetAttribute("Zone") or 1
        local coins = player:GetAttribute("Coins") or 0
        local state, action, open = config.travelAvailability(index, owned, coins)
        title.Text = pad:GetAttribute("TravelTitle")
        status.Text, status.TextColor3 = state, open and mint or gold
        shown.ActionText = action
    end
    ProximityPromptService.PromptShown:Connect(function(prompt)
        if not prompt.Parent or prompt.Parent:GetAttribute("TravelDestination") == nil then return end
        shown = prompt
        refreshTravel()
        travelCard.Visible = true
    end)
    ProximityPromptService.PromptHidden:Connect(function(prompt)
        if shown ~= prompt then return end
        shown = nil
        travelCard.Visible = false
    end)
    player:GetAttributeChangedSignal("Zone"):Connect(refreshTravel)
    player:GetAttributeChangedSignal("Coins"):Connect(refreshTravel)
end

local oreFocus = create("Frame", gui, {
    AnchorPoint = Vector2.new(.5, 1), Position = UDim2.new(.5, 0, 1, -135),
    Size = offset(218, 51), BackgroundColor3 = ink, BorderSizePixel = 0, Visible = false,
})
outline(oreFocus)
local focusName = text(oreFocus, "", 12, white, offset(10, 4), offset(199, 20), true)
local focusTrack = create("Frame", oreFocus, {
    Position = offset(10, 31), Size = offset(198, 8), BackgroundColor3 = slate, BorderSizePixel = 0,
})
outline(focusTrack)
local focusFill = create("Frame", focusTrack, {
    Size = UDim2.fromScale(1, 1), BackgroundColor3 = mint, BorderSizePixel = 0,
})
local focusPrompt, healthConnection
local function clearOreFocus()
    if healthConnection then healthConnection:Disconnect(); healthConnection = nil end
    focusPrompt = nil
    oreFocus.Visible = false
end
ProximityPromptService.PromptShown:Connect(function(prompt)
    local ore = prompt.Parent
    if prompt.ActionText ~= "Mine" or not ore or not ore:GetAttribute("OreMaxHealth") then return end
    clearOreFocus()
    focusPrompt = prompt
    local function refreshHealth()
        local hp = ore:GetAttribute("OreHealth") or 0
        local maxHealth = ore:GetAttribute("OreMaxHealth")
        focusName.Text = (ore:GetAttribute("OreTitle") or "Crystal") .. "  •  " .. hp .. "/" .. maxHealth
        focusFill.Size = UDim2.fromScale(math.clamp(hp / maxHealth, 0, 1), 1)
        focusFill.BackgroundColor3 = hp <= maxHealth / 3 and gold or mint
        oreFocus.Visible = hp > 0
    end
    healthConnection = ore:GetAttributeChangedSignal("OreHealth"):Connect(refreshHealth)
    refreshHealth()
end)
ProximityPromptService.PromptHidden:Connect(function(prompt)
    if focusPrompt == prompt then clearOreFocus() end
end)

local descentTracker = text(gui, "", 13, gold, UDim2.new(.5, 0, 1, -135), offset(251, 46), true)
descentTracker.AnchorPoint = Vector2.new(.5, 1)
descentTracker.TextXAlignment = Enum.TextXAlignment.Center
descentTracker.BackgroundColor3 = ink
descentTracker.BackgroundTransparency = .1
descentTracker.TextWrapped = true
descentTracker.TextTruncate = Enum.TextTruncate.None
descentTracker.Visible = false
outline(descentTracker)
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
outline(chainTracker)
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
outline(relayTimer)
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
outline(heatPanel)
local heatTitle = text(heatPanel, "", 14, gold, offset(12, 5), offset(222, 20), true)
local heatTrack = create("Frame", heatPanel, {
    Position = offset(12, 31), Size = offset(222, 10), BorderSizePixel = 0, BackgroundColor3 = slate,
})
outline(heatTrack)
local successBand = create("Frame", heatTrack, {
    BorderSizePixel = 0, BackgroundColor3 = Color3.fromRGB(80, 173, 151),
})
local heatCursor = create("Frame", heatTrack, {
    AnchorPoint = Vector2.new(.5, .5), Size = offset(4, 16), BorderSizePixel = 0, BackgroundColor3 = white,
})
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
    outline(caption)
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

local waypointName, waypointInstruction
local function refreshWaypoint()
    local world = workspace:FindFirstChild("CrystalWorld")
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    local biome = root and config.biomeAt(root.Position.X)
    home.Visible = root ~= nil and biome ~= 1
    local target
    trailLabel.Text = waypointInstruction or ""
    if world and waypointName then
        local grounds = world:FindFirstChild("Meadow Mine Grounds")
        local zone = config.Zones[biome]
        local localArea = biome == config.StarterMineBiome and grounds or zone and world:FindFirstChild(zone.Name)
        if biome == config.StarterMineBiome and waypointName == "Mine Entrance" then
            target = grounds and grounds:FindFirstChild("Mine Entrance", true)
        elseif biome and biome ~= 1 then
            target = localArea and localArea:FindFirstChild(waypointName)
            if not target and localArea then
                target = localArea:FindFirstChild("Return to Meadow")
                trailLabel.Text = "Return to Meadow"
            end
        else
            target = world:FindFirstChild(waypointName == "Mine Entrance" and "Travel to Meadow Mine" or waypointName)
        end
    end
    trail.Adornee = target
    trail.Enabled = target ~= nil
end
workspace.DescendantAdded:Connect(function(instance)
    if waypointName and (instance.Name == waypointName or instance.Name == "Travel to Meadow Mine"
        or instance.Name == "Return to Meadow") then
        task.defer(refreshWaypoint)
    end
end)
player.CharacterAdded:Connect(function(character)
    if character:WaitForChild("HumanoidRootPart", 10) then refreshWaypoint() end
end)

local function catalogRow(parent, index, name, description)
    local row = create("Frame", parent, {
        LayoutOrder = index, Size = UDim2.new(1, -8, 0, 44), BackgroundColor3 = slate, BorderSizePixel = 0,
    })
    outline(row)
    text(row, name, 13, white, offset(9, 3), offset(155, 20), true)
    text(row, description, 11, soft, offset(9, 23), offset(150, 15))
    local caption = text(row, "", 11, soft, offset(155, 0), offset(106, 44), true)
    caption.TextXAlignment = Enum.TextXAlignment.Right
    return caption
end
local rows, bagRows = {}, {}
for index, pick in ipairs(config.Picks) do
    local stats = string.format("%d power • %.2fs per swing", pick.Power, pick.SwingCooldown)
    rows[index] = catalogRow(forge, index, pick.Name .. " Pickaxe", stats)
end
for index, upgrade in ipairs(config.Bags) do
    bagRows[index] = catalogRow(bags, index, upgrade.Name, upgrade.Capacity .. " base capacity")
end

local toast = create("TextLabel", gui, {
    AnchorPoint = Vector2.new(.5, 1), Position = UDim2.new(.5, 0, 1, -83),
    Size = UDim2.new(.9, 0, 0, 42), BackgroundColor3 = ink, BackgroundTransparency = .06,
    TextColor3 = white, TextSize = 14, Font = Enum.Font.SourceSansBold, TextWrapped = true,
    Text = "", Visible = false,
})
outline(toast)
create("UISizeConstraint", toast, { MaxSize = Vector2.new(490, 42) })
create("UIPadding", toast, { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) })

local pages = {
    { statusTab, status }, { forgeTab, forge }, { bagsTab, bags }, { ordersTab, orders }, { cratesTab, collection }, { cavesTab, caves }, { guideTab, fieldGuide },
}
local function showPage(selected)
    for _, entry in ipairs(pages) do
        local active = entry == selected
        entry[1].TextColor3 = active and ink or white
        entry[1].BackgroundColor3 = active and mint or slate
        entry[1].BackgroundTransparency = active and .16 or .32
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
    nextObjective.Visible = not expanded and nextObjective.Text ~= ""
    body.Size = offset(278, pageTop + 224)
    panel.Size = offset(panelWidth, expanded and bodyTop + pageTop + 234 or (nextObjective.Visible and 99 or foldedHeight))
    collapse.Text = expanded and "Close" or "Menu"
end
collapse.Activated:Connect(function() setExpanded(not body.Visible) end)
guideShortcut.Activated:Connect(function()
    setExpanded(true)
    showPage(pages[7])
    showGuide(1)
end)

local function number(value)
    local grouped = tostring(value):reverse():gsub("(%d%d%d)", "%1,"):reverse()
    return grouped:gsub("^,", "")
end

local fillTween
local function refresh()
    local balanceReady = player:GetAttribute("PremiumReady")
    local premiumBalance = player:GetAttribute("Starshards") or 0
    local rewards = player:GetAttribute("PremiumRewards") or 0
    wallet.Text = not config.StarshardSalesEnabled and "Starshards (in development)"
        or balanceReady and (number(premiumBalance) .. " Starshards • Robux only") or "Starshard wallet unavailable"
    for index, row in ipairs(topUpButtons) do
        local pack = config.StarshardProducts[index]
        local enabled = config.StarshardSalesEnabled and balanceReady and pack.ProductId > 0
        row.Text = not config.StarshardSalesEnabled and (pack.Amount .. " Starshards (in development)")
            or enabled and ("Buy " .. pack.Amount .. " Starshards with Robux") or (pack.Amount .. " Starshards unavailable")
        row.AutoButtonColor = enabled == true
        row.Selectable = enabled == true
        row.TextColor3 = enabled and mint or soft
    end
    for index, crate in ipairs(config.PremiumCrates) do
        local owned = config.owns(rewards, index)
        local row = premiumButtons[index]
        local state = owned and "Owned" or not config.StarshardSalesEnabled and "(in development)" or crate.Cost .. " Starshards"
        row.Text = crate.Name .. " • " .. state
            .. "\nGuaranteed: " .. crate.Reward
        row.AutoButtonColor = config.StarshardSalesEnabled and balanceReady == true and not owned
        row.Selectable = row.AutoButtonColor
        row.TextColor3 = owned and mint or white
    end
    for index, purchase in ipairs(passButtons) do
        local pass = config.GamePasses[index]
        local owned = player:GetAttribute("PassOwned" .. index) == true
        local enabled = config.GamePassSalesEnabled and pass.Id > 0
        purchase.Text = owned and "Owned • equip in Skins and Auras"
            or enabled and "View Roblox price" or "(in development)"
        purchase.AutoButtonColor = enabled and not owned
        purchase.Selectable = purchase.AutoButtonColor
        purchase.TextColor3 = owned and mint or enabled and white or soft
    end
    for group, crate in ipairs(config.Crates) do
        local selected = player:GetAttribute(crate.Equipped) or 0
        for index = 0, #config[crate.Pool] do
            local row = collectionGroups[group].Rows[index]
            local entry = config[crate.Pool][index]
            local unlocked = ownsItem(crate, index)
            local inDevelopment = entry and ((entry.Pass and not config.GamePassSalesEnabled)
                or (entry.Premium and not config.StarshardSalesEnabled))
            local label = entry and (entry.Name .. " • " .. (inDevelopment and "(in development)" or entry.Pass and "Pass"
                or entry.Premium and "Premium" or entry.Expedition and "Expedition" or entry.Specimen and "Collection" or entry.Weight .. "%")) or "Default"
            if entry and entry.Bonus then label ..= " • +" .. entry.Bonus end
            row.Text = label .. (selected == index and unlocked and "   Equipped" or unlocked and "   Equip"
                or inDevelopment and "" or "   Locked")
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
    local frostReserve = player:GetAttribute("FrostReserve") or 0
    recipeInfo.Text = player:GetAttribute("SurveyorLantern") == 1 and "Surveyor’s Lantern equipped"
        or string.format("Lantern: %d/%d Amethyst set aside at the Meadow workbench", reserve, config.SurveyorLantern.Cost)
    recipeInfo.Text ..= player:GetAttribute("FrostSeal") == 1 and "\nFrost Seal equipped • +35 capacity"
        or string.format("\nFrost Seal: %d/%d Frost Ore at the Meadow press", frostReserve, config.FrostSeal.Cost)
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
    for index, row in ipairs(atlasRows) do
        local zone = config.Zones[index]
        row.Text = index == 1 and "Free portal near Meadow spawn"
            or index <= unlockedZone and "Open  •  travel from Meadow"
            or (number(zone.Cost) .. " coins  •  unlock at its wayshrine")
        row.TextColor3 = index <= unlockedZone and mint or gold
    end
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
    local journey = instruction or config.nextJourneyGoal({
        Zone = unlockedZone, Rebirths = rebirths, Lantern = player:GetAttribute("SurveyorLantern") == 1,
        Amethyst = player:GetAttribute(config.oreKey(config.SurveyorLantern.Zone)) or 0,
        Reserve = reserve, Auras = auras,
    })
    nextObjective.Text = journey and ("Next: " .. journey) or ""
    setExpanded(body.Visible)
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
        guide.Text = instruction or journey or ""
    end
    guideCard.Visible = guide.Text ~= ""
    waypointName, waypointInstruction = destination, instruction
    refreshWaypoint()
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
    "Ore1", "Ore2", "Ore3", "Ore4", "Ore5", "SurveyorLantern", "AmethystReserve", "FrostSeal", "FrostReserve",
    "Geodes1", "Geodes2", "Geodes3", "Geodes4", "Geodes5", "Specimens", "GeodeCompass", "HeartstoneTrophy", "PassOwned1", "PassOwned2" }) do
    player:GetAttributeChangedSignal(attribute):Connect(refresh)
end
refresh()

for _, item in ipairs(panel:GetDescendants()) do
    if (item:IsA("Frame") or item:IsA("TextButton")) and item.BackgroundColor3 == slate then
        item.BackgroundTransparency = .32
    end
end

local viewportConnection
local function watchCamera()
    if viewportConnection then viewportConnection:Disconnect() end
    local camera = workspace.CurrentCamera
    if not camera then return end
    local function layout()
        local viewport = camera.ViewportSize
        if viewport.X < 100 or viewport.Y < 100 then return end
        welcomeScale.Scale = math.min(1, (viewport.X - 24) / 424, (viewport.Y - 24) / 322)
        local compact = viewport.X < 560
        pageTop = compact and 87 or 39
        local openHeight = bodyTop + pageTop + 234
        scale.Scale = math.min(1, (viewport.X - 24) / panelWidth, (viewport.Y - 28) / openHeight)
        for index, entry in ipairs(pages) do
            local tab = entry[1]
            if compact then
                tab.Position = offset(((index - 1) % 4) * 70, math.floor((index - 1) / 4) * 42)
                tab.Size = offset(68, 38)
                tab.TextSize = 14
            else
                tab.Position = offset((index - 1) * 40, 0)
                tab.Size = offset(38, 33)
                tab.TextSize = 11
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

local dialogue = create("Frame", gui, {
    AnchorPoint = Vector2.new(.5, 1), Position = UDim2.new(.5, 0, 1, -83),
    Size = UDim2.new(.92, 0, 0, 112), BackgroundColor3 = ink, BorderSizePixel = 0, Visible = false,
})
outline(dialogue)
create("UISizeConstraint", dialogue, { MaxSize = Vector2.new(466, 112) })
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

local travelShade = create("Frame", gui, {
    Size = UDim2.fromScale(1, 1), BackgroundColor3 = ink, BackgroundTransparency = 1,
    BorderSizePixel = 0, ZIndex = 16,
})
local travelTween
local toastVersion = 0
local toastTween
local toastEnd = UDim2.new(.5, 0, 1, -83)
ReplicatedStorage:WaitForChild("MiningAction").OnClientEvent:Connect(function(message, cue, name, role, soundCue)
    if cue == "passes" then
        setExpanded(true)
        showPage(pages[5])
        showCollection(5)
        return
    end
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
    audio:cue(soundCue or cue)
    if cue == "travel" then
        task.delay(.18, refreshWaypoint)
        if travelTween then travelTween:Cancel() end
        travelShade.BackgroundTransparency = .44
        travelTween = TweenService:Create(travelShade, TweenInfo.new(.38), { BackgroundTransparency = 1 })
        travelTween:Play()
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
