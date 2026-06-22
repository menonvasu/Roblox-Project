local uis = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Players = game:GetService("Players")
local player = Players.LocalPlayer

local States = {
	Idle = "Idle",
	Walking = "Walking",
	Sprinting = "Sprinting",
	Dashing  = "Dashing",
	
	-- Jumping and falling states
	Jumping = "Jumping",
	Falling = "Falling",
	Landing = "Landing",

	Casting = "Casting"
}

local STATE_SPEEDS = {
	[States.Idle] = 14,
	[States.Walking] = 14,
	[States.Sprinting] = 28,
	[States.Casting] = 14,
}

local NON_LOOPING_STATES = {
	[States.Landing] = true,
	[States.Jumping] = true,
}

local DASH_DURATION = 0.2
local DASH_COOLDOWN = 2
local DASH_FORCE_STRENGTH = 80
local NORMAL_FOV = 70
local DASH_FOV = 90
local LANDING_THRESHOLD = 5
local CAST_SPEED = 0.25

local MovementController = {}
MovementController.__index = MovementController

-------------------------------------------------------------------------------
-- INITIALIZATION
-------------------------------------------------------------------------------

function MovementController.new()
	local self = setmetatable({}, MovementController)
	
	self.Character = player.Character or player.CharacterAdded:Wait()
	self.Humanoid = self.Character:WaitForChild("Humanoid")
	
	self.CurrentState = nil
	self.CanDash = true
	self.Islanding = false
	
	-- Attributes
	self.Humanoid.UseJumpPower = true
	self.Humanoid.JumpPower = 60
	
	-- Raycast Params
	self.RayParams = RaycastParams.new();
	self.RayParams.FilterType = Enum.RaycastFilterType.Exclude
	self.RayParams.FilterDescendantsInstances = {self.Character}
	
	-- Setup animations
	self.AnimationTracks = {
		Normal = {},
		Staff = {}
	}
	self.CurrentStance = "Normal"
	self.ActiveTrack = nil

	-- connections for listener
	self.Connections = {}
	
	local animFolder = game.ReplicatedStorage:WaitForChild("MovementAnims")
	local animator = self.Humanoid:WaitForChild("Animator") :: Animator
	for _, stateName in pairs(States) do
		local animNormal = animFolder:FindFirstChild(stateName)
		local animStaff = animFolder:FindFirstChild("Staff_" .. stateName)
		if animNormal then
			self.AnimationTracks.Normal[stateName] = animator:LoadAnimation(animNormal)
		end
		if animStaff then
			self.AnimationTracks.Staff[stateName] = animator:LoadAnimation(animStaff)
		end
	end
	
	local equipAnim = animFolder:FindFirstChild("Staff_Equip")
	if equipAnim then
		self.EquipTrack = animator:LoadAnimation(equipAnim)
		self.EquipTrack.Priority = Enum.AnimationPriority.Action
		self.EquipTrack.Looped = false
	end
	
	-- Cleanup defaults
	local defaultAnimate = self.Character:FindFirstChild("Animate")
	if defaultAnimate then defaultAnimate:Destroy() end

	self.AnimationTracks.Normal[States.Casting] = self.AnimationTracks.Normal[States.Walking]
	self.AnimationTracks.Staff[States.Casting] = self.AnimationTracks.Staff[States.Walking]

	--Set state to idle
	self:_SetState(States.Idle)
	return self
end

-------------------------------------------------------------------------------
-- CORE LOGIC
-------------------------------------------------------------------------------

function MovementController:IsBusy()
	return self.CurrentState == States.Dashing or self.Islanding or self.CurrentState == States.Casting
end

-- Updates state based on input
function MovementController:_UpdateStateFromInput() 
	if self:IsBusy() then return end 

	if self.Humanoid.FloorMaterial == Enum.Material.Air then
		self:_SetState(self:_GetAirState())
	else
		self:_SetState(self:_GetGroundState())
	end
end

