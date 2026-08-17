# VR: Improvements Mod / VR+ (VR Plus)

A comprehensive quality-of-life and enhancement mod for PAYDAY 2 VR that significantly improves the VR experience with better controls, comfort options, HUD improvements, and gameplay tweaks.

[![Playing modded PAYDAY 2 VR on the Proving Grounds](https://img.youtube.com/vi/Yz9BA0Oj0bk/0.jpg)](https://youtu.be/Yz9BA0Oj0bk)

## Features & Settings

All settings accessible in-game via **Options → Mod Options → VR Improvements / VRPlus**. The sections below mirror the in-game menu layout and order.

<details>
<summary><b>UI Options</b></summary>

Configure User Interface settings.

- **Wristwatch Health Display**: Move your health indicator to your wristwatch (requires restart)
- **Belt-mounted microphone**: Add a microphone to the top left of your belt, with which you can use voicechat
- **Extra Heist Info on the Main Tablet**: Show pagers used, body bags, alerted guards and loot tracking on the main tablet page

</details>

<details>
<summary><b>Comfort Options</b></summary>

Options to increase physical comfort, by reducing motion sickness and remapping controls.

- **Enable speed cap**: Enable movement speed cap
- **Movement speed cap**: The maximum speed you will be able to walk/run at
- **Interaction Input**: Which button should be used for interacting with objects (Grip Button, Either Grip or Trigger, Trigger Button)
- **Lock Interactions**: Press to interact, press to cancel interaction
- **Artificial Crouching**: Use your non-weapon hand menu/Y button to control crouching (Disabled, Toggle, Hold)
- **Artificial Crouching Scale**: What percentage of your normal height you are when in crouch mode

</details>

<details>
<summary><b>Button Mappings</b></summary>

Customize button assignments for your controller.

- **Jump**: Button for jumping (requires locomotion enabled)
- **Crouch**: Button for crouching
- **Pause**: Button for pause menu
- **Gadget Toggle**: Button to toggle weapon gadget/laser
- **Fire Mode**: Button to switch weapon fire mode

Available buttons include A, B, X, Y, Menu, D-Pad directions, and Touchpad directions/center/menu for both the offhand and dominant hand.

<details>
<summary><b>Advanced Controls Manager</b></summary>

Advanced controller mapping (Use Button Mappings above for simple remapping).

> **WARNING**: The 'Button Mappings' settings take priority for Jump, Crouch, Pause, Gadget and Fire Mode. This is the advanced/legacy manager.

</details>

</details>

<details>
<summary><b>Motion Controller Options</b></summary>

Configure the inputs for your motion controllers.

- **Controller Type**: Select your VR controller type (Auto-Detect, HTC Vive, Oculus Touch / Quest, Valve Index Knuckles, Steam Frame). Change this if jump/crouch buttons don't work correctly.
- **Turning mode**: Use the thumbstick/trackpad on your weapon hand to rotate your view
  - Disable turning, keep default reload/gadget
  - Smooth view rotation
  - Snap view rotation
- **Sprint timer**: The amount of time the sprint button must be held to make the player sprint, rather than jump
- **Sprinting**: What method of using the thumbstick/trackpad click button should be used for sprinting
  - Disable Sprinting
  - Long-click to toggle sprinting
  - Hold-click to sprint
- **Teleport on untouch**: Teleport when the player un-touches their thumbstick/trackpad, rather than clicking it
- **Controller-Relative Movement**: Move relative to the direction of the active motion controller, not the HMD
- **Snap Rotation Delay**: The delay in seconds between snap rotations (0.05s – 1.00s)
- **Deadzone**: Percentage of the thumbstick/trackpad below which movement will be ignored
- **Snap Rotation Amount**: The amount in degrees to rotate when using snap rotation (15° – 90°)
- **Enable Locomotion**: Use thumbstick/trackpad motion to walk around, rather than warping/teleporting
- **Apply movement smoothing**: Apply a smoothing factor to make movement easier
- **Smooth Rotation Speed**: Rotation speed for smooth turning mode (60°/s – 360°/s at full stick)

</details>

<details>
<summary><b>Camera Options</b></summary>

Configure camera behaviour.

- **Fade distance (0 to disable)**: The distance from an obstacle at which the view begins to fade to black (set to 0 to disable)
- **Camera reset percentage**: The percentage that the screen has faded to black before the user will be teleported out of the wall
- **Camera reset timer**: How long (in seconds) after the reset percentage has been reached will the user be teleported out of the wall
- **Enable Redout**: When your health gets below a set threshold, the screen starts to turn red
- **Redout %HP Start**: The percentage of your health at which the screen begins to turn red
- **Redout Max Fade**: The maximum percentage of opacity for the redout effect

</details>

<details>
<summary><b>Change VR headset / Reset Options</b></summary>

- **Change VR headset / Reset Options**: Reset options for this mod back to the default values

</details>

<details>
<summary><b>Tweaks</b></summary>

Random, unimportant options.

- **Laser hue**: The hue of the laser in the main menu
- **Laser Disco**: Constantly make the laser fade through all possible hues, at the speed specified above
- **Endscreen Speedup**: Speed multiplier for the end-heist screen (same effect as holding space)
- **Force graphics quality**: Force-set the desktop window resolution
- **Graphics Quality**: The desktop window resolution, not visible when wearing a headset (HMD)
- **Weapon-hand Melee**: Use your weapon hand as a melee weapon (Yes (vanilla default), Only in Loud not in Stealth, No)

</details>


## Credits

**Version 0.6.6 onward:**
- **Jos Badpak** - Continued coding contributions and mod preservation
- **IssaStorm** - VR Wrist Panel+ | VR Improvements Mod Hud Addons
- **LordiAnders** - Bug fixing

**Versions 0.6.1–0.6.5R:**
- **Hugo Zink** - Continued coding contributions

**Original mod, up to version 0.6.1:**
- **ZNixian** - Coding
- **blinkVR** - Mod icon, helping find and replicate bugs
- **Sergio** - Russian translation

## Note from Maintainer

I mainly use an HTC Vive with this mod, so that's the headset I test against. I sometimes go long stretches without playing PAYDAY 2, so I'm not actively maintaining it on a regular schedule, but it's not abandoned either. I mostly fix things for myself and share those fixes here.

Since I can only test on a Vive, I can't personally verify that every fix works correctly on other headsets. Pull requests improving support for other headsets are very welcome, since I'm not able to test those issues myself.

## Support

- Report issues on [GitHub](https://github.com/DennisGHUA/payday2-vr-improvements/issues)
- Discuss on [ModWorkshop](https://modworkshop.net/mod/45143)

## License

See [LICENSE](LICENSE) file for details.

## Contributing

If you're a modder and want to contribute, feel free to open a pull request on the GitHub page. I actively check my GitHub, so if you have any fixes, improvements, or new features, you're welcome to submit them here:
[https://github.com/DennisGHUA/payday2-vr-improvements](https://github.com/DennisGHUA/payday2-vr-improvements)
