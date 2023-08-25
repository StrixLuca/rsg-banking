local RSGCore = exports['rsg-core']:GetCoreObject()

exports('registerAccount', function(cid)
    local _cid = tonumber(cid)
    currentAccounts[_cid] = generateCurrent(_cid)
end)

exports('current', function(cid)
    if currentAccounts[cid] then
        return currentAccounts[cid]
    end
end)

local function format_int(number)
    local _, _, minus, int, fraction = tostring(number):find('([-]?)(%d+)([.]?%d*)')
    int = int:reverse():gsub("(%d%d%d)", "%1,")
    return minus .. int:reverse():gsub("^,", "") .. fraction
end

-- Get all bank statements for the current player
local function getBankStatements(cid)
    local bankStatements = MySQL.query.await('SELECT * FROM bank_statements WHERE citizenid = ? ORDER BY record_id DESC LIMIT 30', { cid })
    return bankStatements
end

-- Adds a bank statement to the database
local function addBankStatement(cid, accountType, amountDeposited, amountWithdrawn, accountBalance, statementDescription)
    local time = os.date("%Y-%m-%d %H:%M:%S")
    MySQL.insert('INSERT INTO `bank_statements` (`account`, `citizenid`, `deposited`, `withdraw`, `balance`, `date`, `type`) VALUES (?, ?, ?, ?, ?, ?, ?)', {
        accountType,
        cid,
        amountDeposited,
        amountWithdrawn,
        accountBalance,
        time,
        statementDescription
    })
end

RSGCore.Functions.CreateCallback('rsg-banking:getBankingInformation', function(source, cb)
    local xPlayer = RSGCore.Functions.GetPlayer(source)
    if not xPlayer then return cb(nil) end
    local bankStatements = getBankStatements(xPlayer.PlayerData.citizenid)

    local banking = {
        ['name'] = xPlayer.PlayerData.charinfo.firstname .. ' ' .. xPlayer.PlayerData.charinfo.lastname,
        ['bankbalance'] = '$'.. format_int(xPlayer.PlayerData.money['bank']),
        ['cash'] = '$'.. format_int(xPlayer.PlayerData.money['cash']),
        ['accountinfo'] = xPlayer.PlayerData.charinfo.account,
        ['statement'] = bankStatements,
    }

    cb(banking)
end)

RegisterNetEvent('rsg-banking:doQuickDeposit', function(amount)
    local src = source
    local xPlayer = RSGCore.Functions.GetPlayer(src)
    while xPlayer == nil do Wait(0) end
    local currentCash = xPlayer.Functions.GetMoney('cash')

    if tonumber(amount) <= currentCash then
        xPlayer.Functions.RemoveMoney('cash', tonumber(amount), 'banking-quick-depo')
        local bank = xPlayer.Functions.AddMoney('bank', tonumber(amount), 'banking-quick-depo')
        local newBankBalance = xPlayer.Functions.GetMoney('bank')
        addBankStatement(xPlayer.PlayerData.citizenid, 'Bank', amount, 0, newBankBalance, Lang:t('info.deposit', {amount = amount}))

        if bank then
            TriggerClientEvent('rsg-banking:openBankScreen', src)
            TriggerClientEvent('rsg-banking:successAlert', src, Lang:t('success.cash_deposit', {value = amount}))
            TriggerEvent('rsg-log:server:CreateLog', 'banking', 'Banking', 'lightgreen', "**"..GetPlayerName(xPlayer.PlayerData.source) .. " (citizenid: "..xPlayer.PlayerData.citizenid.." | id: "..xPlayer.PlayerData.source..")** made a cash deposit of $"..amount.." successfully.")
        end
    end
end)

RegisterNetEvent('rsg-banking:doQuickWithdraw', function(amount, _)
    local src = source
    local xPlayer = RSGCore.Functions.GetPlayer(src)
    while xPlayer == nil do Wait(0) end
    local currentCash = xPlayer.Functions.GetMoney('bank')
    local newBankBalance = xPlayer.Functions.GetMoney('bank')
    addBankStatement(xPlayer.PlayerData.citizenid, 'Bank', 0, amount, newBankBalance, Lang:t('info.withdraw', {amount = amount}))

    if tonumber(amount) <= currentCash then
        local cash = xPlayer.Functions.RemoveMoney('bank', tonumber(amount), 'banking-quick-withdraw')
        bank = xPlayer.Functions.AddMoney('cash', tonumber(amount), 'banking-quick-withdraw')
        if cash then
            TriggerClientEvent('rsg-banking:openBankScreen', src)
            TriggerClientEvent('rsg-banking:successAlert', src, Lang:t('success.cash_withdrawal', {value = amount}))
            TriggerEvent('rsg-log:server:CreateLog', 'banking', 'Banking', 'red', "**"..GetPlayerName(xPlayer.PlayerData.source) .. " (citizenid: "..xPlayer.PlayerData.citizenid.." | id: "..xPlayer.PlayerData.source..")** made a cash withdrawal of $"..amount.." successfully.")
        end
    end
end)

