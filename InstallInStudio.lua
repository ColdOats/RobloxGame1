-- Run once in Roblox Studio Command Bar in Edit mode.
local function install(parent,name,class,source)
 local old=parent:FindFirstChild(name); if old then old:Destroy() end
 local obj=Instance.new(class); obj.Name=name; obj.Source=source; obj.Parent=parent
end
install(game:GetService("ReplicatedStorage"),"MiningConfig","ModuleScript",[====[
return {
 Zones = {{Name="Meadow",Cost=0,Color=Color3.fromRGB(53,220,190),Value=2,Health=3},{Name="Amethyst Cavern",Cost=250,Color=Color3.fromRGB(161,85,255),Value=8,Health=6},{Name="Frozen Peaks",Cost=1500,Color=Color3.fromRGB(91,175,255),Value=25,Health=10}},
 Picks={{Name="Starter",Cost=0,Power=1},{Name="Iron",Cost=60,Power=2},{Name="Steel",Cost=250,Power=4},{Name="Crystal",Cost=1000,Power=8}},
 Pets={{Name="Pebble Pup",Weight=65,Bonus=1},{Name="Gem Fox",Weight=28,Bonus=3},{Name="Crystal Dragon",Weight=7,Bonus=8}}, EggCost=100,
}
]====])
install(game:GetService("ServerScriptService"),"MiningServer","Script",[====[
local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local DSS=game:GetService("DataStoreService")
local C=require(RS:WaitForChild("MiningConfig"))
local store=DSS:GetDataStore("CrystalMining_v1")
local remote=Instance.new("RemoteEvent"); remote.Name="MiningAction"; remote.Parent=RS
local profiles, ready, last, saving = {}, {}, {}, {}
local function fresh() return {Coins=0,Crystals=0,Pick=1,Zone=1,Pet=0,Rebirths=0} end
local function sync(p)
 local d=profiles[p]; if not d then return end
 for k,v in pairs(d) do p:SetAttribute(k,v) end
 p:SetAttribute("Capacity",50+d.Rebirths*25)
 local stats=p:FindFirstChild("leaderstats"); if stats then stats.Coins.Value=d.Coins; stats.Rebirths.Value=d.Rebirths end
end
local function notify(p,s) remote:FireClient(p,s) end
local function save(p)
 if not ready[p] or not profiles[p] or saving[p] then return end
 saving[p]=true; local snapshot=table.clone(profiles[p]); local ok,err=pcall(function() store:SetAsync(tostring(p.UserId),snapshot) end); saving[p]=nil
 if not ok then warn("Save failed",p.UserId,err) end
end
local function add(p)
 if profiles[p] then return end
 local ok,data=pcall(function() return store:GetAsync(tostring(p.UserId)) end)
 if not p.Parent then return end
 if not ok and not game:GetService("RunService"):IsStudio() then p:Kick("Data could not load. Please rejoin."); return end
 local d=fresh(); if ok and type(data)=="table" then for k,v in pairs(d) do if type(data[k])=="number" and data[k]>=0 and data[k]<1e12 then d[k]=math.floor(data[k]) end end end
 d.Pick=math.clamp(d.Pick,1,#C.Picks); d.Zone=math.clamp(d.Zone,1,#C.Zones); d.Pet=math.clamp(d.Pet,0,#C.Pets)
 profiles[p]=d; ready[p]=ok
 local f=Instance.new("Folder"); f.Name="leaderstats"; f.Parent=p
 for _,k in ipairs({"Coins","Rebirths"}) do local n=Instance.new("IntValue"); n.Name=k; n.Parent=f end
 sync(p)
 if not ok then task.delay(3,function() if p.Parent then notify(p,"Studio test: saving disabled") end end) end
end
Players.PlayerAdded:Connect(add); for _,p in ipairs(Players:GetPlayers()) do task.spawn(add,p) end
Players.PlayerRemoving:Connect(function(p) save(p); profiles[p]=nil; ready[p]=nil; last[p]=nil end)
task.spawn(function() while task.wait(60) do for p in pairs(profiles) do task.spawn(save,p) end end end)
game:BindToClose(function() local pending=0; for p in pairs(profiles) do pending+=1; task.spawn(function() save(p); pending-=1 end) end; while pending>0 do task.wait() end end)
local world=Instance.new("Folder"); world.Name="CrystalWorld"; world.Parent=workspace
local function part(name,size,pos,color,parent)
 local a=Instance.new("Part"); a.Name=name; a.Size=size; a.Position=pos; a.Color=color; a.Anchored=true; a.Material=Enum.Material.SmoothPlastic; a.Parent=parent or world; return a
end
local function label(p,txt)
 local g=Instance.new("BillboardGui"); g.Size=UDim2.fromOffset(220,65); g.StudsOffset=Vector3.new(0,4,0); g.AlwaysOnTop=true; g.MaxDistance=65; g.Parent=p
 local t=Instance.new("TextLabel"); t.Size=UDim2.fromScale(1,1); t.BackgroundTransparency=1; t.Text=txt; t.TextColor3=Color3.new(1,1,1); t.TextStrokeTransparency=.2; t.TextScaled=true; t.Font=Enum.Font.GothamBold; t.Parent=g; return t
end
local function close(p,a,dist) local root=p.Character and p.Character:FindFirstChild("HumanoidRootPart"); return root and (root.Position-a.Position).Magnitude<=dist end
local function prompt(a,txt,fn)
 local q=Instance.new("ProximityPrompt"); q.ActionText=txt; q.ObjectText=a.Name; q.MaxActivationDistance=12; q.RequiresLineOfSight=false; q.Parent=a
 q.Triggered:Connect(function(p) if profiles[p] and close(p,a,15) then fn(p) end end)
end
local function sell(p) local d=profiles[p]; if d.Crystals==0 then notify(p,"Your bag is empty!"); return end; local n=d.Crystals*(1+d.Rebirths); d.Coins+=n; d.Crystals=0; sync(p); notify(p,"Sold for "..n.." coins!") end
local function upgrade(p) local d=profiles[p]; local nextPick=C.Picks[d.Pick+1]; if not nextPick then notify(p,"Max pickaxe!"); return end; if d.Coins<nextPick.Cost then notify(p,"Need "..nextPick.Cost.." coins"); return end; d.Coins-=nextPick.Cost; d.Pick+=1; sync(p); notify(p,"Unlocked "..nextPick.Name) end
local function egg(p) local d=profiles[p]; if d.Coins<C.EggCost then notify(p,"Need 100 coins"); return end; d.Coins-=C.EggCost; local roll=math.random(100); local sum=0; for i,v in ipairs(C.Pets) do sum+=v.Weight; if roll<=sum then d.Pet=math.max(d.Pet,i); notify(p,"Hatched "..v.Name.."! Best pet auto-equipped."); break end end; sync(p) end
local function rebirth(p) local d=profiles[p]; local cost=3000*(d.Rebirths+1); if d.Coins<cost then notify(p,"Need "..cost.." coins"); return end; d.Coins=0; d.Crystals=0; d.Pick=1; d.Zone=1; d.Rebirths+=1; sync(p); local root=p.Character and p.Character:FindFirstChild("HumanoidRootPart"); if root then root.CFrame=CFrame.new(0,5,0) end; notify(p,"Rebirth complete! Permanent sell multiplier increased.") end
local spawn=Instance.new("SpawnLocation"); spawn.Name="Mining Spawn"; spawn.Size=Vector3.new(8,1,8); spawn.Position=Vector3.new(0,1,0); spawn.Anchored=true; spawn.Neutral=true; spawn.Parent=world
local stations={{"Sell Crystals",Vector3.new(-20,2,0),Color3.fromRGB(255,190,50),sell},{"Pickaxe Shop",Vector3.new(20,2,0),Color3.fromRGB(80,160,255),upgrade},{"Pet Egg • 100 Coins",Vector3.new(-20,2,15),Color3.fromRGB(240,100,180),egg},{"Rebirth",Vector3.new(20,2,15),Color3.fromRGB(170,100,255),rebirth}}
for _,s in ipairs(stations) do local a=part(s[1],Vector3.new(9,4,9),s[2],s[3]); label(a,s[1]); prompt(a,"Interact",s[4]) end
for i,z in ipairs(C.Zones) do
 local x=(i-1)*140
 part(z.Name,Vector3.new(110,1,100),Vector3.new(x,0,0),z.Color:Lerp(Color3.fromRGB(35,45,65),.7))
 local sign=part(z.Name.." Sign",Vector3.new(12,3,2),Vector3.new(x,3,-35),z.Color); label(sign,z.Name)
 if i>1 then local gate=part("Travel to "..z.Name,Vector3.new(8,4,8),Vector3.new(0,2,22+i*10),z.Color); label(gate,z.Name.." • "..z.Cost.." coins"); prompt(gate,"Unlock / travel",function(p) local d=profiles[p]; if d.Zone<i then if d.Zone~=i-1 or d.Coins<z.Cost then notify(p,"Unlock previous zone and earn "..z.Cost.." coins"); return end; d.Coins-=z.Cost; d.Zone=i; sync(p) end; local r=p.Character and p.Character:FindFirstChild("HumanoidRootPart"); if r then r.CFrame=CFrame.new(x,5,0) end end)
 local back=part("Return to Meadow",Vector3.new(8,3,8),Vector3.new(x,2,10),Color3.fromRGB(255,200,80)); label(back,"Return to Meadow"); prompt(back,"Travel",function(p) local r=p.Character and p.Character:FindFirstChild("HumanoidRootPart"); if r then r.CFrame=CFrame.new(0,5,0) end end) end
 for j=1,12 do
  local px=x+((j-1)%6-2.5)*13; local pz=-14-math.floor((j-1)/6)*12
  local a=part("Crystal",Vector3.new(4,6,4),Vector3.new(px,3.5,pz),z.Color); a.Material=Enum.Material.Neon; a.Orientation=Vector3.new(0,j*17,12); local hp=z.Health; local busy=false; local t=label(a,z.Name.." Crystal\n"..hp.." HP")
  prompt(a,"Mine",function(p) local d=profiles[p]; if busy or d.Zone<i then return end; local now=os.clock(); if now-(last[p] or 0)<.35 then return end; last[p]=now; local cap=50+d.Rebirths*25; if d.Crystals>=cap then notify(p,"Bag full! Sell your crystals."); return end
   hp-=C.Picks[d.Pick].Power; if hp>0 then t.Text=z.Name.." Crystal\n"..hp.." HP"; return end
   local bonus=d.Pet>0 and C.Pets[d.Pet].Bonus or 0; d.Crystals=math.min(cap,d.Crystals+z.Value+bonus); sync(p); busy=true; a.Transparency=1; a.CanCollide=false; t.Visible=false
  end)
  -- Respawn is managed independently so a depleted node cannot reward twice.
  task.spawn(function() while a.Parent do task.wait(.2); if busy then local q=a:FindFirstChildOfClass("ProximityPrompt"); q.Enabled=false; t.Visible=false; task.wait(3); hp=z.Health; a.Transparency=0; a.CanCollide=true; t.Text=z.Name.." Crystal\n"..hp.." HP"; t.Visible=true; q.Enabled=true; busy=false end end end)
 end
end
]====])
install(game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts"),"MiningClient","LocalScript",[====[
local p=game:GetService("Players").LocalPlayer
local RS=game:GetService("ReplicatedStorage")
local C=require(RS:WaitForChild("MiningConfig"))
local gui=Instance.new("ScreenGui"); gui.Name="MiningHUD"; gui.ResetOnSpawn=false; gui.Parent=p:WaitForChild("PlayerGui")
local panel=Instance.new("Frame"); panel.Size=UDim2.fromOffset(260,190); panel.Position=UDim2.fromOffset(16,65); panel.BackgroundColor3=Color3.fromRGB(23,32,48); panel.BackgroundTransparency=.08; panel.Parent=gui
local corner=Instance.new("UICorner"); corner.CornerRadius=UDim.new(0,14); corner.Parent=panel
local function text(parent,y,h,sz,color) local t=Instance.new("TextLabel"); t.Position=UDim2.new(0,12,0,y); t.Size=UDim2.new(1,-24,0,h); t.BackgroundTransparency=1; t.TextColor3=color; t.Font=Enum.Font.GothamBold; t.TextSize=sz; t.TextXAlignment=Enum.TextXAlignment.Left; t.Parent=parent; return t end
local title=text(panel,8,28,18,Color3.fromRGB(92,240,206)); title.Text="CRYSTAL MINING"
local stats=text(panel,40,140,16,Color3.new(1,1,1)); stats.TextYAlignment=Enum.TextYAlignment.Top
local hint=Instance.new("TextLabel"); hint.AnchorPoint=Vector2.new(.5,1); hint.Position=UDim2.new(.5,0,1,-24); hint.Size=UDim2.new(.9,0,0,55); hint.BackgroundColor3=Color3.fromRGB(23,32,48); hint.BackgroundTransparency=.15; hint.TextColor3=Color3.new(1,1,1); hint.TextScaled=true; hint.TextWrapped=true; hint.Font=Enum.Font.GothamBold; hint.Text="Approach a crystal and use Mine. Sell at the gold station."; hint.Parent=gui
local limit=Instance.new("UITextSizeConstraint"); limit.MaxTextSize=18; limit.Parent=hint
local function refresh() local function a(k) return p:GetAttribute(k) or 0 end; local pick=C.Picks[a("Pick")] or C.Picks[1]; local pet=C.Pets[a("Pet")]; stats.Text=string.format("Coins: %d\nCrystals: %d / %d\nPickaxe: %s\nPet: %s\nRebirths: %d",a("Coins"),a("Crystals"),a("Capacity"),pick.Name,pet and pet.Name or "None",a("Rebirths")) end
for _,k in ipairs({"Coins","Crystals","Capacity","Pick","Pet","Rebirths"}) do p:GetAttributeChangedSignal(k):Connect(refresh) end; refresh()
local version=0; RS:WaitForChild("MiningAction").OnClientEvent:Connect(function(msg) version+=1; local v=version; hint.Text=msg; task.delay(4,function() if v==version then hint.Text="Mine crystals • Sell • Upgrade • Explore" end end) end)
]====])
print("Crystal Mining Simulator installed. Press Play to test.")