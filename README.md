
# Opposing Force NightVision
Version 1.5

Author: Neo, Outerbeast									                

This map script enables the Opposing Force style NightVision             
view mode, which can used with standard flash light key. It is dependant on the cvar mp_flashlight                

## Map script install instructions:                                         

* 1. Extract the map script 'scripts/maps/nvision.as' to 'svencoop_addon/scripts/maps'.         
* 2. Add to main map script the following code:
                          
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
# Customisation

To change color put your rgb values in like this:                   
`NightVision::Enable( Vector(0,255,0) )`                       

Usage of OF NightVision:                                                 

Simply use standard flash light key to switch the OF NightVision view mode on and off.
You can use the condole command `nvision_mode` to switch between night vision and normal flashlight                        
