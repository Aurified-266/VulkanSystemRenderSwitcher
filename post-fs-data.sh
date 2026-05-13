#!/system/bin/sh
# Executes in post-fs-data (before boot completion)
MODDIR="${0%/*}"
#!/system/bin/sh
# ╔══════════════════════════════════════════════════════════════╗
# ║                    VULKAN SYSTEM RENDERER                    ║
# ║         Optimization Module for HyperOS / MIUI               ║
# ║              Target Device: Universal                        ║
# ║            Default Config: Snapdragon                        ║
# ║                                                              ║
# ║  📌 FOR MEDIATEK / EXYNOS:                                   ║
# ║     Read the [MTK] or [EXYNOS] comments on each line         ║
# ║     Comment out specific Snapdragon lines                    ║
# ║                                                              ║
# ║  WARNING: If something fails after installing this module,   ║
# ║  read the comments in each section to identify the line      ║
# ║  causing the issue and comment it out with #.                ║
# ║                                                              ║
# ║  NOTE: This script applies FIXED BASE OPTIMIZATIONS.         ║
# ║  Dynamic props (Vulkan/OpenGL) are managed by service.sh     ║
# ║  to avoid conflicts.                                         ║
# ╚══════════════════════════════════════════════════════════════╝

# Wait 15 seconds for the system to finish booting
# before applying props. Do not reduce this value.
sleep 15

log -t SAFE "--- [VULKAN SYSTEM]: Starting BASE Optimization ---"

# Helper function to safely apply props
set_prop() {
    if command -v resetprop >/dev/null 2>&1; then
        resetprop "$1" "$2"
    else
        setprop "$1" "$2"
    fi
}

# ═══════════════════════════════════════════════════════════════
# SYSTEM BASE: CPU / SCHEDULER / I/O
# General runtime and scheduler optimizations.
# 📌 [UNIVERSAL] Works on all processors
# ═══════════════════════════════════════════════════════════════
set_prop persist.sys.dalvik.vm.lib.2 libart.so                            # Forces ART as runtime (default in modern Android)
# 📌 [MTK/EXYNOS] The following line is specific to Qualcomm FastCV
#    If you have MTK or Exynos, COMMENT this line (put # at the beginning)
set_prop ro.vendor.extension_library /vendor/lib/rfsa/adsp/libfastcvopt.so # [SNAPDRAGON] Activates FastCV - COMMENT in MTK/Exynos
set_prop ro.config.hw_quickpoweron 1                                       # Quick hardware power-on when exiting suspend
set_prop persist.sys.perf.topAppRenderThreadBoost.enable true              # CPU boost to the render thread of the foreground app
set_prop persist.sys.job_delay true                                        # Delays background jobs to prioritize the active app
set_prop ro.config.max_starting_bg 16                                      # Max background processes when launching apps

# ═══════════════════════════════════════════════════════════════
# MIUI / HYPEROS - GLOBAL OPTIMIZATIONS
# Props specific to the MIUI/HyperOS layer.
# 📌 [UNIVERSAL] Works on MIUI/HyperOS on any processor
# ═══════════════════════════════════════════════════════════════
set_prop persist.sys.miui.sf.vsync 1                                       # Enables VSync in SurfaceFlinger for MIUI
set_prop persist.miui.speed_up_freeform true                               # Speeds up freeform windows
set_prop persist.sys.miui_booster 1                                        # Activates MIUI performance booster
set_prop persist.sys.smart_power 0                                         # Disables smart power management (may limit performance)
set_prop persist.sys.doze_powersave true                                   # Keeps power saving in Doze mode
set_prop persist.sys.ui.hw 1                                               # Forces hardware acceleration in system UI
set_prop video.accelerate.hw 1                                             # Activates hardware acceleration for video playback
set_prop persist.miui.migt.enable 1                                        # Activates MIUI Game Turbo (MIGT)
set_prop persist.miui.migt.game_boost 1                                    # Activates specific boost for games within MIGT
set_prop persist.sys.miui_anim_res_direct 1                                # Direct rendering of animation resources
set_prop persist.sys.miui_prio_render 1                                    # High priority for MIUI render thread

