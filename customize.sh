#!/sbin/sh
##########################################################################################
#
# VulkanSystemRenderSwitcher - Magisk Module Installer Script
# Device: Universal (Snapdragon / MediaTek / Exynos)
# Author: Forked & Cleaned by User Aurified.Dev
# Original Author: @srmatdroid
#
##########################################################################################

SKIPMOUNT=false
PROPFILE=true
POSTFSDATA=true
LATESTARTSERVICE=true
SKIPUNZIP=0

##########################################################################################
# REPLACE LIST (None for now)
##########################################################################################

REPLACE="
"

##########################################################################################
# PRINT MODNAME (Installer Header)
##########################################################################################

print_modname() {
  ui_print " "
  ui_print "  ╔═══════════════════════════════════════════════════════════════╗"
  ui_print "  ║              VulkanSystemRenderSwitcher vAU1   stable         ║"
  ui_print "  ║          System UI Optimization for HyperOS / MIUI / AOSP     ║"
  ui_print "  ║                                                               ║"
  ui_print "  ║                       Device: Universal                       ║"
  ui_print "  ║                      Configured for: Snapdragon               ║"
  ui_print "  ║              (Configure post-fs-data for MTK/Exynos)          ║"
  ui_print "  ║                                                               ║"
  ui_print "  ║                     @Aurified.Dev  •  2026/GPLv3              ║"
  ui_print "  ╚═══════════════════════════════════════════════════════════════╝"
  ui_print " "
  ui_print "  ⚠️  IMPORTANT NOTE: "
  ui_print "     This module switches the ANDROID SYSTEM UI renderer between"
  ui_print "     OpenGL and Vulkan for minimal performance gain. It does NOT convert OpenGL games to Vulkan."
  ui_print "     Games must natively support Vulkan to benefit."
  ui_print " "
}

##########################################################################################
# Main Installation
##########################################################################################

