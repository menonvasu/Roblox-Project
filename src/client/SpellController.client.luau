local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContextActionService = game:GetService("ContextActionService")

local player = game.Players.LocalPlayer
local currentCam = game.Workspace.CurrentCamera

-- get events
local CastSpellEvent = ReplicatedStorage.Network.CastSpellEvent
local ReplicatedVisualsEvent = ReplicatedStorage.Network.ReplicatedVisualsEvent

-- Range of spell
local MAXRANGE = 120

-- Configuration Table 
local PlayerKeybinds = {
    PrimaryAttack = Enum.KeyCode.E
}

local isCasting = false

local function handleSpellCast(_,inputState,_)
    if inputState ~= Enum.UserInputState.Begin then return end

    if _G.MovementController:IsBusy() then return end

    local character = player.Character
    if not character then return end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
    if not animator then return end 
 
    -- gets the right weapon action
    local activeAttack = character:GetAttribute("PrimaryAttack")
    if not activeAttack then return end

    if isCasting then return end
    isCasting = true
    _G.MovementController:SetCasting(true)

    -- Load and play the animation on the current animator
    local castAnim = game.ReplicatedStorage.CombatAnims.Zoltraak_Cast
    local playTrack = animator:LoadAnimation(castAnim)
    playTrack.Looped = false
    playTrack:Play()

     -- get spell module and spawn magic circle
    local spellModule = ReplicatedStorage.Shared.Spells:WaitForChild(activeAttack, 2)
    if not spellModule then return end
    local currentSpell = require(spellModule);
    
    -- spawn
    currentSpell.clientCharge(player)

    -- wait for release
    playTrack:GetMarkerReachedSignal("Release"):Once(function()
        -- calculate center point and cast ray
    local centerPoint =  Vector2.new(currentCam.ViewportSize.X/2 , currentCam.ViewportSize.Y/2)
    local ray = currentCam:ViewportPointToRay(centerPoint.X, centerPoint.Y)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {character}
    local raycastResult = workspace:Raycast(ray.Origin, ray.Direction * MAXRANGE, params);
                
    -- get target position
    local targetPos = raycastResult and raycastResult.Position or (ray.Origin + ray.Direction * MAXRANGE)
    
        -- render client visuals
        currentSpell.clientRender(player, targetPos)

        -- cast spell event
        CastSpellEvent:FireServer(activeAttack, targetPos)
    end)

     -- Unlock movement when the animation physically stops
    playTrack.Stopped:Once(function()
        _G.MovementController:SetCasting(false)
    end)

    -- Unlock the actual cast capability ONLY after the full cooldown has finished
    local cooldownDuration = currentSpell.COOLDOWN or 2
    task.delay(cooldownDuration, function()
        isCasting = false
    end)

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