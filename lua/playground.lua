local M = {}

local handle_array, handle_keymap, handle_element

local function subtable(tab, index)
  local sub = {}
  for i, value in ipairs(tab) do
    if i >= index then
      table.insert(sub, value)
    end
  end
  return sub
end

local function logv(msg)
  -- print(msg)
end

local function logi(msg)
  print(msg)
end

local function get_visual_selection()
  local s_start = vim.fn.getpos("'<")
  local s_end = vim.fn.getpos("'>")
  local n_lines = math.abs(s_end[2] - s_start[2]) + 1
  local lines = vim.api.nvim_buf_get_lines(0, s_start[2] - 1, s_end[2], false)
  lines[1] = string.sub(lines[1], s_start[3], -1)
  if n_lines == 1 then
    lines[n_lines] = string.sub(lines[n_lines], 1, s_end[3] - s_start[3] + 1)
  else
    lines[n_lines] = string.sub(lines[n_lines], 1, s_end[3])
  end
  return table.concat(lines, '\n')
end

-- linebreak: true
-- foo: {
--   "foo": "bar"
-- }

-- linebreak: false
-- [
--   {
--      "foo": "bar"
--   }
-- ]

local raw =
'{state: {range: 372, doorsState: {hood: CLOSED, trunk: CLOSED}, windowsState: {rightRear: CLOSED, combinedState: CLOSED}, roofState: {roofState: CLOSED, roofStateType: SUN_ROOF}, tireState: {frontLeft: {status: {currentPressure: 260, targetPressure: 280}}, frontRight: {status: {currentPressure: 270, targetPressure: 280}}, rearLeft: {status: {currentPressure: 290, targetPressure: 310}}, rearRight: {status: {currentPressure: 290, targetPressure: 310}}}, location: {coordinates: {latitude: 31.158047777777778, longitude: 121.45864083333333}, address: {formatted: 上海市徐汇区云锦路862号星扬西岸中心}, heading: 352, indoorParkingLocation: {currentParkingDistrict: , currentParkingLevel: , currentParkingBuilding: }}, currentMileage: 14984, climateControlState: {activity: INACTIVE}, requiredServices: [], checkControlMessages: [{type: TIRE_PRESSURE, severity: LOW}], chargingProfile: {chargingControlType: WEEKLY_PLANNER, reductionOfChargeCurrent: {start: {hour: 7, minute: 31}, end: {hour: 7, minute: 31}}, chargingMode: IMMEDIATE_CHARGING, chargingPreference: NO_PRESELECTION, departureTimes: [{id: 1, timeStamp: {hour: 10, minute: 0}, action: DEACTIVATE, timerWeekDays: []}, {id: 2, timeStamp: {hour: 14, minute: 0}, action: DEACTIVATE, timerWeekDays: []}, {id: 3, timeStamp: {hour: 18, minute: 50}, action: DEACTIVATE, timerWeekDays: []}, {id: 4, action: DEACTIVATE, timerWeekDays: []}], climatisationOn: true, chargingSettings: {targetSoc: 100, idcc: NO_ACTION, hospitality: NO_ACTION}}, electricChargingState: {chargingLevelPercent: 100, range: 372, isChargerConnected: false, chargingStatus: INVALID, chargingTarget: 100}, combustionFuelLevel: {range: 372}, driverPreferences: {lscPrivacyMode: OFF}, isDeepSleepModeActive: false, climateTimers: [{isWeeklyTimer: false, timerAction: DEACTIVATE, timerWeekDays: [], departureTime: {hour: 7, minute: 0}}, {isWeeklyTimer: true, timerAction: DEACTIVATE, timerWeekDays: [MONDAY], departureTime: {hour: 7, minute: 0}}, {isWeeklyTimer: true, timerAction: DEACTIVATE, timerWeekDays: [MONDAY], departureTime: {hour: 7, minute: 0}}]}, capabilities: {a4aType: NOT_SUPPORTED, climateNow: true, climateFunction: AIR_CONDITIONING, horn: true, isBmwChargingSupported: false, isCarSharingSupported: false, isChargeNowForBusinessSupported: false, isChargingHistorySupported: true, isChargingHospitalityEnabled: false, isChargingLoudnessEnabled: false, isChargingPlanSupported: true, isChargingPowerLimitEnabled: false, isChargingSettingsEnabled: false, isChargingTargetSocEnabled: false, isCustomerEsimSupported: false, isDataPrivacyEnabled: false, isDCSContractManagementSupported: false, isEasyChargeEnabled: true, isMiniChargingSupported: false, isEvGoChargingSupported: false, isRemoteHistoryDeletionSupported: false, isRemoteEngineStartSupported: false, isRemoteServicesActivationRequired: false, isRemoteServicesBookingRequired: false, isScanAndChargeSupported: false, lastStateCallState: ACTIVATED, lights: true, lock: true, remoteSoftwareUpgrade: true, sendPoi: true, unlock: true, vehicleFinder: true, vehicleStateSource: LAST_STATE_CALL, isRemoteHistorySupported: true, isWifiHotspotServiceSupported: false, isNonLscFeatureEnabled: false, isSustainabilitySupported: true, isSustainabilityAccumulatedViewEnabled: true, specialThemeSupport: [], isRemoteParkingSupported: false, remoteChargingCommands: {}, isClimateTimerWeeklyActive: false, digitalKey: {state: ACTIVATED, bookedServicePackage: SMACC_1_5, readerGraphics: 000200000000, vehicleSoftwareUpgradeRequired: false, isDigitalKeyFirstSupported: false}, isPersonalPictureUploadSupported: false, isPlugAndChargeSupported: false, isOptimizedChargingSupported: false}}'
local raw1 =
'{state: {isLeftSteering: true, lastFetched: 2023-09-12T09:53:54.408Z, lastUpdatedAt: 2023-05-30T01:00:15Z,'
local raw2 = '{a: , b: , d:'


