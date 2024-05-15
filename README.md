**This mod is also available on the mod workshop:**  
https://modworkshop.net/mod/45143
  
This version is a continuation of the following repositories:  
Version 0.6.1 (2018)  
https://gitlab.com/znixian/payday2-vr-improvements  
Version 0.6.5R (2020)  
https://gitlab.com/HugoZink/payday2-vr-improvements  
  
# PAYDAY 2 VR: Improvements Mod
The PD2VR Improvements mod (referred to as VRPlus in code, in case you run across that) is a mod for the VR Beta of PAYDAY 2, adding many quality-of-life fixes such as smooth locomotion, moving you're health wheel to you're wristwatch (as per the trailer), and snap-turning support, and fading the screen to red while on very low health.

Most of these changes are disabled by default, and must be enabled in the mod settings. See below for a list of the settings, and what they do.

## Reporting bugs / Requesting features
The GitHub [issue tracker](https://github.com/DennisGHUA/payday2-vr-improvements/issues) is the primary way to keep track of problems and suggestions for this project.

Please do not hesitate to post your issue (be it a bug report, or any kind of suggestion) on here. Preferrably look at the list of issues to see if any clearly match yours, but I don't have any problem with the occasional duplicate issue.

If this is a crash bug, please pastebin your `crash.txt` file and include a link to it.

## Automatic Updates
As of this moment the mod does not support automatic updates. You can press the watch button on github top right and select Custom->Releases or follow the mod the [modworkshop](https://modworkshop.net/mod/45143).

## Old Steam Group
This mod has had an [Abandoned Steam group](https://steamcommunity.com/groups/payday-2-vr-mod/). But this no longer seems relevant. Use the github issue tracker or the modworkshop page for discussing.

## Changelog
See [CHANGELOG.md](https://github.com/DennisGHUA/payday2-vr-improvements/blob/master/CHANGELOG.md).

## Credits
Original mod up to version 0.6.1:
- ZNixian - Coding
- blinkVR - Mod icon, helping find and replicate bugs
- Sergio - Russian translation

Onwards from 0.6.1 up to version 0.6.5R:
- Hugo Zink - Continued coding contributions

From version 0.6.6 onward:
- LordiAnders - Bug fixing
- Jos Badpak - Bug fixing, minor adjustments, and mod preservation

## License
See [LICENSE](https://github.com/DennisGHUA/payday2-vr-improvements/blob/master/LICENSE).


## Options
This mod is extensively customizable, and by changing you're settings you'll get the most out of this mod. To open you're settings, open the game and click Options->Mod Options->VR Improvements. From there, you can customize the various aspects of the mod.

Almost all of these options can be changed while playing and will take effect instantly - no need to restart PAYDAY or restart the heist (for those not aware of it, starting, restarting or stopping a heist will almost always have the same effect as restarting PAYDAY 2 - you can install a mod and then restart the heist to have it take effect, without restarting PAYDAY 2, or disable a mod while on the main menu and this takes effect when you next start a heist).

## UI Options
Therese settings are about the ingame user-interface.

### Wristwatch Health Display
This moves you're health wheel to you're wristwatch, as seen in the trailer or seen [here](https://i.imgur.com/A9AmoKo.jpg). This does remove it, not duplicate it, but I'm looking into fixing that.

Changes to this option will not take effect until a new heist starts.

Default: Enabled

## Comfort Options
For those affected by simulator sickness, smooth locomotion is usually worse than teleporting in this regard. These options help try to mitigate this.

Also, they can adjust some controls that some Vive users may find painful over time.

### Speed Cap
Enabling this will artifically limit the player's walking and running speeds, to an adjustable amount.

Default: Disabled

### Interaction Input
This allows you to select, when using an empty hand, which buttons on the motion controller can be used to interract with
items (pick locks, start drills, answer pagers, etc). For Vive users who find their grip button uncomfortable, this may
be extremely useful.

It allows you to either select the Grip button, Trigger button or both as possible inputs.

Default: `Either Grip or Trigger`. Vanilla: `Grip Button`.

### Lock Interactions
Once you start interacting with something (same as above - locks, drills, pagers, etc) you can release the
button you used to start interacting with it, and the interacton will continue.

You can interrupt an interaction by pressing the interact input a second time.

Default: Disabled

## Motion Controller Options
These options adjust how input is taken from the motion controllers

### Enable Locomotion
Enabling this uses trackpad/thumbstick locomotion to move around in-game, while disabling it uses the vanilla warp/teleport system.

When this is enabled, the controls are as follows: The hand you'd normally teleport with is changed to moving you around using the thumbstick/trackpad. Briefly clicking the trackpad/thumbstick will cause you to jump, holding down for longer will make you start running.

Default: Enabled

### Turning Mode
This can be used to switch between no turning, smooth turning, and snap turning. When it is enabled, you're firemode and gadget buttons will be remapped to up and down, respectively, on you're weapon-side thumbstick, and left-right will rotate your view.

Note this works regardless of 'Enable Locomotion'.

Default: Disabled

### Sticky Sprinting
When this is enabled, you only need to hold down on your trackpad/thumbstick to start running, then you can let go. When this is disabled, you have to hold your thumbstick down to continue sprinting.

Note that as of v0.1.9.0, jumping is broken when this is disabled - see #30. Should now be fixed in v0.7.0

Default: Enabled

### Controller-Relative Movement
When this is enabled, you move in the direction you're pointing with the hand whoose thumbstick/trackpad you're using to move around. When this is disabled, you move in the direction you're looking.

As an example, if you're looking forwards and are holding your hand out towards something off to your side. When this is enabled, moving the thumbstick/trackpad forwards will move you in the direction of what you're pointing at, while when disabled you will move in the direction you're looking.

Default: Enabled

### Deadzone
In percent, how much of the trackpad between the center and the edge is considered a deadzone - you will not move while your thumb/thumbstick is in that zone.

Default: `10`%

### Sprint Timer
How long, in seconds, you have to hold down the thumbstick/trackpad to start sprinting, as opposed to jumping.

If you find you're unable to jump, ensure you did not set this to some very low value.

Default: `0.25` Seconds

## Camera Options
This controls options for how the camera is handled in VR

### Fade options:
When you put your head into (or close to) a wall in VR, your screen will fade to black. Once it has reached a certain percentage of blackness (vanilla: 95%), it starts a timer to teleport you out after an amount of time (vanilla: 1.5 seconds).

Fade Distance: The minimum distance from an object you must be before you're screen will start fading. Vanilla: `13`. Default: `2`.

Camera Reset Percentage: The percentage blackness that your screen must fade to for the teleport-out timer to start. Vanilla: `95`%. Default: `95`%.

Camera Reset Timer: The time in seconds that must pass while you're screen is over the reset percentage black before you will be teleported out. Vanilla: `1.5` seconds. Default: `0.25` seconds.

### Redout options:
Redout is where, when running low on health, you're screen will be tinted red in proportion to how close to going down you are as an indicaton. I've never tried this in game, so if you think making it fade out (or have any other suggestions) after a time would be useful, please post a comment on the Steam group or (preferrably) open an issue on the issuetracker.

Redout %HP Start: When you're below this percentage of your health, your screen will begin it's fade to read.

Redout Max Fade: At zero health, what percentage opacity is the red tint?

## Tweaks
Random, misc options that probably aren't very important.

### Laser pointer options
The laser pointer options allow you to set the colour of the laser pointer in the main menu. The hue slider lets you adjust the
hue of the beam, and disco mode makes the pointer fade through the colours of the rainbow at a speed determined by the hue option.

Note that disco mode uses a logarithmic scale, so while setting the hue slider to 100% will do two rainbows per second, at 10% it will
only do two rainbows every 100 seconds (10%=0.1, 0.1^2=0.01, 1/0.01=100).

Default (hue): `33.3`%. Vanilla: `33.3`%
Default (disco): Disabled

