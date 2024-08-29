PayNow.CommandQueue = PayNow.CommandQueue or {}
PayNow.CommandQueue.ExecutedCommands = PayNow.CommandQueue.ExecutedCommands or {}
PayNow.CommandQueue.ExecutedCommandsHistoryCapacity = 25

PayNow.CommandQueue.AcknowledgedCommandQueue = PayNow.CommandQueue.AcknowledgedCommandQueue or {}

function PayNow.CommandQueue.BuildOnlinePlayers()
    local steamIDs = {}
    for k, ply in ipairs(player.GetHumans()) do
        table.insert(steamIDs, ply:SteamID64())
    end

    return {
        steam_ids = steamIDs
    }
end

function PayNow.CommandQueue.InsertExecutedCommand(command)
    if #PayNow.CommandQueue.ExecutedCommands >= PayNow.CommandQueue.ExecutedCommandsHistoryCapacity then
        table.remove(PayNow.CommandQueue.ExecutedCommands, 1)
    end

    table.insert(PayNow.CommandQueue.ExecutedCommands, command)
    table.insert(PayNow.CommandQueue.AcknowledgedCommandQueue, command)
end

function PayNow.CommandQueue.CheckIfCommandAlreadyExecuted(command)
    for i, checkedCmd in ipairs(PayNow.CommandQueue.ExecutedCommands) do
        if command.attempt_id == checkedCmd.attempt_id then
            return true
        end
    end

    return false
end

local function wrapQuotedArgs(str)
    local params, quoted = {}, false
    for sep, word in str:gmatch("(%s*)(%S+)") do
      local word, oquote = word:gsub('^"', "") -- check opening quote
      local word, cquote = word:gsub('"$', "") -- check closing quote
      -- flip open/close quotes when inside quoted string
      if quoted then -- if already quoted, then concatenate
        params[#params] = params[#params]..sep..word
      else -- otherwise, add a new element to the list
        params[#params+1] = word
      end
      if quoted and word == "" then oquote, cquote = 0, oquote end
      quoted = (quoted or (oquote > 0)) and not (cquote > 0)
    end
    return params
end

function PayNow.CommandQueue.ExecuteCommand(command)
    local commandToExecute = string.Trim(command.command)

    -- Gotta love dealing with utf8
    local sanitizedString = ""
    for p, c in utf8.codes(utf8.force(commandToExecute)) do
        -- Replace UTF8 160 (no-break space) and zero width non-joiner with a regular space
        if c == 160 or c == 8204 then
            sanitizedString = sanitizedString .. " "
            continue
        end

        sanitizedString = sanitizedString .. utf8.char(c)
    end

    local parsedArgs = wrapQuotedArgs(sanitizedString)

    PayNow.PrintDebug("Executing the following command:")
    if PayNow.Debug then
        PrintTable(command)

        PayNow.PrintDebug("Parsed command arguments:")
        PrintTable(parsedArgs)
    end

    RunConsoleCommand(unpack(parsedArgs))
    PayNow.CommandQueue.InsertExecutedCommand(command)
end

function PayNow.CommandQueue.AcknowledgeCommands(retry)
    local attemptIDs = {}
    for i, command in ipairs(PayNow.CommandQueue.AcknowledgedCommandQueue) do
        table.insert(attemptIDs, {
            attempt_id = command.attempt_id
        })
    end

    PayNow.API.POST("v1/delivery/command-queue/acknowledge", util.TableToJSON(attemptIDs), function (statusCode, response, headers)
        if statusCode >= 400 then
            PayNow.PrintError("Failed to acknowledge executed commands: " .. PayNow.API.ParseResponseError(response))

            if not retry then
                timer.Create("PayNow.CommandQueue.AcknowledgeRetryAttempt" .. CurTime(), 5, 10, function ()
                    PayNow.CommandQueue.AcknowledgeCommands(true)
                end)
            end

            return
        end

        PayNow.Print(string.format("Executed and acknowledged %d commands", #attemptIDs))
        PayNow.CommandQueue.AcknowledgedCommandQueue = {}
    end)
end

function PayNow.CommandQueue.FetchPendingCommands()
    local onlinePlayersJSON = util.TableToJSON(PayNow.CommandQueue.BuildOnlinePlayers())
    PayNow.API.POST("v1/delivery/command-queue", onlinePlayersJSON, function (statusCode, response, headers)
        if statusCode >= 400 then
            PayNow.PrintError("Failed to fetch pending commands: " .. PayNow.API.ParseResponseError(response))
            return
        end

        local commands = util.JSONToTable(response or {})
        if not commands then
            PayNow.PrintError("Failed to parse JSON for pending commands: ", response)
            return
        end

        if #commands == 0 then
            return
        end

        for i, command in ipairs(commands) do
            if PayNow.CommandQueue.CheckIfCommandAlreadyExecuted(command) then
                PayNow.PrintWarning("Ignoring command " .. command.attempt_id .. ", because it's been already executed")
                continue
            end

            PayNow.CommandQueue.ExecuteCommand(command)
        end

        PayNow.CommandQueue.AcknowledgeCommands()
    end)
end

function PayNow.CommandQueue.CreateTimer()
    timer.Create("PayNow.CommandQueue.Timer", PayNow.Config.GetInterval(), 0, function ()
        if not PayNow.Config.GetToken() then return end
        if not PayNow.Initialized then return end
    
        PayNow.CommandQueue.FetchPendingCommands()
    end)
end

if (PayNow.Config.Loaded) then
    PayNow.CommandQueue.CreateTimer()
else
    hook.Add("PayNow.Config.Loaded", "PayNow.CommandQueue.PayNowConfigLoaded", function ()
        PayNow.CommandQueue.CreateTimer()
    end)
end
