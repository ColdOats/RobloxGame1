local Players=game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local RS=game:GetService("ReplicatedStorage")
local DSS=game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local C=require(RS:WaitForChild("MiningConfig"))
local Pickaxes=require(script.Parent:WaitForChild("Pickaxes"))
local World=require(script.Parent:WaitForChild("World"))
local Premium=require(script.Parent:WaitForChild("Premium"))
local SessionStore = require(script.Parent:WaitForChild("SessionStore"))
local isStudio = game:GetService("RunService"):IsStudio()
local store
local closing = false
local remote=Instance.new("RemoteEvent"); remote.Name="MiningAction"; remote.Parent=RS
local equipRemote = Instance.new("RemoteEvent")
equipRemote.Name = "EquipCollection"
equipRemote.Parent = RS
local premiumRemote = Instance.new("RemoteEvent")
premiumRemote.Name = "PremiumAction"
premiumRemote.Parent = RS
local mineRemote = Instance.new("RemoteEvent")
mineRemote.Name = "SwingAtOre"
mineRemote.Parent = RS
local oreActions = {}
local lastEquip = {}
local relayRuns = {}
local tideRuns = {}
local emberRuns = {}
local veinChains = {}
local descentRuns = {}
local premiumBusy, lastPremium = {}, {}
local profiles, sessions, last, loading, departing = {}, {}, {}, {}, {}
local function fresh()
 local profile = { Coins=0, Crystals=0, Pick=1, Zone=1, Pet=0, Rebirths=0, Discoveries=0,
  Bag=1, Orders=0, OrderZone=0, OrderNodes=0, OrderCrystals=0, GuidedOrder=0,
  PetsOwned=0, SkinsOwned=0, AurasOwned=0, Skin=0, Aura=0, RelayBestMs=0, EmberBestMs=0, DeepLift=0, AmethystReserve=0, SurveyorLantern=0, Specimens=0, GeodeCompass=0, MasterBanked=0, HeartstoneTrophy=0 }
 for index in ipairs(C.Zones) do
  profile["CaveNodes" .. index] = 0
  profile[C.oreKey(index)] = 0
  profile["Geodes" .. index] = 0
 end
 return profile
end
local function capacity(d)
 return C.Bags[d.Bag].Capacity + d.Rebirths * 25
end
local function clearOre(d)
 d.Crystals = 0
 for index in ipairs(C.Zones) do d[C.oreKey(index)] = 0 end
end

local function validateOre(d)
 local remaining = d.Crystals
 for index in ipairs(C.Zones) do
  local key = C.oreKey(index)
  d[key] = math.min(d[key], remaining)
  remaining -= d[key]
 end
 d.SurveyorLantern = math.min(d.SurveyorLantern, 1)
 d.AmethystReserve = d.SurveyorLantern == 1 and 0 or math.min(d.AmethystReserve, C.SurveyorLantern.Cost)
end

local function sync(p)
 local d=profiles[p]; if not d then return end
 for k,v in pairs(d) do p:SetAttribute(k,v) end
 p:SetAttribute("Capacity",capacity(d))
 local stats=p:FindFirstChild("leaderstats"); if stats then stats.Coins.Value=d.Coins; stats.Rebirths.Value=d.Rebirths end
end
local function notify(p,s,effect) remote:FireClient(p,s,effect) end
local function activeProfile(p)
 local d = profiles[p]
 local session = sessions[p]
 if not d or p.Parent ~= Players or closing or (session and session.ExpiresAt <= os.time()) then return nil end
 return d
end

local function releaseSession(p, session, snapshot)
 if not session then return end
 while session.Busy do task.wait() end
 for attempt = 1, 3 do
  local record, reason = store:save(p.UserId, session.Owner, snapshot, true)
  if record or reason == "lost" then return end
  if reason ~= "unavailable" then break end
  if attempt < 3 then task.wait(attempt) end
 end
 warn("Could not save and release mining profile:", p.UserId)
end

local function autosave(p)
 local session = sessions[p]
 local profile = activeProfile(p)
 if not session or not profile or session.Busy then return end
 session.Busy = true
 local record, reason = store:save(p.UserId, session.Owner, table.clone(profile), false)
 if record then session.ExpiresAt = record.Session.ExpiresAt end
 session.Busy = false
 if (reason == "lost" or reason == "invalid") and sessions[p] == session and p.Parent == Players then
  session.ExpiresAt = 0
  p:Kick("Your mining save session ended. Please rejoin.")
 end
end

local function refreshPickaxe(p, d)
 local finish = C.Skins[d.Skin]
 if finish and finish.Premium and not Premium.owns(p, finish.Premium) then finish = nil end
 Pickaxes.sync(p, C.Picks[d.Pick], d.Pick, finish)
end

local function refreshLook(p, character, d)
 local aura = C.Auras[d.Aura]
 if aura and aura.Premium and not Premium.owns(p, aura.Premium) then aura = nil end
 local root = character and character:FindFirstChild("HumanoidRootPart")
 if root then
  World.playerStyle(root, C.Pets[d.Pet], aura)
  if d.SurveyorLantern == 1 then World.surveyorLantern(root) end
 end
end

