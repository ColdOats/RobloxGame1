local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local Pickaxes = require(script.Parent:WaitForChild("Pickaxes"))

local World = {}
local rgb = Color3.fromRGB
local vector = Vector3.new
local material = Enum.Material

local palettes = {
    {
        ground = rgb(73, 119, 73), groundMaterial = material.Grass,
        trail = rgb(168, 143, 111), rock = rgb(95, 109, 104),
    },
    {
        ground = rgb(55, 47, 70), groundMaterial = material.Slate,
        trail = rgb(99, 77, 119), rock = rgb(64, 53, 82),
    },
    {
        ground = rgb(209, 226, 237), groundMaterial = material.Snow,
        trail = rgb(138, 178, 201), rock = rgb(98, 130, 153),
    },
    {
        ground = rgb(91, 127, 112), groundMaterial = material.Slate,
        trail = rgb(176, 164, 130), rock = rgb(84, 108, 97),
    },
    {
        ground = rgb(73, 52, 55), groundMaterial = material.Basalt,
        trail = rgb(133, 86, 68), rock = rgb(63, 49, 54),
    },
}

local darkStone = rgb(53, 61, 69)
local timber = rgb(105, 76, 55)

local function piece(parent, name, size, position, color, surface, solid, shape, rotation, className)
    local object = Instance.new(className or "Part")
    object.Name = name
    object.Size = size
    object.CFrame = rotation and CFrame.new(position) * rotation or CFrame.new(position)
    object.Anchored = true
    object.Color = color
    object.Material = surface
    object.CanCollide = solid == true
    object.CanTouch = false
    object.CanQuery = solid == true
    if shape then
        object.Shape = shape
    end
    object.Parent = parent
    return object
end

local function light(parent, color, brightness, range)
    local glow = Instance.new("PointLight")
    glow.Color = color
    glow.Brightness = brightness
    glow.Range = range
    glow.Parent = parent
end

local function rock(parent, position, size, color)
    return piece(parent, "Rock", size, position, color, material.Slate, false, Enum.PartType.Ball)
end

local function lamp(parent, position, color)
    piece(parent, "Lamp Post", vector(.55, 5, .55), position + vector(0, 2.5, 0), timber, material.Wood, true)
    local bulb = piece(parent, "Lantern", vector(1.4, 1.4, 1.4), position + vector(0, 5.4, 0), color, material.Neon)
    light(bulb, color, 1.25, 16)
end

local mineWarm = rgb(255, 231, 184)

local function mineLamp(parent, position, accent, range)
    local mountHeight = 12.08 - position.Y
    local mount = piece(parent, "Lamp Hanger", vector(.12, mountHeight, .12),
        position + vector(0, mountHeight / 2, 0), darkStone, material.Metal)
    mount.CastShadow = false
    piece(parent, "Mine Lamp Housing", vector(1.36, .38, 1.13), position + vector(0, .34, 0),
        darkStone, material.Metal)
    local lens = piece(parent, "Mine Lamp Lens", vector(1.02, .33, .79), position,
        mineWarm:Lerp(accent, .22), material.Neon)
    lens.CastShadow = false
    light(lens, lens.Color, 2.45, range)
end

local function trailMarker(parent, position, color)
    local stud = piece(parent, "Mine Trail Stud", vector(.7, .07, .4), position, color, material.Neon)
    stud.CastShadow = false
end

local function particles(parent, color, rate, speed, duration, sizes)
    local emitter = Instance.new("ParticleEmitter")
    emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
    emitter.Color = ColorSequence.new(color)
    emitter.Rate = rate
    emitter.Speed = speed
    emitter.Lifetime = duration
    emitter.Size = sizes
    emitter.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, .25),
        NumberSequenceKeypoint.new(.65, .5),
        NumberSequenceKeypoint.new(1, 1),
    })
    emitter.LightEmission = .65
    emitter.SpreadAngle = Vector2.new(35, 35)
    emitter.Parent = parent
    return emitter
end

local function tree(parent, position, height, color)
    local treeModel = Instance.new("Model")
    treeModel.Name = "Meadow Oak"
    treeModel.Parent = parent
    local bark = rgb(99, 70, 51)
    local function limb(from, to, width)
        local length = (to - from).Magnitude
        local cf = CFrame.lookAt((from + to) / 2, to)
        local branch = piece(treeModel, "Bark", vector(width, width, length), cf.Position, bark, material.Wood)
        branch.CFrame = cf
    end

    piece(treeModel, "Trunk", vector(1.45, height, 1.45), position + vector(0, height / 2, 0),
        bark, material.Wood, true)
    for index = 1, 4 do
        local angle = index * math.pi / 2 + height * .1
        local direction = vector(math.cos(angle), 0, math.sin(angle))
        limb(position + vector(0, .55, 0), position + direction * 1.9 + vector(0, .07, 0), .42)
        local tip = position + direction * 2.55 + vector(0, height + index % 2 * .9, 0)
        limb(position + vector(0, height * .57, 0), tip, .52)
        local leaf = color:Lerp(index % 2 == 0 and rgb(130, 183, 83) or rgb(27, 70, 55), .32)
        piece(treeModel, "Leaf Cluster", vector(5.2, 4.5, 5.6), tip, leaf, material.Grass, false, Enum.PartType.Ball)
    end
    piece(treeModel, "Crown", vector(6.1, 5, 5.9), position + vector(0, height + 2.7, 0),
        color:Lerp(rgb(139, 190, 94), .32), material.Grass, false, Enum.PartType.Ball)
end

local function pine(parent, position, height)
    piece(parent, "Pine Trunk", vector(.8, height, .8), position + vector(0, height / 2, 0),
        timber, material.Wood, true)
    for tier = 1, 3 do
        local width = height * (.77 - tier * .15)
        local center = position + vector(0, height * (.27 + tier * .19), 0)
        piece(parent, "Pine Bough", vector(width, height * .35, width), center,
            rgb(56 + tier * 7, 91 + tier * 7, 107 + tier * 8), material.Grass, false, Enum.PartType.Ball)
        piece(parent, "Pine Snowcap", vector(width * .8, height * .17, width * .79),
            center + vector(0, height * .095, 0), rgb(218, 233, 240), material.Snow, false, Enum.PartType.Ball)
    end
end

local shrubStyles = {
    { Name = "Meadow Bramble", Shade = rgb(42, 88, 59), Tip = rgb(109, 151, 68), Accent = rgb(247, 174, 117) },
    { Name = "Cavern Moss", Shade = rgb(57, 69, 73), Tip = rgb(97, 109, 113), Accent = rgb(181, 140, 228) },
    { Name = "Snowberry Shrub", Shade = rgb(58, 91, 112), Tip = rgb(96, 136, 155), Accent = rgb(218, 237, 244), Snow = true },
    { Name = "Tide Fern", Shade = rgb(44, 96, 79), Tip = rgb(111, 164, 113), Accent = rgb(183, 220, 150) },
    { Name = "Cinder Scrub", Shade = rgb(87, 61, 58), Tip = rgb(143, 89, 65), Accent = rgb(229, 143, 80) },
}

local function shrub(parent, position, size, style, rng)
    local ball = Enum.PartType.Ball
    piece(parent, style.Name, vector(2.7, 1.65, 2.35) * size, position + vector(0, .60, 0) * size,
        style.Shade, material.Grass, false, ball)
    for index = 1, 3 do
        local angle = index * math.pi * 2 / 3 + rng:NextNumber(-.26, .26)
        local center = position + vector(math.cos(angle) * 1.14, .58, math.sin(angle) * .88) * size
        local tint = style.Shade:Lerp(style.Tip, rng:NextNumber(.30, .78))
        piece(parent, "Leaf Lobe", vector(1.75, 1.04, 1.62) * size, center, tint, material.Grass, false, ball)
        if index == 1 or (style.Snow and index == 2) then
            local dimensions = style.Snow and vector(.93, .19, .79) or vector(.24, .25, .24)
            local accent = piece(parent, style.Snow and "Snow Dusting" or "Leaf Tip",
                dimensions * size, center + vector(.12, .48, -.09) * size, style.Accent,
                style.Snow and material.Snow or material.SmoothPlastic, false, ball)
            accent.CastShadow = false
        end
    end
end

local function groundCover(parent, position, style, rng)
    local spread = rng:NextNumber(.42, .74)
    for leaf = -1, 1 do
        local height = rng:NextNumber(.56, 1.18)
        local blade = piece(parent, "Ground Cover", vector(.28, height, .19),
            position + vector(leaf * spread * .32, height * .39, leaf * .11),
            style.Tip:Lerp(style.Shade, rng:NextNumber(.1, .65)), material.Grass, false,
            Enum.PartType.Ball, CFrame.Angles(0, rng:NextNumber(-.45, .45), leaf * -.38))
        blade.CastShadow = false
    end
end

