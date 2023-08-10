-- ###############################################################################################
-- # F3F Tool for JETI DC/DS transmitters 
-- # Module: f3fRun
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
-- ========== Object: f3fRun                                                            ==========
-- ========== contains the necessary logic for the run                                  ==========
-- ===============================================================================================
-- ===============================================================================================

local f3fRun = {
--  this needs too much memory for monochrome TX, use Integer directly 
--  status = { INIT=1, ON_HOLD=2, STARTPHASE=3, TIMEOUT=4, F3F_RUN=5 },

  curPosition = nil,             -- current position of model
  curDist = nil,                 -- current distance from home position
  curBearing = nil,              -- current angle from slope
  curDir = nil,                  -- current position on left/right side from home
  nextTurnDir = nil,             -- side of expected next turn
  curSpeed = nil,                -- current speed (given from sensor)
  
  -- values for gps-optimization
  --  maxOffset = 25,             -- max. offset value in [m] at 150 km/h and 100% effect
                                  -- this constant not used here for memory optimization

  -- 'offsets' and 'inside-flags' for launch phase and f3f run.
  -- the values are always calculated independently from the current 
  -- f3f-status. So we know where we are if a status change occurs
  -- (from launch phase to f3f run or in case of reset from f3f run to launch phase)
  -- the values can differ, because the considered offsets work in opposite directions.

  launchPhaseData = { offset=0, insideFlag=0 },
  f3fRunData = { offset=0, insideFlag=0 },
  
  -- other stuff
  curStatus = nil,
  rounds = 0,
  
  launchTime = 0,                 -- time of launch, 30 seconds started
  countdownTime = 0,              -- countdown from launch (F3F) or tow hook release (F3B) to fly in
  remainingCountdown = 0,         -- remaining countdown for start time
  halfDistance = 0,               -- half length of the course, depending on f3f / f3b

  f3fStartTime = 0,               -- start time of f3f-run
  flightTime = 0,
  
  timerStartSpeed = -1,           -- timer for speed-measuring 1,5 sec. after start of f3f-run
  
  -- Object references from main program
  globalVar = nil,
  basicCfg = nil,
  slope = nil,
  gpsSensor = nil
}

-- function f3fRun:isStatus ( status ) return self.curStatus == status end
                                  -- nice function, but not used for memory optimization 

--------------------------------------------------------------------------------------------
function f3fRun:init ()
  -- initial status
  -- self.curStatus = self.status.INIT
  self.curStatus = 1
  self.curDir = self.globalVar.direction.UNDEF
  self.nextTurnDir = self.globalVar.direction.UNDEF
  
  if self.slope.mode == 2 then                     -- F3B
    self.halfDistance = self.basicCfg.f3bDistance / 2
	
    if ( self.basicCfg.f3bMode == 1 ) then             -- speed
      self.countdownTime = 60
    elseif ( self.basicCfg.f3bMode == 2 ) then         -- distance
      self.countdownTime = 0
    end
	
  else                                             -- F3F
    self.countdownTime = 30   
    self.halfDistance = self.basicCfg.f3fDistance / 2
  end
end

--------------------------------------------------------------------------------------------
function f3fRun:setNextTurnDir ()

  -- set side of next turn
  if ( self.curDir == self.globalVar.direction.LEFT ) then
    self.nextTurnDir = self.globalVar.direction.RIGHT
  elseif ( f3fRun.curDir == self.globalVar.direction.RIGHT ) then
    self.nextTurnDir = self.globalVar.direction.LEFT
  end
end

--------------------------------------------------------------------------------------------
-- launch: start button was pressed

function f3fRun:launch ()
  
  -- slope not defined? ?
  if ( self.globalVar.errorStatus == 4 ) then
     -- cancel - beep
     system.playBeep (2, 1000, 200)
     return
  end
  
  -- check, if sensors are active
  self.globalVar.errorStatus = 0
  self.gpsSensor:getCurPosition ()
  if ( self.globalVar.errorStatus ~= 0 ) then
     -- cancel - beep
     system.playBeep (2, 1000, 200)
     return
  end
  
  -- start launch phase
  --  self.curStatus = self.status.STARTPHASE
  self.curStatus = 3
  self.rounds = 0

  self.launchTime = system.getTimeCounter()
  self.remainingCountdown = self.countdownTime

  system.playFile (self.globalVar.resource.audioStart, AUDIO_IMMEDIATE)
  
  -- in F3F and F3B-Speed mode announce countdown time
  if ((self.slope.mode ~= 2) or (self.basicCfg.f3bMode ~= 2)) then
    system.playNumber (self.remainingCountdown, 0)
    system.playFile (self.globalVar.resource.audioSeconds, AUDIO_QUEUE)
  end
