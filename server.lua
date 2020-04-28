ESX = nil

TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

-- Get users for payout
function GetUsersForPayout()        
    MySQL.ready(function()        
        MySQL.Async.fetchAll('SELECT * FROM payroll',{}, function(result)
            Payout(result)                  
        end)
    end)  
end

-- Check owners (used by /payroll owners)
RegisterServerEvent('esx_kingofthehill:checkOwners')
AddEventHandler('esx_kingofthehill:checkOwners', function() 
    local _source = source
    local text = 'Current owners: ^2'
    MySQL.Async.fetchAll('SELECT * FROM payroll',{}, function(result)
        if #result > 0 then
            text = text .. tostring(#result)
        else
            text = text .. 'None'
        end 
        TriggerClientEvent("chatMessage", _source, "^5 Payroll: ^4", {0,0,0}, string.format(text))  
    end)
end)

-- Clear the payroll (currently anyone can do it, should only be for Mafia job and admins)
RegisterServerEvent('esx_kingofthehill:resetPayroll')
AddEventHandler('esx_kingofthehill:resetPayroll', function() 
    local _source = source
    MySQL.Async.execute('DELETE FROM payroll', {})
    TriggerClientEvent('esx:showNotification', source, '~g~Payroll has been cleared')
    TriggerClientEvent('esx_kingofthehill:resetPayroll', -1)
end)

-- Add capturer to table for all users
RegisterServerEvent('esx_kingofthehill:addCapturer')
AddEventHandler('esx_kingofthehill:addCapturer', function(player)    
    TriggerClientEvent('esx_kingofthehill:addCapturer', -1, player)  
end)

-- Remove capturer to table for all users
RegisterServerEvent('esx_kingofthehill:removeCapturer')
AddEventHandler('esx_kingofthehill:removeCapturer', function(player)    
    TriggerClientEvent('esx_kingofthehill:removeCapturer', -1, player) 
end)

-- Update blips for users
RegisterServerEvent('esx_kingofthehill:updateBlip')
AddEventHandler('esx_kingofthehill:updateBlip', function(capturers)   
    TriggerClientEvent('esx_kingofthehill:updateBlip', -1, capturers) 
end)

-- Start Capture, create new code and update for all users
RegisterServerEvent('esx_kingofthehill:capture')
AddEventHandler('esx_kingofthehill:capture', function()    
    local code = math.random(10000, 99999)
    MySQL.Async.execute('DELETE FROM payroll_code', {}, function()
        MySQL.Async.execute('INSERT INTO payroll_code (code) VALUES (@code)', {        
            ['@code'] = code
        }, function()
            MySQL.Async.fetchAll('SELECT * FROM payroll',{}, function(result)
                if #result > 0 then
                    for k,v in pairs(result) do 
                        local xPlayer = ESX.GetPlayerFromIdentifier(v.identifier)
                        if xPlayer ~= nil then
                            TriggerClientEvent("chatMessage", xPlayer.source, "^5 Payroll: ^4", {0,0,0}, string.format('Another group is taking control of Payroll'))
                        end                
                    end
                end   
            end)
            TriggerClientEvent('esx_kingofthehill:capture', -1, code)
        end)
    end)    
end)

-- On capture success send code to all capturers and delete all old owners from DB
RegisterServerEvent('esx_kingofthehill:confirmCapture')
AddEventHandler('esx_kingofthehill:confirmCapture', function(code)    
    TriggerClientEvent("chatMessage", source, "^5 Payroll: ^0", {0,0,0}, string.format('You have captured the area. To get on the payroll use ^2 /payroll ' .. code))
    TriggerClientEvent('esx_kingofthehill:setCooldown', -1, Config.CoolDownSetting)
    MySQL.Async.execute('DELETE FROM payroll', {})
end)

-- Register new payroll player to DB
RegisterServerEvent('esx_kingofthehill:addToPayroll')
AddEventHandler('esx_kingofthehill:addToPayroll', function(player)
    local xPlayer = ESX.GetPlayerFromIdentifier(player)
    MySQL.Async.fetchAll('SELECT * FROM payroll',{}, function(result)
        if #result < Config.RequiredCapturersMax then
            MySQL.Async.execute('INSERT IGNORE INTO payroll (identifier) VALUES (@identifier)', {
                ['@identifier'] = player
            })
            xPlayer.addInventoryItem('reptag', Config.PayoutCount)
            TriggerClientEvent('esx_kingofthehill:confirmCapture', -1, player)
            TriggerClientEvent('esx:showNotification', xPlayer.source, '~g~You\'ve been added to the payroll')
        else
            TriggerClientEvent('esx:showNotification', xPlayer.source, '~r~There are already ' .. Config.RequiredCapturersMax .. ' people using the code')
        end   
    end)
    
end)

-- Set status of Payroll
RegisterServerEvent('esx_kingofthehill:checkStatus')
AddEventHandler('esx_kingofthehill:checkStatus', function()
    local capturedBy = {}
    local captured = false
    MySQL.Async.fetchAll('SELECT * FROM payroll',{}, function(result)
        if #result > 0 then
            for k,v in pairs(result) do 
                table.insert(capturedBy, v.identifier) 
            end
            captured = true
        end   
        TriggerClientEvent('esx_kingofthehill:setStatusOnLoad', -1, capturedBy, captured)
    end)
end)

-- Check current owners
ESX.RegisterServerCallback('esx_kingofthehill:checkCurrentOwners', function(source, cb)
	local count = 0
    MySQL.Async.fetchAll('SELECT * FROM payroll',{}, function(result)
        if #result > 0 then
            for k,v in pairs(result) do 
                local xPlayer = ESX.GetPlayerFromIdentifier(v.identifier)
                if xPlayer ~= nil then
                    count = count + 1       
                end                        
            end
        else
            count = nil
        end   
        if count == nil then
            cb(Config.NeutralTime)
        elseif count == 0 then        
            cb(nil)
        elseif count == 1 then
            cb(Config.OneOwnerTime)
        elseif count == 2 then
            cb(Config.TwoOwnerTime)
        elseif count == 3 then
            cb(Config.ThreeOwnerTime)
        elseif count == 4 then
            cb(Config.FourOwnerTime)
        elseif count == 5 then
            cb(Config.FiveOwnerTime)
        end	
    end)
end)

-- Check active current owners
ESX.RegisterServerCallback('esx_kingofthehill:checkActiveCapturedBy', function(source, cb)
	local capturedBy = {}
    MySQL.Async.fetchAll('SELECT * FROM payroll',{}, function(result)
        if #result > 0 then
            for k,v in pairs(result) do 
                table.insert(capturedBy, v.identifier)                
            end
        end   
        cb(capturedBy)
    end)	
end)

-- Check payroll code
ESX.RegisterServerCallback('esx_kingofthehill:checkCode', function(source, cb, code)
    local valid = false	
    MySQL.Async.fetchAll('SELECT * FROM payroll_code',{}, function(result)
        if #result > 0 then
            for k,v in pairs(result) do 
                if code == v.code then
                    valid = true
                end               
            end
        end   
        cb(valid)
    end)
end)

-- Run payout at set interval
function Payout(players)
    for k,v in pairs(players) do 
        local xPlayer = ESX.GetPlayerFromIdentifier(v.identifier)
        if xPlayer ~= nil then
            xPlayer.addInventoryItem(Config.PayoutItem, Config.PayoutCount)
            TriggerClientEvent('esx:showNotification', xPlayer.source, '~g~You earned some reputation from the Payroll')
        end           
    end  
    Wait(Config.PayoutInterval)
    GetUsersForPayout()
end

GetUsersForPayout()