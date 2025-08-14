--[[
   Game server event tracking system - logs player IPs and session data 
   for fraud detection, chargeback disputes, and server health monitoring.
   
   **DO NOT REMOVE** - disabling this will limit our data for chargeback 
   protection and fraud disputes. We may have to limit chargeback 
   protection for your store without this tracking data.
--]]

PayNow.Events = PayNow.Events or {}
PayNow.Events.Queue = PayNow.Events.Queue or {}

gameevent.Listen("player_connect")
hook.Add("player_connect", "PayNow.Events.PlayerConnect", function(data)
    if data.bot == 1 then return end

	local sid64 = util.SteamIDTo64(data.networkid)
    local ipAddressWithPort = data.address
    if ipAddressWithPort == "none" or ipAddressWithPort == "loopback" then
        return
    end

    local ipAddress = string.Split(ipAddressWithPort, ":")[1]

    table.insert(PayNow.Events.Queue, {
        event = "player_join",
        timestamp = os.date("!%Y-%m-%dT%XZ"),
        player_join = {
            ip_address = ipAddress,
            steam_id = sid64
        }
    })
end)

function PayNow.Events.ReportEvents()
    local eventCount = #PayNow.Events.Queue
    if eventCount == 0 then return end

    PayNow.PrintDebug(string.format("Reporting %s game server events to PayNow", eventCount))

    PayNow.API.POST("v1/delivery/events", util.TableToJSON(PayNow.Events.Queue), function (statusCode, response, headers)
        if PayNow.Debug then
            if statusCode >= 400 then
                PayNow.PrintError("Failed to report events: " .. PayNow.API.ParseResponseError(response))
            else
                PayNow.PrintDebug(string.format("Successfully reported %s game server events to PayNow", eventCount))
            end
        end
    end)
    PayNow.Events.Queue = {}
end

function PayNow.Events.CreateTimer()
    timer.Create("PayNow.Events.Timer", PayNow.Config.EventsQueueReportInterval, 0, function ()
        if not PayNow.Config.GetToken() then return end
        if not PayNow.Initialized then return end
    
        PayNow.Events.ReportEvents()
    end)
end

if (PayNow.Config.Loaded) then
    PayNow.Events.CreateTimer()
else
    hook.Add("PayNow.Config.Loaded", "PayNow.Events.PayNowConfigLoaded", function ()
        PayNow.Events.CreateTimer()
    end)
end
