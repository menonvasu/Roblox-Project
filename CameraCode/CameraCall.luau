local AdventureCamera = require(game.ReplicatedStorage.AdventureCamera)
local runService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")

humanoid.AutoRotate = false
UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter

adventureCam = AdventureCamera.new(12,4,2)

runService.RenderStepped:Connect(function(dt)
	workspace.CurrentCamera.CameraType = Enum.CameraType.Scriptable
	adventureCam:Update(dt)
end)
