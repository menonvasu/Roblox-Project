-- Staff Services

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StaffManager = require(ReplicatedStorage.Shared.StaffManager)

-- Get remote event
local toggleStaffEvent = ReplicatedStorage.Network.ToggleStaffEvent

-- Table to store StaffManager instances for each player
local playerStaffs = {}

toggleStaffEvent.OnServerEvent:Connect(function(player)
	if not playerStaffs[player] then
		playerStaffs[player] = StaffManager.new(player)
	end
	
	playerStaffs[player]:Toggle()
end)

game:GetService("Players").PlayerRemoving:Connect(function(player)
	playerStaffs[player] = nil
end)