# ═══════════════════════════════════════════════════════════════
# GPU / VULKAN - RENDERING CORE (STATIC PROPS ONLY)
# GPU and rendering pipeline optimizations.
# ⚠ If visual glitches or black screens appear in apps,
#   check this section first.
# ⚠ NOTE: Renderer props (skiavk/skiagl) and render_thread
#   are MANAGED DYNAMICALLY by service.sh for the switcher.
# 📌 [SNAPDRAGON] This section is optimized for Adreno GPU
# 📌 [MTK] For Mali GPU, many props differ or don't exist
# 📌 [EXYNOS] For Mali or Xclipse, many props differ
# ═══════════════════════════════════════════════════════════════
# 📌 [MTK/EXYNOS] The following line is specific to Adreno GPU
#    In MTK/Exynos, COMMENT this line (ro.adreno.agp.turbo does not exist)
set_prop ro.adreno.agp.turbo 1                                             # [SNAPDRAGON] Adreno turbo mode - COMMENT in MTK/Exynos
set_prop persist.sys.debug.color_temp 0                                    # Neutral color temperature (0 = no correction)
set_prop debug.renderengine.cache_shaders true                             # Caches compiled shaders to avoid stutters on first run
set_prop debug.egl.hw 1                                                    # Forces hardware EGL rendering
set_prop persist.sys.force_sw_gles 0                                       # Disables fallback to software GLES rendering
# 📌 [MTK/EXYNOS] UBWC is exclusive compression for Adreno
#    In MTK/Exynos, COMMENT the next 2 lines
set_prop debug.gralloc.enable_fb_ubwc 1                                    # [SNAPDRAGON] Activates UBWC - COMMENT in MTK/Exynos
set_prop debug.gralloc.gfx_ubwc_disable 0                                  # [SNAPDRAGON] Confirms UBWC active - COMMENT in MTK/Exynos

# --- HWUI Cache ---
# Controls how much memory HWUI reserves for textures and layers.
# Higher values = less asset reloading, more RAM used.
# 📌 [UNIVERSAL] HWUI caches work on all processors
#    Values can be adjusted based on device RAM
#    (8GB = 70-88, 12GB = 88-96, 6GB = 50-70)
set_prop ro.hwui.texture_cache_size 70                                     # Texture cache size in MB
set_prop ro.hwui.layer_cache_size 64                                       # Layer cache size in MB
set_prop ro.hwui.r_buffer_cache_size 34                                    # Render buffer cache in MB
set_prop ro.hwui.gradient_cache_size 7                                     # Gradient cache in MB
set_prop ro.hwui.path_cache_size 42                                        # Vector path cache in MB
set_prop ro.hwui.drop_shadow_cache_size 7                                  # Drop shadow cache in MB
set_prop ro.hwui.font_cache_size 8                                         # Font cache in MB
set_prop debug.hwui.use_hint_manager=true                                  # Activates HWUI hint manager to optimize GPU load

# --- Composition ---
# NOTE: persist.sys.composition.type is NOT forced here to avoid interfering
# with service.sh which activates/deactivates it based on the game.
# resetprop persist.sys.composition.type gpu                                # [MANAGED BY service.sh] Forced GPU composition ignoring HWC - BREAKS videos in social apps if forced always

# --- Skia ---
# 📌 [UNIVERSAL] Works on all processors
set_prop renderthread.skia.reduceopstasksplitting true                     # Reduces task splitting in Skia pipeline (less overhead)

