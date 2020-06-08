local HasAlreadyEnteredMarker, LastZone = false, nil
local CurrentAction, CurrentActionMsg, CurrentActionData = nil, '', {}
local CurrentlyTowedVehicle, Blips, NPCOnJob, NPCTargetTowable, NPCTargetTowableZone = nil, {}, false, nil, nil
local NPCHasSpawnedTowable, NPCLastCancel, NPCHasBeenNextToTowable, NPCTargetDeleterZone = false, GetGameTimer() - 5 * 60000, false, false
local isDead, isBusy = false, false
local spawnedVehicles = {}

ESX = nil

Citizen.CreateThread(function()
	while ESX == nil do
		TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
		Citizen.Wait(0)
	end

	while ESX.GetPlayerData().job == nil do
		Citizen.Wait(10)
	end

	ESX.PlayerData = ESX.GetPlayerData()
end)

-- NPC JOBB
function SelectRandomTowable()
	local index = GetRandomIntInRange(1,  #Config.Towables)

	for k,v in pairs(Config.Stations) do
		if v.Pos.x == Config.Towables[index].x and v.Pos.y == Config.Towables[index].y and v.Pos.z == Config.Towables[index].z then
			return k
		end
	end
end

function StartNPCJob()
	NPCOnJob = true

	NPCTargetTowableZone = SelectRandomTowable()
	local zone       = Config.Stations[NPCTargetTowableZone]

	Blips['NPCTargetTowableZone'] = AddBlipForCoord(zone.Pos.x,  zone.Pos.y,  zone.Pos.z)
	SetBlipRoute(Blips['NPCTargetTowableZone'], true)

	exports['mythic_notify']:SendAlert('inform', (_U('drive_to_indicated')))
end

function StopNPCJob(cancel)
	if Blips['NPCTargetTowableZone'] then
		RemoveBlip(Blips['NPCTargetTowableZone'])
		Blips['NPCTargetTowableZone'] = nil
	end

	if Blips['NPCDelivery'] then
		RemoveBlip(Blips['NPCDelivery'])
		Blips['NPCDelivery'] = nil
	end

	Config.Stations.VehicleDelivery = -1

	NPCOnJob                = false
	NPCTargetTowable        = nil
	NPCTargetTowableZone    = nil
	NPCHasSpawnedTowable    = false
	NPCHasBeenNextToTowable = false

	if cancel then
		exports['mythic_notify']:SendAlert('error', (_U('mission_canceled')))
	else
		--TriggerServerEvent('esx_mechanicjob:onNPCJobCompleted')
	end
end

function setUniform(job, playerPed)
	TriggerEvent('skinchanger:getSkin', function(skin)
		if skin.sex == 0 then
			if Config.Uniforms[job].male then
				TriggerEvent('skinchanger:loadClothes', skin, Config.Uniforms[job].male)
			else
				exports['mythic_notify']:SendAlert('inform', _U('no_outfit'))
			end
		else
			if Config.Uniforms[job].female then
				TriggerEvent('skinchanger:loadClothes', skin, Config.Uniforms[job].female)
			else
				exports['mythic_notify']:SendAlert('inform', _U('no_outfit'))
			end
		end
	end)
end

function OpenCloakroomMenu()
	local playerPed = PlayerPedId()
	local grade = ESX.PlayerData.job.grade_name

	local elements = {
		{ label = _U('civ_wear'), value = 'citizen_wear' },
	}

	if grade == 'recruit' then
		table.insert(elements, {label = 'Arbetskläder (Provanställd)', value = 'recruit_wear'})
	elseif grade == 'novice' then
		table.insert(elements, {label = 'Arbetskläder (Anställd)', value = 'novice_wear'})
	elseif grade == 'experienced' then
		table.insert(elements, {label = 'Arbetskläder (Mellanchef)', value = 'experienced_wear'})
	elseif grade == 'chef' then
		table.insert(elements, {label = "Arbetskläder (Chef)", value = 'chef_wear'})
	elseif grade == 'boss' then
		table.insert(elements, {label = "Arbetskläder (VD)", value = 'boss_wear'})
	end

	ESX.UI.Menu.CloseAll()

	ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'cloakroom', {
		title    = _U('cloakroom'),
		align    = 'right',
		elements = elements
	}, function(data, menu)

		if data.current.value == 'citizen_wear' then
			if Config.EnableNonFreemodePeds then
				ESX.TriggerServerCallback('esx_skin:getPlayerSkin', function(skin, jobSkin)
					local isMale = skin.sex == 0

					TriggerEvent('skinchanger:loadDefaultModel', isMale, function()
						ESX.TriggerServerCallback('esx_skin:getPlayerSkin', function(skin)
							TriggerEvent('skinchanger:loadSkin', skin)
							TriggerEvent('esx:restoreLoadout')
							TriggerServerEvent('esx_policejob:putRadio', 'radio', 1)
						end)
					end)

				end)
			else
				ESX.TriggerServerCallback('esx_skin:getPlayerSkin', function(skin)
					TriggerEvent('skinchanger:loadSkin', skin)
					TriggerServerEvent('esx_policejob:putRadio', 'radio', 1)
				end)
			end

			if Config.MaxInService ~= -1 then
				ESX.TriggerServerCallback('esx_service:isInService', function(isInService)
					if isInService then
						playerInService = false

						local notification = {
							title    = _U('service_anonunce'),
							subject  = '',
							msg      = _U('service_out_announce', GetPlayerName(PlayerId())),
							iconType = 1
						}

						TriggerServerEvent('esx_service:notifyAllInService', notification, 'mekaniker')

						TriggerServerEvent('esx_service:disableService', 'mekaniker')
						TriggerEvent('esx_mekanikerjobb:updateBlip')
						--ESX.ShowNotification(_U('service_out'))
						exports['mythic_notify']:SendAlert('inform', _U('service_out'))
					end
				end, 'mekaniker')
			end
		end

		if Config.MaxInService ~= -1 and data.current.value ~= 'citizen_wear' then
			local serviceOk = 'waiting'

			ESX.TriggerServerCallback('esx_service:isInService', function(isInService)
				if not isInService then

					ESX.TriggerServerCallback('esx_service:enableService', function(canTakeService, maxInService, inServiceCount)
						if not canTakeService then
							--ESX.ShowNotification(_U('service_max', inServiceCount, maxInService))
							exports['mythic_notify']:SendAlert('inform', _U('service_max', inServiceCount, maxInService))
						else
							serviceOk = true
							playerInService = true

							local notification = {
								title    = _U('service_anonunce'),
								subject  = '',
								msg      = _U('service_in_announce', GetPlayerName(PlayerId())),
								iconType = 1
							}

							TriggerServerEvent('esx_service:notifyAllInService', notification, 'mekaniker')
							TriggerEvent('esx_mekanikerjobb:updateBlip')
							--ESX.ShowNotification(_U('service_in'))
							exports['mythic_notify']:SendAlert('inform', _U('service_in'))
						end
					end, 'mekaniker')

				else
					serviceOk = true
				end
			end, 'mekaniker')

			while type(serviceOk) == 'string' do
				Citizen.Wait(5)
			end

			-- if we couldn't enter service don't let the player get changed
			if not serviceOk then
				return
			end
		end

		if
			data.current.value == 'recruit_wear' or
			data.current.value == 'novice_wear' or
			data.current.value == 'experienced_wear' or
			data.current.value == 'chef_wear' or
			data.current.value == 'boss_wear'
		then
			setUniform(data.current.value, playerPed)
            ClearPedBloodDamage(playerPed)
            ResetPedVisibleDamage(playerPed)
			ClearPedLastWeaponDamage(playerPed)
			TriggerServerEvent('esx_policejob:getRadio', 'radio', 1)
		end

		if data.current.value == 'freemode_ped' then
			local modelHash = ''

			ESX.TriggerServerCallback('esx_skin:getPlayerSkin', function(skin, jobSkin)
				if skin.sex == 0 then
					modelHash = GetHashKey(data.current.maleModel)
				else
					modelHash = GetHashKey(data.current.femaleModel)
				end

				ESX.Streaming.RequestModel(modelHash, function()
					SetPlayerModel(PlayerId(), modelHash)
					SetModelAsNoLongerNeeded(modelHash)

					TriggerEvent('esx:restoreLoadout')
				end)
			end)
		end
	end, function(data, menu)
		menu.close()

		CurrentAction     = 'menu_cloakroom'
		CurrentActionMsg  = _U('open_cloackroom')
		CurrentActionData = {}
	end)
