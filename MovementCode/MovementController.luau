local uis = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local States = {
	Idle = "Idle",
	Walking = "Walking",
	Sprinting = "Sprinting",
	Dashing  = "Dashing"
}

local STATE_SPEEDS = {
	[States.Idle] = 16,
	[States.Walking] = 16,
	[States.Sprinting] = 28,
}

local DASH_DURATION = 0.2
local DASH_COOLDOWN = 2
local DASH_FORCE_STRENGTH = 80
local NORMAL_FOV = 70
local DASH_FOV = 90
	
local MovementController = {}
MovementController.__index = MovementController

function MovementController.new(player)
	local self = setmetatable({}, MovementController)
	
	self.Player = player
	self.Character = player.Character or player.CharacterAdded:Wait()
	self.Humanoid = self.Character:WaitForChild("Humanoid")
	
	self.CurrentState = States.Idle
	self.CanDash = true
	
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
	
	-- Sets Force
	local attachment = Instance.new("Attachment", rootPart)
	local velocity = Instance.new("LinearVelocity", attachment)
	velocity.MaxForce = 1000000
	if(self.Humanoid.MoveDirection.Magnitude == 0) then
		velocity.VectorVelocity = rootPart.CFrame.LookVector * DASH_FORCE_STRENGTH
	else
		velocity.VectorVelocity = self.Humanoid.MoveDirection * DASH_FORCE_STRENGTH
	end
	velocity.Attachment0 = attachment
	
	-- FOV Effect
	TweenService:Create(camera, TweenInfo.new(0.18, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {FieldOfView = DASH_FOV}):Play()
	
	self:_SetState(States.Dashing)
	
	task.wait(DASH_DURATION)
	
	-- Cleanup
	velocity:Destroy()
	attachment:Destroy()
	TweenService:Create(camera, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {FieldOfView = NORMAL_FOV}):Play()
	
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
