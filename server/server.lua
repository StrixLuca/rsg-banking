local RSGCore = exports['rsg-core']:GetCoreObject()

-- callback for bank balance
RSGCore.Functions.CreateCallback('rsg-banking:getBankingInformation', function(source, cb)
    local Player = RSGCore.Functions.GetPlayer(source)
    if not Player then return cb(nil) end
    local banking = tonumber(Player.PlayerData.money['bank'])
    cb(banking)
end)

-- deposit & withdraw
RegisterNetEvent("rsg-banking:server:transact", function(type, amount)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(source)
    local currentCash = Player.Functions.GetMoney('cash')
    local currentBank = Player.Functions.GetMoney('bank')
    amount = tonumber(amount)
    if amount <= 0 then
        lib.notify(src, {title = "Invalid amount.", type = "error"})
        return
    end
    if type == 1 then
        if currentBank >= amount then
            Player.Functions.RemoveMoney('bank', tonumber(amount), 'bank-withdraw')
            Player.Functions.AddMoney('cash', tonumber(amount), 'bank-withdraw')
            local newBankBalance = Player.Functions.GetMoney('bank')
            TriggerClientEvent('rsg-banking:client:UpdateBanking', src, newBankBalance)
        else
            lib.notify(src, {title = "Insufficient funds.", type = "error"})
        end
    elseif type == 2 then
        if currentCash >= amount then
            Player.Functions.RemoveMoney('cash', tonumber(amount), 'bank-withdraw')
            Player.Functions.AddMoney('bank', tonumber(amount), 'bank-withdraw')
            local newBankBalance = Player.Functions.GetMoney('bank')
            TriggerClientEvent('rsg-banking:client:UpdateBanking', src, newBankBalance)
        else
            lib.notify(src, {title = "Insufficient funds.", type = "error"})
        end
    end
end)
