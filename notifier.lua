task.spawn(function()
    local TeleportService = game:GetService("TeleportService")
    local HttpService = game:GetService("HttpService")
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    local RunService = game:GetService("RunService")
    
    print("🧠 ZH Notifier v2.2 - Ultra-Fixed & Powerful! 🧠")
    
    -- Auto-join ZH if not in game
    if game.PlaceId ~= 109983668079237 then
        print("🧠 [ZH Notifier] Not in Steal a Brainrot—auto-joining PlaceId 109983668079237...")
        pcall(function() TeleportService:Teleport(109983668079237, LocalPlayer) end)
        return
    end
    
    print("🧠 [ZH Notifier] In ZH—validating server...")
    
    -- Enhanced private/full server checks
    local function isValidServer()
        if #Players:GetPlayers() < 2 or #Players:GetPlayers() >= (Players.MaxPlayers or 8) then
            print("🧠 [ZH Notifier] Invalid pop (" .. #Players:GetPlayers() .. ")—hopping soon.")
            return false
        end
        local mapFolder = workspace:FindFirstChild("Map")
        if mapFolder then
            local codes = mapFolder:FindFirstChild("Codes")
            if codes then
                local main = codes:FindFirstChild("Main")
                if main then
                    local surfaceGui = main:FindFirstChild("SurfaceGui")
                    if surfaceGui then
                        local mainFrame = surfaceGui:FindFirstChild("MainFrame")
                        if mainFrame then
                            local privateMsg = mainFrame:FindFirstChild("PrivateServerMessage")
                            if privateMsg and privateMsg.Visible == true then
                                print("🧠 [ZH Notifier] Private server detected—hopping.")
                                return false
                            end
                        end
                    end
                end
            end
        end
        local plots = workspace:FindFirstChild("Plots")
        if not plots or #plots:GetChildren() < 2 then
            print("🧠 [ZH Notifier] No/low plots—retrying load...")
            return false
        end
        return true
    end
    
    if not isValidServer() then
        wait(3)  -- Brief retry
        if not isValidServer() then
            print("🧠 [ZH Notifier] Server invalid—auto-hopping.")
            pcall(function() TeleportService:Teleport(game.PlaceId, LocalPlayer) end)
            return
        end
    end
    
    local baseUrl = "https://notifier.jemalagegidze.workers.dev"
    local tiers = {
        {min = "1M/s", max = "4.99M/s", path = "/1", name = "1M-5M", title = "MEDIUM VALUE BRAINTOTS DETECTED"},
        {min = "5M/s", max = "9.99M/s", path = "/5", name = "5M-10M", title = "HIGH VALUE BRAINTOTS DETECTED"},
        {min = "10M/s", max = "29.99M/s", path = "/10", name = "10M-30M", title = "ULTRA VALUE BRAINTOTS DETECTED"},
        {min = "30M/s", max = "5B/s", path = "/30", name = "30M-5B", title = "SUPREME VALUE BRAINTOTS DETECTED"}
    }
    
    local enviados = {}
    local scanStats = {totalScans = 0, totalFinds = 0}
    
    -- Powerful Hop Config
    local hopDelay = 60
    local hopTimer = tick() + hopDelay
    
    local function powerfulHop(reason)
        print("🧠 [ZH Notifier] Hopping (" .. reason .. ")—stats: " .. scanStats.totalScans .. " scans, " .. scanStats.totalFinds .. " finds.")
        enviados = {}
        pcall(function() TeleportService:Teleport(game.PlaceId, LocalPlayer) end)
    end
    
    local function gerarHash(texto)
        local soma = 0
        for i = 1, #texto do local b = string.byte(texto, i) if b then soma += b end end
        return tostring(soma)
    end
    
    local function parseValue(str)
        if not str or type(str) ~= "string" then return 0 end
        str = str:gsub("[^%d%.KMB%s/]", ""):gsub(",", ""):gsub("/s", "")
        local num, suf = str:match("([%d%.]+)([KMB]?)")
        num = tonumber(num) or 0
        if suf == "K" then num *= 1000 elseif suf == "M" then num *= 1000000 elseif suf == "B" then num *= 1000000000 end
        return num
    end
    
    local function scanBrainrots(minStr, maxStr)
        local minVal, maxVal = parseValue(minStr), parseValue(maxStr)
        if minVal > maxVal then minVal, maxVal = maxVal, minVal end
        local results = {}
        local plots = workspace:FindFirstChild("Plots")
        if not plots then return results end
        
        local plotCount = 0
        for _, plot in pairs(plots:GetChildren()) do
            if not plot then continue end  -- Safety
            plotCount += 1
            
            -- Step-by-step nil-safe chaining for PlotSign hierarchy
            local plotSign = plot:FindFirstChild("PlotSign")
            if not plotSign then continue end
            
            local surfaceGui = plotSign:FindFirstChild("SurfaceGui")
            if not surfaceGui then continue end
            
            local frame = surfaceGui:FindFirstChild("Frame")
            if not frame then continue end
            
            local textLabel = frame:FindFirstChild("TextLabel")
            if not textLabel or not textLabel.Text or textLabel.Text == (LocalPlayer.DisplayName .. "'s Base") then continue end
            
            -- Now podiums
            local podiums = plot:FindFirstChild("AnimalPodiums")
            if not podiums then continue end
            
            for _, podium in pairs(podiums:GetChildren()) do
                if not podium then continue end
                
                -- Step-by-step for Base > Spawn > Attachment > AnimalOverhead
                local base = podium:FindFirstChild("Base")
                if not base then continue end
                
                local spawn = base:FindFirstChild("Spawn")
                if not spawn then continue end
                
                local attachment = spawn:FindFirstChild("Attachment")
                if not attachment then continue end
                
                local overhead = attachment:FindFirstChild("AnimalOverhead")
                if not overhead then continue end
                
                local stolen = overhead:FindFirstChild("Stolen")
                if stolen and (stolen.Text == "CRAFTING" or stolen.Text == "IN MACHINE") then continue end
                
                local gen = overhead:FindFirstChild("Generation")
                if not gen or not gen.Text then continue end
                
                local rarity = overhead:FindFirstChild("Rarity")
                if not rarity then continue end
                
                local name = overhead:FindFirstChild("DisplayName")
                if not name or not name.Text then continue end
                
                local val = parseValue(gen.Text)
                if val >= minVal and val <= maxVal then
                    table.insert(results, {nome = name.Text, raridade = rarity.Text, generation = gen.Text})
                    scanStats.totalFinds += 1
                end
            end
        end
        print("🧠 [ZH Notifier] Scanned " .. plotCount .. " plots | Found: " .. #results .. " in tier " .. minStr .. "-" .. maxStr)
        return results
    end
    
    local function getServerInfo()
        return tostring(#Players:GetPlayers()) .. "/" .. tostring(Players.MaxPlayers or 8)
    end
    
    local function sendWebhook(brainrots, url, tierName, title)
        if not brainrots or #brainrots == 0 then return end
        if #Players:GetPlayers() >= (Players.MaxPlayers or 8) then return end
        
        local counts = {}
        for _, item in ipairs(brainrots) do
            if item.nome and item.generation then
                local key = item.nome .. "|" .. item.generation
                counts[key] = (counts[key] or 0) + 1
            end
        end
        
        local news = {}
        for key, qty in pairs(counts) do
            if not enviados[key] then
                enviados[key] = true
                local name, gen = key:match("(.+)|(.+)")
                if name and gen then
                    table.insert(news, {nome = name, generation = gen, quantidade = qty, raridade = brainrots[1].raridade or "Unknown"})  -- Use first rarity if avail
                end
            end
        end
        
        if #news == 0 then return end
        
        local utcTime = os.date("!%H:%M:%S UTC")
        local text = ""
        for i, item in ipairs(news) do
            text = text .. "🧠 " .. item.nome .. " (" .. (item.raridade or "N/A") .. ") — " .. item.generation
            if item.quantidade > 1 then text = text .. " x" .. item.quantidade end
            if i < #news then text = text .. "\n" end
        end
        
        local discordData = {
            embeds = {{
                title = "🧠 " .. title,
                description = text,
                color = 16711680,
                fields = {
                    {name = "📊 Server", value = getServerInfo(), inline = true},
                    {name = "🆔 Job ID", value = "```" .. game.JobId .. "```", inline = true},
                    {name = "🔗 Join", value = "[TP NOW](https://ogsunny.github.io/brainrot-notifier/?placeId=" .. game.PlaceId .. "&gameInstanceId=" .. game.JobId .. ")", inline = false}
                },
                footer = {text = "🧠 ZH Notifier v2.2 | " .. tierName .. " | " .. utcTime .. " | Scans: " .. scanStats.totalScans .. " | Finds: " .. scanStats.totalFinds}
            }}
        }
        
        task.spawn(function()
            pcall(function()
                local timestamp = os.time()
                local userId = tostring(LocalPlayer.UserId)
                local hash = gerarHash(userId .. ":" .. timestamp .. ":ZHNotifier")
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
                print("🧠 [ZH Notifier] 🔥 PING FIRED to " .. tierName .. "! (" .. #news .. " new)")
            end)
        end)
    end
    
    -- Robust load wait
    local loadAttempts = 0
    repeat
        task.wait(2)
        loadAttempts += 1
        if loadAttempts > 15 then  -- Extended for safety
            print("🧠 [ZH Notifier] Load timeout—hopping.")
            powerfulHop("load fail")
            return
        end
    until game:IsLoaded() and workspace:FindFirstChild("Plots") and #workspace.Plots:GetChildren() > 0
    
    print("🧠 [ZH Notifier] 🚀 FULLY LOADED | Hop in " .. hopDelay .. "s | Ready to dominate servers!")
    
    -- Main Loop: Fast, safe scans
    task.spawn(function()
        while true do
            task.wait(3)
            scanStats.totalScans += 1
            
            if tick() >= hopTimer then
                powerfulHop("timer")
                return
            end
            
            if not isValidServer() then
                powerfulHop("invalid")
                return
            end
            
            -- Parallel tiers
            for _, tier in ipairs(tiers) do
                task.spawn(function()
                    local brainrots = scanBrainrots(tier.min, tier.max)
                    sendWebhook(brainrots, baseUrl .. tier.path, tier.name, tier.title)
                end)
            end
        end
    end)
    
    -- Heartbeat safety net
    RunService.Heartbeat:Connect(function()
        if tick() >= hopTimer then
            powerfulHop("heartbeat")
            return
        end
    end)
end)