local function add(p)
 if closing or profiles[p] or loading[p] then return end
 local attemptState = {}
 loading[p] = attemptState
 local record, reason
 local owner = HttpService:GenerateGUID(false)
 if store then
  for attempt = 1, 4 do
   record, reason = store:acquire(p.UserId, owner)
   if record or reason == "invalid" or attemptState.Cancelled or p.Parent ~= Players or closing then break end
   if attempt < 4 then task.wait(attempt) end
  end
 else
  reason = "unavailable"
 end
 local session = record and { Owner = owner, ExpiresAt = record.Session.ExpiresAt }
 if attemptState.Cancelled or p.Parent ~= Players or closing then
  releaseSession(p, session)
  loading[p] = nil
  return
 end
 if not record and (not isStudio or reason ~= "unavailable") then
  loading[p] = nil
  p:Kick(reason == "locked" and "Your save is still open in another server. Please rejoin shortly."
   or "Your mining save could not load. Please rejoin.")
  return
 end
 local data = record and record.Profile
 local d=fresh(); if type(data)=="table" then for k,v in pairs(d) do if type(data[k])=="number" and data[k]>=0 and data[k]<1e12 then d[k]=math.floor(data[k]) end end end
 d.Pick=math.clamp(d.Pick,1,#C.Picks); d.Zone=math.clamp(d.Zone,1,#C.Zones); d.Pet=math.clamp(d.Pet,0,#C.Pets)
 validateOre(d)
 -- Older saves only recorded the equipped pet.
 if d.Pet > 0 then d.PetsOwned = bit32.bor(d.PetsOwned, bit32.lshift(1, d.Pet - 1)) end
 for _, crate in ipairs(C.Crates) do
  local key = crate.Pool .. "Owned"
  local ownedMask = 2 ^ crate.StandardCount - 1
  for index, item in ipairs(C[crate.Pool]) do
   if item.Expedition or item.Specimen then ownedMask = bit32.bor(ownedMask, bit32.lshift(1, index - 1)) end
  end
  d[key] = bit32.band(d[key], ownedMask)
  local selected = d[crate.Equipped]
  local item = C[crate.Pool][selected]
  if not item or (not item.Premium and not C.owns(d[key], selected)) then d[crate.Equipped] = 0 end
 end
 for index, mastery in ipairs(C.CaveMastery) do
  local key = "CaveNodes" .. index
  d[key] = math.min(d[key], mastery.Master)
  local geodes = "Geodes" .. index
  d[geodes] = math.min(d[geodes], C.GeodeHunt.Limit)
 end
 d.GeodeCompass = math.min(d.GeodeCompass, 1)
 d.MasterBanked = math.min(d.MasterBanked, 1)
 d.HeartstoneTrophy = math.min(d.HeartstoneTrophy, 1)
 d.Specimens = bit32.band(d.Specimens, 2 ^ #C.GeodeHunt.Specimens - 1)
 d.DeepLift = math.clamp(d.DeepLift, 0, 1)
 d.Bag = math.clamp(d.Bag, 1, #C.Bags)
 d.OrderZone = math.clamp(d.OrderZone, 0, #C.Zones)
 if d.OrderZone == 0 then
  d.OrderNodes, d.OrderCrystals, d.GuidedOrder = 0, 0, 0
 else
  local _, nodes, crystals = C.commission(d.Orders, d.OrderZone, d.GuidedOrder == 1)
  d.OrderNodes = math.min(d.OrderNodes, nodes)
  d.OrderCrystals = math.min(d.OrderCrystals, crystals)
 end
 d.Discoveries=math.clamp(d.Discoveries,0,2^#C.Zones-1)
 local backpack = p:WaitForChild("Backpack", 10)
 local starterGear = p:WaitForChild("StarterGear", 10)
 if attemptState.Cancelled or p.Parent ~= Players or closing or not backpack or not starterGear then
  releaseSession(p, session)
  loading[p] = nil
  if not attemptState.Cancelled and p.Parent == Players and not closing then p:Kick("Inventory could not load. Please rejoin.") end
  return
 end
 profiles[p], sessions[p] = d, session
 loading[p] = nil
 local f=Instance.new("Folder"); f.Name="leaderstats"; f.Parent=p
 for _,k in ipairs({"Coins","Rebirths"}) do local n=Instance.new("IntValue"); n.Name=k; n.Parent=f end
 sync(p)
 refreshPickaxe(p, d)
 local function styleCharacter(character)
  if character:WaitForChild("HumanoidRootPart", 10) and p.Character == character and profiles[p] == d then
   refreshLook(p, character, d)
  end
 end
 p.CharacterAdded:Connect(styleCharacter)
 if p.Character then task.defer(styleCharacter, p.Character) end
 p:GetAttributeChangedSignal("PremiumReady"):Connect(function()
  if profiles[p] ~= d then return end
  local skin, aura = C.Skins[d.Skin], C.Auras[d.Aura]
  if skin and skin.Premium then refreshPickaxe(p, d) end
  if aura and aura.Premium then refreshLook(p, p.Character, d) end
 end)
 task.spawn(Premium.load, p)
 if not record then task.delay(3,function() if p.Parent == Players then notify(p,"Studio test: saving disabled") end end) end
end
local world=World.create()
local function part(name,size,pos,color,parent)
 local a=Instance.new("Part"); a.Name=name; a.Size=size; a.Position=pos; a.Color=color; a.Anchored=true; a.Material=Enum.Material.SmoothPlastic; a.Parent=parent or world; return a
end
local function label(p,txt)
 local g=Instance.new("BillboardGui"); g.Size=UDim2.fromOffset(168,48); g.StudsOffset=Vector3.new(0,4,0); g.AlwaysOnTop=false; g.MaxDistance=38; g.Parent=p
 local t=Instance.new("TextLabel"); t.Size=UDim2.fromScale(1,1); t.BackgroundTransparency=1; t.Text=txt; t.TextColor3=Color3.new(1,1,1); t.TextStrokeTransparency=.2; t.TextScaled=true; t.Font=Enum.Font.GothamBold; t.Parent=g
 local textSize = Instance.new("UITextSizeConstraint")
 textSize.MinTextSize = 10
 textSize.MaxTextSize = 16
 textSize.Parent = t
 return t
end
local function close(p, target, distance)
 local character = p.Character
 local root = character and character:FindFirstChild("HumanoidRootPart")
 local humanoid = character and character:FindFirstChildOfClass("Humanoid")
 return root and humanoid and humanoid.Health > 0 and (root.Position - target.Position).Magnitude <= distance
end
local function clearShot(p, target)
 local character = p.Character
 local head = character and character:FindFirstChild("Head")
 if not head then return false end
 local ray = RaycastParams.new()
 ray.FilterDescendantsInstances = {character}
 local hit = workspace:Raycast(head.Position, target.Position - head.Position, ray)
 return not hit or hit.Instance == target
end

local function prompt(a,txt,fn,requiresSight)
 local q=Instance.new("ProximityPrompt"); q.ActionText=txt; q.ObjectText=a.Name; q.MaxActivationDistance=12; q.RequiresLineOfSight=requiresSight==true; q.Parent=a
 q.Triggered:Connect(function(p)
  if not q.Enabled or not activeProfile(p) or not close(p, a, 15) then return end
  if requiresSight and not clearShot(p, a) then return end
  fn(p)
 end)
 return q
end
local function sell(p, anchor)
 local d = profiles[p]
 if d.Crystals == 0 then notify(p, "Your bag is empty!"); return end
 local count = d.Crystals
 local coins = count * (1 + d.Rebirths)
 if d.OrderZone > 0 then
  local _, _, target = C.commission(d.Orders, d.OrderZone, d.GuidedOrder == 1)
  d.OrderCrystals = math.min(target, d.OrderCrystals + count)
 end
 d.Coins += coins
 clearOre(d)
 sync(p)
 World.celebrate(anchor, 15)
 notify(p, "Sold for " .. coins .. " coins!", "coins")
end

local function clearVeinChain(p)
 veinChains[p] = nil
 p:SetAttribute("VeinChainCount", 0)
 p:SetAttribute("VeinChainDeadline", 0)
end

local function recordVein(p, profile, zone, node)
 local hunt = C.GeodeHunt
 local key = "Geodes" .. zone
 local now = workspace:GetServerTimeNow()
 if profile[key] >= hunt.Limit then
  if veinChains[p] then clearVeinChain(p) end
  return false
 end
 local chain = veinChains[p]
 if not chain or chain.Zone ~= zone or now >= chain.Deadline then
  chain = { Zone = zone, Nodes = {}, Count = 0 }
  veinChains[p] = chain
 end
 if chain.Nodes[node] then return false end
 chain.Nodes[node] = true
 chain.Count += 1
 if chain.Count >= hunt.Chain then
  profile[key] += 1
  clearVeinChain(p)
  return true
 end
 chain.Deadline = now + hunt.Window + (profile.GeodeCompass == 1 and C.GeodeCompass.ExtraSeconds or 0)
 p:SetAttribute("VeinChainDeadline", chain.Deadline)
 p:SetAttribute("VeinChainCount", chain.Count)
 return false
end

local function buyCompass(p, anchor)
 local d = profiles[p]
 local compass = C.GeodeCompass
 if d.GeodeCompass == 1 then
  notify(p, "Geode Compass equipped • +" .. compass.ExtraSeconds .. " seconds between veins.")
  return
 end
 if d.Coins < compass.Cost then
  notify(p, "Need " .. compass.Cost .. " coins for the Geode Compass.")
  return
 end
 d.Coins -= compass.Cost
 d.GeodeCompass = 1
 sync(p)
 World.celebrate(anchor, 24)
 notify(p, "Geode Compass purchased • +" .. compass.ExtraSeconds .. " seconds between veins", "buy")
end

local function appraiseGeode(p, anchor)
 local d = profiles[p]
 local hunt = C.GeodeHunt
 local chosen
 for index in ipairs(hunt.Specimens) do
  if d["Geodes" .. index] > 0 then
   chosen = chosen or index
   if not C.owns(d.Specimens, index) then chosen = index; break end
  end
 end
 if not chosen then
  notify(p, "Break " .. hunt.Chain .. " different veins in one cave to earn a geode.")
  return
 end
 local key = "Geodes" .. chosen
 local sample = hunt.Specimens[chosen]
 local found = not C.owns(d.Specimens, chosen)
 d[key] -= 1
 d.Coins += sample.Coins
 d.Specimens = bit32.bor(d.Specimens, bit32.lshift(1, chosen - 1))
 local complete = d.Specimens == 2 ^ #hunt.Specimens - 1 and not C.owns(d.AurasOwned, hunt.Aura)
 if complete then
  d.AurasOwned = bit32.bor(d.AurasOwned, bit32.lshift(1, hunt.Aura - 1))
  d.Aura = hunt.Aura
  refreshLook(p, p.Character, d)
 end
 sync(p)
 World.celebrate(anchor, complete and 40 or 20)
 local detail = complete and " • Prismatic Fieldwork unlocked!" or found and " • Specimen collected" or ""
 notify(p, sample.Name .. " • +" .. sample.Coins .. " coins" .. detail, "reward")
end

local function craftLantern(p, anchor)
 local d = profiles[p]
 local recipe = C.SurveyorLantern
 if d.SurveyorLantern == 1 then
  notify(p, "Your Surveyor’s Lantern is equipped. Watch for nearby rich-vein markers.")
  return
 end

 local key = C.oreKey(recipe.Zone)
 local needed = recipe.Cost - d.AmethystReserve
 local moved = math.min(needed, d[key])
 if moved == 0 and needed > 0 then
  notify(p, "Surveyor’s Lantern • " .. d.AmethystReserve .. "/" .. recipe.Cost .. " Amethyst set aside")
  return
 end
 d[key] -= moved
 d.Crystals -= moved
 d.AmethystReserve += moved
 if d.AmethystReserve < recipe.Cost then
  sync(p)
  notify(p, "Set aside " .. moved .. " Amethyst • " .. d.AmethystReserve .. "/" .. recipe.Cost, "accept")
  return
 end

 d.SurveyorLantern = 1
 d.AmethystReserve = 0
 sync(p)
 local root = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
 if root then World.surveyorLantern(root) end
 World.celebrate(anchor, 34)
 notify(p, "Surveyor’s Lantern crafted! Nearby rich veins are marked.", "reward")
end

local function buyBag(p, anchor)
 local d = profiles[p]
 local nextBag = C.Bags[d.Bag + 1]
 if not nextBag then notify(p, "You already own the largest bag."); return end
 if d.Coins < nextBag.Cost then notify(p, "Need " .. nextBag.Cost .. " coins for " .. nextBag.Name .. "."); return end
 d.Coins -= nextBag.Cost
 d.Bag += 1
 sync(p)
 World.celebrate(anchor, 22)
 notify(p, nextBag.Name .. " purchased • " .. capacity(d) .. " capacity", "buy")
end

local function commissions(p, anchor)
 local d = profiles[p]
 if d.OrderZone == 0 then
  d.OrderZone = d.Zone
  d.GuidedOrder = d.Orders == 0 and d.Zone == 1 and d.Rebirths == 0 and 1 or 0
  d.OrderNodes, d.OrderCrystals = 0, 0
  local name = C.commission(d.Orders, d.OrderZone, d.GuidedOrder == 1)
  sync(p)
  notify(p, name .. " accepted. Open the Orders tab for objectives.", "accept")
  return
 end
 local name, nodes, crystals, reward = C.commission(d.Orders, d.OrderZone, d.GuidedOrder == 1)
 if d.OrderNodes < nodes or d.OrderCrystals < crystals then
  notify(p, "Commission in progress. Check the Orders tab.")
  return
 end
 d.Orders += 1
 d.Coins += reward
 d.OrderZone, d.OrderNodes, d.OrderCrystals, d.GuidedOrder = 0, 0, 0, 0
 sync(p)
 World.celebrate(anchor, 30)
 notify(p, name .. " completed • +" .. reward .. " coins", "reward")
end
local function upgrade(p, anchor) local d=profiles[p]; local nextPick=C.Picks[d.Pick+1]; if not nextPick then notify(p,"Max pickaxe!"); return end; if d.Coins<nextPick.Cost then notify(p,"Need "..nextPick.Cost.." coins"); return end; d.Coins-=nextPick.Cost; d.Pick+=1; sync(p); refreshPickaxe(p, d); World.celebrate(anchor, 18); notify(p,"Forged "..nextPick.Name.." Pickaxe", "buy") end
local function applyCollection(p, d, crate)
 if crate.Equipped == "Skin" then
  refreshPickaxe(p, d)
 else
  refreshLook(p, p.Character, d)
 end
end

local function openCrate(p, anchor, crate)
 local d = profiles[p]
 if d.Coins < crate.Cost then
  notify(p, "Need " .. crate.Cost .. " coins for the " .. crate.Name .. ".")
  return
 end

 local pool = C[crate.Pool]
 local key = crate.Pool .. "Owned"
 local standardMask = 2 ^ crate.StandardCount - 1
 if bit32.band(d[key], standardMask) == standardMask then
  notify(p, crate.Name .. " collection complete.")
  return
 end
 local roll = math.random(100)
 local index
 for candidate = 1, crate.StandardCount do
  roll -= pool[candidate].Weight
  if roll <= 0 then index = candidate; break end
 end
 if not index then return end
 local item = pool[index]
 d.Coins -= crate.Cost
 if C.owns(d[key], index) then
  local refund = math.floor(crate.Cost / 2)
  d.Coins += refund
  sync(p)
  notify(p, "Duplicate " .. item.Name .. " • " .. refund .. " coins returned", "coins")
  return
 end
 d[key] = bit32.bor(d[key], bit32.lshift(1, index - 1))
 local current = pool[d[crate.Equipped]]
 if crate.Equipped ~= "Pet" or not current or item.Bonus > current.Bonus then
  d[crate.Equipped] = index
  applyCollection(p, d, crate)
 end
 sync(p)
 World.revealCrate(anchor)
 World.celebrate(anchor, 28)
 notify(p, item.Name .. " added to your collection!", "reward")
end

equipRemote.OnServerEvent:Connect(function(p, group, index)
 local d = activeProfile(p)
 if not d or typeof(group) ~= "number" or typeof(index) ~= "number"
  or group % 1 ~= 0 or index % 1 ~= 0 or index < 0 then return end
 local crate = C.Crates[group]
 if not crate or index > #C[crate.Pool] or d[crate.Equipped] == index then return end
 local item = C[crate.Pool][index]
 if item and item.Premium then
  if not Premium.owns(p, item.Premium) then return end
 elseif index ~= 0 and not C.owns(d[crate.Pool .. "Owned"], index) then
  return
 end
 local now = os.clock()
 if now - (lastEquip[p] or -math.huge) < .35 then return end
 lastEquip[p] = now
 d[crate.Equipped] = index
 applyCollection(p, d, crate)
 sync(p)
end)
premiumRemote.OnServerEvent:Connect(function(p, action, index)
 if not activeProfile(p) or premiumBusy[p] then return end
 local now = os.clock()
 if now - (lastPremium[p] or -math.huge) < 1 then return end
 if action == "TopUp" and typeof(index) == "number" and index % 1 == 0 then
  local product = C.StarshardProducts[index]
  if not product then return end
  lastPremium[p] = now
  local ok, shown = pcall(Premium.prompt, p, product)
  if not ok or not shown then notify(p, "Robux top-ups are unavailable.") end
 elseif action == "Open" and typeof(index) == "number" and index % 1 == 0 then
  local crate = C.PremiumCrates[index]
  if not crate then return end
  lastPremium[p] = now
  premiumBusy[p] = true
  local success, message = Premium.buyCrate(p, index, crate)
  premiumBusy[p] = nil
  if p.Parent ~= Players then return end
  if success then
   notify(p, crate.Reward .. " added to your collection!", "reward")
  else
   notify(p, message)
  end
 end
end)

local function rebirth(p) local d=profiles[p]; local cost=3000*(d.Rebirths+1); if d.Coins<cost then notify(p,"Need "..cost.." coins"); return end; d.Coins=0; clearOre(d); clearVeinChain(p); d.Pick=1; d.Zone=1; d.Rebirths+=1; sync(p); refreshPickaxe(p, d); local root=p.Character and p.Character:FindFirstChild("HumanoidRootPart"); if root then root.CFrame=CFrame.new(0,5,0) end; notify(p,"Rebirth complete! Permanent sell multiplier increased.", "reward") end
local stations={{"Sell Crystals",Vector3.new(-20,2,0),Color3.fromRGB(255,190,50),sell},{"Pickaxe Forge",Vector3.new(20,2,0),Color3.fromRGB(80,160,255),upgrade},{"Rebirth",Vector3.new(20,2,15),Color3.fromRGB(170,100,255),rebirth},
 {"Guild Commissions",Vector3.new(-34,2,8),Color3.fromRGB(68,178,159),commissions},
 {"Bag Outfitters",Vector3.new(34,2,8),Color3.fromRGB(217,130,74),buyBag}}
for _, station in ipairs(stations) do
 local name, position, color, action = table.unpack(station)
 local anchor = part(name, Vector3.new(9,4,9), position, color)
 local promptText = "Interact"
 if action == upgrade then
  World.forge(world, anchor, C.Picks)
  promptText = "Forge next pickaxe"
 elseif action == commissions or action == buyBag then
  World.kiosk(world, anchor, color, action == commissions)
  promptText = action == commissions and "Accept / claim commission" or "Buy next bag"
 else
  World.station(world, anchor, color)
 end
 label(anchor, name)
 prompt(anchor, promptText, function(p) action(p, anchor) end)
end
local crateColors = {Color3.fromRGB(227,129,174), Color3.fromRGB(90,178,212), Color3.fromRGB(166,130,229)}
for group, crate in ipairs(C.Crates) do
 local color = crateColors[group]
 local anchor = part(crate.Name, Vector3.new(6,3,5), Vector3.new((group - 2) * 11,2,23), color)
 World.crateStand(world, anchor, color)
 label(anchor, crate.Name .. " • " .. crate.Cost .. " coins")
 prompt(anchor, "Open crate", function(p) openCrate(p, anchor, crate) end)
end

local function setupResonance(mine, x, color)
 local event = C.Resonance
 local chamber = World.resonance(mine, x, color)
 local status = label(chamber.Status, "")
 local entrance = part("Expedition Notice", Vector3.new(1, 1, 1), Vector3.new(x + 5, 2, -4), color, mine)
 entrance.CanCollide = false
 entrance.CanQuery = false
 entrance.Transparency = 1
 label(entrance, "Crystal Resonance\nFollow the three pulsing veins")
 local cachePrompt
 local cycle, lit = 0, 0
 local active, started = false, false
 local contributed, claimed = {}, {}

 local function showProgress()
  if active then
   status.Text = "Echo Chamber open\nExtract the deposit inside"
  else
   status.Text = "Crystal Resonance • " .. lit .. "/" .. #chamber.Veins .. "\nMine the three pulsing veins"
  end
 end

 local function reset()
  cycle += 1
  lit, active, started = 0, false, false
  contributed, claimed = {}, {}
  chamber.Gate(false)
  cachePrompt.Enabled = false
  for _, vein in ipairs(chamber.Veins) do
   vein.Health = event.Health
   vein.Cluster.Parent = mine
   vein.Prompt.Enabled = true
   vein.Pulse:Play()
  end
  showProgress()
 end

 for _, vein in ipairs(chamber.Veins) do
  vein.Prompt = prompt(vein.Anchor, "Mine resonant vein", function(p)
   local d = profiles[p]
   if d.Zone < event.Zone or active or vein.Health <= 0 or not clearShot(p, vein.Anchor) then return end
   local now = os.clock()
   if now - (last[p] or -math.huge) < .35 then return end
   last[p] = now
   contributed[p] = true
   if not started then
    started = true
    local attempt = cycle
    task.delay(event.IdleReset, function()
     if cycle == attempt and not active then reset() end
    end)
   end

   Pickaxes.swing(p)
   vein.Health -= C.Picks[d.Pick].Power
   vein.Sparks:Emit(vein.Health <= 0 and 18 or 7)
   if vein.Health > 0 then
    notify(p, "Resonant vein • " .. vein.Health .. " HP", "hit")
    return
   end
   vein.Prompt.Enabled = false
   vein.Pulse:Pause()
   vein.Lamp.Brightness = 3.4
   lit += 1
   active = lit == #chamber.Veins
   if active then
    chamber.Gate(true)
    cachePrompt.Enabled = true
    local attempt = cycle
    task.delay(event.Window, function()
     if cycle == attempt then reset() end
    end)
   end
   showProgress()
   for miner in pairs(contributed) do
    if profiles[miner] then
     local message = active and ("Echo Chamber open for " .. event.Window .. " seconds!")
      or ("Resonant veins tuned • " .. lit .. "/" .. #chamber.Veins)
     notify(miner, message, "resonance" .. lit)
    end
   end
  end, true)
 end

 cachePrompt = prompt(chamber.Cache, "Extract echo deposit", function(p)
  local d = profiles[p]
  local root = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
  if not active or d.Zone < event.Zone or not root or math.abs(root.Position.X - chamber.ChamberX) > 9.5
   or root.Position.Z > chamber.FrontZ or root.Position.Z < chamber.BackZ or not clearShot(p, chamber.Cache) then return end
  if not contributed[p] then notify(p, "Help mine a resonant vein to claim a deposit."); return end
  if claimed[p] then notify(p, "Deposit already claimed this expedition."); return end
  claimed[p] = true
  d.Coins += event.Reward
  local first = not C.owns(d.AurasOwned, event.Aura)
  if first then
   d.AurasOwned = bit32.bor(d.AurasOwned, bit32.lshift(1, event.Aura - 1))
   d.Aura = event.Aura
   refreshLook(p, p.Character, d)
  end
  sync(p)
  World.celebrate(chamber.Cache, 28)
  notify(p, "Echo deposit • +" .. event.Reward .. " coins" .. (first and " • Resonance Echo unlocked!" or ""), "reward")
 end, true)
 prompt(chamber.Exit, "Return to the mine", function(p)
  local root = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
  if root and root.Position.Z < chamber.FrontZ then root.CFrame = CFrame.new(chamber.ExitPosition) end
 end, true)
 reset()
end

local function clearRelay(p)
 relayRuns[p] = nil
 p:SetAttribute("RelayDeadline", 0)
 p:SetAttribute("RelayStop", 0)
end

local function clearTempering(p)
 emberRuns[p] = nil
 p:SetAttribute("EmberStage", 0)
 p:SetAttribute("EmberEpoch", 0)
end

local function setupWhiteout(zone, x)
 local relay = C.Whiteout
 local shelter, beacons = World.whiteout(zone, x, relay.Route)
 label(shelter, "Whiteout Relay\nStart at the shelter")
 prompt(shelter, "Start Whiteout Relay", function(p)
  if profiles[p].Zone < relay.Zone then return end
  local now = workspace:GetServerTimeNow()
  local previous = relayRuns[p]
  if previous and now < previous.Deadline then
   notify(p, "Whiteout Relay in progress. Follow your beacon marker.")
   return
  end
  if emberRuns[p] then clearTempering(p) end
  local run = { Started = now, Deadline = now + relay.Duration, Stop = 1 }
  relayRuns[p] = run
  p:SetAttribute("RelayDeadline", run.Deadline)
  p:SetAttribute("RelayStop", run.Stop)
  local best = profiles[p].RelayBestMs
  local record = best > 0 and string.format(" • Best %.1fs", best / 1000) or ""
  notify(p, "Whiteout Relay started. Reach " .. relay.Route[1].Name .. " first!" .. record, "resonance1")
  task.delay(relay.Duration, function()
   if relayRuns[p] ~= run then return end
   clearRelay(p)
   if p.Parent == Players then notify(p, "Whiteout Relay timed out. Restart at the shelter.") end
  end)
 end, true)

 for index, beacon in ipairs(beacons) do
  local stop = relay.Route[index]
  label(beacon.Anchor, stop.Name)
  prompt(beacon.Anchor, "Signal beacon", function(p)
   local run = relayRuns[p]
   local now = workspace:GetServerTimeNow()
   local d = profiles[p]
   if not run or now >= run.Deadline or d.Zone < relay.Zone then return end
   if run.Stop ~= index then
    notify(p, "Next beacon: " .. relay.Route[run.Stop].Name)
    return
   end
   beacon.Pulse:Emit(22)
   if index < #beacons then
    run.Stop += 1
    p:SetAttribute("RelayStop", run.Stop)
    notify(p, index .. "/" .. #beacons .. " lit • " .. relay.Route[run.Stop].Hint, "resonance" .. (index + 1))
    return
   end

   clearRelay(p)
   local elapsed = math.max(1, math.floor((now - run.Started) * 1000))
   local personalBest = d.RelayBestMs == 0 or elapsed < d.RelayBestMs
   if personalBest then d.RelayBestMs = elapsed end
   local first = not C.owns(d.AurasOwned, relay.Aura)
   local reward = first and relay.FirstReward or relay.RepeatReward
   if first then
    d.AurasOwned = bit32.bor(d.AurasOwned, bit32.lshift(1, relay.Aura - 1))
    d.Aura = relay.Aura
    refreshLook(p, p.Character, d)
   end
   d.Coins += reward
   sync(p)
   World.celebrate(beacon.Anchor, 28)
   local suffix = first and " • Icebound Trail unlocked!" or personalBest and " • New personal best!" or ""
   notify(p, string.format("Relay clear in %.1fs • +%d coins%s", elapsed / 1000, reward, suffix), "reward")
  end, true)
 end
end

local function setupTidekeeper(zone, x)
 local puzzle = C.Tidekeeper
 local altar, stations = World.tidekeeper(zone, x, puzzle.Dials)
 local carving = {}
 for _, dial in ipairs(puzzle.Dials) do
  carving[#carving + 1] = string.gsub(dial.Name, " Dial$", "") .. ": " .. puzzle.Symbols[dial.Answer]
 end
 label(altar, "Tidekeeper Carving\n" .. table.concat(carving, "  •  "))
 prompt(altar, "Read / offer dial settings", function(p)
  local d = profiles[p]
  if d.Zone < puzzle.Zone then return end
  if C.owns(d.AurasOwned, puzzle.Aura) then
   notify(p, "The Tidekeeper has already granted your reward.")
   return
  end
  local settings = tideRuns[p]
  if not settings then
   settings = {1, 1, 1}
   tideRuns[p] = settings
   p:SetAttribute("TideSettings", table.concat(settings))
   notify(p, "Set the three dials to match the carving, then return here.", "accept")
   return
  end
  local correct = 0
  for index, dial in ipairs(puzzle.Dials) do
   if settings[index] == dial.Answer then correct += 1 end
  end
  if correct < #puzzle.Dials then
   notify(p, correct .. "/" .. #puzzle.Dials .. " settings match. Read the carving and try again.")
   return
  end

  tideRuns[p] = nil
  p:SetAttribute("TideSettings", nil)
  d.AurasOwned = bit32.bor(d.AurasOwned, bit32.lshift(1, puzzle.Aura - 1))
  d.Aura = puzzle.Aura
  d.Coins += puzzle.Reward
  refreshLook(p, p.Character, d)
  sync(p)
  World.celebrate(altar, 38)
  notify(p, "Tidekeeper shrine aligned • +" .. puzzle.Reward .. " coins • Tideglass Halo unlocked!", "reward")
 end, true)

 for index, anchor in ipairs(stations) do
  label(anchor, puzzle.Dials[index].Name)
  prompt(anchor, "Rotate dial", function(p)
   local d = profiles[p]
   if d.Zone < puzzle.Zone or C.owns(d.AurasOwned, puzzle.Aura) then return end
   local settings = tideRuns[p]
   if not settings then
    notify(p, "Read the Tidekeeper Carving first.")
    return
   end
   settings[index] = settings[index] % #puzzle.Symbols + 1
   p:SetAttribute("TideSettings", table.concat(settings))
   World.celebrate(anchor, 7)
   notify(p, anchor.Name .. " set to " .. puzzle.Symbols[settings[index]] .. ".", "resonance" .. settings[index])
  end, true)
 end
end

local function setupEmberheart(zone, x)
 local trial = C.Emberheart
 local anvil, sparks = World.emberheart(zone, x)
 label(anvil, "Emberheart Tempering\nStrike inside the highlighted heat band")
 prompt(anvil, "Start / strike anvil", function(p)
  local d = profiles[p]
  if d.Zone < trial.Zone then return end
  local now = workspace:GetServerTimeNow()
  local run = emberRuns[p]
  if not run or now >= run.Deadline then
   if relayRuns[p] then clearRelay(p) end
   run = { Stage = 1, Started = now, Epoch = now, Deadline = now + trial.Duration, LastStrike = now }
   emberRuns[p] = run
   p:SetAttribute("EmberEpoch", run.Epoch)
   p:SetAttribute("EmberStage", run.Stage)
   local best = d.EmberBestMs > 0 and string.format(" • Best %.1fs", d.EmberBestMs / 1000) or ""
   notify(p, "Strike the anvil when the marker enters the highlighted band." .. best, "accept")
   task.delay(trial.Duration, function()
    if emberRuns[p] ~= run then return end
    clearTempering(p)
    if p.Parent == Players then notify(p, "The Emberheart cooled. Start a new attempt at the anvil.") end
   end)
   return
  end
  if now - run.LastStrike < .40 then return end
  run.LastStrike = now

  local stage = trial.Stages[run.Stage]
  local heat = C.emberHeat(now - run.Epoch, stage.Period)
  if heat < stage.Low - trial.Tolerance or heat > stage.High + trial.Tolerance then
   notify(p, "Strike missed • keep watching the heat gauge.", "hit")
   return
  end

  Pickaxes.swing(p)
  sparks:Emit(24)
  if run.Stage < #trial.Stages then
   local completed = run.Stage
   run.Stage += 1
   run.Epoch = now
   p:SetAttribute("EmberEpoch", run.Epoch)
   p:SetAttribute("EmberStage", run.Stage)
   notify(p, stage.Name .. " complete • next: " .. trial.Stages[run.Stage].Name, "resonance" .. completed)
   return
  end

  clearTempering(p)
  local elapsed = math.max(1, math.floor((now - run.Started) * 1000))
  local personalBest = d.EmberBestMs == 0 or elapsed < d.EmberBestMs
  if personalBest then d.EmberBestMs = elapsed end
  local first = not C.owns(d.AurasOwned, trial.Aura)
  if first then
   d.AurasOwned = bit32.bor(d.AurasOwned, bit32.lshift(1, trial.Aura - 1))
   d.Aura = trial.Aura
   d.Coins += trial.Reward
   refreshLook(p, p.Character, d)
  end
  sync(p)
  World.celebrate(anvil, 42)
  local reward = first and (" • +" .. trial.Reward .. " coins • Emberheart Mantle unlocked!")
   or personalBest and " • New personal best!" or ""
  notify(p, string.format("Emberheart tempered in %.1fs%s", elapsed / 1000, reward), "reward")
 end, true)
end

local function setupCavernLift(surface, deep)
 local function lift(p, target)
  local root = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
  if not root then return end
  root.CFrame = CFrame.new(target.Position + Vector3.new(0, 4.5, 0))
 end

 label(surface, "Deep Gallery Lift\nDiscover the lower station to unlock")
 prompt(surface, "Descend to Deep Gallery", function(p)
  local d = profiles[p]
  if d.Zone < C.Resonance.Zone then return end
  if d.DeepLift == 0 then
   notify(p, "Reach the lift in Deep Gallery on foot first.")
   return
  end
  lift(p, deep)
 end, true)
 label(deep, "Deep Gallery Lift\nShortcut to the mine entrance")
 prompt(deep, "Unlock / ride to entrance", function(p)
  local d = profiles[p]
  if d.Zone < C.Resonance.Zone then return end
  if d.DeepLift == 0 then
   d.DeepLift = 1
   sync(p)
   notify(p, "Deep Gallery Lift unlocked! Use it from either station.", "reward")
   World.celebrate(deep, 20)
  end
  lift(p, surface)
 end, true)
end

local appraiser = part("Geode Appraiser", Vector3.new(7, 2.8, 3.4), Vector3.new(-29, 1.9, 26),
 Color3.fromRGB(102, 135, 123))
World.geodeStand(world, appraiser, C.Zones)
label(appraiser, "Geode Appraiser\nBring a geode from any mine")
prompt(appraiser, "Appraise a geode", function(p) appraiseGeode(p, appraiser) end, true)

local compassStand = part("Geode Compass", Vector3.new(4.2, 2.2, 2.5), Vector3.new(-37, 1.65, 33),
 Color3.fromRGB(124, 113, 91))
World.compassStand(world, compassStand)
label(compassStand, "Geode Compass • " .. C.GeodeCompass.Cost .. " coins\nLonger vein-chain timer")
prompt(compassStand, "Buy Geode Compass", function(p) buyCompass(p, compassStand) end, true)

local workbench = part("Surveyor’s Workbench", Vector3.new(6.3, 2.7, 3.2), Vector3.new(34, 1.85, -1.5),
 Color3.fromRGB(166, 117, 205))
World.surveyorWorkbench(world, workbench)
label(workbench, "Surveyor’s Workbench\nLantern • " .. C.SurveyorLantern.Cost .. " Amethyst")
prompt(workbench, "Set aside Amethyst / craft", function(p) craftLantern(p, workbench) end, true)

local ledger = part("Cave Ledger", Vector3.new(5, 3.4, 2.5), Vector3.new(8.5, 2.2, 31), Color3.fromRGB(106, 148, 169))
ledger.Material = Enum.Material.Slate
label(ledger, "Cave Ledger\nMaster mines for permanent bonuses")
prompt(ledger, "Read cave progress", function(p)
 notify(p, nil, "caves")
end, true)

local display, revealHeartstone = World.heartstoneDisplay(world, Vector3.new(24, 1.7, 28))
local trophyCaption = label(display, "Heartstone Trophy\nEarned in the Master Expedition")
local function showHeartstone(p)
 revealHeartstone()
 trophyCaption.Text = "Heartstone Trophy\nOn display from " .. p.DisplayName
end
prompt(display, "Display your Heartstone trophy", function(p)
 if profiles[p].HeartstoneTrophy == 1 then
  showHeartstone(p)
  notify(p, "Your Heartstone trophy is on display in Meadow.", "reward")
 else
  notify(p, "Clear Heartstone Descent in Amethyst Cavern to earn this display.")
 end
end, true)

local function setupMasterExpedition(mine, x)
 local config = C.MasterExpedition
 local room = World.masterExpedition(mine, x)
 local joiningTeam
 local function eligible(d)
  return d and d.Zone >= config.Zone
   and C.caveRank(config.Zone, d["CaveNodes" .. config.Zone], d.Discoveries, d.AurasOwned) == 2
 end
 local function teleport(p, point)
  local root = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
  if root then root.CFrame = CFrame.new(point) end
 end
 local function finish(p, run, returnToGallery)
  if descentRuns[p] ~= run then return end
  descentRuns[p], run.Team.Members[p] = nil, nil
  p:SetAttribute("DescentStage", 0)
  p:SetAttribute("DescentDeadline", 0)
  p:SetAttribute("DescentCount", 0)
  if returnToGallery and p.Parent == Players then
   local root = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
   if root and root.Position.Z <= -94 and root.Position.Z >= -160 and math.abs(root.Position.X - x) <= 34 then
    teleport(p, room.Return)
   end
  end
 end
 local function getRun(p)
  local run = descentRuns[p]
  if not run or not eligible(profiles[p]) then return nil end
  if workspace:GetServerTimeNow() >= (run.Deep and run.Team.DeepDeadline or run.Team.SurveyDeadline) then return nil end
  return run
 end
 local function update(team)
  for p, run in pairs(team.Members) do
   local count = run.Deep and team.DeepCount or team.SurveyCount
   local contributed = run.Deep and run.DeepContributed or not run.Deep and run.SurveyContributed
   local stage = run.Deep and 3 or 1
   if contributed and count == 2 then stage += 1 end
   p:SetAttribute("DescentStage", stage)
   p:SetAttribute("DescentCount", count)
   p:SetAttribute("DescentDeadline", run.Deep and team.DeepDeadline or team.SurveyDeadline)
  end
 end

 label(room.Entry, "Heartstone Descent\nAmethyst Master rank required")
 prompt(room.Entry, "Enter Master Expedition", function(p)
  if not eligible(profiles[p]) then notify(p, "Master Amethyst Cavern to open Heartstone Descent."); return end
  local now = workspace:GetServerTimeNow()
  if descentRuns[p] then finish(p, descentRuns[p], false) end
  if not joiningTeam or now >= joiningTeam.JoinUntil or joiningTeam.DeepDeadline or not next(joiningTeam.Members) then
   joiningTeam = { JoinUntil = now + config.JoinWindow, SurveyDeadline = now + config.SurveyWindow,
    SurveyCount = 0, DeepCount = 0, SurveyMarks = {}, DeepMarks = {}, Members = {} }
  end
  local team = joiningTeam
  local run = { Team = team, Deep = false }
  descentRuns[p], team.Members[p] = run, run
  teleport(p, room.Start)
  update(team)
  notify(p, "Survey both amber stakes. Friends entering now can split the work.", "accept")
  task.delay(math.max(0, team.SurveyDeadline - now), function()
   if descentRuns[p] == run and not run.Deep then
    finish(p, run, true)
    if p.Parent == Players then notify(p, "Survey time expired. Your regular haul is safe.") end
   end
  end)
 end, true)

 local function marks(anchors, deep)
  for index, anchor in ipairs(anchors) do
   label(anchor, anchor.Name)
   prompt(anchor, deep and "Extract heartstone seam" or "Log survey stake", function(p)
    local run = getRun(p)
    if not run or run.Deep ~= deep then return end
    local team = run.Team
    local visited = deep and team.DeepMarks or team.SurveyMarks
    if deep then run.DeepContributed = true else run.SurveyContributed = true end
    if not visited[index] then
     visited[index] = true
     if deep then team.DeepCount += 1 else team.SurveyCount += 1 end
     World.celebrate(anchor, 12)
    end
    update(team)
    local count = deep and team.DeepCount or team.SurveyCount
    notify(p, (deep and "Heartstone seams" or "Survey stakes") .. " • " .. count .. "/2", "accept")
   end, true)
  end
 end
 marks(room.Survey, false)
 marks(room.Deep, true)

 label(room.Bank, "Bank the haul\nSafe payout • return to the gallery")
 prompt(room.Bank, "Bank haul", function(p)
  local run = getRun(p)
  if not run or run.Deep then return end
  if run.Team.SurveyCount < 2 or not run.SurveyContributed then
   notify(p, "Log a stake and complete the team survey first.")
   return
  end
  local d = profiles[p]
  local reward = d.MasterBanked == 0 and config.BankFirst or config.BankRepeat
  d.MasterBanked = 1
  d.Coins += reward
  finish(p, run, true)
  sync(p)
  notify(p, "Survey haul banked • +" .. reward .. " coins", "coins")
 end, true)

 label(room.Press, "Press on\nRisk the survey haul for Heartstone")
 prompt(room.Press, "Risk haul / descend", function(p)
  local run = getRun(p)
  if not run or run.Deep then return end
  local team = run.Team
  if team.SurveyCount < 2 or not run.SurveyContributed then
   notify(p, "Log a stake and complete the team survey first.")
   return
  end
  local now = workspace:GetServerTimeNow()
  if team.DeepDeadline and now >= team.DeepDeadline then
   notify(p, "Your team’s deep window closed. You can still bank the survey haul.")
   return
  end
  team.DeepDeadline = team.DeepDeadline or now + config.DeepWindow
  run.Deep = true
  update(team)
  notify(p, "Extract both violet seams, then claim the cache before time runs out.", "resonance2")
  task.delay(team.DeepDeadline - now, function()
   if descentRuns[p] ~= run then return end
   finish(p, run, true)
   if p.Parent == Players then notify(p, "The deep haul was lost. Your regular ore and coins are safe.") end
  end)
 end, true)

 label(room.Cache, "Heartstone Cache")
 prompt(room.Cache, "Claim Heartstone", function(p)
  local run = getRun(p)
  if not run or not run.Deep then return end
  if run.Team.DeepCount < 2 or not run.DeepContributed then
   notify(p, "Extract a seam and complete both team objectives first.")
   return
  end
  local d = profiles[p]
  local first = d.HeartstoneTrophy == 0
  local reward = first and config.DeepFirst or config.DeepRepeat
  d.Coins += reward
  if first then d.HeartstoneTrophy = 1; showHeartstone(p) end
  finish(p, run, true)
  sync(p)
  notify(p, "Heartstone haul • +" .. reward .. " coins" .. (first and " • Trophy on display in Meadow!" or ""), "reward")
 end, true)

 for _, exit in ipairs(room.Exits) do
  label(exit, exit.Name)
  prompt(exit, "Exit expedition", function(p)
   local run = descentRuns[p]
   if run then finish(p, run, false) end
   teleport(p, room.Return)
  end, true)
 end
end

local conversations = {}
local function resident(parent, name, role, position, yaw, coat, scarf, linesFor)
 local anchor = World.resident(parent, name, position, yaw, coat, scarf)
 local caption = label(anchor, name .. " • " .. role)
 caption.Parent.MaxDistance = 24
 caption.Parent.Size = UDim2.fromOffset(130, 27)
 caption.Parent.StudsOffset = Vector3.new(0, 2.4, 0)
 local talk = prompt(anchor, "Talk to " .. name, function(p)
  local lines = linesFor(profiles[p])
  local visits = conversations[p]
  if not visits then visits = {}; conversations[p] = visits end
  local line = (visits[name] or 0) % #lines + 1
  visits[name] = line
  remote:FireClient(p, lines[line], "dialogue", name, role)
 end, true)
 talk.MaxActivationDistance = 8
 talk.ObjectText = name
end

World.welcome(world)
World.meadowLandmarks(world)
resident(world, "Fern", "Trail Steward", Vector3.new(-9.3, .5, 3.3), .25, Color3.fromRGB(72, 127, 105),
 Color3.fromRGB(255, 194, 112), function(d)
  if d.Orders == 0 then
   return {
    "Welcome to Meadow! The guild has a first haul with your name on it. Follow the trail marker and they’ll get you started.",
    "Equip your pickaxe and aim at a crystal to swing, or use the Mine prompt. My first one bounced right out of my hands.",
   }
  end
  return {
   "There’s a bench by the fountain if you need a breather. The mountain will still be there when you’re ready.",
   "The wayshrines light up the road out of Meadow. Amethyst Cavern is the first stop.",
  }
 end)
resident(world, "Marlow", "Surveyor", Vector3.new(38.5, .5, -2), -1.15, Color3.fromRGB(115, 85, 147),
 Color3.fromRGB(234, 179, 110), function(d)
  if d.SurveyorLantern == 1 then
   return {
    "That lantern suits you. Look for its rich-vein marker when the cave walls start looking alike.",
    "Bring your best finds home. The forge likes a good story almost as much as it likes a good crystal.",
   }
  end
  return {
   "Twenty-four Amethyst and I can build you a lantern that spots rich veins. Set a little aside now and sell the rest.",
   "The trick isn’t finding a crystal. It’s remembering why you came down here before the next one catches your eye.",
  }
 end)


for i,z in ipairs(C.Zones) do
 local x=(i-1)*140
 local zone=World.zone(world,i,z,x)
 local mine
 if i == C.Resonance.Zone then
  local surface, deep
  mine, surface, deep = World.cavern(zone, x, C.CavernRoutes)
  setupCavernLift(surface, deep)
  setupMasterExpedition(mine, x)
  setupResonance(mine, x, z.Color)
  resident(zone, "Iona", "Lampkeeper", Vector3.new(x + 5, .5, 3), -.44, Color3.fromRGB(75, 79, 140),
   Color3.fromRGB(191, 147, 248), function(d)
    if C.owns(d.AurasOwned, C.Resonance.Aura) then
     return {
      "You heard the chamber answer! My old crew tried singing to it. Three pickaxe strikes make a better choir.",
      "If you find the lift at the back of Deep Gallery, it’ll save your legs on the way home.",
     }
    end
    return {
     "Amber lanterns lead to a quick haul. Violet ones lead to the singing veins, if you’re in the mood for a detour.",
     "Listen for three rising notes. Tune the pulsing veins in Echo Tunnels and the old chamber will open.",
    }
   end)
 else
  mine = World.mine(zone, z, i, x)
 end
 if i == C.Whiteout.Zone then
  setupWhiteout(zone, x)
 elseif i == C.Tidekeeper.Zone then
  setupTidekeeper(zone, x)
 elseif i == C.Emberheart.Zone then
  setupEmberheart(zone, x)
 elseif i ~= C.Resonance.Zone then
  local sign = part(z.Name .. " Sign", Vector3.new(12,3,2), Vector3.new(x,3,-36), z.Color, zone)
  label(sign,z.Name)
 end
 if i > 1 then
  local gateX = (i - (#C.Zones + 2) / 2) * 22
  local gate = part("Travel to " .. z.Name, Vector3.new(8, 4, 8), Vector3.new(gateX, 1, 38), z.Color)
  World.portal(world, gate, z.Color)
  label(gate, z.Name .. " • " .. z.Cost .. " coins")
  prompt(gate, "Unlock / travel", function(p)
   local d = profiles[p]
   if d.Zone < i then
    if d.Zone ~= i - 1 then
     notify(p, "Unlock " .. C.Zones[i - 1].Name .. " first.")
     return
    end
    if d.Coins < z.Cost then
     notify(p, "Need " .. z.Cost .. " coins to unlock " .. z.Name .. ".")
     return
    end
    d.Coins -= z.Cost
    d.Zone = i
    sync(p)
   end
   local root = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
   if root then root.CFrame = CFrame.new(x, 5, 0) end
  end)

  local back = part("Return to Meadow", Vector3.new(8, 3, 8), Vector3.new(x, 1, 10), Color3.fromRGB(255, 200, 80), zone)
  World.portal(zone, back, back.Color)
  label(back, "Return to Meadow")
  prompt(back, "Travel", function(p)
   local root = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
   if root then root.CFrame = CFrame.new(0, 5, 0) end
  end)
 end

 local landmark = World.landmark(zone, z, x, i)
 label(landmark, z.Landmark)
 local discoveryBit = bit32.lshift(1, i - 1)
 prompt(landmark, "Survey", function(p)
  local d = profiles[p]
  if d.Zone < i or (i == C.Resonance.Zone and not clearShot(p, landmark)) then return end
  if bit32.band(d.Discoveries, discoveryBit) ~= 0 then
   notify(p, "Already surveyed " .. z.Landmark .. ".")
   return
  end
  d.Discoveries = bit32.bor(d.Discoveries, discoveryBit)
  d.Coins += z.DiscoveryReward
  local surveyed = 0
  for index = 1, #C.Zones do
   if bit32.btest(d.Discoveries, bit32.lshift(1, index - 1)) then surveyed += 1 end
  end
  sync(p)
  notify(p, z.Landmark .. " surveyed! +" .. z.DiscoveryReward .. " coins • " .. surveyed .. "/" .. #C.Zones, "reward")
 end, i == C.Resonance.Zone)

 local nodes = {}
 if i == C.Resonance.Zone then
  for _, route in ipairs(C.CavernRoutes) do
   for _, position in ipairs(route.Nodes) do
    nodes[#nodes + 1] = { X = position[1], Z = position[2], Ore = route }
   end
  end
 else
  for j = 1, 12 do
   nodes[j] = { X = ((j - 1) % 6 - 2.5) * 13, Z = -14 - math.floor((j - 1) / 6) * 12, Ore = z }
  end
 end

 for j, node in ipairs(nodes) do
  local ore = node.Ore
  local name = ore.Name .. " Crystal"
  local a = part("Crystal", Vector3.new(3.2, 5.4, 3.2), Vector3.new(x + node.X, 3.3, node.Z), ore.Color, mine)
  a.Transparency = 1
  a.CastShadow = false
  local cluster, glints = World.outcrop(mine, a, ore.Color, j)
  local orePivot = cluster:GetPivot()
  local rich
  local vein
  local function setRich(enabled)
   rich = enabled
   if vein then vein:Destroy(); vein = nil end
   if not rich then
    CollectionService:RemoveTag(a, "SurveyorRichOre")
    return
   end
   CollectionService:AddTag(a, "SurveyorRichOre")
   vein = Instance.new("Highlight")
   vein.Name = "Rich Vein"
   vein.DepthMode = Enum.HighlightDepthMode.Occluded
   vein.FillColor = Color3.fromRGB(255, 191, 74)
   vein.OutlineColor = Color3.fromRGB(255, 232, 162)
   vein.FillTransparency = .72
   vein.OutlineTransparency = .22
   vein.Parent = cluster
  end
  local startsRich = (j + i) % 7 == 0
  if ore.RichEvery then startsRich = math.random(ore.RichEvery) == 1 end
  setRich(startsRich)
  local function oreText(hp)
   return (rich and "Rich " or "") .. name .. "\n" .. hp .. " HP"
  end
  local hp = ore.Health
  local busy = false
  local caption = label(a, oreText(hp))
  caption.Parent.MaxDistance = 17
  local minePrompt
  local function strikeOre(p)
   local d = activeProfile(p)
   if not d or busy or d.Zone < i or not close(p, a, 14) then return end
   local now = os.clock()
   if now - (last[p] or 0) < .35 then return end

   if not clearShot(p, a) then return end

   last[p] = now
   local cap = capacity(d)
   if d.Crystals >= cap then notify(p, "Bag full! Sell your crystals."); return end
   Pickaxes.swing(p)
   hp -= C.Picks[d.Pick].Power
   World.oreStrike(cluster, orePivot, glints, hp <= 0)
   if hp > 0 then
    caption.Text = oreText(hp)
    notify(p, nil, "hit")
    return
   end
   local bonus = d.Pet > 0 and C.Pets[d.Pet].Bonus or 0
   local before = d.Crystals
   local caveKey = "CaveNodes" .. i
   local mined = d[caveKey]
   local previousRank = C.caveRank(i, mined, d.Discoveries, d.AurasOwned)
   d[caveKey] = math.min(C.CaveMastery[i].Master, mined + 1)
   local newRank, caveBonus = C.caveRank(i, d[caveKey], d.Discoveries, d.AurasOwned)
   d.Crystals = math.min(cap, d.Crystals + ore.Value * (rich and 2 or 1) + bonus + caveBonus)
   local oreKey = C.oreKey(i)
   d[oreKey] += d.Crystals - before
   local geodeEarned = recordVein(p, d, i, j)
   if d.OrderZone == i then
    local _, target = C.commission(d.Orders, d.OrderZone, d.GuidedOrder == 1)
    d.OrderNodes = math.min(target, d.OrderNodes + 1)
   end
   sync(p)
   if geodeEarned then
    notify(p, z.Name .. " geode found! Bring it to the Meadow appraiser.", "reward")
   elseif newRank > previousRank then
    local title = newRank == 2 and "Master" or "Prospector"
    notify(p, z.Name .. " • " .. title .. " • +" .. caveBonus .. " crystals per node here", "reward")
   else
    notify(p, rich and ("Rich vein • +" .. (d.Crystals - before) .. " crystals") or nil, rich and "reward" or "break")
   end
   busy = true
   minePrompt.Enabled = false
   a.CanCollide = false
   a.CanQuery = false
   CollectionService:RemoveTag(a, "MineableOre")
   caption.Visible = false
   CollectionService:RemoveTag(a, "SurveyorRichOre")
   task.delay(3, function()
    if not a:IsDescendantOf(workspace) then
     cluster:Destroy()
     return
    end
    cluster:ScaleTo(.35)
    cluster.Parent = mine
    for _, scale in ipairs({.60, .82, 1}) do
     task.wait(.07)
     if not a:IsDescendantOf(workspace) then
      cluster:Destroy()
      return
     end
     cluster:ScaleTo(scale)
    end
    hp = ore.Health
    setRich(math.random(ore.RichEvery or 8) == 1)
    caption.Text = oreText(hp)
    caption.Visible = true
    a.CanQuery = true
    a.CanCollide = true
    CollectionService:AddTag(a, "MineableOre")
    busy = false
    minePrompt.Enabled = true
   end)
  end
  oreActions[a] = strikeOre
  CollectionService:AddTag(a, "MineableOre")
  minePrompt = prompt(a, "Mine", strikeOre, true)
 end
end

mineRemote.OnServerEvent:Connect(function(p, target)
 if typeof(target) ~= "Instance" then return end
 local strikeOre = oreActions[target]
 if not strikeOre then return end
 local character = p.Character
 local tool = character and character:FindFirstChildOfClass("Tool")
 if tool and tool:GetAttribute("MiningPickaxe") == true then
  strikeOre(p)
 end
end)

-- Build the playable world before attempting to initialize persistence.
local storeAvailable, result = pcall(function()
    return DSS:GetDataStore("CrystalMining_v1")
end)
if storeAvailable then
    store = SessionStore.new(result)
else
    warn("Could not initialize CrystalMining_v1:", result)
end

Premium.start(C.StarshardProducts)
local function remove(p)
 if loading[p] then loading[p].Cancelled = true end
 if departing[p] then return end
 local profile, session = profiles[p], sessions[p]
 if not profile then return end
 departing[p] = true
 profiles[p], sessions[p] = nil, nil
 last[p], lastEquip[p], conversations[p] = nil, nil, nil
 premiumBusy[p], lastPremium[p] = nil, nil
 relayRuns[p], tideRuns[p], emberRuns[p], veinChains[p] = nil, nil, nil, nil
 local descent = descentRuns[p]
 if descent then
  descent.Team.Members[p], descentRuns[p] = nil, nil
 end
 Premium.forget(p)
 releaseSession(p, session, table.clone(profile))
 departing[p] = nil
end

Players.PlayerAdded:Connect(add)
Players.PlayerRemoving:Connect(remove)
for _, p in ipairs(Players:GetPlayers()) do task.spawn(add, p) end

task.spawn(function()
 local untilSave = 0
 while task.wait(5) and not closing do
  local now = os.time()
  local saveDue = now >= untilSave
  if saveDue then untilSave = now + 45 end
  for p, session in pairs(sessions) do
   if session.ExpiresAt <= now then
    if p.Parent == Players then p:Kick("Your mining save session expired. Please rejoin.") end
   elseif saveDue then
    task.spawn(autosave, p)
   end
  end
 end
end)

game:BindToClose(function()
 closing = true
 local deadline = os.clock() + 24
 local players = {}
 for p in pairs(profiles) do players[#players + 1] = p end
 for _, p in ipairs(players) do task.spawn(remove, p) end
 while (next(departing) or next(loading)) and os.clock() < deadline do task.wait() end
end)