local function fillZoneFoliage(parent, zone, x)
    local foliage = Instance.new("Folder")
    foliage.Name = "Foliage"
    foliage.Parent = parent
    local style = shrubStyles[zone]
    local rng = Random.new(6130 + zone)
    for _, side in ipairs({-1, 1}) do
        local spacing = zone == 1 and 9 or 16
        for z = -40, 42, spacing do
            local radius = zone == 4 and 36.5 or zone == 1 and 43 or 39
            local center = vector(x + side * (radius + rng:NextNumber(-1.1, 1.1)), .5, z)
            local size = rng:NextNumber(.69, 1.22) * (zone == 2 and .70 or 1)
            shrub(foliage, center, size, style, rng)
            if (z + 40) % (2 * spacing) == 0 then
                groundCover(foliage, center + vector(side * -2.1, 0, 1.4), style, rng)
            end
        end
        for _, z in ipairs({-42, 15, 32, 45}) do
            local radius = zone == 1 and 31 or zone == 2 and 25 or 30
            local patch = vector(x + side * radius, .5, z)
            groundCover(foliage, patch, style, rng)
            if zone == 1 or zone == 4 then shrub(foliage, patch + vector(side * 2.5, 0, -.5), .76, style, rng) end
        end
    end
end

local function shard(parent, position, height, color, tilt)
    return piece(parent, "Crystal Formation", vector(2.2, height, 2.2), position, color, material.Glass, false,
        nil, CFrame.Angles(0, math.rad(35), math.rad(tilt)))
end

function World.ensureSpawn()
    if workspace:FindFirstChild("MiningStart") then
        return
    end

    local start = Instance.new("Folder")
    start.Name = "MiningStart"
    piece(start, "Meadow Ground", vector(110, 1, 100), vector(0, 0, 0), palettes[1].ground, material.Grass, true)

    local spawn = Instance.new("SpawnLocation")
    spawn.Name = "Mining Spawn"
    spawn.Size = vector(8, 1, 8)
    spawn.Position = vector(0, 1, 0)
    spawn.Anchored = true
    spawn.Neutral = true
    spawn.Parent = start
    start.Parent = workspace
end

function World.create()
    World.ensureSpawn()
    Lighting.ClockTime = 14.15
    Lighting.Brightness = 2.3
    Lighting.Ambient = rgb(139, 142, 151)
    Lighting.OutdoorAmbient = rgb(156, 162, 174)

    local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere")
    atmosphere.Color = rgb(214, 230, 246)
    atmosphere.Decay = rgb(131, 153, 178)
    atmosphere.Density = .20
    atmosphere.Haze = .9
    atmosphere.Parent = Lighting

    local folder = Instance.new("Folder")
    folder.Name = "CrystalWorld"
    folder.Parent = workspace
    return folder
end

function World.zone(parent, index, zone, x)
    local palette = palettes[index]
    local folder = Instance.new("Folder")
    folder.Name = zone.Name
    folder.Parent = parent
    local function at(px, py, pz)
        return vector(x + px, py, pz)
    end

    piece(folder, "Bedrock", vector(110, 16, 100), at(0, -8.55, 0), palette.rock, material.Rock, true)
    if index > 1 then
        piece(folder, "Ground", vector(110, 1, 100), at(0, 0, 0), palette.ground, palette.groundMaterial, true)
    end
    piece(folder, "Main Trail", vector(9, .08, 81), at(0, .54, 1), palette.trail, material.Cobblestone)
    piece(folder, "Mine Trail", vector(89, .08, 7), at(0, .54, -20), palette.trail, material.Cobblestone)

    local rng = Random.new(4100 + index)
    for _, side in ipairs({-1, 1}) do
        for z = -42, 42, 12 do
            local width = rng:NextNumber(6, 10)
            local height = rng:NextNumber(3, 7)
            rock(folder, at(side * rng:NextNumber(48, 51), height / 3, z), vector(width, height, 8), palette.rock)
        end
        lamp(folder, at(side * 7, .5, -7), zone.Color)
        lamp(folder, at(side * 7, .5, -33), zone.Color)
    end

    if index == 1 then
        piece(folder, "Wayshrine Promenade", vector(88, .1, 12), at(0, .55, 38),
            palette.trail, material.Cobblestone)
        World.plaza(folder)
        for _, side in ipairs({-1, 1}) do
            for z = -37, 35, 18 do
                tree(folder, at(side * rng:NextNumber(40, 46), .5, z), rng:NextNumber(6, 10), rgb(57, 117, 75))
                for i = 1, 3 do
                    piece(folder, "Wildflower", vector(.65, .65, .65),
                        at(side * (40 + i * 2), .85, z + 4), rgb(248, 204, 113), material.Grass, false, Enum.PartType.Ball)
                end
            end
        end
    elseif index == 2 then
        piece(folder, "Cavern Vault", vector(106, 9, 78), at(0, 26, -6), palette.rock, material.Slate, true)
        for _, side in ipairs({-1, 1}) do
            for z = -35, 23, 14 do
                piece(folder, "Cave Wall", vector(9, 24, 15), at(side * 49, 12, z), palette.rock, material.Slate, true)
                local formation = shard(folder, at(side * 44, 4, z), rng:NextNumber(5, 9), zone.Color, side * 20)
                light(formation, zone.Color, 1.5, 21)
                shard(folder, at(side * 34, 19, z), rng:NextNumber(4, 8), zone.Color, side * -14)
            end
        end
    elseif index == 3 then
        for _, side in ipairs({-1, 1}) do
            for z = -41, 39, 16 do
                local height = rng:NextNumber(11, 21)
                rock(folder, at(side * 48, height / 3, z), vector(12, height, 14), palette.rock)
                rock(folder, at(side * 48, height * .72, z), vector(8, height * .44, 10), palette.ground)
                shard(folder, at(side * 42, 3.5, z + 3), 7, zone.Color, side * 24)
                if (z + 41) % 32 == 0 then
                    pine(folder, at(side * 43, .5, z - 2), rng:NextNumber(8, 12))
                end
            end
        end
        local overlook = piece(folder, "Frozen Tarn", vector(30, .12, 8), at(0, .57, -44),
            rgb(135, 190, 215), material.Ice)
        overlook.Transparency = .15
        local flurries = particles(overlook, rgb(215, 242, 255), 7, NumberRange.new(.3, .7),
            NumberRange.new(3, 5), NumberSequence.new(.16, .06))
        flurries.Acceleration = vector(.6, .25, 0)
        flurries.Shape = Enum.ParticleEmitterShape.Box
    elseif index == 4 then
        for _, side in ipairs({-1, 1}) do
            local water = piece(folder, "Tidal Channel", vector(9, .08, 68), at(side * 42, .55, 0),
                rgb(51, 145, 139), material.Glass)
            water.Transparency = .18
            local motes = particles(water, rgb(134, 235, 204), 3, NumberRange.new(.35, .7),
                NumberRange.new(2, 4), NumberSequence.new(.14, .07))
            motes.Shape = Enum.ParticleEmitterShape.Box
            motes.Acceleration = vector(.3, .15, 0)
            for z = -32, 32, 16 do
                piece(folder, "Ruin Plinth", vector(5, .7, 5), at(side * 47, .85, z),
                    palette.trail, material.Limestone)
                local height = rng:NextNumber(4, 11)
                piece(folder, "Weathered Column", vector(2.6, height, 2.6), at(side * 47, 1.2 + height / 2, z),
                    palette.trail, material.Limestone, true)
            end
        end
        piece(folder, "Sunken Arch", vector(15, 2, 3), at(0, 9, -39), palette.trail, material.Limestone, true)
        for _, side in ipairs({-1, 1}) do
            piece(folder, "Arch Pier", vector(3, 9, 3), at(side * 6, 5, -39), palette.trail, material.Limestone, true)
        end
    elseif index == 5 then
        for _, side in ipairs({-1, 1}) do
            local seam = piece(folder, "Magma Seam", vector(4, .08, 68), at(side * 44, .55, 0),
                rgb(255, 95, 41), material.Neon)
            light(seam, zone.Color, 1.6, 17)
            local embers = particles(seam, rgb(255, 123, 55), 5, NumberRange.new(1, 2.5),
                NumberRange.new(1.2, 2.5), NumberSequence.new(.19, .04))
            embers.Shape = Enum.ParticleEmitterShape.Box
            embers.Acceleration = vector(.15, 1.1, 0)
            for z = -35, 35, 14 do
                local height = rng:NextNumber(8, 19)
                piece(folder, "Basalt Spire", vector(5, height, 5), at(side * 48, height / 2, z),
                    palette.rock, material.Basalt, false, nil, CFrame.Angles(.13, z / 20, -.16 * side))
                local ember = shard(folder, at(side * 42, 3, z), 5, zone.Color, side * 18)
                ember.Material = material.Neon
            end
        end
        piece(folder, "Forge Dais", vector(26, .8, 8), at(0, .9, -42), palette.rock, material.Metal, true)
        for _, side in ipairs({-1, 1}) do
            lamp(folder, at(side * 9, 1.3, -42), zone.Color)
        end
    end

    local accents = {
        {Name = "Meadow Wildflowers", Color = rgb(249, 187, 111), Material = material.Grass},
        {Name = "Cavern Glowcaps", Color = rgb(196, 125, 249), Material = material.Neon},
        {Name = "Frost Bloom", Color = rgb(184, 224, 244), Material = material.Ice},
        {Name = "Tidal Reeds", Color = rgb(118, 183, 125), Material = material.Grass},
        {Name = "Emberglass", Color = rgb(222, 113, 76), Material = material.Glass},
    }
    local accent = accents[index]
    for _, side in ipairs({-1, 1}) do
        for _, z in ipairs({-42, 4, 29}) do
            for offset = 1, 4 do
                local height = rng:NextNumber(.6, 1.45)
                local position = at(side * (39 + rng:NextNumber(-1.5, 1.5)), .5 + height * .45, z + offset * .9)
                piece(folder, accent.Name, vector(.35, height, .38), position, accent.Color, accent.Material,
                    false, Enum.PartType.Ball, CFrame.Angles(0, 0, rng:NextNumber(-.4, .4)))
            end
        end
    end

    fillZoneFoliage(folder, index, x)
    return folder
