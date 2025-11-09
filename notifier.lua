task.spawn(function()
    if game.PlaceId ~= 109983668079237 then return end
    if workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("Codes") and workspace.Map.Codes:FindFirstChild("Main") and workspace.Map.Codes.Main:FindFirstChild("SurfaceGui") and workspace.Map.Codes.Main.SurfaceGui:FindFirstChild("MainFrame") and workspace.Map.Codes.Main.SurfaceGui.MainFrame:FindFirstChild("PrivateServerMessage") and workspace.Map.Codes.Main.SurfaceGui.MainFrame.PrivateServerMessage.Visible == true then return end
    
    local HttpService = game:GetService("HttpService")
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    
    local w1 = "https://notifier.jemalagegidze.workers.dev/medium"
    local w2 = "https://notifier.jemalagegidze.workers.dev/high"
    local w3 = "https://notifier.jemalagegidze.workers.dev/ultra"
    local w4 = "https://notifier.jemalagegidze.workers.dev/supreme"
    
    local enviados = {}
    local lastScanTime = 0
    local SCAN_INTERVAL = 3 -- Faster scanning (was 5)
    
    local function gerarHash(texto)
        local soma = 0
        for i = 1, #texto do
            local b = string.byte(texto, i)
            if b then soma = soma + b end
        end
        return tostring(soma)
    end
    
    local function enviarWebhook(discordData, web)
        if not web or type(web) ~= "string" or web == "" then return end
        task.spawn(function()
            pcall(function()
                local timestamp = math.floor(os.time())
                local userId = tostring(LocalPlayer.UserId)
                local hash = gerarHash(userId .. ":" .. timestamp .. ":Webhookzinha")
                HttpService:RequestAsync({
                    Url = web,
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
        end)
    end
    
    local function parseValue(str)
        if not str or type(str) ~= "string" then return 0 end
        str = str:gsub("%$", ""):gsub("%s", "")
        local num, suf = str:match("([%d%.]+)([KMB]?)")
        num = tonumber(num) or 0
        if suf == "K" then num = num * 1e3
        elseif suf == "M" then num = num * 1e6
        elseif suf == "B" then num = num * 1e9 end
        return num
    end
    
    -- Optimized: Scan all tiers at once
    local function GetAllAnimals()
        local results = {
            medium = {},
            high = {},
            ultra = {},
            supreme = {}
        }
        
        local plotsFolder = workspace:FindFirstChild("Plots")
        if not plotsFolder then return results end
        
        local myBaseName = LocalPlayer.DisplayName .. "'s Base"
        
        for _, plot in ipairs(plotsFolder:GetChildren()) do
            local textLabel = plot:FindFirstChild("PlotSign") and 
                             plot.PlotSign:FindFirstChild("SurfaceGui") and 
                             plot.PlotSign.SurfaceGui:FindFirstChild("Frame") and 
                             plot.PlotSign.SurfaceGui.Frame:FindFirstChild("TextLabel")
            
            if textLabel and textLabel.Text and textLabel.Text ~= myBaseName then
                local animalPodiums = plot:FindFirstChild("AnimalPodiums")
                if animalPodiums then
                    for _, podium in ipairs(animalPodiums:GetChildren()) do
                        local base = podium:FindFirstChild("Base")
                        local spawn = base and base:FindFirstChild("Spawn")
                        local attach = spawn and spawn:FindFirstChild("Attachment")
                        local overhead = attach and attach:FindFirstChild("AnimalOverhead")
                        
                        if overhead then
                            local stolen = overhead:FindFirstChild("Stolen")
                            if not (stolen and (stolen.Text == "CRAFTING" or stolen.Text == "IN MACHINE")) then
                                local gen = overhead:FindFirstChild("Generation")
                                local rarity = overhead:FindFirstChild("Rarity")
                                local name = overhead:FindFirstChild("DisplayName")
                                
                                if gen and rarity and name and gen.Text and name.Text and rarity.Text then
                                    local value = parseValue(gen.Text)
                                    
                                    -- Sort into tiers
                                    if value >= 1000000 then
                                        local animalData = {
                                            nome = name.Text,
                                            raridade = rarity.Text,
                                            generation = gen.Text
                                        }
                                        
                                        if value >= 30000000 then
                                            table.insert(results.supreme, animalData)
                                        elseif value >= 10000000 then
                                            table.insert(results.ultra, animalData)
                                        elseif value >= 5000000 then
                                            table.insert(results.high, animalData)
                                        else
                                            table.insert(results.medium, animalData)
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
        
        return results
    end
    
    local function GetPlayers()
        local total = Players.MaxPlayers or 0
        return tostring(#Players:GetPlayers()) .. "/" .. tostring(total)
    end
    
    local function Web(animals, web, faixaNome, faixaTitulo)
        if typeof(animals) ~= "table" or #animals == 0 then return end
        if #Players:GetPlayers() >= (Players.MaxPlayers or 0) then return end
        
        local contar = {}
        for _, a in ipairs(animals) do
            if a.nome and a.generation then
                local key = a.nome .. "|" .. a.generation
                contar[key] = (contar[key] or 0) + 1
            end
        end
        
        local novos = {}
        for key, qty in pairs(contar) do
            if not enviados[key] then
                enviados[key] = true
                local nome, generation = key:match("(.+)|(.+)")
                table.insert(novos, {nome = nome, generation = generation, quantidade = qty})
            end
        end
        
        if #novos == 0 then return end
        
        local utcTime = os.date("!%H:%M:%S")
        local animalsText = ""
        for i, animal in ipairs(novos) do
            animalsText = animalsText .. "🧠 " .. animal.nome .. " — " .. animal.generation
            if animal.quantidade > 1 then
                animalsText = animalsText .. " - " .. animal.quantidade .. "x"
            end
            if i < #novos then animalsText = animalsText .. "\n" end
        end
        
        local discordData = {
            embeds = {{
                title = "🧠 " .. faixaTitulo,
                description = animalsText,
                color = 3447003,
                fields = {
                    {name = "📊 Server Info", value = GetPlayers(), inline = false},
                    {name = "🆔 Job ID", value = "```" .. tostring(game.JobId) .. "```", inline = false},
                    {name = "🔗 Join Server", value = "[CLICK TO JOIN](https://ogsunny.github.io/brainrot-notifier/?placeId=" .. game.PlaceId .. "&gameInstanceId=" .. game.JobId .. ")", inline = false}
                },
                footer = {text = "Zvios Hub ZH Notifier 🧠 | Scanner " .. faixaNome .. " | " .. utcTime}
            }}
        }
        
        enviarWebhook(discordData, web)
    end
    
    repeat task.wait() until game:IsLoaded()
    
    -- Instant first scan
    task.spawn(function()
        task.wait(2)
        pcall(function()
            local results = GetAllAnimals()
            Web(results.medium, w1, "1M-5M", "MEDIUM VALUE PETS DETECTED (1M-5M)")
            Web(results.high, w2, "5M-10M", "HIGH VALUE PETS DETECTED (5M-10M)")
            Web(results.ultra, w3, "10M-30M", "ULTRA VALUE PETS DETECTED (10M-30M)")
            Web(results.supreme, w4, "30M-5B", "SUPREME VALUE PETS DETECTED (30M-5B)")
        end)
    end)
    
    -- Continuous fast scanning
    task.spawn(function()
        while task.wait(SCAN_INTERVAL) do
            local currentTime = tick()
            if currentTime - lastScanTime < SCAN_INTERVAL then continue end
            lastScanTime = currentTime
            
            pcall(function()
                local results = GetAllAnimals()
                
                -- Send webhooks in parallel
                if #results.supreme > 0 then
                    Web(results.supreme, w4, "30M-5B", "SUPREME VALUE PETS DETECTED (30M-5B)")
                end
                if #results.ultra > 0 then
                    Web(results.ultra, w3, "10M-30M", "ULTRA VALUE PETS DETECTED (10M-30M)")
                end
                if #results.high > 0 then
                    Web(results.high, w2, "5M-10M", "HIGH VALUE PETS DETECTED (5M-10M)")
                end
                if #results.medium > 0 then
                    Web(results.medium, w1, "1M-5M", "MEDIUM VALUE PETS DETECTED (1M-5M)")
                end
            end)
        end
    end)
end)
