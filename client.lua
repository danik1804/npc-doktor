ESX = exports["es_extended"]:getSharedObject()

local beds = {
    { position = vector3(-800.0, -1234.7, 8.2), occupied = false },
    { position = vector3(-804.1, -1231.3, 8.2), occupied = false },
    { position = vector3(-806.7, -1229.2, 8.2), occupied = false },
    { position = vector3(-809.5, -1226.8, 8.2), occupied = false },
    { position = vector3(-812.2, -1224.5, 8.2), occupied = false },
}

local hospitalDoctors = {
    {
        id = "firstDoctor",
        model = "s_m_m_doctor_01",
        position = vector3(-812.4, -1237.6, 6.3),
        heading = 330.3,
        doctorEntity = nil 
    },
    {
        id = "secondDoctor", 
        model = "s_m_m_doctor_01",
        position = vector3(-799.4, -1221.5, 6.3),
        heading = 144.6,
        doctorEntity = nil,
        intermediatePosition = vector3(-804.5, -1227.5, 6.3)
    }
}

function spawnDoctor(doctorInfo, freeze)
    RequestModel(doctorInfo.model)
    while not HasModelLoaded(doctorInfo.model) do
        Wait(500)
    end

    local doctor = CreatePed(4, doctorInfo.model, doctorInfo.position.x, doctorInfo.position.y, doctorInfo.position.z, doctorInfo.heading, false, true)
    SetEntityAsMissionEntity(doctor, true, true)
    TaskSetBlockingOfNonTemporaryEvents(doctor, true)
    SetPedCanPlayAmbientAnims(doctor, true)
    SetPedCanRagdollFromPlayerImpact(doctor, false)
    SetEntityInvincible(doctor, true)

    if freeze then
        FreezeEntityPosition(doctor, true)
    else
        SetEntityVisible(doctor, false)
    end

    doctorInfo.doctorEntity = doctor

    exports.qtarget:AddTargetEntity(doctor, {
        options = {
            {
                event = "db_hospital:interactWithDoctor",
                icon = "fas fa-user-md",
                label = "Zapsat se na ošetření",
            },
        },
        distance = 2.0
    })
end

