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
