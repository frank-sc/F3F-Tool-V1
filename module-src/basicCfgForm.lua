-- ###############################################################################################
-- # F3F Tool for JETI DC/DS transmitters 
-- # Module: basicCfgForm
-- #
-- # Copyright (c) 2023 Frank Schreiber
-- #
-- #    This program is free software: you can redistribute it and/or modify
-- #    it under the terms of the GNU General Public License as published by
-- #    the Free Software Foundation, either version 3 of the License, or
-- #    (at your option) any later version.
-- #    
-- #    This program is distributed in the hope that it will be useful,
-- #    but WITHOUT ANY WARRANTY; without even the implied warranty of
-- #    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- #    GNU General Public License for more details.
-- #    
-- #    You should have received a copy of the GNU General Public License
-- #    along with this program.  If not, see <http://www.gnu.org/licenses/>.
-- #
-- ###############################################################################################

-- ===============================================================================================
-- ===============================================================================================
-- ========== Object: basicCfgForm                                                      ==========
-- ========== contains form and functions for basic f3f-Tool configuration              ==========
-- ===============================================================================================
-- ===============================================================================================

local basicCfgForm = {
   cfgData = nil,
   gpsSensor = nil,
   handleErr = nil,
   dataDir = nil,
   
   sensorList = nil,
   
   compSwitch = nil,
   compCtrlCenterShift = nil,
   compF3bDistance = nil,
   compF3fDistance = nil,
   compSensorLat = nil,
   compSensorLon = nil,
   compSensorSpeed = nil
}

--------------------------------------------------------------------------------------------
-- Check: control valid ?

function basicCfgForm:checkControl (value)
   if (not (value and system.getSwitchInfo (value).assigned)) then
      value = nil
   end
   return value
end

--------------------------------------------------------------------------------------------
-- determine index of a sensor in the sensor list

function basicCfgForm:findIndexForSensor (sensorId, paramId)
   local curIndex=-1
   for index, sensor in ipairs(self.sensorList) do
      if(sensor.id==sensorId and sensor.param==paramId) then 
        curIndex=index
      end
   end
   return curIndex
end

--------------------------------------------------------------------------------------------
function basicCfgForm:initForm(formID)

  -- create sensor list
  self.sensorList = {}                      -- list of sensors, without 'label'-entries like 'GPSLog3'                                        
  --local sysSensors = system.getSensors()    -- system list of sensors and telemetry-entries / not used here directly for memory optimization
  local sysSensors
  local list={}                             -- display-list of telemetry-entries - with preceding Sensor-Label
  local curIndex=-1                         -- index of configured sensor
  local descr = ""                          -- Sensor-Label (e.g. 'GPSLog3') 
   
  -- get reduced system sensor data from saved json-file
  -- direct use of 'system.getSensors()' needs too much memory
  local file = io.readall(self.dataDir .. "/sensors.jsn")
  if( file ) then
     sysSensors = json.decode(file)
	  
     -- convert id values back to number
     for i, sens in ipairs (sysSensors) do
        sens.id = tonumber (sens.id)
     end
  
   else
      self.handleErr ("could not read Sensor file")
   end

   -- for use of Dave McQueeney's SensorEmulator with Jeti Studio:
   --   use 'getSensors' directly, doesn't work the other way 
   local device, devType = system.getDeviceType ()
   if (devType == 1) then  
      sysSensors = system.getSensors()
   end	 
 
  -- build the display list - sensor labels are removed from list and preceded to telemetry entries
  -- and a corresponding sensor reference list without sensor labels
  for index,sensor in ipairs(sysSensors) do 
    if(sensor.param == 0) then
      descr = sensor.label
    else
      local unit = ""
      if (sensor.unit) then unit = "[" .. sensor.unit .. "]" end

      list[#list+1]=string.format("%s - %s %s",descr,sensor.label, unit)   
      self.sensorList[#self.sensorList+1] = sensor
    end
  end

  --  print(" basic cfg - lists: " .. collectgarbage("count") .. " kB");

  --cleanup
  collectgarbage("collect") 

  -- multifunction button
  form.addRow (2)
  form.addLabel({label="Multi-Switch"})
  self.compSwitch = form.addInputbox(self.cfgData.switch, false, nil)

  -- adjustment of center
  form.addRow (2)
  form.addLabel({label="Center adjust ctrl. (prop)", width = 250})
  self.compCtrlCenterShift = form.addInputbox(self.cfgData.ctrlCenterShift, true, nil,{width=60})

  -- definition of distance (F3B / F3F)
  form.addRow(4)
  form.addLabel({label="F3B Dist.[m]", width=100})
  self.compF3bDistance = form.addIntbox (self.cfgData.f3bDistance, 5,200,150,0,1, nil, {width=55})
  form.addLabel({label="F3F Dist.[m]", width=100})
  self.compF3fDistance = form.addIntbox (self.cfgData.f3fDistance, 5,150,100,0,1, nil, {width=55})

  -- sensors for GPS-position
  form.addLabel({label=" --------------------------- Sensors ------------------------------", font=FONT_MINI})

  form.addRow (2)
  form.addLabel({label="- Latitude", width=110})
  curIndex = self:findIndexForSensor (self.gpsSensor.lat.id, self.gpsSensor.lat.param)
  self.compSensorLat = form.addSelectbox (list, curIndex ,true, nil, {width=200})

  form.addRow (2)
  form.addLabel({label="- Longitude", width=110})
  curIndex = self:findIndexForSensor (self.gpsSensor.lon.id, self.gpsSensor.lon.param)
  self.compSensorLon = form.addSelectbox (list, curIndex ,true, nil, {width=200}) 

  -- speed-sensor
  form.addRow (2)
  form.addLabel({label="- Speed", width=110})
  curIndex = self:findIndexForSensor (self.gpsSensor.speed.id, self.gpsSensor.speed.param)
  self.compSensorSpeed = form.addSelectbox (list, curIndex,true, nil, {width=200}) 

  print("GC Count after config init : " .. collectgarbage("count") .. " kB");	
end  

--------------------------------------------------------------------------------------------
function basicCfgForm:closeForm ()

  local value
  
  value = form.getValue ( self.compSwitch )
  self.cfgData.switch = self:checkControl(value)
  system.pSave("switch",value)

  value = form.getValue ( self.compCtrlCenterShift )
  self.cfgData.ctrlCenterShift = self:checkControl(value)
  system.pSave("ctrlCenterShift", value)  
  
  value = form.getValue ( self.compF3bDistance )
  if (value) then 
    self.cfgData.f3bDistance=value
    system.pSave("f3bDistance", value)
  end
  
  value = form.getValue ( self.compF3fDistance )
  if (value) then 
    self.cfgData.f3fDistance=value
    system.pSave("f3fDistance", value)
  end
  
  value = form.getValue ( self.compSensorLat )
  if (value and value>0) then 
    self.gpsSensor:setSensorValue ( self.gpsSensor.lat, self.sensorList[value])
  end 
  
  value = form.getValue ( self.compSensorLon )
  if (value and value>0) then 
    self.gpsSensor:setSensorValue ( self.gpsSensor.lon, self.sensorList[value])
  end 
 
  value = form.getValue ( self.compSensorSpeed )
  if (value and value>0) then 
    self.gpsSensor:setSensorValue ( self.gpsSensor.speed, self.sensorList[value])
  end 
end

--------------------------------------------------------------------------------------------
return basicCfgForm


