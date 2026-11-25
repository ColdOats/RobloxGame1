local BiomeView = {}

function BiomeView.start(player, workspace, zoneAt)
    local view = { Zone = 1 }
    local world, spawn
    local watcher

    local function updatePart(part)
        if not part:IsA("BasePart") then return end
        local root = part
        while root.Parent and root.Parent ~= world do root = root.Parent end
        if root.Parent ~= world then return end
        -- Market props sit beside the named zone folders and belong to Meadow.
        local index = root:GetAttribute("BiomeIndex") or 1
        part.LocalTransparencyModifier = index == view.Zone and 0 or 1
    end

    local function refresh()
        if not world then return end
        for _, part in ipairs(world:GetDescendants()) do updatePart(part) end
        if spawn then
            for _, part in ipairs(spawn:GetDescendants()) do
                if part:IsA("BasePart") then part.LocalTransparencyModifier = view.Zone == 1 and 0 or 1 end
            end
        end
    end

    task.spawn(function()
        while player.Parent do
            local character = player.Character
            local root = character and character:FindFirstChild("HumanoidRootPart")
            local zone = root and zoneAt(root.Position.X)
            local nextWorld = workspace:FindFirstChild("CrystalWorld")
            local nextSpawn = workspace:FindFirstChild("MiningStart")
            local spawnChanged = nextSpawn ~= spawn
            spawn = nextSpawn
            if nextWorld ~= world then
                if watcher then watcher:Disconnect(); watcher = nil end
                world = nextWorld
                if world then watcher = world.DescendantAdded:Connect(updatePart) end
                if zone then view.Zone = zone end
                refresh()
            elseif spawnChanged or (zone and zone ~= view.Zone) then
                view.Zone = zone or view.Zone
                refresh()
            end
            task.wait(.18)
        end
        if watcher then watcher:Disconnect() end
    end)

    return view
end

return BiomeView
