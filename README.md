# F3F-Tool V1
This lua-app for Jeti transmitters is made for gps-based training of RC glider slope racing competitions (F3F) and also distance and speed tasks for F3B.

All program releases in this 'V1'-repository are made to be compatible with generation 1 Jeti transmitters (with monochrome display). Please consider the requirements for those transmitters mentioned in the [**F3F-Tool manual**](docs/F3F-Tool%20Manual.md), so only use the binary form of the program (.lc) and do not use other lua-apps at the same time.

## Program Installation
For installation of a stable release please download the zip-file and the corresponding manual of the newest release from the [**releases-page**](https://github.com/frank-sc/F3F-Tool-V1/releases), download of the 'source code' packages is not necessary. Copy all files and directories into your 'apps' directory on the transmitter, as described in the manual. Then please follow the further steps in the manual.<br>
**Important: Please use newest Jeti Firmware (currently 5.06 LUA). Older Firmware Versions may cause problems!**

For installation of the current development version (HEAD) please refer to the [**wiki**](https://github.com/frank-sc/F3F-Tool-V1/wiki)

## Status
The tool in Version 1.4 is working quite well on the slope for F3F. For F3B-tasks there are some issues, especially with the very hight speed reached in the speed-task and with slightly inaccurate determination of the course bearing. See more detailed description in [**issues**](https://github.com/frank-sc/F3F-Tool-V1/issues).

## News in V 1.41
- none up to now, just prepared

## Development notices
The main program file 'f3f_\<version\> and the working directory 'f3fTool-\<version\> are always renamed for a new upcoming version. This is to make sure that everything fits together and to allow several versions to run independently on one transmitter.

## Installation of GPS-sensor
Information about choosing a GPS-sensor and the Installation in the glider can be found in the [**wiki**](https://github.com/frank-sc/F3F-Tool-V1/wiki)

## Project Support
If you like the tool you can support my work on the the project by making a donation, i appreciate :)<br><br>
[![Donate](https://www.paypalobjects.com/en_US/i/btn/btn_donateCC_LG.gif)](https://www.PayPal.Me/f3frank)<br>

### thanks to
- all donaters, who appreciate my work and help me getting new hardware for testing
- Axel Barnitzke for giving me an idea how to work kind of object-oriented in LUA
- Dave McQueeney for sharing his great Sensor Emulator for Jeti Studio, which allowed me to do a lot of testing on the PC,
and also for bringing up the idea of unloading and reloading parts of code to meet the memory limitations
