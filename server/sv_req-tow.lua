local QBCore = exports['qb-core']:GetCoreObject()

if Config.reqTow then
    RegisterServerEvent('an-tow:sendTowRequest')
    AddEventHandler('an-tow:sendTowRequest', function(plate, coords)
        local src = source
        local players = QBCore.Functions.GetPlayers()

        for _, playerId in ipairs(players) do
            local player = QBCore.Functions.GetPlayer(playerId)
            if player ~= nil and player.PlayerData.job.name == 'tow' then
                TriggerClientEvent('an-tow:receiveTowRequest', playerId, src, plate, coords)
            end
        end
    end)

    RegisterServerEvent('an-tow:sendTowResponse')
    AddEventHandler('an-tow:sendTowResponse', function(target, accepted)
        local towDriver = QBCore.Functions.GetPlayer(source)
        local towDriverName = towDriver.PlayerData.charinfo.firstname

        TriggerClientEvent('an-tow:requestResponse', target, towDriverName, accepted)
    end)
end