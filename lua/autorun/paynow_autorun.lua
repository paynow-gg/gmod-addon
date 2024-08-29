PayNow = PayNow or {}

PayNow.Debug = false
PayNow.Version = "0.0.2"
PayNow.BrandColor = Color(255, 73, 255)

function PayNow.Load(dir, svOnly, shOnly)
	local files = file.Find(dir.. "/".. "*", "LUA")

	for k, v in pairs(files) do
		if string.StartWith(v, "cl") then
			AddCSLuaFile(dir.. "/".. v)

			if CLIENT then
				local load = include(dir.. "/".. v)
				if load then load() end
			end
		end

		if string.StartWith(v, "sv") or svOnly then
			if SERVER then
				local load = include(dir.. "/".. v)
				if load then load() end
			end
		end

		if string.StartWith(v, "sh") or shOnly then
			AddCSLuaFile(dir.. "/".. v)

			local load = include(dir.. "/".. v)
			if load then load() end
		end
	end
end

function PayNow.PrintError(...)
	MsgC(Color(192, 57, 43), "[PayNow] (ERROR): ", color_white, ..., "\n")
end

function PayNow.PrintWarning(...)
	MsgC(Color(255, 122, 0), "[PayNow] (WARNING): ", color_white, ..., "\n")
end

function PayNow.PrintDebug(...)
	if (!PayNow.Debug) then return end

	MsgC(Color(120, 255, 120), "[PayNow] (DEBUG): ", color_white, ..., "\n")
end

function PayNow.Print(...)
	MsgC(PayNow.BrandColor, "[PayNow]: ", color_white, ..., "\n")
end

-- Include the actual addon files

function PayNow.LoadAddon()
    include("paynow/sv_config.lua")
    PayNow.Config.Load()
    
    PayNow.Load("paynow")
end

PayNow.LoadAddon()