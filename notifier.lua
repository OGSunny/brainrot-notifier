-- Enhanced Player Notifier System
-- Optimized for performance and readability

local CONFIG = {
    PLACE_ID = 109983668079237,
    SCAN_INTERVAL = 5,
    MIN_ESTIMATED_VALUE = 100000,
    TIERS = {
        {min = "1M/s", max = "4.99M/s", webhook = "medium", name = "MEDIUM", emoji = "💎"},
        {min = "5M/s", max = "9.99M/s", webhook = "high", name = "HIGH", emoji = "⭐"},
        {min = "10M/s", max = "29.99M/s", webhook = "ultra", name = "ULTRA", emoji = "🔥"},
        {min = "30M/s", max = "5B/s", webhook = "supreme", name = "SUPREME", emoji = "👑"}
    }
}

local Services = {
    Http = game:GetService("HttpService"),
    Players = game:GetService("Players")
}

local State = {
    sentPlayers = {},
    localPlayer = Services.Players.LocalPlayer
}

-- Utility Functions
local function parseValue(str)
    if not str then return 0 end
    
    local cleanStr = tostring(str):gsub("%$", ""):gsub("%s", ""):gsub("/s", "")
    local amount, suffix = cleanStr:match("([%d%.]+)([KMB]?)")
    amount = tonumber(amount) or 0
    
    local multipliers = {K = 1e3, M = 1e6, B = 1e9}
    return amount * (multipliers[suffix] or 1)
end

local function generateHash(data)
    local sum = 0
    for i = 1, #data do
        sum = sum + (string.byte(data, i) or 0)
    end
    return tostring(sum)
end

local function getServerInfo()
    local current = #Services.Players:GetPlayers()
    local max = Services.Players.MaxPlayers or 0
    return string.format("%d/%d", current, max)
end

local function isServerFull()
    return #Services.Players:GetPlayers() >= (Services.Players.MaxPlayers or 0)
end

local function checkPrivateServer()
    local path = workspace:FindFirstChild("Map")
    if not path then return false end
    
    path = path:FindFirstChild("Codes")
    if not path then return false end
    
    path = path:FindFirstChild("Main")
    if not path then return false end
    
    local surfaceGui = path:FindFirstChild("SurfaceGui")
    if not surfaceGui then return false end
    
    local mainFrame = surfaceGui:FindFirstChild("MainFrame")
    if not mainFrame then return false end
    
    local privateMsg = mainFrame:FindFirstChild("PrivateServerMessage")
    return privateMsg and privateMsg.Visible == true
end

-- Player Scanning
local function getPlayerStats(player)
    local leaderstats = player:FindFirstChild("leaderstats")
    if not leaderstats then return nil end
    
    local income = leaderstats:FindFirstChild("IncomePerSec") or leaderstats:FindFirstChild("Income")
    local cash = leaderstats:FindFirstChild("Cash") or leaderstats:FindFirstChild("Money")
    
    if not (income and income.Value and cash) then return nil end
    
    return {
        income = income.Value,
        cash = cash.Value,
        displayName = player.DisplayName
    }
end

local function scanPlayers(minRange, maxRange)
    local minVal, maxVal = parseValue(minRange), parseValue(maxRange)
    if minVal > maxVal then minVal, maxVal = maxVal, minVal end
    
    local results = {}
    
    for _, player in ipairs(Services.Players:GetPlayers()) do
        if player ~= State.localPlayer then
            local stats = getPlayerStats(player)
            
            if stats then
                local incomeValue = stats.income
                local estimatedTotal = stats.cash + (incomeValue * 60)
                
                if incomeValue >= minVal and incomeValue <= maxVal and estimatedTotal > CONFIG.MIN_ESTIMATED_VALUE then
                    table.insert(results, {
                        name = stats.displayName,
                        generation = string.format("$%.2f/s", incomeValue),
                        estimated = estimatedTotal
                    })
                end
            end
        end
    end
    
    return results
end

-- Webhook System
local function buildEmbed(players, tier)
    local description = ""
    local grouped = {}
    
    -- Group duplicate players
    for _, p in ipairs(players) do
        local key = p.name .. "|" .. p.generation
        grouped[key] = (grouped[key] or 0) + 1
    end
    
    -- Build description
    for key, count in pairs(grouped) do
        local name, gen = key:match("(.+)|(.+)")
        description = description .. string.format("%s **%s** — %s (Est: $%s)", 
            tier.emoji, name, gen, string.format("%.0f", parseValue(gen) * 60))
        
        if count > 1 then
            description = description .. string.format(" ×%d", count)
        end
        description = description .. "\n"
    end
    
    return {
        embeds = {{
            title = string.format("%s %s VALUE TARGETS DETECTED", tier.emoji, tier.name),
            description = description,
            color = tier.name == "SUPREME" and 15844367 or 
                    tier.name == "ULTRA" and 15158332 or
                    tier.name == "HIGH" and 3447003 or 2067276,
            fields = {
                {name = "📊 Server Population", value = getServerInfo(), inline = true},
                {name = "🎮 Place ID", value = tostring(game.PlaceId), inline = true},
                {name = "🆔 Job ID", value = "```" .. tostring(game.JobId) .. "```", inline = false},
                {name = "🔗 Quick Join", value = string.format(
                    "[**CLICK TO JOIN SERVER**](https://ogsunny.github.io/brainrot-notifier/?placeId=%s&gameInstanceId=%s)",
                    game.PlaceId, game.JobId
                ), inline = false}
            },
            footer = {text = string.format("Enhanced Notifier | %s Tier | %s UTC", tier.name, os.date("!%H:%M:%S"))},
            timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
        }}
    }
end

local function sendWebhook(players, webhookType, tier)
    if not players or #players == 0 then return end
    if isServerFull() then return end
    
    -- Filter already sent players
    local newPlayers = {}
    for _, p in ipairs(players) do
        local key = p.name .. "|" .. p.generation
        if not State.sentPlayers[key] then
            State.sentPlayers[key] = true
            table.insert(newPlayers, p)
        end
    end
    
    if #newPlayers == 0 then return end
    
    local timestamp = os.time()
    local userId = tostring(State.localPlayer.UserId)
    local hash = generateHash(userId .. ":" .. timestamp .. ":SecureWebhook")
    
    local payload = {
        userId = userId,
        timestamp = timestamp,
        hash = hash,
        dados = buildEmbed(newPlayers, tier)
    }
    
    pcall(function()
        Services.Http:RequestAsync({
            Url = string.format("https://notifier.jemalagegidze.workers.dev/%s", webhookType),
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = Services.Http:JSONEncode(payload)
        })
    end)
end

-- Main Execution
local function initialize()
    -- Validate game
    if game.PlaceId ~= CONFIG.PLACE_ID then 
        return warn("Wrong game - notifier disabled")
    end
    
    -- Check for private server
    if checkPrivateServer() then
        return warn("Private server detected - notifier disabled")
    end
    
    -- Wait for game to load
    repeat task.wait() until game:IsLoaded()
    
    print("Enhanced Notifier initialized successfully")
    
    -- Start scanning loop
    task.spawn(function()
        while task.wait(CONFIG.SCAN_INTERVAL) do
            for _, tier in ipairs(CONFIG.TIERS) do
                pcall(function()
                    local targets = scanPlayers(tier.min, tier.max)
                    sendWebhook(targets, tier.webhook, tier)
                end)
            end
        end
    end)
end

-- Start the system
task.spawn(initialize)
