local Workspace = game:GetService("Workspace")
local Debris = game:GetService("Debris")
-- Zoltraak spell object class

local Zoltraak = {}

-- Configuration
local BEAM_SPEED = 200
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

            -- Trigger step callback if passed and run client visual
            if onStep then
                onStep(currentPos, direction)
            end

            -- cast a miniature ray from currentPos to nextPos
            local raycastResult = workspace:Raycast(currentPos, direction * stepDistance, rayParams)
            
            -- Hit registered!
            if raycastResult then

                if onHit then 
                    onHit(raycastResult)
                    didHit = true
                end
                
                break
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

    -- circle vfx
    local circleSummon = Instance.new("Part")
    circleSummon.Position = circlePos
    circleSummon.CFrame = CFrame.lookAt(circlePos, targetPos)
    circleSummon.Parent = Workspace
    
    Debris:AddItem(circleSummon, 1)

    -- visual beam
    local laserPart = Instance.new("Part")
    laserPart.Parent = workspace

    projectileFrameStepped(playerCasting, targetPos,
        function(currentPos, direction) -- custom onStep visual
            laserPart.CFrame = CFrame.lookAt(currentPos, currentPos + direction)
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