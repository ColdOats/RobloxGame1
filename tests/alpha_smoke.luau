local world = assert(workspace:FindFirstChild("CrystalWorld"))
local spawnGround = workspace:WaitForChild("MiningStart"):WaitForChild("Meadow Ground")
assert(spawnGround.CanCollide and spawnGround.Anchored)
local function countTag(name)
    local count = 0
    for object, assigned in pairs(tags) do
        if assigned[name] and object:IsDescendantOf(world) then count += 1 end
    end
    return count
end
assert(countTag("MineableOre") == 60)
for _, zone in ipairs(C.Zones) do
    assert(world:WaitForChild(zone.Name):WaitForChild(zone.Name .. " Mine"))
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

local meadow = world:WaitForChild("Meadow"):WaitForChild("Meadow Mine")
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
local function clickOre(ore)
    moveTo(ore)
    strike:Fire(player, ore)
    advance(.36)
end
moveTo(meadowOre[1])
strike:Fire(player, meadowOre[1])
assert(player.LastCue == nil, "An unequipped pickaxe must not mine")
interact(world:WaitForChild("Guild Commissions"))
assert(player:GetAttribute("GuidedOrder") == 1)
interact(meadowOre[1])
advance(.36)
assert(character:FindFirstChild("Starter Pickaxe"), "The prompt equips the pickaxe")

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
for i = 2, 4 do
    for _ = 1, 3 do clickOre(meadowOre[i]) end
end
assert(player:GetAttribute("OrderNodes") == 4 and player:GetAttribute("Crystals") >= 8)
assert(player:GetAttribute("Geodes1") == 1)
interact(world:WaitForChild("Sell Crystals"))
assert(player:GetAttribute("OrderCrystals") == 8 and player:GetAttribute("Crystals") == 0)
interact(world:WaitForChild("Guild Commissions"))
assert(player:GetAttribute("Orders") == 1)
interact(world:WaitForChild("Pickaxe Forge"))
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

advance(4)
interact(world:WaitForChild("Guild Commissions"))
fillAndSell(25)
interact(world:WaitForChild("Guild Commissions"))
advance(4)
interact(world:WaitForChild("Guild Commissions"))
fillAndSell(15)
interact(world:WaitForChild("Guild Commissions"))
assert(player:GetAttribute("Coins") >= C.Zones[2].Cost)
interact(world:WaitForChild("Travel to Amethyst Cavern"))
assert(player:GetAttribute("Zone") == 2)

local before = player:GetAttribute("Coins")
services.Players.PlayerRemoving:Fire(player)
player.Parent = nil
local saved = databases.CrystalMining_v1.Values["101"]
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
    advance(.36)
    interact(vein)
    advance(.36)
end
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
for _, checkpoint in ipairs(C.Whiteout.Route) do
    advance(5)
    interact(frozen:WaitForChild(checkpoint.Name))
end
assert(player:GetAttribute("RelayBestMs") > 0 and C.owns(player:GetAttribute("AurasOwned"), C.Whiteout.Aura))

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

-- Validate the paid wallet with simulated product IDs. The shipped configuration can leave both packs disabled.
local receiptStore = SessionStore.new(databases.CrystalMining_v1)
local blocked, reason = receiptStore:acquire(player.UserId, "other-server")
assert(not blocked and reason == "locked")
local pack = { ProductId = 42, Amount = 100 }
Premium.start({pack})
local receive = services.MarketplaceService.ProcessReceipt
local receipt = {PlayerId = player.UserId, ProductId = pack.ProductId, PurchaseId = "alpha-test"}
assert(receive(receipt) == Enum.ProductPurchaseDecision.PurchaseGranted)
assert(receive(receipt) == Enum.ProductPurchaseDecision.PurchaseGranted)
assert(player:GetAttribute("Starshards") == 100)
assert(Premium.buyCrate(player, 1, C.PremiumCrates[1]))
assert(not Premium.buyCrate(player, 1, C.PremiumCrates[1]))
assert(player:GetAttribute("Starshards") == 40 and Premium.owns(player, 1))
print("Persistence smoke passed: concurrent save lock, one-time receipts, and atomic premium crate spend.")
