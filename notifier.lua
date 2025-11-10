task.spawn(function()
    print("[Notifier] Starting load check for PlaceId: " .. game.PlaceId)  -- Debug: Confirm PlaceId
    if game.PlaceId ~= 109983668079237 then 
        print("[Notifier] Wrong game—skipping.") 
        return 
    end
    
    -- Private server check (existing)
    if workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("Codes") and workspace.Map.Codes:FindFirstChild("Main") and workspace.Map.Codes.Main:FindFirstChild("SurfaceGui") and workspace.Map.Codes.Main.SurfaceGui:FindFirstChild("MainFrame") and workspace.Map.Codes.Main.SurfaceGui.MainFrame:FindFirstChild("PrivateServerMessage") and workspace.Map.Codes.Main.SurfaceGui.MainFrame.PrivateServerMessage.Visible == true then 
        print("[Notifier] In private server—skipping scans.") 
        return 
    end
    print("[Notifier] Game checks passed—ready to scan.")  -- Debug: Here means it's good to go
    
    local HttpService = game:GetService("HttpService")
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    local RunService = game:GetService("RunService")
    
    local baseUrl = "https://notifier.jemalagegidze.workers.dev"
    local tiers = {
        {min = "1M/s", max = "4.99M/s", path = "/1", name = "1M-5M", title = "MEDIUM VALUE BRAINTOTS DETECTED"},
        {min = "5M/s", max = "9.99M/s", path = "/5", name = "5M-10M", title = "HIGH VALUE BRAINTOTS DETECTED"},
        {min = "10M/s", max = "29.99M/s", path = "/10", name = "10M-30M", title = "ULTRA VALUE BRAINTOTS DETECTED"},
        {min = "30M/s", max = "5B/s", path = "/30", name = "30M-5B", title = "SUPREME VALUE BRAINTOTS DETECTED"}
    }
    
    local enviados = {}
    local playerCache = {}
    
    local function formatValue(num)
        if num >= 1e9 then
            return string.format("%.2fB", num / 1e9)
        elseif num >= 1e6 then
            return string.format("%.2fM", num / 1e6)
        elseif num >= 1e3 then
            return string.format("%.1fK", num / 1e3)
        else
            return tostring(math.floor(num))
        end
    end
    
    local function gerarHash(texto)
        local soma = 0
        for i = 1, #texto do
            local b = string.byte(texto, i)
            if b then soma += b end
        end
        return tostring(soma)
    end
    
    local function enviarWebhook(discordData, url)
        print("[Notifier] Attempting webhook to: " .. url)  -- Debug: See if it tries to send
        pcall(function()
            local timestamp = os.time()
            local userId = tostring(LocalPlayer.UserId)
            local hash = gerarHash(userId .. ":" .. timestamp .. ":Webhookzinha")
            local success, err = pcall(function()
                HttpService:RequestAsync({
                    Url = url,
                    Method = "POST",
                    Headers = {["Content-Type"] = "application/json"},
                    Body = HttpService:JSONEncode({
                        userId = userId,
                        timestamp = timestamp,
                        hash = hash,
                        dados = discordData
                    })
                })
            end)
            if success then
                print("[Notifier] Webhook sent successfully!")  -- Debug: Confirm send
            else
                print("[Notifier] Webhook failed: " .. tostring(err))  -- Debug: Errors here
            end
        end)
    end
    
    local function parseValue(str)
        if not str or type(str) ~= "string" then return 0 end
        str = str:gsub("%$", ""):gsub("%s", ""):gsub("/s", ""):gsub("/S", ""):gsub(",", "")
        local num, suf = str:match("([%d%.%,]+)([KMB]?)")
        num = tonumber((num:gsub(",", ""))) or 0
        if suf == "K" then num *= 1e3
        elseif suf == "M" then num *= 1e6
        elseif suf == "B" then num *= 1e9 end
        return num
    end
    
    local function scanBrainrots()
        local playerCount = #Players:GetPlayers()
        print("[Notifier] Scanning... Total players: " .. playerCount)  -- Debug: Player count
        if playerCount < 3 then 
            print("[Notifier] Too few players (<3)—skipping scan.") 
            return {} 
        end
        local brainrotsByTier = {}
        for _, tier in ipairs(tiers) do
            brainrotsByTier[tier.path] = {}
        end
        
        local foundStats = 0  -- Debug counter
        for _, pl in ipairs(Players:GetPlayers()) do
            if pl ~= LocalPlayer and pl:FindFirstChild("leaderstats") then
                local stats = playerCache[pl] or pl.leaderstats
                playerCache[pl] = stats
                
                local income = stats:FindFirstChild("IncomePerSec") or stats:FindFirstChild("Income")
                local cash = stats:FindFirstChild("Cash") or stats:FindFirstChild("Money")
                print("[Notifier] Checked " .. pl.DisplayName .. ": Income=" .. tostring(income and income.Value or "nil") .. ", Cash=" .. tostring(cash and cash.Value or "nil"))  -- Debug: Per-player stats
                
                if income and income.Value and cash and cash.Value > 100000 then
                    foundStats += 1
                    local val = income.Value
                    local gen = formatValue(val) .. "/s"
                    local totalEst = cash.Value + (val * 60)
                    
                    local matchedTiers = 0
                    for _, tier in ipairs(tiers) do
                        local minVal, maxVal = parseValue(tier.min), parseValue(tier.max)
                        if val >= minVal and val <= maxVal and totalEst > 100000 then
                            table.insert(brainrotsByTier[tier.path], {nome = pl.DisplayName, generation = gen, valor = totalEst})
                            matchedTiers += 1
                        end
                    end
                    if matchedTiers > 0 then
                        print("[Notifier] " .. pl.DisplayName .. " matched " .. matchedTiers .. " tiers! Val: " .. val)  -- Debug: Matches
                    end
                end
            end
        end
        print("[Notifier] Scan complete: Found " .. foundStats .. " qualifying players.")  -- Debug: Summary
        return brainrotsByTier
    end
    
    local function buildAndSend(tier, brainrots)
        local url = baseUrl .. tier.path
        print("[Notifier] Building for tier " .. tier.name .. ": " .. #brainrots .. " brainrots")  -- Debug: Per tier
        if #brainrots == 0 then return end
        
        local newData = {}
        for _, b in ipairs(brainrots) do
            local key = b.nome .. "|" .. b.generation
            if not newData[key] then
                newData[key] = {nome = b.nome, generation = b.generation, valor = b.valor, count = 0}
            end
            newData[key].count += 1
            newData[key].valor = math.max(newData[key].valor, b.valor)
        end
        
        local novos = {}
        for key, data in pairs(newData) do
            if not enviados[key] then
                enviados[key] = true
                table.insert(novos, {nome = data.nome, generation = data.generation, quantidade = data.count, valor = data.valor})
            end
        end
        
        if #novos == 0 then 
            print("[Notifier] No new brainrots for " .. tier.name) 
            return 
        end
        
        print("[Notifier] Sending " .. #novos .. " new alerts for " .. tier.name)  -- Debug: Before send
        
        local utcTime = os.date("!%H:%M:%S")
        local text = ""
        for i, b in ipairs(novos) do
            text = text .. "🧠 " .. b.nome .. " — " .. b.generation .. " (Est: $" .. string.format("%.0f", b.valor) .. ")"
            if b.quantidade > 1 then text = text .. " - " .. b.quantidade .. "x" end
            if i < #novos then text = text .. "\n" end
        end
        
        local playersStr = tostring(#Players:GetPlayers()) .. "/" .. tostring(Players.MaxPlayers or 0)
        local discordData = {
            embeds = {{
                title = "🧠 " .. tier.title .. " V2",
                description = text,
                color = 3447003,
                fields = {
                    {name = "📊 Server Info", value = playersStr, inline = false},
                    {name = "🆔 Job ID", value = "```" .. tostring(game.JobId) .. "```", inline = false},
                    {name = "🔗 Join Server", value = "[CLICK TO JOIN](https://ogsunny.github.io/brainrot-notifier/?placeId=" .. game.PlaceId .. "&gameInstanceId=" .. game.JobId .. ")", inline = false}
                },
                footer = {text = "Zvios Hub ZH Notifier 🧠 | Scanner " .. tier.name .. " | " .. utcTime}
            }}
        }
        
        enviarWebhook(discordData, url)
    end
    
    print("[Notifier] Waiting for game load...")  -- Debug: Load wait
    repeat task.wait(1) until game:IsLoaded()  -- Bumped to 1s for reliability
    print("[Notifier] Game loaded—starting scan loop!")  -- Debug: Loop start
    
    task.spawn(function()
        local scanCount = 0
        while task.wait(5) do  -- Bumped to 5s for less spam/debug
            scanCount += 1
            print("[Notifier] Loop #" .. scanCount .. " starting...")  -- Debug: Loop ticks
            if #Players:GetPlayers() >= (Players.MaxPlayers or 0) then 
                print("[Notifier] Server full—skipping.") 
                continue 
            end
            pcall(function()
                local brainrotsByTier = scanBrainrots()
                for _, tier in ipairs(tiers) do
                    buildAndSend(tier, brainrotsByTier[tier.path])
                end
            end)
        end
    end)
    print("[Notifier] Auto-scan loop spawned!")  -- Debug: End
end)
