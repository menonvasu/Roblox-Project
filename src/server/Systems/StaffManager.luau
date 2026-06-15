-- Staff Object Class

local StaffManager = {}
StaffManager.__index = StaffManager

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local toggleStaffEvent = ReplicatedStorage.Network.ToggleStaffEvent

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
	self.StaffJoint = nil
	
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

	-- Guard clause
	local character = self.Player.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then
        -- The player died or left during the wait
        self.IsEquipped = false
        return 
    end

	-- set all spell attributes
	character:SetAttribute("PrimaryAttack", "Zoltraak")

	-- clone and parent model
	self.StaffModel = template:Clone()
	self.StaffModel.Parent = character

	self.StaffJoint = Instance.new("RigidConstraint")
	self.StaffJoint.Name = "StaffWeld"

	self.StaffJoint.Attachment0 = character:FindFirstChild("RightGripAttachment", true)
	self.StaffJoint.Attachment1 = self.StaffModel.Staff:FindFirstChild("WeaponAttachment")

	self.StaffJoint.Parent = character
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

		self.StaffJoint:Destroy()
		self.StaffJoint = nil
		print("Staff Removed!")

		local character = self.Player.Character
    	if character then
        	character:SetAttribute("PrimaryAttack", nil)
    	end
	end

end

return StaffManager