RSGCore.Commands.Add('givecash', Lang:t('command.givecash'), {{name = 'id', help = 'Player ID'}, {name = 'amount', help = 'Amount'}}, true, function(source, args)
  local src = source
    local id = tonumber(args[1])
    local amount = math.ceil(tonumber(args[2]))

    if id and amount then
        local xPlayer = RSGCore.Functions.GetPlayer(src)
        local xReciv = RSGCore.Functions.GetPlayer(id)

        if xReciv and xPlayer then
            if not xPlayer.PlayerData.metadata["isdead"] then
                local distance = xPlayer.PlayerData.metadata["inlaststand"] and 3.0 or 10.0
                if #(GetEntityCoords(GetPlayerPed(src)) - GetEntityCoords(GetPlayerPed(id))) < distance then
                    if amount > 0 then
                        if xPlayer.Functions.RemoveMoney('cash', amount) then
                            if xReciv.Functions.AddMoney('cash', amount) then
                                TriggerClientEvent('RSGCore:Notify', src, Lang:t('success.give_cash',{id = tostring(id), cash = tostring(amount)}), "success")
                                TriggerClientEvent('RSGCore:Notify', id, Lang:t('success.received_cash',{id = tostring(src), cash = tostring(amount)}), "success")
                                TriggerClientEvent("payanimation", src)
                            else
                                -- Return player cash
                                xPlayer.Functions.AddMoney('cash', amount)
                                TriggerClientEvent('RSGCore:Notify', src, Lang:t('error.not_give'), "error")
                            end
                        else
                            TriggerClientEvent('RSGCore:Notify', src, Lang:t('error.not_enough'), "error")
                        end
                    else
                        TriggerClientEvent('RSGCore:Notify', src, Lang:t('error.invalid_amount'), "error")
                    end
                else
                    TriggerClientEvent('RSGCore:Notify', src, Lang:t('error.too_far_away'), "error")
                end
            else
                TriggerClientEvent('RSGCore:Notify', src, Lang:t('error.dead'), "error")
            end
        else
            TriggerClientEvent('RSGCore:Notify', src, Lang:t('error.wrong_id'), "error")
        end
    else
        TriggerClientEvent('RSGCore:Notify', src, Lang:t('error.givecash'), "error")
    end
end)

RegisterNetEvent("payanimation", function()
    TriggerEvent('animations:client:EmoteCommandStart', {"id"})
end)

local num = tonumber

RSGCore.Functions.CreateUseableItem('moneyclip', function(source, item)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)

    if not Player then return end

    local itemData = Player.Functions.GetItemBySlot(item.slot)

    if not itemData then return end

    local amount = itemData.info.money

    if Player.Functions.RemoveItem(item.name, 1, item.slot) then
        Player.Functions.AddMoney('cash', amount)

        RSGCore.Functions.Notify(src, 'You\'ve got $'..amount..' cash from this Money Clip!', 'success', 3000)
    end
end)

RSGCore.Commands.Add('moneyclip', 'Make Money Clip', {{ name = 'amount', help = 'How much money do you want convert?' }}, true, function(source, args)
    local src = source
    local args1 = num(args[1])

    if args1 <= 0 then
        RSGCore.Functions.Notify(src, 'Please enter the correct amount!', 'error', 3000)

        return
    end

    local Player = RSGCore.Functions.GetPlayer(src)

    if not Player then return end

    local money = Player.Functions.GetMoney('cash')

    if money and money >= args1 then
        if Player.Functions.RemoveMoney('cash', args1, 'give-money') then
            local info =
            {
                money = args1
            }

            Player.Functions.AddItem('moneyclip', 1, false, info)
            RSGCore.Functions.Notify(src, 'You\'ve just converted $'..args1..' cash into a Money Clip!', 'success', 3000)
        end
    end
end, 'user')
