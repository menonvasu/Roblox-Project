local MovementController = require(game.ReplicatedStorage.MovementController)
local player = game.Players.LocalPlayer

local controller = MovementController.new(player)
controller:Listener()

