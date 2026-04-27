local UserInputService = game:GetService("UserInputService")

local GHOST_TRANSPARENCY = 0.15

local AdventureCamera = {}
AdventureCamera.__index = AdventureCamera

function AdventureCamera.new(distance, height, side)
	local self = setmetatable({}, AdventureCamera)
	self.Distance = distance
	self.Height = height
	self.Side = side
	self.GhostedParts = {}
	
	-- 3D Orbit variables
	self.Yaw = 0
	self.Pitch = 0
	self.Sensitivity = 0.005 
	self.Smoothness = 0.15
	self.TurnSpeed = 0.15 

	return self
end

-- Internal helper to get the character's root
function AdventureCamera:_getRoot()
	local char = game.Players.LocalPlayer.Character
	return char and char:FindFirstChild("HumanoidRootPart")
end

-- Updates the Yaw and Pitch based on mouse movement
function AdventureCamera:_updateInput()
	local delta = UserInputService:GetMouseDelta()
	self.Yaw = self.Yaw - (delta.X * self.Sensitivity)
	self.Pitch = self.Pitch - (delta.Y * self.Sensitivity)
	self.Pitch = math.clamp(self.Pitch, math.rad(-85), math.rad(85))
end

-- Rotates the player's body 
function AdventureCamera:_updateCharacterRotation(rootPart)
	if not UserInputService:IsKeyDown(Enum.KeyCode.LeftAlt) then
		local targetRot = CFrame.Angles(0, self.Yaw, 0)
		local targetCF = CFrame.new(rootPart.Position) * targetRot
		
		rootPart.CFrame = rootPart.CFrame:Lerp(targetCF, self.TurnSpeed)
	end
end

-- Positions and aims the camera
function AdventureCamera:_applyCameraTransform(rootPart, dt)
	local camera = workspace.CurrentCamera
	local rotationCF = CFrame.fromEulerAnglesYXZ(self.Pitch, self.Yaw, 0)

	-- Calculate Position
	local goalPos = self:_checkCollisions(rootPart, rotationCF)
	
	-- Calculate Look Target
	local targetOffset = (Vector3.new(0, 2, 0)) + (rotationCF.RightVector * self.Side)
	local targetPos = rootPart.Position + targetOffset

	local lookCF = CFrame.lookAt(goalPos, targetPos)
	local alpha = 1 - math.pow(1 - self.Smoothness, dt * 60)  -- Maintains smoothness
	camera.CFrame = camera.CFrame:Lerp(lookCF, alpha)
end

-- Checks for collisions
function AdventureCamera:_checkCollisions(rootPart, rotationCF)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = {rootPart.Parent}
	
	local headPos = rootPart.Position + Vector3.new(0,2,0)
	
	local desiredOffset = rotationCF * Vector3.new(self.Side, self.Height, self.Distance)
	
	local result = workspace:Raycast(headPos, desiredOffset, params)
	
	if result then 
		return result.Position + (result.Normal * 0.5)
	else
		return headPos + desiredOffset
	end
end

-- Checks if character is blocking crosshair
function AdventureCamera:_updateGhosting(rootPart)
	local char = rootPart.Parent
	local camera = workspace.CurrentCamera

	-- 1. Reset existing ghosted parts
	for _, part in ipairs(self.GhostedParts) do
		if part:IsA("BasePart") then
			part.LocalTransparencyModifier = 0
		end
	end
	self.GhostedParts = {}

	-- 2. Setup the "Ghosting Ray"
	local rayOrigin = camera.CFrame.Position
	local rayDirection = camera.CFrame.LookVector * 15

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = {char}

	local result = workspace:Raycast(rayOrigin, rayDirection, params)

	-- 3. If the ray hits the character, make them ghostly
	if result then
		for _, item in ipairs(char:GetDescendants()) do
			if item:IsA("BasePart") then
				item.LocalTransparencyModifier = GHOST_TRANSPARENCY 
				table.insert(self.GhostedParts, item)
			end
		end
	end
end

-- Main update loop --
function AdventureCamera:Update(dt)
	local rootPart = self:_getRoot()
	if not rootPart then return end

	self:_updateInput()
	self:_updateCharacterRotation(rootPart)
	self:_applyCameraTransform(rootPart, dt)
	self:_updateGhosting(rootPart)
end

return AdventureCamera