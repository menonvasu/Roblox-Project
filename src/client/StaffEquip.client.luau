local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local player = game.Players.LocalPlayer

local toggleStaffEvent = ReplicatedStorage.Network.ToggleStaffEvent
local staffStateEvent = ReplicatedStorage.LocalEvents.StaffStateChanged

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	
	if input.KeyCode == Enum.KeyCode.G then
		toggleStaffEvent:FireServer()
	end
end)

toggleStaffEvent.OnClientEvent:Connect(function(isEquipped) 
	staffStateEvent:Fire(isEquipped)
end)