end

function World.cavern(parent, x, routes)
    local mine = Instance.new("Folder")
    mine.Name = "Amethyst Cavern Mine"
    mine.Parent = parent
    local stone = palettes[2].rock
    local function at(px, py, pz)
        return vector(x + px, py, pz)
    end
    local function wall(name, px, pz, width, depth)
        return piece(mine, name, vector(width, 11, depth), at(px, 6, pz), stone, material.Slate, true)
    end
    local function trail(name, px, pz, width, depth, tint)
        piece(mine, name, vector(width, .09, depth), at(px, .55, pz), tint, material.Cobblestone)
    end
    local function sign(message, px, pz, tint, yaw)
        local post = piece(mine, "Route Sign", vector(5.8, 1.45, .24), at(px, 4.8, pz),
            rgb(52, 41, 58), material.Wood, false, nil, CFrame.Angles(0, yaw or 0, 0))
        local face = Instance.new("SurfaceGui")
        face.Face = Enum.NormalId.Back
        face.LightInfluence = 0
        face.Parent = post
        local words = Instance.new("TextLabel")
        words.Size = UDim2.fromScale(1, 1)
        words.BackgroundTransparency = 1
        words.TextColor3 = tint
        words.TextScaled = true
        words.Font = Enum.Font.GothamBold
        words.Text = message
        words.Parent = face
    end

    piece(mine, "Deep Floor", vector(88, 1, 34), at(0, 0, -67), palettes[2].ground, material.Slate, true)
    piece(mine, "Deep Bedrock", vector(88, 10, 34), at(0, -5.55, -67), stone, material.Rock, true)
    piece(mine, "Vault", vector(88, 3, 77), at(0, 13, -45), stone, material.Rock, true)
    wall("West Stone", -42, -45, 4, 76)
    wall("East Stone", 42, -45, 4, 76)
    wall("End of the Cavern", 0, -82, 86, 2)
    for _, side in ipairs({-1, 1}) do
        wall("Entrance Wall", side * 25.5, -7, 37, 2)
    end

    wall("Drift Screen", -9, -22, 2, 6)
    wall("Drift Divide", -9, -38, 2, 15)
    wall("Gallery Divide", -9, -66, 2, 20)
    wall("Gallery End Pier", -9, -80, 2, 4)
    wall("Shelf Bedrock", -25, -37, 32, 2.8)
    wall("Echo Screen", 9, -31, 2, 22)
    wall("Echo Deep Divide", 9, -68, 2, 28)
    wall("Echo Bend", 17.5, -26, 18, 2.8)
    wall("Echo Bend", 31, -42, 20, 2.8)

    trail("Entrance Route", 0, -32, 6.4, 50, rgb(110, 93, 136))
    trail("Drift Route", -23, -18, 27, 4, rgb(115, 85, 70))
    trail("Drift Return", -22, -28, 24, 3, rgb(115, 85, 70))
    trail("Echo Route", 23, -18, 27, 3, rgb(99, 69, 143))
    trail("Echo Bend Route", 33.5, -27, 3, 20, rgb(99, 69, 143))
    trail("Echo Bend Route", 22, -35, 24, 3, rgb(99, 69, 143))
    trail("Echo Chamber Route", 15.5, -46, 3, 22, rgb(99, 69, 143))
    trail("Gallery Route", -23, -51, 31, 3, rgb(59, 105, 115))
    trail("Gallery Route", -25, -64, 3, 25, rgb(59, 105, 115))
    for _, z in ipairs({-9, -24, -39, -54}) do
        mineLamp(mine, at(0, 8.5, z), mineWarm, 23)
    end
    for z = -9, -57, -6 do
        for _, side in ipairs({-1, 1}) do
            trailMarker(mine, at(side * 2.65, .66, z), mineWarm)
        end
    end
    for index, route in ipairs(routes) do
        for _, node in ipairs(route.Nodes) do
            local xOffset = index == 2 and 2.2 or -2.2
            mineLamp(mine, at(node[1] + xOffset, 7.7, node[2]), route.Color, 20)
        end
    end
    mineLamp(mine, at(15.5, 8.1, -46.5), routes[2].Color, 20)
    mineLamp(mine, at(22, 8.1, -58), routes[2].Color, 20)
    mineLamp(mine, at(-26, 8.1, -72), routes[3].Color, 20)
    for _, position in ipairs({{-11,-17}, {-16,-18}, {-31,-28}, {11,-17}, {28,-25}, {34,-30},
        {17,-39}, {14,-47}, {17,-54}, {22,-58}, {-11,-51}, {-22,-51}, {-25,-60}, {-25,-68}}) do
        local hue = position[1] > 0 and routes[2].Color or position[2] < -40 and routes[3].Color or routes[1].Color
        trailMarker(mine, at(position[1], .665, position[2]), hue)
    end

    sign("AMETHYST CAVERN", 0, -6.1, rgb(221, 195, 249))
    sign("← Lantern Drift\nQuick haul", -5, -12, routes[1].Color)
    sign("Echo Tunnels →\nRich veins", 5, -12, routes[2].Color)
    sign("← Deep Gallery\nHard ore • return lift", -4.5, -46.7, routes[3].Color)
    sign("Echo Chamber  →", 4.9, -46.7, routes[2].Color)
    sign("↑  Main entrance", 0, -24.2, rgb(255, 217, 158), math.pi)
    sign("↑  Main entrance", 0, -52, rgb(255, 217, 158), math.pi)
    sign("→  Entrance spine", -15, -27.5, routes[1].Color, math.pi / 2)
    sign("Main entrance  ←", 15, -48.4, routes[2].Color, -math.pi / 2)
    sign("Deep lift", -26, -70.3, routes[3].Color)

    local moss = shrubStyles[2]
    local rng = Random.new(42104)
    for _, point in ipairs({{-37, -21}, {-35, -40}, {-37, -70}, {-18, -75}, {37, -31}, {37, -53}, {16, -57}}) do
        local center = at(point[1], .5, point[2])
        shrub(mine, center, .78, moss, rng)
        groundCover(mine, center + vector(1.1, 0, .6), moss, rng)
    end

    local surface = piece(mine, "Cavern Lift", vector(5.8, .5, 5.8), at(-7, .8, 1),
        routes[3].Color, material.Metal, true)
    local deep = piece(mine, "Deep Gallery Lift", vector(5.8, .5, 5.8), at(-26, .8, -71),
        routes[3].Color, material.Metal, true)
    for _, lift in ipairs({surface, deep}) do
        light(lift, routes[3].Color, 1.25, 14)
    end
    return mine, surface, deep
end

function World.mine(parent, zone, index, x)
    local folder = Instance.new("Folder")
    folder.Name = zone.Name .. " Mine"
    folder.Parent = parent
    local stone = palettes[index].rock
    local function at(px, py, pz)
        return vector(x + px, py, pz)
    end
    local function structure(name, size, position, color, surface)
        return piece(folder, name, size, position, color, surface, true)
    end

    structure("Mine Roof", vector(88, 5, 27), at(0, 14.5, -20), stone, material.Rock)
    for _, side in ipairs({-1, 1}) do
        structure("Side Wall", vector(4, 12, 27), at(side * 42, 6.5, -20), stone, material.Rock)
        structure("Entrance Rock", vector(37, 12, 3), at(side * 25.5, 6.5, -7), stone, material.Rock)
        structure("Rear Wall", vector(37, 12, 3), at(side * 25.5, 6.5, -33), stone, material.Rock)
        for _, z in ipairs({-7, -20, -32}) do
            structure("Mine Support", vector(1.25, 11.5, 1.25), at(side * 6, 6.25, z), timber, material.Wood)
            if side == 1 then mineLamp(folder, at(0, 8.45, z), zone.Color, 23) end
        end
        for _, wing in ipairs({17, 32}) do
            mineLamp(folder, at(side * wing, 7.6, -20), zone.Color, 21)
        end
        for z = -10, -30, -5 do
            trailMarker(folder, at(side * 2.9, .66, z), mineWarm)
        end
        for _, z in ipairs({-15, -25}) do
            local crystal = shard(folder, at(side * 39, 5, z), 6, zone.Color, side * 19)
            light(crystal, zone.Color, 1.4, 17)
        end
    end
    local trim = zone.Color:Lerp(stone, .42)
    for _, side in ipairs({-1, 1}) do
        piece(folder, "Inlaid Portal Border", vector(.28, 8.1, .19), at(side * 6.8, 4.75, -5.41),
            trim, material.Metal)
        piece(folder, "Miner's Trail Inlay", vector(.22, .06, 20), at(side * 3.85, .62, -20),
            trim, material.SmoothPlastic)
    end
    local header = structure("Mine Entrance", vector(14, 2, 2), at(0, 10, -7), timber, material.Wood)
    local sign = Instance.new("SurfaceGui")
    sign.Face = Enum.NormalId.Back
    sign.LightInfluence = 0
    sign.Parent = header
    local title = Instance.new("TextLabel")
    title.Size = UDim2.fromScale(1, 1)
    title.BackgroundTransparency = 1
    title.Text = string.upper(zone.Name .. " Mine")
    title.TextColor3 = rgb(255, 232, 174)
    title.TextScaled = true
    title.Font = Enum.Font.GothamBold
    title.Parent = sign
    return folder
