local config = {
    Zones = {
        { Name = "Meadow", Ore = "Quartz", Cost = 0, Color = Color3.fromRGB(53, 220, 190), Value = 2, Health = 3,
            Landmark = "Old Survey Marker", DiscoveryReward = 20, OreRespawn = 10 },
        { Name = "Amethyst Cavern", Ore = "Amethyst", Cost = 250, Color = Color3.fromRGB(161, 85, 255), Value = 8, Health = 6,
            Landmark = "Echo Chamber", DiscoveryReward = 80, OreRespawn = 12 },
        { Name = "Frozen Peaks", Ore = "Frost Ore", Cost = 1500, Color = Color3.fromRGB(91, 175, 255), Value = 25, Health = 10,
            Landmark = "Tarn Overlook", DiscoveryReward = 200, OreRespawn = 14 },
        { Name = "Sunken Ruins", Ore = "Tideglass", Cost = 3500, Color = Color3.fromRGB(84, 233, 182), Value = 42, Health = 16,
            Landmark = "Tidekeeper Shrine", DiscoveryReward = 450, OreRespawn = 15 },
        { Name = "Ember Forge", Ore = "Ember Ore", Cost = 8000, Color = Color3.fromRGB(255, 122, 65), Value = 75, Health = 26,
            Landmark = "Emberheart Beacon", DiscoveryReward = 1000, OreRespawn = 17 },
    },
    ZoneSpacing = 2800,
    StarterMineBiome = 0,
    StarterMineX = -2800,
    Meadow = { Width = 180, Depth = 220, MineWidthScale = 1.22, MineDepthScale = 1.37 },
    Picks = {
        { Name = "Starter", Cost = 0, Power = 1, SwingCooldown = .75 },
        { Name = "Iron", Cost = 60, Power = 2, SwingCooldown = .62 },
        { Name = "Steel", Cost = 250, Power = 4, SwingCooldown = .53 },
        { Name = "Crystal", Cost = 1000, Power = 8, SwingCooldown = .45 },
        { Name = "Tideglass", Cost = 2800, Power = 13, SwingCooldown = .38 },
        { Name = "Embersteel", Cost = 6200, Power = 20, SwingCooldown = .33 },
    },
    Pets = {
        { Name = "Pebble Pup", Weight = 54, Bonus = 1, Color = Color3.fromRGB(172, 149, 121) },
        { Name = "Gem Fox", Weight = 26, Bonus = 3, Color = Color3.fromRGB(236, 135, 106) },
        { Name = "Crystal Dragon", Weight = 6, Bonus = 8, Color = Color3.fromRGB(174, 133, 249) },
        { Name = "Frost Owl", Weight = 11, Bonus = 5, Color = Color3.fromRGB(149, 218, 250) },
        { Name = "Ember Sprite", Weight = 3, Bonus = 12, Color = Color3.fromRGB(255, 118, 67) },
    },
    Skins = {
        { Name = "Copperleaf", Weight = 46, Color = Color3.fromRGB(207, 138, 80) },
        { Name = "Lagoon", Weight = 31, Color = Color3.fromRGB(49, 211, 176) },
        { Name = "Moonstone", Weight = 17, Color = Color3.fromRGB(145, 172, 247) },
        { Name = "Sunflare", Weight = 6, Color = Color3.fromRGB(255, 166, 59) },
        { Name = "Astral Alloy", Premium = 1, Color = Color3.fromRGB(105, 146, 248) },
        { Name = "Meteor Etch", Premium = 3, Color = Color3.fromRGB(158, 80, 105),
            Accent = Color3.fromRGB(255, 198, 119) },
        { Name = "Trail Brass", Pass = 1, Color = Color3.fromRGB(166, 108, 68),
            Accent = Color3.fromRGB(144, 239, 186) },
        { Name = "Prism Edge", Pass = 2, Color = Color3.fromRGB(112, 101, 183),
            Accent = Color3.fromRGB(244, 176, 241) },
    },
    Auras = {
        { Name = "Firefly Trail", Weight = 46, Color = Color3.fromRGB(237, 205, 111) },
        { Name = "Petal Drift", Weight = 31, Color = Color3.fromRGB(239, 143, 190) },
        { Name = "Polar Glow", Weight = 17, Color = Color3.fromRGB(120, 229, 244) },
        { Name = "Starfall", Weight = 6, Color = Color3.fromRGB(174, 128, 246) },
        { Name = "Aurora Crown", Premium = 2, Color = Color3.fromRGB(95, 244, 223) },
        { Name = "Resonance Echo", Expedition = true, Color = Color3.fromRGB(193, 127, 255) },
        { Name = "Icebound Trail", Expedition = true, Color = Color3.fromRGB(138, 223, 255) },
        { Name = "Tideglass Halo", Expedition = true, Color = Color3.fromRGB(112, 241, 197) },
        { Name = "Emberheart Mantle", Expedition = true, Color = Color3.fromRGB(255, 146, 65) },
        { Name = "Prismatic Fieldwork", Specimen = true, Color = Color3.fromRGB(245, 193, 128) },
        { Name = "Dusk Comet", Premium = 4, Color = Color3.fromRGB(163, 132, 255),
            Accent = Color3.fromRGB(255, 171, 125) },
        { Name = "Lantern Parade", Pass = 1, Color = Color3.fromRGB(255, 208, 104),
            Accent = Color3.fromRGB(139, 206, 160) },
        { Name = "Prism Bloom", Pass = 2, Color = Color3.fromRGB(130, 195, 253),
            Accent = Color3.fromRGB(244, 160, 216) },
    },
    SurveyorLantern = { Zone = 2, Cost = 24, Range = 45, Name = "Surveyor’s Lantern", Owned = "SurveyorLantern",
        Reserve = "AmethystReserve", Benefit = "Nearby rich veins are marked." },
    FrostSeal = { Zone = 3, Cost = 75, ExtraCapacity = 35, Name = "Frost Satchel Seal", Owned = "FrostSeal",
        Reserve = "FrostReserve", Benefit = "Your bag holds 35 more crystals." },
    FirstForgeReward = 20,
    GeodeCompass = { Cost = 450, ExtraSeconds = 20 },
    GeodeHunt = {
        Chain = 3, Window = 45, Limit = 12, Aura = 10,
        Specimens = {
            { Name = "Fern Quartz", Coins = 14 },
            { Name = "Singing Amethyst", Coins = 24 },
            { Name = "Glacier Rosette", Coins = 42 },
            { Name = "Tidal Fossil", Coins = 64 },
            { Name = "Emberglass Star", Coins = 90 },
        },
    },
    CaveMastery = {
        { Prospect = 8, Master = 20, Yield = {1, 2} },
        { Prospect = 10, Master = 25, Yield = {2, 4}, Expedition = "Resonance", Trial = "Crystal Resonance" },
        { Prospect = 12, Master = 28, Yield = {4, 8}, Expedition = "Whiteout", Trial = "Whiteout Relay" },
        { Prospect = 14, Master = 32, Yield = {6, 13}, Expedition = "Tidekeeper", Trial = "Tidekeeper puzzle" },
        { Prospect = 16, Master = 36, Yield = {10, 20}, Expedition = "Emberheart", Trial = "Emberheart Tempering" },
    },
    MasterExpedition = {
        Zone = 2, JoinWindow = 18, SurveyWindow = 135, DeepWindow = 55,
        BankFirst = 120, BankRepeat = 45, DeepFirst = 360, DeepRepeat = 90,
    },
    CavernRoutes = {
        {
            Name = "Lantern Drift", Health = 6, Value = 8, RichEvery = 10,
            Color = Color3.fromRGB(239, 185, 114),
            Nodes = {{-18,-15}, {-31,-15}, {-19,-25}, {-34,-29}},
        },
        {
            Name = "Echo Tunnels", Health = 8, Value = 11, RichEvery = 4,
            Color = Color3.fromRGB(180, 116, 255),
            Nodes = {{18,-17}, {34,-22}, {32,-38}, {28,-51}},
        },
        {
            Name = "Deep Gallery", Health = 12, Value = 17, RichEvery = 6,
            Color = Color3.fromRGB(116, 218, 228),
            Nodes = {{-21,-48}, {-34,-53}, {-17,-66}, {-32,-75}},
        },
    },
    Resonance = { Zone = 2, Aura = 6, Reward = 150, Window = 85, IdleReset = 120, Health = 4 },
    Whiteout = {
        Zone = 3, Aura = 7, Duration = 100, FirstReward = 300, RepeatReward = 45,
        Route = {
            { Name = "Pinewatch Beacon", X = -27, Z = 8, Hint = "Light the beacon beside the pines" },
            { Name = "Frostmine Beacon", X = 0, Z = -19, Hint = "Follow the center aisle into the mine" },
            { Name = "Tarn Beacon", X = 20, Z = -43, Hint = "Use the rear exit, then turn right" },
        },
    },
    Tidekeeper = {
        Zone = 4, Aura = 8, Reward = 475,
        Symbols = {"Wave", "Shell", "Sun"},
        Dials = {
            { Name = "Reed Dial", X = -27, Z = 7, Answer = 2 },
            { Name = "Arch Dial", X = 28, Z = -20, Answer = 1 },
            { Name = "Mosaic Dial", X = 20, Z = -43, Answer = 3 },
        },
    },
    Emberheart = {
        Zone = 5, Aura = 9, Reward = 850, Duration = 120, Tolerance = .045,
        Stages = {
            { Name = "Heat", Period = 4.2, Low = .28, High = .60 },
            { Name = "Shape", Period = 3.7, Low = .48, High = .77 },
            { Name = "Quench", Period = 3.2, Low = .24, High = .47 },
        },
    },
    GamePassSalesEnabled = false,
    StarshardSalesEnabled = false,
    GamePasses = {
        { Id = 0, Name = "Trailblazer", Finish = "Trail Brass", Aura = "Lantern Parade" },
        { Id = 0, Name = "Cavern Artist", Finish = "Prism Edge", Aura = "Prism Bloom" },
    },
    StarshardProducts = {
        { ProductId = 0, Amount = 100 },
        { ProductId = 0, Amount = 250 },
    },
    PremiumCrates = {
        { Name = "Astral Forge Crate", Cost = 60, Reward = "Astral Alloy pickaxe finish" },
        { Name = "Aurora Crate", Cost = 90, Reward = "Aurora Crown aura" },
        { Name = "Meteor Crate", Cost = 110, Reward = "Meteor Etch finish with gold inlays" },
        { Name = "Dusk Crate", Cost = 140, Reward = "Dusk Comet two-color aura" },
    },
    Crates = {
        { Name = "Pet Crate", Cost = 100, Pool = "Pets", StandardCount = 5, Equipped = "Pet" },
        { Name = "Pickaxe Crate", Cost = 175, Pool = "Skins", StandardCount = 4, Equipped = "Skin" },
        { Name = "Cosmetic Crate", Cost = 225, Pool = "Auras", StandardCount = 4, Equipped = "Aura" },
    },
    Bags = {
        { Name = "Canvas Pouch", Capacity = 50, Cost = 0 },
        { Name = "Prospector Satchel", Capacity = 85, Cost = 180 },
        { Name = "Trail Pack", Capacity = 135, Cost = 700 },
        { Name = "Tideglass Trunk", Capacity = 215, Cost = 2400 },
        { Name = "Ember Vault", Capacity = 340, Cost = 6900 },
    },
}