end

function OpenArmoryMenu(station)
	local elements = {
		--table.insert(elements, {label = ('Plocka ut från förrådet'), value = 'get_stock'})
	}

	if ESX.PlayerData.job.grade_name == 'boss' then
		
	end

	ESX.UI.Menu.CloseAll()

	ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'armory', {
		title    = _U('armory'),
		align    = 'right',
		elements = elements
	}, function(data, menu)

		if data.current.value == 'put_stock' then
			OpenPutStocksMenu()
		elseif data.current.value == 'get_stock' then
			OpenGetStocksMenu()
		end

	end, function(data, menu)
		menu.close()

		CurrentAction     = 'menu_armory'
		CurrentActionMsg  = _U('open_armory')
		CurrentActionData = {station = station}
	end)
end

function OpenVehicleSpawnerMenu(type, station, part, partNum)
	local playerCoords = GetEntityCoords(PlayerPedId())
	ESX.PlayerData = ESX.GetPlayerData()
	local elements = {
		{label = _U('garage_storeditem'), action = 'garage'},
		{label = _U('garage_storeitem'), action = 'store_garage'},
		{label = _U('garage_buyitem'), action = 'buy_vehicle'}
	}

	ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'vehicle', {
		title    = _U('garage_title'),
		align    = 'right',
		elements = elements
	}, function(data, menu)
		if data.current.action == 'buy_vehicle' then
			local shopElements, shopCoords = {}

			if type == 'car' then
				shopCoords = Config.Stations[station].Vehicles[partNum].InsideShop
				local authorizedVehicles = Config.AuthorizedVehicles[ESX.PlayerData.job.grade_name]

				if #Config.AuthorizedVehicles.Shared > 0 then
					for k,vehicle in ipairs(Config.AuthorizedVehicles.Shared) do
						table.insert(shopElements, {
							label = ('%s - <span style="color: #771282;">%s</span>'):format(vehicle.label, _U('shop_item', ESX.Math.GroupDigits(vehicle.price))),
							name  = vehicle.label,
							model = vehicle.model,
							price = vehicle.price,
							type  = 'car'
						})
					end
				end

				if #authorizedVehicles > 0 then
					for k,vehicle in ipairs(authorizedVehicles) do
						table.insert(shopElements, {
							label = ('%s - <span style="color: #771282;">%s</span>'):format(vehicle.label, _U('shop_item', ESX.Math.GroupDigits(vehicle.price))),
							name  = vehicle.label,
							model = vehicle.model,
							price = vehicle.price,
							type  = 'car'
						})
					end
				else
					if #Config.AuthorizedVehicles.Shared == 0 then
						return
					end
				end
			elseif type == 'helicopter' then
				shopCoords = Config.Stations[station].Helicopters[partNum].InsideShop
				local authorizedHelicopters = Config.AuthorizedHelicopters[ESX.PlayerData.job.grade_name]

				if #authorizedHelicopters > 0 then
					for k,vehicle in ipairs(authorizedHelicopters) do
						table.insert(shopElements, {
							label = ('%s - <span style="color: #771282;">%s</span>'):format(vehicle.label, _U('shop_item', ESX.Math.GroupDigits(vehicle.price))),
							name  = vehicle.label,
							model = vehicle.model,
							price = vehicle.price,
							livery = vehicle.livery or nil,
							type  = 'helicopter'
						})
					end
				else
					--ESX.ShowNotification(_U('helicopter_notauthorized'))
					exports['mythic_notify']:SendAlert('inform', _U('helicopter_notauthorized'))
					return
				end
			end

			OpenShopMenu(shopElements, playerCoords, shopCoords)
		elseif data.current.action == 'garage' then
			local garage = {}

			ESX.TriggerServerCallback('esx_vehicleshop:retrieveJobVehicles', function(jobVehicles)
				if #jobVehicles > 0 then
					for k,v in ipairs(jobVehicles) do
						local props = json.decode(v.vehicle)
						local vehicleName = GetLabelText(GetDisplayNameFromVehicleModel(props.model))
						local label = ('%s - <span style="color: #771282;">%s</span>: '):format(vehicleName, props.plate)

						if v.stored then
							label = label .. ('<span style="color:green;">%s</span>'):format(_U('garage_stored'))
						else
							label = label .. ('<span style="color:red;">%s</span>'):format(_U('garage_notstored'))
						end

						table.insert(garage, {
							label = label,
							stored = v.stored,
							model = props.model,
							vehicleProps = props
						})
					end

					ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'vehicle_garage', {
						title    = _U('garage_title'),
						align    = 'right',
						elements = garage
					}, function(data2, menu2)
						if data2.current.stored then
							local foundSpawn, spawnPoint = GetAvailableVehicleSpawnPoint(station, part, partNum)

							if foundSpawn then
								menu2.close()

								ESX.Game.SpawnVehicle(data2.current.model, spawnPoint.coords, spawnPoint.heading, function(vehicle)
									ESX.Game.SetVehicleProperties(vehicle, data2.current.vehicleProps)

									TriggerServerEvent('esx_vehicleshop:setJobVehicleState', data2.current.vehicleProps.plate, false)
									--ESX.ShowNotification(_U('garage_released'))
									exports['mythic_notify']:SendAlert('inform', _U('garage_released'))
								end)
							end
						else
							--ESX.ShowNotification(_U('garage_notavailable'))
							exports['mythic_notify']:SendAlert('inform', _U('garage_notavailable'))
						end
					end, function(data2, menu2)
						menu2.close()
					end)
				else
					--ESX.ShowNotification(_U('garage_empty'))
					exports['mythic_notify']:SendAlert('inform', _U('garage_empty'))
				end
			end, type)
		elseif data.current.action == 'store_garage' then
			StoreNearbyVehicle(playerCoords)
		end
	end, function(data, menu)
		menu.close()
	end)
end

function StoreNearbyVehicle(playerCoords)
	local vehicles, vehiclePlates = ESX.Game.GetVehiclesInArea(playerCoords, 30.0), {}

	if #vehicles > 0 then
		for k,v in ipairs(vehicles) do

			-- Make sure the vehicle we're saving is empty, or else it wont be deleted
			if GetVehicleNumberOfPassengers(v) == 0 and IsVehicleSeatFree(v, -1) then
				table.insert(vehiclePlates, {
					vehicle = v,
					plate = ESX.Math.Trim(GetVehicleNumberPlateText(v))
				})
			end
		end
	else
		--ESX.ShowNotification(_U('garage_store_nearby'))
		exports['mythic_notify']:SendAlert('inform', _U('garage_store_nearby'))
		return
	end

	ESX.TriggerServerCallback('esx_mekanikerjobb:storeNearbyVehicle', function(storeSuccess, foundNum)
		if storeSuccess then
			local vehicleId = vehiclePlates[foundNum]
			local attempts = 0
			ESX.Game.DeleteVehicle(vehicleId.vehicle)
			IsBusy = true

			Citizen.CreateThread(function()
				BeginTextCommandBusyString('STRING')
				AddTextComponentSubstringPlayerName(_U('garage_storing'))
				EndTextCommandBusyString(4)

				while IsBusy do
					Citizen.Wait(100)
				end

				RemoveLoadingPrompt()
			end)

			-- Workaround for vehicle not deleting when other players are near it.
			while DoesEntityExist(vehicleId.vehicle) do
				Citizen.Wait(500)
				attempts = attempts + 1

				-- Give up
				if attempts > 30 then
					break
				end

				vehicles = ESX.Game.GetVehiclesInArea(playerCoords, 30.0)
				if #vehicles > 0 then
					for k,v in ipairs(vehicles) do
						if ESX.Math.Trim(GetVehicleNumberPlateText(v)) == vehicleId.plate then
							ESX.Game.DeleteVehicle(v)
							break
						end
					end
				end
			end

			IsBusy = false
			--ESX.ShowNotification(_U('garage_has_stored'))
			exports['mythic_notify']:SendAlert('inform', _U('garage_has_stored'))
		else
			--ESX.ShowNotification(_U('garage_has_notstored'))
			exports['mythic_notify']:SendAlert('inform', _U('garage_has_notstored'))
		end
	end, vehiclePlates)