end

--------------------------------------------------------------------------------------------
-- start run: A-Base was passed from outside course or timeout occurred

function f3fRun:startRun ( timeout )
  
  -- in F3B-Distance mode go directly on hold and just count legs
  if ((self.slope.mode == 2) and (self.basicCfg.f3bMode == 2)) then
  --     self.curStatus = self.status.ON_HOLD
     self.curStatus = 2
  
  -- timeout - late entry ocurred   
  elseif (timeout) then
  --     self.curStatus = self.status.TIMEOUT
     self.curStatus = 4
  else
  -- regular f3f-start 
  --     self.curStatus = self.status.F3F_RUN
     self.curStatus = 5
  end
  
  self.f3fStartTime = system.getTimeCounter()
  system.playFile (self.globalVar.resource.audioCourse, AUDIO_QUEUE)
  
  -- start timer for speed measurement after 1,5 sec.
  --   if ( self.curSpeed and self.curStatus == self.status.F3F_RUN) then
  if ( self.curSpeed and self.curStatus == 5) then
     self.timerStartSpeed = system.getTimeCounter()
  end
end

--------------------------------------------------------------------------------------------
-- distance done: A-Base or B-Base was passed from inside course

function f3fRun:distanceDone ()

-- if we are not in a valid f3f-run - just beep to practise
   -- if (self.curStatus ~= self.status.F3F_RUN) then
   if (self.curStatus ~= 5) then
     system.playBeep (0, 700, 300)  
   end
   
   -- in F3B-mode: count more rounds after 4 rounds (status 2: ON_HOLD)
   if ( (self.slope.mode == 2) and ( self.curStatus == 2)) then
     self.rounds = self.rounds+1
   end

   local maxRounds
   if ( self.slope.mode == 1 ) then
     maxRounds = 10              -- F3F mode
   elseif ( self.slope.mode == 2 ) then
     maxRounds = 4               -- F3B mode
   end
   
   -- are we in f3f-run ?
   -- if ( self:isStatus (self.status.F3F_RUN)  ) then
   if ( self.curStatus == 5 ) then

      -- one more leg done
      self.rounds = self.rounds+1

      -- perform the appropriate beep
      if (self.rounds <= maxRounds-2 ) then
        system.playBeep  (0, 700, 300)  
      elseif (self.rounds == maxRounds-1 ) then
        system.playBeep  (1, 700, 300)	   
      else	  
        system.playBeep  (2, 850, 200)
      end

      -- from leg 8 make an announcement
      if ( self.rounds > maxRounds-3 and self.rounds < maxRounds ) then
         system.playNumber (self.rounds, 0)	  
      end

      -- all legs done - get flight time, change status
      if ( self.rounds >= maxRounds ) then
  	     local endTime = system.getTimeCounter()
        self.flightTime = endTime-self.f3fStartTime
		  
        system.playFile (self.globalVar.resource.audioTime, AUDIO_QUEUE)
        system.playNumber (self.flightTime / 1000, 1)
        system.playFile (self.globalVar.resource.audioSeconds, AUDIO_QUEUE)
		   
--      self.curStatus = self.status.ON_HOLD
        self.curStatus = 2
      end
   end
   
   -- set side of next turn
   self:setNextTurnDir ()

end

--------------------------------------------------------------------------------------------
-- calc remaining time for launch phase and give some announcements

