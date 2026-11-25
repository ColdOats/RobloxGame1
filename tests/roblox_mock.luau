-- Headless runtime for server smoke checks. Rendering, device input and Roblox networking
-- still need to be exercised in Studio.
local actualTypeof = typeof
local function typeof(value)
    return type(value) == "table" and rawget(value, "_class") and "Instance" or actualTypeof(value)
end
local now = 1000
local queue = {}
local os = { clock = function() return now end, time = function() return math.floor(now) end }
local task = {}
local function schedule(at, thread, args)
    table.insert(queue, { At = at, Thread = thread, Args = args })
end
function task.delay(delay, fn, ...)
    schedule(now + delay, coroutine.create(fn), table.pack(...))
end
function task.spawn(fn, ...)
    task.delay(0, fn, ...)
end
task.defer = task.spawn
function task.wait(delay)
    return coroutine.yield(delay or .03)
end
local function advance(seconds)
    local finish = now + seconds
    while true do
        local index
        for i, item in ipairs(queue) do
            if item.At <= finish and (not index or queue[index].At > item.At) then index = i end
        end
        if not index then break end
        local item = table.remove(queue, index)
        now = item.At
        local ok, delay = coroutine.resume(item.Thread, table.unpack(item.Args, 1, item.Args.n))
        assert(ok, tostring(delay) .. "\n" .. debug.traceback(item.Thread))
        if coroutine.status(item.Thread) ~= "dead" then schedule(now + delay, item.Thread, table.pack(delay)) end
    end
    now = finish
end

local function signal()
    local callbacks = {}
    return {
        Connect = function(_, fn)
            table.insert(callbacks, fn)
            return { Disconnect = function()
                local index = table.find(callbacks, fn)
                if index then table.remove(callbacks, index) end
            end }
        end,
        Fire = function(_, ...)
            for _, fn in ipairs(table.clone(callbacks)) do fn(...) end
        end,
        Wait = function() return "Completed" end,
    }
end

local Vector3, vec = {}, {}
function Vector3.new(x, y, z)
    return setmetatable({ X = x or 0, Y = y or 0, Z = z or 0 }, vec)
end
vec.__index = function(v, key)
    if key == "Magnitude" then return math.sqrt(v.X * v.X + v.Y * v.Y + v.Z * v.Z) end
end
vec.__add = function(a, b) return Vector3.new(a.X + b.X, a.Y + b.Y, a.Z + b.Z) end
vec.__sub = function(a, b) return Vector3.new(a.X - b.X, a.Y - b.Y, a.Z - b.Z) end
vec.__mul = function(v, n) return Vector3.new(v.X * n, v.Y * n, v.Z * n) end
vec.__div = function(v, n) return v * (1 / n) end

local CFrame, frames = {}, {}
local function frame(position, right, up, back)
    return setmetatable({ Position = position, RightVector = right, UpVector = up, LookVector = back * -1 }, frames)
end
function CFrame.new(x, y, z)
    return frame(type(x) == "table" and x or Vector3.new(x, y, z),
        Vector3.new(1, 0, 0), Vector3.new(0, 1, 0), Vector3.new(0, 0, 1))
end
local function rotate(cf, v)
    return cf.RightVector * v.X + cf.UpVector * v.Y - cf.LookVector * v.Z
end
frames.__mul = function(a, b)
    return frame(a.Position + rotate(a, b.Position), rotate(a, b.RightVector), rotate(a, b.UpVector), rotate(a, b.LookVector * -1))
end
function CFrame.Angles(x, y, z)
    local sx, sy, sz = math.sin(x), math.sin(y), math.sin(z)
    local cx, cy, cz = math.cos(x), math.cos(y), math.cos(z)
    local origin = Vector3.new()
    return frame(origin, Vector3.new(1, 0, 0), Vector3.new(0, cx, sx), Vector3.new(0, -sx, cx))
        * frame(origin, Vector3.new(cy, 0, -sy), Vector3.new(0, 1, 0), Vector3.new(sy, 0, cy))
        * frame(origin, Vector3.new(cz, sz, 0), Vector3.new(-sz, cz, 0), Vector3.new(0, 0, 1))
end
CFrame.lookAt = CFrame.new
frames.__index = function(cf, name)
    if name == "Rotation" then return frame(Vector3.new(), cf.RightVector, cf.UpVector, cf.LookVector * -1) end
end
local function color()
    return { Lerp = function(self) return self end }
end
local Color3 = { fromRGB = color, new = color }
local Vector2 = { new = function(x, y) return { X = x, Y = y } end }
local UDim = { new = Vector2.new }
local udim2 = {}
local function uiDimensions(x, y)
    return setmetatable({ X = x, Y = y }, udim2)
end
udim2.__add = function(a, b) return uiDimensions(a.X + b.X, a.Y + b.Y) end
local UDim2 = { fromOffset = uiDimensions, fromScale = uiDimensions, new = uiDimensions }
local ColorSequence = { new = table.pack }
local NumberRange = { new = table.pack }
local NumberSequence = { new = table.pack }
local NumberSequenceKeypoint = { new = table.pack }
local TweenInfo = { new = table.pack }
local RaycastParams = { new = function() return {} end }
local Random = { new = function() return { NextNumber = function(_, a, b) return (a + b) / 2 end } end }
local Enum = setmetatable({}, { __index = function()
    return setmetatable({}, { __index = function(_, name) return name end })
end })

local methods = {}
local instanceMT = {}
local Instance = {}
function Instance.new(class)
    return setmetatable({ _class = class, _props = { Name = class, Enabled = class == "ProximityPrompt" }, _children = {}, _attributes = {} }, instanceMT)
