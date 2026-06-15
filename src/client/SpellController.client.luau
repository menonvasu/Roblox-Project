local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContextActionService = game:GetService("ContextActionService")

local player = game.Players.LocalPlayer
local currentCam = game.Workspace.CurrentCamera

-- get events
local CastSpellEvent = ReplicatedStorage.Network.CastSpellEvent
local ReplicatedVisualsEvent = ReplicatedStorage.Network.ReplicateVisualsEvent

-- Range of spell
local MAXRANGE = 120

-- Configuration Table 
local PlayerKeybinds = {
    PrimaryAttack = Enum.KeyCode.E
}

local function handleSpellCast(_,inputState,_)
    if inputState ~= Enum.UserInputState.Begin then return end

    local character = player.Character
    if not character then return end
 
    -- gets the right weapon action
    local activeAttack = character:GetAttribute("PrimaryAttack")
    if not activeAttack then return end

    -- calculate center point and cast ray
    local centerPoint =  Vector2.new(currentCam.ViewportSize.X/2 , currentCam.ViewportSize.Y/2)
    local ray = currentCam:ViewportPointToRay(centerPoint.X, centerPoint.Y)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {character}
    local raycastResult = workspace:Raycast(ray.Origin, ray.Direction * MAXRANGE, params);
            
    -- get target position
    local targetPos
    if raycastResult then
        targetPos = raycastResult.Position
    else
        targetPos = ray.Origin + ray.Direction * MAXRANGE
    end

    -- get spell module
    local spellModule = ReplicatedStorage.Shared.Spells:WaitForChild(activeAttack, 2)
    if not spellModule then return end
    local currentSpell = require(spellModule);

    -- render client visuals
    currentSpell.clientRender(player, targetPos);

    -- cast spell event
    CastSpellEvent:FireServer(activeAttack, targetPos)
end 

ContextActionService:BindAction("CastActiveSpell", handleSpellCast, true, PlayerKeybinds.PrimaryAttack)

ReplicatedVisualsEvent.OnClientEvent:Connect(function(caster, activeAttack, targetPos) 
    if caster == player then return end

    -- get spell module
    local spellModule = ReplicatedStorage.Shared.Spells:WaitForChild(activeAttack, 2)
    if not spellModule then return end

    local currentSpell = require(spellModule);
    currentSpell.clientRender(caster, targetPos)
end)