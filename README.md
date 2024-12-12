# Opposing Force NightVision
### Version 1.6
							                
This script brings the Opposing Force style NightVision view mode to your map, which can used with standard flash light key.

If you want a plugin version to use as a server addon, see [Nero's Custom NightVision Flashlight plugin](https://github.com/Neyami/Custom-Nightvision-Flashlight).

## Installation                                       

[Download](https://github.com/Outerbeast/NightVision/archive/refs/heads/main.zip) and extract into your map's dir/`svencoop_addon`.

To enable it in your map, either do:
                          
- `map_script opfor/nvision` in your map's cfg file

OR
- `#include "opfor/nvision"` in your map's main script header

OR
- Make a trigger_script entity in your map with the keyvalue `"m_iszScriptFile" "opfor/nvision"`

## Usage

Once you have the suit equipped (and `mp_flashlight` is set to `1`), simply use the standard flash light key to switch the OF NightVision view mode on and off.

You can use the console command `nvision_mode` to switch between night vision and normal flashlight.                       

## Customisation

The night vision colour is the standard green colour as featured in Opposing Force, but it is possible to customise the colour using the cvar `nvision_color` in the map cfg:
```as_command nvision_color 255 0 0```

### Mapping

You can use the entity `info_nvision` to allow you to change things like colour, on/off sounds, and position offset of the effect from within your map.
The entity can be triggered to toggle the nightvision on/off, and obeys use types.
Deleting the entity via `killtarget` will completely disable night vision for the remainder of the level.

When a player turns their night vision on/off, entities with the targetname `"nvision_trigger_on"`/`"nvision_trigger_off"` will be automatically be triggered.
Those entities will receive the player as `!activator`.

#### Keys
| Key | Value | Description |
| ----| :---: | -------- |
| `"nvmode"` | `"m"` | Starting mode for the night vision. Default is `0` (OFF) |
| `"rendercolor"` | `"r g b"` | Colour value |
| `"renderamt"` | `"a"` | Radius of nightvision effect between `1` - `255`. Default is `40` |
| `"view_ofs"` | `"x y z"` | Position offset of the night vision effect from player's origin. Zero by default |
| `"noise1"` | `"player/hud_nightvision.wav"` | Sound to play when night vision is turned on
| `"noise2"` | `"items/flashlight2.wav"` | Sound to play when night vision is turned off |
| `"target"` | `entity` | Target entity to trigger whenever this info_nvision is triggered. `!activator` is supported, target entity receives the same use type that the info_nvision was triggered with |

#### Flags
| Name | Value `"spawnflags" "f"` | Description |
| ----| :---: | -------- |
| Start off | `1` | Nightvision is turned off, entity needs to be triggered to turn on |
| Activator only | `2` | Night vision usability is only applied to the player who triggered the entity |
| Disable Console Command | `4` | Prevents the `nvision_mode` console command from being used |
| Don't Boost Illumination | `8` | Prevents changing the lightstyle of the world to boost illumination |

### Scripting
Preface: all functions/variables are in the `NightVision` namespace.

You can customise various things with the nightvision effect using this function in `MapInit()`:
```void Config(RGBA rgbaNVColourCustom, string strNVOnSndCustom = "player/hud_nightvision.wav", string strNVOffSndCustom = "items/flashlight2.wav")```

You can use preset RGBA values that are available as global constants in the SC AngelScript API: https://baso88.github.io/SC_AngelScript/docs/Properties.htm
