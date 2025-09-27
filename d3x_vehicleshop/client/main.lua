local Keys = {
  ["ESC"] = 322, ["F1"] = 288, ["F2"] = 289, ["F3"] = 170, ["F5"] = 166, ["F6"] = 167, ["F7"] = 168, ["F8"] = 169, ["F9"] = 56, ["F10"] = 57,
  ["~"] = 243, ["1"] = 157, ["2"] = 158, ["3"] = 160, ["4"] = 164, ["5"] = 165, ["6"] = 159, ["7"] = 161, ["8"] = 162, ["9"] = 163, ["-"] = 84, ["="] = 83, ["BACKSPACE"] = 177,
  ["TAB"] = 37, ["Q"] = 44, ["W"] = 32, ["E"] = 38, ["R"] = 45, ["T"] = 245, ["Y"] = 246, ["U"] = 303, ["P"] = 199, ["["] = 39, ["]"] = 40, ["ENTER"] = 18,
  ["CAPS"] = 137, ["A"] = 34, ["S"] = 8, ["D"] = 9, ["F"] = 23, ["G"] = 47, ["H"] = 74, ["K"] = 311, ["L"] = 182,
  ["LEFTSHIFT"] = 21, ["Z"] = 20, ["X"] = 73, ["C"] = 26, ["V"] = 0, ["B"] = 29, ["N"] = 249, ["M"] = 244, [","] = 82, ["."] = 81,
  ["LEFTCTRL"] = 36, ["LEFTALT"] = 19, ["SPACE"] = 22, ["RIGHTCTRL"] = 70,
  ["HOME"] = 213, ["PAGEUP"] = 10, ["PAGEDOWN"] = 11, ["DELETE"] = 178,
  ["LEFT"] = 174, ["RIGHT"] = 175, ["TOP"] = 27, ["DOWN"] = 173,
  ["NENTER"] = 201, ["N4"] = 108, ["N5"] = 60, ["N6"] = 107, ["N+"] = 96, ["N-"] = 97, ["N7"] = 117, ["N8"] = 61, ["N9"] = 118
}


local Keys = { ... } 

local HasAlreadyEnteredMarker = false
local LastZone                = nil
local actionDisplayed         = false
local CurrentAction           = nil
local CurrentActionMsg        = ''
local CurrentActionData       = {}
local IsInShopMenu            = false
local Categories              = {}
local Vehicles                = {}
local LastVehicles            = {}
local CurrentVehicleData      = nil
local testdrive_timer         = 40

ESX                           = nil

Citizen.CreateThread(function ()
	while ESX == nil do
		ESX = exports["es_extended"]:getSharedObject()
		Citizen.Wait(0)
	end

	ESX.TriggerServerCallback('d3x_vehicleshop:getVehicles', function (vehicles)
		Vehicles = vehicles
	end)
	Citizen.Wait(1000)
	ESX.TriggerServerCallback('d3x_vehicleshop:getCategories', function (categories)
		Categories = categories
	end)
end)

-- Eventos de carregamento
RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(xPlayer)
	ESX.PlayerData = xPlayer
end)

RegisterNetEvent('d3x_vehicleshop:sendCategories')
AddEventHandler('d3x_vehicleshop:sendCategories', function (categories)
	Categories = categories
end)

RegisterNetEvent('d3x_vehicleshop:sendVehicles')
AddEventHandler('d3x_vehicleshop:sendVehicles', function (vehicles)
	Vehicles = vehicles
end)

function DeleteShopInsideVehicles()
	while #LastVehicles > 0 do
		local vehicle = LastVehicles[1]
		ESX.Game.DeleteVehicle(vehicle)
		table.remove(LastVehicles, 1)
	end
end

function StartShopRestriction()
	Citizen.CreateThread(function()
		while IsInShopMenu do
			Citizen.Wait(1)
			DisableControlAction(0, 75, true)
			DisableControlAction(27, 75, true)
		end
	end)
end

RegisterNUICallback('TestDrive', function(data, cb) 
	SetNuiFocus(false, false)
	local model = data.model
	local playerPed = PlayerPedId()
	local playerpos = GetEntityCoords(playerPed)
	IsInShopMenu = false
	--exports['mythic_notify']:DoHudText('START','waiting','vermelho',_U('wait_vehicle'))
	exports['okokNotify']:Alert("STAND", _U('wait_vehicle'), 3000, 'info')

	ESX.Game.SpawnVehicle(model, Config.Zones.TestDrive.Pos, Config.Zones.TestDrive.Heading, function (vehicle)
		--exports['mythic_notify']:DoHudText('END','waiting')
		exports['okokNotify']:Alert("STAND", "Viatura pronta!", 3000, 'success')
		TaskWarpPedIntoVehicle(playerPed, vehicle, -1)
		SetVehicleNumberPlateText(vehicle, "TEST")
		exports['okokNotify']:Alert("STAND", "Tens 40 segundos para fazer o test-drive.", 3000, 'info')

		local counter = testdrive_timer
		local showTimer = true

		-- Exibir temporizador no canto superior direito
		Citizen.CreateThread(function()
			while showTimer do
				DrawTimerText("TEST DRIVE: " .. counter .. "s restantes")
				Citizen.Wait(0)
			end
		end)

		-- Contador regressivo
		Citizen.CreateThread(function()
			while counter > 0 do
				Citizen.Wait(1000)
				counter = counter - 1
			end

			showTimer = false
			DeleteVehicle(vehicle)
			SetEntityCoords(playerPed, playerpos, false, false, false, false)
			exports['okokNotify']:Alert("STAND", "Teste Drive acabou.", 3000, 'info')
		end)
	end)
end)

