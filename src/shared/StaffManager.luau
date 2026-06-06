-- Staff Object Class

local StaffManager = {}
StaffManager.__index = StaffManager

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local toggleStaffEvent = ReplicatedStorage.Network.ToggleStaffEvent

-------------------------------------------------------------------------------
-- LOCAL HELPER FUNCTIONS (Private to this module)
-------------------------------------------------------------------------------


-------------------------------------------------------------------------------
-- INITIALIZATION
-------------------------------------------------------------------------------

function StaffManager.new(player) 
	local self = setmetatable({}, StaffManager)

	-- Properties
	self.IsEquipped = false
	self.IsAnimating = false
	self.StaffModel = nil
	self.Player = player
	
	return self
end

-------------------------------------------------------------------------------
-- CORE LOGIC
-------------------------------------------------------------------------------

function StaffManager:Toggle() 
	if self.IsAnimating then return end

	self.IsAnimating = true
	
	if not self.IsEquipped then self:Equip()
	else self:Unequip()
	end

	task.wait(0.5)
	self.IsAnimating = false
end

function StaffManager:Equip() 
	local template = game.ReplicatedStorage.Assets.Weapons:WaitForChild("Staff_Model")
	if not template then return end

	self.IsEquipped = true
	toggleStaffEvent:FireClient(self.Player, self.IsEquipped)
	
	task.wait(0.2)
	self.StaffModel = template:Clone()
	self.StaffModel.Parent = self.Player.Character

	local joint = Instance.new("RigidConstraint")
	joint.Name = "StaffWeld"

	joint.Attachment0 = self.Player.Character:FindFirstChild("RightGripAttachment", true)
	joint.Attachment1 = self.StaffModel.Staff:FindFirstChild("WeaponAttachment")

	joint.Parent = self.Player.Character
	print("Staff Attached!")
	
end

function StaffManager:Unequip() 
	print("Unequipping...")

	self.IsEquipped = false
	toggleStaffEvent:FireClient(self.Player, self.IsEquipped)
	
	task.wait(0.2)
	
	if self.StaffModel then
		self.StaffModel:Destroy()
		self.StaffModel = nil
		print("Staff Removed!")
	end

end

return StaffManager