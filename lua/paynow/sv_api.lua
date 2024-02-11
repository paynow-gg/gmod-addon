PayNow.API = PayNow.API or {}
PayNow.API.BaseURL = "https://api.paynow.gg"

function PayNow.API.ParseResponseError(response)
    if not response or #response == 0 then
        return "Unknown Error"
    end

    local parsed = util.JSONToTable(response)
    if not parsed then
        return response
    end

    return string.format("%s (code %s)", parsed.message or "Unknown", parsed.code or "Unknown")
end

function PayNow.API.HTTP(path, method, body, customHeaders, callback)
    local headers = {
        ["Content-Type"] = "application/json"
    }

    local configToken = PayNow.Config.GetToken()
    if configToken then
        headers["Authorization"] = string.format("Gameserver %s", configToken)
    end

    for key, value in pairs(customHeaders or {}) do
        headers[key] = value
    end

    HTTP({
        url = string.format("%s/%s", PayNow.API.BaseURL, path),
        method = method,
        headers = headers,
        body = body,
        success = function (statusCode, response, headers)
            if statusCode == 429 then
                -- If we are getting rate limited, increase the interval without saving
                PayNow.Config.SetInterval(PayNow.Config.GetInterval() + 10, true)
            end

            callback(statusCode, response, headers)
        end,
        type = "application/json"
    })
end

function PayNow.API.GET(path, callback)
    PayNow.API.HTTP(path, "GET", nil, nil, callback)
end

function PayNow.API.POST(path, data, callback)
    PayNow.API.HTTP(path, "POST", data, nil, callback)
end

function PayNow.API.DELETE(path, data, callback)
    PayNow.API.HTTP(path, "DELETE", data, nil, callback)
end