services.SoundService = Instance.new("SoundService")
services.ProximityPromptService = { PromptShown = signal(), PromptHidden = signal() }
services.UserInputService = { GetLastInputType = function() return { Name = "MouseButton1" } end }
local movementBlocked = false
services.GuiService = {}
services.ContextActionService = {
    BindActionAtPriority = function(_, name) assert(name == "MeadowWelcomeMovement"); movementBlocked = true end,
    UnbindAction = function(_, name) assert(name == "MeadowWelcomeMovement"); movementBlocked = false end,
}
Enum.ContextActionPriority = { High = { Value = 3000 } }
collection.HasTag = function(_, target, tag) return tags[target] and tags[target][tag] end
collection.GetTagged = function(_, tag)
    local result = {}
    for target, assigned in pairs(tags) do
        if assigned[tag] then table.insert(result, target) end
    end
    return result
end
collection.GetInstanceAddedSignal = signal
collection.GetInstanceRemovedSignal = signal
local cameraMock = Instance.new("Camera")
cameraMock.ViewportSize = Vector2.new(390, 844)
workspace.CurrentCamera = cameraMock
local localPlayerMock = Instance.new("Player")
services.Players.LocalPlayer = localPlayerMock
localPlayerMock.Parent = services.Players
Instance.new("PlayerGui").Parent = localPlayerMock
local characterMock = Instance.new("Model")
localPlayerMock.Character = characterMock
local audioRoot = Instance.new("Part")
audioRoot.Name, audioRoot.Position, audioRoot.Parent = "HumanoidRootPart", Vector3.new(0, 4, 0), characterMock
function methods:Play() self.PlayCount = (self.PlayCount or 0) + 1 end
function methods:Stop() self.StopCount = (self.StopCount or 0) + 1 end
local toolMock = Instance.new("Tool")
toolMock:SetAttribute("MiningPickaxe", true)
toolMock.Parent = characterMock
local mouseMock = {}
function methods:GetMouse() return mouseMock end
for _, name in ipairs({"SwingAtOre", "EquipCollection", "PremiumAction", "MiningAction", "ReturnToMeadow", "DismissWelcome"}) do
    local remote = Instance.new("RemoteEvent")
    remote.Name, remote.Parent = name, services.ReplicatedStorage
end
local firedRemote, firedTarget
function methods:FireServer(target)
    firedRemote, firedTarget = self.Name, target
end
