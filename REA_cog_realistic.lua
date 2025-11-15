-- ===========================================================
-- REA COG FS25 – Final Edition (v1.0.5)
-- by Papa_Matze – Improved by ChatGPT Repair/Patch
-- ===========================================================

REACOG = {}
REACOG.version = "1.0.5"

-- Strength multipliers
REACOG.cogShiftFactor     = 2.60   -- Wie stark der Schwerpunkt sich verlagert
REACOG.cogTiltFactor      = 1.85   -- Seitenneigung
REACOG.helperEffect       = 1.75   -- Helfer-Verhalten verbessern
REACOG.speedInfluence     = 0.015  -- Einfluss von Geschwindigkeit
REACOG.workloadInfluence  = 0.020  -- Einfluss der Geräte-Last

REACOG.debug = false

--------------------------------------------------------------------
-- UPDATE LOOP
--------------------------------------------------------------------
function REACOG:update(dt)
    if g_currentMission == nil then return end
    if g_currentMission.vehicles == nil then return end

    for _, vehicle in ipairs(g_currentMission.vehicles) do
        if vehicle.spec_motorized ~= nil then
            self:updateVehicleCOG(vehicle, dt)
        end
    end
end

--------------------------------------------------------------------
-- MAIN COG FUNCTION
--------------------------------------------------------------------
function REACOG:updateVehicleCOG(vehicle, dt)
    if vehicle.components == nil then return end
    local comp = vehicle.components[1]
    if comp == nil then return end

    local isHelper = vehicle.getIsAIActive ~= nil and vehicle:getIsAIActive()

    -------------------------------------------------
    -- Determine shift factors
    -------------------------------------------------
    local speed     = math.abs(vehicle.lastSpeed * 3600)
    local throttle  = math.abs(vehicle:getLastInputAxis(1) or 0)
    local load      = self:getImplementLoad(vehicle)

    local speedShift = speed * REACOG.speedInfluence
    local loadShift  = load * REACOG.workloadInfluence

    local finalShift = (speedShift + loadShift) * REACOG.cogShiftFactor

    if isHelper then
        finalShift = finalShift * REACOG.helperEffect
    end

    -------------------------------------------------
    -- Compute lateral tilt (side forces)
    -------------------------------------------------
    local tiltForce = (speed * 0.004) * REACOG.cogTiltFactor
    if tiltForce > 0.35 then tiltForce = 0.35 end

    -------------------------------------------------
    -- APPLY SHIFT
    -------------------------------------------------
    local x, y, z = getTranslation(comp.node)
    y = y + finalShift * 0.001

    setTranslation(comp.node, x, y, z)

    -------------------------------------------------
    -- APPLY TILT
    -------------------------------------------------
    local rx, ry, rz = getRotation(comp.node)
    rx = rx + tiltForce * 0.005

    setRotation(comp.node, rx, ry, rz)

    -------------------------------------------------
    -- DEBUG
    -------------------------------------------------
    if REACOG.debug and REA_WHEELS and REA_WHEELS.DEBUG_ENABLED then
        setTextColor(1,1,1,1)
        setTextAlignment(RenderText.ALIGN_RIGHT)
        renderText(0.98, 0.55, 0.018,
            string.format("REA COG v%s  Shift=%.3f Tilt=%.3f Load=%.2f",
                REACOG.version, finalShift, tiltForce, load))
    end
end

--------------------------------------------------------------------
-- Additional load from implements
--------------------------------------------------------------------
function REACOG:getImplementLoad(vehicle)
    local load = 0

    if vehicle.getAttachedImplements == nil then
        return 0
    end

    for _, impl in ipairs(vehicle:getAttachedImplements()) do
        if impl.object ~= nil and impl.object.spec_workArea ~= nil then
            if impl.object.getIsWorkAreaActive ~= nil then
                if impl.object:getIsWorkAreaActive() then
                    load = load + 1.0
                end
            end
        end
    end

    return load
end

--------------------------------------------------------------------
-- FS25 Register
--------------------------------------------------------------------
function REACOG.prerequisitesPresent(s)
    return true
end

function REACOG.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "update", REACOG)
end

addModEventListener(REACOG)
