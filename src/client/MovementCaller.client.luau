local MovementController = require(game.ReplicatedStorage.Shared.MovementController)
local player = game.Players.LocalPlayer

local controller = MovementController.new(player)
controller:Listener()

