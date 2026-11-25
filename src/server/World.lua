local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local Pickaxes = require(script.Parent:WaitForChild("Pickaxes"))
local config = require(game:GetService("ReplicatedStorage"):WaitForChild("MiningConfig"))

local World = {}
local rgb = Color3.fromRGB
local vector = Vector3.new
local material = Enum.Material

local palettes = {
    {
        ground = rgb(84, 140, 67), groundMaterial = material.Plastic,
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

local studdedSurfaces = {
    ["Meadow Ground"] = true,
    ["Starter Mine Ground"] = true,
    ["Market Square"] = true,
    ["Wayshrine Promenade"] = true,
    ["Stall Landing"] = true,
    ["Plaza Kerb"] = true,
    ["Commons Pavers"] = true,
    ["Storefront Cap"] = true,
    ["Town Sidewalk"] = true,
    ["Descent Floor"] = true,
}

local function piece(parent, name, size, position, color, surface, solid, shape, rotation, className)
    local object = Instance.new(className or "Part")
    object.Name = name
    object.Size = size
    object.CFrame = rotation and CFrame.new(position) * rotation or CFrame.new(position)
    object.Anchored = true
    object.Color = color
    object.Material = surface
    if studdedSurfaces[name] then
        object.Material = material.Plastic
        object.TopSurface = Enum.SurfaceType.Studs
    end
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

local function signText(board, headline, subtitle, tint, distance)
    local face = Instance.new("SurfaceGui")
    face.Face = Enum.NormalId.Back
    face.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
    face.PixelsPerStud = 54
    face.LightInfluence = 0
    face.MaxDistance = distance
    face.Parent = board

    local function line(message, color, y, height, font)
        local lettering = Instance.new("TextLabel")
        lettering.Position = UDim2.fromScale(.08, y)
        lettering.Size = UDim2.fromScale(.84, height)
        lettering.BackgroundTransparency = 1
        lettering.TextColor3 = color
        lettering.Text = message
        lettering.TextScaled = true
        lettering.Font = font
        lettering.Parent = face
        local limit = Instance.new("UITextSizeConstraint")
        limit.MaxTextSize = math.floor(board.Size.Y * face.PixelsPerStud * height * .76)
        limit.Parent = lettering
        return lettering
    end
    local heading = line(headline, tint, subtitle and .12 or .10, subtitle and .46 or .80, Enum.Font.SourceSansBold)
    if subtitle then
        return line(subtitle, rgb(255, 229, 168), .61, .25, Enum.Font.SourceSans)
    end
    return heading
end

local function signFrame(parent, board)
    local size = board.Size
    local function rail(name, dimensions, x, y, tint, finish)
        local cf = board.CFrame * CFrame.new(x, y, size.Z / 2 + .035)
        local trim = piece(parent, name, dimensions, cf.Position, tint, finish)
        trim.CFrame = cf
    end
    local rim = rgb(89, 59, 42)
    local brass = rgb(182, 131, 72)
    for _, side in ipairs({-1, 1}) do
        rail("Sign Frame", vector(size.X + .12, .12, .14), 0, side * size.Y / 2, rim, material.Wood)
        rail("Sign Frame", vector(.12, size.Y, .14), side * size.X / 2, 0, rim, material.Wood)
        rail("Sign Rivet", vector(.115, .115, .09), side * (size.X / 2 - .22), 0, brass, material.Metal)
    end
end

local function signPosts(board)
    local bottom = board.Position.Y - board.Size.Y / 2
    local height = math.max(.30, bottom - .48 + .24)
    for _, side in ipairs({-1, 1}) do
        local placement = board.CFrame * CFrame.new(side * board.Size.X * .37, .48 + height / 2 - board.Position.Y, -.085)
        local post = piece(board, "Sign Post", vector(.34, height, .34), placement.Position, timber, material.Wood)
        post.CFrame = placement
    end
end

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

local function woodSegment(parent, name, from, to, width, shade, solid)
    local direction = to - from
    local length = direction.Magnitude
    local center = (from + to) / 2
    local beam = piece(parent, name, vector(length + .12, width, width), center,
        shade, material.Wood, solid, Enum.PartType.Cylinder)
    local up = math.abs(direction.Y) > length * .96 and vector(1, 0, 0) or vector(0, 1, 0)
    beam.CFrame = CFrame.lookAt(center, to, up) * CFrame.Angles(0, math.pi / 2, 0)
end

local function tree(parent, position, height, color)
    local oak = Instance.new("Model")
    oak.Name = "Meadow Oak"
    oak.Parent = parent
    local rng = Random.new(math.floor(position.X * 7381 + position.Z * 19397))
    local bark = rgb(111, 78, 53)
    local baseBark = rgb(91, 65, 47)
    local lean = vector(rng:NextNumber(-.42, .42), 0, rng:NextNumber(-.42, .42))
    local fork = position + lean + vector(0, height * .58, 0)
    local crown = position + lean * 2 + vector(0, height, 0)
    local girth = height * .145
    woodSegment(oak, "Flared oak base", position - vector(0, .1, 0),
        position + vector(0, height * .18, 0), girth * 1.32, baseBark, true)
    woodSegment(oak, "Oak trunk", position + vector(0, height * .15, 0), fork, girth, bark, true)
    woodSegment(oak, "Tapered leader", fork, crown, girth * .64, bark, false)

    local direction = rng:NextNumber(0, math.pi * 2)
    for branch = 1, 5 do
        local angle = direction + branch * 2.40 + rng:NextNumber(-.18, .18)
        local radial = vector(math.cos(angle), 0, math.sin(angle))
        local length = height * rng:NextNumber(.27, .47)
        local rise = height * rng:NextNumber(.16, .46)
        local origin = fork + vector(0, height * rng:NextNumber(-.10, .12), 0)
        local elbow = origin + radial * (length * .51) + vector(0, rise * .56, 0)
        local tip = origin + radial * length + vector(0, rise, 0)
        woodSegment(oak, "Oak limb", origin, elbow, girth * .46, bark, false)
        woodSegment(oak, "Branch tip", elbow, tip, girth * .27, bark, false)
        if branch <= 3 then
            woodSegment(oak, "Exposed root", position + vector(0, .5, 0),
                position + radial * (girth * 1.5) + vector(0, .04, 0), girth * .34, baseBark, false)
        end

        local leaves = color:Lerp(rgb(34, 75, 47), rng:NextNumber(.10, .36))
        local sunlit = leaves:Lerp(rgb(154, 185, 85), rng:NextNumber(.22, .55))
        local spread = height * rng:NextNumber(.33, .50)
        piece(oak, "Leaf mass", vector(spread, height * .27, spread * .8),
            tip + vector(0, height * .075, 0), leaves, material.Grass, false, Enum.PartType.Ball,
            CFrame.Angles(0, -angle, rng:NextNumber(-.22, .22)))
        piece(oak, "Light leaf spray", vector(spread * .73, height * .22, spread * .68),
            tip + radial * (height * .09) + vector(0, height * .18, 0), sunlit,
            material.Grass, false, Enum.PartType.Ball)
    end
    piece(oak, "Oak crown", vector(height * .54, height * .33, height * .48),
        crown + vector(0, height * .115, 0), color:Lerp(rgb(145, 177, 82), .32),
        material.Grass, false, Enum.PartType.Ball)
end

local function pine(parent, position, height)
    local pineTree = Instance.new("Model")
    pineTree.Name = "Frostpine"
    pineTree.Parent = parent
    local rng = Random.new(math.floor(position.X * 2927 + position.Z * 6817))
    local bark = rgb(113, 88, 71)
    local lower = position + vector(0, height * .43, 0)
    local tip = position + vector(.14, height, -.12)
    woodSegment(pineTree, "Lower pine trunk", position, lower, height * .09, bark, true)
    woodSegment(pineTree, "Pine leader", lower, tip, height * .044, bark, false)

    for tier = 1, 4 do
        local level = .26 + tier * .145
        local reach = height * (.37 - tier * .059)
        local hub = position + vector(0, height * level, 0)
        local baseColor = rgb(41 + tier * 6, 78 + tier * 8, 83 + tier * 8)
        for branch = 1, 4 do
            local angle = branch * math.pi / 2 + tier * .71 + rng:NextNumber(-.14, .14)
            local radial = vector(math.cos(angle), 0, math.sin(angle))
            local length = reach * rng:NextNumber(.77, 1.19)
            local midpoint = hub + radial * (length * .49) - vector(0, height * .044, 0)
            local yaw = CFrame.Angles(0, -angle, -.20)
            piece(pineTree, "Pine needle bough", vector(length * 1.58, height * .115, reach * .72),
                midpoint, baseColor, material.Grass, false, Enum.PartType.Ball, yaw)
            if (tier + branch) % 3 ~= 0 then
                piece(pineTree, "Bough snow", vector(length * 1.10, height * .046, reach * .48),
                    midpoint + vector(0, height * .054, 0), rgb(218, 233, 240), material.Snow,
                    false, Enum.PartType.Ball, yaw)
            end
        end
    end
    piece(pineTree, "Needle tip", vector(height * .108, height * .23, height * .103),
        tip - vector(0, height * .071, 0), rgb(62, 111, 118), material.Grass, false, Enum.PartType.Ball,
        CFrame.Angles(0, 0, -.07))
end

local shrubStyles = {
    { Name = "Meadow Bramble", Shade = rgb(42, 88, 59), Tip = rgb(109, 151, 68), Accent = rgb(247, 174, 117),
        Sprout = "Meadow Wildflower", Surface = material.Grass },
    { Name = "Cavern Moss", Shade = rgb(57, 69, 73), Tip = rgb(97, 109, 113), Accent = rgb(181, 140, 228),
        Sprout = "Cavern Glowcap", Surface = material.Neon },
    { Name = "Snowberry Shrub", Shade = rgb(58, 91, 112), Tip = rgb(96, 136, 155), Accent = rgb(218, 237, 244),
        Sprout = "Frost Bloom", Surface = material.Ice, Snow = true },
    { Name = "Tide Fern", Shade = rgb(44, 96, 79), Tip = rgb(111, 164, 113), Accent = rgb(183, 220, 150),
        Sprout = "Tidal Reed", Surface = material.Grass },
    { Name = "Cinder Scrub", Shade = rgb(87, 61, 58), Tip = rgb(143, 89, 65), Accent = rgb(229, 143, 80),
        Sprout = "Emberglass", Surface = material.Glass },
}

local function shrub(parent, position, size, style, rng)
    local ball = Enum.PartType.Ball
    piece(parent, style.Name, vector(2.7, 1.46, 2.35) * size, position + vector(0, .73, 0) * size,
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
            position + vector(leaf * spread * .32, height * .52 + .06, leaf * .11),
            style.Tip:Lerp(style.Shade, rng:NextNumber(.1, .65)), material.Grass, false,
            Enum.PartType.Ball, CFrame.Angles(0, rng:NextNumber(-.45, .45), leaf * -.38))
        blade.CastShadow = false
    end
end

local function shard(parent, position, height, color, tilt)
    return piece(parent, "Crystal Formation", vector(2.2, height, 2.2), position, color, material.Glass, false,
        nil, CFrame.Angles(0, math.rad(35), math.rad(tilt)))
end

function World.ensureSpawn()
    local start = workspace:FindFirstChild("MiningStart") or Instance.new("Folder")
    start.Name = "MiningStart"
    local size = vector(config.Meadow.Width, 1, config.Meadow.Depth)
    local ground = start:FindFirstChild("Meadow Ground")
    if ground and ground:IsA("BasePart") then
        ground.Size = size
        ground.Color = palettes[1].ground
        ground.Material = material.Plastic
        ground.TopSurface = Enum.SurfaceType.Studs
    else
        piece(start, "Meadow Ground", size, vector(0, 0, 0), palettes[1].ground, material.Plastic, true)
    end

    if not start:FindFirstChildOfClass("SpawnLocation") then
        local spawn = Instance.new("SpawnLocation")
        spawn.Name = "Mining Spawn"
        spawn.Size = vector(8, 1, 8)
        spawn.Position = vector(0, 1, 0)
        spawn.Anchored = true
        spawn.Neutral = true
        spawn.Parent = start
    end
    local spawn = start:FindFirstChildOfClass("SpawnLocation")
    spawn.Color = rgb(209, 217, 214)
    spawn.Material = material.Plastic
    spawn.TopSurface = Enum.SurfaceType.Studs
    start.Parent = workspace
end

function World.create()
    World.ensureSpawn()
    Lighting.ClockTime = 13.25
    Lighting.Brightness = 2.1
    Lighting.Ambient = rgb(139, 142, 151)
    Lighting.OutdoorAmbient = rgb(160, 167, 181)

    local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere")
    atmosphere.Color = rgb(214, 230, 246)
    atmosphere.Decay = rgb(131, 153, 178)
    atmosphere.Density = .11
    atmosphere.Haze = .25
    atmosphere.Parent = Lighting

    local grade = Lighting:FindFirstChild("Crystal Color Grading") or Instance.new("ColorCorrectionEffect")
    grade.Name = "Crystal Color Grading"
    grade.Saturation = .025
    grade.Contrast = .01
    grade.TintColor = rgb(255, 253, 246)
    grade.Parent = Lighting

    local bloom = Lighting:FindFirstChild("Crystal Glow")
    if bloom then bloom.Enabled = false end

    local folder = Instance.new("Folder")
    folder.Name = "CrystalWorld"
    folder.Parent = workspace
    return folder
end

local slopeHeights = {.43, .33, .24}
local mountainColors = {
    {rgb(86, 116, 80), rgb(104, 137, 89), rgb(126, 152, 102)},
    {rgb(65, 61, 85), rgb(87, 79, 111), rgb(116, 102, 145)},
    {rgb(106, 144, 163), rgb(151, 179, 196), rgb(224, 235, 242)},
    {rgb(87, 119, 103), rgb(118, 147, 119), rgb(165, 173, 128)},
    {rgb(71, 59, 63), rgb(100, 74, 71), rgb(138, 94, 78)},
}

local function mountainBackdrop(parent, index, x)
    local range = Instance.new("Folder")
    range.Name = "Mountain Backdrop"
    range.Parent = parent
    local colors = mountainColors[index]
    local rng = Random.new(2348 + index)
    local front = index == 1 and (config.Meadow.Depth / 2 + 29) or 86
    local rear = index == 2 and -207 or index == 1 and (-config.Meadow.Depth / 2 - 27) or -82
    local side = index == 1 and (config.Meadow.Width / 2 + 30) or 89

    local function peak(px, pz, rotated)
        local height = rng:NextNumber(27, 50)
        local span = rng:NextNumber(35, 48)
        local depth = rng:NextNumber(17, 29)
        local drift = rng:NextNumber(-7, 7)
        local floor = -6
        for tier = 1, 3 do
            local rise = height * slopeHeights[tier]
            local multiplier = 1 - (tier - 1) * .27
            local mid = floor + rise / 2
            local offset = (tier - 1) * drift
            local width, length = span * multiplier, depth * multiplier
            if rotated then width, length = length, width end
            local center = vector(x + px + (rotated and 0 or offset), mid, pz + (rotated and offset or 0))
            piece(range, tier == 3 and "Peak" or "Mountain Slope", vector(width, rise + .1, length),
                center, colors[tier], index == 3 and tier == 3 and material.Snow or material.Plastic)
            floor += rise
        end
    end

    for px = -side, side, 29 do
        peak(px, rear - rng:NextNumber(0, 9), false)
        peak(px, front + rng:NextNumber(0, 9), false)
    end
    for _, direction in ipairs({-1, 1}) do
        for pz = rear + 19, front - 16, 30 do
            peak(direction * (side + rng:NextNumber(0, 7)), pz, true)
        end
    end
end

function World.starterMine(parent)
    local ground = Instance.new("Folder")
    ground.Name = "Meadow Mine Grounds"
    ground:SetAttribute("BiomeIndex", config.StarterMineBiome)
    ground.Parent = parent
    local x = config.StarterMineX
    piece(ground, "Starter Mine Ground", vector(126, 1, 118), vector(x, 0, -5),
        palettes[1].ground, material.Plastic, true)
    piece(ground, "Starter Mine Bedrock", vector(126, 14, 118), vector(x, -7.55, -5),
        palettes[1].rock, material.Rock, true)
    piece(ground, "Mine Arrival Path", vector(9.5, .1, 29), vector(x, .55, 8.5),
        rgb(176, 157, 121), material.Cobblestone)
    mountainBackdrop(ground, 1, x)
    for _, side in ipairs({-1, 1}) do
        for _, z in ipairs({-49, -27, -5, 19, 40}) do
            rock(ground, vector(x + side * 57, 2.3, z), vector(8.4, 5.6, 9.6), palettes[1].rock)
        end
        lamp(ground, vector(x + side * 7.5, .5, 8), mineWarm)
        local rest = vector(x + side * 9.8, .5, 20)
        piece(ground, "Mine Bench Landing", vector(4.8, .15, 3.4), rest + vector(0, .075, 0),
            rgb(173, 159, 128), material.Cobblestone)
        local bench = piece(ground, "Mine Bench", vector(3.9, .32, 1.4), rest + vector(0, 1.16, 0),
            timber, material.WoodPlanks, true, nil, CFrame.Angles(0, math.pi, 0), "Seat")
        bench.CanTouch = true
        for _, leg in ipairs({-1, 1}) do
            piece(ground, "Mine Bench Leg", vector(.47, 1.1, 1.12), rest + vector(leg * 1.46, .55, 0),
                palettes[1].rock, material.Rock)
        end
    end
    World.fieldSign(ground, "Starter Claim Board", vector(x + 10.8, 3.18, 3.5), 7.6,
        "QUARTZ CLAIM", "Mine ore • Sell it in Meadow")
    return ground
end

function World.zone(parent, index, zone, x)
    local palette = palettes[index]
    local folder = Instance.new("Folder")
    folder.Name = zone.Name
    folder:SetAttribute("BiomeIndex", index)
    folder.Parent = parent
    mountainBackdrop(folder, index, x)
    local function at(px, py, pz)
        return vector(x + px, py, pz)
    end

    local width = index == 1 and config.Meadow.Width or 110
    local depth = index == 1 and config.Meadow.Depth or 100
    piece(folder, "Bedrock", vector(width, 16, depth), at(0, -8.55, 0), palette.rock, material.Rock, true)
    if index > 1 then
        piece(folder, "Ground", vector(110, 1, 100), at(0, 0, 0), palette.ground, palette.groundMaterial, true)
    end
    if index ~= 1 then
        piece(folder, "Main Trail", vector(9, .08, 81), at(0, .54, 1), palette.trail, material.Cobblestone)
        piece(folder, "Mine Trail", vector(89, .08, 7), at(0, .54, -20), palette.trail, material.Cobblestone)
    end

    local rng = Random.new(4100 + index)
    for _, side in ipairs({-1, 1}) do
        local edge = index == 1 and 60 or 42
        local shift = index == 1 and 19 or 0
        for z = -edge, edge, 12 do
            local width = rng:NextNumber(6, 10)
            local height = rng:NextNumber(3, 7)
            rock(folder, at(side * (rng:NextNumber(48, 51) + shift), height / 3, z), vector(width, height, 8), palette.rock)
        end
        if index ~= 1 then
            lamp(folder, at(side * 7, .5, -7), zone.Color)
            lamp(folder, at(side * 7, .5, -33), zone.Color)
        end
    end

    if index == 1 then
        piece(folder, "Wayshrine Promenade", vector(120, .1, 13), at(0, .55, 72),
            palette.trail, material.Cobblestone)
        World.plaza(folder)
        World.townHouses(folder)
        World.overlookPark(folder)
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

    return folder
end

local mineProfiles = {
    {Name = "Weathered Sandstone", Dark = rgb(107, 94, 71), Light = rgb(142, 123, 90), Material = material.Sandstone},
    {Name = "Split Amethyst Slate", Dark = rgb(58, 48, 76), Light = rgb(95, 77, 117), Material = material.Slate},
    {Name = "Glacial Shelf", Dark = rgb(92, 129, 151), Light = rgb(171, 206, 219), Material = material.Ice},
    {Name = "Waterworn Limestone", Dark = rgb(80, 100, 89), Light = rgb(143, 150, 108), Material = material.Limestone},
    {Name = "Basalt Slag", Dark = rgb(64, 51, 52), Light = rgb(105, 72, 65), Material = material.Basalt},
}

local function dressMine(parent, index, at)
    local finish = mineProfiles[index]
    local dressing = Instance.new("Folder")
    dressing.Name = "Mine Details"
    dressing.Parent = parent

    local ledges = index == 2 and {-18, -30, -48, -63, -74} or {-12, -21, -29}
    for _, side in ipairs({-1, 1}) do
        for order, z in ipairs(ledges) do
            local width = 2.35 + order % 3 * .64
            local pos = at(side * 39.1, 2.35 + (order % 2) * .83, z)
            piece(dressing, finish.Name, vector(width, 4.9, 4.2 + order % 3), pos,
                finish.Dark, finish.Material, false, nil, CFrame.Angles(order * .19, side * .28, side * -.39),
                "WedgePart")
            piece(dressing, "Exposed Stratum", vector(2.98, .61, 3.85), pos + vector(side * -.39, 1.06, .25),
                finish.Light, finish.Material, false, nil, CFrame.Angles(0, -.23 * side, .15 * side))
            piece(dressing, "Mine Rubble", vector(1.42, .54, 1.2), at(side * 37.1, .78, z + 1.33),
                finish.Dark, finish.Material, false, nil, CFrame.Angles(-.18, order * .71, .12))
        end
    end

    if index == 1 then
        local center = at(-35.8, 1.18, -10)
        piece(dressing, "Retired Ore Cart", vector(2.1, .8, 2.68), center,
            rgb(103, 76, 58), material.WoodPlanks)
        for _, side in ipairs({-1, 1}) do
            piece(dressing, "Cart Rim", vector(.13, .34, 2.72), center + vector(side * .94, .48, 0),
                darkStone, material.Metal)
            for _, endZ in ipairs({-.81, .81}) do
                piece(dressing, "Cart Wheel", vector(.28, .53, .53), center + vector(side * 1.01, -.48, endZ),
                    darkStone, material.Metal, false, Enum.PartType.Cylinder)
            end
        end
    elseif index == 2 then
        for _, pos in ipairs({{-35.8,-22}, {34.8,-33}, {35.5,-53}, {-35,-69}}) do
            piece(dressing, "Fractured Slate Shelf", vector(5.42, 1.91, 3.46), at(pos[1], 7.8, pos[2]),
                finish.Light, finish.Material, false, nil, CFrame.Angles(.33, -.22, .57), "WedgePart")
        end
    elseif index == 3 then
        for _, side in ipairs({-1, 1}) do
            for offset = 0, 3 do
                piece(dressing, "Hanging Ice Tooth", vector(1.05, 1.65 + offset % 2 * .65, 1.38),
                    at(side * (35 + offset * .64), 10.58, -15 - offset * 4.8), finish.Light, material.Ice,
                    false, nil, CFrame.Angles(math.pi + .2, offset * .67, .21 * side), "WedgePart")
            end
        end
    elseif index == 4 then
        for _, side in ipairs({-1, 1}) do
            for block = 1, 3 do
                piece(dressing, "Collapsed Relief", vector(1.12, .77, 2.03),
                    at(side * (35.2 + block * .86), 1.13 + block * .12, -31.5 - block * .2),
                    finish.Light, material.Limestone, false, nil, CFrame.Angles(-.11, block * .29, side * .41))
            end
        end
    else
        for _, side in ipairs({-1, 1}) do
            for _, z in ipairs({-15, -21, -28}) do
                piece(dressing, "Pitted Iron Bracket", vector(.54, 3.22, 1.27), at(side * 38.1, 6.9, z),
                    rgb(104, 82, 71), material.CorrodedMetal, false, nil, CFrame.Angles(.11, 0, side * .49))
                piece(dressing, "Cooling Slag Seam", vector(.15, .29, 2.45), at(side * 39, 2.12, z + .7),
                    rgb(207, 100, 66), material.Neon, false, nil, CFrame.Angles(.14, .11, 0))
            end
        end
    end
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
        local headline, subtitle = string.match(message, "^(.-)\n(.+)$")
        signFrame(mine, post)
        signPosts(post)
        signText(post, headline or message, subtitle, tint, 44)
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

    local surface = piece(mine, "Cavern Lift", vector(5.8, .5, 5.8), at(-7, .8, 1),
        routes[3].Color, material.Metal, true)
    local deep = piece(mine, "Deep Gallery Lift", vector(5.8, .5, 5.8), at(-26, .8, -71),
        routes[3].Color, material.Metal, true)
    for _, lift in ipairs({surface, deep}) do
        light(lift, routes[3].Color, 1.25, 14)
    end
    dressMine(mine, 2, at)
    return mine, surface, deep
end

function World.mine(parent, zone, index, x)
    local folder = Instance.new("Folder")
    folder.Name = zone.Name .. " Mine"
    folder.Parent = parent
    local stone = palettes[index].rock
    local meadow = index == 1
    local widthScale = meadow and config.Meadow.MineWidthScale or 1
    local depthScale = meadow and config.Meadow.MineDepthScale or 1
    local function at(px, py, pz)
        return vector(x + px * widthScale, py, pz * depthScale)
    end
    local function structure(name, size, position, color, surface)
        return piece(folder, name, vector(size.X * widthScale, size.Y, size.Z * depthScale), position, color, surface, true)
    end

    if meadow then
        piece(folder, "Meadow Mine Approach", vector(12, .08, 10), vector(x, .55, -6),
            rgb(189, 166, 124), material.Cobblestone)
        piece(folder, "Meadow Mine Cross Aisle", vector(95, .08, 7), at(0, .55, -20),
            rgb(155, 143, 116), material.Cobblestone)
        for _, side in ipairs({-1, 1}) do
            structure("Entrance Upright", vector(.94, 8.95, .94), at(side * 6, 5, -5.5), timber, material.Wood)
            structure("Entrance Footing", vector(1.65, .74, 1.55), at(side * 6, .87, -5.5),
                rgb(175, 154, 119), material.Limestone)
            mineLamp(folder, at(side * 5.25, 7.35, -5.4), mineWarm, 22)
        end
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
            mineLamp(folder, at(side * wing, 7.6, -20), zone.Color, meadow and 23 or 21)
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
    local header = structure("Mine Entrance", vector(14, 2, 2), at(0, 10, meadow and -5.5 or -7),
        timber, material.Wood)
    local signFace = header
    if meadow then
        local width, height = 15.3, 2.6
        local mount = header.Position + vector(0, .17, header.Size.Z / 2 + .24)
        local frame = rgb(89, 59, 42)
        local brass = rgb(202, 156, 84)
        signFace = piece(folder, "Meadow Mine Plaque", vector(width, height, .38), mount,
            rgb(37, 94, 64), material.Plastic)
        local rim = mount + vector(0, 0, .23)
        for _, side in ipairs({-1, 1}) do
            piece(folder, "Plaque Horizontal Frame", vector(width + .3, .18, .29),
                rim + vector(0, side * height / 2, 0), frame, material.Wood)
            piece(folder, "Plaque Vertical Frame", vector(.19, height + .23, .29),
                rim + vector(side * width / 2, 0, 0), frame, material.Wood)
            piece(folder, "Plaque Gold Inlay", vector(width - .48, .033, .06),
                rim + vector(0, side * (height / 2 - .2), .025), brass, material.Metal)

            local xPos = side * (width / 2 - 1.1)
            piece(folder, "Plaque Diamond Setting", vector(.71, .71, .20), rim + vector(xPos, 0, .10),
                brass, material.Metal, false, nil, CFrame.Angles(0, 0, math.pi / 4))
            piece(folder, "Plaque Crystal Emblem", vector(.44, .44, .16), rim + vector(xPos, 0, .24),
                rgb(113, 211, 169), material.SmoothPlastic, false, nil, CFrame.Angles(0, 0, math.pi / 4))
        end
    end
    local sign = Instance.new("SurfaceGui")
    sign.Face = Enum.NormalId.Back
    sign.LightInfluence = 0
    sign.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
    sign.PixelsPerStud = 54
    sign.MaxDistance = meadow and 92 or 70
    sign.Parent = signFace
    local title = Instance.new("TextLabel")
    title.BackgroundTransparency = 1
    title.Text = meadow and "MEADOW MINE" or string.upper(zone.Name .. " Mine")
    title.Position = meadow and UDim2.fromScale(.14, .08) or UDim2.fromScale(.055, .10)
    title.Size = meadow and UDim2.fromScale(.72, .84) or UDim2.fromScale(.89, .80)
    title.TextColor3 = meadow and rgb(255, 238, 188) or rgb(255, 232, 174)
    title.TextScaled = true
    title.Font = Enum.Font.SourceSansBold
    title.Parent = sign
    if meadow then
        local lettering = Instance.new("UITextSizeConstraint")
        lettering.MaxTextSize = 73
        lettering.Parent = title
    end
    dressMine(folder, index, at)
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
    signFrame(parent, sign)
    signPosts(sign)
    signText(sign, name, nil, rgb(255, 244, 211), 57)
end

local function storefront(parent, name, origin, yaw, width, color)
    local pose = CFrame.new(origin) * CFrame.Angles(0, yaw, 0)
    local sand = rgb(224, 211, 166)
    local stone = rgb(168, 169, 161)
    local function panel(partName, size, offset, tint)
        local cf = pose * CFrame.new(offset)
        local part = piece(parent, name .. " " .. partName, size, cf.Position, tint, material.Plastic)
        part.CFrame = cf
        return part
    end
    local function cap(partName, size, offset, tint)
        local cf = pose * CFrame.new(offset)
        local part = piece(parent, "Storefront Cap", size, cf.Position, tint, material.Plastic)
        part.CFrame = cf
        part:SetAttribute("Shop", name .. " " .. partName)
    end
    panel("Roof Band", vector(width, .58, .67), vector(0, 1.6, 0), color)
    panel("Trim", vector(width + .24, .18, .71), vector(0, 1.25, 0), sand)
    cap("Top", vector(width - 1.25, .34, .72), vector(0, 2.06, 0), color)
    for _, side in ipairs({-1, 1}) do
        local x = side * (width / 2 - .29)
        panel("Post", vector(.57, 4.25, .67), vector(x, -.72, 0), color)
        panel("Foot", vector(.87, .53, .88), vector(x, -2.93, 0), stone)
        panel("Capstone", vector(.78, .36, .84), vector(x, 1.26, 0), sand)
    end
end

function World.fieldSign(parent, name, position, width, headline, subtitle, yaw)
    local board = piece(parent, name, vector(width, 2.20, .26), position,
        rgb(46, 65, 56), material.WoodPlanks, false, nil, CFrame.Angles(0, yaw or 0, 0))
    signFrame(parent, board)
    signPosts(board)
    return signText(board, headline, subtitle, rgb(255, 239, 195), 48)
end

function World.marketSign(parent, anchor, headline, subtitle)
    local pos = anchor.Position
    local bearing = vector(-pos.X, 0, 20 - pos.Z)
    local direction = bearing.Magnitude > 0 and bearing / bearing.Magnitude or vector(0, 0, -1)
    local offset = .55 + math.abs(direction.X) * anchor.Size.X / 2 + math.abs(direction.Z) * anchor.Size.Z / 2
    local display = pos + direction * offset
    return World.fieldSign(parent, anchor.Name .. " Board", vector(display.X, 4.35, display.Z), 6.8,
        headline, subtitle, math.atan2(direction.X, direction.Z))
end

function World.stationSign(anchor, headline, subtitle)
    local pos = anchor.Position
    local facing = pos.Z > 0 and -1 or 1
    local board = vector(pos.X, math.max(3.9, pos.Y + 1.42), pos.Z + facing * .52)
    World.fieldSign(anchor.Parent, anchor.Name .. " Board", board, 6.85, headline, subtitle,
        facing < 0 and math.pi or 0)
end

function World.communityCorner(parent)
    local corner = Instance.new("Folder")
    corner.Name = "Community Corner"
    corner.Parent = parent
    World.fieldSign(corner, "Meadow Noticeboard", vector(-19, 3.15, 13.3), 8.6,
        "MEADOW NOTICEBOARD", "First commission? Visit the guild.")
    piece(corner, "Noticeboard Base", vector(10.8, .11, 3.1), vector(-19, .69, 13.5),
        rgb(188, 177, 148), material.Plastic)
    for _, side in ipairs({-1, 1}) do
        local base = vector(-19 + side * 5.03, .52, 13.45)
        piece(corner, "Community Planter", vector(1.24, .67, 1.2), base + vector(0, .32, 0),
            rgb(130, 89, 64), material.WoodPlanks)
        shrub(corner, base + vector(0, .66, 0), .57, shrubStyles[1], Random.new(1077 + side))
    end
    local crate = vector(-12.7, 1.04, 26.2)
    piece(corner, "Shared Supply Crate", vector(1.73, 1.04, 1.33), crate,
        rgb(152, 108, 70), material.WoodPlanks)
    piece(corner, "Supply Crate Lid", vector(1.8, .12, 1.41), crate + vector(0, .55, 0),
        rgb(176, 135, 86), material.Wood)

    local cart = vector(-28.2, .62, 16.8)
    piece(corner, "Guild Delivery Cart", vector(2.8, .26, 3.1), cart + vector(0, .93, 0), timber, material.WoodPlanks)
    piece(corner, "Cart Delivery Parcel", vector(1.8, 1.05, 1.85), cart + vector(0, 1.58, -.15),
        rgb(188, 145, 87), material.WoodPlanks)
    for _, side in ipairs({-1, 1}) do
        piece(corner, "Delivery Cart Wheel", vector(.26, 1.22, 1.22), cart + vector(side * 1.38, .61, .38),
            darkStone, material.Wood, false, Enum.PartType.Cylinder)
        piece(corner, "Delivery Cart Handle", vector(.23, .21, 1.48), cart + vector(side * 1.11, .88, 2.19),
            timber, material.Wood)
    end
end

function World.meadowLandmarks(parent)
    local sell = parent:FindFirstChild("Sell Crystals")
    local forge = parent:FindFirstChild("Pickaxe Forge")
    local guild = parent:FindFirstChild("Guild Commissions")
    storefront(parent, sell.Name, sell.Position + vector(4.91, 1.44, 0), math.pi / 2, 10.6, rgb(177, 109, 54))
    storefront(parent, forge.Name, forge.Position + vector(0, 1.44, -2.42), math.pi, 10.6, rgb(76, 117, 171))
    storefront(parent, guild.Name, guild.Position + vector(4.13, 1.44, 0), math.pi / 2, 8.8, rgb(78, 134, 93))
    shopSign(parent, "SELL CRYSTALS", sell.Position + vector(5.38, 2.96, 0),
        vector(6.25, 1.48, .22), rgb(93, 59, 40), math.pi / 2)
    shopSign(parent, "PICKAXE FORGE", forge.Position + vector(0, 2.96, -2.88),
        vector(6.5, 1.48, .22), rgb(37, 62, 82), math.pi)
    shopSign(parent, "GUILD COMMISSIONS", guild.Position + vector(4.60, 2.96, 0),
        vector(7.2, 1.48, .24), rgb(36, 70, 60), math.pi / 2)
end

function World.welcome(parent)
    local cream = rgb(251, 228, 177)
    local green = rgb(27, 58, 47)
    local function board(name, headline, subtitle, position, width, yaw)
        local orientation = CFrame.Angles(0, yaw or 0, 0)
        local panel = piece(parent, name, vector(width, 2.35, .28), position, green,
            material.WoodPlanks, false, nil, orientation)
        signFrame(parent, panel)
        signPosts(panel)
        signText(panel, headline, subtitle, cream, 58)
    end

    board("Meadow Welcome", "Welcome to Meadow", "First stop • Guild Commissions", vector(-10.5, 3.22, -3.3), 8.6, -.22)
    board("Market Directions", "← Services    Shops →", "Wayshrines ahead", vector(10.6, 3.12, -3.5), 8, .23)
    board("Wayshrine Directions", "Wayshrines ↑", "Market Square ↓", vector(-10.5, 3.26, 64), 8.4, math.pi)
    World.fieldSign(parent, "Miners’ Services Board", vector(-23.5, 3.45, 7.6), 10.4,
        "MINERS’ SERVICES", "Guild • Sell • Forge • Bags • Geodes", 1.94)
    World.fieldSign(parent, "Market Shops Board", vector(23.5, 3.45, 7.6), 10.4,
        "MARKET SHOPS", "Crates • Styles • Compass", -1.94)
    piece(parent, "Welcome Walk", vector(8.6, .10, 11.5), vector(0, .67, 10.25),
        rgb(196, 179, 149), material.Cobblestone)
    for _, side in ipairs({-1, 1}) do
        lamp(parent, vector(side * 6.3, .62, 13.9), rgb(255, 222, 157))
        for z = 5.9, 15, 2.7 do
            piece(parent, "Welcome Walk Inlay", vector(.66, .05, .66), vector(side * 3.23, .738, z),
                rgb(103, 148, 119), material.Plastic, false, nil, CFrame.Angles(0, math.pi / 4, 0))
        end
    end
    local pavedBand = {
        rgb(210, 172, 115),
        rgb(144, 179, 205),
    }
    for index, side in ipairs({-1, 1}) do
        piece(parent, "Market Lane Inlay", vector(14.2, .055, .33), vector(side * 17.6, .68, 4.21),
            pavedBand[index], material.Limestone)
    end
    local path = rgb(209, 179, 130)
    for _, side in ipairs({-1, 1}) do
        for step = 1, 8 do
            piece(parent, "Market Stepping Stone", vector(2.75, .06, 2.15), vector(side * (5.2 + step * 3), .655, 2.75),
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

local function commons(parent)
    local garden = Instance.new("Folder")
    garden.Name = "Miner’s Commons"
    garden.Parent = parent
    local stone = rgb(203, 204, 184)
    local board = rgb(126, 88, 57)
    local siding = rgb(87, 130, 88)
    for _, side in ipairs({-1, 1}) do
        local center = vector(side * 15.3, .5, 23)
        piece(garden, "Commons Pavers", vector(10.5, .16, 7.25), center + vector(0, .14, 0),
            stone, material.Plastic)
        piece(garden, "Picnic Table", vector(5.4, .38, 2.05), center + vector(0, 1.86, 0),
            board, material.WoodPlanks, true)
        for _, foot in ipairs({-1, 1}) do
            piece(garden, "Picnic Table Leg", vector(.52, 1.65, 1.62),
                center + vector(foot * 1.91, .91, 0), siding, material.Plastic)
        end
        for _, edge in ipairs({-1, 1}) do
            local seat = piece(garden, "Commons Seat", vector(4.65, .33, 1.36),
                center + vector(0, .91, edge * 2.03), board, material.WoodPlanks,
                true, nil, CFrame.Angles(0, edge < 0 and math.pi or 0, 0), "Seat")
            seat.CanTouch = true
            for _, leg in ipairs({-1, 1}) do
                piece(garden, "Seat Support", vector(.37, .84, .84),
                    center + vector(leg * 1.7, .46, edge * 2.03), siding, material.Plastic)
            end
        end
    end
end

function World.plaza(parent)
    local center = vector(0, 1, 23)
    local basin = piece(parent, "Fountain Basin", vector(1, 12, 12), center, rgb(99, 126, 138),
        material.Marble, true, Enum.PartType.Cylinder, CFrame.Angles(0, 0, math.pi / 2))
    local water = piece(parent, "Fountain Pool", vector(.08, 10.05, 10.05), center + vector(0, .54, 0),
        rgb(72, 189, 209), material.Glass, false, Enum.PartType.Cylinder, CFrame.Angles(0, 0, math.pi / 2))
    water.Reflectance = .16
    local spout = piece(parent, "Fountain Spout", vector(1.1, 1.5, 1.1), basin.Position + vector(0, 1.1, 0),
        rgb(215, 188, 119), material.Metal, false, Enum.PartType.Ball)
    local spray = particles(spout, rgb(172, 243, 251), 21, NumberRange.new(5, 8),
        NumberRange.new(.55, .85), NumberSequence.new(.23, .08))
    spray.Acceleration = vector(0, -17, 0)
    spray.SpreadAngle = Vector2.new(48, 48)
    piece(parent, "Market Square", vector(124, .12, 62), vector(0, .56, 26), rgb(176, 177, 168), material.Plastic)
    for _, side in ipairs({-1, 1}) do
        for _, z in ipairs({1, 11, 27, 41, 54}) do
            piece(parent, "Plaza Kerb", vector(1.5, .25, 7), vector(side * 61.4, .63, z),
                rgb(217, 218, 200), material.Plastic)
        end
    end
    for _, side in ipairs({-1, 1}) do
        piece(parent, "Plaza Border", vector(121, .12, 1), vector(0, .64, 26 + side * 30),
            rgb(219, 199, 161), material.Limestone)
        for _, z in ipairs({-1, 54}) do
            local position = vector(side * 47, .5, z)
            lamp(parent, position, rgb(255, 188, 107))
            if z == 54 then
                piece(parent, "Bunting Pole", vector(.25, 2, .25), vector(side * 46.8, 6.3, z), timber, material.Wood)
                piece(parent, "Pennant Tie", vector(2.9, .065, .065), vector(side * 45.35, 7.26, z), timber, material.Fabric)
            end
            piece(parent, "Flower Box", vector(2.5, .8, 2.5), position + vector(0, .4, 0), timber, material.Wood, true)
            for index = 1, 4 do
                piece(parent, "Market Flowers", vector(.5, .7, .5),
                    position + vector(math.cos(index * math.pi / 2) * .85, .86, math.sin(index * math.pi / 2) * .85),
                    index % 2 == 0 and rgb(254, 139, 109) or rgb(247, 207, 93), material.Grass, false, Enum.PartType.Ball)
            end
        end
    end
    commons(parent)
    piece(parent, "Wayshrine Approach", vector(12, .12, 11), vector(0, .56, 62),
        rgb(164, 141, 114), material.Cobblestone)
    piece(parent, "Market Terrace", vector(72, .085, 11), vector(0, .625, 61),
        rgb(187, 181, 159), material.Plastic)
    local bunting = {rgb(235, 181, 71), rgb(103, 155, 223), rgb(198, 89, 85), rgb(110, 173, 101)}
    local z = 54
    for index = -7, 7 do
        local height = 5.7 + math.abs(index) * .16
        piece(parent, "Pennant", vector(1.25, .95, .15), vector(index * 6.15, height, z),
            bunting[index % #bunting + 1], material.Fabric, false, nil, CFrame.Angles(0, 0, index * -.025))
        if index < 7 then
            local from = vector(index * 6.15, height + .44, z)
            local to = vector((index + 1) * 6.15, 6.14 + math.abs(index + 1) * .16, z)
            local cord = piece(parent, "Pennant Cord", vector(.055, .055, (to - from).Magnitude),
                (from + to) / 2, timber, material.Fabric)
            cord.CFrame = CFrame.lookAt((from + to) / 2, to)
        end
    end
end

function World.landmark(parent, zone, x, index)
    local position = vector(x + (index % 2 == 0 and -31 or 31), 2.3, -39)
    if index == 1 then position = vector(x + 46, 2.3, -54) end
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

function World.townHouses(parent)
    local row = Instance.new("Folder")
    row.Name = "Meadow Houses"
    row.Parent = parent
    local stucco = {rgb(213, 184, 133), rgb(161, 194, 168), rgb(187, 151, 134), rgb(183, 190, 211)}
    local roof = {rgb(157, 73, 64), rgb(81, 109, 133), rgb(129, 87, 72), rgb(98, 110, 130)}
    local trim = rgb(232, 221, 185)
    for _, side in ipairs({-1, 1}) do
        piece(row, "Town Sidewalk", vector(3.35, .15, 105), vector(side * 62.65, .65, 52),
            rgb(184, 186, 173), material.Plastic)
        for index, z in ipairs({9, 26, 44, 61, 79, 97}) do
            local house = Instance.new("Model")
            house.Name = "Meadow House " .. (side == -1 and index or index + 6)
            house.Parent = row
            local pose = CFrame.new(side * 68.5, .5, z) * CFrame.Angles(0, -side * math.pi / 2, 0)
            local width = index % 2 == 0 and 10.6 or 11.7
            local height = index % 2 == 0 and 6.5 or 7.25
            local function detail(name, size, offset, color, surface, solid)
                local cf = pose * CFrame.new(offset)
                local object = piece(house, name, size, cf.Position, color, surface, solid)
                object.CFrame = cf
                return object
            end
            detail("House Foundation", vector(width + .36, .54, 8.7), vector(0, .27, 0),
                rgb(116, 123, 117), material.Concrete, true)
            local scheme = (index + (side == 1 and 1 or 0) - 1) % #stucco + 1
            detail("House Shell", vector(width, height, 8.35), vector(0, height / 2 + .33, 0),
                stucco[scheme], material.Plastic, true)
            for level = 1, 3 do
                detail("Stepped Roof", vector(width + 1, .62, 9.2 - level * 1.90),
                    vector(0, height + level * .59, 0), roof[scheme], material.Plastic, true)
            end
            detail("Roof Eaves", vector(width + 1.15, .33, 9.3), vector(0, height + .38, 0),
                roof[scheme], material.Plastic, true)
            detail("Closed House Door", vector(1.81, 3.25, .17), vector(-.55, 1.80, 4.23),
                roof[scheme], material.WoodPlanks)
            detail("Door Knob", vector(.11, .12, .12), vector(.07, 1.64, 4.38),
                rgb(222, 176, 98), material.Metal)
            detail("Door Lintel", vector(2.17, .17, .18), vector(-.55, 3.49, 4.25), trim, material.Plastic)
            detail("Door Step", vector(2.53, .24, 1.14), vector(-.55, .14, 4.7), trim, material.Concrete, true)
            for _, windowX in ipairs({-width * .31, width * .30}) do
                detail("Window Frame", vector(1.69, 1.62, .16), vector(windowX, height * .59, 4.23),
                    trim, material.Plastic)
                detail("Window Pane", vector(1.43, 1.35, .08), vector(windowX, height * .59, 4.34),
                    rgb(123, 162, 182), material.SmoothPlastic)
                detail("Window Crossbar", vector(1.49, .10, .075), vector(windowX, height * .59, 4.39),
                    trim, material.Plastic)
            end
            if index % 2 == 1 then
                detail("Porch Bench", vector(2.4, .24, .8), vector(2.9, .98, 4.86),
                    timber, material.WoodPlanks)
                detail("Bench Legs", vector(1.94, .71, .66), vector(2.9, .43, 4.86), timber, material.Wood)
                detail("Porch Parcel", vector(.77, .56, .72), vector(3.25, 1.38, 4.82),
                    rgb(184, 151, 99), material.WoodPlanks)
            else
                detail("Window Flower Box", vector(1.9, .38, .45), vector(width * .30, height * .59 - .85, 4.53),
                    timber, material.WoodPlanks)
                for bloom = -1, 1 do
                    detail("Window Blossom", vector(.18, .34, .21),
                        vector(width * .30 + bloom * .46, height * .59 - .58, 4.58),
                        bloom == 0 and rgb(237, 175, 104) or rgb(220, 133, 136), material.Grass)
                end
            end
            if index == 2 or index == 4 or index == 6 then
                detail("Chimney", vector(1.2, 2.7, 1.17), vector(width * .27, height + 1.51, -1.52),
                    rgb(148, 105, 87), material.Brick, true)
                detail("Chimney Cap", vector(1.43, .20, 1.43), vector(width * .27, height + 2.9, -1.52),
                    rgb(173, 138, 112), material.Plastic)
                if index == 2 or index == 6 then
                    local smoke = Instance.new("Smoke")
                    smoke.Color = rgb(223, 225, 223)
                    smoke.Opacity = .12
                    smoke.RiseVelocity = 2.2
                    smoke.Size = 2.8
                    local vent = detail("Chimney Vent", vector(.11, .11, .11),
                        vector(width * .27, height + 3.04, -1.52), trim, material.Plastic)
                    vent.Transparency = 1
                    smoke.Parent = vent
                end
            end
        end
    end
end

function World.overlookPark(parent)
    local park = Instance.new("Folder")
    park.Name = "Overlook Park"
    park.Parent = parent
    local buff = rgb(209, 194, 146)
    local grass = rgb(101, 150, 78)
    local skyBlue = rgb(89, 165, 196)
    local shade = rgb(79, 106, 91)
    -- Keep the central lane continuous through the wayshrines and into the park.
    piece(park, "Overlook Path", vector(9.6, .12, 31), vector(0, .56, 91.2), buff, material.Cobblestone)
    piece(park, "Park Crosswalk", vector(83, .12, 4.8), vector(0, .57, 86), buff, material.Cobblestone)
    piece(park, "Overlook Lawn", vector(88, .08, 23), vector(0, .53, 96), grass, material.Plastic)
    shopSign(park, "OVERLOOK PARK", vector(12, 3.18, 83.8), vector(7.2, 1.5, .24), shade, math.pi)

    piece(park, "Pond Stone Rim", vector(22.9, .28, 14.7), vector(-18.8, .69, 96), shade, material.Slate)
    local water = piece(park, "Overlook Pond", vector(21.6, .13, 13.5), vector(-18.8, .86, 96),
        skyBlue, material.Glass)
    water.Transparency = .17
    for _, pos in ipairs({{-26.4, 92.7}, {-20.5, 99.2}, {-13.1, 94.2}}) do
        piece(park, "Pond Lily Pad", vector(.12, 1.25, 1.25), vector(pos[1], .99, pos[2]),
            rgb(80, 151, 93), material.Plastic, false, Enum.PartType.Cylinder, CFrame.Angles(0, 0, math.pi / 2))
    end
    for index = 1, 2 do
        local center = vector(-18 - index * 1.65, 1.10, 93.9 + index * 1.72)
        local body = piece(park, "Pond Duck", vector(.58, .38, .84), center,
            rgb(244, 218, 137), material.Plastic)
        local head = piece(park, "Duck Head", vector(.38, .35, .38), center + vector(0, .25, -.33),
            rgb(244, 218, 137), material.Plastic)
        local bill = piece(park, "Duck Bill", vector(.28, .11, .28), center + vector(0, .19, -.59),
            rgb(223, 141, 65), material.Plastic)
        for _, part in ipairs({body, head, bill}) do
            local motion = TweenService:Create(part, TweenInfo.new(1.2 + .25 * index, Enum.EasingStyle.Sine,
                Enum.EasingDirection.InOut, -1, true), { Position = part.Position + vector(index * .33, .17, -.45) })
            motion:Play()
        end
    end

    local shelter = vector(25.4, .5, 96.4)
    piece(park, "Lookout Patio", vector(14.5, .28, 10.6), shelter + vector(0, .15, 0), buff, material.Cobblestone)
    for _, side in ipairs({-1, 1}) do
        for _, edge in ipairs({-1, 1}) do
            piece(park, "Lookout Post", vector(.59, 6.25, .58), shelter + vector(side * 6.3, 3.28, edge * 4.49),
                timber, material.Wood, true)
        end
        local seat = piece(park, "Lookout Bench", vector(3.6, .32, 1.35), shelter + vector(side * 3.95, 1.05, 1.9),
            timber, material.WoodPlanks, true, nil, nil, "Seat")
        seat.CanTouch = true
        piece(park, "Lookout Rail", vector(13.2, .27, .24), shelter + vector(0, 2.71 + side * .39, 4.51),
            timber, material.Wood)
    end
    piece(park, "Lookout Roof", vector(14.1, .52, 10.4), shelter + vector(0, 6.65, 0),
        rgb(123, 87, 66), material.Plastic, true)
    piece(park, "Lookout Roof Cap", vector(13.4, .30, 7.1), shelter + vector(0, 7.01, 0),
        rgb(159, 119, 83), material.Plastic)
    lamp(park, vector(10, .5, 91), rgb(245, 219, 151))
    lamp(park, vector(-10, .5, 104), rgb(245, 219, 151))
end

local plantingGround = {
    ["Ground"] = true,
    ["Deep Floor"] = true,
    ["Starter Mine Ground"] = true,
}

local function footprint(part)
    local cf, size = part.CFrame, part.Size
    local right, up, look = cf.RightVector, cf.UpVector, cf.LookVector
    return vector(
        (math.abs(right.X) * size.X + math.abs(up.X) * size.Y + math.abs(look.X) * size.Z) / 2,
        (math.abs(right.Y) * size.X + math.abs(up.Y) * size.Y + math.abs(look.Y) * size.Z) / 2,
        (math.abs(right.Z) * size.X + math.abs(up.Z) * size.Y + math.abs(look.Z) * size.Z) / 2
    )
end

local function plantingArea(parent, scenery, x, style, seed)
    local folder = Instance.new("Folder")
    folder.Name = "Foliage"
    folder.Parent = parent
    local bounds = {}
    local market
    local lawn
    for _, part in ipairs(scenery) do
        if part:IsA("BasePart") and math.abs(part.Position.X - x) < 130 then
            local radius = footprint(part)
            local center = part.Position
            if part.Name == "Market Square" then
                market = { Center = center, Radius = radius }
            elseif part.Name == "Overlook Lawn" then
                lawn = { Center = center, Radius = radius }
            elseif not plantingGround[part.Name] and center.Y + radius.Y > .51 and center.Y - radius.Y < 3.4 then
                table.insert(bounds, { Center = center, Radius = radius })
            end
        end
    end

    local function overlaps(area, position, spanX, spanZ, gap)
        return math.abs(area.Center.X - position.X) < area.Radius.X + spanX + gap
            and math.abs(area.Center.Z - position.Z) < area.Radius.Z + spanZ + gap
    end
    local function clear(position, spanX, spanZ, inPlanter)
        if market and not inPlanter and overlaps(market, position, spanX, spanZ, .5) then return false end
        for _, area in ipairs(bounds) do
            if overlaps(area, position, spanX, spanZ, .48) then return false end
        end
        return true
    end
    local function surface(px, pz, spanX, spanZ)
        local position = vector(x + px, .5, pz)
        if not lawn then return position end
        if not overlaps(lawn, position, spanX, spanZ, .04) then return position end
        if math.abs(position.X - lawn.Center.X) + spanX <= lawn.Radius.X
            and math.abs(position.Z - lawn.Center.Z) + spanZ <= lawn.Radius.Z then
            return vector(position.X, lawn.Center.Y + lawn.Radius.Y, position.Z)
        end
        return nil
    end

    local rng = Random.new(seed)
    local function patch(px, pz, size)
        local span = math.max(2.23 * size, 1.65 * size + .64)
        local position = surface(px, pz, span, span)
        if not position or not clear(position, span, span) then return end
        shrub(folder, position, size, style, rng)
        for _, side in ipairs({-1, 1}) do
            local offset = vector(side * 1.65, 0, rng:NextNumber(.77, 1.34)) * size
            groundCover(folder, position + offset, style, rng)
            local height = rng:NextNumber(.48, .97) * size
            piece(folder, style.Sprout, vector(.28, height, .27),
                position + vector(-side * .49 * size, height * .5, -1.77 * size), style.Accent,
                style.Surface, false, Enum.PartType.Ball)
        end
    end
    local function canopy(px, pz, height, snowy)
        local span = height * .86
        local position = surface(px, pz, span, span)
        if not position or not clear(position, span, span) then return end
        if snowy then
            pine(parent, position, height)
        else
            tree(parent, position, height, rgb(64, 123, 75):Lerp(rgb(105, 145, 71), rng:NextNumber(.05, .66)))
        end
        -- Keep neighbouring planting beds clear of the tree's root flare.
        table.insert(bounds, { Center = position, Radius = vector(height * .22, 0, height * .22) })
    end
    local function planter(px, pz)
        local position = vector(x + px, .62, pz)
        if not clear(position, 3.75, 1.82, true) then return end
        piece(folder, "Market Planter", vector(7.5, .62, 3.64), position + vector(0, .31, 0),
            rgb(127, 88, 58), material.WoodPlanks, true)
        piece(folder, "Planter Soil", vector(7.1, .14, 3.23), position + vector(0, .69, 0),
            rgb(95, 68, 49), material.Ground)
        for _, side in ipairs({-1, 1}) do
            shrub(folder, position + vector(side * 1.76, .76, .02), .72, style, rng)
        end
        groundCover(folder, position + vector(0, .76, 0), style, rng)
    end
    return patch, canopy, planter
end

function World.landscape(world)
    local scenery = world:GetDescendants()
    local meadow = world:FindFirstChild(config.Zones[1].Name)
    local patch, canopy, planter = plantingArea(meadow, scenery, 0, shrubStyles[1], 6131)
    for _, side in ipairs({-1, 1}) do
        for _, point in ipairs({{19,-29}, {39,-20}, {47,-48}, {23,-58}, {9,-78}, {36,-84},
            {65,-66}, {64,-31}, {82,-47}, {82,-15}, {82,14}, {82,48}, {82,77}, {82,99}, {49,96}, {39,96}}) do
            canopy(side * point[1], point[2], 7.8)
        end
        for _, point in ipairs({{8,-19}, {18,-17}, {27,-23}, {34,-32}, {12,-46}, {29,-49}, {58,-16}, {72,-19},
            {18,-72}, {58,-76}, {53,-91}, {16,-96}, {77,-89}, {75,-58}, {60,-56},
            {79,3}, {78,26}, {81,35}, {77,62}, {80,90}, {73,105}, {53,106}, {52,81},
            {33,83}, {30,105}, {10,99}, {13,91}, {38,92}}) do
            patch(side * point[1], point[2], 1.04)
        end
        planter(side * 13.5, 36)
        planter(side * 12.5, 51)
    end

    local starter = world:FindFirstChild("Meadow Mine Grounds")
    local starterPatch, starterCanopy = plantingArea(starter, scenery, config.StarterMineX, shrubStyles[1], 6050)
    for _, side in ipairs({-1, 1}) do
        for _, point in ipairs({{20,17}, {41,23}, {34,42}, {54,37}}) do
            starterCanopy(side * point[1], point[2], 8.1)
        end
        for _, point in ipairs({{11,14}, {19,6}, {28,12}, {36,6}, {45,8}, {44,31},
            {15,29}, {24,38}, {46,46}, {12,46}, {57,-16}, {57,-38}, {32,-55}, {15,-55}}) do
            starterPatch(side * point[1], point[2], 1.05)
        end
    end

    for index = 2, #config.Zones do
        local parent = world:FindFirstChild(config.Zones[index].Name)
        local biomePatch, biomeCanopy = plantingArea(parent, scenery, config.zoneCenter(index), shrubStyles[index], 6130 + index)
        for _, side in ipairs({-1, 1}) do
            if index == 3 then
                biomeCanopy(side * 18, 16, 9.2, true)
                biomeCanopy(side * 33, 34, 9.7, true)
                biomeCanopy(side * 17, 40, 8.1, true)
            end
            for _, point in ipairs({{12,4}, {21,-1}, {30,1}, {35,9}, {14,24}, {22,30}, {28,18},
                {38,17}, {38,31}, {26,42}, {42,44}, {11,45}, {28,-42}, {34,-47}, {47,-26}}) do
                biomePatch(side * point[1], point[2], index == 2 and .78 or .9)
            end
        end
        if index == config.Resonance.Zone then
            for _, point in ipairs({{-37,-21}, {-36,-40}, {-37,-70}, {-18,-76}, {37,-32}, {37,-53}, {17,-57}, {30,-65}}) do
                biomePatch(point[1], point[2], .73)
            end
        end
    end
end

function World.marketCanopy(parent, anchor, width, color)
    local origin = anchor.Position
    local pale = rgb(228, 213, 173)
    for _, side in ipairs({-1, 1}) do
        piece(parent, "Market Stand Post", vector(.32, 5.9, .32),
            origin + vector(side * (width / 2 - .25), 1.72, 1.32), pale, material.Plastic)
    end
    piece(parent, "Market Stand Canopy", vector(width, .34, 3.95),
        origin + vector(0, 4.6, .22), color, material.Plastic)
    for stripe = -2, 2 do
        piece(parent, "Canopy Stripe", vector(width / 5, .44, .22),
            origin + vector(stripe * width / 5, 4.43, -1.75),
            stripe % 2 == 0 and color or pale, material.Plastic)
    end
end

function World.station(parent, anchor, color)
    local position = anchor.Position
    local cream = rgb(231, 221, 184)
    anchor.Material = material.Plastic
    for _, dx in ipairs({-4.15, 4.15}) do
        piece(parent, "Stall Post", vector(.62, 6, .62), position + vector(dx, 1.5, 3.8), cream, material.Plastic, true)
    end
    piece(parent, "Stall Roof", vector(10, .48, 9), position + vector(0, 4.7, 0), color, material.Plastic, true)
    piece(parent, "Counter Trim", vector(9.3, .4, 9.3), position + vector(0, 1.85, 0), cream, material.Plastic)
    for stripe = -4, 4 do
        local tint = stripe % 2 == 0 and color or cream
        piece(parent, "Striped Fascia", vector(1.1, .72, .24), position + vector(stripe * 1.1, 4.39, -4.46),
            tint, material.Plastic)
    end
    piece(parent, "Shop Emblem", vector(1.38, 1.38, .26), position + vector(0, 2.61, -4.72),
        color, material.Plastic, false, nil, CFrame.Angles(0, 0, math.rad(45)))
end

function World.forge(parent, anchor, picks, color)
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
    piece(parent, "Forge Canopy", vector(17, .4, 8), at(0, 5.6, 3), color, material.Plastic, true,
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

function World.frostPress(parent, anchor)
    local pos = anchor.Position
    anchor.Material = material.Slate
    local steel = rgb(75, 108, 128)
    piece(parent, "Frost Seal Counter", vector(5.8, .34, 3.4), pos + vector(0, 1.42, 0), timber, material.Wood)
    piece(parent, "Seal Press Frame", vector(.6, 2.05, .58), pos + vector(0, 2.53, .45), steel, material.Metal)
    piece(parent, "Seal Press Lever", vector(1.62, .2, .22), pos + vector(.49, 3.4, .4), steel,
        material.Metal, false, nil, CFrame.Angles(0, 0, -.23))
    local lens = piece(parent, "Frost Seal Display", vector(.64, .54, .63), pos + vector(0, 1.96, -.46),
        rgb(142, 224, 255), material.Glass, false, nil, CFrame.Angles(0, .57, .23))
    light(lens, lens.Color, .9, 8)
end

function World.styleGallery(parent, anchor, skins)
    anchor.Material = material.WoodPlanks
    local origin = anchor.Position
    piece(parent, "Style Gallery Base", vector(6.8, .25, 3.7), origin + vector(0, -1.12, 0),
        darkStone, material.Slate)
    piece(parent, "Style Gallery Counter", vector(6.2, .4, 3.7), origin + vector(0, 1.31, 0),
        timber, material.Wood)
    piece(parent, "Style Display Back", vector(6.1, 3.5, .28), origin + vector(0, 2.94, 1.45),
        rgb(61, 57, 85), material.Fabric)
    for _, finish in ipairs(skins) do
        if finish.Pass then
            local x = finish.Pass == 1 and -1.45 or 1.45
            local pose = CFrame.new(origin + vector(x, 2.8, 1.11)) * CFrame.Angles(0, math.pi, math.rad(x * 8))
            Pickaxes.model(parent, pose, 4, true, finish)
        end
    end
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

function World.travelPulse(anchor)
    local shimmer = anchor:FindFirstChild("Wayshrine Ripple")
    if not shimmer then
        shimmer = particles(anchor, anchor.Color, 0, NumberRange.new(2.8, 5.3),
            NumberRange.new(.55, .84), NumberSequence.new(.24, .06))
        shimmer.Name = "Wayshrine Ripple"
        shimmer.SpreadAngle = Vector2.new(120, 120)
        shimmer.Acceleration = vector(0, 2.3, 0)
    end
    shimmer:Emit(19)
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
    anchor.Size = vector(8, .65, 8)
    local position = vector(anchor.Position.X, .81, anchor.Position.Z)
    anchor.Position = position
    anchor.Material = material.Slate
    anchor.Color = darkStone
    piece(parent, "Teleporter Plate", vector(6.85, .08, 6.85), position + vector(0, .34, 0),
        color:Lerp(darkStone, .58), material.Plastic)
    for _, side in ipairs({-1, 1}) do
        piece(parent, "Teleporter Inlay", vector(.27, .10, 6.12), position + vector(side * 2.96, .39, 0),
            color, material.Neon)
    end
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
    local status = World.fieldSign(mine, "Resonance Gate Sign", at(0, 4.9, -31), 8.25,
        "CRYSTAL RESONANCE", "Tune the three pulsing veins")
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

    local gateOpen = false
    local gateTween
    return {
        Veins = veins, Status = status, Cache = cache, Exit = exit,
        ExitPosition = at(0, 5, -27),
        ChamberX = x + 22,
        FrontZ = -63.2,
        BackZ = -76,
        Gate = function(open)
            if open == gateOpen then return end
            gateOpen = open
            if gateTween then gateTween:Cancel() end
            door.CanCollide = false
            door.CanQuery = false
            local target = open and (closed * CFrame.new(0, 8.7, 0)) or closed
            local tween = TweenService:Create(door, TweenInfo.new(open and .72 or .55, Enum.EasingStyle.Quad), {CFrame = target})
            gateTween = tween
            tween.Completed:Connect(function(result)
                if result == Enum.PlaybackState.Completed and gateTween == tween and not gateOpen then
                    door.CanQuery = true
                    door.CanCollide = true
                end
            end)
            tween:Play()
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
