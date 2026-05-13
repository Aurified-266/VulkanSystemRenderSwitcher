#!/system/bin/sh
# Executes in late_start service (after boot)
MODDIR="${0%/*}"
#!/system/bin/sh
# ╔══════════════════════════════════════════════════════════════╗
# ║         VulkanSystemRenderSwitcher (vAU1 stable)              ║
# ║      Optimization Module for HyperOS / MIUI / AOSP          ║
# ║      Device: universal                                      ║
# ╚══════════════════════════════════════════════════════════════╝

# ================================================================
# INITIAL CONFIGURATION
# ================================================================

# Wait for system
sleep 15

# Global variables
LOG_TAG="VULKAN_ENGINE"
LOG_FILE="/data/local/tmp/vulkan_engine.log"
CURRENT_MODE="normal"
LAST_PACKAGE=""
FAIL_COUNT=0
DEBUG_MODE=false  # Change to true for detailed debugging

# ================================================================
# LOGGING FUNCTIONS
# ================================================================

log_msg() {
    local msg="$(date '+%Y-%m-%d %H:%M:%S') - $1"
    log -t "$LOG_TAG" "$msg"
    echo "$msg" >> "$LOG_FILE"
    
    # Log rotation (keep under 1MB)
    if [ -f "$LOG_FILE" ] && [ $(stat -c%s "$LOG_FILE" 2>/dev/null || echo 0) -gt 1048576 ]; then
        tail -n 500 "$LOG_FILE" > "${LOG_FILE}.tmp"
        mv "${LOG_FILE}.tmp" "$LOG_FILE"
        log_msg "Log rotated (size exceeded)"
    fi
}

debug_msg() {
    if [ "$DEBUG_MODE" = true ]; then
        log_msg "[DEBUG] $1"
    fi
}

# ================================================================
# SAFE SETPROP FUNCTION
# ================================================================

set_prop() {
    if command -v resetprop >/dev/null 2>&1; then
        resetprop "$1" "$2"
    else
        setprop "$1" "$2"
    fi
    debug_msg "set_prop: $1 = $2"
}

# ================================================================
# VERIFICATION OF VULKAN
# ================================================================

check_vulkan_support() {
    log_msg "Verifying Vulkan driver installation..."
    
    # 1. Check if the specific driver prop is set
    HW_VULKAN=$(getprop ro.hardware.vulkan)
    if [ "$HW_VULKAN" = "turnip" ]; then
        log_msg "✓ Driver prop 'ro.hardware.vulkan' is set to 'turnip'"
    else
        log_msg "⚠ WARNING: 'ro.hardware.vulkan' is '$HW_VULKAN' (expected 'turnip')"
        # Continue anyway, maybe they are using a different driver name
    fi

    # 2. Check if the actual driver file exists
    # Check common locations for the Turnip driver
    DRIVER_FOUND=false
    if [ -f "/vendor/lib64/hw/vulkan.turnip.so" ]; then
        log_msg "✓ Found driver: /vendor/lib64/hw/vulkan.turnip.so"
        DRIVER_FOUND=true
    elif [ -f "/vendor/lib64/hw/vulkan.adreno.so" ]; then
        log_msg "✓ Found driver: /vendor/lib64/hw/vulkan.adreno.so"
        DRIVER_FOUND=true
    elif [ -f "/system/vendor/lib64/hw/vulkan.turnip.so" ]; then
        log_msg "✓ Found driver: /system/vendor/lib64/hw/vulkan.turnip.so"
        DRIVER_FOUND=true
    fi

    if [ "$DRIVER_FOUND" = false ]; then
        log_msg "❌ CRITICAL ERROR: No Vulkan driver file found!"
        log_msg "   The module will attempt to switch to Vulkan, but it may fail."
        log_msg "   Please ensure the Turnip driver module is installed."
        return 1
    fi

    # 3. Check if libvulkan.so symlink exists
    if [ -L "/vendor/lib64/libvulkan.so" ]; then
        TARGET=$(readlink /vendor/lib64/libvulkan.so)
        log_msg "✓ Symlink verified: libvulkan.so -> $TARGET"
    else
        log_msg "⚠ WARNING: libvulkan.so symlink missing. Driver may not load."
    fi

    log_msg "✅ Vulkan environment appears ready."
    return 0
}

# ================================================================
# LIST OF SUPPORTED GAMES & EMULATORS
# ================================================================

