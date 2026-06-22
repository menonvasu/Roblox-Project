local MovementController = require(game.ReplicatedStorage.Shared.MovementController)
local player = game.Players.LocalPlayer

local activeController = nil

function setupCharacter(character) 
    if activeController then 
        activeController:Destroy()
        _G.MovementController = nil
        activeController = nil
    end

    -- instantiate
    activeController = MovementController.new()
    _G.MovementController = activeController
    activeController:Listener()
end

if player.Character then 
    setupCharacter(player.Character)
end

player.CharacterAdded:Connect(setupCharacter)


