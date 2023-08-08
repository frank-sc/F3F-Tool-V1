-- ###############################################################################################
-- # F3F Tool for JETI DC/DS transmitters 
-- # Module: slopeMgrForm
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
-- ========== Object: slopeMgrForm                                                      ==========
-- ========== contains form and functions for course setup                              ==========
-- ===============================================================================================
-- ===============================================================================================

local slopeMgrForm = {
  -- referenced objects, set from outside
  dataDir = nil,
  globalVar = nil,
  slope = nil,
  gpsSens = nil,
  errorTable = nil,
  f3bDist = nil,
  handleErr = nil

  -- internal stuff
  displayName = "",
  action = "",               -- display information
  checkBoxSlope = nil,       -- checkBox components
  checkBoxBearingL = nil,
  checkBoxBearingR = nil,
  
  gpsNewHome = nil,          -- new Center point
  gpsBearLeft = nil,	       -- left bearing point
  gpsBearRight = nil,        -- right bearing point
  
  mode = nil,                -- 1: F3F  /  2: F3B
}

--------------------------------------------------------------------------------------------
function slopeMgrForm:setF3FSlopeSetup ()
  form.setTitle ("Setup F3F-Slope")
  
  form.addRow(3)
  form.addLabel({label="Start:", width=65, font=FONT_BOLD})
  form.addLabel({label="center point (starting pos.)", width=195})
  self.checkBoxSlope = form.addCheckbox( false, nil, {enabled=false})

  form.addRow(3)
  form.addLabel({label="Left:", width=65, font=FONT_BOLD})
  form.addLabel({label="left Bearing point", width=195})
  self.checkBoxBearingL = form.addCheckbox( false, nil, {enabled=false})

  form.addRow(3)
  form.addLabel({label="Right:", width=65, font=FONT_BOLD})
  form.addLabel({label="right bearing point", width=195})
  self.checkBoxBearingR = form.addCheckbox( false, nil, {enabled=false})

  form.setButton(1,"Start", ENABLED)
  form.setButton(2,"Left",ENABLED)
  form.setButton(3,"Right",ENABLED)
  form.setButton(4,"F3B",ENABLED)
  
  -- slope already defined ?  
  if ( self.slope:isDefined () ) then
     self.displayName = self.slope.name
     self.action = string.format("%s-Slope (%.0f degrees)", self:getWindDir (self.slope.bearing) )
  end  

end

--------------------------------------------------------------------------------------------
function slopeMgrForm:setF3BCourseSetup ()
  form.setTitle ("Setup F3B-Course")

  form.addRow(3)
  form.addLabel({label="Start:", width=65, font=FONT_BOLD})
  form.addLabel({label="starting position", width=195})
  self.checkBoxBearingL = form.addCheckbox( false, nil, {enabled=false})

  form.addRow(3)
  form.addLabel({label="Bear:", width=65, font=FONT_BOLD})
  form.addLabel({label="bearing point", width=195})
  self.checkBoxBearingR = form.addCheckbox( false, nil, {enabled=false})

  -- form.setButton(1,"Start", ENABLED)
  form.setButton(1,"Start", ENABLED)
  form.setButton(2,"Bear",ENABLED)
  form.setButton(4,"F3F",ENABLED)
  
  -- course already defined ?  
  if ( self.slope:isDefined () ) then
     self.displayName = self.slope.name
     self.action = string.format("F3B-course (%.0f degrees)", self.slope.bearing )
  end  
  
end

--------------------------------------------------------------------------------------------
function slopeMgrForm:initSlopeForm (formID)

  local freeMem = collectgarbage("count");

  -- clear memory for new challenge
  collectgarbage("collect") 

  -- set initial F3F/F3B mode from slope object
  if ( not self.mode) then
     self.mode = self.slope.mode
  end	 
  if (self.mode == 2) then formID = 2 end
  
  -- reset display action
  self.action = ""

  -- show form for mode
  if ( formID == 1) then
     self:setF3FSlopeSetup ()
	 
  elseif ( formID == 2) then	 
	 self:setF3BCourseSetup ()
  end	 

  -- show a cancel button, until all points are scanned
  form.setButton(5, "Cancel", ENABLED)

  local freeMem = collectgarbage("count");
  print("GC Count after slopemgr init : " .. freeMem .. " kB");
   
end
     
--------------------------------------------------------------------------------------------
-- get GPS-position from Sensor
function slopeMgrForm:scanGpsPoint ( checkBox, successMsg )

  local gpsPoint
  gpsPoint = self.gpsSens:getCurPosition ()  
	
   if (self.globalVar.errorStatus >0) then
     self.action = self.errorTable [self.globalVar.errorStatus][1].." "
	                ..self.errorTable [self.globalVar.errorStatus][2].." "
				          ..self.errorTable [self.globalVar.errorStatus][3]
   end

  if (  gpsPoint ) then                                        
     -- set status information   
     if ( checkBox ) then form.setValue(checkBox, true ) end
     if ( successMsg ) then self.action = successMsg end
  end 

  return gpsPoint
end

