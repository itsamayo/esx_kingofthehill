local Keys = {
    ["ESC"] = 322, ["F1"] = 288, ["F2"] = 289, ["F3"] = 170, ["F5"] = 166, ["F6"] = 167, ["F7"] = 168, ["F8"] = 169, ["F9"] = 56, ["F10"] = 57,
    ["~"] = 243, ["1"] = 157, ["2"] = 158, ["3"] = 160, ["4"] = 164, ["5"] = 165, ["6"] = 159, ["7"] = 161, ["8"] = 162, ["9"] = 163, ["-"] = 84, ["="] = 83, ["BACKSPACE"] = 177,
    ["TAB"] = 37, ["Q"] = 44, ["W"] = 32, ["E"] = 38, ["R"] = 45, ["T"] = 245, ["Y"] = 246, ["U"] = 303, ["P"] = 199, ["["] = 39, ["]"] = 40, ["ENTER"] = 18,
    ["CAPS"] = 137, ["A"] = 34, ["S"] = 8, ["D"] = 9, ["F"] = 23, ["G"] = 47, ["H"] = 74, ["K"] = 311, ["L"] = 182,
    ["LEFTSHIFT"] = 21, ["Z"] = 20, ["X"] = 73, ["C"] = 26, ["V"] = 0, ["B"] = 29, ["N"] = 249, ["M"] = 244, [","] = 82, ["."] = 81,
    ["LEFTCTRL"] = 36, ["LEFTALT"] = 19, ["SPACE"] = 22, ["RIGHTCTRL"] = 70,
    ["HOME"] = 213, ["PAGEUP"] = 10, ["PAGEDOWN"] = 11, ["DELETE"] = 178,
    ["LEFT"] = 174, ["RIGHT"] = 175, ["TOP"] = 27, ["DOWN"] = 173,
  }

ESX                           = nil  
local PlayerData              = {}  
local IsInRange               = true -- Whether or not a player is in the capture range
local blipsCapturers          = {} -- Player map markers table

Citizen.CreateThread(function()
    while ESX == nil do
      TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
      Citizen.Wait(0)
    end
    while ESX.GetPlayerData().job == nil do
      Citizen.Wait(10)
    end
    PlayerData = ESX.GetPlayerData()
end)
  
RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(xPlayer)
    PlayerData = xPlayer    
end)

-- Make sure all clients have latest current owners list
TriggerServerEvent('esx_kingofthehill:checkStatus')

RegisterNetEvent('esx_kingofthehill:setStatusOnLoad')
AddEventHandler('esx_kingofthehill:setStatusOnLoad', function(capturedBy, captured)
    Config.GroveStreet.capturedBy = capturedBy
    Config.GroveStreet.captured = captured 
end)

-- Set the cooldown afer successful capture
RegisterNetEvent('esx_kingofthehill:setCooldown')
AddEventHandler('esx_kingofthehill:setCooldown', function(time)
    Config.CoolDown = time    
    Config.GroveStreet.capturedBy = {}
    Config.GroveStreet.captureCount = #Config.GroveStreet.capturers
end)

-- Force reset payroll
RegisterNetEvent('esx_kingofthehill:resetPayroll')
AddEventHandler('esx_kingofthehill:resetPayroll', function()    
    Config.GroveStreet.capturedBy = {}    
    Config.GroveStreet.captured = false
    Config.GroveStreet.capturers = {} 
    Config.GroveStreet.captureCount = #Config.GroveStreet.capturers
    Config.GroveStreet.captureInProgress = false
    TriggerEvent('esx_kingofthehill:updateBlip', Config.GroveStreet.capturers) 
end)

