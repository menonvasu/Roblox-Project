-- Simple Server Script to force blocky
game.Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		player.CharacterAppearanceLoaded:Wait()
		
		for _, child in pairs(character:GetChildren()) do
			if child:IsA("CharacterMesh") then
				child:Destroy()
			end
		end
	end)
end)