on_install() {
  ui_print "  ┌───────────────────────────────────────────────────────────────┐"
  ui_print "  │                      📱 DEVICE INFO                           │"
  ui_print "  └───────────────────────────────────────────────────────────────┘"
  ui_print "  "
  ui_print "     • Model       : $(getprop ro.product.model 2>/dev/null || echo "Unknown")"
  ui_print "     • Brand       : $(getprop ro.product.brand 2>/dev/null || echo "Unknown")"
  ui_print "     • Android     : $(getprop ro.build.version.release 2>/dev/null || echo "Unknown")"
  ui_print "     • SDK         : $(getprop ro.build.version.sdk 2>/dev/null || echo "Unknown")"
  ui_print "     • Kernel      : $(uname -r 2>/dev/null || echo "Unknown")"
  ui_print "     • Architecture: $(getprop ro.product.cpu.abi 2>/dev/null || echo "Unknown")"
  
  # Detect GPU
  GPU=$(getprop ro.hardware.egl 2>/dev/null || echo "Unknown")
  ui_print "     • GPU         : $GPU"
  ui_print "  "
  
  ui_print "  ┌───────────────────────────────────────────────────────────────┐"
  ui_print "  │                      ⚙️  MODULE                               │"
  ui_print "  └───────────────────────────────────────────────────────────────┘"
  ui_print "  "
  ui_print "     ✅ Universal mode activated"
  ui_print "     ✅ Adaptive optimizations enabled"
  ui_print "  "
  
  ui_print "  ┌───────────────────────────────────────────────────────────────┐"
  ui_print "  │                      📦 INSTALLING                            │"
  ui_print "  └───────────────────────────────────────────────────────────────┘"
  ui_print "  "
  
  # Create directory structure
  ui_print "     • Creating directories..."
  mkdir -p $MODPATH/system/bin
  mkdir -p $MODPATH
  
  # Extract files
  ui_print "     • Extracting module files..."
  unzip -o "$ZIPFILE" '*' -d $MODPATH >&2
  
  # Verify extracted files
  if [ -f "$MODPATH/post-fs-data.sh" ]; then
    ui_print "     ✅ post-fs-data.sh installed"
    chmod 755 $MODPATH/post-fs-data.sh
  else
    ui_print "     ❌ ERROR: post-fs-data.sh not found"
    abort "     ❌ Installation failed - Missing file"
  fi
  
  if [ -f "$MODPATH/service.sh" ]; then
    ui_print "     ✅ service.sh installed"
    chmod 755 $MODPATH/service.sh
  else
    ui_print "     ❌ ERROR: service.sh not found"
    abort "     ❌ Installation failed - Missing file"
  fi
  
  # Verify and create system.prop if it doesn't exist
  if [ ! -f "$MODPATH/system.prop" ]; then
    ui_print "     • Creating default system.prop..."
    echo "# VulkanSystemRenderSwitcher - System Properties" > $MODPATH/system.prop
    echo "ro.vulkansystem.version=v2" >> $MODPATH/system.prop
    echo "ro.vulkansystem.universal=true" >> $MODPATH/system.prop
  fi
  
  ui_print "     ✅ Permissions configured correctly"
  ui_print "  "
  
  ui_print "  ┌───────────────────────────────────────────────────────────────┐"
  ui_print "  │                      🎮 CONFIGURATION                         │"
  ui_print "  └───────────────────────────────────────────────────────────────┘"
  ui_print "  "
  ui_print "     • Compatibility  : Universal (Snapdragon/MTK/Exynos)"
  ui_print "     • Note           : For MTK/Exynos, configure post-fs-data.sh"
  ui_print "  "
  
  ui_print "  ┌───────────────────────────────────────────────────────────────┐"
  ui_print "  │                      ✅ INSTALLATION COMPLETE                 │"
  ui_print "  └───────────────────────────────────────────────────────────────┘"
  ui_print "  "
  ui_print "     📌 Installed files:"
  ui_print "        • /data/adb/modules/vulkan.system/post-fs-data.sh"
  ui_print "        • /data/adb/modules/vulkan.system/service.sh"
  ui_print "        • /data/adb/modules/vulkan.system/system.prop"
  ui_print "  "
  ui_print "     📌 To verify functionality:"
  ui_print "        • Termux: watch -n 1 getprop debug.hwui.renderer"
  ui_print "        • Logs: logcat -s VULKAN_ENGINE"
  ui_print "  "
  ui_print "     ⚠️  Reboot your device to apply changes"
  ui_print "  "
}

##########################################################################################
# SET PERMISSIONS
##########################################################################################

set_permissions() {
  ui_print "  ┌───────────────────────────────────────────────────────────────┐"
  ui_print "  │                      🔒 PERMISSIONS                           │"
  ui_print "  └───────────────────────────────────────────────────────────────┘"
  ui_print "  "
  
  set_perm_recursive "$MODPATH" root root 0755 0644
  # Executable scripts
  set_perm "$MODPATH/post-fs-data.sh" root root 0755
  set_perm "$MODPATH/service.sh" root root 0755
  
  # Permissions for system.prop (system properties)
  #set_perm $MODPATH/system.prop 0 0 0644
  
  ui_print "     ✅ Permissions applied correctly"
  ui_print "  "
}

##########################################################################################
# POST INSTALL (Final Message)
##########################################################################################

post_install() {
  ui_print "  ╔═══════════════════════════════════════════════════════════════╗"
  ui_print "  ║                        🎉 SUCCESS! 🎉                         ║"
  ui_print "  ║                                                               ║"
  ui_print "  ║     VulkanSystemRenderSwitcher vAU1 installed successfully    ║"
  ui_print "  ║                                                               ║"
  ui_print "  ║    🔄 Reboot your device to activate the module               ║"
  ui_print "  ║                                                               ║"
  ui_print "  ║    📱 Developed by @srmatdroid (Cleaned by User Aurified.Dev) ║"
  ui_print "  ║    🎮 Compatible with Snapdragon | MediaTek | Exynos          ║"
  ui_print "  ║                                                               ║"
  ui_print "  ╚═══════════════════════════════════════════════════════════════╝"
  ui_print " "
}

# Run installation and final message
on_install
post_install