function selectRandomBed()
    local availableBeds = {}

    for index, bed in ipairs(beds) do
        if not bed.occupied then
            table.insert(availableBeds, { index = index, position = bed.position }) 
        end
    end

    if #availableBeds > 0 then
        local randomIndex = math.random(1, #availableBeds)
        local selectedBed = availableBeds[randomIndex]
        beds[selectedBed.index].occupied = true 
        return selectedBed.position
    else
        return nil
    end
end

function startTreatment(bedPosition)
    local playerPed = PlayerPedId()
    local treatmentCost = 1000

    for _, bed in ipairs(beds) do
        if bed.position == bedPosition then
            bed.occupied = true
            break
        end
    end    

    ESX.TriggerServerCallback('db_hospital:getPlayerMoney', function(hasMoney)
        if hasMoney and hasMoney >= treatmentCost then
            TriggerServerEvent('db_hospital:pay', treatmentCost) 

            while #(GetEntityCoords(playerPed) - bedPosition) > 1.5 do
                Wait(100)
            end

            RequestAnimDict('anim@gangops@morgue@table@')
            while not HasAnimDictLoaded('anim@gangops@morgue@table@') do
                Wait(10)
            end

            SetEntityCoords(playerPed, bedPosition.x, bedPosition.y, bedPosition.z)
            TaskPlayAnim(playerPed, 'anim@gangops@morgue@table@', 'ko_front', 8.0, -8.0, -1, 1, 0, false, false, false)

            SetEntityHeading(playerPed, 320.0) -- heading

            spawnDoctor(hospitalDoctors[2])

            selectedBedPosition = nil

            local secondDoctor = hospitalDoctors[2].doctorEntity
            if secondDoctor and not IsEntityVisible(secondDoctor) then
                SetEntityVisible(secondDoctor, true)

                TaskGoStraightToCoord(secondDoctor, hospitalDoctors[2].intermediatePosition.x, hospitalDoctors[2].intermediatePosition.y, hospitalDoctors[2].intermediatePosition.z, 1.0, -1, hospitalDoctors[2].heading, 0.0)

                while true do
                    local doctorCoords = GetEntityCoords(secondDoctor)
                    local distance = #(doctorCoords - hospitalDoctors[2].intermediatePosition)

                    if distance <= 2.0 then
                        ClearPedTasks(secondDoctor)
                        Wait(1000)
                        ClearPedTasks(doctorPed)
                        Wait(100)

                        TaskGoStraightToCoord(secondDoctor, bedPosition.x, bedPosition.y, bedPosition.z + 1.0, 1.0, -1, hospitalDoctors[2].heading, 0.0)

                        while true do
                            local doctorCoords = GetEntityCoords(secondDoctor)
                            local distance = #(doctorCoords - bedPosition)

                            if distance <= 2.0 then
                                ClearPedTasks(secondDoctor)
                                TaskStartScenarioInPlace(secondDoctor, "WORLD_HUMAN_CLIPBOARD", 0, true) 
                                break
                            end

                            Wait(100) 
                        end
                        break
                    end
                    Wait(100) 
                end
            end

            lib.progressBar({
                duration = 120000, -- (120000 = 2 minuty)
                label = "Doktor tě ošetřuje...",
                useWhileDead = false,
                canCancel = false,
                disable = {car = true, move = true, fight = true}
            })

            SetEntityHealth(playerPed, GetEntityMaxHealth(playerPed))

            SetEntityHeading(playerPed, GetEntityHeading(playerPed) + 90.0)
            RequestAnimDict('switch@franklin@bed')
            while not HasAnimDictLoaded('switch@franklin@bed') do
                Wait(10)
            end
        
            TaskPlayAnim(playerPed, 'switch@franklin@bed', 'sleep_getup_rubeyes', 8.0, -8.0, 5000, 0, 0, 0, 0)
            Wait(5000)
        
            Wait(1000) 

            for _, bed in ipairs(beds) do
                if bed.position == bedPosition then
                    bed.occupied = false
                    break
                end
            end
            
            if secondDoctor then
                TaskGoStraightToCoord(secondDoctor, hospitalDoctors[2].intermediatePosition.x, hospitalDoctors[2].intermediatePosition.y, hospitalDoctors[2].intermediatePosition.z, 1.0, -1, hospitalDoctors[2].heading, 0.0)
            
                while true do
                    local doctorCoords = GetEntityCoords(secondDoctor)
                    local distance = #(doctorCoords - hospitalDoctors[2].intermediatePosition)
            
                    if distance <= 2.0 then
                        ClearPedTasks(secondDoctor)
                        Wait(1000)
                        ClearPedTasks(doctorPed)
                        Wait(100)
            
                        TaskGoStraightToCoord(secondDoctor, hospitalDoctors[2].position.x, hospitalDoctors[2].position.y, hospitalDoctors[2].position.z, 1.0, -1, hospitalDoctors[2].heading, 0.0)
            
                        while true do
                            local doctorCoords = GetEntityCoords(secondDoctor)
                            local distance = #(doctorCoords - hospitalDoctors[2].position)
            
                            if distance <= 2.0 then
                                ClearPedTasks(secondDoctor)
            
                                DeleteEntity(secondDoctor)
                                hospitalDoctors[2].doctorEntity = nil
                                break
                            end
            
                            Wait(100) 
                        end
            
                        break
                    end
            
                    Wait(100) 
                end
            end            
        end
    end)
end

RegisterNetEvent("db_hospital:interactWithDoctor")
AddEventHandler("db_hospital:interactWithDoctor", function()
    selectedBedPosition = selectRandomBed()
    if selectedBedPosition then
        startTreatment(selectedBedPosition)
    end
end)

Citizen.CreateThread(function()
    while true do
        Wait(0)
        if selectedBedPosition then
            DrawMarker(20, selectedBedPosition.x, selectedBedPosition.y, selectedBedPosition.z - 0.35, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 255, 0, 0, 200, true, true, 2, false, nil, nil, false)
        else
            Wait(1000)
        end
    end
end)

Citizen.CreateThread(function()
    spawnDoctor(hospitalDoctors[1], true)
end)
