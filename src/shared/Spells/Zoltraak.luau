local Workspace = game:GetService("Workspace")
local Debris = game:GetService("Debris")
-- Zoltraak spell object class

local Zoltraak = {}

-- Configuration
local BEAM_SPEED = 100
local DAMAGE = 40

-------------------------------------------------------------------------------
-- Helper functions(internal use only)
-------------------------------------------------------------------------------

local function calculateSpellGeometry(caster, targetPos)
    local character = caster.Character
    if not character then return nil end

    -- Get physical staff model
    local staffModel = character:FindFirstChild("Staff_Model")
    if not staffModel then return nil end

    -- Get muzzle attachment
    local muzzleAttachment = staffModel.Staff:FindFirstChild("MuzzleAttachment")
    if not muzzleAttachment then return nil end

    -- Direction and position
    local startPos = muzzleAttachment.WorldPosition
    local direction = (targetPos - startPos).Unit
    local circlePos = startPos + (direction * 3)

    -- Return multiple values so both functions can use them
    return startPos, direction, circlePos
end

local function projectileFrameStepped(player, targetPos, onStep, onHit, onComplete) 
    local startPos, direction, circlePos = calculateSpellGeometry(player, targetPos)
    if not startPos then return end

    local currentPos = circlePos
    local distanceTravelled = 0
    local maxRange = 150
    local velocity = direction * BEAM_SPEED
    local didHit = false

    -- Set up raycast parameters to exclude the caster
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    rayParams.FilterDescendantsInstances = {player.Character}


    task.spawn(function() 
        while distanceTravelled < maxRange do
            -- Wait for next physics frame and capture elapsed time(dt)
            local dt = task.wait()
            local stepDistance = BEAM_SPEED * dt
            local nextPos = currentPos + (direction * stepDistance)

            -- cast a miniature ray from currentPos to nextPos
            local raycastResult = workspace:Raycast(currentPos, direction * stepDistance, rayParams)
            
            -- Hit registered!
            if raycastResult then
                nextPos = raycastResult.Position

                if onStep then
                    onStep(currentPos, nextPos) 
                end

                if onHit then 
                    onHit(raycastResult)
                    didHit = true
                end
                
                break
            end

            -- Trigger step callback if passed and run client visual
            if onStep then
                onStep(currentPos, nextPos)
            end

            -- Update tracking variables for next frame
            currentPos = nextPos
            distanceTravelled = distanceTravelled + stepDistance
        end

        -- distance reached max range
        if onComplete and not didHit then
            onComplete()
        end

    end)
end

local function spawnMagicCircle(circlePos, targetPos) 
    -- create summon
    local circleSummon = Instance.new("Part")
    circleSummon.Size = Vector3.new(6, 6, 0.1) 
    circleSummon.Transparency = 0.99
    circleSummon.Anchored = true
    circleSummon.CanCollide = false
    circleSummon.CFrame = CFrame.lookAt(circlePos, targetPos)
    circleSummon.CanQuery = false
    circleSummon.Parent = Workspace

     -- Front Decal 
    local frontDecal = Instance.new("Decal")
    frontDecal.Face = Enum.NormalId.Front 
    frontDecal.Texture = "rbxassetid://13006927102"
    frontDecal.Parent = circleSummon

    -- Back Decal 
    local backDecal = Instance.new("Decal")
    backDecal.Face = Enum.NormalId.Back 
    backDecal.Texture = "rbxassetid://13006927102"
    backDecal.Parent = circleSummon
    
    Debris:AddItem(circleSummon, 1)
end

local function spawnLaserBeam() 
    -- visual beam core 
    local laserPart = Instance.new("Part")
    laserPart.Material = Enum.Material.Neon
    laserPart.Color = Color3.fromRGB(184, 217, 231)
    laserPart.Anchored = true
    laserPart.CanCollide = false
    laserPart.Shape = Enum.PartType.Cylinder
    laserPart.Parent = workspace

    -- The Zoltraak envelope
    local auraEmitter = Instance.new("ParticleEmitter")
    auraEmitter.Texture = "rbxassetid://2527922625" 
    auraEmitter.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(150, 0, 255)), -- Bright magical purple core
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(80, 0, 160)), -- Deep purple
        ColorSequenceKeypoint.new(1, Color3.fromRGB(20, 0, 40)) -- Dark edge
    })
    
    auraEmitter.LightEmission = 0.5 
    auraEmitter.LightInfluence = 0
    auraEmitter.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 3), -- Starts wide
        NumberSequenceKeypoint.new(1, 6)  -- Expands outward
    })
    
    auraEmitter.Lifetime = NumberRange.new(0.15, 0.3) -- Short lifetime
    auraEmitter.Rate = 300 
    auraEmitter.Speed = NumberRange.new(0, 5) 
    auraEmitter.SpreadAngle = Vector2.new(15, 15)
    auraEmitter.Parent = laserPart

    return laserPart
end

-------------------------------------------------------------------------------
-- CORE LOGIC
-------------------------------------------------------------------------------

function Zoltraak.serverCast(player, targetPos) 
    projectileFrameStepped(player, targetPos, 
        nil, 
        function(raycastResult) -- custom onHit math
            local hitInstance = raycastResult.Instance
            local hitModel = hitInstance:FindFirstAncestorOfClass("Model")
            local humanoid = hitModel and hitModel:FindFirstChildOfClass("Humanoid")

            if humanoid then
                --Apply damage safely
                print("Hit player: " .. hitModel.Name)
            end
        end, 
        nil
    )
end

function Zoltraak.clientRender(playerCasting, targetPos)
    local startPos, direction, circlePos = calculateSpellGeometry(playerCasting, targetPos)
    if not startPos then return end

    spawnMagicCircle(circlePos, targetPos)

    local laserPart = spawnLaserBeam()

    projectileFrameStepped(playerCasting, targetPos,
        function(currentPos, nextPos) -- custom onStep visual
            local midPoint = (currentPos + nextPos) / 2
            local beamLength = (nextPos - circlePos).Magnitude

            -- stretch to match step distance
            laserPart.Size = Vector3.new(beamLength, 1.5, 1.5)
            laserPart.CFrame = CFrame.lookAt(midPoint, nextPos) * CFrame.Angles(0, math.rad(90), 0)
        end,
        
        function(raycastResult) -- custom onHit visual
            laserPart:Destroy()
        end,

        function() -- custom onComplete
            laserPart:Destroy()
        end

    )
end

return Zoltraak