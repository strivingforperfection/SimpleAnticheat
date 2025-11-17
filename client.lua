--author: striving
--put in starterplayerscripts
local players = game:GetService("Players")
local runservice = game:GetService("RunService")
local replicatedstorage = game:GetService("ReplicatedStorage")

local player = players.LocalPlayer
local detectionremote = replicatedstorage:WaitForChild("RequestData", 10) --if you really want to, make it use a remote that actually does stuff to make the game functional

if not detectionremote then
	return
end


local function detectexploit(reason)
	detectionremote:FireServer(reason)
end

local function isinwater(position)
	local terrain = workspace.Terrain
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

task.wait(2) --wait for character to load

local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local hrp = character:WaitForChild("HumanoidRootPart")
local torso = character:FindFirstChild("Torso") or character:FindFirstChild("UpperTorso")
local animate = character:FindFirstChild("Animate")


local swimchecktick = 0
local kicked = false

runservice.Heartbeat:Connect(function()
	if kicked then return end

	--recheck parts in case they were removed
	if not character or not character.Parent then return end
	torso = character:FindFirstChild("Torso") or character:FindFirstChild("UpperTorso")
	hrp = character:FindFirstChild("HumanoidRootPart")
	animate = character:FindFirstChild("Animate")

	--check for BodyGyro in torso
	if torso and torso:FindFirstChildOfClass("BodyGyro") then
		kicked = true
		detectexploit("BodyGyro found in user Torso")
		return
	end

	--check for BodyVelocity in torso
	if torso and torso:FindFirstChildOfClass("BodyVelocity") then
		kicked = true
		detectexploit("BodyVelocity found in user Torso")
		return
	end

	--check for BodyGyro in HumanoidRootPart
	if hrp and hrp:FindFirstChildOfClass("BodyGyro") then
		kicked = true
		detectexploit("BodyGyro found in user HumanoidRootPart")
		return
	end

	--check for BodyVelocity in HumanoidRootPart
	if hrp and hrp:FindFirstChildOfClass("BodyVelocity") then
		kicked = true
		detectexploit("BodyVelocity found in user HumanoidRootPart")
		return
	end

	--check walkspeed
	if humanoid and humanoid.WalkSpeed > 20 then
		kicked = true
		detectexploit("Walkspeed < 20")
		return
	end

	--check jumppower
	if humanoid and humanoid.JumpPower > 50 then
		kicked = true
		detectexploit("JumpPower < 65")
		return
	end

	--check if animate script is disabled
	if animate and not animate.Enabled then
		kicked = true
		detectexploit("Animate script disabled")
		return
	end

	--swim detection (check every second)
	swimchecktick = swimchecktick + 1
	if swimchecktick >= 60 then
		swimchecktick = 0

		if hrp and humanoid and humanoid:GetState() == Enum.HumanoidStateType.Swimming then
			local inwater = isinwater(hrp.Position)

			if not inwater then
				kicked = true
				detectexploit("Player found swimming outside of water")
				return
			end
		end
	end
end)