--------------------------------------------------------------------------------------------
function slopeMgrForm:handleF3FSlopeKeys(key)

   -- start button
   if(key==KEY_1) then
     self.gpsNewHome = self:scanGpsPoint ( self.checkBoxSlope, "Starting position set" )

   -- button bearing left 
   elseif(key==KEY_2) then
     self.gpsBearLeft = self:scanGpsPoint ( self.checkBoxBearingL, "Left bearing point set" )

   -- button bearing right
   elseif(key==KEY_3) then
     self.gpsBearRight = self:scanGpsPoint ( self.checkBoxBearingR, "Right bearing point set" )

   -- toggle to F3B-mode
   elseif(key==KEY_4) then
     if not ( self.gpsNewHome or self.gpsBearLeft or self.gpsBearRight ) then
       self.mode = 2
       form.reinit (2)
	 end
   end
   
   -- disable F3B mode and hide course name if scan is started
   if ( self.gpsNewHome or self.gpsBearLeft or self.gpsBearRight ) then
      form.setButton(4,"F3B",DISABLED)
      self.displayName = ""   
   end

   -- data complete ? -> show slope bearing and enable OK
   if ( self.gpsNewHome and self.gpsBearLeft and self.gpsBearRight ) then
   
      local bearing = gps.getBearing ( self.gpsBearLeft, self.gpsBearRight )
      self.action = string.format("%s-Slope (%.0f degrees)", self:getWindDir (bearing) )
   
      form.setButton(5, "Ok", ENABLED)
   end

end

--------------------------------------------------------------------------------------------
function slopeMgrForm:handleF3BCourseKeys(key)

   -- start button (start point will be our left point in F3B)
   if(key==KEY_1) then
     self.gpsBearLeft = self:scanGpsPoint ( self.checkBoxBearingL, "Starting position set" )

   -- button bearing (will be our right point in F3B)
   elseif(key==KEY_2) then
     self.gpsBearRight = self:scanGpsPoint ( self.checkBoxBearingR, "Bearing point set" )

   -- toggle to F3F-mode
   elseif(key==KEY_4) then
     if not ( self.gpsNewHome or self.gpsBearLeft or self.gpsBearRight ) then
       self.mode = 1
       form.reinit (1)
	 end
   end
   
   -- disable F3F mode and hide course name if scan is started
   if ( self.gpsNewHome or self.gpsBearLeft or self.gpsBearRight ) then
      form.setButton(4,"F3F",DISABLED)
      self.displayName = ""   
   end

   -- data complete 
   if ( self.gpsBearLeft and self.gpsBearRight ) then

      local bearing = gps.getBearing ( self.gpsBearLeft, self.gpsBearRight )
	  
	  -- calc home position, half distance away from start
	  self.gpsNewHome = gps.getDestination ( self.gpsBearLeft, self.f3bDist / 2, bearing )
      self.action = string.format("F3B-course (%.0f degrees)", bearing )

      form.setButton(5, "Ok", ENABLED)
   end
   
end

--------------------------------------------------------------------------------------------
-- observe keys of scan page
function slopeMgrForm:slopeScanKeyPressed(key)

   if self.mode == 1 then
      self:handleF3FSlopeKeys(key)
   elseif self.mode == 2 then
      self:handleF3BCourseKeys(key)
   end

   -- button OK	/ Cancel 
   if(key==KEY_5) then
   
     if ( self.gpsNewHome and self.gpsBearLeft and self.gpsBearRight ) then
       -- set home and calc bearing
       self.slope.gpsHome = self.gpsNewHome
       self.slope.bearing = gps.getBearing ( self.gpsBearLeft, self.gpsBearRight )

       self.slope.mode = self.mode
       -- F3B: A-Base always left, left Base is defined as start point
	   if (self.mode == 2) then
	      self.slope.aBase = self.globalVar.direction.LEFT
	   end

       -- new scan has no name yet
       self.slope.name = nil

       -- save it
	   self.slope:persist ()
       -- ok - beep
       system.playBeep (0, 700, 300)  
	
     else
	   -- cancel - beep
       system.playBeep (2, 1000, 200)
     end

   end
     
end  

--------------------------------------------------------------------------------------------
-- calculate wind direction
  function slopeMgrForm:getWindDir ( bearing )

	local windDir = -1
    local windDirDesc = "undefined"
	
    local angle, low, high
	  
	  -- read wind direction descriptions from file
	  local filespec = self.dataDir .. "/windDir-" ..self.globalVar.lng.. ".jsn"	  
	  local desc
	  local file = io.readall( filespec )
      if( file ) then
         desc = json.decode(file)
	  else
         self.handleErr ("can not open file: '" ..filespec .."'")	  
	  end

	-- get wind direction from slope bearing
    if bearing < 90 then windDir = bearing + 270 else windDir = bearing - 90 end
	
    for i = 0, 15, 1 do
      angle = i * 22.5

      -- calculate range for wind direction
      low = angle - 11.25
      if low < 0 then low = low+360 end
      local high = angle + 11.25
      if high > 360 then high = high -360 end

      -- inside ?
      if ( windDir > low and windDir < high) then
	    if (desc) then windDirDesc = desc [i+1] end
	    break
      end
    end
    return windDirDesc, windDir	  -- maybe: ( South, 185 )	
  end


--------------------------------------------------------------------------------------------
function slopeMgrForm:printSlopeForm()
   if ( self.displayName and self.displayName ~= "" ) then
      lcd.drawText(20,90, self.displayName .. ":", FONT_BIG)   
   end
   lcd.drawText(20,115, self.action, FONT_BIG)   
end  

--------------------------------------------------------------------------------------------
return slopeMgrForm