GAMES="
gamehub.lite
org.es_de.frontend
com.netease.winds
com.aspyr.kotor
com.companyname.AM2RWrapper
dev.eden.eden_emulator
com.miHoYo.Yuanshen.nightly
org.kenjinx.android
xyz.aethersx2.android
org.citra_emu.citra
org.citra_emu.citra.canary
io.github.limelime3ds.lime3ds
io.github.lime3ds.lime3ds.canary
com.retroarch
com.swordfish.lemuroid
com.dolphin.emulator
com.dolphin.emulator.canary
org.dolphinemu.dolphinemu
org.ppsspp.ppsspp
com.ppsspp.ppsspp
com.ppsspp.ppsspp.canary
io.github.azaharplus.android
org.vita3k.emulator
com.izzy2lost.x1box
com.google.android.apps.stadia
com.xbox.gamepass
com.microsoft.xcloud
com.netflix.games
com.miHoYo.GenshinImpact
com.miHoYo.HonkaiStarRail
com.miHoYo.ys.oversea
com.miHoYo.bh3oversea
com.miHoYo.hkrpgoversea
com.netease.g108na
com.netease.hyxd
com.netease.onmyoji
com.netease.lztgglobal
com.netease.wzry
com.tencent.tmgp.sgame
com.tencent.tmgp.cf
com.tencent.tmgp.pubgmhd
com.tencent.tmgp.speedmobile
com.tencent.tmgp.wzry
com.tencent.ig
com.pubg.imobile
com.pubg.newstate
com.activision.callofduty.shooter
com.activision.callofduty.warzone
com.dts.freefiremax
com.dts.freefire
com.garena.game.kgvn
com.garena.game.kgtw
com.garena.game.kgid
com.garena.game.kgth
com.garena.game.kgsg
com.roblox.client
com.mojang.minecraftpe
com.ea.gp.fifamobile
com.ea.gp.nbamobile
com.ea.gp.apexlegendsmobilefps
com.rockstargames.gtasa
com.rockstargames.gtalcs
com.rockstargames.rdr
com.rockstargames.reddeadredemption2
com.bandainamcoent.dblegends_ww
com.bandainamcoent.dbzdokkanww
com.bandainamcoent.dragonballlegends
com.square_enix.android_googleplay.FFBEWW
com.square_enix.android_googleplay.DQW
com.bandainamcoent.dbzsparkingzero
com.bandainamcoent.dbzlegends
"

# ================================================================
# VULKAN MODE (MAX PERFORMANCE)
# ================================================================

set_vulkan_mode() {
    log_msg "🔧 Activating VULKAN MODE (Max Performance)"
    
    # Main Rendering
    set_prop debug.hwui.renderer skiavk
    set_prop ro.hwui.use_vulkan true
    set_prop debug.vulkan.frame.pacing 1
    
    # Pipeline & Cache Optimizations
    set_prop renderthread.skia.reduceopstasksplitting true
    set_prop debug.hwui.vulkan.use_pipeline_cache true
    set_prop debug.hwui.vulkan.enable_shared_image true
    set_prop debug.hwui.use_vulkan_texture_filtering true
    set_prop debug.hwui.fbpipeline true
    
    # Threads & Rendering
    set_prop debug.hwui.render_thread true
    set_prop debug.skia.threaded true
    set_prop debug.cpurend.disable 1
    
    # UI & Memory
    set_prop debug.hwui.use_gpu_pixel_buffers true
    set_prop debug.hwui.skip_empty_damage true
    set_prop debug.hwui.webview_overlays_enabled true
    set_prop sys.use_fifo_ui true
    
    # SurfaceFlinger Priority
    set_prop debug.renderengine.vulkan.disable_vblank_wait true
    
    # Adreno Specific
    set_prop debug.perf.vulkan.use_gpu_memcpy 1
    set_prop debug.perf.vulkan.enable_robustness 0
    set_prop vulkan.pipeline_cache.enabled true
    
    # Latency
    set_prop debug.vulkan.force_disable_validation_layers true
    
    # Thermal Anti-throttling
    set_prop debug.composition.type gpu
    set_prop persist.sys.composition.type gpu
    
    log_msg "✓ Vulkan mode activated successfully"
}

# ================================================================
# NORMAL MODE (BATTERY & STABILITY)
# ================================================================