# ⚠️ THE FOLLOWING PROPS ARE DYNAMIC (commented - managed by service.sh)
# set_prop debug.hwui.renderer skiavk                                       # [MANAGED BY service.sh] HWUI renderer - skiavk = Vulkan, skiagl = OpenGL
# set_prop debug.hwui.render_thread true                                    # [MANAGED BY service.sh] Dedicated HWUI render thread - Improves performance in games
# set_prop ro.hwui.use_vulkan true                                          # [MANAGED BY service.sh] Allows HWUI to use Vulkan as render backend
# set_prop debug.vulkan.frame.pacing 1                                      # [MANAGED BY service.sh] Vulkan frame pacing to prevent tearing and stutter
# set_prop debug.hwui.vulkan.use_pipeline_cache true                        # [MANAGED BY service.sh] Caches compiled Vulkan pipelines to reduce initial stutter
# set_prop debug.hwui.vulkan.enable_shared_image true                       # [MANAGED BY service.sh] Allows sharing images between GPU and CPU in Vulkan
# set_prop debug.hwui.use_vulkan_texture_filtering true                     # [MANAGED BY service.sh] Texture filtering via Vulkan (better visual quality)
# set_prop debug.hwui.fbpipeline true                                       # [MANAGED BY service.sh] Framebuffer pipeline optimized for Vulkan
# set_prop debug.skia.threaded true                                         # [MANAGED BY service.sh] Executes Skia operations on multiple threads
# set_prop debug.cpurend.disable 1                                          # [MANAGED BY service.sh] Disables CPU rendering forces everything to GPU
# set_prop debug.hwui.use_gpu_pixel_buffers true                            # [MANAGED BY service.sh] Uses GPU pixel buffers for fast pixel operations
# set_prop debug.hwui.skip_empty_damage true                                # [MANAGED BY service.sh] Skips empty damaged regions (saves render cycles)
# set_prop debug.hwui.webview_overlays_enabled true                         # [MANAGED BY service.sh] Accelerates WebView overlays with GPU
# set_prop sys.use_fifo_ui true                                             # [MANAGED BY service.sh] Uses FIFO scheduler for UI (max priority)
# set_prop debug.renderengine.vulkan.disable_vblank_wait true               # [MANAGED BY service.sh] Removes VBlank wait in Vulkan (reduces latency but may cause tearing)
# set_prop debug.perf.vulkan.use_gpu_memcpy 1                               # [MANAGED BY service.sh] Uses GPU-accelerated memory copies for Vulkan
# set_prop debug.perf.vulkan.enable_robustness 0                            # [MANAGED BY service.sh] Disables Vulkan robustness (lower overhead, higher performance)
# set_prop vulkan.pipeline_cache.enabled true                               # [MANAGED BY service.sh] Enables global Vulkan pipeline cache

# ═══════════════════════════════════════════════════════════════
# SURFACEFLINGER / FRAME PACING
# Screen compositor control and frame rate.
# ⚠ If video looks choppy in social apps,
#   check latch_unsignaled (it is disabled for this reason).
# 📌 [UNIVERSAL] Works on all processors
# ═══════════════════════════════════════════════════════════════
set_prop debug.sf.set_idle_timer_ms 4000                                   # SF waits 4000ms before lowering refresh rate due to inactivity
# resetprop debug.sf.latch_unsignaled 1                                    # [DISABLED] Presents frames before decoder fills them - BREAKS video playback in Facebook, Telegram, Twitter, etc.
set_prop debug.sf.enable_transaction_tracing false                         # Disables SF transaction tracing (reduces logging overhead)
set_prop ro.surface_flinger.uclamp.min 205                                 # [SNAPDRAGON] Minimum frequency for SF - MTK/EXYNOS may not support it, comment if issues arise

# --- Latency and Touch Response ---
# 📌 [UNIVERSAL] Works on all processors
set_prop ro.max.fling_velocity 15000                                       # Max fling velocity (fast scroll) in pixels/sec
set_prop ro.min_pointer_dur 0                                              # Min touch pointer duration (0 = max response)

# ═══════════════════════════════════════════════════════════════
# UI/UX - ANIMATIONS AND INPUT
# System animation speed and input response.
# ⚠ If animations look weird or too fast, adjust
#   the first three values (0.5 = half stock speed).
# 📌 [UNIVERSAL] Works on all processors
# ═══════════════════════════════════════════════════════════════
set_prop persist.sys.window_animation_scale 0.5                            # Window animation speed (1.0 = stock, 0.5 = double speed)
set_prop persist.sys.transition_animation_scale 0.5                       # Transition animation speed between apps
set_prop persist.sys.animator_duration_scale 0.5                          # General system animation duration
set_prop windowsmgr.max_events_per_sec 240                                 # Max input events processed per second (adjusted to 240Hz)
set_prop ro.input.noresample 1                                             # Disables touch event resampling (lower touch latency)

# ═══════════════════════════════════════════════════════════════
# MEDIA / CODECS
# Stagefright media playback framework control.
# ⚠ If an app fails to play video, check this section.
# 📌 [UNIVERSAL] Works on all processors
# ═══════════════════════════════════════════════════════════════
set_prop media.stagefright.enable-player true                              # Enables native Stagefright player
set_prop media.stagefright.enable-meta true                                # Enables metadata reading by Stagefright
# resetprop audio.offload.video true                                       # [DISABLED] Audio offload during video playback - Can cause audio/video desync
# resetprop audio.offload.pcm.16bit.enable true                            # [DISABLED] 16bit PCM offload to DSP - BREAKS video playback in Twitter
# resetprop audio.offload.pcm.24bit.enable true                            # [DISABLED] 24bit PCM offload to DSP - BREAKS video playback in Twitter
# resetprop audio.offload.track.enabled true                               # [DISABLED] Audio track offload to DSP - Can cause conflicts with multiple streams

