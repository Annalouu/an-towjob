local QBCore = exports['qb-core']:GetCoreObject()
local PlayerJob = {}
local JobsDone = 0
local NpcOn = false
local CurrentLocation = {}
local CurrentBlip = nil
local LastVehicle = 0
local VehicleSpawned = false
local selectedVeh = nil
local ranWorkThread = false
local towable = false
local towout = false
local cryptostick = false

local JobStarted = false

-- Functions

local function getRandomVehicleLocation()
    local randomVehicle = math.random(1, #Config.Locations["towspots"])
    while (randomVehicle == LastVehicle) do
        Wait(10)
        randomVehicle = math.random(1, #Config.Locations["towspots"])
    end
    return randomVehicle
end

CreateThread(function()
    QBCore.Functions.LoadModel(Config.PedHash)
    towped = CreatePed(0, Config.PedHash, Config.PedPos.x, Config.PedPos.y, Config.PedPos.z-1.0, Config.PedPos.w, false, false)
    TaskStartScenarioInPlace(towped,  true)
    FreezeEntityPosition(towped, true)
    SetEntityInvincible(towped, true)
    SetBlockingOfNonTemporaryEvents(towped, true)
    exports['qb-target']:AddTargetEntity(towped, {
        options = {
            {
                type = "client",
                event = "an-tow:takeoutcar",
                icon = "fas fa-circle",
                label = Lang:t('info.take_out_flatbed'),
                canInteract = function()
                    return not towout
                end,
                job = "tow"
            },
            {
                type = "client",
                event = "an-tow:parkcar",
                icon = "fas fa-circle",
                label = Lang:t('info.store_the_flatbed'),
                canInteract = function()
                    return towout
                end,
                job = "tow"
            },
        },
        distance = 2.0
    })
    QBCore.Functions.LoadModel(Config.payPedHash)
    payped = CreatePed(0, Config.payPedHash, Config.payPedPos.x, Config.payPedPos.y, Config.payPedPos.z-1.0, Config.payPedPos.w, false, false)
    TaskStartScenarioInPlace(payped,  true)
    FreezeEntityPosition(payped, true)
    SetEntityInvincible(payped, true)
    SetBlockingOfNonTemporaryEvents(payped, true)
    exports['qb-target']:AddTargetEntity(payped, {
        options = {
            {
                type = "client",
                event = "an-tow:pay",
                icon = "fas fa-circle",
                label = Lang:t('info.collect_payslip'),
                job = "tow"
            },
        },
        distance = 2.0
    })
end)

function sendemail(sent)
    local email = sent
    if Config.Phone == 'qb' then 
        TriggerServerEvent('qb-phone:server:sendNewMail', {
            sender = Lang:t('email.sender'),
            subject = Lang:t('email.subject'),
            message = email,
        })
    elseif Config.Phone == 'gks' then
        TriggerServerEvent('gksphone:NewMail', {
            sender = Lang:t('email.sender'),
            image = '/html/static/img/icons/mail.png',
            subject = Lang:t('email.subject'),
            message = email,
        })
    elseif Config.Phone == 'qs' then
        TriggerServerEvent('qs-smartphone:server:sendNewMail', {
            sender = 'Floyd',
            subject = Lang:t('email.subject'),
            message = email,
            button = {}
        })
    end
end

function sendpopups(sent)
    local popup = sent
    if Config.Phone == 'qb' then
        TriggerEvent('qb-phone:client:CustomNotification', Lang:t('info.tow'), popup, 'fas fa-location-arrow', '#FF0000', 5500)
    elseif Config.Phone == 'gks' then
        TriggerEvent('gksphone:notifi', {title = Lang:t('info.current_task'), message = popup, img= '/html/static/img/icons/messages.png'})
    elseif Config.Phone == 'qs' then
        TriggerEvent('qs-smartphone:client:notify', {title = Lang:t('info.current_task'), text = popup, icon = './img/apps/whatsapp.png', timeout = 4000})
    end
end

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
            DeleteEntity(towped)
            DeleteEntity(payped)
    end
end)

AddEventHandler('onResourceStart', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then
        PlayerJob = QBCore.Functions.GetPlayerData().job
    end 
end)

function deliverVehicle(vehicle)
    DeleteVehicle(vehicle)
    RemoveBlip(CurrentBlip2)
    JobsDone = JobsDone + 1
    VehicleSpawned = false
end

function getnewvehicle()
    local randomLocation = getRandomVehicleLocation()
    CurrentLocation.x = Config.Locations["towspots"][randomLocation].coords.x
    CurrentLocation.y = Config.Locations["towspots"][randomLocation].coords.y
    CurrentLocation.z = Config.Locations["towspots"][randomLocation].coords.z
    CurrentLocation.model = Config.Locations["towspots"][randomLocation].model
    CurrentLocation.id = randomLocation
    CurrentBlip = AddBlipForCoord(CurrentLocation.x, CurrentLocation.y, CurrentLocation.z)
    SetBlipColour(CurrentBlip, 3)
    SetBlipRoute(CurrentBlip, true)
    SetBlipRouteColour(CurrentBlip, 3)
end

local function getVehicleInDirection(coordFrom, coordTo)
    local rayHandle = CastRayPointToPoint(coordFrom.x, coordFrom.y, coordFrom.z, coordTo.x, coordTo.y, coordTo.z, 10, PlayerPedId(), 0)
    local a, b, c, d, vehicle = GetRaycastResult(rayHandle)
    return vehicle
end

local function isTowVehicle(vehicle)
    local retval = false
    for k, v in pairs(Config.Vehicles) do
        if GetEntityModel(vehicle) == GetHashKey(k) then
            retval = true
        end
    end
    return retval
end

local function DrawText3D(x, y, z, text)
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry("STRING")
    SetTextCentre(true)
    AddTextComponentString(text)
    SetDrawOrigin(x,y,z, 0)
    DrawText(0.0, 0.0)
    local factor = (string.len(text)) / 370
    DrawRect(0.0, 0.0+0.0125, 0.017+ factor, 0.03, 0, 0, 0, 75)
    ClearDrawOrigin()
end

local function doCarDamage(currentVehicle)
    local smash = false
    local damageOutside = false
    local damageOutside2 = false
    local engine = 199.0
    local body = 149.0
    if engine < 200.0 then
        engine = 200.0
    end

    if engine  > 1000.0 then
        engine = 950.0
    end

    if body < 150.0 then
        body = 150.0
    end
    if body < 950.0 then
        smash = true
    end

    if body < 920.0 then
        damageOutside = true
    end

    if body < 920.0 then
        damageOutside2 = true
    end

    Wait(100)
    SetVehicleEngineHealth(currentVehicle, engine)
    if smash then
        SmashVehicleWindow(currentVehicle, 0)
        SmashVehicleWindow(currentVehicle, 1)
        SmashVehicleWindow(currentVehicle, 2)
        SmashVehicleWindow(currentVehicle, 3)
        SmashVehicleWindow(currentVehicle, 4)
    end
    if damageOutside then
        SetVehicleDoorBroken(currentVehicle, 1, true)
        SetVehicleDoorBroken(currentVehicle, 6, true)
        SetVehicleDoorBroken(currentVehicle, 4, true)
    end
    if damageOutside2 then
        SetVehicleTyreBurst(currentVehicle, 1, false, 990.0)
        SetVehicleTyreBurst(currentVehicle, 2, false, 990.0)
        SetVehicleTyreBurst(currentVehicle, 3, false, 990.0)
        SetVehicleTyreBurst(currentVehicle, 4, false, 990.0)
    end
    if body < 1000 then
        SetVehicleBodyHealth(currentVehicle, 985.1)
    end
end

-- Old Menu Code (being removed)

local function MenuGarage()
    local towMenu = {
        {
            header = Lang:t('info.available_trucks'),
            isMenuHeader = true
        }
    }
    for k, v in pairs(Config.Vehicles) do
        towMenu[#towMenu+1] = {
            header = Config.Vehicles[k],
            params = {
                event = "an-tow:client:TakeOutVehicle",
                args = {
                    vehicle = k
                }
            }
        }
    end

    towMenu[#towMenu+1] = {
        header = Lang:t('info.close_menu'),
        txt = "",
        params = {
            event = "qb-menu:client:closeMenu"
        }

    }
    exports['qb-menu']:openMenu(towMenu)
end

local function CloseMenuFull()
    exports['qb-menu']:closeMenu()
end

-- Events

RegisterNetEvent('an-tow:client:SpawnVehicle', function()
    local vehicleInfo = selectedVeh
    local coords = Config.Locations["vehicle"].coords
    QBCore.Functions.SpawnVehicle(vehicleInfo, function(veh)
        SetVehicleNumberPlateText(veh, "TOW"..tostring(math.random(1000, 9999)))
        SetEntityHeading(veh, coords.w)
        NetworkRequestControlOfEntity(veh)
        exports[Config.fuel]:SetFuel(veh, 100.0)
        SetEntityAsMissionEntity(veh, true, true)
        CloseMenuFull()
        TriggerEvent("vehiclekeys:client:SetOwner", QBCore.Functions.GetPlate(veh))
        SetVehicleEngineOn(veh, true, true)
        for i = 1, 9, 1 do
            SetVehicleExtra(veh, i, 0)
        end
    end, coords, true)
    
end)

CreateThread(function()
    local TowBlip = AddBlipForCoord(Config.Locations["main"].coords.x, Config.Locations["main"].coords.y, Config.Locations["main"].coords.z)
    SetBlipSprite(TowBlip, 477)
    SetBlipDisplay(TowBlip, 4)
    SetBlipScale(TowBlip, 0.6)
    SetBlipAsShortRange(TowBlip, true)
    SetBlipColour(TowBlip, 15)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentSubstringPlayerName(Config.Locations["main"].label)
    EndTextCommandSetBlipName(TowBlip)
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    PlayerJob = QBCore.Functions.GetPlayerData().job

    if PlayerJob.name == "tow" then
        local TowBlip = AddBlipForCoord(Config.Locations["main"].coords.x, Config.Locations["main"].coords.y, Config.Locations["main"].coords.z)
        SetBlipSprite(TowBlip, 477)
        SetBlipDisplay(TowBlip, 4)
        SetBlipScale(TowBlip, 0.6)
        SetBlipAsShortRange(TowBlip, true)
        SetBlipColour(TowBlip, 15)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentSubstringPlayerName(Config.Locations["main"].label)
        EndTextCommandSetBlipName(TowBlip)
        RunWorkThread()
    end
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function(JobInfo)
    PlayerJob = JobInfo

    if PlayerJob.name == "tow" then
        local TowBlip = AddBlipForCoord(Config.Locations["main"].coords.x, Config.Locations["main"].coords.y, Config.Locations["main"].coords.z)
        SetBlipSprite(TowBlip, 477)
        SetBlipDisplay(TowBlip, 4)
        SetBlipScale(TowBlip, 0.6)
        SetBlipAsShortRange(TowBlip, true)
        SetBlipColour(TowBlip, 15)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentSubstringPlayerName(Config.Locations["main"].label)
        EndTextCommandSetBlipName(TowBlip)

        RunWorkThread()
    end
end)

AddEventHandler('onResourceStart', function(resource)
    if resource == GetCurrentResourceName() then
      Wait(100)
      PlayerJob = QBCore.Functions.GetPlayerData().job
        local TowBlip = AddBlipForCoord(Config.Locations["main"].coords.x, Config.Locations["main"].coords.y, Config.Locations["main"].coords.z)
        SetBlipSprite(TowBlip, 477)
        SetBlipDisplay(TowBlip, 4)
        SetBlipScale(TowBlip, 0.6)
        SetBlipAsShortRange(TowBlip, true)
        SetBlipColour(TowBlip, 15)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentSubstringPlayerName(Config.Locations["main"].label)
        EndTextCommandSetBlipName(TowBlip)
        RunWorkThread()
    end
end)

RegisterNetEvent('jobs:client:ToggleNpc', function()
    if QBCore.Functions.GetPlayerData().job.name == "tow" then
        if CurrentTow ~= nil then
            QBCore.Functions.Notify(Lang:t('error.finish_your_work'), "error")
            return
        end
        NpcOn = not NpcOn
        if NpcOn then
            sendpopups(Lang:t('info.someone_called_tow'))
            local randomLocation = getRandomVehicleLocation()
            CurrentLocation.x = Config.Locations["towspots"][randomLocation].coords.x
            CurrentLocation.y = Config.Locations["towspots"][randomLocation].coords.y
            CurrentLocation.z = Config.Locations["towspots"][randomLocation].coords.z
            CurrentLocation.model = Config.Locations["towspots"][randomLocation].model
            CurrentLocation.id = randomLocation

            CurrentBlip = AddBlipForCoord(CurrentLocation.x, CurrentLocation.y, CurrentLocation.z)
            SetBlipColour(CurrentBlip, 3)
            SetBlipRoute(CurrentBlip, true)
            SetBlipRouteColour(CurrentBlip, 3)
            JobStarted = true
        else
            if DoesBlipExist(CurrentBlip) then
                RemoveBlip(CurrentBlip)
                CurrentLocation = {}
                CurrentBlip = nil
            end
            JobStarted = false
            VehicleSpawned = false
            QBCore.Functions.DeleteVehicle(towablevehicle)
        end
    end
end)

RegisterNetEvent('an-tow:client:TowVehicle', function()
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), true)
    if isTowVehicle(vehicle) then
        if CurrentTow == nil then
            local playerped = PlayerPedId()
            local coordA = GetEntityCoords(playerped, 1)
            local coordB = GetOffsetFromEntityInWorldCoords(playerped, 0.0, 5.0, 0.0)
            local targetVehicle = getVehicleInDirection(coordA, coordB)
            local flatbed = GetHashKey('flatbed')
            local slamtruck = GetHashKey('slamtruck')
            local modelName = GetDisplayNameFromVehicleModel(selectedVeh)
                if NpcOn and CurrentLocation ~= nil then
                    if GetEntityModel(targetVehicle) ~= GetHashKey(CurrentLocation.model) then
                        QBCore.Functions.Notify(Lang:t('error.not_right_vehicle'), "error")
                        return
                    end
                end
                if not IsPedInAnyVehicle(PlayerPedId()) then
                    if vehicle ~= targetVehicle then
                        NetworkRequestControlOfEntity(targetVehicle)
                        local towPos = GetEntityCoords(vehicle)
                        local targetPos = GetEntityCoords(targetVehicle)
                        local flatbed = GetHashKey('flatbed')
                        local slamtruck = GetHashKey('slamtruck')                   
                        if #(towPos - targetPos) < 11.0 then
                            QBCore.Functions.Progressbar("towing_vehicle", Lang:t('info.hoisting_vehicle'), 5000, false, true, {
                                disableMovement = true,
                                disableCarMovement = true,
                                disableMouse = false,
                                disableCombat = true,
                            }, {
                                animDict = "mini@repair",
                                anim = "fixing_a_ped",
                                flags = 16,
                            }, {}, {}, function() -- Done
                                StopAnimTask(PlayerPedId(), "mini@repair", "fixing_a_ped", 1.0)
                                if JobStarted then
                                    sendpopups(Lang:t('info.take_vehicle_impound_lot'))
                                else
                                    sendpopups('Take Car Back To Station To Depot')
                                end
                                local bone = GetEntityBoneIndexByName(vehicle, 'bodyshell')
                            if  modelName == 'SLAMTRUCK' then
                                AttachEntityToEntity(targetVehicle, vehicle, GetEntityBoneIndexByName(vehicle, 'bodyshell'), 0.0, -0.90 + -0.85, -0.4 + 1.15, 0, 0, 0, 1, 1, 0, 1, 0, 1)
                                NetworkRequestControlOfEntity(targetVehicle)
                                FreezeEntityPosition(targetVehicle, true)
                            else
                                AttachEntityToEntity(targetVehicle, vehicle, GetEntityBoneIndexByName(vehicle, 'bodyshell'), 0.0, -1.5 + -0.85, -0.35 + 1.60, 0, 0, 0, 1, 1, 0, 1, 0, 1)
                                NetworkRequestControlOfEntity(targetVehicle)
                                FreezeEntityPosition(targetVehicle, true)
                            end
                                CurrentTow = targetVehicle

                                if JobStarted then
                                    if NpcOn then
                                        local item = "cryptostick"
                                        RemoveBlip(CurrentBlip)
                                        QBCore.Functions.Notify(Lang:t('success.take_vehicle_hayes_depot'), "success", 5000)
                                        CurrentBlip2 = AddBlipForCoord(-238.66, -1177.61, 23.04)
                                        SetBlipColour(CurrentBlip2, 3)
                                        SetBlipRoute(CurrentBlip2, true)
                                        SetBlipRouteColour(CurrentBlip2, 3)
                                        cryptostick = true
                                        Wait(100)
                                        TriggerServerEvent('an-tow:server:giveitem', item, 1, cryptostick)
                                        cryptostick = false
                                    end
                                end
                                QBCore.Functions.Notify(Lang:t('success.vehicle_towed'), "success", 5000)
                            end, function() -- Cancel
                                StopAnimTask(PlayerPedId(), "mini@repair", "fixing_a_ped", 1.0)
                                QBCore.Functions.Notify(Lang:t('error.failed'), "error")
                            end)
                        end
                    end
                end
            else
                QBCore.Functions.Progressbar("untowing_vehicle", Lang:t('info.removing_vehicle'), 5000, false, true, {
                    disableMovement = true,
                    disableCarMovement = true,
                    disableMouse = false,
                    disableCombat = true,
                }, {
                    animDict = "mini@repair",
                    anim = "fixing_a_ped",
                    flags = 16,
                }, {}, {}, function() -- Done
                    StopAnimTask(PlayerPedId(), "mini@repair", "fixing_a_ped", 1.0)
                    local modelName = GetDisplayNameFromVehicleModel(selectedVeh)
                    if  modelName == 'SLAMTRUCK' then
                        NetworkRequestControlOfEntity(CurrentTow)
                        FreezeEntityPosition(CurrentTow, false)
                        Wait(250)
                        AttachEntityToEntity(CurrentTow, vehicle, 20, -0.0, -7.0, 1.0, 0.0, 0.0, 0.0, false, false, false, false, 20, true)
                        DetachEntity(CurrentTow, true, true)
                    else
                        NetworkRequestControlOfEntity(CurrentTow)
                        FreezeEntityPosition(CurrentTow, false)
                        Wait(250)
                        AttachEntityToEntity(CurrentTow, vehicle, 20, -0.0, -12.0, 1.0, 0.0, 0.0, 0.0, false, false, false, false, 20, true)
                        DetachEntity(CurrentTow, true, true)
                    end
                    if JobStarted then
                        if NpcOn then
                            local targetPos = GetEntityCoords(CurrentTow)
    
                        if #(targetPos - vector3(-238.66, -1177.61, 23.04)) < 25.0 then                      
                                deliverVehicle(CurrentTow)
                                sendpopups(Lang:t('info.vehicle_delivered'))
                            end
                        end
                        CurrentTow = nil
                        QBCore.Functions.Notify(Lang:t('success.vehicle_taken_off'), "success", 5000)
                        Wait(Config.waitbetweenjobs * 1000)
                        sendpopups(Lang:t('info.new_vehicle_for_pickup'))
                        getnewvehicle()
                    else
                        CurrentTow = nil
                        QBCore.Functions.Notify(Lang:t('success.vehicle_taken_off'), "success", 5000)
                    end

                end, function() -- Cancel
                    StopAnimTask(PlayerPedId(), "mini@repair", "fixing_a_ped", 1.0)
                    QBCore.Functions.Notify(Lang:t('error.failed'), "error", 5000)
                end)
            end
    else
        QBCore.Functions.Notify(Lang:t('error.must_be_towing_vehicle'), "error", 5000)
    end
