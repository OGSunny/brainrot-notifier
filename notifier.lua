task.spawn(function()
    if game.PlaceId ~= 109983668079237 then return end
    if workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("Codes") and workspace.Map.Codes:FindFirstChild("Main") and workspace.Map.Codes.Main:FindFirstChild("SurfaceGui") and workspace.Map.Codes.Main.SurfaceGui:FindFirstChild("MainFrame") and workspace.Map.Codes.Main.SurfaceGui.MainFrame:FindFirstChild("PrivateServerMessage") and workspace.Map.Codes.Main.SurfaceGui.MainFrame.PrivateServerMessage.Visible == true then return end
    
    local HttpService = game:GetService("HttpService")
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    local RunService = game:GetService("RunService")  -- For heartbeat if needed, but keeping simple
    
    local baseUrl = "https://notifier.jemalagegidze.workers.dev"  -- Your worker
    local tiers = {
        {min = "1M/s", max = "4.99M/s", path = "/1", name = "1M-5M", title = "MEDIUM VALUE BRAINTOTS DETECTED"},
        {min = "5M/s", max = "9.99M/s", path = "/5", name = "5M-10M", title = "HIGH VALUE BRAINTOTS DETECTED"},
        {min = "10M/s", max = "29.99M/s", path = "/10", name = "10M-30M", title = "ULTRA VALUE BRAINTOTS DETECTED"},
        {min = "30M/s", max = "5B/s", path = "/30", name = "30M-5B", title = "SUPREME VALUE BRAINTOTS DETECTED"}
    }
    
    local enviados = {}  -- Global dedupe across tiers
    local playerCache = {}  -- Speed: Cache leaderstats per player
    
    local function gerarHash(texto)
        local soma = 0
        for i = 1, #texto do
            local b = string.byte(texto, i)
            if b then soma += b end
        end
        return tostring(soma)
    end
    
    local function enviarWebhook(discordData, url)
        pcall(function()
            local timestamp = os.time()
            local userId = tostring(LocalPlayer.UserId)
            local hash = gerarHash(userId .. ":" .. timestamp .. ":Webhookzinha")
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
    end
    
    local function parseValue(str)
        if not str or type(str) ~= "string" then return 0 end
        str = str:gsub("%$", ""):gsub("%s", ""):gsub("/s", ""):gsub("/S", ""):gsub(",", "")  -- Handles "1,000K/s" too
        local num, suf = str:match("([%d%.%,]+)([KMB]?)")
        num = tonumber((num:gsub(",", ""))) or 0
        if suf == "K" then num *= 1e3
        elseif suf == "M" then num *= 1e6
        elseif suf == "B" then num *= 1e9 end
        return num
    end
    
    local function scanBrainrots()
        if #Players:GetPlayers() < 3 then return {} end  -- Auto-skip low-pop servers
        local brainrotsByTier = {}
        for _, tier in ipairs(tiers) do
            brainrotsByTier[tier.path] = {}
        end
        
        for _, pl in ipairs(Players:GetPlayers()) do
            if pl ~= LocalPlayer and pl:FindFirstChild("leaderstats") then
                -- Cache speed: Quick ref
                local stats = playerCache[pl] or pl.leaderstats
                playerCache[pl] = stats
                
                local income = stats:FindFirstChild("IncomePerSec") or stats:FindFirstChild("Income")
                local cash = stats:FindFirstChild("Cash") or stats:FindFirstChild("Money")
                if income and income.Value and cash and cash.Value > 100000 then  -- Faster: Inline totalEst check
                    local gen = tostring(income.Value) .. "/s"
                    local val = parseValue(gen)
                    local totalEst = cash.Value + (income.Value * 60)
                    
                    for _, tier in ipairs(tiers) do
                        local minVal, maxVal = parseValue(tier.min), parseValue(tier.max)
                        if minVal > maxVal then minVal, maxVal = maxVal, minVal end
                        if val >= minVal and val <= maxVal and totalEst > 100000 then
                            table.insert(brainrotsByTier[tier.path], {nome = pl.DisplayName, generation = gen, valor = totalEst})
                        end
                    end
                end
            end
        end
        return brainrotsByTier
    end
    
    local function buildAndSend(tier, brainrots)
        local url = baseUrl .. tier.path
        if #brainrots == 0 then return end  -- Auto-skip empty
        
        local contar = {}
        for _, b in ipairs(brainrots) do
            local key = b.nome .. "|" .. b.generation
            contar[key] = (contar[key] or 0) + 1
        end
        
        local novos = {}
        for key, qty in pairs(contar) do
            if not enviados[key] then
                enviados[key] = true
                local nome, generation = key:match("(.+)|(.+)")
                table.insert(novos, {nome = nome, generation = generation, quantidade = qty, valor = parseValue(generation) * 60})
            end
        end
        
        if #novos == 0 then return end  -- Auto-skip no news
        
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
    
    repeat task.wait() until game:IsLoaded()
    
    -- Auto-loop: Faster 2s, one scan feeds all tiers
    task.spawn(function()
        while task.wait(2) do  -- Tuned for speed without bans
            if #Players:GetPlayers() >= (Players.MaxPlayers or 0) then continue end  -- Auto-skip full
            pcall(function()
                local brainrotsByTier = scanBrainrots()  -- Single fast pass
                for _, tier in ipairs(tiers) do
                    buildAndSend(tier, brainrotsByTier[tier.path])
                end
                -- Optional: Clear cache every 30s for freshness (uncomment if players join/leave a lot)
                -- if os.clock() % 30 < 2 then playerCache = {} end
            end)
        end
    end)
end)
