local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- 1. Run this in a deferred thread so the main game loop never locks up
task.defer(function()
	-- 2. Give the engine a brief moment to finish mounting the Rojo file tree
	task.wait(0.5) 
	
	-- 3. Safely locate the Shared folder and SmartBone module
	local Shared = ReplicatedStorage:WaitForChild("Shared", 5)
	if not Shared then
		warn("SmartBone Fix: Could not find 'Shared' folder in ReplicatedStorage!")
		return
	end
	
	local SmartBoneModule = Shared:WaitForChild("SmartBone", 5)
	if not SmartBoneModule then
		warn("SmartBone Fix: Could not find 'SmartBone' ModuleScript inside Shared!")
		return
	end
	
	-- 4. Require and fire the engine
	print("[SmartBone Runtime] Safely required module. Waking up physics...")
	local SmartBone = require(SmartBoneModule)
	
	SmartBone.Start()
	print("[SmartBone Runtime] Engine initialized successfully!")
end)