# ═══════════════════════════════════════════════════════════════
# AUDIO - CORE
# Main system audio pipeline.
# ⚠ This section is the most sensitive. If audio fails
#   (videos won't start, volume lag, sounds disappear in games),
#   start by commenting out lines here.
# 📌 [UNIVERSAL] Most work, but some props are Qualcomm specific
# ═══════════════════════════════════════════════════════════════
set_prop audio.offload.buffer.size.kb 440                                  # Offload buffer size to DSP in KB - Higher = more simultaneous sounds in games, more lag in social apps
# resetprop audio.offload.min.duration.secs 30                             # [DISABLED] Activated offload for audio > 30 seconds - BREAKS Twitter
set_prop audio.deep_buffer.media true                                      # Deep buffer for media playback - ⚠ Can cause volume change lag
set_prop audio.playback.capture.pcm.quality high                          # High resolution PCM capture quality
set_prop ro.audio.flinger_standbytime_ms 3000                             # Time before AudioFlinger enters standby (3000 = no lag)
set_prop af.resampler.quality 5                                            # AudioFlinger resampler quality (range 0-8)
# 📌 [MTK/EXYNOS] The following line is specific to Qualcomm DSP
#    In MTK/Exynos, COMMENT this line if there are audio issues
set_prop persist.vendor.audio.offload.multiple.enabled true               # [SNAPDRAGON] Multiple offload streams - COMMENT in MTK/Exynos if issues arise

# --- Sample Rates ---
# ALL DISABLED: Mapping sample rates to DSP causes apps like Telegram
# to fail video playback.
# 📌 [UNIVERSAL] DO NOT activate on ANY processor
# resetprop ro.audio.samplerate.8000 48000                                 # [DISABLED] Resamples 8kHz - BREAKS Telegram
# ... (other sample rate lines removed for brevity as they were all disabled)

# --- HiFi Audio ---
# DISABLED: Routes audio through dedicated DAC.
# ⚠ BREAKS Bluetooth audio on ALL processors
# 📌 [UNIVERSAL] DO NOT activate on ANY processor if using Bluetooth
# resetprop persist.audio.hifi true                                        # [DISABLED] BREAKS Bluetooth on all devices
# resetprop persist.vendor.audio.hifi true                                 # [DISABLED] BREAKS Bluetooth on all devices

# --- Audio Latency ---
# 📌 [UNIVERSAL] Works on all processors
set_prop persist.audio.lowprio true                                        # Low audio priority to free up CPU in games
set_prop ro.audio.pcm.cb.size 192                                          # PCM callback buffer size (128-256, lower = less latency)

# --- Fluence (microphones / noise cancellation) ---
# 📌 [SNAPDRAGON] Fluence is Qualcomm technology
# 📌 [MTK/EXYNOS] These props do not exist, COMMENT all
# resetprop persist.vendor.audio.fluence.game false                        # [SNAPDRAGON] Game noise cancellation - COMMENT in MTK/Exynos
# resetprop persist.audio.fluence.voicecall true                           # [SNAPDRAGON] Call noise cancellation - COMMENT in MTK/Exynos
# resetprop persist.audio.fluence.speaker false                            # [SNAPDRAGON] Speaker noise cancellation - COMMENT in MTK/Exynos
# resetprop ro.qc.sdk.audio.fluencetype fluence                            # [SNAPDRAGON] Fluence type - COMMENT in MTK/Exynos

# ═══════════════════════════════════════════════════════════════
# BOSE SIGNATURE TONE (Sound Profile)
# Experimental sound profile - [UNIVERSAL] but depends on hardware
# ═══════════════════════════════════════════════════════════════
# resetprop ro.vendor.audio.dolby.hp_advanced true                         # [EXPERIMENTAL] Advanced Dolby - Test on each device
# ... (experimental lines removed for safety)