end

function World.resident(parent, name, position, yaw, clothing, accent)
    local model = Instance.new("Model")
    model.Name = name
    model.Parent = parent
    local pose = CFrame.new(position) * CFrame.Angles(0, yaw, 0)
    local skin = rgb(211, 166, 130)
    local boots = rgb(57, 48, 53)
    local function feature(partName, size, offset, tint, surface, shape)
        local cf = pose * CFrame.new(offset)
        local object = piece(model, partName, size, cf.Position, tint, surface, false, shape)
        object.CFrame = cf
        return object
    end

    local torso = feature("Coat", vector(1.55, 1.46, .83), vector(0, 2.27, 0), clothing, material.Fabric)
    local ball = Enum.PartType.Ball
    feature("Head", vector(1.08, 1.13, 1.02), vector(0, 3.53, 0), skin, material.SmoothPlastic, ball)
    feature("Hat Brim", vector(1.38, .12, 1.25), vector(0, 3.9, -.09), boots, material.Fabric, ball)
    feature("Hat Crown", vector(1.08, .43, 1), vector(0, 4.03, .01), clothing, material.Fabric, ball)
    feature("Scarf", vector(1.06, .23, .83), vector(0, 3.02, -.04), accent, material.Fabric, ball)
    feature("Scarf Tail", vector(.29, .62, .12), vector(.28, 2.71, -.44), accent, material.Fabric)
    local buckle = feature("Survey Pin", vector(.21, .21, .09), vector(-.39, 2.62, -.435), accent, material.Metal, ball)
    light(buckle, accent, .22, 5)
    for _, side in ipairs({-1, 1}) do
        feature("Eye", vector(.09, .13, .064), vector(side * .19, 3.54, -.478), boots, material.SmoothPlastic, ball)
        feature("Sleeve", vector(.43, 1.15, .53), vector(side * .9, 2.25, .04), clothing, material.Fabric, ball)
        feature("Hand", vector(.34, .37, .37), vector(side * .88, 1.67, -.03), skin, material.SmoothPlastic, ball)
        feature("Trouser Leg", vector(.54, 1.28, .57), vector(side * .36, .89, 0), boots, material.Fabric)
        feature("Boot", vector(.63, .36, .89), vector(side * .36, .19, -.15), boots, material.SmoothPlastic)
    end
    return torso
end

local function shopSign(parent, name, position, size, color, yaw)
    local sign = piece(parent, name .. " Sign", size, position, color, material.WoodPlanks,
        false, nil, CFrame.Angles(0, yaw, 0))
    local face = Instance.new("SurfaceGui")
    face.Face = Enum.NormalId.Back
    face.LightInfluence = 0
    face.MaxDistance = 55
    face.Parent = sign
    local lettering = Instance.new("TextLabel")
    lettering.Position = UDim2.fromScale(.06, .12)
    lettering.Size = UDim2.fromScale(.88, .76)
    lettering.BackgroundTransparency = 1
    lettering.TextColor3 = rgb(255, 247, 220)
    lettering.TextScaled = true
    lettering.Font = Enum.Font.GothamBold
    lettering.Text = name
    lettering.Parent = face
end

function World.meadowLandmarks(parent)
    local timberDark = rgb(104, 76, 57)
    local sandstone = rgb(179, 160, 128)
    local cream = rgb(237, 213, 157)
    local green = rgb(76, 136, 101)
    for _, side in ipairs({-1, 1}) do
        local px = side * 6.9
        piece(parent, "Trailhead Footing", vector(2.15, .68, 2.25),
            vector(px, .84, -5), sandstone, material.Limestone)
        piece(parent, "Trailhead Upright", vector(.69, 8.25, .66),
            vector(px, 4.75, -5), timberDark, material.Wood)
        local signal = piece(parent, "Trailhead Lantern", vector(.81, .94, .78),
            vector(side * 6.14, 5.7, -4.5), cream, material.Neon)
        light(signal, cream, 1.4, 17)
        for step = 1, 3 do
            trailMarker(parent, vector(side * 2.85, .635, -2 - step * 1.35), cream)
        end
    end
    piece(parent, "Trailhead Crossbeam", vector(14.8, .43, .64),
        vector(0, 8.8, -5), timberDark, material.WoodPlanks)
    shopSign(parent, "MEADOW MINE", vector(0, 8.8, -4.63), vector(7.4, 1.42, .3), green, 0)

    shopSign(parent, "SELL CRYSTALS", vector(-17.7, 5.25, 0.15), vector(5.1, 1.3, .22), rgb(127, 82, 46), math.pi / 2)
    shopSign(parent, "PICKAXE FORGE", vector(14.85, 5.3, -.2), vector(5.35, 1.3, .22), rgb(56, 88, 124), -math.pi / 2)
    shopSign(parent, "GUILD COMMISSIONS", vector(-29.4, 5.5, 8.1), vector(5.35, 1.35, .24), rgb(44, 100, 86), math.pi / 2)
end

function World.welcome(parent)
    local cream = rgb(251, 228, 177)
    local green = rgb(51, 92, 78)
    local function board(name, lines, position, width, yaw)
        local orientation = CFrame.Angles(0, yaw or 0, 0)
        local panel = piece(parent, name, vector(width, 2.35, .28), position, green,
            material.WoodPlanks, false, nil, orientation)
        for _, side in ipairs({-1, 1}) do
            local support = panel.CFrame * CFrame.new(side * (width / 2 - .18), -1.14, .16)
            piece(parent, "Sign Post", vector(.32, 3.1, .35), support.Position, timber, material.Wood,
                false, nil, orientation)
        end
        local sign = Instance.new("SurfaceGui")
        sign.Face = Enum.NormalId.Back
        sign.CanvasSize = Vector2.new(480, 152)
        sign.MaxDistance = 55
        sign.LightInfluence = .3
        sign.Parent = panel
        local lettering = Instance.new("TextLabel")
        lettering.Position = UDim2.fromScale(.055, .07)
        lettering.Size = UDim2.fromScale(.89, .86)
        lettering.BackgroundTransparency = 1
        lettering.Font = Enum.Font.GothamBold
        lettering.TextColor3 = cream
        lettering.Text = lines
        lettering.TextScaled = true
        lettering.TextWrapped = true
        lettering.Parent = sign
    end

    board("Meadow Welcome", "Welcome to Meadow\nMine crystals. Sell your haul. Upgrade your gear.", vector(-10.5, 3.22, -3.3), 8, -.22)
    board("Market Directions", "← Sell crystals     Mine ↑     Forge →", vector(10.6, 3.12, -3.5), 8, .23)
    board("Wayshrine Directions", "Market Square  •  Crates  •  Wayshrines", vector(-8.2, 3.26, 21.4), 8.4, math.pi)
    local path = rgb(209, 179, 130)
    for _, side in ipairs({-1, 1}) do
        for step = 1, 4 do
            piece(parent, "Market Stepping Stone", vector(2.8, .06, 2.15), vector(side * (5.2 + step * 2.15), .56, .4),
                path, material.Limestone, false, nil, CFrame.Angles(0, step % 2 * .12, 0))
        end
        local center = vector(side * 14, .5, -3.7)
        piece(parent, "Welcome Planter", vector(4.3, .72, 1.9), center + vector(0, .36, 0), timber, material.WoodPlanks)
        for index = -2, 2 do
            local position = center + vector(index * .73, .87, index % 2 * .32 - .15)
            piece(parent, "Welcome Blossom", vector(.48, .6, .48), position,
                index % 2 == 0 and rgb(244, 181, 116) or rgb(237, 141, 158), material.Grass, false, Enum.PartType.Ball)
        end
    end
end

