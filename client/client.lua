local RSGCore = exports['rsg-core']:GetCoreObject()
local banks
local showing, playerLoaded = false, false
InBank = false
blips = {}


RegisterNetEvent('rsg-banking:client:syncBanks')
AddEventHandler('rsg-banking:client:syncBanks', function(data)
    banks = data
    if showing then
        showing = false
    end
end)

function openAccountScreen()
    RSGCore.Functions.TriggerCallback('rsg-banking:getBankingInformation', function(banking)
        if banking ~= nil then
            InBank = true
            SetNuiFocus(true, true)
            SendNUIMessage({
                status = "openbank",
                information = banking
            })

            TriggerEvent("debug", 'Banking: Open UI', 2000, 0, 'hud_textures', 'check')
        end
    end)
end

function atmRefresh()
    RSGCore.Functions.TriggerCallback('rsg-banking:getBankingInformation', function(infor)
        InBank = true
        SetNuiFocus(true, true)
        SendNUIMessage({
            status = "refreshatm",
            information = infor
        })
    end)
end

RegisterNetEvent('rsg-banking:openBankScreen')
AddEventHandler('rsg-banking:openBankScreen', function()
    openAccountScreen()
end)

Citizen.CreateThread(function()
    for banks, v in pairs(Config.BankLocations) do
        if Config.UseTarget == false then
            exports['rsg-core']:createPrompt(v.name, v.coords, 0xF3830D8E, 'Open ' .. v.name, {
                type = 'client',
                event = 'rsg-banking:openBankScreen',
                args = { false, true, false },
            })
        else
            exports['rsg-target']:AddCircleZone(v.name, v.coords, 1, {
                name = v.name,
                debugPoly = false,
              }, {
                options = {
                  {
                    type = "client",
                    event = 'rsg-banking:openBankScreen',
                    icon = "fas fa-dollar-sign",
                    label = "Open Bank",
                  },
                },
                distance = 2.0,
              })
        end
        if v.showblip == true then
            local StoreBlip = N_0x554d9d53f696d002(1664425300, v.coords)
            SetBlipSprite(StoreBlip, -2128054417, 52)
            SetBlipScale(StoreBlip, 0.2)
        end
    end
end)

Citizen.CreateThread(function()
    for k,v in pairs(Config.BankDoors) do
        --for v, door in pairs(k) do
        Citizen.InvokeNative(0xD99229FE93B46286,v,1,1,0,0,0,0)
        Citizen.InvokeNative(0x6BAB9442830C7F53,v,0)
    end
end)


RegisterNetEvent('rsg-banking:transferError')
AddEventHandler('rsg-banking:transferError', function(msg)
    SendNUIMessage({
        status = "transferError",
        error = msg
    })
end)

RegisterNetEvent('rsg-banking:successAlert')
AddEventHandler('rsg-banking:successAlert', function(msg)
    SendNUIMessage({
        status = "successMessage",
        message = msg
    })
end)
