local uis = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Players = game:GetService("Players")
local player = Players.LocalPlayer

local States = {
	Idle = "Idle",
	Walking = "Walking",
	Sprinting = "Sprinting",
	Dashing  = "Dashing"
}

local STATE_SPEEDS = {
	[States.Idle] = 14,
	[States.Walking] = 14,
	[States.Sprinting] = 28,
}

local DASH_DURATION = 0.2
local DASH_COOLDOWN = 2
local DASH_FORCE_STRENGTH = 80
local NORMAL_FOV = 70
local DASH_FOV = 90
	
local MovementController = {}
MovementController.__index = MovementController

function MovementController.new()
	local self = setmetatable({}, MovementController)
	
	self.Player = player
	self.Character = player.Character or player.CharacterAdded:Wait()
	self.Humanoid = self.Character:WaitForChild("Humanoid")
	
	self.CurrentState = States.Idle
	self.CanDash = true
	
	self.AnimationTracks = {}
	self.ActiveTrack = nil
	
	local animFolder = game.ReplicatedStorage:WaitForChild("MovementAnims")
	self.AnimationTracks[States.Walking] = self.Humanoid:LoadAnimation(animFolder.Walk)
	
	-- Remove animate script
	local defaultAnimate = self.Character:FindFirstChild("Animate")
	if defaultAnimate then
		defaultAnimate:Destroy()
	end

	return self
end

-- Core state logic 
function MovementController:_SetState(newState)
	if self.CurrentState == newState then return end

	-- Handles transitions
	local speed = STATE_SPEEDS[newState]
	if speed then
		self.Humanoid.WalkSpeed = speed
	end
	
	-- Update the tracking variable
	self.CurrentState = newState
	print("Movement State: " .. self.CurrentState)
	self:_UpdateAnimation()
end

function MovementController:_UpdateAnimation()
	local newTrack = self.AnimationTracks[self.CurrentState]
	
	if self.ActiveTrack and self.ActiveTrack ~= newTrack then
		self.ActiveTrack:Stop(0.3)
	end
	
	if newTrack and not newTrack.IsPlaying then
		newTrack:Play(0.2)
		self.ActiveTrack = newTrack
	end
end

-- Creates a ghost of the player during dash
function MovementController:_CreateGhost()
	-- Safety check
	local character = player.Character
	if not character then return end
	
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
	
	ghostModel.Parent = workspace
	-- Cleanup
	task.delay(0.6, function()
		ghostModel:Destroy()
	end)
	
end

-- Handles visual effects during dash
function MovementController:_ToggleDashVisuals(enabled, camera, rootPart)
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

-- Applies force to the player
function MovementController:_ApplyForce(rootPart, direction, strength, duration)
	-- Sets Force
	local attachment = Instance.new("Attachment", rootPart)
	local velocity = Instance.new("LinearVelocity", attachment)
	velocity.MaxForce = 1000000
		
	velocity.VectorVelocity = direction * strength
	velocity.Attachment0 = attachment
	
	task.wait(duration)
	
	-- Cleanup
	velocity:Destroy()
	attachment:Destroy()
end

-- Handles dashing
function MovementController:_Dash()
	if not self.CanDash or self.CurrentState == States.Dashing then return end
	
	self.CanDash = false
	task.delay(DASH_COOLDOWN, function()
		self.CanDash = true
	end)
	
	local rootPart = self.Character:WaitForChild("HumanoidRootPart")
	local camera = workspace.CurrentCamera
	local previousState = self.CurrentState
	
	local dashDirection = (self.Humanoid.MoveDirection.Magnitude == 0) and rootPart.CFrame.LookVector or self.Humanoid.MoveDirection
		
	-- FOV Effect
	self:_ToggleDashVisuals(true, camera, rootPart)
	self:_SetState(States.Dashing)
	
	-- Apply Physics (spawn to not block)
	task.spawn(function()
		self:_ApplyForce(rootPart, dashDirection, DASH_FORCE_STRENGTH, DASH_DURATION)
	end)
	
	task.wait(DASH_DURATION)
	
	-- Cleanup visuals and state
	self:_ToggleDashVisuals(false, camera, rootPart)
	self:_SetState(previousState)
end

-- Updates state based on input
function MovementController:_UpdateStateFromInput() 
	if(self.CurrentState == States.Dashing) then return end

	if self.Humanoid.MoveDirection.Magnitude > 0 then
		if uis:IsKeyDown(Enum.KeyCode.LeftShift) then
			self:_SetState(States.Sprinting)
		else
			self:_SetState(States.Walking)
		end
	else
		self:_SetState(States.Idle)
	end
end

-- Listens for input
function MovementController:Listener()
	uis.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
	
		if input.KeyCode == Enum.KeyCode.Q then
			self:_Dash()
		end
	end)
	
	RunService.PreSimulation:Connect(function()
		self:_UpdateStateFromInput()
	end)
end

return MovementController
