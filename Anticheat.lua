--author: striving
--anticheat based off of soup's anticheat for Heli-Wars
local httpservice = game:GetService("HttpService")
local players = game:GetService("Players")
local hook = "https://discord.com/api/webhooks/1439397491215831142/paYcZlFj-_2ZjsqTuJqzDHqD-5XljqDV-dqO7GX-ONNhPdeytLKtfHqT2-mJutTN2jOZ"
local kickedplayers = {} 

local function sendlog(player, detection)
	if kickedplayers[player.UserId] then
		return
	end

	kickedplayers[player.UserId] = true
	print("kicking player: " .. player.Name .. " - " .. detection)

	local data = {
		["embeds"] = {{
			["title"] = "Player kicked",
			["color"] = 16776960, --yelow
			["fields"] = {
				{
					["name"] = "Reason",
					["value"] = detection,
					["inline"] = false
				},
				{
					["name"] = "User",
					["value"] = player.Name,
					["inline"] = false
				}
			},
			["timestamp"] = os.date("!%Y-%m-%dT%H:%M:%S")
		}}}

	local success, err = pcall(function()
		httpservice:PostAsync(hook, httpservice:JSONEncode(data), Enum.HttpContentType.ApplicationJson)
	end)

	if not success then
		warn("failed to send webhook: " .. tostring(err))
	end

	player:Kick(detection)
end

local function isinwater(position)
	local terrain = game.Workspace.Terrain
	local region = Region3.new(position - Vector3.new(2, 2, 2), position + Vector3.new(2, 2, 2))
	region = region:ExpandToGrid(4)

	local materials, sizes = terrain:ReadVoxels(region, 4)
	local size = materials.Size

	for x = 1, size.X do
		for y = 1, size.Y do
			for z = 1, size.Z do
				if materials[x][y][z] == Enum.Material.Water then
					return true
				end
			end
		end
	end

	return false
end

local function setupcharacter(player, character)
	local humanoid = character:WaitForChild("Humanoid", 5)
	local torso = character:FindFirstChild("Torso")
	local hrp = character:FindFirstChild("HumanoidRootPart")
	local animate = character:FindFirstChild("Animate")

	if not humanoid then return end

	--check torso for existing bodygyro/bodyvelocity
	if torso then
		if torso:FindFirstChildOfClass("BodyGyro") then
			sendlog(player, "BodyGyro detected in torso")
		end
		if torso:FindFirstChildOfClass("BodyVelocity") then
			sendlog(player, "BodyVelocity detected in torso")
		end

		--monitor torso for new bodygyro/bodyvelocity
		torso.ChildAdded:Connect(function(child)
			if child:IsA("BodyGyro") then
				sendlog(player, "BodyGyro detected in torso")
			elseif child:IsA("BodyVelocity") then
				sendlog(player, "BodyVelocity added in torso")
			end
		end)
	end

	--check hrp for existing bodygyro/bodyvelocity
	if hrp then
		if hrp:FindFirstChildOfClass("BodyGyro") then
			sendlog(player, "BodyGyro detected in HumanoidRootPart")
		end
		if hrp:FindFirstChildOfClass("BodyVelocity") then
			sendlog(player, "BodyVelocity detected in HumanoidRootPart")
		end

		--monitor hrp for new bodygyro/bodyvelocity
		hrp.ChildAdded:Connect(function(child)
			if child:IsA("BodyGyro") then
				sendlog(player, "BodyGyro detected in HumanoidRootPart")
			elseif child:IsA("BodyVelocity") then
				sendlog(player, "BodyVelocity detected in HumanoidRootPart")
			end
		end)
	end

	--check initial walkspeed and jumppower
	if humanoid.WalkSpeed > 20 then
		sendlog(player, "Walkspeed over 20 (current: " .. tostring(humanoid.WalkSpeed) .. ")")
	end

	if humanoid.JumpPower > 50 then
		sendlog(player, "JumpPower over 50 (current: " .. tostring(humanoid.JumpPower) .. ")")
	end

	--check if animate is disabled
	if animate and not animate.Enabled then
		sendlog(player, "Animate script disabled")
	end

	--monitor walkspeed changes
	humanoid:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
		if humanoid.WalkSpeed > 20 then
			sendlog(player, "Walkspeed over 20 (current: " .. tostring(humanoid.WalkSpeed) .. ")")
		end
	end)

	--monitor jumppower changes
	humanoid:GetPropertyChangedSignal("JumpPower"):Connect(function()
		if humanoid.JumpPower > 50 then
			sendlog(player, "JumpPower over 50 (current: " .. tostring(humanoid.JumpPower) .. ")")
		end
	end)

	--monitor animate script
	if animate then
		animate:GetPropertyChangedSignal("Enabled"):Connect(function()
			if not animate.Enabled then
				sendlog(player, "Animate script disabled")
			end
		end)
	end

	--swim detection
	task.spawn(function()
		task.wait(3) 

		while player and player.Parent and character.Parent do
			task.wait(1)

			if not hrp or not hrp.Parent then break end

			--detect swimming outside of water
			if humanoid:GetState() == Enum.HumanoidStateType.Swimming then
				task.wait(1) --wait longer to avoid false positives when jumping into water
				
				if humanoid:GetState() == Enum.HumanoidStateType.Swimming then
					local inwater = isinwater(hrp.Position)

					if not inwater then
						sendlog(player, "Player was found swimming.")
						return
					end
				end
			end
		end
	end)
end

--setup for existing players
for _, player in pairs(players:GetPlayers()) do
	if player.Character then
		setupcharacter(player, player.Character)
	end

	player.CharacterAdded:Connect(function(character)
		setupcharacter(player, character)
	end)
end

--setup for new players
players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		setupcharacter(player, character)
	end)
end)

--cleanup
players.PlayerRemoving:Connect(function(player)
	if kickedplayers[player.UserId] then
		kickedplayers[player.UserId] = nil
	end
end)
