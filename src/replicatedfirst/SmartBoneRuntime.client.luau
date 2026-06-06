local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Running this in a deferred thread so the main game loop never locks up
task.defer(function()
	-- Gives the engine a brief moment to finish mounting the Rojo file tree
	task.wait(0.5) 
	
	-- Safely locate the Shared folder and SmartBone module
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
	
	-- Require and fire the engine
	local SmartBone = require(SmartBoneModule)
	SmartBone.Start()
end)