-- payroll commands
RegisterCommand("payroll", function(source, args, rawCommand) 
    local isCapturing = table.contains(Config.GroveStreet.capturers, PlayerData.identifier)   
    local isCapturedBySelf = table.contains(Config.GroveStreet.capturedBy, PlayerData.identifier) 
    if args[1] == nil then
        ESX.ShowNotification('Missing command, try ~r~/payroll start')
    elseif tostring(args[1]) == 'check' then
        if isCapturing then
            ESX.ShowNotification('You are in the capturing group')
        elseif isCapturedBySelf then
            ESX.ShowNotification('You are on the payroll')
        else
            ESX.ShowNotification('You are not in a capture group, and you aren\'t on the payroll')
        end
    elseif tostring(args[1]) == 'start' then        
        if Config.BlockEmergencyServices and (ESX.GetPlayerData().job.name == 'police' or ESX.GetPlayerData().job.name == 'ambulance') then
            ESX.ShowNotification('Emergency services are not allowed to Capture') 
        elseif Config.GroveStreet.captureCount >= Config.RequiredCapturersMin and isCapturing and Config.CoolDown == 0 then 
            if Config.GroveStreet.captureInProgress then
                ESX.ShowNotification('Already being captured') 
            else
                TriggerServerEvent('esx_kingofthehill:capture')  
            end                                
        elseif Config.CoolDown > 0 then
            ESX.ShowNotification('Recently captured. You need to wait ~r~' .. Config.CoolDown / 1000 .. ' ~w~seconds')
        else
            ESX.ShowNotification('~r~You need at least ' .. Config.RequiredCapturersMin .. ' in your group')
        end
    elseif tostring(args[1]) == 'join' then
        if Config.GroveStreet.captureCount >= Config.RequiredCapturersMax then
            ESX.ShowNotification( '~r~There are already ' .. Config.RequiredCapturersMax .. ' people in the group')
        else
            if isCapturing then
                ESX.ShowNotification('You are already in the group') 
            elseif isCapturedBySelf then
                ESX.ShowNotification('You are already on payroll') 
            else
                if Config.BlockEmergencyServices and (ESX.GetPlayerData().job.name == 'police' or ESX.GetPlayerData().job.name == 'ambulance') then
                    ESX.ShowNotification('Emergency services are not allowed to Capture') 
                else
                    TriggerServerEvent('esx_kingofthehill:addCapturer', PlayerData.identifier)
                    ESX.ShowNotification('~g~Joined the Capture group')
                end
            end                        
        end 
    elseif tostring(args[1]) == 'leave' then
        if isCapturing then
            TriggerServerEvent('esx_kingofthehill:removeCapturer', PlayerData.identifier)
            ESX.ShowNotification('~r~Left the Capture group')
        else
            ESX.ShowNotification('You\'re not in the Capture group')
        end
    elseif tostring(args[1]) == 'clear' then
        if ESX.GetPlayerData().job.name == 'mafia' then
            TriggerServerEvent('esx_kingofthehill:resetPayroll')
        else           
            ESX.ShowNotification('~r~Unauthorized')
        end
    elseif tostring(args[1]) == 'owners' then
        TriggerServerEvent('esx_kingofthehill:checkOwners')
    else        
        if not isCapturedBySelf then
            ESX.TriggerServerCallback('esx_kingofthehill:checkCode', function(valid)
                if valid then
                    TriggerServerEvent('esx_kingofthehill:addToPayroll', PlayerData.identifier)
                else
                    ESX.ShowNotification('~r~Invalid Code')
                end
            end, tostring(args[1]))            
        else
            ESX.ShowNotification('You are already on the Payroll')
        end   
    end    
end)

-- Join capture group
RegisterNetEvent('esx_kingofthehill:addCapturer')
AddEventHandler('esx_kingofthehill:addCapturer', function(player)    
    table.insert(Config.GroveStreet.capturers, player)
    Config.GroveStreet.captureCount = #Config.GroveStreet.capturers
end)

-- Leave capture group
RegisterNetEvent('esx_kingofthehill:removeCapturer')
AddEventHandler('esx_kingofthehill:removeCapturer', function(player)    
    local index = table.getindex(Config.GroveStreet.capturers, player)
    Config.GroveStreet.capturers[index] = nil
    Config.GroveStreet.captureCount = #Config.GroveStreet.capturers
end)

