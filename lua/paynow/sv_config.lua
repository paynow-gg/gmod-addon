PayNow.Config = PayNow.Config or {}
PayNow.Config.Data = PayNow.Config.Data or {}

PayNow.Config.Path = "paynow/config.json"

PayNow.Config.DefaultCommandFetchInterval = 10

function PayNow.Config.Load()
    if not file.Exists(PayNow.Config.Path, "DATA") then
        PayNow.Config.Loaded = true
        hook.Run("PayNow.Config.Loaded")

        return
    end

    file.AsyncRead(PayNow.Config.Path, "DATA", function (fileName, gamePath, status, data)
        if status ~= FSASYNC_OK then
            PayNow.PrintError("Failed to read config file: err code ", status)
            return
        end

        local parsedConfig = util.JSONToTable(data or {})
        if not parsedConfig then
            PayNow.PrintError("Failed to parse config file JSON")
            return
        end

        PayNow.Config.Loaded = true
        PayNow.Config.Data = parsedConfig
        PayNow.Print("Config loaded successfully")

        hook.Run("PayNow.Config.Loaded")
    end)
end

function PayNow.Config.Save()
    file.CreateDir("paynow")
    file.Write(PayNow.Config.Path, util.TableToJSON(PayNow.Config.Data, true))
end

-- Config getters/setters

function PayNow.Config.GetToken()
    return PayNow.Config.Data.Token
end

function PayNow.Config.ValidateToken(token, callback)
    -- Try to call a command queue route, see if it failed
    PayNow.API.HTTP("v1/delivery/command-queue", "GET", nil, {
        ["Authorization"] = string.format("Gameserver %s", token)
    }, function (statusCode)
        callback(statusCode ~= 401 and statusCode ~= 403)
    end)
end

function PayNow.Config.SetToken(token)
    PayNow.Config.Data.Token = token
    PayNow.Config.Save()
end

function PayNow.Config.GetInterval()
    return PayNow.Config.Data.FetchIntervalSeconds or PayNow.Config.DefaultCommandFetchInterval
end

function PayNow.Config.SetInterval(interval, noSave)
    PayNow.Config.Data.FetchIntervalSeconds = interval

    if not noSave then
        PayNow.Config.Save()
    end

    timer.Adjust("PayNow.CommandQueue.Timer", interval)
end

-- Concommands

local function concommandReply(ply, text)
    if ply ~= NULL then
        ply:ChatPrint(text)    
    else
        PayNow.Print(text)
    end
end

concommand.Add("paynow.token", function (ply, cmd, args, argStr)
    if ply ~= NULL and not ply:IsSuperAdmin() then
        ply:ChatPrint("This command can only be executed from the console or by a superadmin.")
        return
    end

    local token = args[1]
    if not token or #token < 1 then
        concommandReply(ply, "Usage: paynow.token <token>")
        return
    end

    concommandReply(ply, "Validating token...")
    PayNow.Config.ValidateToken(token, function (success)
        if not success then
            concommandReply(ply, "This token is invalid, make sure you copied the token correctly, and that your gameserver is enabled.")
            return
        end

        PayNow.Config.SetToken(token)
        concommandReply(ply, "Token set successfully!")

        PayNow.Link.LinkGameServer()
    end)
end, nil, nil, FCVAR_PROTECTED)

concommand.Add("paynow.interval_seconds", function (ply, cmd, args, argStr)
    if ply ~= NULL and not ply:IsSuperAdmin() then
        ply:ChatPrint("This command can only be executed from the console or by a superadmin.")
        return
    end

    local seconds = args[1]
    local numSeconds = tonumber(seconds)
    if not seconds or numSeconds == nil or numSeconds < 10 then
        concommandReply(ply, "Usage: paynow.interval_seconds <seconds>")
        return
    end

    PayNow.Config.SetInterval(numSeconds)
    concommandReply(ply, "Changed command fetch interval succesfully!")
end, nil, nil, FCVAR_PROTECTED)