# VulkanSystemRendererSwitcher / `VSRS`
>**A fork of [HyperVulkan Switcher](https://www.magiskmodule.com/hypervulkan-switcher/) by [@srmatdroid](https://github.com/SrMatdroid)**
>
> *Made for Android Devices like the Retroid Pocket 5*

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
![Platform](https://img.shields.io/badge/Platform-Android%2013%2B-green.svg)
![Device](https://img.shields.io/badge/Device-Retroid%20Pocket%205-orange.svg)
![Status](https://img.shields.io/badge/Status-Stable-success.svg)

### 🚀 Summary of Transformation

#### `Took a risky, bloated, Spanish-language script, filled with false claims; and turned it into a safe, English language translated, focused utility that strictly manages the Android System UI renderer.`

**1. 🗑️ Removed Dangerous & Unnecessary Features
Stripped out everything that wasn't directly related to switching the System UI renderer to prevent crashes, bootloops, and security issues.**

| Feature Removed	| Why It Was Removed |
| :-------------- | :----------------- |
| VBMeta / Boot Integrity Spoofing |	High Risk. Fake hashes (ro.boot.vbmeta.digest) can trigger bootloops, break banking apps, and fail SafetyNet. |
| Blur Disabling	| Unrelated to Vulkan. Removing blur is a UI preference, not a rendering engine switch. |
| Audio Tweaks (Bose, HiFi, Fluence) | High Risk. Many of these broke Bluetooth or caused audio desync in social apps. |
| Network / TCP Optimizations |	Unrelated to graphics. Conflicts with and overwites other more purposeful connectivity changes. Can cause connectivity instability on some carriers. |
| Camera Optimizations |	Unrelated to rendering. Can cause camera crashes on non-Snapdragon devices. |
| Unity Scheduler Tweaks	| Too specific. Better handled by the OS or game-specific settings. |
| Spanish Language |	Translated all comments, logs, and UI messages to English for clarity. |

**2. 🛡️ Enhanced Security & Stability
Added safeguards to ensure the module doesn't break your device if something is missing.**

**Robust Driver Verification: Added a new check_vulkan_support() function that:**
- Verifies ro.hardware.vulkan is set to turnip.
- Checks if the actual .so driver file exists on the disk.
- Verifies the libvulkan.so symlink is present.
- Logs clear errors instead of silently failing if the driver is missing.
- Safe Property Setting: Ensured set_prop uses resetprop (Magisk) when available, falling back to setprop safely.
- Process Priority: Added renice to lower the script's CPU priority so it doesn't lag the system.

**3. 🎯 Clarified Functionality (The "Truth")
Corrected the misleading claims in the original module.**

**`Old Claim: "Forcibly switches OpenGL ES programs to use Vulkan."` - *(False)***

**`New Reality: "Switches the Android System UI renderer between OpenGL and Vulkan."`**

*Explanation: It changes how menus, status bars, and overlays render. It does not force a game's internal engine to switch APIs unless the game natively supports Vulkan.*

*Updated Descriptions: All module.prop and customize.sh text now accurately reflects this limitation.*

**4. 📝 Code Cleanup & Optimization**

- Translated Comments: All comments in customize.sh, post-fs-data.sh, and service.sh are now in English.
- Streamlined Logic: Removed redundant ui_print boxes and simplified the installation flow.
- Expanded the GAMES list to 70+ entries, including:
- `Top mobile titles (AM2R, Genshin, COD, PUBG, Roblox, etc.).`
- `Emulators: Eden, Eden Nightly, Kenji NX, x1Box, Azahar, Vita3k, Aethersx2, RetroArch, Citra, Yuzu, Skyline, PPSSPP, Dolphin, GameHub Lite, etc.`
- `Frontends: EmulationStation_DE`

**6. 🔄 Integration with Turnip Driver**

**The module is now designed to work seamlessly with [My Turnip Driver Module](https://github.com/Aurified-266/Mesa-Turnip_CI-CD_Linux-Debian):**

- It checks for the vulkan.turnip.so file specifically.
- It relies on the libvulkan.so symlink created by the Turnip module's customize.sh.
- It only activates Vulkan mode if the driver is confirmed to be present.