-- Start capturing
RegisterNetEvent('esx_kingofthehill:capture')
AddEventHandler('esx_kingofthehill:capture', function(code)    
    ESX.TriggerServerCallback('esx_kingofthehill:checkCurrentOwners', function(count)
        local timer = count
        if timer ~= nil then
            Config.GroveStreet.captureInProgress = true
            TriggerEvent('esx_kingofthehill:updateBlip', Config.GroveStreet.capturers) 
            -- Send a message to Police at start of capture
            TriggerServerEvent('esx_phone:send', 'police', 'There seems to be a turf war breaking out in Grove Street. It\'s not safe to enter the area', false, {
                x = Config.GroveStreet.pos.x,
                y = Config.GroveStreet.pos.y,
                z = Config.GroveStreet.pos.z
            })
            GetPercentage(timer)                         
            local playerPed = GetPlayerPed(-1)
            for k,v in pairs(Config.GroveStreet.capturers) do  
                if PlayerData.identifier == v and not IsEntityDead(playerPed)then
                    TriggerServerEvent('esx_kingofthehill:confirmCapture', code)                
                end
            end               
            Config.GroveStreet.captureInProgress = false
            Config.GroveStreet.capturers = {}
            Config.GroveStreet.captureCount = #Config.GroveStreet.capturers
            TriggerEvent('esx_kingofthehill:updateBlip', Config.GroveStreet.capturers)
            -- Send a message to Police at end of capture
            TriggerServerEvent('esx_phone:send', 'police', 'It looks like things have calmed down in Grove Street. The area should be safe to enter.', false, {
                x = Config.GroveStreet.pos.x,
                y = Config.GroveStreet.pos.y,
                z = Config.GroveStreet.pos.z
            })
        else
            for k,v in pairs(Config.GroveStreet.capturers) do  
                if PlayerData.identifier == v then
                    ESX.ShowNotification('~r~None of the owners are around to defend')              
                end
            end             
        end    
    end)    
    ESX.TriggerServerCallback('esx_kingofthehill:checkActiveCapturedBy', function(capturedBy)
        Config.GroveStreet.capturedBy = capturedBy	
	end)
    Cancelled = false   
end)

-- Successfully capture
RegisterNetEvent('esx_kingofthehill:confirmCapture')
AddEventHandler('esx_kingofthehill:confirmCapture', function(player)
    Config.GroveStreet.captured = true
    table.insert(Config.GroveStreet.capturedBy, player)
end)

-- Triggers for joining, leaving, starting a capture
Citizen.CreateThread(function()  
    while true do
        Citizen.Wait(5)
        local playerPed = PlayerPedId()               
        local isCapturedBySelf = table.contains(Config.GroveStreet.capturedBy, PlayerData.identifier)      
        local isCapturing = table.contains(Config.GroveStreet.capturers, PlayerData.identifier)   
        local coords = GetEntityCoords(playerPed)
        local dist = GetDistanceBetweenCoords(Config.GroveStreet.pos.x, Config.GroveStreet.pos.y, Config.GroveStreet.pos.z, coords.x, coords.y, coords.z, true)  
        if dist <= Config.CaptureBreakingDistance and dist ~= 0.0 then
            if dist <= Config.CaptureBreakingDistance then
                IsInRange = true                    
                if not isCapturedBySelf then    
                    if Config.GroveStreet.showPercentage and Config.GroveStreet.captureInProgress then
                        DrawText3D(Config.GroveStreet.pos.x, Config.GroveStreet.pos.y, Config.GroveStreet.pos.z, 'Capture in progress ~g~' .. perc .. '%', 0.4)                                                                                                                                                           
                    else
                        DrawText3D(Config.GroveStreet.pos.x, Config.GroveStreet.pos.y, Config.GroveStreet.pos.z, "~g~/payroll join~w~ to join. ~g~/payroll leave ~w~to leave. ~g~/payroll start ~w~to start - [" .. Config.GroveStreet.captureCount .. "/".. Config.RequiredCapturersMax .. "]", 0.4)                  
                    end    
                    if Config.GroveStreet.showPercentage and Config.GroveStreet.captureInProgress and isCapturing then
                        DrawMarker(1, Config.GroveStreet.pos.x, Config.GroveStreet.pos.y, Config.GroveStreet.pos.z - 8, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, Config.CaptureBreakingDistance*2, Config.CaptureBreakingDistance*2, 30.0, 52, 207, 250, 155, false, false, 2, false)                                                                     
                    end                                              
                else      
                    DrawText3D(Config.GroveStreet.pos.x, Config.GroveStreet.pos.y, Config.GroveStreet.pos.z, "~g~You are on the payroll", 0.4)                                                  
                end  
            end      
        end
    end
end)