local commissionNames = { "Field Survey", "Market Delivery", "Guild Supply Run" }

function config.commission(completed, zone, guided)
    if guided and completed == 0 and zone == 1 then
        return "First Haul", 4, 8, 86
    end
    local kind = completed % #commissionNames + 1
    local nodes = kind == 2 and 0 or 3 + zone
    local crystals = kind == 1 and 0 or (kind == 2 and 25 or 15) * zone
    return commissionNames[kind], nodes, crystals, math.floor((50 + nodes * 9 + crystals) * zone)
end

function config.meadowGuide(progress)
    if progress.Zone ~= 1 or progress.Rebirths > 0 then return end
    local guild = "Guild Commissions"
    local mine = "Mine Entrance"
    local sell = "Sell Crystals"

    if progress.Pick > 1 and progress.Coins >= config.Zones[2].Cost then
        return "Travel to Amethyst Cavern", "Unlock Amethyst Cavern"
    end
    if progress.Orders > 0 and progress.Pick == 1 and progress.Coins >= config.Picks[2].Cost then
        return "Pickaxe Forge", "Forge your Iron pickaxe"
    end
    if progress.OrderZone == 0 then
        return guild, progress.Orders == 0 and "Accept your first commission" or "Take another commission for cavern funds"
    end
    local _, nodes, sales = config.commission(progress.Orders, progress.OrderZone, progress.GuidedOrder == 1)
    if progress.OrderNodes < nodes then
        if progress.Crystals >= progress.Capacity then return sell, "Sell your full crystal bag" end
        return mine, "Mine crystal nodes in Meadow"
    end
    if progress.OrderCrystals < sales then
        if progress.Crystals == 0 then return mine, "Gather crystals to sell" end
        return sell, "Sell crystals at the market"
    end
    return guild, "Claim your commission reward"