end

function GetAvailableVehicleSpawnPoint(station, part, partNum)
	local spawnPoints = Config.Stations[station][part][partNum].SpawnPoints
	local found, foundSpawnPoint = false, nil

	for i=1, #spawnPoints, 1 do
		if ESX.Game.IsSpawnPointClear(spawnPoints[i].coords, spawnPoints[i].radius) then
			found, foundSpawnPoint = true, spawnPoints[i]
			break
		end
	end

	if found then
		return true, foundSpawnPoint
	else
		--ESX.ShowNotification(_U('vehicle_blocked'))
		exports['mythic_notify']:SendAlert('inform', _U('vehicle_blocked'))
		return false
	end
end

function OpenShopMenu(elements, restoreCoords, shopCoords)
	local playerPed = PlayerPedId()
	isInShopMenu = true

	ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'vehicle_shop', {
		title    = _U('vehicleshop_title'),
		align    = 'right',
		elements = elements
	}, function(data, menu)
		ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'vehicle_shop_confirm', {
			title    = _U('vehicleshop_confirm', data.current.name, data.current.price),
			align    = 'right',
			elements = {
				{label = _U('confirm_no'), value = 'no'},
				{label = _U('confirm_yes'), value = 'yes'}
		}}, function(data2, menu2)
			if data2.current.value == 'yes' then
				local newPlate = exports['esx_vehicleshop']:GeneratePlate()
				local vehicle  = GetVehiclePedIsIn(playerPed, false)
				local props    = ESX.Game.GetVehicleProperties(vehicle)
				props.plate    = newPlate

				ESX.TriggerServerCallback('esx_mekanikerjobb:buyJobVehicle', function (bought)
					if bought then
						--ESX.ShowNotification(_U('vehicleshop_bought', data.current.name, ESX.Math.GroupDigits(data.current.price)))
						exports['mythic_notify']:SendAlert('inform', _U('vehicleshop_bought', data.current.name, ESX.Math.GroupDigits(data.current.price)))

						isInShopMenu = false
						ESX.UI.Menu.CloseAll()
						DeleteSpawnedVehicles()
						FreezeEntityPosition(playerPed, false)
						SetEntityVisible(playerPed, true)

						ESX.Game.Teleport(playerPed, restoreCoords)
					else
						--ESX.ShowNotification(_U('vehicleshop_money'))
						exports['mythic_notify']:SendAlert('inform', _U('vehicleshop_money'))
						menu2.close()
					end
				end, props, data.current.type)
			else
				menu2.close()
			end
		end, function(data2, menu2)
			menu2.close()
		end)
	end, function(data, menu)
		isInShopMenu = false
		ESX.UI.Menu.CloseAll()

		DeleteSpawnedVehicles()
		FreezeEntityPosition(playerPed, false)
		SetEntityVisible(playerPed, true)

		ESX.Game.Teleport(playerPed, restoreCoords)
	end, function(data, menu)
		DeleteSpawnedVehicles()
		WaitForVehicleToLoad(data.current.model)

		ESX.Game.SpawnLocalVehicle(data.current.model, shopCoords, 0.0, function(vehicle)
			table.insert(spawnedVehicles, vehicle)
			TaskWarpPedIntoVehicle(playerPed, vehicle, -1)
			FreezeEntityPosition(vehicle, true)
			SetModelAsNoLongerNeeded(data.current.model)

			if data.current.livery then
				SetVehicleModKit(vehicle, 0)
				SetVehicleLivery(vehicle, data.current.livery)
			end
		end)
	end)

	WaitForVehicleToLoad(elements[1].model)
	ESX.Game.SpawnLocalVehicle(elements[1].model, shopCoords, 0.0, function(vehicle)
		table.insert(spawnedVehicles, vehicle)
		TaskWarpPedIntoVehicle(playerPed, vehicle, -1)
		FreezeEntityPosition(vehicle, true)
		SetModelAsNoLongerNeeded(elements[1].model)

		if elements[1].livery then
			SetVehicleModKit(vehicle, 0)
			SetVehicleLivery(vehicle, elements[1].livery)
		end
	end)
end

Citizen.CreateThread(function()
	while true do
		Citizen.Wait(0)

		if isInShopMenu then
			DisableControlAction(0, 75, true)  -- Disable exit vehicle
			DisableControlAction(27, 75, true) -- Disable exit vehicle
		else
			Citizen.Wait(500)
		end
	end
end)

function DeleteSpawnedVehicles()
	while #spawnedVehicles > 0 do
		local vehicle = spawnedVehicles[1]
		ESX.Game.DeleteVehicle(vehicle)
		table.remove(spawnedVehicles, 1)
	end
end

function WaitForVehicleToLoad(modelHash)
	modelHash = (type(modelHash) == 'number' and modelHash or GetHashKey(modelHash))

	if not HasModelLoaded(modelHash) then
		RequestModel(modelHash)

		BeginTextCommandBusyString('STRING')
		AddTextComponentSubstringPlayerName(_U('vehicleshop_awaiting_model'))
		EndTextCommandBusyString(4)

		while not HasModelLoaded(modelHash) do
			Citizen.Wait(0)
			DisableAllControlActions(0)
		end

		RemoveLoadingPrompt()
	end
end

