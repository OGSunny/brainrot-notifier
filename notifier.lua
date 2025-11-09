task.spawn(function()
    if game.PlaceId ~= 109983668079237 then return end
    if workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("Codes") and workspace.Map.Codes:FindFirstChild("Main") and workspace.Map.Codes.Main:FindFirstChild("SurfaceGui") and workspace.Map.Codes.Main.SurfaceGui:FindFirstChild("MainFrame") and workspace.Map.Codes.Main.SurfaceGui.MainFrame:FindFirstChild("PrivateServerMessage") and workspace.Map.Codes.Main.SurfaceGui.MainFrame.PrivateServerMessage.Visible == true then return end
    
    local H = game:GetService("HttpService")
    local P = game:GetService("Players")
    local RS = game:GetService("RunService")
    local L = P.LocalPlayer
    
    local enviados = {}
    local lastScan = 0
    local SCAN_COOLDOWN = 2 -- Reduced from 5 to 2 seconds
    
    local function v(t)
        local s = 0
        for i = 1, #t do
            local b = string.byte(t, i)
            if b then s += b end
        end
        return tostring(s)
    end
    
    local function p(s)
        local n = s:gsub("%$",""):gsub("%s","")
        local a, u = n:match("([%d%.]+)([KMB]?)")
        a = tonumber(a) or 0
        if u == "K" then a *= 1e3 elseif u == "M" then a *= 1e6 elseif u == "B" then a *= 1e9 end
        return a
    end
    
    -- Optimized: Scan all tiers in ONE function call
    local function scanAllPlayers()
        local results = {
            medium = {},
            high = {},
            ultra = {},
            supreme = {}
        }
        
        for _, pl in ipairs(P:GetPlayers()) do
            if pl ~= L and pl:FindFirstChild("leaderstats") then
                local income = pl.leaderstats:FindFirstChild("IncomePerSec") or pl.leaderstats:FindFirstChild("Income")
                local cash = pl.leaderstats:FindFirstChild("Cash") or pl.leaderstats:FindFirstChild("Money")
                
                if income and income.Value and cash then
                    local gen = tostring(income.Value) .. "/s"
                    local val = p(gen)
                    local totalEst = cash.Value + (income.Value * 60)
                    
                    -- Only process if above minimum threshold
                    if val >= 1000000 and totalEst > 100000 then
                        local playerData = {
                            nome = pl.DisplayName,
                            generation = gen,
                            valor = totalEst
                        }
                        
                        -- Sort into tiers
                        if val >= 30000000 then
                            table.insert(results.supreme, playerData)
                        elseif val >= 10000000 then
                            table.insert(results.ultra, playerData)
                        elseif val >= 5000000 then
                            table.insert(results.high, playerData)
                        elseif val >= 1000000 then
                            table.insert(results.medium, playerData)
                        end
                    end
                end
            end
        end
        
        return results
    end
    
    local function J()
        return tostring(#P:GetPlayers()) .. "/" .. tostring(P.MaxPlayers or 0)
    end
    
    -- Optimized: Send webhook immediately, no batching
    local function w(a, u, t)
        if typeof(a) ~= "table" or #a == 0 then return end
        if #P:GetPlayers() >= (P.MaxPlayers or 0) then return end
        
        local nv = {}
        for _, x in ipairs(a) do
            if x.nome and x.generation then
                local k = x.nome .. "|" .. x.generation
                if not enviados[k] then
                    enviados[k] = true
                    table.insert(nv, x)
                end
            end
        end
        
        if #nv == 0 then return end
        
        local tm = os.date("!%H:%M:%S")
        local tx = ""
        for i, y in ipairs(nv) do
            tx = tx .. "🧠 " .. y.nome .. " — " .. y.generation .. " (Est: $" .. string.format("%.0f", y.valor) .. ")"
            if i < #nv then tx = tx .. "\n" end
        end
        
        local d = {
            embeds = {{
                title = "🧠 " .. t .. " V2",
                description = tx,
                color = 3447003,
                fields = {
                    {name = "📊 Server Info", value = J(), inline = false},
                    {name = "🆔 Job ID", value = "```" .. tostring(game.JobId) .. "```", inline = false},
                    {name = "🔗 Join Server", value = "[CLICK TO JOIN](https://ogsunny.github.io/brainrot-notifier/?placeId=" .. game.PlaceId .. "&gameInstanceId=" .. game.JobId .. ")", inline = false}
                },
                footer = {text = "Zvios Hub ZH Notifier 🧠 | " .. tm}
            }}
        }
        
        local ti = os.time()
        local id = tostring(L.UserId)
        local h = v(id .. ":" .. ti .. ":Webhookzinha")
        
        -- Fire and forget - don't wait for response
        task.spawn(function()
            pcall(function()
                H:RequestAsync({
                    Url = u,
                    Method = "POST",
                    Headers = {["Content-Type"] = "application/json"},
                    Body = H:JSONEncode({userId = id, timestamp = ti, hash = h, dados = d})
                })
            end)
        end)
    end
    
    repeat task.wait() until game:IsLoaded()
    
    -- INSTANT first scan when joining server
    task.spawn(function()
        task.wait(1) -- Wait 1 second for leaderstats to load
        local results = scanAllPlayers()
        w(results.medium, "https://notifier.jemalagegidze.workers.dev/medium", "MEDIUM VALUE BRAINTOTS DETECTED")
        w(results.high, "https://notifier.jemalagegidze.workers.dev/high", "HIGH VALUE BRAINTOTS DETECTED")
        w(results.ultra, "https://notifier.jemalagegidze.workers.dev/ultra", "ULTRA VALUE BRAINTOTS DETECTED")
        w(results.supreme, "https://notifier.jemalagegidze.workers.dev/supreme", "SUPREME VALUE BRAINTOTS DETECTED")
    end)
    
    -- Continuous fast scanning
    task.spawn(function()
        while task.wait(SCAN_COOLDOWN) do
            local currentTime = tick()
            if currentTime - lastScan < SCAN_COOLDOWN then
                continue
            end
            lastScan = currentTime
            
            pcall(function()
                local results = scanAllPlayers()
                
                -- Send webhooks in parallel (don't wait for each)
                if #results.supreme > 0 then
                    w(results.supreme, "https://notifier.jemalagegidze.workers.dev/supreme", "SUPREME VALUE BRAINTOTS DETECTED")
                end
                if #results.ultra > 0 then
                    w(results.ultra, "https://notifier.jemalagegidze.workers.dev/ultra", "ULTRA VALUE BRAINTOTS DETECTED")
                end
                if #results.high > 0 then
                    w(results.high, "https://notifier.jemalagegidze.workers.dev/high", "HIGH VALUE BRAINTOTS DETECTED")
                end
                if #results.medium > 0 then
                    w(results.medium, "https://notifier.jemalagegidze.workers.dev/medium", "MEDIUM VALUE BRAINTOTS DETECTED")
                end
            end)
        end
    end)
    
    -- Listen for NEW players joining (instant detection)
    P.PlayerAdded:Connect(function(newPlayer)
        task.wait(2) -- Wait for leaderstats to load
        if newPlayer == L then return end
        
        pcall(function()
            if newPlayer:FindFirstChild("leaderstats") then
                local income = newPlayer.leaderstats:FindFirstChild("IncomePerSec") or newPlayer.leaderstats:FindFirstChild("Income")
                local cash = newPlayer.leaderstats:FindFirstChild("Cash") or newPlayer.leaderstats:FindFirstChild("Money")
                
                if income and income.Value and cash then
                    local gen = tostring(income.Value) .. "/s"
                    local val = p(gen)
                    local totalEst = cash.Value + (income.Value * 60)
                    
                    if val >= 1000000 and totalEst > 100000 then
                        local playerData = {{
                            nome = newPlayer.DisplayName,
                            generation = gen,
                            valor = totalEst
                        }}
                        
                        -- Instant notification for new high-value player
                        if val >= 30000000 then
                            w(playerData, "https://notifier.jemalagegidze.workers.dev/supreme", "SUPREME VALUE BRAINTOTS DETECTED")
                        elseif val >= 10000000 then
                            w(playerData, "https://notifier.jemalagegidze.workers.dev/ultra", "ULTRA VALUE BRAINTOTS DETECTED")
                        elseif val >= 5000000 then
                            w(playerData, "https://notifier.jemalagegidze.workers.dev/high", "HIGH VALUE BRAINTOTS DETECTED")
                        elseif val >= 1000000 then
                            w(playerData, "https://notifier.jemalagegidze.workers.dev/medium", "MEDIUM VALUE BRAINTOTS DETECTED")
                        end
                    end
                end
            end
        end)
    end)
end)
