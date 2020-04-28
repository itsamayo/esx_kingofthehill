Config = {}
Config.BlockEmergencyServices = true -- Allow/Disallow Police & EMS from capturing
Config.RequiredCapturersMin = 3 -- Minimum members required for capture group
Config.RequiredCapturersMax = 5 -- Max allowed number of capturers in a group
Config.RequiredCaptureDistance = 20.0 -- How clost to capture point you need to be to start a capture
Config.CaptureBreakingDistance = 50.0 -- How far you can go without leaving the capturing
Config.NeutralTime =  1 * 600 -- 1 minute - Time it takes to capture when it isn't owned by anyone
Config.OneOwnerTime =  40 * 600 -- 40 minutes - Time it takes to capture when 1 of the owners is online
Config.TwoOwnerTime = 35 * 600 -- 35 minutes - Time it takes to capture when 2 of the owners are online
Config.ThreeOwnerTime = 30 * 600 -- 30 minutes - Time it takes to capture when 3 of the owners are online
Config.FourOwnerTime = 20 * 600 -- 20 minutes - Time it takes to capture when 4 of the owners are online
Config.FiveOwnerTime = 15 * 600 -- 15 minutes - Time it takes to capture when 5 of the owners are online
Config.PayoutInterval = 12 * 60000 -- 12 minutes - Payout interval
Config.PayoutItem = 'marijuana' -- Reward item (make sure whatever you reward, is in the DB)
Config.PayoutCount = 10 -- Count of item reward
Config.CoolDownSetting = 300 * 60000 -- 5 hours - Cooldown time afer successful capture before another capture can be started
Config.CoolDown = 0 -- Gets set on capture - default must be 0

Config.GroveStreet = {      
    pos = { x = 111.25, y = -1946.97, z = 20.74 },
    captured = false,
    captureInProgress = false,
    captureCount = 0,
    capturers = {},
    capturedBy = {},
    showPercentage = false
}