function OpenMechanicActionsMenu()
	ESX.UI.Menu.CloseAll()

	ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'mekaniker_actions', {
		title    = 'Mekaniker',
		align    = 'right',
		elements = {
			{label = ('Reparera fordon'), value = 'repair_meny'},
			{label = _U('hijack'),        value = 'hijack_vehicle'},
			--{label = _U('imp_veh'),       value = 'del_vehicle'},
			{label = _U('flat_bed'),      value = 'dep_vehicle'},
			{label = _U('place_objects'), value = 'object_spawner'},
			{label = _U('billing'),       value = 'fine'},
	}}, function(data, menu)
		if isBusy then return end

		if data.current.value == 'fine' then
			OpenFineMenu(player)
		end
		if data.current.value == 'billing' then
			ESX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'billing', {
				title = _U('invoice_amount')
			}, function(data, menu)
				local amount = tonumber(data.value)

				if amount == nil or amount < 0 then
					exports['mythic_notify']:SendAlert('error',(_U('amount_invalid')))
				else
					local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
					if closestPlayer == -1 or closestDistance > 3.0 then
						exports['mythic_notify']:SendAlert('error', (_U('no_players_nearby')))
					else
						menu.close()
						TriggerServerEvent('esx_billing:sendBill', GetPlayerServerId(closestPlayer), 'society_mekaniker', _U('mechanic'), amount)
					end
				end
			end, function(data, menu)
				menu.close()
			end)
		elseif data.current.value == 'hijack_vehicle' then
			local playerPed = PlayerPedId()
			local vehicle   = ESX.Game.GetVehicleInDirection()
			local coords    = GetEntityCoords(playerPed)

			if IsPedSittingInAnyVehicle(playerPed) then
				exports['mythic_notify']:SendAlert('error', (_U('inside_vehicle')))
				return
			end

			if DoesEntityExist(vehicle) then
				isBusy = true
				TaskStartScenarioInPlace(playerPed, 'WORLD_HUMAN_WELDING', 0, true)
				Citizen.CreateThread(function()
					Citizen.Wait(10000)

					SetVehicleDoorsLocked(vehicle, 1)
					SetVehicleDoorsLockedForAllPlayers(vehicle, false)
					ClearPedTasksImmediately(playerPed)

					exports['mythic_notify']:SendAlert('success', (_U('vehicle_unlocked')))
					isBusy = false
				end)
			else
				exports['mythic_notify']:SendAlert('error', (_U('no_vehicle_nearby')))
			end

		elseif data.current.value == 'repair_meny' then
			OpenRepairMenu()
		
		elseif data.current.value == 'del_vehicle' then
			local playerPed = PlayerPedId()

			if IsPedSittingInAnyVehicle(playerPed) then
				local vehicle = GetVehiclePedIsIn(playerPed, false)

				if GetPedInVehicleSeat(vehicle, -1) == playerPed then
					exports['mythic_notify']:SendAlert('success', (_U('vehicle_impounded')))
					ESX.Game.DeleteVehicle(vehicle)
				else
					exports['mythic_notify']:SendAlert('error', (_U('must_seat_driver')))
				end
			else
				local vehicle = ESX.Game.GetVehicleInDirection()

				if DoesEntityExist(vehicle) then
					exports['mythic_notify']:SendAlert('success', (_U('vehicle_impounded')))
					ESX.Game.DeleteVehicle(vehicle)
				else
					exports['mythic_notify']:SendAlert('error', (_U('must_near')))
				end
			end
		elseif data.current.value == 'dep_vehicle' then
			local playerPed = PlayerPedId()
			local vehicle = GetVehiclePedIsIn(playerPed, true)

			local towmodel = GetHashKey('flatbed')
			local isVehicleTow = IsVehicleModel(vehicle, towmodel)

			if isVehicleTow then
				local targetVehicle = ESX.Game.GetVehicleInDirection()

				if CurrentlyTowedVehicle == nil then
					if targetVehicle ~= 0 then
						if not IsPedInAnyVehicle(playerPed, true) then
							if vehicle ~= targetVehicle then
								AttachEntityToEntity(targetVehicle, vehicle, 20, 0.0, -5.5, 0.5, 0.0, 0.0, 0.0, false, false, false, false, 20, true)
								CurrentlyTowedVehicle = targetVehicle
								exports['mythic_notify']:SendAlert('success', (_U('vehicle_success_attached')))

								if NPCOnJob then
									if NPCTargetTowable == targetVehicle then
										exports['mythic_notify']:SendAlert('inform', (_U('please_drop_off')))
										Config.Stations.VehicleDelivery = 1

										if Blips['NPCTargetTowableZone'] then
											RemoveBlip(Blips['NPCTargetTowableZone'])
											Blips['NPCTargetTowableZone'] = nil
										end

										Blips['NPCDelivery'] = AddBlipForCoord(Config.Stations.VehicleDelivery.Pos.x, Config.Stations.VehicleDelivery.Pos.y, Config.Stations.VehicleDelivery.Pos.z)
										SetBlipRoute(Blips['NPCDelivery'], true)
									end
								end
							else
								exports['mythic_notify']:SendAlert('error', (_U('cant_attach_own_tt')))
							end
						end
					else
						exports['mythic_notify']:SendAlert('error', (_U('no_veh_att')))
					end
				else
					AttachEntityToEntity(CurrentlyTowedVehicle, vehicle, 20, -0.5, -12.0, 0.3, 0.0, 0.0, 0.0, false, false, false, false, 20, true)
					DetachEntity(CurrentlyTowedVehicle, true, true)

					if NPCOnJob then
						if NPCTargetDeleterZone then

							if CurrentlyTowedVehicle == NPCTargetTowable then
								ESX.Game.DeleteVehicle(NPCTargetTowable)
								TriggerServerEvent('esx_mechanicjob:onNPCJobMissionCompleted')
								StopNPCJob()
								NPCTargetDeleterZone = false
							else
								exports['mythic_notify']:SendAlert('error', (_U('not_right_veh')))
							end

						else
							exports['mythic_notify']:SendAlert('error', (_U('not_right_place')))
						end
					end

					CurrentlyTowedVehicle = nil
					exports['mythic_notify']:SendAlert('success', (_U('veh_det_succ')))
				end
			else
				exports['mythic_notify']:SendAlert('error', (_U('imp_flatbed')))
			end
		elseif data.current.value == 'object_spawner' then
			local playerPed = PlayerPedId()

			if IsPedSittingInAnyVehicle(playerPed) then
				exports['mythic_notify']:SendAlert('error', (_U('inside_vehicle')))
				return
			end

			ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'mobile_mechanic_actions_spawn', {
				title    = _U('objects'),
				align    = 'right',
				elements = {
					{label = _U('roadcone'), value = 'prop_roadcone02a'},
					{label = _U('toolbox'),  value = 'prop_toolchest_01'}
			}}, function(data2, menu2)
				local model   = data2.current.value
				local coords  = GetEntityCoords(playerPed)
				local forward = GetEntityForwardVector(playerPed)
				local x, y, z = table.unpack(coords + forward * 1.0)

				if model == 'prop_roadcone02a' then
					z = z - 2.0
				elseif model == 'prop_toolchest_01' then
					z = z - 2.0
				end

				ESX.Game.SpawnObject(model, {x = x, y = y, z = z}, function(obj)
					SetEntityHeading(obj, GetEntityHeading(playerPed))
					PlaceObjectOnGroundProperly(obj)
				end)
			end, function(data2, menu2)
				menu2.close()
			end)
		end
	end, function(data, menu)
		menu.close()
	end)
end

function OpenRepairMenu()
	local elements = {
		{label = ('Reparera Motor'), value = 'fix_motor'},
		{label = ('Reparera Kaross'), value = 'fix_body'},
		{label = ('Byt Däck'), value = 'fix_tyre'},
		--{label = _U('clean'), value = 'wash'}
	}

	ESX.UI.Menu.CloseAll()

	ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'repair_actions', {
		title    = ('Repair'),
		align    = 'right',
		elements = elements
	}, function(data, menu)
		if data.current.value == 'fix_motor' then
			repairMotor()
		elseif data.current.value == 'fix_body' then
			repairBody()
		elseif data.current.value == 'wash' then
			Wash()
		elseif data.current.value == 'fix_tyre' then
			fixTyre()
		end
	end, function(data, menu)
		menu.close()
	end)
end

function OpenGetStocksMenu()
	ESX.TriggerServerCallback('esx_mechanicjob:getStockItems', function(items)
		local elements = {}

		for i=1, #items, 1 do
			table.insert(elements, {
				label = 'x' .. items[i].count .. ' ' .. items[i].label,
				value = items[i].name
			})
		end

		ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'stocks_menu', {
			title    = _U('mechanic_stock'),
			align    = 'right',
			elements = elements
		}, function(data, menu)
			local itemName = data.current.value

			ESX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'stocks_menu_get_item_count', {
				title = _U('quantity')
			}, function(data2, menu2)
				local count = tonumber(data2.value)

				if count == nil then
					exports['mythic_notify']:SendAlert('error',(_U('invalid_quantity')))
				else
					menu2.close()
					menu.close()
					TriggerServerEvent('esx_mechanicjob:getStockItem', itemName, count)

					Citizen.Wait(1000)
					OpenGetStocksMenu()
				end
			end, function(data2, menu2)
				menu2.close()
			end)
		end, function(data, menu)
			menu.close()
		end)
	end)
end

function OpenPutStocksMenu()
	ESX.TriggerServerCallback('esx_mechanicjob:getPlayerInventory', function(inventory)
		local elements = {}

		for i=1, #inventory.items, 1 do
			local item = inventory.items[i]

			if item.count > 0 then
				table.insert(elements, {
					label = item.label .. ' x' .. item.count,
					type  = 'item_standard',
					value = item.name
				})
			end
		end

		ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'stocks_menu', {
			title    = _U('inventory'),
			align    = 'right',
			elements = elements
		}, function(data, menu)
			local itemName = data.current.value

			ESX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'stocks_menu_put_item_count', {
				title = _U('quantity')
			}, function(data2, menu2)
				local count = tonumber(data2.value)

				if count == nil then
					exports['mythic_notify']:SendAlert('error', (_U('invalid_quantity')))
				else
					menu2.close()
					menu.close()
					TriggerServerEvent('esx_mechanicjob:putStockItems', itemName, count)

					Citizen.Wait(1000)
					OpenPutStocksMenu()
				end
			end, function(data2, menu2)
				menu2.close()
			end)
		end, function(data, menu)
			menu.close()
		end)
	end)
