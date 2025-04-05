local useDebug = Config.Debug

if not Config.OxLib then
    if useDebug then print('^3 OxLib is not enabled for CW gearbox. Creating Core Object') end
    QBCore = exports['qb-core']:GetCoreObject()
end

if GetGameBuildNumber() < 3095 then
    print('^1THIS SERVER GAME BUILD IS TO LOW TO USE CW GEARBOX!')
    print("Version:", GetGameBuildNumber())
    print("Least required version:", 3095)
end 

local lowestGear = 0
local topGear = 5
local clutchUp = 1.0
local clutchDown = 1.0

local nextGear = 0
local isGearing = false

local MANUAL_FLAG = 1024
local LATE_GEAR_FLAG = 2710

local LanimationDict = "veh@driveby@first_person@passenger_rear_right_handed@smg" 
local LanimationName = "outro_90r"
local RanimationDict = "veh@driveby@first_person@passenger_rear_left_handed@smg" 
local RanimationName = "outro_90l"

local hashedRhd = {}

for i, v in pairs(Config.rhdCars) do
    hashedRhd[joaat(v)] = true
end

local function isDriver(vehicle)
    if (GetPedInVehicleSeat(vehicle, -1) == PlayerPedId()) then return true end
    return false
end

local function notify(text, type)
    if Config.OxLib then
        lib.notify({
            title = text,
            type = type,
        })
    else 
        QBCore.Functions.Notify(text, type)
    end
end

local loadedAnimDicts = {}


local function animDictIsLoaded(animDict)
    if loadedAnimDicts[animDict] then
        if useDebug then print('^6Animation was already loaded') end
        return true
    end

    RequestAnimDict(animDict)
    if useDebug then notify('Loading animation Fresh', 'success') end
    local retrys = 0
    while not HasAnimDictLoaded(animDict) do
        if useDebug then print('Loading animation dict for gearbox', animDict) end
        retrys = retrys + 1
        if retrys > 10 then if useDebug then print('Breaking early') notify('Failed to load dictionary', 'error') end return false end
        Wait(10)
    end

    loadedAnimDicts[animDict] = true
    return true
end

local function clearAnimCache()
    for dict in pairs(loadedAnimDicts) do
        RemoveAnimDict(dict)
    end
    loadedAnimDicts = {}
    if useDebug then print('^3Cleared animation cache') notify('Clearing animation cache') end
end

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1*60*1000)  -- 5 minutes
        clearAnimCache()
    end
end)

local function playAnimation(animation, animDict)
    
    if animDictIsLoaded(animDict) then
        if useDebug then print('^2Animation loaded successfully') end
        TaskPlayAnim(PlayerPedId(), animDict, animation, 8.0, 1.0, 500, 48, 0, 0, 0, 0)
        Wait(100)
        StopAnimTask(PlayerPedId(), animDict, animation, 1.0)
    else
        if useDebug then print('^1Could not load animation') notify('Animation broke') end
    end
end

local function handleAnimation(vehicle)
    local rhd = hashedRhd[GetEntityModel(vehicle)]
    local class = GetVehicleClass(vehicle)
    if class == 8 or class == 21 or class == 16 or class == 15 or class == 14 or class == 13 then
        if useDebug then print('Vehicle does not have gearing animation') end
        return
    end
    if rhd then
        playAnimation(RanimationName, RanimationDict)
    else
        playAnimation(LanimationName, LanimationDict)
    end
end

local OR, XOR, AND = 1, 3, 4
local function bitOper(flag, checkFor, oper)
	local result, mask, sum = 0, 2 ^ 31
	repeat
		sum, flag, checkFor = flag + checkFor + mask, flag % mask, checkFor % mask
		result, mask = result + mask * oper % (sum - flag - checkFor), mask / 2
	until mask < 1
	return result
end

local function addManualFlagToFlag(flag)
    local hasFullAutoFlag = bitOper(flag, 512, AND) == 512
    local hasDirectShiftFlag = bitOper(flag, 2048, AND) == 2048

    -- Remove flags 512 and 2048 if present
    if hasFullAutoFlag then
        flag = bitOper(flag, 512, XOR) -- Remove flag 512
    end
    if hasDirectShiftFlag then
        flag = bitOper(flag, 2048, XOR) -- Remove flag 2048
    end

    -- Add flag 1024
    flag = bitOper(flag, MANUAL_FLAG, OR)

    return math.floor(flag)