# ═══════════════════════════════════════════════════════════════
# BLUETOOTH - WIRELESS AUDIO
# Optimizations for A2DP and LDAC.
# 📌 [SNAPDRAGON] LDAC and AAC whitelist are Qualcomm specific
# 📌 [MTK/EXYNOS] Some props may not exist, comment if issues arise
# ═══════════════════════════════════════════════════════════════
set_prop persist.audio.bt.a2dp.hifi true                                   # Bluetooth HiFi mode - Universal
set_prop persist.bluetooth.a2dp.aac_whitelist true                        # [SNAPDRAGON] AAC whitelist - COMMENT in MTK/Exynos if not working
set_prop persist.bluetooth.a2dp.aac_vbr true                              # AAC VBR - Universal
set_prop persist.bluetooth.a2dp.aac_frame_ctl true                        # AAC control frames - Universal
set_prop persist.bluetooth.a2dp.ldac.quality hq                           # LDAC Quality - Universal (if device supports LDAC)
set_prop persist.bluetooth.a2dp.ldac.abr true                             # LDAC ABR - Universal

# ═══════════════════════════════════════════════════════════════
# THREAD / DALVIK PERFORMANCE
# 📌 [UNIVERSAL] Works on all processors
# ═══════════════════════════════════════════════════════════════
set_prop dalvik.vm.dex2oat-threads 6                                       # Threads for app compilation
set_prop ro.vendor.qti.sys.fw.bg_apps_limit 47                            # [SNAPDRAGON] Background app limit - COMMENT in MTK/Exynos

# ═══════════════════════════════════════════════════════════════
# NETWORK / CONNECTIVITY
# 📌 [UNIVERSAL] TCP and RIL work on all processors
# ═══════════════════════════════════════════════════════════════

# Initial TCP window by network type (in segments)
set_prop net.tcp.2g_init_rwnd 10
set_prop net.tcp.3g_init_rwnd 20
set_prop net.tcp.gprs_init_rwnd 10
set_prop net.tcp.lte_init_rwnd 30
set_prop net.tcp.init_rwnd 30
set_prop net.tcp.default_tcp_congestion_control cubic

# Mobile data stability
set_prop persist.radio.data_con_recovery true
set_prop persist.radio.data_no_toggle 1
set_prop persist.cust.tel.e010 1
set_prop persist.radio.add_power_save 0

# RIL (Radio Interface Layer) - [UNIVERSAL] but may vary
set_prop ro.ril.hep 1
set_prop ro.ril.enable.dtm 1
set_prop ro.ril.enable.managed.roaming 1
set_prop ro.ril.enable.a53 1
set_prop ro.ril.gprsclass 12
set_prop ro.config.nocheckin 0

# ═══════════════════════════════════════════════════════════════
# CAMERA
# Accelerate startup and capture - [UNIVERSAL] but depends on manufacturer
# ═══════════════════════════════════════════════════════════════
# 📌 [MTK/EXYNOS] The following props are Qualcomm specific
#    In MTK/Exynos, COMMENT these lines or change to equivalents
set_prop persist.vendor.camera.perf.hfr.enable 1                           # [SNAPDRAGON] High perf profiles - COMMENT in MTK/Exynos
set_prop persist.vendor.camera.enable_fast_launch 1                        # [SNAPDRAGON] Fast launch - COMMENT in MTK/Exynos
set_prop persist.camera.focus.debug 0                                      # Focus speed - Universal
set_prop persist.camera.shutter.speed 0                                    # Shutter speed - Universal

# ═══════════════════════════════════════════════════════════════
# KERNEL TCP OPTIMIZATION
# Applies TCP config directly to kernel.
# 📌 [UNIVERSAL] Works on all Linux kernels
# ═══════════════════════════════════════════════════════════════
echo "cubic" > /proc/sys/net/ipv4/tcp_congestion_control
echo "cubic" > /proc/sys/net/ipv4/tcp_allowed_congestion_control
echo "0" > /proc/sys/net/ipv4/tcp_no_metrics_save

# Delete modified kernel version prop
resetprop --delete ro.modversion

log -t SAFE "--- [VULKAN SYSTEM]: BASE Optimization Completed Successfully ---"
log -t SAFE "--- [VULKAN SYSTEM]: Dynamic props (Vulkan/OpenGL) managed by service.sh ---"
log -t SAFE "--- [VULKAN SYSTEM]: If using MTK/Exynos, review marked lines ---"

exit 0