end

function repairMotor()
	local playerPed = PlayerPedId()
	local vehicle   = ESX.Game.GetVehicleInDirection()
	local coords    = GetEntityCoords(playerPed)
	
	if IsPedSittingInAnyVehicle(playerPed) then
		exports['mythic_notify']:SendAlert('error', (_U('inside_vehicle')))
		return
	end

	if DoesEntityExist(vehicle) then
		isBusy = true
		SetVehicleDoorOpen(vehicle,4,0,0)
		exports['mythic_progbar']:Progress({
			name = "mechanicRepair",
			duration = 60000,
			label = "Reparerar Motorn",
			useWhileDead = false,
			canCancel = true,
			controlDisables = {
				disableMovement = true,
				disableCarMovement = true,
				disableMouse = false,
				disableCombat = true,
			},
			animation = {
				animDict = "mini@repair",
				anim = "fixing_a_ped",
			},
			prop = {
				model = "prop_tool_screwdvr03",
				bone = 58870,
				coords = { x = 0.00, y = 0.05, z = 0.15 },
				rotation = { x = 180.0, y = 0.0, z = 0.0 },
			}
		}, function(status)
			if not status then
				SetVehicleFixed(vehicle)
				SetVehicleEngineHealth(vehicle, 1000.0)
				SetVehicleEngineOn(vehicle, true, true)
				SetVehicleUndriveable(vehicle, false)
				ClearPedTasks(playerPed)
				SetVehicleDoorShut(vehicle,4,0)

			exports['mythic_notify']:SendAlert('Success', (_U('vehicle_repaired')))
			isBusy = false
			end
		end)
	else
		exports['mythic_notify']:SendAlert('error',(_U('no_vehicle_nearby')))
	end
end

function repairBody()
	local playerPed = PlayerPedId()
	local vehicle   = ESX.Game.GetVehicleInDirection()
	local engineHealth = GetVehicleEngineHealth(vehicle)
	local coords    = GetEntityCoords(playerPed)

	if IsPedSittingInAnyVehicle(playerPed) then
		exports['mythic_notify']:SendAlert('error', (_U('inside_vehicle')))
		return
	end

	if DoesEntityExist(vehicle) then
	isBusy = true
	
		exports['mythic_progbar']:Progress({
			name = "mechanicRepair",
			duration = 60000,
			label = "Reparerar Kaross",
			useWhileDead = false,
			canCancel = true,
			controlDisables = {
				disableMovement = true,
				disableCarMovement = true,
				disableMouse = false,
				disableCombat = true,
			},
			animation = {
				animDict = "amb@world_human_welding@male@idle_a",
				anim = "idle_b",
			},
			prop = {
				model = "prop_weld_torch",
				bone = 58870,
				coords = { x = 0.00, y = 0.00, z = 0.0 },
				rotation = { x = 100.0, y = 0.0, z = 180.0 }
			}
		}, function(status)
			if not status then
				SetVehicleFixed(vehicle)
				SetVehicleEngineHealth(vehicle, engineHealth)
				ClearPedTasks(playerPed)
				exports['mythic_notify']:SendAlert('Success', (_U('vehicle_repaired')))
			isBusy = false
			end
		end)
	else
		exports['mythic_notify']:SendAlert('error',(_U('no_vehicle_nearby')))
	end
end

function Wash()
	local playerPed = PlayerPedId()
	local vehicle   = ESX.Game.GetVehicleInDirection()
	local coords    = GetEntityCoords(playerPed)

		if IsPedSittingInAnyVehicle(playerPed) then
			exports['mythic_notify']:SendAlert('error', (_U('inside_vehicle')))
			return
		end

		if DoesEntityExist(vehicle) then
			exports['mythic_progbar']:Progress({
				name = "mechanicWash",
				duration = 60000,
				label = "Tvättar",
				useWhileDead = false,
				canCancel = true,
				controlDisables = {
					disableMovement = true,
					disableCarMovement = true,
					disableMouse = false,
					disableCombat = true,
				},
					animation = {
						animDict = "amb@world_human_maid_clean@base",
						anim = "base",
					},
					prop = {
						model = "prop_sponge_01",
						bone = 58870,
						coords = { x = 0.00, y = 0.05, z = 0.0 },
						rotation = { x = 180.0, y = 0.0, z = 0.0 },
					}
				}, function(cancelled)
					if not cancelled then
					SetVehicleDirtLevel(vehicle, 0)
					ClearPedTasksImmediately(playerPed)
					exports['mythic_notify']:SendAlert('success', (_U('vehicle_cleaned')))
				else
					ClearPedTasksImmediately(PlayerPed)
					end
				end)
			else
				exports['mythic_notify']:SendAlert('error', (_U('no_vehicle_nearby')))
			end
		end

function fixTyre()
	local playerPed = PlayerPedId()
	local vehicle   = ESX.Game.GetVehicleInDirection()
	local coords    = GetEntityCoords(playerPed)

		if IsPedSittingInAnyVehicle(playerPed) then
			exports['mythic_notify']:SendAlert('error', (_U('inside_vehicle')))
			return
		end

		if DoesEntityExist(vehicle) then
			exports['mythic_progbar']:Progress({
				name = "mechanicTyre",
				duration = 60000,
				label = "Byter Däck",
				useWhileDead = false,
				canCancel = true,
				controlDisables = {
					disableMovement = true,
					disableCarMovement = true,
					disableMouse = false,
					disableCombat = true,
				},
					animation = {
						animDict = "anim@amb@clubhouse@tutorial@bkr_tut_ig3@",
						anim = "machinic_loop_mechandplayer",
					},
					prop = {
						model = "prop_tool_spanner02",
						bone = 58870,
						coords = { x = 0.00, y = 0.0, z = 0.05 },
						rotation = { x = 0.0, y = 0.0, z = 0.0 },
					}
				}, function(status)
					if not status then
						SetVehicleTyreFixed(vehicle, 0)
						SetVehicleTyreFixed(vehicle, 1)
						SetVehicleTyreFixed(vehicle, 2)
						SetVehicleTyreFixed(vehicle, 3)
						SetVehicleTyreFixed(vehicle, 4)
						SetVehicleTyreFixed(vehicle, 5)
						SetVehicleTyreFixed(vehicle, 45)
						SetVehicleTyreFixed(vehicle, 47)
						SetVehicleEngineOn(vehicle, true, true)
					ClearPedTasksImmediately(playerPed)

					exports['mythic_notify']:SendAlert('success', (_U('vehicle_cleaned')))
					end
				end)
			else
				exports['mythic_notify']:SendAlert('error', (_U('no_vehicle_nearby')))
			end
		end

function OpenFineMenu(player)

ESX.UI.Menu.Open(
	'default', GetCurrentResourceName(), 'fine',
	{
	title    = _U('fine'),
	align    = 'right',
	elements = {
		{label = _U('service'),   value = 0},
	},
	},
	function(data, menu)
		  
	OpenFineCategoryMenu(player, data.current.value)
		  
	end,
	function(data, menu)
	menu.close()
	end
)
		  
end

function OpenFineCategoryMenu(player, category)

ESX.UI.Menu.Open(
	'dialog', GetCurrentResourceName(), 'set_vehicle_owner_sell_amount',
	{
	title = _U('invoice_amount'),
	},
	function (data2, menu)
	
	local amount = tonumber(data2.value)
	
	if amount == nil then
		ESX.ShowNotification(_U('invoice_amount'))
	else
		menu.close()
	
		local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
	
		if closestPlayer == -1 or closestDistance > 3.0 then
		ESX.ShowNotification(_U('invoice_amount'))
		else
		TriggerServerEvent('esx_billing:sendBill', GetPlayerServerId(closestPlayer), 'society_mecano', ('Mekonomen'), tonumber(data2.value))
		end
	end
end,
	function (data2, menu)
	menu.close()
	end
)
end

