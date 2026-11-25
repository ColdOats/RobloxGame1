local TweenService = game:GetService("TweenService")
local Pickaxes = {}

local colors = {
    Color3.fromRGB(144, 151, 156),
    Color3.fromRGB(194, 204, 210),
    Color3.fromRGB(107, 160, 203),
    Color3.fromRGB(166, 103, 241),
    Color3.fromRGB(68, 233, 185),
    Color3.fromRGB(255, 129, 63),
}

function Pickaxes.color(tier)
    return colors[tier]
end

function Pickaxes.model(parent, origin, tier, anchored, finish)
    local metal = finish and finish.Color or colors[tier]
    local accent = finish and finish.Accent
    local function piece(name, size, offset, color, material)
        local part = Instance.new("Part")
        part.Name = name
        part.Size = size
        part.CFrame = origin * offset
        part.Color = color
        part.Material = material
        part.Anchored = anchored
        part.CanCollide = false
        part.CanTouch = false
        part.CanQuery = false
        part.Massless = true
        part.Parent = parent
        return part
    end

    local handle = piece("Handle", Vector3.new(.24, 2.85, .24), CFrame.new(),
        Color3.fromRGB(106, 65, 42), Enum.Material.Wood)
    local function attach(name, size, offset, color, material)
        local part = piece(name, size, offset, color, material)
        if not anchored then
            local weld = Instance.new("WeldConstraint")
            weld.Part0 = handle
            weld.Part1 = part
            weld.Parent = part
        end
    end

    attach("Grip Wrap", Vector3.new(.32, 1.05, .32), CFrame.new(0, -.63, 0),
        Color3.fromRGB(41, 35, 40), Enum.Material.Fabric)
    attach("Head", Vector3.new(1.55, .3, .34), CFrame.new(0, 1.18, 0), metal, Enum.Material.Metal)
    for _, side in ipairs({-1, 1}) do
        attach("Beak", Vector3.new(.68, .24, .29),
            CFrame.new(side * .98, 1.04, 0) * CFrame.Angles(0, 0, -side * .45), metal, Enum.Material.Metal)
    end
    if accent then
        for _, side in ipairs({-1, 1}) do
            attach("Gold Etching", Vector3.new(.53, .075, .035),
                CFrame.new(side * .43, 1.2, -.185), accent, Enum.Material.Neon)
        end
    end
    if tier >= 4 or accent then
        attach("Inlay", Vector3.new(.33, .39, .38),
            CFrame.new(0, 1.18, 0) * CFrame.Angles(0, 0, math.rad(45)), accent or metal, Enum.Material.Neon)
    end
end

function Pickaxes.sync(player, pick, tier, finish)
    local backpack = player:FindFirstChildOfClass("Backpack")
    local starterGear = player:FindFirstChildOfClass("StarterGear")
    local character = player.Character
    local wasEquipped = false

    local function clear(container)
        if not container then return end
        for _, item in ipairs(container:GetChildren()) do
            if item:IsA("Tool") and item:GetAttribute("MiningPickaxe") == true then
                item:Destroy()
            end
        end
    end

    if character then
        for _, item in ipairs(character:GetChildren()) do
            if item:IsA("Tool") and item:GetAttribute("MiningPickaxe") == true then
                wasEquipped = true
                break
            end
        end
    end

    clear(character)
    clear(backpack)
    clear(starterGear)

    local tool = Instance.new("Tool")
    tool.Name = pick.Name .. " Pickaxe"
    tool.ToolTip = string.format("%d mining power • %.2fs between swings", pick.Power, pick.SwingCooldown)
    tool.CanBeDropped = false
    tool.Grip = CFrame.new(0, -.55, 0) * CFrame.Angles(math.rad(15), 0, 0)
    tool:SetAttribute("MiningPickaxe", true)
    Pickaxes.model(tool, CFrame.new(), tier, false, finish)

    if starterGear then tool:Clone().Parent = starterGear end
    if backpack then
        tool.Parent = backpack
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        if wasEquipped and humanoid and humanoid.Health > 0 then
            humanoid:EquipTool(tool)
        end
    else
        tool:Destroy()
    end
end

local swinging = {}

function Pickaxes.swing(player)
    local character = player.Character
    if not character then return end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then return end
    local function findPickaxe(container)
        if not container then return nil end
        for _, item in ipairs(container:GetChildren()) do
            if item:IsA("Tool") and item:GetAttribute("MiningPickaxe") then return item end
        end
        return nil
    end
    local tool = findPickaxe(character)
    if not tool then
        tool = findPickaxe(player:FindFirstChildOfClass("Backpack"))
        if not tool then return end
        humanoid:EquipTool(tool)
    end

    local shoulder
    local arm = character:FindFirstChild("RightUpperArm") or character:FindFirstChild("Right Arm")
    if not arm then return end
    for _, joint in ipairs(character:GetDescendants()) do
        if joint:IsA("Motor6D") and joint.Part1 == arm and joint.Part0 and joint.Part0:IsDescendantOf(character) then
            shoulder = joint
            break
        end
    end
    if not shoulder or swinging[shoulder] then return end

    swinging[shoulder] = true
    local resting = shoulder.C0
    task.spawn(function()
        local function pose(target, duration, direction)
            if not shoulder:IsDescendantOf(character) then return false end
            local tween = TweenService:Create(shoulder, TweenInfo.new(duration, Enum.EasingStyle.Quad, direction),
                { C0 = target })
            tween:Play()
            return tween.Completed:Wait() == Enum.PlaybackState.Completed
        end

        local function strikePose(pitch, roll)
            return CFrame.new(resting.Position) * CFrame.Angles(math.rad(pitch), 0, math.rad(roll)) * resting.Rotation
        end
        if pose(strikePose(120, 17), .085, Enum.EasingDirection.Out)
            and pose(strikePose(18, -12), .075, Enum.EasingDirection.In) then
            pose(resting, .13, Enum.EasingDirection.Out)
        end
        if shoulder.Parent then shoulder.C0 = resting end
        swinging[shoulder] = nil
    end)
end

return Pickaxes