end
local eventNames = {
    Triggered = true, OnServerEvent = true, CharacterAdded = true,
    PlayerAdded = true, PlayerRemoving = true,
    ChildAdded = true, ChildRemoved = true, Activated = true, OnClientEvent = true, DescendantAdded = true,
}
instanceMT.__index = function(self, key)
    if key == "ClassName" then return self._class end
    if methods[key] then return methods[key] end
    if self._props[key] ~= nil then return self._props[key] end
    if eventNames[key] then
        self._props[key] = signal()
        return self._props[key]
    end
    return self:FindFirstChild(key)
end
instanceMT.__newindex = function(self, key, value)
    if key == "Parent" then
        local previous = self._props.Parent
        if previous then
            local index = table.find(previous._children, self)
            if index then table.remove(previous._children, index) end
        end
        if value then table.insert(value._children, self) end
    elseif key == "CFrame" then
        self._props.Position = value.Position
    elseif key == "Position" then
        self._props.CFrame = CFrame.new(value)
    end
    self._props[key] = value
end

function methods:IsA(class)
    return self.ClassName == class or class == "BasePart" and getmetatable(self.Size) == vec
end
function methods:IsDescendantOf(target)
    local parent = self.Parent
    while parent do
        if parent == target then return true end
        parent = parent.Parent
    end
    return false
end
function methods:GetChildren() return table.clone(self._children) end
function methods:GetDescendants()
    local result = self:GetChildren()
    for _, child in ipairs(self._children) do
        for _, descendant in ipairs(child:GetDescendants()) do table.insert(result, descendant) end
    end
    return result
end
function methods:FindFirstChild(name, recursive)
    local children = recursive and self:GetDescendants() or self._children
    for _, child in ipairs(children) do if child.Name == name then return child end end
end
function methods:FindFirstChildOfClass(class)
    for _, child in ipairs(self._children) do if child:IsA(class) then return child end end
end
function methods:WaitForChild(name) return assert(self:FindFirstChild(name), self.Name .. " missing " .. name) end
function methods:SetAttribute(name, value) self._attributes[name] = value end
function methods:GetAttribute(name) return self._attributes[name] end
function methods:GetPropertyChangedSignal(key)
    local topic = "_event:" .. key
    if not self._props[topic] then self._props[topic] = signal() end
    return self._props[topic]
end
function methods:GetAttributeChangedSignal(key) return self:GetPropertyChangedSignal("attribute:" .. key) end
function methods:Emit() end
function methods:Destroy() self.Parent = nil end
function methods:GetPivot() return self.WorldPivot or CFrame.new() end
function methods:PivotTo(pivot) self.WorldPivot = pivot end
function methods:ScaleTo(scale) self.Scale = scale end
function methods:Clone()
    local copy = Instance.new(self.ClassName)
    for k, v in pairs(self._props) do if k ~= "Parent" then copy._props[k] = v end end
    copy._attributes = table.clone(self._attributes)
    for _, child in ipairs(self._children) do child:Clone().Parent = copy end
    return copy
end
function methods:FireClient(player, message, cue, _, _, soundCue)
    player.LastMessage, player.LastCue, player.LastSoundCue = message, cue, soundCue or cue
end

local tags = {}
local collection = {
    AddTag = function(_, object, tag) tags[object] = tags[object] or {}; tags[object][tag] = true end,
    RemoveTag = function(_, object, tag) if tags[object] then tags[object][tag] = nil end end,
}
local databases = {}
local function getStore(_, name)
    if not databases[name] then
        local values = {}
        databases[name] = {
            Values = values,
            GetAsync = function(_, key) return values[key] end,
            UpdateAsync = function(_, key, transform)
                local result = transform(values[key])
                if result then values[key] = result end
                return result
            end,
        }
    end
    return databases[name]
end
local workspace = Instance.new("Workspace")
function methods:GetServerTimeNow() return now end
function methods:Raycast() return self.BlockingHit end
local services = {
    CollectionService = collection,
    Players = Instance.new("Players"),
    Lighting = Instance.new("Lighting"),
    ReplicatedStorage = Instance.new("ReplicatedStorage"),
    ServerScriptService = Instance.new("ServerScriptService"),
    RunService = { IsStudio = function() return false end },
    HttpService = { GenerateGUID = function() return "test-" .. now end },
    DataStoreService = { GetDataStore = getStore },
    MarketplaceService = { PromptGamePassPurchaseFinished = signal() },
    TweenService = { Create = function(self, target, info, goal)
        self.LastTween = { Target = target, Info = info, Goal = goal }
        return { Play = function() end, Pause = function() end, Cancel = function() end, Completed = signal() }
    end },
}
function methods:GetPlayers() return self:GetChildren() end
function methods:GetPlayerByUserId(id)
    for _, player in ipairs(self._children) do if player.UserId == id then return player end end
end
function methods:Kick(reason) self.KickReason = reason end
function methods:EquipTool(tool) tool.Parent = self.Parent end
local game = {
    GetService = function(_, service) return assert(services[service], service) end,
    BindToClose = function(self, callback) self.Close = callback end,
}
local script = { Parent = services.ServerScriptService }
local modules = {}
local function register(name, parent, value)
    local handle = Instance.new("ModuleScript")
    handle.Name = name
    handle.Parent = parent
    modules[handle] = value
end
local function require(handle) return assert(modules[handle], handle.Name) end
local function warn(...) print(...) end
