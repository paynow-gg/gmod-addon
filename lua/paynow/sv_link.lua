PayNow.Link = PayNow.Link or {}

function PayNow.Link.LinkGameServer()
    local data = {
        ip = game.GetIPAddress(),
        hostname = GetHostName(),
        platform = "gmod",
        version = PayNow.Version
    }

    -- Fallback to an alternative method of fetching the IP if it's not available yet
    if string.StartWith(data.ip, "0.0.0.0:") then
        data.ip = GetConVarString('ip') .. ':' .. GetConVarString('hostport')
    end

    PayNow.API.POST("v1/delivery/gameserver/link", util.TableToJSON(data), function (statusCode, response, headers)
        if statusCode >= 400 then
            PayNow.PrintError("Failed to link gameserver: " .. PayNow.API.ParseResponseError(response))
            return
        end

        local linkData = util.JSONToTable(response or {})
        if not linkData then
            PayNow.PrintError("Failed to parse JSON for gameserver link: ", response)
            return
        end

        if linkData.update_available then
            PayNow.Print("Update available! Latest version: " .. linkData.latest_version .. ", current: " .. PayNow.Version)
        end

        if linkData.previously_linked then
            PayNow.PrintWarning("This token was previously linked to " .. linkData.previously_linked.host_name .. " (" .. linkData.previously_linked.ip .. "), make sure you have updated/removed the token on the old server")
        end

        if linkData.gameserver == nil then
            PayNow.PrintError("Gameserver link was missing a gameserver object!")
            return
        end

        local gs = linkData.gameserver
        PayNow.Print("Connected your server to PayNow gameserver " .. gs.name .. " (" .. gs.id .. ")")
    end)
end