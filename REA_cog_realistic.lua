--============================================================--
--  REA Center of Gravity – Realistic Weight & Stability
--  by Papa_Matze
--  Version: 1.0.7.0
--============================================================--

REAcog = {}
REAcog.version = "1.0.7.0"

---------------------------------------------------------------------
-- Tuning-Werte
---------------------------------------------------------------------
REAcog.BaseStability        = 1.4      -- Grundstabilität
REAcog.WeightInfluence      = 2.2      -- Einfluss von Ladung/Füllmenge
REAcog.SideSlopeSensitivity = 1.6      -- Seitenhang-Empfindlichkeit
REAcog.SpeedStabilityFactor = 1.3      -- Stabilität bei Geschwindigkeit

-- NEU → Helfer-Schwankphysik stärker / realer
REAcog.HelperRollFactor     = 1.25     -- KI schwankt 25% stärker seitlich
REAcog.HelperWeightBoost    = 1.15     -- KI spürt Gewicht 15% stärker
REAcog.HelperStabilityDrop  = 0.85     -- KI hat etwas weniger Grundstabilität

---------------------------------------------------------------------
-- Map Events
---------------------------------------------------------------------

function REAcog:loadMap(name)
    print("REA Center of Gravity geladen – Version " .. REAcog.version)
end

function REAcog:deleteMap()
end

function REAcog:update(dt)
    if g_currentMission == nil or g_currentMission.vehicles == nil then
        return
    end

    for _, vehicle in pairs(g_currentMission.vehicles) do
        REAcog:updateVehicleCOG(vehicle, dt)
    end
end

function REAcog:draw()
end

---------------------------------------------------------------------
-- Schwerpunkt je Fahrzeug
---------------------------------------------------------------------

function REAcog:updateVehicleCOG(vehicle, dt)
    if vehicle == nil or vehicle.components == nil then
        return
    end

    if vehicle.spec_enterable == nil then
        return
    end

    local isAI = vehicle.getIsAIActive ~= nil and vehicle:getIsAIActive()

    ---------------------------------------------------------
    -- Basisstabilität
    ---------------------------------------------------------
    local stability = REAcog.BaseStability

    -- Helfer bekommen realistischere, dynamischere Physik
    if isAI then
        stability = stability * REAcog.HelperStabilityDrop
    end

    ---------------------------------------------------------
    -- Geschwindigkeit
    ---------------------------------------------------------
    local speed = 0
    if vehicle.getLastSpeed ~= nil then
        speed = vehicle:getLastSpeed()
    elseif vehicle.lastSpeed ~= nil then
        speed = vehicle.lastSpeed * 3600
    end

    if speed > 20 then
        local drop = ((speed - 20) / 40) * 0.3 * REAcog.SpeedStabilityFactor
        stability = stability - drop
    end

    ---------------------------------------------------------
    -- Füllmengen / Gewicht
    ---------------------------------------------------------
    local dynamicWeight = 0
    if vehicle.getFillUnits ~= nil then
        local units = vehicle:getFillUnits()
        for i = 1, #units do
            local lvl = vehicle:getFillUnitFillLevel(i) or 0
            local cap = vehicle:getFillUnitCapacity(i)   or 1
            dynamicWeight = dynamicWeight + (lvl / cap)
        end
    end

    local weightEffect = dynamicWeight * 0.7 * REAcog.WeightInfluence

    -- Helfer haben mehr Gewichtseinfluss
    if isAI then
        weightEffect = weightEffect * REAcog.HelperWeightBoost
    end

    stability = stability - weightEffect

    ---------------------------------------------------------
    -- Anhängende Geräte / Anhänger
    ---------------------------------------------------------
    if vehicle.attachedImplements ~= nil then
        for _, impl in pairs(vehicle.attachedImplements) do
            if impl.object ~= nil then
                local drop = 0.15 * REAcog.WeightInfluence
                if isAI then
                    drop = drop * REAcog.HelperWeightBoost
                end
                stability = stability - drop
            end
        end
    end

    ---------------------------------------------------------
    -- Seitenneigung (Hang)
    ---------------------------------------------------------
    local rollDeg = 0
    if vehicle.rootNode ~= nil then
        local rx, ry, rz = getRotation(vehicle.rootNode)
        rollDeg = math.deg(rx)
    end

    if math.abs(rollDeg) > 5 then
        local slope = ((math.abs(rollDeg) - 5) / 30) * REAcog.SideSlopeSensitivity

        -- KI schwankt stärker in der Seitenlage
        if isAI then
            slope = slope * REAcog.HelperRollFactor
        end

        stability = stability - slope
    end

    ---------------------------------------------------------
    -- Finaler Stabilitätswert
    ---------------------------------------------------------
    local finalStability = math.max(0.1, stability)

    ---------------------------------------------------------
    -- Schwerpunkt absenken / anpassen
    ---------------------------------------------------------
    for _, comp in pairs(vehicle.components) do
        if comp ~= nil and comp.node ~= nil then
            local origX, origY, origZ = getCenterOfMass(comp.node)

            -- Schwerpunkt tiefer → stabiler
            local newY = origY - (0.4 * (1 - finalStability))

            setCenterOfMass(comp.node, origX, newY, origZ)
        end
    end
end

---------------------------------------------------------------------
-- Registrierung
---------------------------------------------------------------------

addModEventListener(REAcog)
