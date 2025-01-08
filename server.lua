ESX = exports["es_extended"]:getSharedObject()

ESX.RegisterServerCallback('db_hospital:getPlayerMoney', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    local money = xPlayer.getMoney()
    cb(money)
end)

RegisterNetEvent('db_hospital:pay')
AddEventHandler('db_hospital:pay', function(amount)
    local xPlayer = ESX.GetPlayerFromId(source)
    local playerMoney = xPlayer.getMoney()

    if playerMoney >= amount then
        xPlayer.removeMoney(amount)
        TriggerClientEvent('ox_lib:notify', source, { 
            title = 'Hospital',
            type = 'success', 
            description = "Bylo Vám naúčtováno " .. amount .. " za ošetření." 
        })

        TriggerEvent("db_hospital:backupInventory")
        TriggerEvent("db_hospital:clearInventory")

        TriggerClientEvent("db_hospital:lieOnBed", source)
        sendLogToWebhook("Platba za oživení", "Bylo " .. xPlayer.getName() .. " naúčtováno " .. amount .. " za oživení.", 65280) -- Zelená
    else
        TriggerClientEvent('ox_lib:notify', source, { 
            title = 'Hospital',
            type = 'error', 
            description = "Nemáte dostatek peněz na oživení."
        })
    end
end)