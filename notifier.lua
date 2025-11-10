task.spawn(function()
    local TeleportService = game:GetService("TeleportService")
    local HttpService = game:GetService("HttpService")
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    
    -- Configuration
    local CONFIG = {
        botId = "ZHBot_" .. math.random(1000, 9999),
        PLACE_ID = 109983668079237,
        hopDelay = 45,  -- Time to scan before hopping
        maxPopulation = 6,  -- Only scan low-pop servers
        maxEnviadosSize = 500,  -- Prevent memory leak
        baseUrl = "https://notifier.jemalagegidze.workers.dev",
        lastPingTime = {},  -- Rate limiting per tier
        minPingInterval = 30  -- Minimum seconds between pings per tier
    }
    
    print("🧠 [ZH Scanner " .. CONFIG.botId .. "] Starting real-time plot scanner!")
    
    -- Tier definitions
    local TIERS = {
        {min = "1M/s", max = "4.99M/s", path = "/1", name = "1M-5M", title = "MEDIUM VALUE BRAINTOTS", color = 10181046},
        {min = "5M/s", max = "9.99M/s", path = "/5", name = "5M-10M", title = "HIGH VALUE BRAINTOTS", color = 5763719},
        {min = "10M/s", max = "29.99M/s", path = "/10", name = "10M-30M", title = "ULTRA VALUE BRAINTOTS", color = 16711680},
        {min = "30M/s", max = "5B/s", path = "/30", name = "30M+", title = "SUPREME VALUE BRAINTOTS", color = 16776960}
    }
    
    local enviados = {}  -- Track sent items
    local scanCount = 0
    
    -- Utility: Parse value strings (e.g., "1.5M/s" -> 1500000)
    local function parseValue(str)
        if not str or type(str) ~= "string" then return 0 end
        
        str = str:gsub("[^%d%.KMB/s]", "")
        local num, suffix = str:match("([%d%.]+)([KMB]?)")
        num = tonumber(num) or 0
        
        local multipliers = {K = 1e3, M = 1e6, B = 1e9}
        if multipliers[suffix] then
            num = num * multipliers[suffix]
        end
        
        return num
    end
    
    -- Utility: Estimate total value (generation rate + random cash estimate)
    local function estimateValue(genRate)
        local perMinute = genRate * 60
        local cashEstimate = math.random(1000000, 50000000)
        return perMinute + cashEstimate
    end
    
    -- Core: Scan plots for brainrots in value range
    local function scanBrainrots(minStr, maxStr)
        local success, result = pcall(function()
            local minVal = parseValue(minStr)
            local maxVal = parseValue(maxStr)
            
            if minVal > maxVal then
                minVal, maxVal = maxVal, minVal
            end
            
            local results = {}
            local plots = workspace:FindFirstChild("Plots")
            
            if not plots then
                warn("⚠️ [Scanner] Plots folder not found!")
                return results
            end
            
            for _, plot in pairs(plots:GetChildren()) do
                local success2, _ = pcall(function()
                    -- Navigate to plot sign
                    local plotSign = plot:FindFirstChild("PlotSign")
                    if not plotSign then return end
                    
                    local surfaceGui = plotSign:FindFirstChild("SurfaceGui")
                    if not surfaceGui then return end
                    
                    local frame = surfaceGui:FindFirstChild("Frame")
                    if not frame then return end
                    
                    local textLabel = frame:FindFirstChild("TextLabel")
                    if not textLabel or not textLabel.Text then return end
                    
                    -- Skip own plot
                    if textLabel.Text == (LocalPlayer.DisplayName .. "'s Base") then return end
                    
                    -- Check animal podiums
                    local podiums = plot:FindFirstChild("AnimalPodiums")
                    if not podiums then return end
                    
                    for _, podium in pairs(podiums:GetChildren()) do
                        local success3, _ = pcall(function()
                            local base = podium:FindFirstChild("Base")
                            if not base then return end
                            
                            local spawn = base:FindFirstChild("Spawn")
                            if not spawn then return end
                            
                            local attachment = spawn:FindFirstChild("Attachment")
                            if not attachment then return end
                            
                            local overhead = attachment:FindFirstChild("AnimalOverhead")
                            if not overhead then return end
                            
                            -- Skip if crafting or in machine
                            local stolen = overhead:FindFirstChild("Stolen")
                            if stolen and (stolen.Text == "CRAFTING" or stolen.Text == "IN MACHINE") then
                                return
                            end
                            
                            -- Get animal data
                            local gen = overhead:FindFirstChild("Generation")
                            local rarity = overhead:FindFirstChild("Rarity")
                            local name = overhead:FindFirstChild("DisplayName")
                            
                            if not gen or not gen.Text then return end
                            if not rarity or not rarity.Text then return end
                            if not name or not name.Text then return end
                            
                            local genValue = parseValue(gen.Text)
                            
                            -- Check if in range
                            if genValue >= minVal and genValue <= maxVal then
                                local estimatedValue = estimateValue(genValue)
                                
                                table.insert(results, {
                                    nome = name.Text,
                                    raridade = rarity.Text,
                                    generation = gen.Text,
                                    genValue = genValue,
                                    valor = estimatedValue,
                                    plotOwner = textLabel.Text
                                })
                            end
                        end)
                        
                        if not success3 then
                            -- Silent fail for individual podiums
                        end
                    end
                end)
            end
            
            return results
        end)
        
        if success then
            return result
        else
            warn("❌ [Scanner] Error in scanBrainrots:", result)
            return {}
        end
    end
    
    -- Core: Send Discord notification
    local function sendPing(brainrots, tierConfig)
        if #brainrots == 0 then return end
        
        -- Rate limiting check
        local now = tick()
        if CONFIG.lastPingTime[tierConfig.name] then
            local elapsed = now - CONFIG.lastPingTime[tierConfig.name]
            if elapsed < CONFIG.minPingInterval then
                print("⏱️ [Scanner] Rate limited for " .. tierConfig.name .. " (wait " .. math.floor(CONFIG.minPingInterval - elapsed) .. "s)")
                return
            end
        end
        
        -- Count and deduplicate
        local counts = {}
        for _, item in ipairs(brainrots) do
            local key = item.nome .. "|" .. item.generation
            counts[key] = (counts[key] or 0) + 1
        end
        
        -- Find new items not yet sent
        local newItems = {}
        for key, qty in pairs(counts) do
            if not enviados[key] then
                enviados[key] = true
                
                local name, gen = key:match("(.+)|(.+)")
                local itemData = nil
                
                for _, item in ipairs(brainrots) do
                    if item.nome == name and item.generation == gen then
                        itemData = item
                        break
                    end
                end
                
                if itemData then
                    table.insert(newItems, {
                        nome = name,
                        generation = gen,
                        quantidade = qty,
                        valor = itemData.valor,
                        plotOwner = itemData.plotOwner
                    })
                end
            end
        end
        
        if #newItems == 0 then return end
        
        -- Build description text
        local description = ""
        for i, item in ipairs(newItems) do
            description = description .. "🧠 **" .. item.nome .. "** — " .. item.generation
            description = description .. " (Est: $" .. string.format("%.1fM", item.valor / 1000000) .. ")"
            
            if item.quantidade > 1 then
                description = description .. " — **" .. item.quantidade .. "x**"
            end
            
            if i < #newItems then
                description = description .. "\n"
            end
        end
        
        -- Create Discord embed
        local utcTime = os.date("!%H:%M:%S UTC", os.time())
        local jobId = game.JobId
        
        local discordData = {
            embeds = {{
                title = "🧠 " .. tierConfig.title,
                description = description,
                color = tierConfig.color,
                fields = {
                    {
                        name = "📊 Server Info",
                        value = #Players:GetPlayers() .. "/" .. (Players.MaxPlayers or 8) .. " players",
                        inline = true
                    },
                    {
                        name = "🔍 Items Found",
                        value = #newItems .. " new item(s)",
                        inline = true
                    },
                    {
                        name = "🆔 Job ID",
                        value = "```" .. jobId .. "```",
                        inline = false
                    },
                    {
                        name = "🔗 Join Server",
                        value = "[CLICK TO JOIN](https://ogsunny.github.io/brainrot-notifier/?placeId=" .. CONFIG.PLACE_ID .. "&gameInstanceId=" .. jobId .. ")",
                        inline = false
                    }
                },
                footer = {
                    text = "ZH Scanner | " .. tierConfig.name .. " | " .. utcTime .. " | " .. CONFIG.botId
                },
                timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ", os.time())
            }}
        }
        
        -- Send webhook
        local success, response = pcall(function()
            local timestamp = os.time()
            local userId = tostring(LocalPlayer.UserId)
            
            -- Simple hash (your backend should validate this properly)
            local hashStr = userId .. timestamp .. jobId
            local hash = 0
            for i = 1, #hashStr do
                hash = hash + string.byte(hashStr, i)
            end
            
            return HttpService:RequestAsync({
                Url = CONFIG.baseUrl .. tierConfig.path,
                Method = "POST",
                Headers = {
                    ["Content-Type"] = "application/json"
                },
                Body = HttpService:JSONEncode({
                    userId = userId,
                    timestamp = timestamp,
                    hash = tostring(hash),
                    dados = discordData
                })
            })
        end)
        
        if success then
            CONFIG.lastPingTime[tierConfig.name] = now
            print("✅ [Scanner] Sent " .. #newItems .. " items to " .. tierConfig.name .. " webhook")
        else
            warn("❌ [Scanner] Failed to send webhook:", response)
        end
    end
    
    -- Utility: Clean up enviados table to prevent memory leak
    local function cleanupEnviados()
        local count = 0
        for _ in pairs(enviados) do count = count + 1 end
        
        if count > CONFIG.maxEnviadosSize then
            enviados = {}
            print("🧹 [Scanner] Cleared enviados cache (" .. count .. " entries)")
        end
    end
    
    -- Main scanner loop
    local function scanLoop()
        while true do
            task.wait(5)
            
            -- Check if we should hop
            local currentPlayers = #Players:GetPlayers()
            local shouldHop = currentPlayers > CONFIG.maxPopulation or not workspace:FindFirstChild("Plots")
            
            if shouldHop then
                print("🔄 [Scanner] Hopping... (Pop: " .. currentPlayers .. "/" .. CONFIG.maxPopulation .. ")")
                
                local success, err = pcall(function()
                    TeleportService:Teleport(CONFIG.PLACE_ID, LocalPlayer)
                end)
                
                if not success then
                    warn("❌ [Scanner] Teleport failed:", err)
                end
                
                task.wait(10)
                enviados = {}
                CONFIG.lastPingTime = {}
                scanCount = 0
                continue
            end
            
            -- Scan all tiers
            scanCount = scanCount + 1
            print("🔍 [Scanner] Scan #" .. scanCount .. " starting...")
            
            for _, tier in ipairs(TIERS) do
                task.spawn(function()
                    local brainrots = scanBrainrots(tier.min, tier.max)
                    
                    if #brainrots > 0 then
                        print("📦 [Scanner] Found " .. #brainrots .. " items in " .. tier.name)
                        sendPing(brainrots, tier)
                    end
                end)
            end
            
            -- Periodic cleanup
            if scanCount % 10 == 0 then
                cleanupEnviados()
            end
            
            task.wait(CONFIG.hopDelay)
        end
    end
    
    -- Start scanner
    scanLoop()
end)