local function insert_line(line, indent)
  if indent > 0 then
    for _ = 0, indent, 1 do
      line = '  ' .. line
    end
  end
  print(line)
end

local function len(tab)
  local i = 0
  for index, v in ipairs(tab) do
    i = index
  end
  return i
end

local function tokenize(input)
  local tokens = {}
  local word = ''
  local check_real_colon = false
  local last_char = ''
  for c in string.gmatch(input, ".") do
    -- print('c: ' .. c .. ', last: ' .. last_char)
    if check_real_colon and c == ' ' then
      table.insert(tokens, '"' .. word .. '"')
      check_real_colon = false
      word = ''
      table.insert(tokens, ":")
    else
      check_real_colon = false
    end
    if c == ':' then
      check_real_colon = true
    elseif c == ',' and last_char == ':' then
      table.insert(tokens, '""')
    elseif c == '{' or c == '}' or c == ',' or c == '[' or c == ']' then
      if word ~= '' then
        table.insert(tokens, '"' .. word .. '"')
        word = ''
      end
      table.insert(tokens, c)
    elseif word == '' and (c == ' ' or c == '\n') then
      -- do nothing
    elseif word == '' and c ~= ' ' then
      word = c
    elseif word ~= '' and c ~= ' ' then
      word = word .. c
    end
    if (c ~= ' ') then
      last_char = c
    end
  end
  for key, value in pairs(tokens) do
    -- log(key .. ': ' .. value)
  end
  return tokens
end

function handle_keymap(tokens, indent, linebreak, start_index)
  logv('handle_keymap: ' .. tokens[start_index])
  local line = ''
  local index = start_index
  while true do
    -- log('tokens[' .. index .. ']' .. tokens[index])
    if index == #tokens then
      insert_line('}', indent)
      break
    end
    -- if index == start_index and linebreak then
    --   logv('[handle start] indent: ' .. indent)
    --   line = tokens[index] .. ': ' .. tokens[index + 2]
    --   index = index + 2
    --   if tokens[index + 1] == ',' then
    --     logv(', FOUND' .. index)
    --     line = line .. ','
    --     index = index + 1
    --   end
    --   insert_line(line, indent + 1)
    --   line = ''
    if tokens[index] == '}' then
      logv('} FOUND' .. index)
      line = '}'
      if tokens[index + 1] == ',' then
        line = '},'
        index = index + 1
      end
      insert_line(line, indent)
      line = ''
      logv('MAP END index: ' .. index)
      return index
    elseif tokens[index] == '{' then
      logv('{ FOUND' .. index)
      insert_line('{', indent)
      index = index + 1
    elseif string.sub(tokens[index + 2], 1, 1) == '"' then
      logv('" FOUND' .. index)
      line = tokens[index] .. ': ' .. tokens[index + 2]
      index = index + 2
      if tokens[index + 1] == ',' then
        line = line .. ','
        index = index + 1
      end
      insert_line(line, indent + 1)
      line = ''
    elseif string.sub(tokens[index + 2], 1, 1) == '{' then
      logv('{ FOUND' .. index)
      -- "list": {
      --   "a"
      -- }
      line = tokens[index] .. ': {'
      index = index + 2
      insert_line(line, indent + 1)
      line = ''
      index = handle_keymap(tokens, indent + 1, true, index + 1) + 1
      logv('^^^^^ index' .. index)
    elseif string.sub(tokens[index + 2], 1, 1) == '[' then
      logv('[ FOUND' .. index)
      -- "list": [
      --   "a"
      -- ]
      line = tokens[index] .. ': ['
      index = index + 2
      insert_line(line, indent + 1)
      line = ''
      index = handle_array(tokens, indent + 1, true, index + 1) + 1
      logv('^^^^^ index' .. index)
    else
      index = index + 1
    end
  end
end

function handle_array(tokens, indent, linebreak, start_index)
  local index = start_index
  local line = ''
  while true do
    logv('current index: ' .. index)
    if string.sub(tokens[index], 1, 1) == '{' then
      index = handle_keymap(tokens, indent + 1, false, index) + 1
    elseif string.sub(tokens[index], 1, 1) == '"' then
      -- elements array
      index = handle_element(tokens, indent + 1, index) + 1
    elseif tokens[index] == ']' then
      line = ']'
      logv("** FOUND ] " .. index)
      if tokens[index + 1] == ',' then
        logv("** FOUND ,")
        line = '],'
        index = index + 1
      end
      insert_line(line, indent)
      line = ''
      logv('LIST END index: ' .. index)
      return index
    else
      index = index + 1
    end
  end
end

function handle_element(tokens, indent, start_index)
  local index = start_index
  local line = tokens[start_index]
  if tokens[index + 1] == ',' then
    line = line .. ','
    index = index + 1
  end
  insert_line(line, indent)
  return index
end

function M.fmt()
  local tokens = tokenize(raw)
  for index, value in ipairs(tokens) do
    -- logv(index .. ': ' .. value)
  end
  handle_keymap(tokens, 0, false, 1)
end

M.fmt()

return M
