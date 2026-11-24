services.SoundService = Instance.new("SoundService")
services.UserInputService = { GetLastInputType = function() return { Name = "MouseButton1" } end }
collection.HasTag = function(_, target, tag) return tags[target] and tags[target][tag] end
collection.GetTagged = function() return {} end
collection.GetInstanceAddedSignal = signal
collection.GetInstanceRemovedSignal = signal
local cameraMock = Instance.new("Camera")
cameraMock.ViewportSize = Vector2.new(390, 844)
workspace.CurrentCamera = cameraMock
local localPlayerMock = Instance.new("Player")
services.Players.LocalPlayer = localPlayerMock
Instance.new("PlayerGui").Parent = localPlayerMock
local characterMock = Instance.new("Model")
localPlayerMock.Character = characterMock
local toolMock = Instance.new("Tool")
toolMock:SetAttribute("MiningPickaxe", true)
toolMock.Parent = characterMock
local mouseMock = {}
function methods:GetMouse() return mouseMock end
for _, name in ipairs({"SwingAtOre", "EquipCollection", "PremiumAction", "MiningAction"}) do
    local remote = Instance.new("RemoteEvent")
    remote.Name, remote.Parent = name, services.ReplicatedStorage
end
local firedRemote, firedTarget
function methods:FireServer(target)
    firedRemote, firedTarget = self.Name, target
end