RegisterNetEvent('esx_mechanicjob:onHijack')
AddEventHandler('esx_mechanicjob:onHijack', function()
	local playerPed = PlayerPedId()
	local coords    = GetEntityCoords(playerPed)
		  
	if IsAnyVehicleNearPoint(coords.x, coords.y, coords.z, 5.0) then
		local vehicle
		  
	if IsPedInAnyVehicle(playerPed, false) then
		vehicle = GetVehiclePedIsIn(playerPed, false)
	else
		vehicle = GetClosestVehicle(coords.x, coords.y, coords.z, 5.0, 0, 71)
	end
		  
	local chance = math.random(100)
	local alarm  = math.random(100)
		  
	if DoesEntityExist(vehicle) then
		if alarm <= 33 then
			SetVehicleAlarm(vehicle, true)
			StartVehicleAlarm(vehicle)
		end
		  
		TaskStartScenarioInPlace(playerPed, 'WORLD_HUMAN_WELDING', 0, true)
		  
		Citizen.CreateThread(function()
			Citizen.Wait(10000)
				if chance <= 66 then
					SetVehicleDoorsLocked(vehicle, 1)
					SetVehicleDoorsLockedForAllPlayers(vehicle, false)
					ClearPedTasksImmediately(playerPed)
					xports['mythic_notify']:SendAlert('success',(_U('veh_unlocked')))
				else
					exports['mythic_notify']:SendAlert('error',(_U('hijack_failed')))
					ClearPedTasksImmediately(playerPed)
				end
			end)
		end
	end
end)
		  
RegisterNetEvent('esx_mechanicjob:onCarokit')
AddEventHandler('esx_mechanicjob:onCarokit', function()
	local playerPed = PlayerPedId()
	local coords    = GetEntityCoords(playerPed)
		  
if IsAnyVehicleNearPoint(coords.x, coords.y, coords.z, 5.0) then
	local vehicle
		  
if IsPedInAnyVehicle(playerPed, false) then
	vehicle = GetVehiclePedIsIn(playerPed, false)
else
	vehicle = GetClosestVehicle(coords.x, coords.y, coords.z, 5.0, 0, 71)
end
		  
			if DoesEntityExist(vehicle) then
				TaskStartScenarioInPlace(playerPed, 'WORLD_HUMAN_HAMMERING', 0, true)
				Citizen.CreateThread(function()
				Citizen.Wait(10000)
				SetVehicleFixed(vehicle)
				SetVehicleDeformationFixed(vehicle)
				ClearPedTasksImmediately(playerPed)
				exports['mythic_notify']:SendAlert('success', (_U('body_repaired')))
			end)
		end
	end
end)
		  
RegisterNetEvent('esx_mechanicjob:onFixkit')
AddEventHandler('esx_mechanicjob:onFixkit', function()
local playerPed = PlayerPedId()
local coords    = GetEntityCoords(playerPed)
		  
	if IsAnyVehicleNearPoint(coords.x, coords.y, coords.z, 5.0) then
	local vehicle
		  
		if IsPedInAnyVehicle(playerPed, false) then
			vehicle = GetVehiclePedIsIn(playerPed, false)
		else
			ehicle = GetClosestVehicle(coords.x, coords.y, coords.z, 5.0, 0, 71)
		end
		  
		if DoesEntityExist(vehicle) then
			TaskStartScenarioInPlace(playerPed, 'PROP_HUMAN_BUM_BIN', 0, true)
			Citizen.CreateThread(function()
			Citizen.Wait(20000)
			SetVehicleFixed(vehicle)
			SetVehicleDeformationFixed(vehicle)
			SetVehicleUndriveable(vehicle, false)
			ClearPedTasksImmediately(playerPed)
			exports['mythic_notify']:SendAlert('success',(_U('veh_repaired')))
			end)
		end
	end
end)

RegisterNetEvent('esx:setJob')
AddEventHandler('esx:setJob', function(job)
	ESX.PlayerData.job = job

	Citizen.Wait(5000)
	TriggerServerEvent('esx_mekanikerjobb:forceBlip')
end)

RegisterNetEvent('esx_phone:loaded')
AddEventHandler('esx_phone:loaded', function(phoneNumber, contacts)
	local specialContact = {
		name       = _U('mechanic'),
		number     = 'mechanic',
		base64Icon = 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAABHNCSVQICAgIfAhkiAAAAAlwSFlzAAALEwAACxMBAJqcGAAAA4BJREFUWIXtll9oU3cUx7/nJA02aSSlFouWMnXVB0ejU3wcRteHjv1puoc9rA978cUi2IqgRYWIZkMwrahUGfgkFMEZUdg6C+u21z1o3fbgqigVi7NzUtNcmsac40Npltz7S3rvUHzxQODec87vfD+/e0/O/QFv7Q0beV3QeXqmgV74/7H7fZJvuLwv8q/Xeux1gUrNBpN/nmtavdaqDqBK8VT2RDyV2VHmF1lvLERSBtCVynzYmcp+A9WqT9kcVKX4gHUehF0CEVY+1jYTTIwvt7YSIQnCTvsSUYz6gX5uDt7MP7KOKuQAgxmqQ+neUA+I1B1AiXi5X6ZAvKrabirmVYFwAMRT2RMg7F9SyKspvk73hfrtbkMPyIhA5FVqi0iBiEZMMQdAui/8E4GPv0oAJkpc6Q3+6goAAGpWBxNQmTLFmgL3jSJNgQdGv4pMts2EKm7ICJB/aG0xNdz74VEk13UYCx1/twPR8JjDT8wttyLZtkoAxSb8ZDCz0gdfKxWkFURf2v9qTYH7SK7rQIDn0P3nA0ehixvfwZwE0X9vBE/mW8piohhl1WH18UQBhYnre8N/L8b8xQvlx4ACbB4NnzaeRYDnKm0EALCMLXy84hwuTCXL/ExoB1E7qcK/8NCLIq5HcTT0i6u8TYbXUM1cAyyveVq8Xls7XhYrvY/4n3gC8C+dsmAzL1YUiyfWxvHzsy/w/dNd+KjhW2yvv/RfXr7x9QDcmo1he2RBiCCI1Q8jVj9szPNixVfgz+UiIGyDSrcoRu2J16d3I6e1VYvNSQjXpnucAcEPUOkGYZs/l4uUhowt/3kqu1UIv9n90fAY9jT3YBlbRvFTD4fw++wHjhiTRL/bG75t0jI2ITcHb5om4Xgmhv57xpGOg3d/NIqryOR7z+r+MC6qBJB/ZB2t9Om1D5lFm843G/3E3HI7Yh1xDRAfzLQr5EClBf/HBHK462TG2J0OABXeyWDPZ8VqxmBWYscpyghwtTd4EKpDTjCZdCNmzFM9k+4LHXIFACJN94Z6FiFEpKDQw9HndWsEuhnADVMhAUaYJBp9XrcGQKJ4qFE9k+6r2+MG3k5N8VQ22TVglbX2ZwOzX2VvNKr91zmY6S7N6zqZicVT2WNLyVSehESaBhxnOALfMeYX+K/S2yv7wmMAlvwyuR7FxQUyf0fgc/jztfkJr7XeGgC8BJJgWNV8ImT+AAAAAElFTkSuQmCC'
	}

	TriggerEvent('esx_phone:addSpecialContact', specialContact.name, specialContact.number, specialContact.base64Icon)
end)

-- don't show dispatches if the player isn't in service
AddEventHandler('esx_phone:cancelMessage', function(dispatchNumber)
	if ESX.PlayerData.job and ESX.PlayerData.job.name == 'mekaniker' and ESX.PlayerData.job.name == dispatchNumber then
		-- if esx_service is enabled
		if Config.MaxInService ~= -1 and not playerInService then
			CancelEvent()
		end
	end
end)