end)

RegisterNetEvent('an-tow:client:TakeOutVehicle', function(data)
    local coords = Config.Locations["vehicle"].coords
    coords = vector3(coords.x, coords.y, coords.z)
    local ped = PlayerPedId()
    local pos = GetEntityCoords(ped)
    towout = true
        local vehicleInfo = data.vehicle
        TriggerServerEvent('an-tow:server:DoBail', true, vehicleInfo)
        selectedVeh = vehicleInfo
end)

RegisterNetEvent('an-tow:client:SelectVehicle', function()
    local coords = Config.Locations["vehicle"].coords
    coords = vector3(coords.x, coords.y, coords.z)
    local ped = PlayerPedId()
    local pos = GetEntityCoords(ped)
        MenuGarage()
end)

-- Threads
function RunWorkThread()
    if not ranWorkThread then
        ranWorkThread = true

        CreateThread(function()
            local shownHeader = false
            PlayerJob = QBCore.Functions.GetPlayerData().job

            while LocalPlayer.state.isLoggedIn and PlayerJob.name == "tow" do
                local sleep = 1000
                local pos = GetEntityCoords(PlayerPedId())
                local vehicleCoords = vector3(Config.Locations["vehicle"].coords.x, Config.Locations["vehicle"].coords.y, Config.Locations["vehicle"].coords.z)
                local mainCoords = vector3(Config.Locations["main"].coords.x, Config.Locations["main"].coords.y, Config.Locations["main"].coords.z)

                if NpcOn and CurrentLocation ~= nil and next(CurrentLocation) ~= nil then
                    if not VehicleSpawned then
                        Wait(Config.waitbetweenjobs + 3 * 1000)
                        VehicleSpawned = true
                        QBCore.Functions.SpawnVehicle(CurrentLocation.model, function(veh)
                            exports[Config.fuel]:SetFuel(veh, 0.0)
                            if math.random(1,2) == 1 then
                                doCarDamage(veh)
                            end
                            towablevehicle = veh
                        end, CurrentLocation, true)
                        print(CurrentLocation.model)
                        
                    end
                    sleep = 5
                end

                Wait(sleep)
            end
        end)

        ranWorkThread = false
    end