end

function config.nextJourneyGoal(progress)
    if progress.Zone < 2 or progress.Rebirths > 0 then return end
    if not progress.Lantern then
        local recipe = config.SurveyorLantern
        local total = math.min(recipe.Cost, progress.Amethyst + progress.Reserve)
        if total >= recipe.Cost then
            return "Craft your lantern at the Meadow workbench"
        end
        return string.format("Surveyor’s Lantern: %d/%d Amethyst", total, recipe.Cost)
    end
    if not config.owns(progress.Auras, config.Resonance.Aura) then
        return "Crystal Resonance: tune the three pulsing veins"
    end
    if progress.Zone == 2 then
        return "Next expedition: Whiteout Relay in Frozen Peaks"
    end
end

function config.zoneCenter(index)
    return (index - 1) * config.ZoneSpacing
end

function config.biomeAt(x)
    if math.abs(x - config.StarterMineX) <= 68 then return config.StarterMineBiome end
    if math.abs(x) <= config.Meadow.Width / 2 then return 1 end
    local index = math.floor(x / config.ZoneSpacing + .5) + 1
    if index >= 2 and index <= #config.Zones and math.abs(x - config.zoneCenter(index)) <= 55 then
        return index
    end
    return nil
end

function config.zoneAt(x)
    local biome = config.biomeAt(x)
    return biome == config.StarterMineBiome and 1 or biome