end

local function addLateGearFlag(flag)
    -- Add flag lateGearFlag
    flag = bitOper(flag, LATE_GEAR_FLAG, OR)

    return math.floor(flag)
end

local function removeManualFlagFromFlag(flag)
    local hasFullAutoFlag = bitOper(flag, 512, AND) == 512
    local hasDirectShiftFlag = bitOper(flag, 2048, AND) == 2048

    -- Remove flags 512 and 2048 if present
    if hasFullAutoFlag then
        flag = bitOper(flag, 512, XOR) -- Remove flag 512
    end
    if hasDirectShiftFlag then
        flag = bitOper(flag, 2048, XOR) -- Remove flag 2048
    end

    -- Add flag 1024
    flag = bitOper(flag, MANUAL_FLAG, XOR)

    return math.floor(flag)
end

local function vehicleHasFlag(vehicle, adv_flags)
    if adv_flags == nil then adv_flags = GetVehicleHandlingInt(vehicle, 'CCarHandlingData', 'strAdvancedFlags') end 
    if adv_flags == 0 and useDebug then 
        print('^1This vehicle either has empty advancedflags or no advanced flag in its handling file')
    end
    local flag_check_1024 = bitOper(adv_flags, MANUAL_FLAG, AND)
    local hasFlag = flag_check_1024 == MANUAL_FLAG
    if useDebug then print('Vehicle has flag:', adv_flags, hasFlag) end
    return hasFlag
end

local function createThread()
    Citizen.CreateThread(function()
        while true do
            local Player = PlayerPedId()
            local vehicle = GetVehiclePedIsUsing(Player)
            if not vehicle or not isDriver(vehicle) then 
                TerminateThisThread() 
                break;
            end
            Wait(1) -- Disable gtas gear stuff
            DisableControlAction(0, 363, true)
            DisableControlAction(0, 364, true)
        end
    end)
end

local function removeManualFlag(vehicle)
    if useDebug then print('Removing manual flag') end
    local adv_flags = GetVehicleHandlingInt(vehicle, 'CCarHandlingData', 'strAdvancedFlags')
    if not Entity(vehicle).state.originalFlag then
        if useDebug then print('Setting default flag') end
        Entity(vehicle).state:set('originalFlag', adv_flags, true)
    end
    local newFlag = removeManualFlagFromFlag(adv_flags)
    SetVehicleHandlingInt(vehicle, 'CCarHandlingData', 'strAdvancedFlags', newFlag)
    ModifyVehicleTopSpeed(vehicle, 1.0)
    Entity(vehicle).state:set('isManual', false, true)
end exports('removeManualFlag', removeManualFlag)

local function addManualFlag(vehicle)
    if useDebug then print('Adding manual flag') end
    
    local adv_flags = GetVehicleHandlingInt(vehicle, 'CCarHandlingData', 'strAdvancedFlags')
    if not Entity(vehicle).state.originalFlag then
        if useDebug then print('Setting default flag') end
        Entity(vehicle).state:set('originalFlag', adv_flags, true)
    end
    local newFlag = addManualFlagToFlag(adv_flags)
    SetVehicleHandlingInt(vehicle, 'CCarHandlingData', 'strAdvancedFlags', newFlag)
    ModifyVehicleTopSpeed(vehicle, 1.0)
    Entity(vehicle).state:set('isManual', true, true)
end exports('addManualFlag', addManualFlag)

local function vehicleShouldHaveFlag(vehicle)
    local originalFlag = Entity(vehicle).state.originalFlag
    if exports['cw-tuning']:vehicleIsAutomatic(vehicle) then -- vehicle is automatic
        if useDebug then print('Vehicle is an AUTOMATIC as per cw tuning') end
        return false
    end
    if exports['cw-tuning']:vehicleIsManual(vehicle) then
        if useDebug then print('Vehicle is an MANUAL as per cw tuning') end
        return true
    end

    return vehicleHasFlag(vehicle, originalFlag)
end