-- If a capturer leaves the area, remove them from the capturing
-- And update cooldown time for everyone
Citizen.CreateThread(function()      
    while true do
        Citizen.Wait(5)
        for a, b in pairs(Config.GroveStreet.capturers) do
            if b == PlayerData.identifier then
                local index = table.getindex(Config.GroveStreet.capturers, b)
                local playerPed = GetPlayerPed(-1)
                local coords = GetEntityCoords(playerPed)
                local dist = GetDistanceBetweenCoords(Config.GroveStreet.pos.x, Config.GroveStreet.pos.y, Config.GroveStreet.pos.z, coords.x, coords.y, coords.z, true) 
                if dist > Config.CaptureBreakingDistance then
                    IsInRange = false                    
                    Config.GroveStreet.capturers[index] = nil
                    Config.GroveStreet.captureCount = #Config.GroveStreet.capturers
                    Cancelled = true                    
                    ESX.ShowNotification('~r~You are no longer Capturing because you left the area')
                    TriggerServerEvent('esx_kingofthehill:updateBlip', Config.GroveStreet.capturers)
                end
                if IsEntityDead(playerPed) then  
                    Config.GroveStreet.capturers[index] = nil   
                    Config.GroveStreet.captureCount = #Config.GroveStreet.capturers                                                      
                    TriggerServerEvent('esx_kingofthehill:updateBlip', Config.GroveStreet.capturers)
                    ESX.ShowNotification('~r~You are no longer Capturing')
                end
            end                
        end                          
        if Config.CoolDown > 0 then
            Config.CoolDown = Config.CoolDown - 10
        end
    end
end)

-- Capturer blips that are shown to existing owners only during a capture
RegisterNetEvent('esx_kingofthehill:updateBlip')
AddEventHandler('esx_kingofthehill:updateBlip', function(capturers)
    Config.GroveStreet.capturers = capturers
    Config.GroveStreet.captureCount = #capturers
	-- Refresh all blips
	for k, existingBlip in pairs(blipsCapturers) do
		RemoveBlip(existingBlip)
	end
	-- Clean the blip table
	blipsCapturers = {}
	-- Make sure the capturer is online
    ESX.TriggerServerCallback('esx_society:getOnlinePlayers', function(players)        
        for i=1, #players, 1 do
            local isCapturedBySelf = table.contains(Config.GroveStreet.capturedBy, PlayerData.identifier)
            if isCapturedBySelf then
                for c,d in pairs(Config.GroveStreet.capturers) do                    
                    local id = GetPlayerFromServerId(players[i].source)                    
                    if NetworkIsPlayerActive(id) and players[i].identifier == d and GetPlayerPed(id) ~= PlayerPedId() then
                        createBlip(id, 1)
                    end
                end
            end  
        end        
    end)    
end)

-- Create blip for capturers
function createBlip(id, colour)
	local ped = GetPlayerPed(id)
	local blip = GetBlipFromEntity(ped)
	if not DoesBlipExist(blip) then
		blip = AddBlipForEntity(ped)
		SetBlipSprite(blip, 84)
		SetBlipColour(blip, colour)
		ShowHeadingIndicatorOnBlip(blip, true)
		SetBlipRotation(blip, math.ceil(GetEntityHeading(ped)))
		SetBlipNameToPlayerName(blip, id)
		SetBlipScale(blip, 0.85)
        SetBlipAsShortRange(blip, true)
        -- add blip to array so we can remove it later
		table.insert(blipsCapturers, blip)
	end
end

-- locally native table lookup
function table.contains(table, element)
    for _, value in pairs(table) do
      if value == element then  
        return true        
      end
    end    
    return false
end

-- locally native index getter
function table.getindex(table, element)
    local index = {}
    for k,v in pairs(table) do
        index[v] = k
    end
    return index[element]
end

-- Draws all 3D text
function DrawText3D(x, y, z, text, scale)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    local pX, pY, pZ = table.unpack(GetGameplayCamCoords())  
    SetTextScale(scale, scale)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextEntry("STRING")
    SetTextCentre(1)
    SetTextColour(255, 255, 255, 255)
    SetTextOutline()  
    AddTextComponentString(text)
    DrawText(_x, _y)  
    local factor = (string.len(text)) / 270
    DrawRect(_x, _y + 0.015, 0.005 + factor, 0.03, 31, 31, 31, 155)
end

-- Set and unset visibility for progress
function GetPercentage(time)
    Config.GroveStreet.showPercentage = true
    perc = 0
    repeat
    perc = perc + 1
    Citizen.Wait(time)
    until(perc == 100 or #Config.GroveStreet.capturers == 0)
    Config.GroveStreet.showPercentage = false
end