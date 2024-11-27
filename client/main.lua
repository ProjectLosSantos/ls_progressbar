local playerState = LocalPlayer.state
local progressData
local currentProps = {}

local function interrupt(data)
    if not data.useWhileDead and IsEntityDead(PlayerPedId()) or playerState.isDead then return true end
    if not data.allowRagdoll and IsPedRagdoll(PlayerPedId()) then return true end
    if not data.allowCuffed and IsPedCuffed(PlayerPedId()) then return true end
    if not data.allowFalling and IsPedFalling(PlayerPedId()) then return true end
    if not data.allowSwimming and IsPedSwimming(PlayerPedId()) then return true end
end

local function handleprogress(data)
    progressData = data
    if data.anim then
        if data.anim.dict then
            lib.requestAnimDict(data.anim.dict)
            TaskPlayAnim(PlayerPedId(), data.anim.dict, data.anim.clip, data.anim.blendIn or 3.0,
                data.anim.blendOut or 1.0,
                data.anim.duration or -1,
                data.anim.flag or 49, data.anim.playbackRate or 0, data.anim.lockX, data.anim.lockY, data.anim.lockZ)
            RemoveAnimDict(data.anim.dict)
        elseif data.anim.scenario then
            TaskStartScenarioInPlace(PlayerPedId(), data.anim.scenario, 0,
                data.anim.playEnter ~= nil and data.anim.playEnter or true)
        end
    end
    if data.prop then
        playerState:set('progressProp', data.prop, true)
    end
    local disable = data.disable
    while progressData do
        if disable then
            if disable.mouse then
                DisableControlAction(0, 1, true)
                DisableControlAction(0, 2, true)
                DisableControlAction(0, 106, true)
            end
            if disable.move then
                DisableControlAction(0, 21, true)
                DisableControlAction(0, 30, true)
                DisableControlAction(0, 31, true)
                DisableControlAction(0, 36, true)
            end
            if disable.sprint and not disable.move then
                DisableControlAction(0, 21, true)
            end
            if disable.car then
                DisableControlAction(0, 63, true)
                DisableControlAction(0, 64, true)
                DisableControlAction(0, 71, true)
                DisableControlAction(0, 72, true)
                DisableControlAction(0, 75, true)
            end
            if disable.combat then
                DisableControlAction(0, 25, true)
                DisablePlayerFiring(PlayerId(), true)
            end
        end
        if interrupt(data) then
            progressData = false
        end
        Wait(0)
    end
    if data.prop then
        playerState:set('progressProp', nil, true)
    end
    if data.anim then
        if data.anim.dict then
            StopAnimTask(PlayerPedId(), data.anim.dict, data.anim.clip, 1.0)
            Wait(0)
        else
            ClearPedTasks(PlayerPedId())
        end
    end
    if progressData == false then
        SendNUIMessage({ type = 'cancelProgress' })
        return false
    end
    return true
end

local function startProgress(data)
    playerState:set('invBusy', true, true)
    while progressData ~= nil do
        Wait(0)
    end
    if not interrupt(data) then
        SendNUIMessage({
            type = "startProgress",
            table = {
                label = data.label,
                icon = data.icon,
                duration = data.duration,
            }
        })
        return handleprogress(data)
    end
end
exports('progressBar', startProgress)

local function cancelProgress()
    if not progressData then
        return
    end
    progressData = false
    playerState:set('invBusy', false, true)
end
exports('cancel', cancelProgress)

local function isProgressActive()
    return progressData and true
end
exports('isProgressActive', isProgressActive)

RegisterNUICallback('progressEnded', function(_, cb)
    cb('ok')
    progressData = nil
    playerState:set('invBusy', false, true)
end)

local function createProp(ped, prop)
    lib.requestModel(prop.model)
    local coords = GetEntityCoords(ped)
    local object = CreateObject(prop.model, coords.x, coords.y, coords.z, false, false, false)

    AttachEntityToEntity(object, ped, GetPedBoneIndex(ped, prop.bone or 60309), prop.pos.x, prop.pos.y, prop.pos.z,
        prop.rot.x, prop.rot.y, prop.rot.z, true, true, false, true, prop.rotOrder or 0, true)
    SetModelAsNoLongerNeeded(prop.model)

    return object
end

local function deleteProgressProps(serverId)
    local playerProps = currentProps[serverId]
    if not playerProps then return end
    for i = 1, #playerProps do
        local prop = playerProps[i]
        if DoesEntityExist(prop) then
            DeleteEntity(prop)
        end
    end
    currentProps[serverId] = nil
end

AddStateBagChangeHandler('progressProp', nil, function(bagName, _, value, _, replicated)
    if replicated then return end

    local player = GetPlayerFromStateBagName(bagName)
    if player == 0 then return end

    local ped = GetPlayerPed(player)
    local serverId = GetPlayerServerId(player)

    if not value then
        return deleteProgressProps(serverId)
    end

    currentProps[serverId] = {}
    local playerProps = currentProps[serverId]

    if value.model then
        playerProps[#playerProps + 1] = createProp(ped, value)
    else
        for i = 1, #value do
            local prop = value[i]

            if prop then
                playerProps[#playerProps + 1] = createProp(ped, prop)
            end
        end
    end
end)

RegisterNetEvent('onPlayerDropped', function(serverId)
    deleteProgressProps(serverId)
end)

RegisterCommand('cancelprogressbar', function()
    if progressData?.canCancel then progressData = false end
end)

RegisterKeyMapping('cancelprogressbar', 'Cancel current progress bar', 'keyboard', 'x')
