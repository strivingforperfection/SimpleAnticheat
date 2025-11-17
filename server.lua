--author: striving
--place inside of serverscriptservice
local httpservice = game:GetService("HttpService")
local players = game:GetService("Players")
local localizationservice = game:GetService("LocalizationService")
local replicatedstorage = game:GetService("ReplicatedStorage")

local hook = ""
local kickedplayers = {}

--create remote event
local detectionremote = Instance.new("RemoteEvent")
detectionremote.Name = "RequestData" --gave it this name because naming it something like "AntiCheatDetection" would be obvious to players using Dex
detectionremote.Parent = replicatedstorage

local function sendlog(player, detection)
	if kickedplayers[player.UserId] then
		return
	end

	kickedplayers[player.UserId] = true
	print("Kicking player: " .. player.Name .. " - " .. detection)

	local countrycode = nil

	local success1, result1 = pcall(function()
		return localizationservice:GetCountryRegionForPlayerAsync(player)
	end)

	if success1 and result1 and result1 ~= "" then
		countrycode = result1
	else
		local success2, result2 = pcall(function()
			return players:GetPlayerCountryRegionAsync(player)
		end)

		if success2 and result2 and result2 ~= "" then
			countrycode = result2
		end
	end

	--convert country code to full name
	local countrynames = {
		["US"] = "United States",
		["GB"] = "United Kingdom",
		["CA"] = "Canada",
		["AU"] = "Australia",
		["DE"] = "Germany",
		["FR"] = "France",
		["ES"] = "Spain",
		["IT"] = "Italy",
		["NL"] = "Netherlands",
		["SE"] = "Sweden",
		["NO"] = "Norway",
		["DK"] = "Denmark",
		["FI"] = "Finland",
		["PL"] = "Poland",
		["BR"] = "Brazil",
		["MX"] = "Mexico",
		["AR"] = "Argentina",
		["CL"] = "Chile",
		["CO"] = "Colombia",
		["PE"] = "Peru",
		["IN"] = "India",
		["CN"] = "China",
		["JP"] = "Japan",
		["KR"] = "South Korea",
		["TH"] = "Thailand",
		["VN"] = "Vietnam",
		["PH"] = "Philippines",
		["ID"] = "Indonesia",
		["MY"] = "Malaysia",
		["SG"] = "Singapore",
		["NZ"] = "New Zealand",
		["ZA"] = "South Africa",
		["RU"] = "Russia",
		["UA"] = "Ukraine",
		["TR"] = "Turkey",
		["SA"] = "Saudi Arabia",
		["AE"] = "United Arab Emirates",
		["IL"] = "Israel",
		["EG"] = "Egypt",
		["NG"] = "Nigeria",
		["KE"] = "Kenya",
		["PT"] = "Portugal",
		["GR"] = "Greece",
		["CZ"] = "Czech Republic",
		["RO"] = "Romania",
		["HU"] = "Hungary",
		["AT"] = "Austria",
		["CH"] = "Switzerland",
		["BE"] = "Belgium",
		["IE"] = "Ireland",
		["HK"] = "Hong Kong",
		["TW"] = "Taiwan"
	}

	local country = countrynames[countryCode] or countryCode

	local data = {
		["embeds"] = {{
			["title"] = "Player Disconnected",
			["color"] = 16776960, --yellow
			["fields"] = {
				{
					["name"] = "Reason",
					["value"] = detection,
					["inline"] = false
				},	
				{
					["name"] = "Country",
					["value"] = country,
					["inline"] = false
				},
				{
					["name"] = "User",
					["value"] = "[" .. player.Name .. "](https://roblox.com/users/" .. tostring(player.UserId) .. "/profile)",
					["inline"] = false
				}
			},
		}}
	}

	local success, err = pcall(function()
		httpservice:PostAsync(hook, httpservice:JSONEncode(data), Enum.HttpContentType.ApplicationJson)
	end)

	if not success then
		warn("failed to send webhook: " .. tostring(err))
	end

	player:Kick() --player:Kick(detection) if you want
end

--listen for detections from client
detectionremote.OnServerEvent:Connect(function(player, reason)
	if typeof(reason) ~= "string" then
		return
	end

	sendlog(player, reason)
end)

players.PlayerRemoving:Connect(function(player)
	if kickedplayers[player.UserId] then
		kickedplayers[player.UserId] = nil
	end
end)