set_normal_mode() {
    log_msg "🔄 Restoring NORMAL MODE (OpenGL - Battery)"
    
    # Restore to OpenGL
    set_prop debug.hwui.renderer skiagl
    set_prop ro.hwui.use_vulkan false
    set_prop debug.vulkan.frame.pacing 0
    
    # Disable forced Vulkan
    set_prop renderthread.skia.reduceopstasksplitting true
    set_prop debug.hwui.vulkan.use_pipeline_cache false
    set_prop debug.hwui.vulkan.enable_shared_image false
    set_prop debug.hwui.use_vulkan_texture_filtering false
    set_prop debug.hwui.fbpipeline false
    
    # Restore threads
    set_prop debug.hwui.render_thread false
    set_prop debug.skia.threaded false
    set_prop debug.cpurend.disable 0
    
    # Restore UI
    set_prop debug.hwui.use_gpu_pixel_buffers false
    set_prop debug.hwui.skip_empty_damage false
    set_prop debug.hwui.webview_overlays_enabled false
    set_prop sys.use_fifo_ui false
    
    # Restore SurfaceFlinger
    set_prop debug.renderengine.vulkan.disable_vblank_wait false
    
    # Restore Adreno
    set_prop debug.perf.vulkan.use_gpu_memcpy 0
    set_prop debug.perf.vulkan.enable_robustness 1
    set_prop vulkan.pipeline_cache.enabled false
    
    # Restore Composition
    set_prop debug.composition.type dyn
    set_prop persist.sys.composition.type dyn
    
    log_msg "✓ Normal mode restored successfully"
}

# ================================================================
# SCRIPT PRIORITY
# ================================================================

# Lower script priority to avoid CPU consumption
if command -v renice >/dev/null 2>&1; then
    renice -n 19 -p $$ 2>/dev/null
    debug_msg "Script priority reduced (nice 19)"
fi

# ================================================================
# INITIALIZATION
# ================================================================

log_msg "═══════════════════════════════════════════════════════════"
log_msg "🚀 VULKAN SYSTEM RENDER SWITCHER vAU1 STARTED"
log_msg "📱 Device: $(getprop ro.product.model 2>/dev/null || echo "Unknown")"
log_msg "🤖 Android: $(getprop ro.build.version.release 2>/dev/null || echo "Unknown")"
log_msg "═══════════════════════════════════════════════════════════"

# Verify Vulkan support
check_vulkan_support

# Initial state
set_normal_mode
log_msg "✅ Service ready - Monitoring applications..."

# ================================================================
# MAIN MONITORING LOOP
# ================================================================

while true; do
    # Detect active window (ignoring screen recorder)
    WINDOW=$(dumpsys window 2>/dev/null | grep -E 'mCurrentFocus|mFocusedApp' | grep -v "screenrecorder\|miui\.screenrecorder" | head -n 1)
    
    # Check for detection error
    if [ -z "$WINDOW" ]; then
        FAIL_COUNT=$((FAIL_COUNT + 1))
        debug_msg "Failed to detect window (#$FAIL_COUNT)"
        
        if [ $FAIL_COUNT -gt 5 ]; then
            log_msg "⚠ ERROR: Cannot detect active window - retrying..."
            sleep 10
            FAIL_COUNT=0
            continue
        fi
        sleep 2
        continue
    else
        FAIL_COUNT=0
    fi
    
    # Extract current package (more robust)
    CURRENT_PACKAGE=$(echo "$WINDOW" | sed 's/.* //g' | cut -d'/' -f1 | grep -o '[a-zA-Z0-9_.]*$')
    
    # Check if app changed
    if [ "$CURRENT_PACKAGE" = "$LAST_PACKAGE" ] && [ -n "$CURRENT_PACKAGE" ]; then
        # Same app - use longer intervals to save battery
        if [ "$IS_GAME" = true ]; then
            debug_msg "Same game ($CURRENT_PACKAGE) - waiting 4s"
            sleep 4
        else
            debug_msg "Same normal app - waiting 6s"
            sleep 6
        fi
        continue
    fi
    
    # Update last detected app
    LAST_PACKAGE="$CURRENT_PACKAGE"
    debug_msg "App detected: $CURRENT_PACKAGE"
    
    # Check if it is a game
    IS_GAME=false
    for GAME in $GAMES; do
        if echo "$CURRENT_PACKAGE" | grep -q "$GAME"; then
            IS_GAME=true
            debug_msg "✓ Game identified: $GAME"
            break
        fi
    done
    
    # Apply corresponding mode
    if [ "$IS_GAME" = true ]; then
        if [ "$CURRENT_MODE" != "vulkan" ]; then
            log_msg "🎮 Game detected: $CURRENT_PACKAGE"
            set_vulkan_mode
            CURRENT_MODE="vulkan"
            sleep 1  # Small pause for props to apply
        fi
        sleep 3  # Interval in game
    else
        if [ "$CURRENT_MODE" != "normal" ]; then
            if [ -n "$CURRENT_PACKAGE" ]; then
                debug_msg "Normal app: $CURRENT_PACKAGE"
            fi
            set_normal_mode
            CURRENT_MODE="normal"
            sleep 1
        fi
        sleep 5  # Interval outside game
    fi
done
