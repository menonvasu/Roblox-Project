local UserInputService = game:GetService("UserInputService")
local players = game:GetService("Players")

-- Constants
local PITCH_LIMIT = math.rad(85)
local CAMERA_RESPONSIVENESS = 0.4
local VERTICAL_SMOOTHNESS = 0.3
local SIDE_SMOOTHNESS = 0.25
local FOV_SMOOTHNESS = 0.1

local AdventureCamera = {}
AdventureCamera.__index = AdventureCamera

-------------------------------------------------------------------------------
-- INITIALIZATION
-------------------------------------------------------------------------------

function AdventureCamera.new(distance, height, side)
	local self = setmetatable({}, AdventureCamera)
	
	-- Configurable Properties
	self.Distance = distance
	self.Height = height
	self.Side = side
	
	-- State variables
	self.Yaw = 0
	self.Pitch = 0
	self.LastRootY = 0
	self.CurrentSide = side
	self.RootPart = nil
	
	-- Internal settings
	self.Sensitivity = 0.005
	
	-- Setup character listeners
	local player = game.Players.LocalPlayer
	player.CharacterAdded:Connect(function(char)
		self:_onCharacterAdded(char)
	end)

	-- Handle the current character if they already exist
	if player.Character then
		self:_onCharacterAdded(player.Character)
	end
	
	return self
end

function AdventureCamera:_onCharacterAdded(char)
	local humanoid = char:WaitForChild("Humanoid")
	self.RootPart = char:WaitForChild("HumanoidRootPart")

	self.LastRootY = self.RootPart.Position.Y
	humanoid.AutoRotate = false -- Manual rotation alignment
end

-------------------------------------------------------------------------------
-- CORE LOGIC
-------------------------------------------------------------------------------

-- Updates the Yaw and Pitch based on mouse movement
function AdventureCamera:_UpdateInput()
	local delta = UserInputService:GetMouseDelta()
	self.Yaw = self.Yaw - (delta.X * self.Sensitivity)
	self.Pitch = self.Pitch - (delta.Y * self.Sensitivity)
	self.Pitch = math.clamp(self.Pitch, -PITCH_LIMIT, PITCH_LIMIT)
end

function AdventureCamera:_ApplyTransform(dt)
	local camera = workspace.CurrentCamera
	local currentPos = self.RootPart.Position

	-- 1. Rotation and Vertical Calculations
	local rotationCF = CFrame.fromEulerAnglesYXZ(self.Pitch, self.Yaw, 0)
	local cameraHeight = self.LastRootY + self.Height
	local headLevel = currentPos.Y + self.Height

	-- 2. Position Calculation
	local stableCenter = Vector3.new(currentPos.X, cameraHeight, currentPos.Z)
	local orbitOffset = rotationCF * Vector3.new(self.CurrentSide, 0, self.Distance)
	local cameraDesiredPos = stableCenter + orbitOffset

	-- 3. Collision and Final CFrame
	local finalCameraPos = self:_CheckCollisions(rotationCF, cameraDesiredPos)
	local lookAtPoint = Vector3.new(currentPos.X, headLevel, currentPos.Z) + (rotationCF.LookVector * 100)

	local targetCF = CFrame.lookAt(finalCameraPos, lookAtPoint)

	-- 4. Smoothing Assignment
	local alpha = 1 - math.pow(1 - CAMERA_RESPONSIVENESS, dt * 60)
	camera.CFrame = camera.CFrame:Lerp(targetCF, alpha)
end

function AdventureCamera:_UpdateVisuals(dt)
	local camera = workspace.CurrentCamera
	local velocity = self.RootPart.AssemblyLinearVelocity.Magnitude

	-- Dynamic FOV based on speed
	local targetFOV = (velocity > 20) and 80 or 75
	local alpha = 1 - math.pow(1 - FOV_SMOOTHNESS, dt * 60)

	camera.FieldOfView = camera.FieldOfView + (targetFOV - camera.FieldOfView) * alpha
end

-------------------------------------------------------------------------------
-- HELPERS
-------------------------------------------------------------------------------

function AdventureCamera:_CheckCollisions(rotationCF, cameraDesiredPos)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	
	-- Setup Ignore List
	local ignoreList = {self.RootPart.Parent} 
	local ignoreFolder = workspace:FindFirstChild("CameraIgnore")
	if ignoreFolder then table.insert(ignoreList, ignoreFolder) end 
	params.FilterDescendantsInstances = ignoreList

	-- Raycast from character to camera
	local origin = self.RootPart.Position + Vector3.new(0, 2, 0)
	local direction = cameraDesiredPos - origin
	local result = workspace:Raycast(origin, direction, params)

	return result and (result.Position + (result.Normal * 0.5)) or cameraDesiredPos
end

function AdventureCamera:_UpdateVerticalShift(dt)
	local humanoid = self.RootPart.Parent:FindFirstChild("Humanoid")
	local state = humanoid:GetState()
	local isInAir = state == Enum.HumanoidStateType.Jumping or state == Enum.HumanoidStateType.Freefall

	local targetY = self.RootPart.Position.Y

	if isInAir then
		-- Snap camera height to player during high-velocity vertical movement
		self.LastRootY = targetY
	else
		-- Smooth vertical tracking
		local alpha = 1 - math.pow(1 - VERTICAL_SMOOTHNESS, dt * 60)
		self.LastRootY = self.LastRootY + (targetY - self.LastRootY) * alpha
	end
end

function AdventureCamera:_UpdateSideOffset(dt)
	local alpha = 1 - math.pow(1 - SIDE_SMOOTHNESS, dt * 60)
	self.CurrentSide = self.CurrentSide + (self.Side - self.CurrentSide) * alpha
end

function AdventureCamera:_AlignCharacter()
	local targetRotation = CFrame.Angles(0, self.Yaw, 0)
	self.RootPart.CFrame = CFrame.new(self.RootPart.Position) * targetRotation
end

-------------------------------------------------------------------------------
-- PUBLIC API
-------------------------------------------------------------------------------

function AdventureCamera:Update(dt)
	if not self.RootPart then return end

	-- Input and Character Orientation
	self:_UpdateInput()
	self:_AlignCharacter()

	-- Positional Offsets
	self:_UpdateSideOffset(dt)
	self:_UpdateVerticalShift(dt)

	-- Final Camera Placement
	self:_ApplyTransform(dt)
	self:_UpdateVisuals(dt)
end

return AdventureCamera

