local RSGCore = exports['rsg-core']:GetCoreObject()

-----------------------------------------------------------------------
-- version checker
-----------------------------------------------------------------------
local function versionCheckPrint(_type, log)
    local color = _type == 'success' and '^2' or '^1'

    print(('^5['..GetCurrentResourceName()..']%s %s^7'):format(color, log))
end

local function CheckVersion()
    PerformHttpRequest('https://raw.githubusercontent.com/Rexshack-RedM/rsg-banking/main/version.txt', function(err, text, headers)
        local currentVersion = GetResourceMetadata(GetCurrentResourceName(), 'version')

        if not text then 
            versionCheckPrint('error', 'Currently unable to run a version check.')
            return 
        end

        --versionCheckPrint('success', ('Current Version: %s'):format(currentVersion))
        --versionCheckPrint('success', ('Latest Version: %s'):format(text))
        
        if text == currentVersion then
            versionCheckPrint('success', 'You are running the latest version.')
        else
            versionCheckPrint('error', ('You are currently running an outdated version, please update to version %s'):format(text))
        end
    end)
end

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

--------------------------------------------------------------------------------------------------
-- start version check
--------------------------------------------------------------------------------------------------
CheckVersion()
