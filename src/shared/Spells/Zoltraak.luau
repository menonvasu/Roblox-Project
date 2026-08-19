local Workspace = game:GetService("Workspace")
local Debris = game:GetService("Debris")
-- Zoltraak spell object class

local Zoltraak = {}

-- Configuration
local BEAM_SPEED = 200
local DAMAGE = 40
Zoltraak.MAX_RANGE = 150
Zoltraak.COOLDOWN = 2
Zoltraak.MANA_COST = 25

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
    local muzzleAttachment = staffModel.Staff:WaitForChild("MuzzleAttachment")
    if not muzzleAttachment then return nil end

    -- Direction and position
    local startPos = muzzleAttachment.WorldPosition
    local direction = (targetPos - startPos).Unit
    local circlePos = startPos 

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

local function spawnMagicCircle(character) 
    local staffModel = character:FindFirstChild("Staff_Model")
    local muzzleAttachment = staffModel and staffModel.Staff:FindFirstChild("MuzzleAttachment")
    if not muzzleAttachment then return end

    -- Create circle part
    local circleSummon = Instance.new("Part")
    circleSummon.Size = Vector3.new(1, 1, 1) 
    circleSummon.Transparency = 0.5 
    circleSummon.Material = Enum.Material.Neon 
    circleSummon.Color = Color3.fromRGB(0, 150, 255)
    circleSummon.Anchored = false 
    circleSummon.CanCollide = false
    circleSummon.CanQuery = false
    circleSummon.Parent = Workspace

    -- Insert the 3D Mesh
    local specialMesh = Instance.new("SpecialMesh")
    specialMesh.MeshType = Enum.MeshType.FileMesh
    specialMesh.MeshId = "rbxassetid://131419958270785" 

    specialMesh.Scale = Vector3.new(1, 1, 1) 
    specialMesh.Parent = circleSummon

    -- Create a local attachment inside the circle
    local circleAttachment = Instance.new("Attachment")
    local rightOffset = 0.1 
    local upOffset = 0  
    local forwardOffset = -1
    circleAttachment.CFrame = CFrame.new(rightOffset, forwardOffset, upOffset) * CFrame.Angles(math.rad(90), 0, 0) 
    circleAttachment.Parent = circleSummon

     -- Weld the circle to the staff muzzle
    local joint = Instance.new("RigidConstraint")
    joint.Attachment0 = muzzleAttachment
    joint.Attachment1 = circleAttachment
    joint.Parent = circleSummon
    
    Debris:AddItem(circleSummon, 2)
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
    auraEmitter.Texture = "rbxassetid://14304899539" 
    auraEmitter.FlipbookLayout = Enum.ParticleFlipbookLayout.Grid4x4
    auraEmitter.FlipbookMode = Enum.ParticleFlipbookMode.Loop
    auraEmitter.FlipbookFramerate = NumberRange.new(24)

    auraEmitter.LightEmission = 0.5 -- Blends out the black background
    auraEmitter.LightInfluence = 0  -- Prevents world shadows 

    -- Fade the particles out cleanly 
    auraEmitter.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0),    -- Fully opaque when spawned
        NumberSequenceKeypoint.new(0.7, 0.2),-- Start fading near the end
        NumberSequenceKeypoint.new(1, 1)  
    })

    -- Taper the size
    auraEmitter.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1.5),  -- Starts matching the beam width
        NumberSequenceKeypoint.new(1, 2.5)   -- Expands slightly as it crackles outward
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

function Zoltraak.clientCharge(playerCasting) 
    local character = playerCasting.Character
    if not character then return end
    spawnMagicCircle(character) -- spawn immediately on charge
end

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

    local laserPart = spawnLaserBeam()

    projectileFrameStepped(playerCasting, targetPos,
        function(currentPos, nextPos) -- custom onStep visual
            local midPoint = (currentPos + nextPos) / 2
            local beamLength = (nextPos - circlePos).Magnitude

            -- stretch to match step distance
            laserPart.Size = Vector3.new(beamLength, 1.5, 1.5)
            laserPart.CFrame = CFrame.lookAt(midPoint, nextPos) * CFrame.Angles(0, math.rad(90), 0)
        end,
        
        function() -- custom onHit visual
            laserPart:Destroy()
        end,

        function() -- custom onComplete
            laserPart:Destroy()
        end

    )
end

return Zoltraak