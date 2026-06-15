local AdventureCamera = require(game.ReplicatedStorage.Shared.AdventureCamera)
local runService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")

humanoid.AutoRotate = false
UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter

local adventureCam = AdventureCamera.new(13,2,2.5)

workspace.CurrentCamera.CameraType = Enum.CameraType.Scriptable
runService:BindToRenderStep("AdventureCameraUpdate", Enum.RenderPriority.Camera.Value, function(dt)
	workspace.CurrentCamera.CameraType = Enum.CameraType.Scriptable
	adventureCam:Update(dt)
end)
