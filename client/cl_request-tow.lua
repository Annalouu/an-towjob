local QBCore = exports['qb-core']:GetCoreObject()

if Config.reqTow then
        exports['qb-target']:AddGlobalVehicle({
            options = {
                {
                    icon = "fas fa-truck",
                    type = "client",
                    label = "Request Tow",
                    event = "tow:requestTow",
                },
            },
            distance = 3
        })
    RegisterNetEvent('an-tow:requestTow')
    AddEventHandler('an-tow:requestTow', function()
        local player = PlayerPedId()
        local vehicle = QBCore.Functions.GetClosestVehicle()
        local coords = GetEntityCoords(player)

        if vehicle ~= 0 then
            TriggerServerEvent('an-tow:sendTowRequest', GetVehicleNumberPlateText(vehicle), coords)
        else
            QBCore.Functions.Notify('No vehicle found', 'error')
        end
    end)

    RegisterNetEvent('an-tow:requestResponse')
    AddEventHandler('an-tow:requestResponse', function(towDriverName, accepted)
        if accepted then
            exports['qb-phone']:PhoneNotification('Tow request accepted by ' .. towDriverName, 'They will be there shortly!', '#9f0e63', "NONE", 5000)
        else
            exports['qb-phone']:PhoneNotification('Tow request declined.', 'Declined.', '#9f0e63', "NONE", 5000)
        end
    end)

    RegisterNetEvent('an-tow:receiveTowRequest')
    AddEventHandler('an-tow:receiveTowRequest', function(target, plate, coords)

        local success = exports['qb-phone']:PhoneNotification('Tow Request: ', 'Vehicle Plate: ' .. plate, '#9f0e63', "NONE", 5000, 'fas fa-check-circle', 'fas fa-times-circle')
        if success then
            TriggerServerEvent('an-tow:sendTowResponse', target, true)
            local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
            SetBlipAsShortRange(blip, false)
            SetBlipSprite(blip, 68)
            SetBlipColour(blip, 0)
            SetBlipScale(blip, 0.7)
            SetBlipDisplay(blip, 6)
            Wait(130000)
            RemoveBlip(blip)
        else
            TriggerServerEvent('an-tow:sendTowResponse', target, false)
        end
    end)
end
