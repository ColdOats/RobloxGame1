local world = assert(workspace:FindFirstChild("CrystalWorld"))
local spawnGround = workspace:WaitForChild("MiningStart"):WaitForChild("Meadow Ground")
assert(spawnGround.CanCollide and spawnGround.Anchored)
assert(spawnGround.TopSurface == Enum.SurfaceType.Studs and spawnGround.Material == Enum.Material.Plastic)
assert(spawnGround.Size.X == C.Meadow.Width and spawnGround.Size.Z == C.Meadow.Depth)
spawnGround.Size = Vector3.new(110, 1, 100)
World.ensureSpawn()
assert(spawnGround.Size.X == C.Meadow.Width and spawnGround.Size.Z == C.Meadow.Depth, "Existing Studio floors must resize")
local meadowZone = world:WaitForChild("Meadow")
local plaza = meadowZone:WaitForChild("Market Square")
assert(plaza.Size.X == 124 and plaza.Size.Z == 62)
assert(plaza.TopSurface == Enum.SurfaceType.Studs)
local entranceSignCount = 0
for _, object in ipairs(world:GetDescendants()) do
    if object:IsA("TextLabel") and object.Text == "MEADOW MINE" then entranceSignCount += 1 end
end
assert(entranceSignCount == 1 and not meadowZone:FindFirstChild("Meadow Sign"), "The mine entrance must have one sign")
local starterGrounds = world:WaitForChild("Meadow Mine Grounds")
local plaque = starterGrounds:WaitForChild("Meadow Mine"):WaitForChild("Meadow Mine Plaque")
local plaqueGui = plaque:FindFirstChildOfClass("SurfaceGui")
assert(plaqueGui.SizingMode == Enum.SurfaceGuiSizingMode.PixelsPerStud)
assert(not plaque.CanCollide and plaqueGui:FindFirstChildOfClass("TextLabel").Text == "MEADOW MINE")
for _, name in ipairs({"Meadow Welcome", "Market Directions", "Wayshrine Directions", "Miners’ Services Board",
    "Market Shops Board", "SELL CRYSTALS Sign", "PICKAXE FORGE Sign", "GUILD COMMISSIONS Sign"}) do
    local board = world:WaitForChild(name)
    assert(board:FindFirstChildOfClass("SurfaceGui").SizingMode == Enum.SurfaceGuiSizingMode.PixelsPerStud)
    assert(not board.CanCollide)
    local posts = 0
    for _, child in ipairs(board:GetChildren()) do
        if child.Name == "Sign Post" then
            assert(child.Anchored and math.abs(child.Position.Y - child.Size.Y / 2 - .48) < .01)
            posts += 1
        end
    end
    assert(posts == 2)
end
for _, name in ipairs({"Guild Commissions", "Sell Crystals", "Bag Outfitters", "Pickaxe Forge", "Geode Appraiser"}) do
    assert(world:WaitForChild(name).Position.X < 0, name .. " should be on the services side")
end
for _, crate in ipairs(C.Crates) do
    assert(world:WaitForChild(crate.Name).Position.X > 0, crate.Name .. " should be on the shops side")
end
assert(world:WaitForChild("Style Gallery").Position.X > 0 and world:WaitForChild("Geode Compass").Position.X > 0)
local residents = world:WaitForChild("Community Corner")
assert(residents:WaitForChild("Meadow Noticeboard"):WaitForChild("Sign Post"))
assert(world:FindFirstChild("Pip") and world:FindFirstChild("Nell"))
local galleryBoard = world:WaitForChild("Style Gallery Board")
local hasDevLabel = false
for _, item in ipairs(galleryBoard:GetDescendants()) do
    if item:IsA("TextLabel") and string.find(item.Text, "(in development)", 1, true) then hasDevLabel = true end
end
assert(hasDevLabel and galleryBoard:WaitForChild("Sign Post"))
local commons = meadowZone:WaitForChild("Miner’s Commons")
local seats = 0
for _, item in ipairs(commons:GetChildren()) do
    if item:IsA("Seat") then
        seats += 1
        assert(item.CanTouch and math.abs(item.Position.X) >= 12)
    end
