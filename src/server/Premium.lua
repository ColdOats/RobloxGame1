local DataStoreService = game:GetService("DataStoreService")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")

local Premium = {}
local ledger
local latest = {}
local productsById = {}

local function key(userId)
    return "wallet:" .. userId
end

local function read(record)
    return record or { Balance = 0, Rewards = 0, Version = 0, Receipts = {} }
end

local function publish(player, record)
    if not player or player.Parent ~= Players then return end
    if latest[player] and latest[player].Version > record.Version then return end
    latest[player] = record
    player:SetAttribute("Starshards", record.Balance)
    player:SetAttribute("PremiumRewards", record.Rewards)
    player:SetAttribute("PremiumReady", true)
end

function Premium.owns(player, index)
    local record = latest[player]
    return record ~= nil and bit32.btest(record.Rewards, bit32.lshift(1, index - 1))
end

function Premium.load(player)
    if not ledger then return end
    local ok, result = pcall(function()
        return ledger:GetAsync(key(player.UserId))
    end)
    if ok then
        publish(player, read(result))
    else
        warn("Starshard wallet load failed:", result)
    end
end

function Premium.forget(player)
    latest[player] = nil
end

function Premium.buyCrate(player, index, crate)
    if not ledger then return false, "Starshard wallet is unavailable." end
    local bit = bit32.lshift(1, index - 1)
    local outcome
    local ok, updated = pcall(function()
        return ledger:UpdateAsync(key(player.UserId), function(previous)
            local record = read(previous)
            if bit32.btest(record.Rewards, bit) then
                outcome = "You already own this crate's reward."
                return nil
            end
            if record.Balance < crate.Cost then
                outcome = "Need " .. crate.Cost .. " Starshards for this crate."
                return nil
            end
            outcome = nil
            record.Balance -= crate.Cost
            record.Rewards = bit32.bor(record.Rewards, bit)
            record.Version += 1
            return record
        end)
    end)
    if not ok then
        warn("Premium crate transaction failed:", updated)
        return false, "Could not open the crate. Try again."
    end
    if not updated then return false, outcome or "Could not open the crate." end
    publish(player, updated)
    return true
end

function Premium.prompt(player, product)
    if not ledger or not product or productsById[product.ProductId] ~= product then return false end
    MarketplaceService:PromptProductPurchase(player, product.ProductId)
    return true
end

function Premium.start(products)
    productsById = {}
    for _, product in ipairs(products) do
        if product.ProductId > 0 then
            if productsById[product.ProductId] then
                warn("Duplicate Starshard product ID. Keep each pack on a separate Developer Product.")
            else
                productsById[product.ProductId] = product
            end
        end
    end
    local ok, result = pcall(function()
        return DataStoreService:GetDataStore("CrystalMining_Starshards_v1")
    end)
    if ok then ledger = result end

    MarketplaceService.ProcessReceipt = function(receipt)
        local product = productsById[receipt.ProductId]
        if not ledger or not product then
            return Enum.ProductPurchaseDecision.NotProcessedYet
        end
        local purchaseId = tostring(receipt.PurchaseId)
        local success, record = pcall(function()
            return ledger:UpdateAsync(key(receipt.PlayerId), function(previous)
                local wallet = read(previous)
                if not wallet.Receipts[purchaseId] then
                    wallet.Balance += product.Amount
                    wallet.Receipts[purchaseId] = true
                    wallet.Version += 1
                end
                return wallet
            end)
        end)
        if not success or not record or not record.Receipts[purchaseId] then
            if not success then warn("Starshard receipt deferred:", record) end
            return Enum.ProductPurchaseDecision.NotProcessedYet
        end
        publish(Players:GetPlayerByUserId(receipt.PlayerId), record)
        return Enum.ProductPurchaseDecision.PurchaseGranted
    end
end

local passIndexes = {}
local purchaseConnection

function Premium.ownsPass(player, index)
    return player:GetAttribute("PassOwned" .. index) == true
end

function Premium.startPasses(passes, onPurchase)
    passIndexes = {}
    for index, pass in ipairs(passes) do
        if pass.Id > 0 then
            if passIndexes[pass.Id] then
                warn("Duplicate game pass ID:", pass.Id)
            else
                passIndexes[pass.Id] = index
            end
        end
    end
    if purchaseConnection then purchaseConnection:Disconnect() end
    purchaseConnection = MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, id, purchased)
        local index = passIndexes[id]
        if not purchased or not index or player.Parent ~= Players or Premium.ownsPass(player, index) then return end
        player:SetAttribute("PassOwned" .. index, true)
        onPurchase(player, passes[index])
    end)
end

local function checkPass(player, index, pass)
    if passIndexes[pass.Id] ~= index then return nil end
    local ok, owned = pcall(function()
        return MarketplaceService:UserOwnsGamePassAsync(player.UserId, pass.Id)
    end)
    if player.Parent ~= Players then return nil end
    if Premium.ownsPass(player, index) then return true end
    if not ok then
        warn("Could not check game pass ownership:", owned)
        return nil
    end
    player:SetAttribute("PassOwned" .. index, owned)
    return owned
end

function Premium.loadPasses(player, passes)
    for index, pass in ipairs(passes) do
        if pass.Id > 0 then task.spawn(checkPass, player, index, pass) end
    end
end

function Premium.promptPass(player, index, pass)
    if passIndexes[pass.Id] ~= index then return false, "This pass is unavailable." end
    local owned = player:GetAttribute("PassOwned" .. index)
    if owned == nil then owned = checkPass(player, index, pass) end
    if owned == nil then return false, "Could not check pass ownership. Try again." end
    if owned then return false, "You already own this pass." end
    MarketplaceService:PromptGamePassPurchase(player, pass.Id)
    return true
end

return Premium
