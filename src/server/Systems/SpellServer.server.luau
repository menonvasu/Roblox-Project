-- Spell services

local MAXRANGE = 150

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Get remote event
local CastSpellEvent = ReplicatedStorage.Network.CastSpellEvent
local ReplicatedVisualsEvent = ReplicatedStorage.Network.ReplicatedVisualsEvent

CastSpellEvent.OnServerEvent:Connect(function(player, PrimaryAttack, targetPos)
    local character = player.Character
    if not character then return end
    
    local rootPart = character and character.PrimaryPart
    if not rootPart then return end

    -- Distance sanity check
    local startPos = rootPart.Position
    local distance = (targetPos - startPos).Magnitude
    if distance > MAXRANGE then return end
    
    -- Attribute sanity check
    local activeAttack = character:GetAttribute("PrimaryAttack")
    if activeAttack ~= PrimaryAttack then return end

    -- Dynamic Module Routing
    local spellModule = ReplicatedStorage.Shared.Spells:FindFirstChild(PrimaryAttack)
    if not spellModule then return end
    local spellScript = require(spellModule)

    -- Execute server logic
    spellScript.serverCast(player, targetPos)

    -- Broadcast visual effects to players
    ReplicatedVisualsEvent:FireAllClients(player, activeAttack, targetPos)
end)
