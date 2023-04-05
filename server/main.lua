local QBCore = exports['qb-core']:GetCoreObject()
local PaymentTax = 15
local Bail = {}

RegisterNetEvent('an-tow:server:DoBail', function(bool, vehInfo)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if bool then
        if Player.PlayerData.money.cash >= Config.BailPrice then
            Bail[Player.PlayerData.citizenid] = Config.BailPrice
            Player.Functions.RemoveMoney('cash', Config.BailPrice, "tow-paid-bail")
            TriggerClientEvent('QBCore:Notify', src, Lang:t('success.deposit_of_paid', {price = Config.BailPrice}), 'success')
            TriggerClientEvent('an-tow:client:SpawnVehicle', src, vehInfo)
        elseif Player.PlayerData.money.bank >= Config.BailPrice then
            Bail[Player.PlayerData.citizenid] = Config.BailPrice
            Player.Functions.RemoveMoney('bank', Config.BailPrice, "tow-paid-bail")
            TriggerClientEvent('QBCore:Notify', src, Lang:t('success.you_have_paid', {price = Config.BailPrice}), 'success')
            TriggerClientEvent('an-tow:client:SpawnVehicle', src, vehInfo)
        else
            TriggerClientEvent('QBCore:Notify', src, Lang:t('error.not_enough_money_deposit', {price = Config.BailPrice}), 'error')
        end
    else
        if Bail[Player.PlayerData.citizenid] ~= nil then
            Player.Functions.AddMoney('bank', Bail[Player.PlayerData.citizenid], "tow-bail-paid")
            Bail[Player.PlayerData.citizenid] = nil
            TriggerClientEvent('QBCore:Notify', src, Lang:t('success.you_got_back', {price = Config.BailPrice}), 'success')
        end
    end
end)

RegisterNetEvent('an-tow:server:giveitem', function(item,amount,bool)
    local src = source
    local xPlayer = QBCore.Functions.GetPlayer(src)
    local chance = math.random(1,100)
    if bool then
        if chance < 26 then
            xPlayer.Functions.AddItem(item, amount, false)
            TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[item], "add")
        end
    end
end)

RegisterNetEvent('an-tow:server:getpaid', function(drops)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    drops = tonumber(drops)
    local bonus = 0
    local DropPrice = Config.dropprice
    if drops > 5 then
        bonus = math.ceil((DropPrice / 10) * 5)
    elseif drops > 10 then
        bonus = math.ceil((DropPrice / 10) * 7)
    elseif drops > 15 then
        bonus = math.ceil((DropPrice / 10) * 10)
    elseif drops > 20 then
        bonus = math.ceil((DropPrice / 10) * 12)
    end
    local price = (DropPrice * drops) + bonus
    local payment = price 

    Player.Functions.AddJobReputation(1)
    Player.Functions.AddMoney("bank", payment, "tow-salary")
    TriggerClientEvent('an-tow:client:sendemail', src, Lang:t('success.you_got_paid', {payment = payment}), 'success')
    
end)

QBCore.Commands.Add("npc", Lang:t('info.toggle_npc_job'), {}, false, function(source, args)
	TriggerClientEvent("jobs:client:ToggleNpc", source)
end)
