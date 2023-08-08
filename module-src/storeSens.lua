-- ###############################################################################################
-- # F3F Tool for JETI DC/DS transmitters 
-- # Module: storeSens
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
-- ========== Object: storeSens                                                         ==========
-- ========== contains functions for temporary sensor list in a file                    ==========
-- ========== needed for memory optimization                                            ==========
-- ===============================================================================================
-- ===============================================================================================

local storeSens = {}

--------------------------------------------------------------------------------------------
function storeSens:isIn (element, list)
  
  for i, elem in ipairs ( list ) do
     if elem == element then
	    return true
	 end
  end
  return false
end

--------------------------------------------------------------------------------------------
-- save Sensor data in a file for later use  
-- part of memory optimization for Gen1 - Hardware

function storeSens:storeSensorData ( dir, filename )

  collectgarbage("collect") 
  -- print(" init:" .. collectgarbage("count") .. " kB")

  -- save sensor information in a file
  local sysSensors = system.getSensors()     -- system list of sensors and telemetry-entries

  -- look for sensor id's which contain an entry with type '9' (GPS Coordinates)
  local gpsIds = {}
  for index,sensor in ipairs(sysSensors) do 

    local id = sensor.id
    if ( sensor.type == 9 ) then             -- type '9' = GPS-coordinates
       if not self:isIn ( id, gpsIds ) then
          gpsIds [ #gpsIds+1 ] = id
	    end	 
	  end
  end

  -- build new table with reduced entries and reduced data per entry
  local newSens = {}
  for index,sensor in ipairs(sysSensors) do

     -- store only GPS-relevant telemetry entries 
     if self:isIn ( sensor.id, gpsIds ) then  
       local entry = { label=sensor.label, param = sensor.param, unit = sensor.unit }
	 
	   -- important: explicitly convert the id to decimal, otherwise it is written as float by the
	   --            json encoder and corrupted by loss of precision !
	   entry.id = string.format ("%d", sensor.id )
	 
       -- add to new list 
       newSens [ #newSens+1 ] = entry
	 end  
	 
	 sysSensors [ index ] = nil
     collectgarbage("collect") 
  end

  -- save list for later use in sensor configuration
  
  local f = io.open ( dir.."/"..filename, "w" )	   
  if ( f ) then
    io.write(f, json.encode ( newSens ), "\n")
    io.close ( f )
  else
     print ( "ERROR: can not write file: " .. fSpec)
  end
  
  -- print (" init - sensor list: " .. collectgarbage("count") .. " kB");

  -- cleanup
  sysSensors = nil
  newSens=nil
  collectgarbage("collect") 

  -- print(" init - after collect: " .. collectgarbage("count") .. " kB");
end

--------------------------------------------------------------------------------------------
return storeSens