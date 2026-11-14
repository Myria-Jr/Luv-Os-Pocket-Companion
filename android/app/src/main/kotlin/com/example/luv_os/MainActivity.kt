package com.example.luv_os

import android.app.AppOpsManager
import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.os.Process
import android.os.VibrationEffect
import android.os.Vibrator
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "luv.os/hardware_bridge"
    private var methodChannel: MethodChannel? = null

    private var appLockActive: Boolean = false
    private var blockedCategories: List<String> = emptyList()
    private var lockReason: String = "Mimi ist sauer! 💢"
    private var requiredHeadpats: Int = 15

    private val watchdogHandler = Handler(Looper.getMainLooper())
    private val watchdogRunnable = object : Runnable {
        override fun run() {
            if (appLockActive) {
                inspectForegroundAndIntercept()
            }
            watchdogHandler.postDelayed(this, 1800L)
        }
    }

    // Known package fragments for TikTok, Instagram, YouTube, Games & V4 System Apps
    private val blockedPackageKeywords = mapOf(
        "TikTok" to listOf("musically", "trill", "tiktok"),
        "Instagram" to listOf("instagram"),
        "YouTube" to listOf("youtube"),
        "Games" to listOf("roblox", "genshin", "brawlstars", "clash", "minecraft", "pubg", "freefire"),
        "Taschenrechner" to listOf("calculator", "calc"),
        "Kalender" to listOf("calendar"),
        "Wetter-App" to listOf("weather")
    )

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        watchdogHandler.postDelayed(watchdogRunnable, 2000L)
    }

    override fun onDestroy() {
        watchdogHandler.removeCallbacks(watchdogRunnable)
        super.onDestroy()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
        methodChannel = channel

        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "triggerHeartbeatPulse" -> {
                    val intensity = call.argument<Double>("intensity") ?: 0.5
                    vibratePattern(
                        longArrayOf(0, 45, 95, 75),
                        (intensity * 255).toInt().coerceIn(40, 255)
                    )
                    result.success(true)
                }
                "triggerGlitchHapticBurst" -> {
                    vibratePattern(longArrayOf(0, 30, 40, 55, 35, 70), 255)
                    result.success(true)
                }
                "getDeviceName" -> {
                    result.success("${Build.MANUFACTURER} ${Build.MODEL}")
                }
                "setAppLockState" -> {
                    appLockActive = call.argument<Boolean>("locked") ?: false
                    blockedCategories = call.argument<List<String>>("blockedCategories") ?: emptyList()
                    lockReason = call.argument<String>("reason") ?: "Mimi hat deine Apps gesperrt!"
                    requiredHeadpats = call.argument<Int>("requiredHeadpats") ?: 15
                    if (appLockActive) {
                        vibratePattern(longArrayOf(0, 60, 50, 90, 50, 120), 255)
                    }
                    result.success(true)
                }
                "checkUsageStatsPermission" -> {
                    result.success(hasUsageStatsPermission())
                }
                "openUsageStatsSettings" -> {
                    try {
                        val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
                        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        startActivity(intent)
                        result.success(true)
                    } catch (_: Exception) {
                        result.success(false)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun hasUsageStatsPermission(): Boolean {
        return try {
            val appOps = getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
            val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                appOps.unsafeCheckOpNoThrow(
                    AppOpsManager.OPSTR_GET_USAGE_STATS,
                    Process.myUid(),
                    packageName
                )
            } else {
                @Suppress("DEPRECATION")
                appOps.checkOpNoThrow(
                    AppOpsManager.OPSTR_GET_USAGE_STATS,
                    Process.myUid(),
                    packageName
                )
            }
            mode == AppOpsManager.MODE_ALLOWED
        } catch (_: Exception) {
            false
        }
    }

    private fun inspectForegroundAndIntercept() {
        if (!hasUsageStatsPermission()) return
        try {
            val usageStatsManager =
                getSystemService(Context.USAGE_STATS_SERVICE) as? UsageStatsManager ?: return
            val endTime = System.currentTimeMillis()
            val beginTime = endTime - 8000L
            val events = usageStatsManager.queryEvents(beginTime, endTime)
            val event = UsageEvents.Event()
            var latestForegroundPkg: String? = null

            while (events.hasNextEvent()) {
                events.getNextEvent(event)
                if (event.eventType == UsageEvents.Event.ACTIVITY_RESUMED) {
                    latestForegroundPkg = event.packageName
                }
            }

            val pkg = latestForegroundPkg?.lowercase() ?: return
            if (pkg == packageName.lowercase() || pkg.contains("launcher") || pkg.contains("systemui")) {
                return
            }

            var matchedCategory: String? = null
            for (category in blockedCategories) {
                val keywords = blockedPackageKeywords[category] ?: listOf(category.lowercase())
                if (keywords.any { kw -> pkg.contains(kw) }) {
                    matchedCategory = category
                    break
                }
            }

            if (matchedCategory != null) {
                vibratePattern(longArrayOf(0, 90, 45, 110, 45, 160), 255)
                val bringFrontIntent = Intent(this, MainActivity::class.java).apply {
                    addFlags(
                        Intent.FLAG_ACTIVITY_NEW_TASK or
                            Intent.FLAG_ACTIVITY_REORDER_TO_FRONT or
                            Intent.FLAG_ACTIVITY_SINGLE_TOP
                    )
                }
                startActivity(bringFrontIntent)
                methodChannel?.invokeMethod(
                    "onBlockedAppIntercepted",
                    mapOf(
                        "category" to matchedCategory,
                        "packageName" to pkg,
                        "reason" to lockReason
                    )
                )
            }
        } catch (_: Exception) {
        }
    }

    @Suppress("DEPRECATION")
    private fun vibratePattern(pattern: LongArray, amplitude: Int) {
        try {
            val vibrator = getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator ?: return
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val amplitudes =
                    IntArray(pattern.size) { index -> if (index % 2 == 1) amplitude else 0 }
                vibrator.vibrate(VibrationEffect.createWaveform(pattern, amplitudes, -1))
            } else {
                vibrator.vibrate(pattern, -1)
            }
        } catch (_: Exception) {
        }
    }
}
