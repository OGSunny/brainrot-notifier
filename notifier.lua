task.spawn(function()
    local TeleportService = game:GetService("TeleportService")
    local HttpService = game:GetService("HttpService")
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    local RunService = game:GetService("RunService")
    
    print("🧠 ZH Notifier v2.1 - Fixed & More Powerful! 🧠")
    
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
        if workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("Codes") and workspace.Map.Codes:FindFirstChild("Main") and workspace.Map.Codes.Main:FindFirstChild("SurfaceGui") and workspace.Map.Codes.Main.SurfaceGui:FindFirstChild("MainFrame") and workspace.Map.Codes.Main.SurfaceGui.MainFrame:FindFirstChild("PrivateServerMessage") and workspace.Map.Codes.Main.SurfaceGui.MainFrame.PrivateServerMessage.Visible == true then
            print("🧠 [ZH Notifier] Private server detected—hopping.")
            return false
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
    local scanStats = {totalScans = 0, totalFinds = 0}  -- Power: Track stats
    
    -- Powerful Hop Config: Hop after 60s or invalid
    local hopDelay = 60  -- Seconds per server (tuned for power: frequent fresh scans)
    local hopTimer = tick() + hopDelay
    
    local function powerfulHop(reason)
        print("🧠 [ZH Notifier] Hopping (" .. reason .. ")—stats: " .. scanStats.totalScans .. " scans, " .. scanStats.totalFinds .. " finds.")
        enviados = {}  -- Reset dedupe for new server
        pcall(function() TeleportService:Teleport(game.PlaceId, LocalPlayer) end)
    end
    
    local function gerarHash(texto)
        local soma = 0
        for i = 1, #texto do local b = string.byte(texto, i) if b then soma += b end end
        return tostring(soma)
    end
    
    local function parseValue(str)  -- Optimized
        if not str then return 0 end
        str = str:gsub("[^%d%.KMB]", ""):gsub(",", "")
        local num, suf = str:match("([%d%.]+)([KMB]?)")
        num = tonumber(num) or 0
        if suf == "K" then num *= 1000 elseif suf == "M" then num *= 1000000 elseif suf == "B" then num *= 1000000000 end
        return num
    end
    
    local function safeFind(parent, childName, recursive)
        if not parent then return nil end
        return parent:FindFirstChild(childName, recursive)
    end
    
    local function scanBrainrots(minStr, maxStr)  -- Fixed: Safe chaining, no nil errors
        local minVal, maxVal = parseValue(minStr), parseValue(maxStr)
        if minVal > maxVal then minVal, maxVal = maxVal, minVal end
        local results = {}
        local plots = workspace:FindFirstChild("Plots")
        if not plots then return results end
        
        local plotCount = 0
        for _, plot in pairs(plots:GetChildren()) do  -- Use pairs for speed
            plotCount += 1
            local plotSign = safeFind(plot, "PlotSign", true)
            if plotSign then
                local surfaceGui = safeFind(plotSign, "SurfaceGui", true)
                if surfaceGui then
                    local frame = safeFind(surfaceGui, "Frame", true)
                    if frame then
                        local textLabel = safeFind(frame, "TextLabel", true)
                        if textLabel and textLabel.Text and textLabel.Text ~= (LocalPlayer.DisplayName .. "'s Base") then
                            local podiums = safeFind(plot, "AnimalPodiums")
                            if podiums then
                                for _, podium in pairs(podiums:GetChildren()) do
                                    local base = safeFind(podium, "Base", true)
                                    if base then
                                        local spawn = safeFind(base, "Spawn", true)
                                        if spawn then
                                            local attachment = safeFind(spawn, "Attachment", true)
                                            if attachment then
                                                local overhead = safeFind(attachment, "AnimalOverhead", true)
                                                if overhead then
                                                    local stolen = safeFind(overhead, "Stolen")
                                                    if not (stolen and (stolen.Text == "CRAFTING" or stolen.Text == "IN MACHINE")) then
                                                        local gen = safeFind(overhead, "Generation")
                                                        local rarity = safeFind(overhead, "Rarity")
                                                        local name = safeFind(overhead, "DisplayName")
                                                        if gen and rarity and name and gen.Text then
                                                            local val = parseValue(gen.Text)
                                                            if val >= minVal and val <= maxVal then
                                                                table.insert(results, {nome = name.Text, raridade = rarity.Text, generation = gen.Text})
                                                                scanStats.totalFinds += 1
                                                            end
                                                        end
                                                    end
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
        print("🧠 [ZH Notifier] Scanned " .. plotCount .. " plots | Found: " .. #results)
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
            local key = item.nome .. "|" .. item.generation
            counts[key] = (counts[key] or 0) + 1
        end
        
        local news = {}
        for key, qty in pairs(counts) do
            if not enviados[key] then
                enviados[key] = true
                local name, gen = key:match("(.+)|(.+)")
                table.insert(news, {nome = name, generation = gen, quantidade = qty})
            end
        end
        
        if #news == 0 then return end
        
        local utcTime = os.date("!%H:%M:%S UTC")
        local text = ""
        for i, item in ipairs(news) do
            text = text .. "🧠 " .. item.nome .. " (" .. item.raridade .. ") — " .. item.generation
            if item.quantidade > 1 then text = text .. " x" .. item.quantidade end
            if i < #news then text = text .. "\n" end
        end
        
        local discordData = {
            embeds = {{
                title = "🧠 " .. title,
                description = text,
                color = 16711680,  -- Red for power
                fields = {
                    {name = "📊 Server", value = getServerInfo(), inline = true},
                    {name = "🆔 Job ID", value = "```" .. game.JobId .. "```", inline = true},
                    {name = "🔗 Join", value = "[TP NOW](https://ogsunny.github.io/brainrot-notifier/?placeId=" .. game.PlaceId .. "&gameInstanceId=" .. game.JobId .. ")", inline = false}
                },
                footer = {text = "🧠 ZH Notifier | " .. tierName .. " | " .. utcTime .. " | Scans: " .. scanStats.totalScans}
            }}
        }
        
        task.spawn(function()  -- Async send for power
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
    
    -- Wait for full load with retry
    local loadAttempts = 0
    repeat
        task.wait(2)
        loadAttempts += 1
        if loadAttempts > 10 then powerfulHop("load fail") return end
    until game:IsLoaded() and workspace:FindFirstChild("Plots")
    
    print("🧠 [ZH Notifier] 🚀 FULLY LOADED | Hop in " .. hopDelay .. "s | Ready to dominate!")
    
    -- Powerful Loop: Scan every 3s, hop on timer/invalid
    task.spawn(function()
        while true do
            task.wait(3)  -- Fast scans
            scanStats.totalScans += 1
            
            if tick() >= hopTimer then
                powerfulHop("timer")
                return
            end
            
            if not isValidServer() then
                powerfulHop("invalid")
                return
            end
            
            -- Parallel tier scans (Lua power: spawn per tier)
            for _, tier in ipairs(tiers) do
                task.spawn(function()
                    local brainrots = scanBrainrots(tier.min, tier.max)
                    sendWebhook(brainrots, baseUrl .. tier.path, tier.name, tier.title)
                end)
            end
        end
    end)
    
    -- Anti-kick: Humanize with heartbeat
    RunService.Heartbeat:Connect(function()
        if tick() >= hopTimer then powerfulHop("heartbeat hop") return end
    end)
end)