AddEventHandler('esx_mekanikerjobb:hasEnteredMarker', function(station, part, partNum)
	if part == 'Cloakroom' then
		CurrentAction     = 'menu_cloakroom'
		CurrentActionMsg  = _U('open_cloackroom')
		CurrentActionData = {}
	elseif part == 'Armory' then
		CurrentAction     = 'menu_armory'
		CurrentActionMsg  = _U('open_armory')
		CurrentActionData = {station = station}
	elseif part == 'Vehicles' then
		CurrentAction     = 'menu_vehicle_spawner'
		CurrentActionMsg  = _U('garage_prompt')
		CurrentActionData = {station = station, part = part, partNum = partNum}
	elseif part == 'Helicopters' then
		CurrentAction     = 'Helicopters'
		CurrentActionMsg  = _U('helicopter_prompt')
		CurrentActionData = {station = station, part = part, partNum = partNum}
	elseif part == 'BossActions' then
		CurrentAction     = 'menu_boss_actions'
		CurrentActionMsg  = _U('open_bossmenu')
		CurrentActionData = {}
	end
end)

AddEventHandler('esx_mekanikerjobb:hasExitedMarker', function(station, part, partNum)
	if not isInShopMenu then
		ESX.UI.Menu.CloseAll()
	end

	CurrentAction = nil
end)

AddEventHandler('esx_mekanikerjobb:hasEnteredEntityZone', function(entity)
	local playerPed = PlayerPedId()

	if ESX.ESX.PlayerData.job and ESX.ESX.PlayerData.job.name == 'mekaniker' and IsPedOnFoot(playerPed) then
		CurrentAction     = 'remove_entity'
		CurrentActionMsg  = _U('remove_prop')
		CurrentActionData = {entity = entity}
	end

	if GetEntityModel(entity) == GetHashKey('p_ld_stinger_s') then
		local playerPed = PlayerPedId()
		local coords    = GetEntityCoords(playerPed)

		if IsPedInAnyVehicle(playerPed, false) then
			local vehicle = GetVehiclePedIsIn(playerPed)

			for i=0, 7, 1 do
				SetVehicleTyreBurst(vehicle, i, true, 1000)
			end
		end
	end
end)

AddEventHandler('esx_mekanikerjobb:hasExitedEntityZone', function(entity)
	if CurrentAction == 'remove_entity' then
		CurrentAction = nil
	end
end)

-- Create blips
Citizen.CreateThread(function()

	for k,v in pairs(Config.Stations) do
		local blip = AddBlipForCoord(v.Blip.Coords)

		SetBlipSprite (blip, v.Blip.Sprite)
		SetBlipDisplay(blip, v.Blip.Display)
		SetBlipScale  (blip, v.Blip.Scale)
		SetBlipColour (blip, v.Blip.Colour)
		SetBlipAsShortRange(blip, true)

		BeginTextCommandSetBlipName('STRING')
		AddTextComponentString(_U('mechanic'))
		EndTextCommandSetBlipName(blip)
	end

	for k,v in pairs(Config.Stations) do
		local blip = AddBlipForCoord(v.Vehicles.Blip.Coords)

		SetBlipSprite (blip, v.Vehicles.Blip.Sprite)
		SetBlipDisplay(blip, v.Vehicles.Blip.Display)
		SetBlipScale  (blip, v.Vehicles.Blip.Scale)
		SetBlipColour (blip, v.Vehicles.Blip.Colour)
		SetBlipAsShortRange(blip, true)

		BeginTextCommandSetBlipName('STRING')
		AddTextComponentString('Mekaniker Garage')
		EndTextCommandSetBlipName(blip)
	end

end)

-- Display markers
Citizen.CreateThread(function()
	while true do
		Citizen.Wait(0)

		if ESX.PlayerData.job and ESX.PlayerData.job.name == 'mekaniker' then

			local playerPed = PlayerPedId()
			local coords    = GetEntityCoords(playerPed)
			local isInMarker, hasExited, letSleep = false, false, true
			local currentStation, currentPart, currentPartNum

			for k,v in pairs(Config.Stations) do

				for i=1, #v.Cloakrooms, 1 do
					local distance = GetDistanceBetweenCoords(coords, v.Cloakrooms[i], true)

					if distance < Config.DrawDistance then
						DrawMarker(27, v.Cloakrooms[i], 0.0, 0.0, 0.0, 0, 0.0, 0.0, 1.0, 1.0, 1.0, Config.MarkerColor.r, Config.MarkerColor.g, Config.MarkerColor.b, 100, false, true, 2, false, false, true, false)
						--Marker("~w~[~g~E~w~] Omklädningsrum", 27, v.Cloakrooms[i].x, v.Cloakrooms[i].y, v.Cloakrooms[i].z - 0.95)
						letSleep = false
					end

					if distance < Config.MarkerSize.x then
						isInMarker, currentStation, currentPart, currentPartNum = true, k, 'Cloakroom', i
					end
				end

				--[[for i=1, #v.Armories, 1 do
					local distance = GetDistanceBetweenCoords(coords, v.Armories[i], true)

					if distance < Config.DrawDistance then
						DrawMarker(27, v.Armories[i], 0.0, 0.0, 0.0, 0, 0.0, 0.0, 1.0, 1.0, 1.0, Config.MarkerColor.r, Config.MarkerColor.g, Config.MarkerColor.b, 100, false, true, 2, false, false, true, false)
						--Marker("~w~[~g~E~w~] Förråd", 27, v.Armories[i].x, v.Armories[i].y, v.Armories[i].z - 0.95)
						letSleep = false
					end

					if distance < Config.MarkerSize.x then
						isInMarker, currentStation, currentPart, currentPartNum = true, k, 'Armory', i
					end
				end]]

				for i=1, #v.Vehicles, 1 do
					local distance = GetDistanceBetweenCoords(coords, v.Vehicles[i].Spawner, true)

					if distance < Config.DrawDistance then
						DrawMarker(36, v.Vehicles[i].Spawner, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, Config.MarkerColor.r, Config.MarkerColor.g, Config.MarkerColor.b, 100, false, true, 2, false, false, true, false)
						--Marker("~w~[~g~E~w~] Garage", 27, v.Vehicles[i].Spawner.x, v.Vehicles[i].Spawner.y, v.Vehicles[i].Spawner.z - 0.95)
						letSleep = false
					end

					if distance < Config.MarkerSize.x then
						isInMarker, currentStation, currentPart, currentPartNum = true, k, 'Vehicles', i
					end
				end

				for i=1, #v.Helicopters, 1 do
					local distance =  GetDistanceBetweenCoords(coords, v.Helicopters[i].Spawner, true)

					if distance < Config.DrawDistance then
						DrawMarker(34, v.Helicopters[i].Spawner, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, Config.MarkerColor.r, Config.MarkerColor.g, Config.MarkerColor.b, 100, false, true, 2, false, false, true, false)
						--Marker("~w~[~g~E~w~] Helikopter", 27, v.Helicopters[i].Spawner.x, v.Helicopters[i].Spawner.y, v.Helicopters[i].Spawner.z - 0.95)
						letSleep = false
					end

					if distance < Config.MarkerSize.x then
						isInMarker, currentStation, currentPart, currentPartNum = true, k, 'Helicopters', i
					end
				end

				if Config.EnablePlayerManagement and ESX.PlayerData.job.grade_name == 'boss' then
					for i=1, #v.BossActions, 1 do
						local distance = GetDistanceBetweenCoords(coords, v.BossActions[i], true)

						if distance < Config.DrawDistance then
							DrawMarker(27, v.BossActions[i], 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, Config.MarkerColor.r, Config.MarkerColor.g, Config.MarkerColor.b, 100, false, true, 2, false, false, true, false)
							--Marker("~w~[~g~E~w~] Chefsmeny", 27, v.BossActions[i].x, v.BossActions[i].y, v.BossActions[i].z - 0.95)
							letSleep = false
						end

						if distance < Config.MarkerSize.x then
							isInMarker, currentStation, currentPart, currentPartNum = true, k, 'BossActions', i
						end
					end
				end
			end

			if isInMarker and not HasAlreadyEnteredMarker or (isInMarker and (LastStation ~= currentStation or LastPart ~= currentPart or LastPartNum ~= currentPartNum)) then
				if
					(LastStation and LastPart and LastPartNum) and
					(LastStation ~= currentStation or LastPart ~= currentPart or LastPartNum ~= currentPartNum)
				then
					TriggerEvent('esx_mekanikerjobb:hasExitedMarker', LastStation, LastPart, LastPartNum)
					hasExited = true
				end

				HasAlreadyEnteredMarker = true
				LastStation             = currentStation
				LastPart                = currentPart
				LastPartNum             = currentPartNum

				TriggerEvent('esx_mekanikerjobb:hasEnteredMarker', currentStation, currentPart, currentPartNum)
			end

			if not hasExited and not isInMarker and HasAlreadyEnteredMarker then
				HasAlreadyEnteredMarker = false
				TriggerEvent('esx_mekanikerjobb:hasExitedMarker', LastStation, LastPart, LastPartNum)
			end

			if letSleep then
				Citizen.Wait(500)
			end

		else
			Citizen.Wait(500)
		end
	end
end)