local function vehicleHasManualGearBox(vehicle)
    local adv_flags = GetVehicleHandlingInt(vehicle, 'CCarHandlingData', 'strAdvancedFlags')
    local originalFlag = Entity(vehicle).state.originalFlag
    if not originalFlag then 
        if useDebug then print('Setting original flag to', adv_flags) end
        Entity(vehicle).state:set('originalFlag', adv_flags, true)
    end
    if vehicleHasFlag(vehicle, adv_flags) then -- if car is a manual
        if Config.CwTuning then
            local shouldHaveFlag = vehicleShouldHaveFlag(vehicle)
            local hasManualFlag = vehicleHasFlag(vehicle, MANUAL_FLAG)
            if useDebug then print('Should Have Flag', shouldHaveFlag, 'has flag', hasManualFlag) end
            if not shouldHaveFlag and hasManualFlag then
                if useDebug then print("car should be an automatic but is not") end
                removeManualFlag(vehicle)
                return false
            end
            if not vehicleHasFlag(vehicle, originalFlag) and not exports['cw-tuning']:vehicleIsManual(vehicle) then -- car should be an automatic and does not have a swapped gearbox
                if useDebug then print("car should be an automatic and does not have a swapped gearbox") end
                removeManualFlag(vehicle)
                return false
            end
        end
        topGear = GetVehicleHighGear(vehicle)
        clutchDown = GetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fClutchChangeRateScaleDownShift')
        clutchUp = GetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fClutchChangeRateScaleUpShift')
        if Config.NotifyManual then
            notify(Config.ManualNotificationText)
        end
        createThread()
        Entity(vehicle).state:set('isManual', true, true)
        return true
    else -- if car ISNT a manual
        if Config.CwTuning then
            if exports['cw-tuning']:vehicleIsAutomatic(vehicle) then -- car should be an automatic
                Entity(vehicle).state:set('isManual', false, true)
                return false
            end 
            if vehicleShouldHaveFlag(vehicle) then
                if useDebug then print("car should be a manual but does not have the flag") end
                addManualFlag(vehicle)
            end
            if useDebug then print('Verifying original flag:') end
            if not vehicleHasFlag(vehicle, originalFlag) and not exports['cw-tuning']:vehicleIsManual(vehicle) then -- car should be an automatic and does not have a swap
                if useDebug then print('Verifying current flag:') end
                if vehicleHasFlag(vehicle, adv_flags) then
                    if useDebug then print("car should NOT be a manual by default and does not have a swapped gearbox, but currently has flag") end
                    removeManualFlag(vehicle)
                    return false
                end
                Entity(vehicle).state:set('isManual', false, true)
                return false
            end

            addManualFlag(vehicle)
            topGear = GetVehicleHighGear(vehicle)
            clutchDown = GetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fClutchChangeRateScaleDownShift')
            clutchUp = GetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fClutchChangeRateScaleUpShift')
            if Config.NotifyManual then
                notify(Config.ManualNotificationText)
            end
            createThread()
            return true
        elseif Config.UseOtherCheck then
            print('^1If you can see this print then someone enabled UseOtherCheck for manual gears but didnt add any code') -- REMOVE THIS IF YOU IMPLEMENT SOMETHING HERE
            -- ADD YOUR CHECK HERE
        end
    end
end exports('vehicleHasManualGearBox', vehicleHasManualGearBox)

local isEnteringVehicle = false

AddEventHandler('gameEventTriggered', function (name, args)
    if name == 'CEventNetworkPlayerEnteredVehicle' and not isEnteringVehicle then
        isEnteringVehicle = true
        SetTimeout(2000, function()
            isEnteringVehicle = false
        end)
        local Player = PlayerPedId()
        local vehicle = GetVehiclePedIsUsing(Player)
        vehicleHasManualGearBox(vehicle)
        if not isDriver(vehicle) then
            return
        end
        -- if not isDriver(vehicle) then return end -- check for if driverseat
        isGearing = false
        nextGear = 2
        topGear = 5
        clutchUp = 1.0
        clutchDown = 1.0
    end
end)


local setGear = GetHashKey('SET_VEHICLE_CURRENT_GEAR') & 0xFFFFFFFF
local function setNextGear(veh)
    Citizen.InvokeNative(setGear, veh, nextGear)
    if Config.UseServerSideStateSet then
        TriggerServerEvent('cw-gearbox:server:setGear', NetworkGetNetworkIdFromEntity(veh), nextGear)
        return
    end

    Entity(veh).state:set('gearchange', nextGear, false)
end

local function setNoGear(veh)
    Citizen.InvokeNative(setGear, veh, 0)
end