RegisterNUICallback('BuyVehicle', function(data, cb)
	SetNuiFocus(false, false)
	local model = data.model
	local playerPed = PlayerPedId()
	IsInShopMenu = false
	--exports['mythic_notify']:PersistentHudText('START','waiting','vermelho',_U('wait_vehicle'))
	exports['okokNotify']:Alert("STAND", _U('wait_vehicle'), 3000, 'info')

	ESX.TriggerServerCallback('d3x_vehicleshop:buyVehicle', function(hasEnoughMoney)
		--exports['mythic_notify']:PersistentHudText('END','waiting')
		exports['okokNotify']:Alert("STAND", "Processo concluído", 3000, 'success')
		if hasEnoughMoney then
			ESX.Game.SpawnVehicle(model, Config.Zones.ShopOutside.Pos, Config.Zones.ShopOutside.Heading, function (vehicle)
				TaskWarpPedIntoVehicle(playerPed, vehicle, -1)
				local newPlate     = GeneratePlate()
				local vehicleProps = ESX.Game.GetVehicleProperties(vehicle)
				vehicleProps.plate = newPlate
				SetVehicleNumberPlateText(vehicle, newPlate)

				if Config.EnableOwnedVehicles then
					local name = GetPlayerName(PlayerId())
					
					TriggerServerEvent('d3x_vehicleshop:setVehicleOwned', vehicleProps)
					TriggerServerEvent('toDiscord', model, name)
				end				
				
				exports['okokNotify']:Alert("STAND", "Viatura, adquirida", 3000, 'success')
			end)
		else
			exports['okokNotify']:Alert("Stand", "Não tens dinheiro suficiente.", 3000, 'error')
		end
	end, model)
end)

RegisterNUICallback('CloseMenu', function(data, cb)
	SetNuiFocus(false, false)
	IsInShopMenu = false
	cb(false)
end)

RegisterCommand('closeshop', function() 
	SetNuiFocus(false, false)
	IsInShopMenu = false
end)

function OpenShopMenu()
	if not IsInShopMenu then
		IsInShopMenu = true
		SetNuiFocus(true, true)
		SendNUIMessage({
			show = true,
			cars = Vehicles,
			categories = Categories
		})
	end
end

-- Blip no mapa
Citizen.CreateThread(function ()
	local blip = AddBlipForCoord(Config.Zones.ShopEntering.Pos.x, Config.Zones.ShopEntering.Pos.y, Config.Zones.ShopEntering.Pos.z)
	SetBlipSprite (blip, 326)
	SetBlipDisplay(blip, 6)
	SetBlipColour(blip, 2)  -- Definindo a cor como verde, por exemplo
	SetBlipScale  (blip, 0.8)
	SetBlipAsShortRange(blip, true)
	BeginTextCommandSetBlipName("STRING")
	AddTextComponentString("Stand")
	EndTextCommandSetBlipName(blip)
end)

-- NPC com ox_target
Citizen.CreateThread(function()
    -- Pega as coordenadas e o heading diretamente do Config.Zones.ShopEntering
    local npcCoords = Config.Zones.ShopEntering.Pos
    local heading = Config.Zones.ShopEntering.Heading or 135.0  -- Caso não tenha um heading no config, usa o default 135.0
    local model = "a_m_y_smartcaspat_01"

    -- Carrega o modelo do NPC
    RequestModel(model)
    while not HasModelLoaded(model) do
        Wait(0)
    end

    -- Cria o NPC
    local npc = CreatePed(4, GetHashKey(model), npcCoords.x, npcCoords.y, npcCoords.z - 1.0, heading, false, true)
    SetEntityInvincible(npc, true)
    SetBlockingOfNonTemporaryEvents(npc, true)
    FreezeEntityPosition(npc, true)
    SetEntityHeading(npc, heading)

    -- Configura o ox_target para interagir com o NPC
    exports.ox_target:addBoxZone({
        coords = vector3(npcCoords.x, npcCoords.y, npcCoords.z),
        size = vec3(2, 2, 2),
        rotation = 0,
        debug = false,
        options = {
            {
                icon = "fas fa-car",
                label = "Abrir Catálogo de Veículos",
                distance = 2.0,
                onSelect = function()
                    OpenShopMenu()
                end
            }
        }
    })
end)


-- okokTextUI barra
Citizen.CreateThread(function()
	local estado_barra = false
	while true do
		Citizen.Wait(100)
		if CurrentAction ~= nil and estado_barra == false then
			estado_barra = true
			if CurrentActionMsg ~= nil and CurrentActionMsg ~= '' then
				exports['okokTextUI']:Open(CurrentActionMsg, 'darkblue', 'left') 
			end
		elseif CurrentAction == nil and estado_barra == true then
			estado_barra = false
			exports['okokTextUI']:Close()
		end
	end
end)

function DrawTimerText(text)
	SetTextFont(0)
	SetTextProportional(1)
	SetTextScale(0.5, 0.5)
	SetTextJustification(0)  -- Centraliza o texto
	SetTextColour(255, 165, 0, 255)  -- Cor laranja
	SetTextDropShadow(0, 0, 0, 0, 255)
	SetTextEdge(1, 0, 0, 0, 255)
	SetTextOutline()
	SetTextEntry("STRING")
	AddTextComponentString(text)
	DrawText(0.5, 0.02) -- Topo central
end



