local setupTokenText = {
    "\n",
    Color(255, 0, 0),
    "You have not configured your PayNow Game Server token yet. \n",
    color_white,
    "\n",
    "To connect your Garry's Mod server to PayNow: \n",
    "1. Create a game server @ https://dashboard.paynow.gg/gameservers \n",
    "2. Copy the generated token \n",
    "3. Execute the following command in console: \n",
    PayNow.BrandColor,
    "paynow.token <your-token-here> \n",
    "\n"
}

local tokenFailureText = {
    "\n",
    Color(255, 0, 0),
    "Failed to connect to PayNow using your token. \n",
    color_white,
    "\n",
    "Possible solutions: \n",
    "1. Make sure your gameserver is enabled @ https://dashboard.paynow.gg/gameservers \n",
    "2. Your token might be copied incorrectly. \n",
    "3. You might've resetted (rotated) your token. \n",
    "4. Try updating the PayNow addon to the latest version. \n",
    "You can reset your PayNow token using the following command: \n",
    PayNow.BrandColor,
    "paynow.token <your-token-here> \n",
    "\n"
}

local function initPayNow()
    if PayNow.Initialized then return end
    PayNow.Initialized = true

    local token = PayNow.Config.GetToken()
    if not token then
        MsgC(PayNow.BrandColor, "\n[PayNow]: \n", color_white, unpack(setupTokenText))
        return
    end

    PayNow.Config.ValidateToken(token, function (success)
        if not success then
            MsgC(PayNow.BrandColor, "\n[PayNow]: \n", color_white, unpack(tokenFailureText))
        else
            PayNow.Print("Successfully validated PayNow token!")
            PayNow.Link.LinkGameServer()
        end
    end)

    local thinkWhileHibernating = GetConVar("sv_hibernate_think"):GetBool()
    if not thinkWhileHibernating then
        PayNow.Print("PayNow will start listening for commands once someone joins the server (sv_hibernate_think disabled).")
    end
end

local function waitForConfigLoadAndThenInit()
    if (PayNow.Config.Loaded) then
        initPayNow()
    else
        hook.Add("PayNow.Config.Loaded", "PayNow.Setup.PayNowConfigLoaded", function ()
            initPayNow()
        end)
    end
end

-- We listen for an InitPostEntity hook AND a 30 timer simple delay
-- just to make sure initPayNow() gets called, probably useless, but whatever
-- (we need to run this delayed because game.GetIPAddress() might not be available,
-- and we don't want to run commands prematurely until all addons are loaded)
hook.Add("InitPostEntity", "PayNow.Setup.InitPostEntity", function ()
    -- Wait for a while.. game.GetIPAddress() is likely not available yet
    -- and some plugins might still keep loading
    timer.Simple(5, function ()
        waitForConfigLoadAndThenInit()
    end)
end)

timer.Simple(30, function ()
    waitForConfigLoadAndThenInit()
end)