# Changelog

## V0.8.8
- Fixed: Restored compatibility with the "Crouch Sliding - VR & Non-VR Compatible" mod (https://modworkshop.net/mod/47919).
- Fixed: Advanced Controller Mappings menu sometimes not opening in VR
- Fixed: Smooth turning accelerating the longer the stick is held.

## V0.8.7
- Fixed: Toggle sprint (Long-click to toggle) could not be toggled off, a second long-click now stops sprinting.
- Fixed: Toggle sprint (Long-click to toggle) now also works on the HTC Vive.

## V0.8.6
- Fixed: Weapon now rotates instantly with snap turning (previously had a delay).

## V0.8.5
- Fixed: Vanilla sprinting with the vanilla "Dash + Direct" setting when "Enable Locomotion" is off in the mod settings
- Fixed: The "Sprinting" setting now applies properly in Dash+Direct too, hold to sprint and toggle sprint both keep their behavior, and "Off / Vanilla" leaves default vanilla logic untouched.
- Added: The Jump button (Button Mappings / Advanced Controls Manager) now works for vanilla "Dash + Direct"
    Note: Jump speed isn't always accurate when combined with vanilla locomotion and sprint.
- Added: New "Enable Jump Button" toggle under Motion Controller Options (on by default).
    Note: Jump button is always disabled when the vanilla movement setting is Dash, and mod locomotion is off.
- Renamed: "Disable Sprinting" is renamed to "Off / Vanilla" functionality is the same.
- Renamed: "Enable Locomotion" is renamed to "Only Locomotion (Direct, no Dash)" functionality is the same.

## V0.8.4
- Fixed: The small flicker when stopping moving using the VR elements lag fix should be gone now in locomotion mode.

## V0.8.3
- Added: Fixed a vanilla issue causing all player-relative VR elements to lag behind during movement (https://youtu.be/2ngw1aKqLPM)

## V0.8.2
- Added: `jump` and `duck` (crouch) can now be bound in the Advanced Controls Manager.
- Added: Button Mappings now includes Trigger Click on the offhand as a input option.
- Fixed: The B, X and Y options in Button Mappings now bind the face button they name.
- Fixed: The Pause option now binds the pause menu, on button controllers and Vive wands alike.
- Fixed: Pause now sits on one hand instead of firing from both upper buttons.
- Fixed: Jump now uses the button it is mapped to.
- Changed: Renamed "D-Pad Up" and the other directional options to "Stick / Touchpad / D-Pad Up (Both Hands)".
- Changed: New settings files default to HMD-relative locomotion.

## V0.8.1
- Changed: Button Mappings now opens a picker with the full list when you click a mapping, instead of cycling through the options one by one
- Changed: Button Mappings now offers every stick/touchpad direction for both the offhand and the dominant hand
- Changed: Advanced Controls Manager rebindings take priority over the Button Mappings menu
- Changed: The settings file now records the mod version it was saved with, so later updates can correct older settings
- Fixed: Stick/touchpad locomotion being broken on every controller except HTC Vive.
- Fixed: Gadget and fire mode sitting on the same stick directions as view turning.
  - Both are back on up/down of the dominant hand. Configs still on the 0.8.0 defaults are moved over on load.
- Fixed: Advanced Controls Manager rebindings being ignored on every controller except the Vive
- Fixed: Headsets reporting as "Meta" falling back to the generic layout instead of being detected as Oculus Touch/Quest
- Fixed: Crouch being bound a second time on button-based controllers

**Note:** Steam Frame compatibility still needs testing. D-Pad might not work as intended.

## V0.8.0
- Added: "Extra Heist Info on the Main Tablet" HUD panel (default on; toggle in Options > Mod Options > VR Plus > UI Options)
  - Shows pagers used, body bags, guards with pagers, and unbagged/bagged/secured loot on the main tablet page
  - Based on "VR Wrist Panel+ / VR Improvements Mod Hud Addons" - credit to IssaStorm (https://modworkshop.net/mod/56553)
    - Fixed a crash introduced in update 247; bag counts should now be accurate.
- Added: Customizable button mappings (new "Button Mappings" menu)
  - Jump: Default B button
  - Crouch: Default A button
  - Pause: Default Y button
  - Gadget Toggle: Default D-Pad Right
  - Fire Mode Switch: Default D-Pad Left
  - All actions can be remapped to A/B/X/Y/Menu/D-Pad Up/Down/Left/Right
  - Expanded support for Oculus Touch/Quest, Valve Index Knuckles, Steam Frame, HTC Vive
- Added: Vive wand remapping options to the Button Mappings menu
  - New options: Touchpad Up/Down/Left/Right/Center and Menu, each for "Offhand" or "Dominant Hand"
  - Vive defaults match the 0.7.3 layout: Jump = Touchpad Center (Dominant Hand), Crouch = Menu (Offhand),
    Pause = Menu (Dominant Hand), Gadget = Touchpad Up (Dominant Hand), Fire Mode = Touchpad Down (Dominant Hand)
- Added: "Controller Type" setting in Motion Controller Options menu
  - Settings: Auto-Detect, HTC Vive, Oculus Touch/Quest, Valve Index Knuckles, Steam Frame
- Fixed: Crouch state resetting when grabbing bag
- Fixed: Controls Manager now saves correctly
- Fixed: Button-based controllers can now jump when using locomotion mode
- Fixed: Crouch button now properly works for button-based controllers
- Fixed: Vive touchpad no longer has conflicting jump+sprint mappings on same button
- Fixed: Switching the Sprint Mode setting to "Off" no longer crashes the game
- Fixed: Mod settings menu not showing up when the config file is empty or corrupt
- Changed: Unknown/generic headsets now default to Touch controller layout (A/B buttons) instead of Vive

**Note:** I develop and test on an original HTC Vive. Other headsets/controllers (Oculus Touch/Quest, Valve Index Knuckles, Steam Frame, etc.) are supported based on best-effort mapping, but they have not been personally tested.

## V0.7.3
- Added: Setting to customize snap rotation delay
- Added: Setting to customize snap rotation amount
- Added: Setting to customize smooth rotation speed
- Fixed: Laser chronometer (Espionage DLC) no longer holsters instead of firing when triggered. Credit to Shoshana for the fix.

## V0.7.2
- Fixed a crash that occurred when transitioning to bleedout state while crouching

## V0.7.1
- Fixed an issue where player movement speed would remain slow after uncrouching in VR
- Fixed an issue where player movement speed would remain slow after taking fall damage

## V0.7.0
- Added automatic updates starting from this version you no longer need to manually update the mod
- Added experimental Valve Index support
- Changed belt radio to "microphone" to better reflect its functionality
- Changed microphone icon to be turned off by default since voice chat has been disabled since update 239
- Changed jump button location to the center of the trackpad on the dominant hand when locomotion is enabled
- Changed jump and sprint logic so you can now sprint with one controller and jump with the other simultaneously
- Simplified sprint settings by removing "Hold-click to sprint, click inside the deadzone to jump" option
- Changed VR fade so it can now be lowered all the way down to 0
- Changed VR fade to be set to 0 by default to prevent it from being triggered too easily
- Updated various text strings for improved clarity

## V0.6.8
- Resolved issue causing a permanent red screen effect after entering custody.
- Disabled the red screen effect when the player is downed.
- Updated belt radio icon to a microphone for clearer distinction.

## V0.6.7
These issues only apply when using the 'Wristwatch Health Display' option in the UI Options:
- Fix crash when going into custody after using an ability.
- Fix ability icon turning into just a white square.

## V0.6.6
- Lowered delay for turning from 0.25 to 0.15
- Increased rotation amount from 30 to 45

## V0.6.5.R
- Fixed another potential arm movements crash with akimbos

## V0.6.4.R
- Added extra wrist tablet page for quick voice commands

## V0.6.3.R
- Fixed clients crashing on load, related to VR arm movements

## V0.6.2.R
- Fixed custom movement control not working
- Fixed bottom A/X button on Oculus Touch not being rebindable
- Removed bottom A/X button snap turning on Oculus Touch

## V0.6.1
- Fix the game crashing as soon as a level is loaded if no custom controls are set

## V0.6.0
- Add the control customisation system

## V0.5.5
- Fix belt constantly resetting to default when the radio is enabled in PD2 version U180 and later

## V0.5.4
- Fix crash on startup when used with the new WSOCK32.dll-based hook

## V0.5.3
- Fix crash on radio use when no other mods use XAudio - Fixes #98

## V0.5.2
- Add belt-mounted push-to-talk radio - Implements #95

## V0.5.1
- Fix the bug preventing the player from accessing their tablet - Fixes #96

## V0.5.0
- Initial compatibility with the non-beta version of PAYDAY 2 VR
- Fixes the crash bug when loading a heist with trigger-based interaction enabled
- Don't remove the DLL update when used with SuperBLT

## V0.4.8
- Fix crash bug triggeded by teleporting up ladders with mod locomotion disabled - Fixes #94

## V0.4.7
- If you fire a bullet on the same frame as being tased, your guns break - weapons on automatic mode will fire
at the maximum possible ROF of once per frame, and semiautomatic weapons will not fire at all - Fixes #87. Many thanks
to [Kane](http://steamcommunity.com/app/218620/discussions/30/1693785669845446430/) for providing an invaluable analysis
of this problem.

## V0.4.6
- Add hand meele enable/loud only/disable option
- Improve name and description for force-desktop-resolution option

## V0.4.5
- Fix #90

## V0.4.4
- Fix double-update error, making it impossible to hold your weapon with your off hand when toggle-grabbing was enabled, see #89
- Same change as above also fixes #88, which was bags making a ghost copy when picked from your inventory

## V0.4.3
- Disable slowmotion effects, hopefully fixing #87

## V0.4.2
- Remove lag removal now included in the base game, fixes #82 and #85

## V0.4.1
- Add teleport-on-untouch support - Implements #77

## V0.4.0
- Add force quality setting, for use on slower computers - Implements #81

## V0.3.9
- Fix crash when starting heist with mod locomotion disabled - Fixes #78
- Fix gadget always toggling from the right-hand side, when the player is
in left-handed mode - Fixes #76
- Fix toggle crouch button also jumping the player - Fixes #79

## V0.3.8
- Fix hand inputs not working while interacting with belt
- Add crouch button - Implements #75
- Prevent hold-to-sprint from toggling off

## V0.3.7
- Fix messiah skill not activating while jumping (Thanks, Kevin Stich)
- Add zeadzone-based sprinting/jumping option - Implements #70
- Add movement smoothing, same as that in the base game - Implements #69

## V0.3.6
- Temporaraly remove camera fade options, fixing PD2VR 1.4 crash
- Fix menu laser dot colour not matching beam colour

## V0.3.5
- Fix weapon-assist toggling - Fixes #58

## V0.3.4
- Fix movement for left-handed users

## V0.3.3
- Fix jumping in PD2VRBeta update 1.3 - Fixes #57

## V0.3.2
- Update Russian translation
- Updates for VR Beta 1.3
  - Fixed crash-on-startup
  - Disable weapon-grip-toggle as it's in the base game
  - Note snap turning is not removed, as the builtin one doesn't seem to work.

## V0.3.1
- Add endscreen speedup option - Implements #40

## V0.3.0
- Fix menu options having no effect after resetting them - Fixes #50
- Fix player slowing down while quickly moving the HMD - Fixes #51

## V0.2.9
- Set default options depending on which HMD is used

## v0.2.8
- Fix fade-to-black problem - Fixes #45

## V0.2.7
- Allow player rotation while in casing mode - Fixes #44
- Fix issues with rotation jumping the player's view the first time they use it per heist.

## V0.2.6
- Add ladder support - Fixes #42

## V0.2.5
- Fix taser crash bug

## V0.2.4
- Update Russian translations (Thanks, Sergio)
- Fix weapons lagging behind their respective hand position/rotations - Fixes #38

## V0.2.3
- Add toggle weapon grip option
- Show warning when using IPHLPAPI.dll 2.0VR5 (crash-on-startup when used in VR)

## V0.2.2
- Add Korean translation (Thanks, DreadNought_40k)
- Add Spanish translation (Thanks, Souls Alive)

## V0.2.1
- Add main-menu laser pointer customization
- Update Russian translations (Thanks, Sergio)

## V0.2.0
- Add option to rebind interact control
- Add sticky-interact option

## V0.1.9.2
- Allow users to jump while in hold-to-sprint mode - Fixes #30

## V0.1.9.1
- Add Russian translations for v0.1.9.0

## V0.1.9.0
- Add HP-on-watch option (enabled by default) - Implements #16

## V0.1.8.1
- Update Russian translations for V0.1.8.0 (Thanks, Sergio)

## V0.1.8.0
- Fix player hands lagging behing camera while moving - Issue #23
- Add movement speed cap in comfort options

## V0.1.7.0:
- Add Russian translations (Thanks, Sergio)

## V0.1.6.3:
- Remove BLT hook DLL from automatic updates
- Warn user if the mod's filename is incorrect and will cause issues while updating

## V0.1.6.2:
- Fix crash on startup caused by v0.1.6.1 and extremely inadequate testing on my part
- Note this version's mod.txt says v0.1.6.1 - I forgot to update it

## V0.1.6.1:
- Add redout effect (disabled by default), fading screen to red as your health runs low - See #21

## V0.1.6:
- Add option to disable locomotion
- Warn the user if an outdated IPHLPAPI.dll is found

## V0.1.5.3:
- Add mod icon

## V0.1.5.2:
- Split camera and control options into two different menus

## V0.1.5.1:
- Fix crash when jumping while downed - See #18

## V0.1.5:
- Adds automatic updates

## V0.1.4:
- Implement controller-relative (Onward-like) movement: #8
- Fix major movement bug: #9
- Add thumbstick/trackpad-based rotation (smooth and snapping)

## V0.1.3:
- Add jumping support.
- Fix issue #4 preventing users from moving while in casing mode (not masked up).
- Adds configuration options for what the camera does when you put your head into a wall, along with defaults far better suited to locomotion movement.

## V0.1.2:
- Add deadzone slider (mainly for Vive users)

## V0.1.1:
- Add sticky sprinting checkbox (default on)

## V0.1.0:
- Initial Release