end

RegisterNetEvent('an-tow:client:sendemail', function(messagesent)
    paymentmsg = messagesent
    Wait(100)
    sendemail(paymentmsg)
end)

RegisterNetEvent("an-tow:pay")
AddEventHandler("an-tow:pay", function()
    if JobsDone > 0 then
    RemoveBlip(CurrentBlip)
    TriggerServerEvent("an-tow:server:getpaid", JobsDone)
    JobsDone = 0
    NpcOn = false
    else
    QBCore.Functions.Notify(Lang:t('error.no_work_done'), "error", 5000)
    end
end)

RegisterNetEvent("an-tow:takeoutcar")
AddEventHandler("an-tow:takeoutcar", function()
    MenuGarage()
end)

RegisterNetEvent("an-tow:parkcar")
AddEventHandler("an-tow:parkcar", function()
    local coords = vector3(-209.43, -1169.82, 23.04)
    local closestVehicle, distance = QBCore.Functions.GetClosestVehicle(coords)
    if distance < 40 then -- distance limiter to make sure it's close enough change as you wish
        local isTruck = isTowVehicle(closestVehicle) -- uses existing function so will work as normal
        if isTruck then
            towout = false
            QBCore.Functions.Notify(Lang:t('success.vehicle_stored'), "success", 5000)
            NetworkRequestControlOfEntity(closestVehicle) -- network entity ownership check before deletion
            QBCore.Functions.DeleteVehicle(closestVehicle)
            if DoesBlipExist(CurrentBlip) then
                RemoveBlip(CurrentBlip)
                CurrentLocation = {}
                CurrentBlip = nil
            end
            JobStarted = false
            VehicleSpawned = false
            QBCore.Functions.DeleteVehicle(towablevehicle)
            TriggerServerEvent('an-tow:server:DoBail', false)
        else
            print(Lang:t('error.closest_vehicle_not_delivery_truck'))
            QBCore.Functions.Notify(Lang:t('error.closest_vehicle_not_delivery_truck'), "error", 5000)
        end       
    else
        print(Lang:t('error.no_vehicle_nearby'))
        QBCore.Functions.Notify(Lang:t('error.no_vehicle_nearby'), "error", 5000)
    end
end)

CreateThread(function()
    exports['qb-target']:AddGlobalVehicle({
        options = {
            {
                icon = "fa-solid fa-magnifying-glass",
                label = Lang:t('info.tow'),
                canInteract = function(entity)
                    local oldtruck = GetVehiclePedIsIn(PlayerPedId(),true)
                    local flatbed = GetHashKey('flatbed')
                    local slamtruck = GetHashKey('slamtruck')
                    if GetEntityModel(oldtruck) == flatbed or GetEntityModel(oldtruck) == slamtruck then return true end
                        return false
                end,
                event = "an-tow:client:TowVehicle",
                job = {
                    ["tow"] = 0,
                    ["mechanic"] = 0,
                    ["hayes"] = 0,
                    ["harmony"] = 0,
                },
            },
        },
        distance = 3
    })
end)
