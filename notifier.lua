task.spawn(function()
    if game.PlaceId ~= 109983668079237 then return end
    if workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("Codes") and workspace.Map.Codes:FindFirstChild("Main") and workspace.Map.Codes.Main:FindFirstChild("SurfaceGui") and workspace.Map.Codes.Main.SurfaceGui.MainFrame and workspace.Map.Codes.Main.SurfaceGui.MainFrame:FindFirstChild("PrivateServerMessage") and workspace.Map.Codes.Main.SurfaceGui.MainFrame.PrivateServerMessage.Visible == true then return end
    local H = game:GetService("HttpService")
    local P = game:GetService("Players")
    local L = P.LocalPlayer
    local enviados = {}
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
    local function g(m, M)
        local mi, ma = p(m), p(M)
        if mi > ma then mi, ma = ma, mi end
        local r = {}
        for _, pl in ipairs(P:GetPlayers()) do
            if pl ~= L and pl:FindFirstChild("leaderstats") then
                local income = pl.leaderstats:FindFirstChild("IncomePerSec") or pl.leaderstats:FindFirstChild("Income")
                local cash = pl.leaderstats:FindFirstChild("Cash") or pl.leaderstats:FindFirstChild("Money")
                if income and income.Value and cash then
                    local gen = tostring(income.Value) .. "/s"
                    local val = p(gen)
                    local totalEst = cash.Value + (income.Value * 60)
                    if val >= mi and val <= ma and totalEst > 100000 then
                        table.insert(r, {nome = pl.DisplayName, generation = gen, valor = totalEst})
                    end
                end
            end
        end
        return r
    end
    local function J()
        return tostring(#P:GetPlayers()) .. "/" .. tostring(P.MaxPlayers or 0)
    end
    local function w(a, u, n, t)
        if typeof(a) ~= "table" or #a == 0 then return end
        if #P:GetPlayers() >= (P.MaxPlayers or 0) then return end
        local c = {}
        for _, x in ipairs(a) do
            if x.nome and x.generation then
                local k = x.nome .. "|" .. x.generation
                c[k] = (c[k] or 0) + 1
            end
        end
        local nv = {}
        for k, q in pairs(c) do
            if not enviados[k] then
                enviados[k] = true
                local nm, ge = k:match("(.+)|(.+)")
                table.insert(nv, {nome = nm, generation = ge, quantidade = q, valor = p(ge) * 60})
            end
        end
        if #nv == 0 then return end
        local tm = os.date("!%H:%M:%S")
        local tx = ""
        for i, y in ipairs(nv) do
            tx = tx .. "🧠 " .. y.nome .. " — " .. y.generation .. " (Est: $" .. string.format("%.0f", y.valor) .. ")"
            if y.quantidade > 1 then tx = tx .. " - " .. y.quantidade .. "x" end
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
                    {name = "🔗 Join Server", value = "[CLICK TO JOIN](https://yourusername.github.io/brainrot-notifier/?placeId=" .. game.PlaceId .. "&gameInstanceId=" .. game.JobId .. ")", inline = false}
                },
                footer = {text = "Brainrot Notifier 🧠 | Scanner " .. n .. " | " .. tm}
            }}
        }
        local ti = os.time()
        local id = tostring(L.UserId)
        local h = v(id .. ":" .. ti .. ":Webhookzinha")
        pcall(function()
            H:RequestAsync({
                Url = u,
                Method = "POST",
                Headers = {["Content-Type"] = "application/json"},
                Body = H:JSONEncode({userId = id, timestamp = ti, hash = h, dados = d})
            })
        end)
    end
    repeat task.wait() until game:IsLoaded()
    task.spawn(function()
        while task.wait(5) do
            pcall(function()
                w(g("1M/s", "4.99M/s"), "https://brainrot-notifier.jemalagegidze.workers.dev/medium", "1M-5M", "MEDIUM VALUE BRAINTOTS DETECTED")
                w(g("5M/s", "9.99M/s"), "https://brainrot-notifier.jemalagegidze.workers.dev/high", "5M-10M", "HIGH VALUE BRAINTOTS DETECTED")
                w(g("10M/s", "29.99M/s"), "https://brainrot-notifier.jemalagegidze.workers.dev/ultra", "10M-30M", "ULTRA VALUE BRAINTOTS DETECTED")
                w(g("30M/s", "5B/s"), "https://brainrot-notifier.jemalagegidze.workers.dev/supreme", "30M-5B", "SUPREME VALUE BRAINTOTS DETECTED")
            end)
        end
    end)
end)
