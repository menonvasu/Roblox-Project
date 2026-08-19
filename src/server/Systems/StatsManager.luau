local StatsManager = {}

game.Players.PlayerAdded:Connect(function(player)
    player:SetAttribute("Health", 100)
    player:SetAttribute("MaxHealth", 100)
    player:SetAttribute("Mana", 100)
    player:SetAttribute("MaxMana", 100)
    player:SetAttribute("Stamina", 100)
    player:SetAttribute("MaxStamina", 100)
end)

function StatsManager.ConsumeMana(player, amount) 
    local currentMana = player:GetAttribute("Mana")
    if currentMana == nil or currentMana < amount then
        return false
    end

    currentMana -= amount
    player:SetAttribute("Mana", currentMana)
    return true
end

return StatsManager
