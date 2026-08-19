-- Spell services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local lastCastTimes = {} -- Key: player.UserID, Value: timestamp (number)

-- Get remote event
local CastSpellEvent = ReplicatedStorage.Network.CastSpellEvent
local ReplicatedVisualsEvent = ReplicatedStorage.Network.ReplicatedVisualsEvent

local StatsManager = require(script.Parent.StatsManager)

CastSpellEvent.OnServerEvent:Connect(function(player, PrimaryAttack, targetPos)
    local character = player.Character
    if not character then return end
    
    local rootPart = character and character.PrimaryPart
    if not rootPart then return end

    -- Dynamic Module Routing
    local spellModule = ReplicatedStorage.Shared.Spells:FindFirstChild(PrimaryAttack)
    if not spellModule then return end
    local spellScript = require(spellModule)

    -- spell attributes
    local maxRange = spellScript.MAX_RANGE
    local cooldownDuration = spellScript.COOLDOWN
    local manaCost = spellScript.ManaCost or 15

    -- Distance sanity check
    local startPos = rootPart.Position
    local distance = (targetPos - startPos).Magnitude
    if distance > maxRange then return end
    
    -- Attribute sanity check
    local activeAttack = character:GetAttribute("PrimaryAttack")
    if activeAttack ~= PrimaryAttack then return end

    -- Cooldown logic check
    local cooldownKey = player.UserId .. "_" .. PrimaryAttack
    local lastCast = lastCastTimes[cooldownKey] or 0
    
    if os.clock() - lastCast < cooldownDuration then return end
    lastCastTimes[cooldownKey] = os.clock()

    --call consume mana
    local consumeManaResult = StatsManager.ConsumeMana(player, manaCost)
    if not consumeManaResult then return end

    -- Execute server logic
    spellScript.serverCast(player, targetPos)

    -- Broadcast visual effects to players
    ReplicatedVisualsEvent:FireAllClients(player, activeAttack, targetPos)
end)