function World.plaza(parent)
    local center = vector(0, 1, 13)
    local basin = piece(parent, "Fountain Basin", vector(1, 10, 10), center, rgb(99, 126, 138),
        material.Marble, true, Enum.PartType.Cylinder, CFrame.Angles(0, 0, math.pi / 2))
    local water = piece(parent, "Fountain Pool", vector(.08, 8.6, 8.6), center + vector(0, .54, 0),
        rgb(72, 189, 209), material.Glass, false, Enum.PartType.Cylinder, CFrame.Angles(0, 0, math.pi / 2))
    water.Reflectance = .16
    local spout = piece(parent, "Fountain Spout", vector(1.1, 1.5, 1.1), basin.Position + vector(0, 1.1, 0),
        rgb(215, 188, 119), material.Metal, false, Enum.PartType.Ball)
    local spray = particles(spout, rgb(172, 243, 251), 21, NumberRange.new(5, 8),
        NumberRange.new(.55, .85), NumberSequence.new(.23, .08))
    spray.Acceleration = vector(0, -17, 0)
    spray.SpreadAngle = Vector2.new(48, 48)
    piece(parent, "Market Square", vector(62, .12, 30), vector(0, .56, 7), rgb(180, 155, 125), material.Cobblestone)
    for _, side in ipairs({-1, 1}) do
        piece(parent, "Plaza Border", vector(61, .12, 1), vector(0, .64, 7 + side * 14),
            rgb(219, 199, 161), material.Limestone)
        for _, z in ipairs({-6, 21}) do
            local position = vector(side * 29, .5, z)
            lamp(parent, position, rgb(255, 188, 107))
            piece(parent, "Bunting Pole", vector(.25, 2, .25), vector(side * 28.8, 6.3, z), timber, material.Wood)
            piece(parent, "Pennant Tie", vector(2.9, .065, .065), vector(side * 27.35, 7.26, z), timber, material.Fabric)
            piece(parent, "Flower Box", vector(2.5, .8, 2.5), position + vector(0, .4, 0), timber, material.Wood, true)
            for index = 1, 4 do
                piece(parent, "Market Flowers", vector(.5, .7, .5),
                    position + vector(math.cos(index * math.pi / 2) * .85, .86, math.sin(index * math.pi / 2) * .85),
                    index % 2 == 0 and rgb(254, 139, 109) or rgb(247, 207, 93), material.Grass, false, Enum.PartType.Ball)
            end
        end
    end
    for _, side in ipairs({-1, 1}) do
        local spot = vector(side * 11.5, .5, 15)
        local seat = piece(parent, "Market Bench", vector(4.6, .4, 1.65), spot + vector(0, 1, 0),
            timber, material.WoodPlanks, true, nil, nil, "Seat")
        seat.CanTouch = true
        for _, foot in ipairs({-1, 1}) do
            piece(parent, "Bench Leg", vector(.38, .8, 1.3), spot + vector(foot * 1.65, .4, 0),
                darkStone, material.Slate)
        end
        piece(parent, "Bench Back", vector(4.6, .88, .23), seat.Position + vector(0, .63, .74),
            timber, material.WoodPlanks)
    end
    local bunting = {rgb(255, 167, 82), rgb(92, 218, 204), rgb(246, 117, 162), rgb(157, 138, 238)}
    for _, z in ipairs({-6, 21}) do
        for index = -7, 7 do
            local height = 5.7 + math.abs(index) * .16
            piece(parent, "Pennant", vector(1.25, .95, .15), vector(index * 3.7, height, z),
                bunting[index % #bunting + 1], material.Fabric, false, nil, CFrame.Angles(0, 0, index * -.025))
            if index < 7 then
                local from = vector(index * 3.7, height + .44, z)
                local to = vector((index + 1) * 3.7, 6.14 + math.abs(index + 1) * .16, z)
                local cord = piece(parent, "Pennant Cord", vector(.055, .055, (to - from).Magnitude),
                    (from + to) / 2, timber, material.Fabric)
                cord.CFrame = CFrame.lookAt((from + to) / 2, to)
            end
        end
    end
end

function World.landmark(parent, zone, x, index)
    local position = vector(x + (index % 2 == 0 and -31 or 31), 2.3, -39)
    if index == 2 then position = vector(x + 27, 2.3, -73) end
    piece(parent, "Survey Platform", vector(10, .6, 8), position - vector(0, 1.5, 0),
        palettes[index].trail, material.Cobblestone, true)
    piece(parent, "Survey Plinth", vector(3.8, 2.4, 3.8), position - vector(0, .2, 0),
        palettes[index].rock, material.Slate, true)
    local beacon = piece(parent, zone.Landmark, vector(2.1, 2.1, 2.1), position + vector(0, 2.3, 0),
        zone.Color, material.Neon, false, Enum.PartType.Ball)
    light(beacon, zone.Color, 2, 20)
    return beacon
end

function World.station(parent, anchor, color)
    local position = anchor.Position
    for _, dx in ipairs({-4.15, 4.15}) do
        piece(parent, "Canopy Support", vector(.55, 6, .55), position + vector(dx, 1.5, 3.8), timber, material.Wood, true)
    end
    piece(parent, "Canopy", vector(10, .45, 9), position + vector(0, 4.7, 0), color, material.Fabric, true)
    piece(parent, "Counter Trim", vector(9.3, .4, 9.3), position + vector(0, 1.85, 0), timber, material.Wood)
    for stripe = -4, 4 do
        local fabric = stripe % 2 == 0 and color or rgb(246, 222, 178)
        piece(parent, "Awning Stripe", vector(1.1, .2, 3.5), position + vector(stripe * 1.1, 4.2, -4.45),
            fabric, material.Fabric, false, nil, CFrame.Angles(math.rad(-12), 0, 0))
    end
    local accent = piece(parent, "Shop Emblem", vector(1.55, 1.55, .45), position + vector(0, 2.65, -4.8),
        color, material.Neon, false, nil, CFrame.Angles(0, 0, math.rad(45)))
    light(accent, color, 1.3, 10)
end

function World.forge(parent, anchor, picks)
    local position = anchor.Position
    local function at(x, y, z)
        return position + vector(x, y, z)
    end

    anchor.Size = vector(10, 3.4, 4)
    anchor.Color = darkStone
    anchor.Material = material.Brick
    piece(parent, "Forge Countertop", vector(10.8, .45, 4.7), at(0, 1.8, 0), timber, material.Wood)
    piece(parent, "Copper Fascia", vector(9.6, .6, .12), at(0, .9, -2.06), rgb(211, 127, 73), material.Metal)
    piece(parent, "Workshop Floor", vector(17, .1, 12), at(0, -1.45, 2), rgb(114, 104, 102), material.Pavement)
    for _, side in ipairs({-1, 1}) do
        piece(parent, "Forge Post", vector(.65, 7.1, .65), at(side * 7.6, 2, 5.2), timber, material.Wood, true)
    end
    piece(parent, "Copper Roof", vector(17, .4, 8), at(0, 5.6, 3), rgb(146, 73, 51), material.Metal, true,
        nil, CFrame.Angles(math.rad(-8), 0, 0))
    piece(parent, "Tool Rack", vector(14.8, 3.7, .5), at(0, 2.6, 5), rgb(60, 41, 40), material.WoodPlanks, true)
    for tier in ipairs(picks) do
        local offset = (tier - (#picks + 1) / 2) * 2.3
        Pickaxes.model(parent, CFrame.new(at(offset, 2.55, 4.58)) * CFrame.Angles(0, 0, math.rad(-12)), tier, true)
        piece(parent, "Rack Marker", vector(1.1, .2, .12), at(offset, .9, 4.68), Pickaxes.color(tier), material.Neon)
    end
    local forge = piece(parent, "Forge Hearth", vector(2.6, 2.6, 3), at(-6, 0, 2.8), darkStone, material.Brick, true)
    local heat = piece(parent, "Hot Coals", vector(2.2, .18, 2.6), forge.Position + vector(0, 1.31, 0),
        rgb(255, 118, 61), material.Neon)
    light(heat, heat.Color, 2, 16)
    piece(parent, "Anvil Base", vector(1.15, 1.1, 1.3), at(6.1, -.85, 2.8), darkStone, material.Metal)
    piece(parent, "Anvil", vector(2.6, .5, 1.35), at(6.1, -.12, 2.8), rgb(87, 100, 115), material.Metal)
end

function World.compassStand(parent, anchor)
    anchor.Material = material.WoodPlanks
    local top = anchor.Position + vector(0, 1.19, 0)
    piece(parent, "Compass Counter", vector(4.6, .4, 2.85), top, timber, material.Wood)
    local brass = rgb(220, 171, 96)
    local surface = top + vector(0, .29, 0)
    piece(parent, "Compass Dial", vector(.21, 1.67, 1.67), surface, brass, material.Metal,
        false, Enum.PartType.Cylinder, CFrame.Angles(0, 0, math.pi / 2))
    piece(parent, "Compass Needle", vector(.19, .11, 1.17), surface + vector(0, .12, 0),
        rgb(125, 229, 183), material.Neon, false, nil, CFrame.Angles(0, -.56, 0))
end

function World.geodeStand(parent, anchor, zones)
    local origin = anchor.Position
    anchor.Material = material.WoodPlanks
    piece(parent, "Appraiser Counter", vector(7.5, .4, 4), origin + vector(0, 1.5, 0), timber, material.Wood)
    piece(parent, "Display Felt", vector(6.9, .14, 2.25), origin + vector(0, 1.77, .24),
        rgb(50, 83, 76), material.Fabric)
    for index, zone in ipairs(zones) do
        local sample = piece(parent, "Specimen Display", vector(.54, .82, .62),
            origin + vector((index - 3) * 1.22, 2.16, .22), zone.Color, material.Glass,
            false, nil, CFrame.Angles(.2, index * .57, -.24))
        sample.Reflectance = .12
    end
    for _, side in ipairs({-1, 1}) do
        piece(parent, "Greenhouse Post", vector(.42, 5.4, .42), origin + vector(side * 3.8, 1.75, 1.4),
            timber, material.Wood, true)
    end
    piece(parent, "Appraiser Awning", vector(8.5, .38, 4.6), origin + vector(0, 4.35, .25),
        rgb(75, 120, 97), material.Fabric)
end

function World.surveyorWorkbench(parent, anchor)
    local origin = anchor.Position
    local brass = rgb(219, 167, 102)
    local violet = rgb(191, 143, 244)
    anchor.Material = material.WoodPlanks
    piece(parent, "Surveyor Counter", vector(6.8, .34, 3.65), origin + vector(0, 1.46, 0),
        timber, material.Wood)
    piece(parent, "Workbench Trim", vector(6.4, .27, .13), origin + vector(0, 1.07, -1.66),
        brass, material.Metal)
    for _, side in ipairs({-1, 1}) do
        piece(parent, "Workbench Support", vector(.45, 5.6, .45), origin + vector(side * 3.15, 1.48, 1.48),
            timber, material.Wood, true)
    end
    piece(parent, "Surveyor Canopy", vector(7.35, .35, 4.8), origin + vector(0, 4.38, .4),
        rgb(107, 78, 131), material.Fabric)
    local lamp = piece(parent, "Amethyst Lantern Display", vector(.9, 1.35, .9), origin + vector(2.1, 2.23, -.43),
        violet, material.Neon)
    light(lamp, violet, 1.65, 13)
    for _, height in ipairs({1.69, 2.99}) do
        piece(parent, "Display Lantern Fitting", vector(1.13, .22, 1.13), origin + vector(2.1, height, -.43),
            brass, material.Metal)
    end
end

function World.surveyorLantern(root)
    if root:FindFirstChild("SurveyorLantern") then return end
    local model = Instance.new("Model")
    model.Name = "SurveyorLantern"
    model.Parent = root
    local violet = rgb(194, 158, 253)
    local brass = rgb(225, 175, 102)
    local origin = CFrame.new(-1.33, -.43, .28)
    local function fitting(name, size, height, tint, surface)
        local part = piece(model, name, size, root.Position, tint, surface)
        part.CFrame = root.CFrame * origin * CFrame.new(0, height, 0)
        part.Massless = true
        part.Anchored = false
        local weld = Instance.new("WeldConstraint")
        weld.Part0, weld.Part1 = root, part
        weld.Parent = part
        return part
    end
    local glass = fitting("Lantern Crystal", vector(.39, .55, .39), 0, violet, material.Neon)
    fitting("Lantern Cap", vector(.53, .11, .53), .29, brass, material.Metal)
    fitting("Lantern Base", vector(.53, .11, .53), -.29, brass, material.Metal)
    light(glass, violet, .7, 9)
end

function World.celebrate(anchor, count)
    local burst = anchor:FindFirstChild("Trade Sparks")
    if not burst then
        burst = particles(anchor, rgb(255, 202, 105), 0, NumberRange.new(4, 7),
            NumberRange.new(.4, .8), NumberSequence.new(.34, .12))
        burst.Name = "Trade Sparks"
        burst.SpreadAngle = Vector2.new(95, 95)
        burst.Acceleration = vector(0, -6, 0)
    end
    burst:Emit(count)
end

function World.kiosk(parent, anchor, color, guild)
    anchor.Size = vector(6.8, 3.2, 3.2)
    anchor.Material = material.WoodPlanks
    local base = anchor.Position
    piece(parent, "Stall Landing", vector(9, .11, 9), base + vector(0, -1.45, -.5),
        rgb(164, 133, 104), material.Cobblestone)
    piece(parent, "Counter", vector(7.4, .3, 3.7), base + vector(0, 1.67, 0), timber, material.Wood)
    for _, side in ipairs({-1, 1}) do
        piece(parent, "Stall Post", vector(.42, 6.5, .42), base + vector(side * 3.35, 1.75, 1.35),
            timber, material.Wood, true)
    end
    for strip = -3, 3 do
        piece(parent, "Canvas Awning", vector(1.05, .22, 4.8), base + vector(strip * 1.05, 4.65, .3),
            strip % 2 == 0 and color or rgb(255, 219, 156), material.Fabric)
    end
    if guild then
        piece(parent, "Notice Board", vector(4.8, 2.1, .2), base + vector(0, 3.02, 1.25), timber, material.Wood)
        for index = -1, 1 do
            piece(parent, "Pinned Commission", vector(.95, 1.24, .05),
                base + vector(index * 1.36, 3.09 - math.abs(index) * .14, 1.12),
                rgb(245, 217, 155), material.Fabric, false, nil, CFrame.Angles(0, 0, index * .12))
        end
    else
        for index = -1, 1 do
            local size = 1.25 + index * .2
            piece(parent, "Display Satchel", vector(size, 1.05, .75), base + vector(index * 1.9, 2.25, 0),
                color:Lerp(timber, .18 + index * .12), material.Fabric, false, Enum.PartType.Ball)
            piece(parent, "Brass Buckle", vector(.21, .26, .08), base + vector(index * 1.9, 2.21, -.38),
                rgb(228, 166, 73), material.Metal)
        end
    end
end

function World.crateStand(parent, anchor, color)
    local origin = anchor.Position
    anchor.Material = material.WoodPlanks
    anchor.Color = timber
    piece(parent, "Crate Counter", vector(6.6, .35, 5.5), origin + vector(0, 1.45, 0), darkStone, material.Slate)
    local box = origin + vector(0, 2.45, 0)
    piece(parent, "Prize Chest", vector(3.5, 1.6, 2.2), box, color, material.Wood)
    piece(anchor, "Prize Chest Lid", vector(3.6, .4, 2.3), box + vector(0, .86, 0), color, material.Metal)
    local brass = rgb(230, 175, 91)
    for _, side in ipairs({-1, 1}) do
        piece(parent, "Brass Binding", vector(.32, 1.95, 2.27), box + vector(side * 1.14, .12, 0), brass, material.Metal)
    end
    local lock = piece(parent, "Crystal Clasp", vector(.42, .43, .19), box + vector(0, .09, -1.15),
        color:Lerp(rgb(255, 255, 244), .45), material.Neon)
    light(lock, color, 1.3, 12)
end

function World.revealCrate(anchor)
    local lid = anchor:FindFirstChild("Prize Chest Lid")
    if not lid or lid:GetAttribute("Opening") then return end
    lid:SetAttribute("Opening", true)
    local rest = lid.CFrame
    local peek = rest * CFrame.new(0, .55, .45) * CFrame.Angles(math.rad(34), 0, 0)
    local open = TweenService:Create(lid, TweenInfo.new(.2, Enum.EasingStyle.Back), {CFrame = peek})
    open:Play()
    task.delay(.65, function()
        if not lid:IsDescendantOf(workspace) then return end
        local shut = TweenService:Create(lid, TweenInfo.new(.24), {CFrame = rest})
        shut:Play()
        shut.Completed:Wait()
        lid:SetAttribute("Opening", false)
    end)
end

function World.playerStyle(root, pet, aura)
    for _, name in ipairs({"MiningAura", "MiningCompanion"}) do
        local previous = root:FindFirstChild(name)
        if previous then previous:Destroy() end
    end
    if aura then
        local anchor = Instance.new("Attachment")
        anchor.Name = "MiningAura"
        anchor.Position = vector(0, -1.7, 0)
        anchor.Parent = root
        local drift = particles(anchor, aura.Color, 5, NumberRange.new(.6, 1.4),
            NumberRange.new(.6, 1.1), NumberSequence.new(.27, .10))
        drift.Acceleration = vector(0, 1.2, 0)
        if aura.Accent then
            drift.Color = ColorSequence.new(aura.Color, aura.Accent)
            local tail = particles(anchor, aura.Accent, 3, NumberRange.new(.4, 1.1),
                NumberRange.new(.7, 1.3), NumberSequence.new(.18, .04))
            tail.Acceleration = vector(0, .7, 0)
            tail.SpreadAngle = Vector2.new(85, 85)
        end
    end
    if not pet then return end
    local buddy = Instance.new("Model")
    buddy.Name = "MiningCompanion"
    buddy.Parent = root
    local function petPart(name, size, position, color, shape, surface)
        local part = piece(buddy, name, size, root.Position, color, surface or material.SmoothPlastic, false, shape)
        part.CFrame = root.CFrame * CFrame.new(vector(2.15, .8, .55) + position)
        part.Massless = true
        local weld = Instance.new("WeldConstraint")
        part.Anchored = false
        weld.Part0 = root
        weld.Part1 = part
        weld.Parent = part
    end
    local ball = Enum.PartType.Ball
    local soft = pet.Color:Lerp(rgb(255, 251, 223), .47)
    petPart("Body", vector(1.28, 1.09, 1.15), vector(0, 0, .15), pet.Color, ball)
    petPart("Head", vector(1.18, 1, .9), vector(0, .35, -.35), pet.Color, ball)
    for _, side in ipairs({-1, 1}) do
        local earHeight = pet.Name == "Gem Fox" and .76 or .4
        petPart("Ear", vector(.29, earHeight, .31), vector(side * .33, .79 + earHeight / 3, -.29), soft, ball)
        if pet.Name == "Crystal Dragon" or pet.Name == "Frost Owl" then
            petPart("Wing", vector(.44, .5, .8), vector(side * .63, .19, .3), soft, ball)
        end
        petPart("Eye", vector(.16, .2, .09), vector(side * .24, .45, -.77), rgb(38, 33, 56), ball)
        petPart("Paw", vector(.31, .28, .34), vector(side * .36, -.36, -.24), soft, ball)
    end
    if pet.Name == "Ember Sprite" then
        petPart("Ember Crest", vector(.42, .57, .36), vector(0, 1.03, -.15), soft, ball, material.Neon)
    end
    petPart("Crystal Tail", vector(.38, .44, .52), vector(0, .33, .79), soft, ball, material.Neon)
end

function World.portal(parent, anchor, color)
    local position = anchor.Position
    for _, dx in ipairs({-3.7, 3.7}) do
        piece(parent, "Wayshrine Pillar", vector(1.25, 5.8, 1.25), position + vector(dx, 2, 1.9), darkStone, material.Slate, true)
    end
    local lintel = piece(parent, "Wayshrine Arch", vector(8.6, .8, 1.4), position + vector(0, 5.1, 1.9), darkStone, material.Slate, true)
    light(lintel, color, 2, 19)
end

function World.emberheart(parent, x)
    local iron = rgb(62, 53, 61)
    local copper = rgb(176, 99, 70)
    local fire = rgb(255, 126, 63)
    local function at(px, py, pz)
        return vector(x + px, py, pz)
    end

    piece(parent, "Tempering Forecourt", vector(20, .15, 15), at(0, .58, 28), copper, material.Basalt)
    local anvil = piece(parent, "Emberheart Anvil", vector(6, 2.8, 3.8), at(0, 1.93, 29),
        iron, material.Metal, true)
    piece(parent, "Tempering Surface", vector(6.8, .68, 4.2), at(0, 3.53, 29), copper, material.Metal)
    local core = piece(parent, "Emberheart Core", vector(2.2, 2.2, 2.2), at(0, 4.8, 29),
        fire, material.Neon, false, nil, CFrame.Angles(math.rad(27), math.rad(36), math.rad(22)))
    light(core, fire, 2.7, 22)
    local sparks = particles(core, fire, 4, NumberRange.new(2.5, 4.5),
        NumberRange.new(.45, .95), NumberSequence.new(.31, .07))
    sparks.Acceleration = vector(0, 3, 0)
    for _, side in ipairs({-1, 1}) do
        piece(parent, "Forged Arch Upright", vector(1.2, 8, 1.45), at(side * 5.7, 4.65, 31),
            iron, material.Metal, true)
        local rivet = piece(parent, "Heated Rail", vector(.24, 5.7, .38), at(side * 5.7, 4.63, 30.14),
            fire, material.Neon)
        light(rivet, fire, 1.4, 13)
    end
    piece(parent, "Forged Arch Lintel", vector(12.9, 1.45, 1.45), at(0, 8.15, 31),
        iron, material.Metal, true)
    return anvil, sparks
end

function World.tidekeeper(parent, x, dials)
    local bronze = rgb(178, 144, 92)
    local marble = rgb(145, 179, 158)
    local turquoise = rgb(94, 222, 188)
    local function at(px, py, pz)
        return vector(x + px, py, pz)
    end

    piece(parent, "Shrine Platform", vector(16, .35, 13), at(0, .67, 26), bronze, material.Limestone)
    local altar = piece(parent, "Tidekeeper Altar", vector(6.4, 2.45, 3.1), at(0, 1.74, 27),
        marble, material.Marble, true)
    local bowl = piece(parent, "Tidal Basin", vector(.38, 5.5, 5.5), at(0, 3.12, 27), turquoise,
        material.Glass, false, Enum.PartType.Cylinder, CFrame.Angles(0, 0, math.pi / 2))
    local current = particles(bowl, turquoise, 3, NumberRange.new(.7, 1.4), NumberRange.new(.8, 1.5),
        NumberSequence.new(.2, .04))
    current.Acceleration = vector(.1, .7, 0)
    light(bowl, turquoise, 1.7, 18)
    for _, side in ipairs({-1, 1}) do
        local base = at(side * 5.8, .5, 27)
        piece(parent, "Tidal Column", vector(1.8, 6.4, 2), base + vector(0, 3.2, 0), marble, material.Limestone, true)
        piece(parent, "Bronze Capital", vector(2.3, .37, 2.5), base + vector(0, 6.45, 0), bronze, material.Metal)
    end
    piece(parent, "Tidekeeper Lintel", vector(13.5, 1.1, 2), at(0, 7.6, 27), marble, material.Limestone, true)

    local stations = {}
    for index, dial in ipairs(dials) do
        local origin = at(dial.X, .5, dial.Z)
        piece(parent, "Dial Plinth", vector(3.9, .36, 3.9), origin + vector(0, .18, 0), marble, material.Limestone)
        local post = piece(parent, dial.Name, vector(1.6, 2.45, 1.6), origin + vector(0, 1.23, 0),
            marble, material.Marble, true)
        local face = piece(parent, "Bronze Dial Face", vector(.55, 2.35, 2.35), origin + vector(0, 2.74, 0),
            bronze, material.Metal, false, Enum.PartType.Cylinder, CFrame.Angles(0, math.pi / 2, 0))
        for point = 0, 2 do
            local angle = point * math.pi * 2 / 3
            piece(parent, "Tidal Stud", vector(.21, .21, .21), face.Position + vector(math.sin(angle) * .69, math.cos(angle) * .69, -.31),
                turquoise, material.Neon, false, Enum.PartType.Ball)
        end
        light(face, turquoise, 1.15, 12)
        stations[index] = post
    end
    return altar, stations
end

function World.whiteout(parent, x, route)
    local ice = rgb(143, 222, 253)
    local warm = rgb(255, 197, 118)
    local shelter = piece(parent, "Whiteout Shelter", vector(5.3, 2.5, 3), vector(x, 1.75, 23),
        timber, material.WoodPlanks, true)
    for _, side in ipairs({-1, 1}) do
        piece(parent, "Shelter Support", vector(.55, 5.7, .55), vector(x + side * 3.4, 3.35, 24.15),
            timber, material.Wood, true)
    end
    piece(parent, "Shelter Roof", vector(8, .45, 5.4), vector(x, 6.2, 23.6), rgb(100, 140, 166),
        material.WoodPlanks, true, nil, CFrame.Angles(math.rad(9), 0, 0))
    local fire = piece(parent, "Shelter Lantern", vector(1, 1.25, 1), vector(x, 3.62, 23),
        warm, material.Neon, false, Enum.PartType.Ball)
    light(fire, warm, 2, 17)

    local beacons = {}
    for index, stop in ipairs(route) do
        local origin = vector(x + stop.X, .5, stop.Z)
        piece(parent, "Beacon Footing", vector(3.8, .32, 3.8), origin + vector(0, .13, 0),
            rgb(170, 201, 216), material.Slate)
        local beacon = piece(parent, stop.Name, vector(.95, 3.3, .95), origin + vector(0, 1.65, 0),
            rgb(77, 114, 142), material.Metal, true)
        local crystal = piece(parent, "Frost Beacon Lens", vector(1.2, 1.35, 1.2), origin + vector(0, 3.7, 0),
            ice, material.Neon, false, Enum.PartType.Ball)
        light(crystal, ice, 1.5, 15)
        local plume = particles(crystal, ice, 0, NumberRange.new(2.5, 5), NumberRange.new(.55, 1.05),
            NumberSequence.new(.27, .06))
        plume.Acceleration = vector(0, 2.5, 0)
        beacons[index] = { Anchor = beacon, Pulse = plume }
    end
    return shelter, beacons
end

function World.masterExpedition(mine, x)
    local chamber = Instance.new("Folder")
    chamber.Name = "Heartstone Descent"
    chamber.Parent = mine
    local stone = rgb(66, 54, 86)
    local quartz = rgb(194, 151, 247)
    local amber = rgb(249, 204, 130)
    local function at(px, py, pz)
        return vector(x + px, py, pz)
    end
    local function slab(name, size, pos)
        return piece(chamber, name, size, pos, stone, material.Slate, true)
    end
    local function pedestal(name, px, pz, color)
        local base = slab(name, vector(2.2, 2.4, 2.2), at(px, 1.7, pz))
        local lens = piece(chamber, "Survey Crystal", vector(.74, 1.23, .74), at(px, 3.21, pz),
            color, material.Neon, false, nil, CFrame.Angles(.21, .4, -.18))
        light(lens, color, 1.3, 13)
        return base
    end
    slab("Descent Floor", vector(68, 1, 68), at(0, 0, -127))
    slab("Descent Vault", vector(68, 3, 68), at(0, 13.6, -127))
    for _, side in ipairs({-1, 1}) do
        slab("Outer Wall", vector(2, 12, 68), at(side * 33, 6.5, -127))
        slab("Checkpoint Wall", vector(25, 12, 2), at(side * 20, 6.5, -128))
        slab("Deep Buttress", vector(4.5, 12, 10), at(side * 13, 6.5, -143))
        for _, z in ipairs({-104, -122, -145, -154}) do
            mineLamp(chamber, at(side * 16, 8, z), z < -130 and quartz or amber, 22)
        end
    end
    slab("Entry Wall", vector(68, 12, 2), at(0, 6.5, -94))
    slab("Far Wall", vector(68, 12, 2), at(0, 6.5, -160))
    for z = -100, -153, -6 do
        trailMarker(chamber, at(-2.1, .62, z), z < -128 and quartz or amber)
        trailMarker(chamber, at(2.1, .62, z), z < -128 and quartz or amber)
    end
    local entry = pedestal("Master Expedition", -23, -77, quartz)
    local cache = pedestal("Heartstone Cache", 0, -155, quartz)
    local crystal = shard(chamber, at(0, 4.7, -155), 3.4, quartz, 15)
    light(crystal, quartz, 2, 18)
    return {
        Entry = entry, Start = at(0, 4, -100), Return = at(-23, 4, -74),
        Survey = {pedestal("West Survey Stake", -18, -110, amber), pedestal("East Survey Stake", 18, -115, amber)},
        Bank = pedestal("Bank the Survey Haul", -6, -122, amber),
        Press = pedestal("Press On for Heartstone", 6, -122, quartz),
        Deep = {pedestal("West Heartstone Seam", -22, -145, quartz), pedestal("East Heartstone Seam", 22, -149, quartz)},
        Cache = cache,
        Exits = {pedestal("Return to Deep Gallery", 7, -99, amber), pedestal("Emergency Lift", 26, -155, amber)},
    }
end

function World.heartstoneDisplay(parent, origin)
    local base = piece(parent, "Heartstone Display", vector(5.4, 2.4, 3.5), origin,
        rgb(69, 87, 91), material.Slate, true)
    local gem = shard(parent, origin + vector(0, 2.7, 0), 2.35, rgb(215, 163, 250), 14)
    gem.Transparency = 1
    local shine = Instance.new("PointLight")
    shine.Color = gem.Color
    shine.Range = 12
    shine.Brightness = 1.4
    shine.Enabled = false
    shine.Parent = gem
    return base, function()
        gem.Transparency = 0
        shine.Enabled = true
    end
end

function World.resonance(mine, x, color)
    local stone = rgb(54, 39, 74)
    local glow = rgb(220, 159, 255)
    local function at(px, py, pz)
        return vector(x + 22 + px, py, pz - 28)
    end
    local function block(name, size, position)
        return piece(mine, name, size, position, stone, material.Slate, true)
    end

    block("Chamber Roof", vector(23, 3, 17), at(0, 12, -41.5))
    block("Chamber Back", vector(23, 10.5, 2), at(0, 5.65, -49))
    for _, side in ipairs({-1, 1}) do
        block("Chamber Wall", vector(2, 10.5, 17), at(side * 10.5, 5.65, -41.5))
        block("Door Pier", vector(6, 10.5, 2), at(side * 7, 5.65, -34))
        local stripe = piece(mine, "Door Rune", vector(.5, 7, .17), at(side * 4.4, 4.45, -32.92),
            glow, material.Neon)
        light(stripe, color, 1.3, 15)
    end
    block("Door Lintel", vector(8, 2, 2), at(0, 10, -34))
    local door = block("Resonance Gate", vector(8, 8.5, 1), at(0, 4.7, -34))
    local closed = door.CFrame
    local status = piece(mine, "Crystal Resonance", vector(1, 1, 1), at(0, 4.4, -31),
        color, material.SmoothPlastic)
    status.Transparency = 1
    local cache = piece(mine, "Echo Deposit", vector(4.4, 2.2, 3.8), at(0, 1.58, -44),
        stone, material.Slate, true)
    local exit = piece(mine, "Chamber Exit", vector(1.15, 2.7, 1.15), at(6, 1.86, -38),
        color, material.Neon, true)
    light(exit, color, 1.2, 12)
    local depositModel = World.outcrop(mine, cache, glow, 4)
    depositModel:PivotTo(CFrame.new(at(0, 2.6, -44)))
    depositModel:ScaleTo(1.36)
    light(cache, glow, 2, 21)
    mineLamp(mine, at(0, 7.5, -39), glow, 19)
    mineLamp(mine, at(0, 7.5, -46), glow, 17)
    for _, z in ipairs({-36, -39, -42}) do
        trailMarker(mine, at(3.1, .66, z), mineWarm)
    end

    local veins = {}
    for index, location in ipairs({{25, -17}, {33, -34}, {14, -47}}) do
        local anchor = piece(mine, "Resonant Vein " .. index, vector(3.1, 4.8, 3.1),
            vector(x + location[1], 3.3, location[2]), glow, material.SmoothPlastic, true)
        anchor.Transparency = 1
        anchor.CastShadow = false
        local cluster, sparks = World.outcrop(mine, anchor, glow, index + 20)
        local lampLight = Instance.new("PointLight")
        lampLight.Color = glow
        lampLight.Range = 18
        lampLight.Brightness = .7
        lampLight.Parent = anchor
        local pulse = TweenService:Create(lampLight,
            TweenInfo.new(.85 + index * .15, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
            {Brightness = 1.9})
        pulse:Play()
        veins[index] = { Anchor = anchor, Cluster = cluster, Sparks = sparks, Pulse = pulse, Lamp = lampLight }
    end

    return {
        Veins = veins, Status = status, Cache = cache, Exit = exit,
        ExitPosition = at(0, 5, -27),
        ChamberX = x + 22,
        FrontZ = -63.2,
        BackZ = -76,
        Gate = function(open)
            door.CanCollide = not open
            door.CanQuery = not open
            door.CFrame = open and (closed * CFrame.new(0, 8.7, 0)) or closed
        end,
    }
end

local oreMotions = setmetatable({}, {__mode = "k"})

function World.oreStrike(cluster, rest, glints, depleted)
    local motion = {}
    oreMotions[cluster] = motion
    local function current()
        return oreMotions[cluster] == motion and cluster.Parent ~= nil
    end

    task.delay(.14, function()
        if not current() then return end
        glints:Emit(depleted and 15 or 5)
        cluster:PivotTo(rest * CFrame.Angles(.085, 0, -.13))
        task.wait(.04)
        if not current() then return end
        cluster:PivotTo(rest * CFrame.Angles(-.04, 0, .08))
        task.wait(.045)
        if not current() then return end
        cluster:PivotTo(rest)
        if depleted then cluster.Parent = nil end
        oreMotions[cluster] = nil
    end)
end

function World.outcrop(parent, anchor, color, index)
    local foot = anchor.Position - vector(0, 3, 0)
    rock(parent, foot + vector(0, .24, 0), vector(5.4, 1.05, 4.9), darkStone)
    local cluster = Instance.new("Model")
    cluster.Name = "Ore Cluster"
    cluster.WorldPivot = CFrame.new(foot)
    cluster.Parent = parent
    local pale = color:Lerp(rgb(240, 255, 255), .42)
    local shaded = color:Lerp(darkStone, .23)

    for ordinal = 1, 3 do
        local yaw = math.rad(index * 37 + ordinal * 121)
        local radius = ordinal == 1 and 0 or 1.25
        local origin = CFrame.new(foot + vector(math.cos(yaw) * radius, .42, math.sin(yaw) * radius))
            * CFrame.Angles(0, -yaw + math.pi / 2, math.rad(ordinal == 1 and 9 or -21))
        local width = ordinal == 1 and 1.6 or .88
        local height = ordinal == 1 and 3.7 + index % 3 * .22 or 1.7 + ordinal * .30
        local function facet(name, size, cf, tint, surface, className)
            local object = piece(cluster, name, size, cf.Position, tint, surface, false, nil, nil, className)
            object.CFrame = cf
        end

        facet("Crystal Face", vector(width, height, width), origin * CFrame.new(0, height / 2, 0),
            color, material.Glass)
        facet("Luminous Vein", vector(width * .14, height * .79, .035),
            origin * CFrame.new(width * .25, height * .52, -width / 2 - .02), pale, material.Neon)
        local taper = width * .82
        for face = 0, 3 do
            local cap = origin * CFrame.new(0, height + taper / 2, 0)
                * CFrame.Angles(0, face * math.pi / 2, 0) * CFrame.new(width / 4, 0, width / 4)
            facet("Crystal Tip", vector(width / 2, taper, width / 2), cap,
                face % 2 == 0 and pale or shaded, material.Glass, "CornerWedgePart")
        end
    end

    local attachment = Instance.new("Attachment")
    attachment.Position = vector(0, .4, 0)
    attachment.Parent = anchor
    local glints = particles(attachment, pale, 0, NumberRange.new(2, 5),
        NumberRange.new(.22, .48), NumberSequence.new(.19, .04))
    glints.SpreadAngle = Vector2.new(140, 140)
    return cluster, glints
end

return World
