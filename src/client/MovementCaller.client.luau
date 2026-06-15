local MovementController = require(game.ReplicatedStorage.Shared.MovementController)
local player = game.Players.LocalPlayer

local activeController = nil

function setupCharacter(character) 
    if activeController then 
        activeController:Destroy()
        activeController = nil
    end

    -- instantiate
    activeController = MovementController.new()
    activeController:Listener()
end

if player.Character then 
    setupCharacter(player.Character)
end

player.CharacterAdded:Connect(setupCharacter)