end

function config.travelAvailability(index, unlocked, coins)
    if index == 0 then return "Free • return to the hub", "Travel", true end
    if index == 1 then return "Free • starter cave", "Travel", true end
    local zone = config.Zones[index]
    if unlocked >= index then return "Unlocked • travel available", "Travel", true end
    if unlocked < index - 1 then
        return "Locked • unlock " .. config.Zones[index - 1].Name .. " first", "Inspect", false
    end
    if coins < zone.Cost then return "Locked • need " .. (zone.Cost - coins) .. " more coins", "Inspect", false end
    return "Locked • " .. zone.Cost .. " coins to unlock", "Unlock and travel", false
end

function config.oreKey(zone)
    return "Ore" .. zone
end

function config.caveRank(zone, mined, surveyed, auras)
    local mastery = config.CaveMastery[zone]
    local surveyedHere = config.owns(surveyed, zone)
    local expeditionDone = not mastery.Expedition or config.owns(auras, config[mastery.Expedition].Aura)
    local rank = 0
    if mined >= mastery.Master and surveyedHere and expeditionDone then
        rank = 2
    elseif mined >= mastery.Prospect then
        rank = 1
    end
    return rank, mastery.Yield[rank] or 0, surveyedHere, expeditionDone
end

function config.emberHeat(elapsed, period)
    local phase = math.max(elapsed, 0) % period / period
    return 1 - math.abs(2 * phase - 1)
end

function config.owns(mask, index)
    return index > 0 and bit32.btest(mask, bit32.lshift(1, index - 1))
end

return config