-- Core state logic 
function MovementController:_SetState(newState)
	if self.CurrentState == newState then return end

	-- Handle Landing Lock
	if newState == States.Landing then
		self.Islanding = true
		
		task.delay(self.AnimationTracks.Normal[States.Landing].Length, function()
			self.Islanding = false
		end)
	end
	
	-- Handles transitions
	local speed = STATE_SPEEDS[newState]
	if speed then
		self.Humanoid.WalkSpeed = speed
	end
	
	-- Update the tracking variable
	self.CurrentState = newState
	self:_UpdateAnimation()
end

-------------------------------------------------------------------------------
-- HELPERS
-------------------------------------------------------------------------------

function MovementController:_GetDistanceToGround()
	local root = self.Character:FindFirstChild("HumanoidRootPart")
	if not root then return math.huge end

	local footPos = root.Position + Vector3.new(0, -2, 0)
	local result = workspace:Raycast(footPos, Vector3.new(0, -10, 0), self.RayParams)

	return result and result.Distance or math.huge
end

-- Helper function for air state
function MovementController:_GetAirState()
	local root = self.Character:FindFirstChild("HumanoidRootPart")
	local velocityY = root.AssemblyLinearVelocity.Y
	
	if velocityY > 0 then 
		return States.Jumping 
	end
	
	local dist = self:_GetDistanceToGround()
	if dist < LANDING_THRESHOLD and velocityY < -50 then
		return States.Landing
	end

	return States.Falling
end

-- Helper function for ground state
function MovementController:_GetGroundState() 
	if self.Humanoid.MoveDirection.Magnitude > 0 then
		local isSprinting = uis:IsKeyDown(Enum.KeyCode.LeftShift)
		return isSprinting and States.Sprinting or States.Walking
	end
	return States.Idle
end

function MovementController:_UpdateAnimation()
	local currentStanceTable = self.AnimationTracks[self.CurrentStance]
	if not currentStanceTable then return end
	
	local newTrack = currentStanceTable[self.CurrentState]
	
	if newTrack and self.ActiveTrack ~= newTrack then
		local fadeTime = (self.CurrentState == States.Landing) and 0.05 or 0.3
		
		if self.ActiveTrack then self.ActiveTrack:Stop(fadeTime) end
		
		self.ActiveTrack = newTrack
		--Only loop things that aren't land and jump animations
		self.ActiveTrack.Looped = not NON_LOOPING_STATES[self.CurrentState]
		self.ActiveTrack:Play(fadeTime)

		if self.CurrentState == States.Casting then
			self.ActiveTrack:AdjustSpeed(CAST_SPEED) -- slow legs down 
		else
			self.ActiveTrack:AdjustSpeed(1.0) -- restore normal speed
		end
		
	end
	print(self.CurrentState)
end

-------------------------------------------------------------------------------
-- DASH & VISUALS
-------------------------------------------------------------------------------

-- Handles dashing
function MovementController:_Dash()
	if not self.CanDash or self.CurrentState == States.Dashing then return end

	self.CanDash = false
	task.delay(DASH_COOLDOWN, function() self.CanDash = true end)

	local rootPart = self.Character:WaitForChild("HumanoidRootPart")
	local camera = workspace.CurrentCamera
	local previousState = self.CurrentState

	local dashDirection = (self.Humanoid.MoveDirection.Magnitude == 0) and rootPart.CFrame.LookVector or self.Humanoid.MoveDirection

	-- FOV Effect
	self:_ToggleDashVisuals(true, camera)
	self:_SetState(States.Dashing)

	-- Apply Physics (spawn to not block)
	task.spawn(function() 
		self:_ApplyForce(rootPart, dashDirection, DASH_FORCE_STRENGTH, DASH_DURATION) 
	end)

	task.wait(DASH_DURATION)

	-- Cleanup visuals and state
	self:_ToggleDashVisuals(false, camera)
	self:_SetState(previousState)
end

-- Applies force to the player
function MovementController:_ApplyForce(rootPart, direction, strength, duration)
	-- Sets Force
	local attachment = Instance.new("Attachment")
	attachment.Parent = rootPart

	local velocity = Instance.new("LinearVelocity")
	velocity.MaxForce = 75000
	velocity.VectorVelocity = direction * strength
	velocity.Attachment0 = attachment
	velocity.Parent = attachment

	task.wait(duration)

	-- Cleanup
	velocity:Destroy()
	attachment:Destroy()