local function SetVehicleCurrentGear(veh, gear, clutch, currentGear)
    if GetEntitySpeedVector(veh, true).y < 0 then 
        return
    end
    if useDebug then 
        notify('next gear: '.. nextGear)
        print('^5========== NEW GEAR ==========')
        print('veh', veh)
        print('gear', gear)
        print('clutch', clutch)
        print('currentGear', currentGear)
    end
    if isGearing then 
        if useDebug then print('^3Is gearing. skipping') end
        SetTimeout(300, function () -- should be 900/clutch but this lets manual gearing be a tad faster
            if useDebug then print('Resetting clutch') end
            isGearing = false
        end)
        return 
    else
        setNoGear(veh)
        isGearing = true
        SetTimeout(Config.ClutchTime/clutch, function () -- should be 900/clutch but this lets manual gearing be a tad faster
            isGearing = false
            setNextGear(veh)
        end)
    end
    handleAnimation(veh)
end

local function shiftUp()
    local Player = PlayerPedId()
    local vehicle = GetVehiclePedIsUsing(Player)
    local adv_flags = GetVehicleHandlingInt(vehicle, 'CCarHandlingData', 'strAdvancedFlags')
    if vehicle == 0 then return end
    if not isDriver(vehicle) then if useDebug then print('^1Not driver') end return end
    if not vehicleHasFlag(vehicle, adv_flags) then if useDebug then print('^2No flag') end return end
    local currentGear = GetVehicleCurrentGear(vehicle)

    if useDebug then print('Before: CurrentGear:', currentGear, 'TopGear:', topGear, 'nextGear', nextGear) end
    if currentGear == topGear then return end
    
    if currentGear == lowestGear then
        nextGear = nextGear+1
        if useDebug then print('Current gear is lowest gear. Next gear will be', nextGear) end
    else
        nextGear = GetVehicleNextGear(vehicle)+1
        if useDebug then print('Current was not lowest gear. Next gear will be', nextGear) end
    end

    if useDebug then print('After: CurrentGear:', currentGear, 'TopGear:', topGear, 'nextGear', nextGear) end
    if nextGear > topGear then nextGear = topGear end

    SetVehicleCurrentGear( vehicle, nextGear, clutchUp, currentGear)
    ModifyVehicleTopSpeed(vehicle,1)
end

local function shiftDown()
    local Player = PlayerPedId()
    local vehicle = GetVehiclePedIsUsing(Player)
    local adv_flags = GetVehicleHandlingInt(vehicle, 'CCarHandlingData', 'strAdvancedFlags')
    if not isDriver(vehicle) then return end
    if not vehicleHasFlag(vehicle, adv_flags) then return end
    local currentGear = GetVehicleCurrentGear(vehicle)

    if currentGear == lowestGear then
        local newNextGear = nextGear-1
        if newNextGear > lowestGear then nextGear = newNextGear end
    else
        local newNextGear = currentGear-1
        if newNextGear > lowestGear then nextGear = newNextGear end
    end
    SetVehicleCurrentGear( vehicle,  nextGear , clutchDown, currentGear)
    ModifyVehicleTopSpeed(vehicle,1)
end


if Config.OxLib then
    if useDebug then print('^2OxLib is enabled') end
    if not lib then
        print('^OxLib is enabled but no lib was found. Might be missing from fxmanifest')
    else
        lib.addKeybind({
            name = 'shiftup',
            description = 'Shift Up',
            defaultKey = Config.Keys.gearUp,
            onPressed = function(self)
                shiftUp()
            end,
        })
        
        lib.addKeybind({
            name = 'shiftdown',
            description = 'Shift Down',
            defaultKey = Config.Keys.gearDown,
            onPressed = function(self)
                shiftDown()
            end
        })
    end
else
    RegisterCommand("clickShiftUp", function()
        shiftUp()
    end, false)
    RegisterKeyMapping("clickShiftUp", "Shift Up", "keyboard", Config.Keys.gearUp)

    RegisterCommand("clickShiftDown", function()
        shiftDown()
    end, false)
    RegisterKeyMapping("clickShiftDown", "Shift Up", "keyboard", Config.Keys.gearDown)
end

AddStateBagChangeHandler("gearchange", nil, function(bagName, key, value) 
    local veh = GetEntityFromStateBagName(bagName)
    if isDriver(veh) then return end
    if useDebug then print('gear change for veh', veh, value) end
    if veh == 0 then return end
    while not HasCollisionLoadedAroundEntity(veh) do
        if not DoesEntityExist(veh) then return end
        Wait(250)
    end
    local Player = PlayerPedId()
    Citizen.InvokeNative(setGear, veh, value)
end)