end
assert(seats == 4)
for _, item in ipairs(meadowZone:GetChildren()) do
    if item.Name == "Pennant" then assert(item.Position.Z == 54, "The mine entrance should stay clear of pennants") end
end
local facades = 0
for _, item in ipairs(world:GetChildren()) do
    if item.Name == "Storefront Cap" then
        facades += 1
        assert(item.TopSurface == Enum.SurfaceType.Studs and not item.CanCollide)
    end
end
assert(facades == 3)
local houses = meadowZone:WaitForChild("Meadow Houses")
local houseCount, smokeCount = 0, 0
for _, house in ipairs(houses:GetChildren()) do
    if house:IsA("Model") then
        houseCount += 1
        local door = house:WaitForChild("Closed House Door")
        assert(door.Anchored and not door:FindFirstChildOfClass("ProximityPrompt"))
        assert(house:WaitForChild("House Shell").CanCollide)
        local vent = house:FindFirstChild("Chimney Vent")
        if vent and vent:FindFirstChildOfClass("Smoke") then smokeCount += 1 end
    end
end
assert(houseCount == 12 and smokeCount == 4)
do
    local plants = meadowZone:WaitForChild("Foliage")
    local plazaPlants, meadowPlants, planterCount = 0, 0, 0
    for _, plant in ipairs(plants:GetChildren()) do
        local name, position = plant.Name, plant.Position
        if name == "Market Planter" then planterCount += 1 end
        if name == "Ground Cover" or name == "Meadow Bramble" or name == "Leaf Lobe" or name == "Leaf Tip"
            or name == "Meadow Wildflower" then
            local cf, size = plant.CFrame, plant.Size
            local halfX = (math.abs(cf.RightVector.X) * size.X + math.abs(cf.UpVector.X) * size.Y
                + math.abs(cf.LookVector.X) * size.Z) / 2
            local halfZ = (math.abs(cf.RightVector.Z) * size.X + math.abs(cf.UpVector.Z) * size.Y
                + math.abs(cf.LookVector.Z) * size.Z) / 2
            local halfY = (math.abs(cf.RightVector.Y) * size.X + math.abs(cf.UpVector.Y) * size.Y
                + math.abs(cf.LookVector.Y) * size.Z) / 2
            assert(position.Y - halfY >= .499, "Foliage must sit above ground")
            for _, house in ipairs(houses:GetChildren()) do
                if house:IsA("Model") then
                    local foundation = house:WaitForChild("House Foundation")
                    assert(math.abs(position.X - foundation.Position.X) >= halfX + foundation.Size.Z / 2
                        or math.abs(position.Z - foundation.Position.Z) >= halfZ + foundation.Size.X / 2,
                        "Foliage overlaps " .. house.Name)
                elseif house.Name == "Town Sidewalk" then
                    assert(math.abs(position.X - house.Position.X) >= halfX + house.Size.X / 2
                        or math.abs(position.Z - house.Position.Z) >= halfZ + house.Size.Z / 2,
                        "Foliage overlaps the town sidewalk")
                end
            end
            if math.abs(position.X) < plaza.Size.X / 2 and math.abs(position.Z - plaza.Position.Z) < plaza.Size.Z / 2 then
                assert(position.Y - halfY > plaza.Position.Y + plaza.Size.Y / 2 + .5, "Paved plants should grow in raised beds")
                plazaPlants += 1
            elseif position.Z < -16 then
                meadowPlants += 1
            end
        end
    end
    assert(planterCount == 4 and plazaPlants >= 30 and meadowPlants >= 100)
    assert(#starterGrounds:WaitForChild("Foliage"):GetChildren() >= 100)
    for index = 2, #C.Zones do
        assert(#world:WaitForChild(C.Zones[index].Name):WaitForChild("Foliage"):GetChildren() >= 60)
    end
    print("Landscape smoke passed: planted market beds, fuller biomes, and clearance around house foundations and sidewalks.")
end
local park = meadowZone:WaitForChild("Overlook Park")
local parkPath = park:WaitForChild("Overlook Path")
local promenade = meadowZone:WaitForChild("Wayshrine Promenade")
assert(parkPath.Position.Z - parkPath.Size.Z / 2 < promenade.Position.Z + promenade.Size.Z / 2)
assert(parkPath.Position.Z + parkPath.Size.Z / 2 <= C.Meadow.Depth / 2)
assert(not park:WaitForChild("Overlook Pond").CanCollide)
local ducks = 0
for _, item in ipairs(park:GetChildren()) do
    if item.Name == "Pond Duck" then ducks += 1; assert(not item.CanCollide) end
end
assert(ducks == 2 and world:FindFirstChild("Hollis"))
local canopies = 0
for _, object in ipairs(world:GetChildren()) do
    if object.Name == "Market Stand Canopy" then
        assert(object.Material == Enum.Material.Plastic)
        canopies += 1
    end
end
assert(canopies == 6)
assert(world:WaitForChild("Travel to Amethyst Cavern").Position.Z == 72)
local oak = meadowZone:WaitForChild("Meadow Oak")
assert(oak:WaitForChild("Oak trunk").CanCollide and not oak:WaitForChild("Oak limb").CanCollide)
assert(not oak:WaitForChild("Leaf mass").CanCollide)
local pine = world:WaitForChild("Frozen Peaks"):WaitForChild("Frostpine")
assert(pine:WaitForChild("Lower pine trunk").CanCollide and not pine:WaitForChild("Bough snow").CanCollide)
local function countTag(name)
    local count = 0
    for object, assigned in pairs(tags) do
        if assigned[name] and object:IsDescendantOf(world) then count += 1 end
    end
    return count
end
assert(countTag("MineableOre") == 60)
for index, zone in ipairs(C.Zones) do
    local area = world:WaitForChild(zone.Name)
    assert(area:GetAttribute("BiomeIndex") == index)
    local mine = (index == 1 and starterGrounds or area):WaitForChild(zone.Name .. " Mine")
    local details = mine:WaitForChild("Mine Details")
    local detailName = ({"Retired Ore Cart", "Fractured Slate Shelf", "Hanging Ice Tooth", "Collapsed Relief", "Pitted Iron Bracket"})[index]
    assert(details:WaitForChild(detailName))
    for _, detail in ipairs(details:GetChildren()) do
        assert(not detail.CanCollide and not detail.CanQuery)
    end
    local scenery = area:WaitForChild("Mountain Backdrop")
    local summit = scenery:WaitForChild("Peak")
    assert(not summit.CanCollide and math.abs(summit.Position.X - C.zoneCenter(index)) <= 132)
    assert(math.abs(summit.Position.Z) > 50)
end

local player = Instance.new("Player")
player.UserId = 101
player.Parent = services.Players
player.DisplayName = "Alpha Tester"
for _, name in ipairs({"Backpack", "StarterGear"}) do Instance.new(name).Parent = player end
local character = Instance.new("Model")
player.Character = character
local root = Instance.new("Part")
root.Name = "HumanoidRootPart"
root.Parent = character
local head = Instance.new("Part")
head.Name = "Head"
head.Parent = character
local humanoid = Instance.new("Humanoid")
humanoid.Health = 100
humanoid.Parent = character

local function moveTo(anchor, meters)
    root.Position = anchor.Position + Vector3.new(meters or 3, 0, 0)
    head.Position = root.Position + Vector3.new(0, 1.5, 0)
end
local function interact(anchor)
    moveTo(anchor)
    local control = anchor:FindFirstChildOfClass("ProximityPrompt")
    assert(control and control.Enabled ~= false, anchor.Name)
    control.Triggered:Fire(player)
end

services.Players.PlayerAdded:Fire(player)
advance(0)
assert(not player.KickReason and player:GetAttribute("Coins") == 0)
assert(player.Backpack:FindFirstChild("Starter Pickaxe"))

assert(player:GetAttribute("WelcomeSeen") == 0)
local dismissWelcome = services.ReplicatedStorage:WaitForChild("DismissWelcome").OnServerEvent
dismissWelcome:Fire(player)
dismissWelcome:Fire(player)
assert(player:GetAttribute("WelcomeSeen") == 1)

local starterPad = world:WaitForChild("Travel to Meadow Mine")
assert(starterPad:GetAttribute("TravelDestination") == 1)
assert(starterGrounds:GetAttribute("BiomeIndex") == C.StarterMineBiome and C.biomeAt(C.StarterMineX) ~= C.biomeAt(0))
assert(not meadowZone:FindFirstChild("Meadow Mine"))
interact(world:WaitForChild("Travel to Frozen Peaks"))
assert(root.Position.X ~= C.zoneCenter(3) and player:GetAttribute("Zone") == 1)
assert(string.find(player.LastMessage, "unlock Amethyst Cavern first", 1, true))
interact(world:WaitForChild("Travel to Amethyst Cavern"))
assert(string.find(player.LastMessage, "need 250 more coins", 1, true))
interact(starterPad)
assert(root.Position.X == C.StarterMineX and player:GetAttribute("Coins") == 0)
assert(starterGrounds:WaitForChild("Starter Claim Board"):FindFirstChild("Sign Post"))
assert(starterGrounds:WaitForChild("Mine Bench"):IsA("Seat"))
services.ReplicatedStorage:WaitForChild("ReturnToMeadow").OnServerEvent:Fire(player)
assert(root.Position.X == 0 and player:GetAttribute("Zone") == 1)
interact(starterPad)
local starterBack = starterGrounds:WaitForChild("Return to Meadow")
assert(starterBack:GetAttribute("TravelDestination") == 0)
interact(starterBack)
assert(root.Position.X == 0 and player:GetAttribute("Zone") == 1)
for index = 2, #C.Zones do
    local back = world:WaitForChild(C.Zones[index].Name):WaitForChild("Return to Meadow")
    assert(back:GetAttribute("TravelDestination") == 0)
end
local meadow = starterGrounds:WaitForChild("Meadow Mine")
local caverns = world:WaitForChild("Amethyst Cavern"):WaitForChild("Amethyst Cavern Mine")
local function oreIn(mine)
    local ore = {}
    for _, child in ipairs(mine:GetChildren()) do
        if child.Name == "Crystal" then table.insert(ore, child) end
    end
    return ore
end
local meadowOre = oreIn(meadow)
local strike = services.ReplicatedStorage:WaitForChild("SwingAtOre").OnServerEvent
local function waitForSwing()
    advance(C.Picks[player:GetAttribute("Pick")].SwingCooldown + .01)
end
local function clickOre(ore)
    moveTo(ore)
    strike:Fire(player, ore)
    waitForSwing()
end
moveTo(meadowOre[1])
player.LastCue = nil
strike:Fire(player, meadowOre[1])
assert(player.LastCue == nil, "An unequipped pickaxe must not mine")
interact(world:WaitForChild("Guild Commissions"))
assert(player:GetAttribute("GuidedOrder") == 1)
interact(meadowOre[1])
assert(character:FindFirstChild("Starter Pickaxe"), "The prompt equips the pickaxe")
assert(meadowOre[1]:GetAttribute("OreHealth") == 2)
assert(player.LastSoundCue == "hit")
advance(.36)
moveTo(meadowOre[2])
strike:Fire(player, meadowOre[2])
assert(meadowOre[2]:GetAttribute("OreHealth") == 3, "The Starter cooldown applies across ore and input methods")
waitForSwing()

local function checkRejected(target)
    player.LastCue = nil
    player.LastMessage = nil
    strike:Fire(player, target)
    assert(player.LastCue == nil and player.LastMessage == nil, "Invalid swing produced feedback")
end
moveTo(meadowOre[1], 20)
checkRejected(meadowOre[1])
moveTo(meadowOre[1])
workspace.BlockingHit = { Instance = spawnGround }
checkRejected(meadowOre[1])
workspace.BlockingHit = nil
moveTo(oreIn(caverns)[1])
checkRejected(oreIn(caverns)[1])

clickOre(meadowOre[1])
clickOre(meadowOre[1])
assert(player.LastSoundCue == "break" or player.LastSoundCue == "richBreak")
local firstOrePrompt = meadowOre[1]:FindFirstChildOfClass("ProximityPrompt")
advance(3)
assert(not firstOrePrompt.Enabled and meadowOre[1]:GetAttribute("OreHealth") == 0)
for i = 2, 4 do
    for _ = 1, 3 do clickOre(meadowOre[i]) end
    if i == 3 then
        assert(player.LastCue == "reward" and (player.LastSoundCue == "break" or player.LastSoundCue == "richBreak"))
    end
end
assert(player:GetAttribute("OrderNodes") == 4 and player:GetAttribute("Crystals") >= 8)
assert(player:GetAttribute("Geodes1") == 1)
interact(world:WaitForChild("Sell Crystals"))
assert(player:GetAttribute("OrderCrystals") == 8 and player:GetAttribute("Crystals") == 0)
interact(world:WaitForChild("Guild Commissions"))
assert(player:GetAttribute("Orders") == 1)
local beforeForge = player:GetAttribute("Coins")
interact(world:WaitForChild("Pickaxe Forge"))
assert(player:GetAttribute("FirstForgeKit") == 1 and player:GetAttribute("Coins") == beforeForge - C.Picks[2].Cost + C.FirstForgeReward)
assert(player:GetAttribute("Pick") == 2 and character:FindFirstChild("Iron Pickaxe"))
interact(world:WaitForChild("Geode Appraiser"))
assert(C.owns(player:GetAttribute("Specimens"), 1))

local function fillAndSell(required)
    local mined = 0
    local caves = oreIn(meadow)
    for i = 1, #caves do
        local ore = caves[i]
        if ore:FindFirstChildOfClass("ProximityPrompt").Enabled ~= false then
            clickOre(ore)
            clickOre(ore)
            mined += 1
        end
        if player:GetAttribute("Crystals") >= required and mined >= 4 then break end
    end
    assert(player:GetAttribute("Crystals") >= required)
    interact(world:WaitForChild("Sell Crystals"))
end

advance(C.Zones[1].OreRespawn + .25)
assert(firstOrePrompt.Enabled and meadowOre[1]:GetAttribute("OreHealth") == C.Zones[1].Health)
assert(C.Picks[2].SwingCooldown < C.Picks[1].SwingCooldown)
interact(world:WaitForChild("Guild Commissions"))
fillAndSell(25)
interact(world:WaitForChild("Guild Commissions"))
advance(C.Zones[1].OreRespawn + .25)
interact(world:WaitForChild("Guild Commissions"))
fillAndSell(15)
interact(world:WaitForChild("Guild Commissions"))
assert(player:GetAttribute("Coins") >= C.Zones[2].Cost)
interact(world:WaitForChild("Travel to Amethyst Cavern"))
assert(player:GetAttribute("Zone") == 2 and root.Position.X == C.zoneCenter(2))
local coinsAfterUnlock = player:GetAttribute("Coins")
interact(world:WaitForChild("Travel to Amethyst Cavern"))
assert(player:GetAttribute("Coins") == coinsAfterUnlock, "Unlocked caves must not charge again")

local before = player:GetAttribute("Coins")
services.Players.PlayerRemoving:Fire(player)
player.Parent = nil
local saved = databases.CrystalMining_v1.Values["101"]
assert(saved.Profile.WelcomeSeen == 1)
assert(saved.Session == nil and saved.Profile.Pick == 2 and saved.Profile.Zone == 2 and saved.Profile.Coins == before)
player.Parent = services.Players
services.Players.PlayerAdded:Fire(player)
advance(0)
assert(player:GetAttribute("Zone") == 2 and player:GetAttribute("Coins") == before)
print("Alpha smoke passed: world boot, 60 ore nodes, validated mining, first commission, forging, geodes, Cavern unlock, and rejoin.")

local resonance = {}
for i = 1, 3 do resonance[i] = caverns:WaitForChild("Resonant Vein " .. i) end
for _, vein in ipairs(resonance) do
    interact(vein)
    waitForSwing()
    interact(vein)
    waitForSwing()
end
local gateBoard = caverns:WaitForChild("Resonance Gate Sign")
assert(gateBoard:WaitForChild("Sign Post") and not gateBoard.CanCollide)
assert(caverns:WaitForChild("Route Sign"):WaitForChild("Sign Post"))
local chamberGate = caverns:WaitForChild("Resonance Gate")
local gateTween = services.TweenService.LastTween
assert(gateTween.Target == chamberGate and gateTween.Goal.CFrame.Position.Y > chamberGate.Position.Y)
assert(not chamberGate.CanCollide, "The animated gate must release collision while it opens")
local chamberCache = caverns:WaitForChild("Echo Deposit")
interact(chamberCache)
assert(C.owns(player:GetAttribute("AurasOwned"), C.Resonance.Aura))
local chamberCoins = player:GetAttribute("Coins")
interact(chamberCache)
assert(player:GetAttribute("Coins") == chamberCoins, "Chamber payout must be unique per run")

local cavernsOre = oreIn(caverns)
for i = 1, 4 do
    for _ = 1, 3 do clickOre(cavernsOre[i]) end
end
assert(player:GetAttribute("Ore2") >= 24)
interact(world:WaitForChild("Surveyor’s Workbench"))
assert(player:GetAttribute("SurveyorLantern") == 1)
assert(root:FindFirstChild("SurveyorLantern"))

-- Seed a returning save to exercise the same server handlers in the later zones.
services.Players.PlayerRemoving:Fire(player)
player.Parent = nil
saved = databases.CrystalMining_v1.Values["101"]
saved.Profile.Zone = 5
saved.Profile.Discoveries = 2
saved.Profile.CaveNodes2 = C.CaveMastery[2].Master
player.Parent = services.Players
services.Players.PlayerAdded:Fire(player)
advance(0)
assert(player:GetAttribute("SurveyorLantern") == 1 and player:GetAttribute("Zone") == 5)

local descent = caverns:WaitForChild("Heartstone Descent")
interact(descent:WaitForChild("Master Expedition"))
interact(descent:WaitForChild("West Survey Stake"))
interact(descent:WaitForChild("East Survey Stake"))
assert(player:GetAttribute("DescentStage") == 2)
interact(descent:WaitForChild("Press On for Heartstone"))
interact(descent:WaitForChild("West Heartstone Seam"))
interact(descent:WaitForChild("East Heartstone Seam"))
assert(player:GetAttribute("DescentStage") == 4)
interact(descent:WaitForChild("Heartstone Cache"))
assert(player:GetAttribute("HeartstoneTrophy") == 1 and player:GetAttribute("DescentStage") == 0)

local frozen = world:WaitForChild("Frozen Peaks")
interact(frozen:WaitForChild("Whiteout Shelter"))
local goHome = services.ReplicatedStorage:WaitForChild("ReturnToMeadow").OnServerEvent
local expeditionX = root.Position.X
goHome:Fire(player)
assert(root.Position.X == expeditionX, "A timed expedition should protect its route")
for _, checkpoint in ipairs(C.Whiteout.Route) do
    advance(5)
    interact(frozen:WaitForChild(checkpoint.Name))
end
assert(player:GetAttribute("RelayBestMs") > 0 and C.owns(player:GetAttribute("AurasOwned"), C.Whiteout.Aura))
local haul = player:GetAttribute("Crystals")
goHome:Fire(player)
assert(root.Position.X == 0 and player:GetAttribute("Crystals") == haul)

local ruins = world:WaitForChild("Sunken Ruins")
local altar = ruins:WaitForChild("Tidekeeper Altar")
interact(altar)
for _, dial in ipairs(C.Tidekeeper.Dials) do
    for _ = 2, dial.Answer do interact(ruins:WaitForChild(dial.Name)) end
end
interact(altar)
assert(C.owns(player:GetAttribute("AurasOwned"), C.Tidekeeper.Aura))

local anvil = world:WaitForChild("Ember Forge"):WaitForChild("Emberheart Anvil")
interact(anvil)
for _, stage in ipairs(C.Emberheart.Stages) do
    advance(stage.Period * (stage.Low + stage.High) / 4)
    interact(anvil)
end
assert(player:GetAttribute("EmberBestMs") > 0 and C.owns(player:GetAttribute("AurasOwned"), C.Emberheart.Aura))
print("Expedition smoke passed: Crystal Resonance, lantern crafting, Heartstone Descent, Whiteout Relay, Tidekeeper, and Emberheart.")

-- Keep receipt fulfillment and stored ownership testable while the live purchase routes are paused.
local receiptStore = SessionStore.new(databases.CrystalMining_v1)
local blocked, reason = receiptStore:acquire(player.UserId, "other-server")
assert(not blocked and reason == "locked")
local pack = { ProductId = 42, Amount = 100 }
local originalPack = C.StarshardProducts[1]
C.StarshardProducts[1] = pack
Premium.start({pack})
local receive = services.MarketplaceService.ProcessReceipt
local receipt = {PlayerId = player.UserId, ProductId = pack.ProductId, PurchaseId = "alpha-test"}
assert(receive(receipt) == Enum.ProductPurchaseDecision.PurchaseGranted)
assert(receive(receipt) == Enum.ProductPurchaseDecision.PurchaseGranted)
assert(player:GetAttribute("Starshards") == 100)
do
    local purchasePrompted = false
    function services.MarketplaceService:PromptProductPurchase() purchasePrompted = true end
    local request = services.ReplicatedStorage:WaitForChild("PremiumAction").OnServerEvent
    request:Fire(player, "TopUp", 1)
    assert(not purchasePrompted and string.find(player.LastMessage, "(in development)", 1, true))
    advance(1.1)
    request:Fire(player, "Open", 1)
    assert(player:GetAttribute("Starshards") == 100 and not Premium.owns(player, 1))
    assert(string.find(player.LastMessage, "(in development)", 1, true))
    advance(1.1)
end
C.StarshardProducts[1] = originalPack
assert(Premium.buyCrate(player, 1, C.PremiumCrates[1]))
assert(not Premium.buyCrate(player, 1, C.PremiumCrates[1]))
assert(player:GetAttribute("Starshards") == 40 and Premium.owns(player, 1))
print("Persistence smoke passed: concurrent save lock, one-time receipts, and atomic premium crate spend.")

local passId = 51
local pendingPass
local marketplace = services.MarketplaceService
function marketplace:UserOwnsGamePassAsync() return false end
function marketplace:PromptGamePassPurchase(p, id)
    assert(p == player)
    pendingPass = id
end
C.GamePasses[1].Id = passId
local purchaseCount = 0
Premium.startPasses(C.GamePasses, function() purchaseCount += 1 end)
Premium.loadPasses(player, C.GamePasses)
advance(0)
local equip = services.ReplicatedStorage:WaitForChild("EquipCollection").OnServerEvent
local finishIndex, auraIndex
for index, item in ipairs(C.Skins) do if item.Pass == 1 then finishIndex = index end end
for index, item in ipairs(C.Auras) do if item.Pass == 1 then auraIndex = index end end
assert(finishIndex and auraIndex)
equip:Fire(player, 2, finishIndex)
assert(player:GetAttribute("Skin") ~= finishIndex)
services.ReplicatedStorage:WaitForChild("PremiumAction").OnServerEvent:Fire(player, "Pass", 1)
assert(not pendingPass and string.find(player.LastMessage, "(in development)", 1, true))
assert(Premium.promptPass(player, 1, C.GamePasses[1]) and pendingPass == passId)
marketplace.PromptGamePassPurchaseFinished:Fire(player, 999, true)
marketplace.PromptGamePassPurchaseFinished:Fire(player, passId, false)
assert(not Premium.ownsPass(player, 1) and purchaseCount == 0)
marketplace.PromptGamePassPurchaseFinished:Fire(player, passId, true)
marketplace.PromptGamePassPurchaseFinished:Fire(player, passId, true)
assert(Premium.ownsPass(player, 1) and purchaseCount == 1)
assert(not Premium.promptPass(player, 1, C.GamePasses[1]))
equip:Fire(player, 2, finishIndex)
advance(.4)
equip:Fire(player, 3, auraIndex)
assert(player:GetAttribute("Skin") == finishIndex and player:GetAttribute("Aura") == auraIndex)
assert(not Premium.promptPass(player, 2, C.GamePasses[2]))

local journey = { Zone = 2, Rebirths = 0, Lantern = false, Amethyst = 4, Reserve = 5, Auras = 0 }
assert(string.find(C.nextJourneyGoal(journey), "9/24", 1, true))
journey.Amethyst = 30
assert(string.find(C.nextJourneyGoal(journey), "Craft", 1, true))
journey.Lantern = true
assert(string.find(C.nextJourneyGoal(journey), "Resonance", 1, true))
journey.Auras = bit32.lshift(1, C.Resonance.Aura - 1)
assert(string.find(C.nextJourneyGoal(journey), "Whiteout", 1, true))
print("Engagement smoke passed: pass authorization, cosmetic equip, and next goals after the Cavern unlock.")


services.Players.PlayerRemoving:Fire(player)
player.Parent = nil
saved = databases.CrystalMining_v1.Values["101"]
saved.Profile.Crystals = 45
for index in ipairs(C.Zones) do saved.Profile[C.oreKey(index)] = 0 end
saved.Profile.Ore3 = 45
player.Parent = services.Players
services.Players.PlayerAdded:Fire(player)
advance(0)
local press = world:WaitForChild("Frost Seal Press")
interact(press)
assert(player:GetAttribute("FrostReserve") == 45 and player:GetAttribute("Crystals") == 0)
services.Players.PlayerRemoving:Fire(player)
player.Parent = nil
saved = databases.CrystalMining_v1.Values["101"]
saved.Profile.Crystals, saved.Profile.Ore3 = 33, 33
player.Parent = services.Players
services.Players.PlayerAdded:Fire(player)
advance(0)
local capacityBefore = player:GetAttribute("Capacity")
interact(press)
assert(player:GetAttribute("FrostSeal") == 1 and player:GetAttribute("Capacity") == capacityBefore + 35)
assert(player:GetAttribute("FrostReserve") == 0 and player:GetAttribute("Ore3") == 3)
interact(press)
assert(player:GetAttribute("Ore3") == 3)
print("Field Guide smoke passed: first-forge bonus, protected expedition exit, safe haul return, and Frost Seal across saved sessions.")

do
    local bought = C.Bags[2]
    local before = player:GetAttribute("Coins")
    interact(world:WaitForChild("Bag Outfitters"))
    assert(player:GetAttribute("Bag") == 2 and player:GetAttribute("Capacity") == bought.Capacity + C.FrostSeal.ExtraCapacity)
    assert(player:GetAttribute("Coins") == before - bought.Cost)
    for _, crate in ipairs(C.Crates) do
        local coins = player:GetAttribute("Coins")
        interact(world:WaitForChild(crate.Name))
        local reward = player:GetAttribute(crate.Equipped)
        assert(player:GetAttribute("Coins") == coins - crate.Cost)
        assert(reward > 0 and C.owns(player:GetAttribute(crate.Pool .. "Owned"), reward))
    end
    services.Players.PlayerRemoving:Fire(player)
    player.Parent = nil
    local pending = databases.CrystalMining_v1.Values["101"].Profile
    pending.Coins = 3000
    pending.OrderZone, pending.OrderNodes = 5, 1
    player.Parent = services.Players
    services.Players.PlayerAdded:Fire(player)
    advance(0)
    interact(world:WaitForChild("Rebirth"))
    assert(player:GetAttribute("Rebirths") == 1 and player:GetAttribute("Pick") == 1 and player:GetAttribute("Zone") == 1)
    assert(player:GetAttribute("OrderZone") == 0 and player:GetAttribute("Coins") == 0 and player:GetAttribute("Crystals") == 0)
    assert(player:GetAttribute("Bag") == 2 and player:GetAttribute("Pet") > 0 and player:GetAttribute("FrostSeal") == 1)
    interact(world:WaitForChild("Guild Commissions"))
    assert(player:GetAttribute("OrderZone") == 1)
    print("Pre-alpha market smoke passed: earned-coin bags and crates, collection persistence, and fresh commissions after rebirth.")
end
