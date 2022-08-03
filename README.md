
# Opposing Force NightVision
Version 1.5

Author: Neo, Outerbeast									                

This script enables the Opposing Force style NightVision view mode, which can used with standard flash light key. It is dependant on the cvar mp_flashlight.
This can be added for a map or as a server plugin.

## Map script install instructions:                                         

* 1. Copy the file `nvision.as` to `scripts/maps/opfor'` to your map pack.
* 2. Add to main map script (if you don't have one, make one) the following code:
                          
(a) `#include "opfor/nvision"`                                           
                                                                        
(b) in function `MapInit()`:                                            
    `NightVision::Enable();`

The code should look like this:
```
#include "opfor/nvision"

void MapInit()
{
    NightVision::Enable();
}
```
* 3. Save this file, name it, put this file in `scripts/maps` in your map pack, then go to your map cfg and add this script to your `map_script` cvar.

## Server plugin installation instructions:
* Download and extract the contents into `svencoop_addon/scripts`
* Add this to your `default_plugins.txt` file then save:
```
	"plugin"
	{
		"name" "NightVision"
		"script" "NightVision"
	}
 ```

## Customisation
To change color put your rgb values in like this:                   
`NightVision::Enable( Vector(0,255,0) )`                       

## Usage:
Simply use standard flash light key to switch the OF NightVision view mode on and off.
You can use the condole command `nvision_mode` to switch between night vision and normal flashlight.                       