function f3fRun:countdown ()

  -- skip countdown for F3B-Distance mode
  if ((self.slope.mode == 2) and (self.basicCfg.f3bMode == 2)) then
     return
  end	 

  local prevValue = self.remainingCountdown
  local curTime = system.getTimeCounter()     
  self.remainingCountdown = math.floor (self.countdownTime - (curTime-self.launchTime)/1000)

  if (self.remainingCountdown ~= prevValue) then

     -- Announcement
     if ( (self.remainingCountdown >= 30 and self.remainingCountdown % 10 == 0) or 
          (self.remainingCountdown  < 30 and self.remainingCountdown %  5 == 0) or 
          (self.remainingCountdown <= 10) )  then
		
        system.playNumber (self.remainingCountdown, 0)
     end
  end  
    
  -- Timeout: start F3F run / cancel F3B run 
  if ( self.remainingCountdown == 0 ) then
	   
     if ( self.slope.mode == 1 ) then        -- F3F
        self:startRun ( true ) 
     elseif ( self.slope.mode == 2 ) then    -- F3B
        system.playBeep (2, 500, 400)  
        self:init ()
     end	 
  end
end

--------------------------------------------------------------------------------------------
-- update current position, distance and bearing data

function f3fRun:updatePositionData ( point )

  if ( not point ) then return end
  self.curPosition = point
  
  ------ calc current distance
  if (self.slope.gpsHome) then
     self.curDist = gps.getDistance (self.slope.gpsHome, self.curPosition)
  end

  ------ calc current flight angle to slope
  if ( self.slope.gpsHome and self.slope.bearing ) then 
     
     -- current flight angle from north
     self.curBearing = gps.getBearing (self.slope.gpsHome, self.curPosition)

     -- current flight angle to slope
     self.curBearing = self.slope.bearing - self.curBearing
     if (self.curBearing < 0) then 
        self.curBearing = self.curBearing + 360
     end
	 
     -- determine, on which side of home position the model is located
     -- curBearing always meant clockwise from flight line to slope
	 
     if (self.curBearing <= 90 or self.curBearing > 270) then     -- 0-90 deg, 270-360 deg
        self.curDir = self.globalVar.direction.RIGHT
     else                             
        self.curDir = self.globalVar.direction.LEFT                -- 90-270 deg
     end

  end
end

--------------------------------------------------------------------------------------------
-- update current speed from sensor, calculate optimization offsets
-- the whole magic of GPS and latency optimization

function f3fRun:updateSpeedAndOptimizationData ( speed )

  self.curSpeed = speed
  if ( self.curSpeed ) then
  
     -- offset determination
     -- for memory optimization we don't use configurable parameters but calculate it here absolutely

     -- self.f3fRunData.offset = (self.curSpeed / (150/self.maxOffset))  * (self.basicCfg.speedFaktorF3F / self.basicCfg.maxSpeedFaktor)
     -- self.launchPhaseData.offset = (-1) * (((self.curSpeed / (150/self.maxOffset))  * (self.basicCfg.speedFaktorLaunchPhase / self.basicCfg.maxSpeedFaktor)) + self.basicCfg.statOffsetLaunchPhase)

     --  1/(150/25)  * (65 / 100) = 0.65/6 
     -- stat. Offset bei Start: 8

     self.f3fRunData.offset = self.curSpeed * 0.65/6
     -- *(-1): in launch phase the offset works in the opposite direction to optimize the first fly in
     --        also add a static offset, this brought better results in flying tests, can't explain why
     self.launchPhaseData.offset =  (-1) * ((self.curSpeed * 0.65/6) + 8)
  end
end

--------------------------------------------------------------------------------------------
-- check, if a fly out occurred, consider the calculated offsets and the turn line calculation
-- based on the cosinus

function f3fRun:checkFlyOut ( trackData )

  if ( trackData.insideFlag and 
     (self.curDist + trackData.offset) * math.abs ( math.cos (math.rad ( self.curBearing )))
      > self.halfDistance) then
  
     trackData.insideFlag = false  
     return true
  end
  
  return false  
end

--------------------------------------------------------------------------------------------
-- check, if a fly in occurred, consider the calculated offsets and the turn line calculation
-- based on the cosinus

function f3fRun:checkFlyIn ( trackData )

  if ( not trackData.insideFlag and 
     (self.curDist + trackData.offset) * math.abs ( math.cos (math.rad ( self.curBearing ))) 
      < self.halfDistance) then
  
     trackData.insideFlag = true 
     return true
  end
  
  return false  
end

--------------------------------------------------------------------------------------------
return f3fRun