end

-- Handles visual effects during dash
function MovementController:_ToggleDashVisuals(enabled, camera)
	if enabled then
		-- FOV Effect
		TweenService:Create(camera, TweenInfo.new(0.18, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {FieldOfView = DASH_FOV}):Play()

		-- Ghost Effect
		task.spawn(function()
			for i = 1, 4 do
				self:_CreateGhost()
				task.wait(DASH_DURATION / 4)
			end
		end)
	else 
		-- Resets FOV
		TweenService:Create(camera, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {FieldOfView = NORMAL_FOV}):Play()
	end	
end

-- Creates a ghost of the player during dash
function MovementController:_CreateGhost()
	-- Safety check
	local character = player.Character
	if not character then return end
	
	local ignoreFolder = workspace:FindFirstChild("CameraIgnore")
	if not ignoreFolder then
		ignoreFolder = Instance.new("Folder")
		ignoreFolder.Name = "CameraIgnore"
		ignoreFolder.Parent = workspace
	end
	
	character.Archivable = true
	local ghostModel = player.Character:Clone()

	local humanoid = ghostModel:FindFirstChildOfClass("Humanoid")
	if humanoid then humanoid:Destroy() end
	
	-- Get parts and remove unnecessary stuff
	for _, part in pairs(ghostModel:GetDescendants()) do
		if part:IsA("LuaSourceContainer") or part:IsA("Accessory") then
			part:Destroy()
		
		elseif part:IsA("BasePart")  and part.Name ~= "HumanoidRootPart" then
			-- Align to player
			local realPart = player.Character:FindFirstChild(part.Name)
			if realPart and realPart:IsA("BasePart") then
				part.CFrame = realPart.CFrame
			
				part.Material = Enum.Material.Neon
				part.CanCollide = false
				part.Anchored = true
				part.Transparency = 0.5
				part.Color = Color3.fromRGB(163, 163, 163)
				
				-- Tween in transparency
				local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Cubic,Enum.EasingDirection.Out)
				local tween = TweenService:Create(part, tweenInfo, {Transparency = 1})
				
				tween:Play()
				
			else
				part:Destroy()
			end
			
		elseif part:IsA("Decal") then
			part.Transparency = 1
		end
		
	end
	
	ghostModel.Parent = ignoreFolder
	-- Cleanup
	task.delay(0.6, function()
		ghostModel:Destroy()
	end)
	
end

-------------------------------------------------------------------------------
-- PUBLIC API
-------------------------------------------------------------------------------

-- Locks or unlocks the movement state for spell casting
function MovementController:SetCasting(isCasting) 
	if isCasting then
		self:_SetState(States.Casting)
	else
		self:_SetState(States.Idle)
	end
end

-- Listens for input
function MovementController:Listener()
	local staffStateEvent = game.ReplicatedStorage.LocalEvents.StaffStateChanged

	local inputConnection = uis.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end

		if input.KeyCode == Enum.KeyCode.Q then
			self:_Dash()
		end
	end)

	local preSimulationConnection = RunService.PreSimulation:Connect(function()
		self:_UpdateStateFromInput()
	end)
	
	local staffStateConnection = staffStateEvent.Event:Connect(function(isEquipped)
		if isEquipped then
			self.CurrentStance = "Staff"
			if self.EquipTrack then
				self.EquipTrack:Play()	
			end
			print("Playing equip animation...")
		else
			if self.EquipTrack then
				self.EquipTrack.TimePosition = self.EquipTrack.Length
				self.EquipTrack:Play(0.10, 1, -1)
			end
			

			self.CurrentStance = "Normal"
			print("Stopping staff state...")
		end
		
		self:_UpdateAnimation()
	end)

	table.insert(self.Connections, inputConnection) 
	table.insert(self.Connections, preSimulationConnection)
	table.insert(self.Connections, staffStateConnection)
end

-- Clear all connections
function MovementController:Destroy() 
	for _, connection in pairs(self.Connections) do
		connection:Disconnect()
	end
end

return MovementController

