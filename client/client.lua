local RSGCore = exports['rsg-core']:GetCoreObject()
local BankOpen = false

-------------------------------------------------------------------------------------------
-- prompts and blips if needed
-------------------------------------------------------------------------------------------
Citizen.CreateThread(function()
    for _, v in pairs(Config.BankLocations) do
        exports['rsg-core']:createPrompt(v.id, v.coords, RSGCore.Shared.Keybinds[Config.Keybind], 'Open '..v.name, {
            type = 'client',
            event = 'rsg-banking:client:OpenBanking',
        })
        if v.showblip == true then
            local BankingBlip = Citizen.InvokeNative(0x554D9D53F696D002, 1664425300, v.coords)
            SetBlipSprite(BankingBlip,  joaat(Config.Blip.blipSprite), true)
            SetBlipScale(Config.Blip.blipScale, 0.2)
            Citizen.InvokeNative(0x9CB1A1623062F402, BankingBlip, Config.Blip.blipName)
        end
    end
end)

-- set bank door default state
Citizen.CreateThread(function()
    for _,v in pairs(Config.BankDoors) do
        Citizen.InvokeNative(0xD99229FE93B46286, v.door, 1, 1, 0, 0, 0, 0)
        Citizen.InvokeNative(0x6BAB9442830C7F53, v.door, v.state)
    end
end)

-- open bank with opening hours
local OpenBank = function()
    local hour = GetClockHours()
    if (hour < Config.OpenTime) or (hour > Config.CloseTime) then
        lib.notify({
            title = 'Bank Closed',
            description = 'come back after '..Config.OpenTime..'am',
            type = 'error',
            icon = 'fa-solid fa-building-columns',
            iconAnimation = 'shake',
            duration = 7000
        })
        return
    end
    RSGCore.Functions.TriggerCallback('rsg-banking:getBankingInformation', function(banking)
        if banking ~= nil then
            SendNUIMessage({action = "OPEN_BANK", balance = banking})
            SetNuiFocus(true, true)
            BankOpen = true
            Citizen.InvokeNative(0xFA08722A5EA82DA7, 'RespawnLight')
            for i=0, 10 do Citizen.InvokeNative(0xFDB74C9CC54C3F37, 0.1 + (i / 10)); Wait(10) end
        end
    end)
end

-- close bank
local CloseBank = function()
    SendNUIMessage({action = "CLOSE_BANK"})
    SetNuiFocus(false, false)
    BankOpen = false
    for i=1, 10 do Citizen.InvokeNative(0xFDB74C9CC54C3F37, 1.0 - (i / 10)); Wait(15) end
    Citizen.InvokeNative(0x0E3F4AF2D63491FB)
end

RegisterNUICallback('CloseNUI', function()
    CloseBank()
end)

RegisterNUICallback('SafeDeposit', function()
    CloseBank()
    TriggerEvent('rsg-banking:client:safedeposit')
end)

AddEventHandler("rsg-banking:client:OpenBanking", function()
    OpenBank()
end)

RegisterNUICallback('Transact', function(data)
    TriggerServerEvent('rsg-banking:server:transact', data.type, data.amount)
end)

-- update bank balance
RegisterNetEvent('rsg-banking:client:UpdateBanking', function(newbalance)
    if not BankOpen then return end
    SendNUIMessage({action = "UPDATE_BALANCE", balance = newbalance})
end)

-- bank safe deposit box
RegisterNetEvent('rsg-banking:client:safedeposit', function()
    RSGCore.Functions.GetPlayerData(function(PlayerData)
        local cid = PlayerData.citizenid
        local ZoneTypeId = 1
        local x,y,z =  table.unpack(GetEntityCoords(PlayerPedId()))
        local town = Citizen.InvokeNative(0x43AD8FC02B429D33, x,y,z, ZoneTypeId)
        TriggerServerEvent("inventory:server:OpenInventory", "stash", cid..town, { maxweight = Config.StorageMaxWeight, slots = Config.StorageMaxSlots } )
        TriggerEvent("inventory:client:SetCurrentStash", cid..town)
    end)
end)