Citizen.CreateThread(function()
	local trackedEntities = {
		'prop_roadcone02a',
		'prop_toolchest_01'
	}

	while true do
		Citizen.Wait(500)

		local playerPed = PlayerPedId()
		local coords    = GetEntityCoords(playerPed)

		local closestDistance = -1
		local closestEntity   = nil

		for i=1, #trackedEntities, 1 do
			local object = GetClosestObjectOfType(coords, 3.0, GetHashKey(trackedEntities[i]), false, false, false)

			if DoesEntityExist(object) then
				local objCoords = GetEntityCoords(object)
				local distance  = GetDistanceBetweenCoords(coords, objCoords, true)

				if closestDistance == -1 or closestDistance > distance then
					closestDistance = distance
					closestEntity   = object
				end
			end
		end

		if closestDistance ~= -1 and closestDistance <= 3.0 then
			if LastEntity ~= closestEntity then
				TriggerEvent('esx_mechanicjob:hasEnteredEntityZone', closestEntity)
				LastEntity = closestEntity
			end
		else
			if LastEntity then
				TriggerEvent('esx_mechanicjob:hasExitedEntityZone', LastEntity)
				LastEntity = nil
			end
		end
	end
end)

-- Key Controls
Citizen.CreateThread(function()
	while true do
		Citizen.Wait(0)

		if CurrentAction then
			ESX.ShowHelpNotification(CurrentActionMsg)

			if IsControlJustReleased(0, 38) and ESX.PlayerData.job and ESX.PlayerData.job.name == 'mekaniker' then

				if CurrentAction == 'menu_cloakroom' then
					OpenCloakroomMenu()
				elseif CurrentAction == 'menu_armory' then
					if Config.MaxInService == -1 then
						OpenArmoryMenu(CurrentActionData.station)
					elseif playerInService then
						OpenArmoryMenu(CurrentActionData.station)
					else
						--ESX.ShowNotification(_U('service_not'))
						exports['mythic_notify']:SendAlert('inform', _U('service_not'))
					end
				elseif CurrentAction == 'menu_vehicle_spawner' then
					if Config.MaxInService == -1 then
						OpenVehicleSpawnerMenu('car', CurrentActionData.station, CurrentActionData.part, CurrentActionData.partNum)
					elseif playerInService then
						OpenVehicleSpawnerMenu('car', CurrentActionData.station, CurrentActionData.part, CurrentActionData.partNum)
					else
						--ESX.ShowNotification(_U('service_not'))
						exports['mythic_notify']:SendAlert('inform', _U('service_not'))
					end
				elseif CurrentAction == 'Helicopters' then
					if Config.MaxInService == -1 then
						OpenVehicleSpawnerMenu('helicopter', CurrentActionData.station, CurrentActionData.part, CurrentActionData.partNum)
					elseif playerInService then
						OpenVehicleSpawnerMenu('helicopter', CurrentActionData.station, CurrentActionData.part, CurrentActionData.partNum)
					else
						--ESX.ShowNotification(_U('service_not'))
						exports['mythic_notify']:SendAlert('inform', _U('service_not'))
					end
				elseif CurrentAction == 'delete_vehicle' then
					ESX.Game.DeleteVehicle(CurrentActionData.vehicle)
				elseif CurrentAction == 'menu_boss_actions' then
					ESX.UI.Menu.CloseAll()
					TriggerEvent('esx_society:openBossMenu', 'mekaniker', function(data, menu)
						menu.close()

						CurrentAction     = 'menu_boss_actions'
						CurrentActionMsg  = _U('open_bossmenu')
						CurrentActionData = {}
					end, { wash = false }) -- disable washing money
				elseif CurrentAction == 'remove_entity' then
					DeleteEntity(CurrentActionData.entity)
				end

				CurrentAction = nil
			end
		end -- CurrentAction end

		if IsControlJustReleased(0, 167) and not isDead and ESX.PlayerData.job and ESX.PlayerData.job.name == 'mekaniker' and not ESX.UI.Menu.IsOpen('default', GetCurrentResourceName(), 'mekaniker_actions') then
			if Config.MaxInService == -1 then
				OpenMechanicActionsMenu()
			elseif playerInService then
				OpenMechanicActionsMenu()
			else
				--ESX.ShowNotification(_U('service_not'))
				exports['mythic_notify']:SendAlert('inform', _U('service_not'))
			end
		end
		--[[
		if IsControlJustReleased(0, 178) and not isDead and ESX.PlayerData.job and ESX.PlayerData.job.name == 'mekaniker' then
			if NPCOnJob then
				if GetGameTimer() - NPCLastCancel > 5 * 60000 then
					StopNPCJob(true)
					NPCLastCancel = GetGameTimer()
				else
					ESX.ShowNotification(_U('wait_five'))
				end
			else
				local playerPed = PlayerPedId()

				if IsPedInAnyVehicle(playerPed, false) and IsVehicleModel(GetVehiclePedIsIn(playerPed, false), GetHashKey('flatbed')) then
					StartNPCJob()
				else
					ESX.ShowNotification(_U('must_in_flatbed'))
				end
			end
		end--]]
	end
end)

AddEventHandler('esx:onPlayerDeath', function(data)
	isDead = true
end)

AddEventHandler('playerSpawned', function(spawn)
	isDead = false
end)


function loadanimdict(dictname)
	if not HasAnimDictLoaded(dictname) then
		RequestAnimDict(dictname) 
		while not HasAnimDictLoaded(dictname) do 
			Citizen.Wait(1)
		end
	end
end

-- Pop NPC mission vehicle when inside area
Citizen.CreateThread(function()
	while true do
		Citizen.Wait(10)

		if NPCTargetTowableZone and not NPCHasSpawnedTowable then
			local coords = GetEntityCoords(PlayerPedId())
			local zone   = Config.Stations[NPCTargetTowableZone]

			if GetDistanceBetweenCoords(coords, zone.Pos.x, zone.Pos.y, zone.Pos.z, true) < Config.NPCSpawnDistance then
				local model = Config.Vehicles[GetRandomIntInRange(1,  #Config.Vehicles)]

				ESX.Game.SpawnVehicle(model, zone.Pos, 0, function(vehicle)
					NPCTargetTowable = vehicle
				end)

				NPCHasSpawnedTowable = true
			end
		end

		if NPCTargetTowableZone and NPCHasSpawnedTowable and not NPCHasBeenNextToTowable then
			local coords = GetEntityCoords(PlayerPedId())
			local zone   = Config.Stations[NPCTargetTowableZone]

			if GetDistanceBetweenCoords(coords, zone.Pos.x, zone.Pos.y, zone.Pos.z, true) < Config.NPCNextToDistance then
				exports['mythic_notify']:SendAlert('inform', (_U('please_tow')))
				NPCHasBeenNextToTowable = true
			end
		end
	end
end)
