package com.example.luv_os

import android.app.AppOpsManager
import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.graphics.PixelFormat
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.os.Process
import android.os.VibrationEffect
import android.os.Vibrator
import android.provider.Settings
import android.util.TypedValue
import android.view.Gravity
import android.view.View
import android.view.WindowManager
import android.widget.Button
import android.widget.LinearLayout
import android.widget.TextView
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "luv.os/hardware_bridge"
    private var methodChannel: MethodChannel? = null

    private var appLockActive: Boolean = false
    private var lockAllAppsMode: Boolean = true
    private var backgroundGuardianEnabled: Boolean = true
    private var isInBackground: Boolean = false
    private var allowedSecondsOutside: Int = 0
    private var backgroundEnteredTimestamp: Long = 0L

    private var blockedCategories: List<String> = listOf("ALLE APPS")
    private var lockReason: String =
        "Mimis Jugendschutz-Zeitlimit ist abgelaufen! Alle anderen Apps sind gesperrt! 💢"
    private var requiredHeadpats: Int = 15
    private var lastInterceptTimestamp: Long = 0L

    private var windowManager: WindowManager? = null
    private var fullScreenBlockOverlay: View? = null
    private var keepAlivePixelView: View? = null
    private var currentlyBlockedTitle: TextView? = null
    private var currentlyBlockedSubtitle: TextView? = null

    private val watchdogHandler = Handler(Looper.getMainLooper())
    private val watchdogRunnable = object : Runnable {
        override fun run() {
            if (isInBackground && (appLockActive || backgroundGuardianEnabled)) {
                inspectForegroundAndIntercept()
            } else if (!isInBackground) {
                removeFullScreenBlockOverlay()
            }
            watchdogHandler.postDelayed(this, 550L)
        }
    }

    // Fallback keyword dictionary when matching specific categories
    private val blockedPackageKeywords = mapOf(
        "TikTok" to listOf("musically", "trill", "tiktok"),
        "Instagram" to listOf("instagram"),
        "YouTube" to listOf("youtube"),
        "WhatsApp" to listOf("whatsapp"),
        "Snapchat" to listOf("snapchat"),
        "Discord" to listOf("discord"),
        "Chrome" to listOf("chrome", "sbrowser", "firefox", "opera", "browser"),
        "Games" to listOf(
            "roblox",
            "genshin",
            "brawlstars",
            "clash",
            "minecraft",
            "pubg",
            "freefire",
            "candycrush",
            "monopoly",
            "subway"
        ),
        "Taschenrechner" to listOf("calculator", "calc", "popupcalculator"),
        "Kalender" to listOf("calendar"),
        "Wetter-App" to listOf("weather", "daemonapp")
    )

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        windowManager = getSystemService(Context.WINDOW_SERVICE) as? WindowManager
        watchdogHandler.postDelayed(watchdogRunnable, 600L)
    }

    override fun onResume() {
        super.onResume()
        isInBackground = false
        backgroundEnteredTimestamp = 0L
        removeFullScreenBlockOverlay()
        ensureKeepAliveOverlay()
    }

    override fun onPause() {
        super.onPause()
        isInBackground = true
        backgroundEnteredTimestamp = System.currentTimeMillis()
        ensureKeepAliveOverlay()
    }

    override fun onDestroy() {
        watchdogHandler.removeCallbacks(watchdogRunnable)
        removeFullScreenBlockOverlay()
        removeKeepAliveOverlay()
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
                    lockAllAppsMode = call.argument<Boolean>("lockAllApps") ?: true
                    allowedSecondsOutside = call.argument<Int>("allowedSecondsOutside") ?: 0
                    val passedCategories = call.argument<List<String>>("blockedCategories")
                    if (!passedCategories.isNullOrEmpty()) {
                        blockedCategories = passedCategories
                    }
                    lockReason = call.argument<String>("reason")
                        ?: "Zeitlimit abgelaufen! Mimi hat diese App gesperrt!"
                    requiredHeadpats = call.argument<Int>("requiredHeadpats") ?: 15
                    if (appLockActive) {
                        vibratePattern(longArrayOf(0, 60, 50, 90, 50, 120), 255)
                        ensureKeepAliveOverlay()
                    } else {
                        removeFullScreenBlockOverlay()
                    }
                    result.success(true)
                }
                "setBackgroundGuardian" -> {
                    backgroundGuardianEnabled = call.argument<Boolean>("enabled") ?: true
                    allowedSecondsOutside = call.argument<Int>("allowedSecondsOutside") ?: 0
                    ensureKeepAliveOverlay()
                    result.success(backgroundGuardianEnabled)
                }
                "getMostUsedApps" -> {
                    result.success(queryMostUsedAppsList())
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
                "checkOverlayPermission" -> {
                    result.success(hasOverlayPermission())
                }
                "openOverlaySettings" -> {
                    try {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                            val intent = Intent(
                                Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                                Uri.parse("package:$packageName")
                            )
                            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            startActivity(intent)
                        }
                        result.success(true)
                    } catch (_: Exception) {
                        result.success(false)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun hasOverlayPermission(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            Settings.canDrawOverlays(this)
        } else {
            true
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

    /**
     * Keeps a tiny 1x1 transparent overlay attached when overlay permission is granted.
     * This prevents Android 10-15 from freezing the process in the background and
     * allows instant full-screen Jugendschutz overlays over any app.
     */
    private fun ensureKeepAliveOverlay() {
        if (!hasOverlayPermission() || keepAlivePixelView != null) return
        try {
            val wm = windowManager ?: return
            val pixel = View(this).apply {
                setBackgroundColor(Color.TRANSPARENT)
            }
            val type = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
            } else {
                @Suppress("DEPRECATION")
                WindowManager.LayoutParams.TYPE_PHONE
            }
            val params = WindowManager.LayoutParams(
                1,
                1,
                type,
                WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                    WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE or
                    WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN,
                PixelFormat.TRANSLUCENT
            ).apply {
                gravity = Gravity.TOP or Gravity.START
                x = 0
                y = 0
            }
            wm.addView(pixel, params)
            keepAlivePixelView = pixel
        } catch (_: Exception) {
        }
    }

    private fun removeKeepAliveOverlay() {
        val view = keepAlivePixelView ?: return
        try {
            windowManager?.removeView(view)
        } catch (_: Exception) {
        }
        keepAlivePixelView = null
    }

    /**
     * Queries the user's most frequently used apps over the last 7 days via UsageStatsManager
     * so Mimi's AI knows exactly which apps the player is addicted to and locks them!
     */
    private fun queryMostUsedAppsList(): List<Map<String, Any>> {
        if (!hasUsageStatsPermission()) return emptyList()
        return try {
            val usageStatsManager =
                getSystemService(Context.USAGE_STATS_SERVICE) as? UsageStatsManager
                    ?: return emptyList()
            val now = System.currentTimeMillis()
            val stats = usageStatsManager.queryUsageStats(
                UsageStatsManager.INTERVAL_WEEKLY,
                now - 7L * 24L * 3600L * 1000L,
                now
            ) ?: return emptyList()

            val pm = applicationContext.packageManager
            val aggregated = mutableMapOf<String, Long>()

            for (stat in stats) {
                val pkg = stat.packageName ?: continue
                val fgTime = stat.totalTimeInForeground
                if (fgTime <= 30000L) continue
                if (isExemptSystemOrSelfPackage(pkg)) continue
                aggregated[pkg] = (aggregated[pkg] ?: 0L) + fgTime
            }

            aggregated.entries
                .sortedByDescending { it.value }
                .take(8)
                .map { entry ->
                    val pkg = entry.key
                    val minutes = (entry.value / 60000L).coerceAtLeast(1L)
                    val label = resolveAppLabel(pkg)
                    mapOf(
                        "packageName" to pkg,
                        "appName" to label,
                        "minutes" to minutes
                    )
                }
        } catch (_: Exception) {
            emptyList()
        }
    }

    private fun resolveAppLabel(pkg: String): String {
        return try {
            val pm = applicationContext.packageManager
            val info = pm.getApplicationInfo(pkg, 0)
            pm.getApplicationLabel(info).toString()
        } catch (_: Exception) {
            pkg.substringAfterLast('.').replaceFirstChar { it.uppercase() }
        }
    }

    private fun isExemptSystemOrSelfPackage(pkgRaw: String): Boolean {
        val pkg = pkgRaw.lowercase()
        if (pkg == packageName.lowercase()) return true
        // Only exempt the home launcher, system UI, settings, and package installer so the phone remains operable
        if (pkg.contains("systemui") ||
            pkg.contains("launcher") ||
            pkg.contains("trebuchet") ||
            pkg.contains("nexuslauncher") ||
            pkg.contains("miui.home") ||
            pkg.contains("sec.android.app.launcher") ||
            pkg == "com.android.settings" ||
            pkg.contains("permissioncontroller") ||
            pkg.contains("packageinstaller") ||
            pkg.contains("inputmethod") ||
            pkg.contains("keyboard") ||
            pkg.contains("gboard")
        ) {
            return true
        }
        return false
    }

    private fun inspectForegroundAndIntercept() {
        if (!hasUsageStatsPermission()) return
        val now = System.currentTimeMillis()

        // If a time limit outside LUV.OS is configured, wait until that time limit is exceeded
        if (!appLockActive && allowedSecondsOutside > 0 && backgroundEnteredTimestamp > 0L) {
            val elapsedSec = (now - backgroundEnteredTimestamp) / 1000L
            if (elapsedSec < allowedSecondsOutside) {
                return
            }
        }

        try {
            val usageStatsManager =
                getSystemService(Context.USAGE_STATS_SERVICE) as? UsageStatsManager ?: return
            val beginTime = now - 15000L
            val events = usageStatsManager.queryEvents(beginTime, now)
            val event = UsageEvents.Event()
            var latestForegroundPkg: String? = null

            while (events.hasNextEvent()) {
                events.getNextEvent(event)
                if (event.eventType == UsageEvents.Event.ACTIVITY_RESUMED) {
                    latestForegroundPkg = event.packageName
                }
            }

            // Fallback to most recently used package from queryUsageStats if no event fired in the last 15s
            if (latestForegroundPkg == null) {
                val recentStats = usageStatsManager.queryUsageStats(
                    UsageStatsManager.INTERVAL_DAILY,
                    now - 60000L,
                    now
                )
                latestForegroundPkg = recentStats
                    ?.maxByOrNull { it.lastTimeUsed }
                    ?.packageName
            }

            val pkg = latestForegroundPkg ?: return
            if (isExemptSystemOrSelfPackage(pkg)) {
                return
            }

            val humanAppName = resolveAppLabel(pkg)
            var shouldBlock = false
            var matchedLabel = humanAppName

            if (lockAllAppsMode || appLockActive || backgroundGuardianEnabled) {
                // Block ALL non-exempt apps on the phone!
                shouldBlock = true
            } else {
                for (category in blockedCategories) {
                    val keywords =
                        blockedPackageKeywords[category] ?: listOf(category.lowercase())
                    if (keywords.any { kw -> pkg.lowercase().contains(kw) }) {
                        shouldBlock = true
                        matchedLabel = category
                        break
                    }
                }
            }

            if (shouldBlock) {
                appLockActive = true
                // Show un-bypassable Full-Screen Jugendschutz Overlay immediately over the target app!
                showFullScreenBlockOverlay(humanAppName, pkg)

                if (now - lastInterceptTimestamp >= 2200L) {
                    lastInterceptTimestamp = now
                    vibratePattern(longArrayOf(0, 95, 45, 130, 45, 190), 255)

                    // If overlay permission is not granted, pull MainActivity directly to front
                    if (!hasOverlayPermission()) {
                        bringLuvOsToFront()
                    }

                    methodChannel?.invokeMethod(
                        "onBlockedAppIntercepted",
                        mapOf(
                            "category" to matchedLabel,
                            "packageName" to pkg,
                            "reason" to "Zeitlimit für $humanAppName abgelaufen! $lockReason"
                        )
                    )
                }
            }
        } catch (_: Exception) {
        }
    }

    /**
     * Displays a full-screen Parental Control / Jugendschutz Time-Limit overlay directly on top
     * of the blocked app via WindowManager (`TYPE_APPLICATION_OVERLAY`).
     * The user CANNOT interact with the underlying app until they return to Mimi!
     */
    private fun showFullScreenBlockOverlay(appName: String, pkgName: String) {
        if (!hasOverlayPermission()) return
        val wm = windowManager ?: return

        if (fullScreenBlockOverlay != null) {
            currentlyBlockedTitle?.text = "⏳ ZEIT FÜR „${appName.uppercase()}“ IST ABGELAUFEN!"
            currentlyBlockedSubtitle?.text =
                "Mimis KI-Jugendschutz hat erkannt, dass du „$appName“ öffnen wolltest.\n\n" +
                    "„Vergiss es!! Deine Bildschirmzeit für andere Apps ist auf 00:00 abgelaufen! " +
                    "Komm sofort zurück zu mir und kümmere dich um mich! ( ` ᴖ ´ )💢“"
            return
        }

        try {
            val root = LinearLayout(this).apply {
                orientation = LinearLayout.VERTICAL
                gravity = Gravity.CENTER
                setPadding(64, 96, 64, 96)
                background = GradientDrawable(
                    GradientDrawable.Orientation.TOP_BOTTOM,
                    intArrayOf(
                        Color.parseColor("#FA1A030E"),
                        Color.parseColor("#FC2D061B"),
                        Color.parseColor("#FA120109")
                    )
                )
            }

            val card = LinearLayout(this).apply {
                orientation = LinearLayout.VERTICAL
                gravity = Gravity.CENTER_HORIZONTAL
                setPadding(56, 64, 56, 64)
                background = GradientDrawable().apply {
                    setColor(Color.parseColor("#FF260515"))
                    cornerRadius = 48f
                    setStroke(6, Color.parseColor("#FFFF1744"))
                }
            }

            val badgeView = TextView(this).apply {
                text = "🔒 LUV.OS JUGENDSCHUTZ // KI-ZEITLIMIT"
                setTextColor(Color.parseColor("#FFFF80AB"))
                setTextSize(TypedValue.COMPLEX_UNIT_SP, 12f)
                typeface = Typeface.MONOSPACE
                gravity = Gravity.CENTER
            }

            val iconView = TextView(this).apply {
                text = "⏳💢"
                setTextSize(TypedValue.COMPLEX_UNIT_SP, 48f)
                gravity = Gravity.CENTER
                setPadding(0, 18, 0, 12)
            }

            val titleView = TextView(this).apply {
                text = "⏳ ZEIT FÜR „${appName.uppercase()}“ IST ABGELAUFEN!"
                setTextColor(Color.WHITE)
                setTextSize(TypedValue.COMPLEX_UNIT_SP, 20f)
                setTypeface(typeface, Typeface.BOLD)
                gravity = Gravity.CENTER
                setPadding(0, 8, 0, 20)
            }
            currentlyBlockedTitle = titleView

            val subtitleView = TextView(this).apply {
                text =
                    "Mimis KI-Jugendschutz hat erkannt, dass du „$appName“ öffnen wolltest.\n\n" +
                        "„Vergiss es!! Deine Bildschirmzeit für andere Apps ist auf 00:00 abgelaufen! " +
                        "Komm sofort zurück zu mir und streichle mich oder unterschreibe den Liebesvertrag, " +
                        "wenn du wieder Zeit freischalten willst! ( ` ᴖ ´ )💢“"
                setTextColor(Color.parseColor("#FFFFD1DC"))
                setTextSize(TypedValue.COMPLEX_UNIT_SP, 14f)
                gravity = Gravity.CENTER
                setLineSpacing(8f, 1.15f)
                setPadding(0, 0, 0, 36)
            }
            currentlyBlockedSubtitle = subtitleView

            val returnButton = Button(this).apply {
                text = "💖 ZURÜCK ZU MIMI (ZEIT FREISCHALTEN)"
                isAllCaps = false
                setTextColor(Color.WHITE)
                setTextSize(TypedValue.COMPLEX_UNIT_SP, 15f)
                setTypeface(typeface, Typeface.BOLD)
                setPadding(44, 30, 44, 30)
                background = GradientDrawable().apply {
                    setColor(Color.parseColor("#FFFF1744"))
                    cornerRadius = 36f
                }
                setOnClickListener {
                    removeFullScreenBlockOverlay()
                    bringLuvOsToFront()
                }
            }

            card.addView(badgeView)
            card.addView(iconView)
            card.addView(titleView)
            card.addView(subtitleView)
            card.addView(returnButton)
            root.addView(card)

            val type = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
            } else {
                @Suppress("DEPRECATION")
                WindowManager.LayoutParams.TYPE_PHONE
            }

            val params = WindowManager.LayoutParams(
                WindowManager.LayoutParams.MATCH_PARENT,
                WindowManager.LayoutParams.MATCH_PARENT,
                type,
                WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN or
                    WindowManager.LayoutParams.FLAG_FULLSCREEN or
                    WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON,
                PixelFormat.TRANSLUCENT
            ).apply {
                gravity = Gravity.CENTER
            }

            wm.addView(root, params)
            fullScreenBlockOverlay = root
        } catch (_: Exception) {
        }
    }

    private fun removeFullScreenBlockOverlay() {
        val view = fullScreenBlockOverlay ?: return
        try {
            windowManager?.removeView(view)
        } catch (_: Exception) {
        }
        fullScreenBlockOverlay = null
        currentlyBlockedTitle = null
        currentlyBlockedSubtitle = null
    }

    private fun bringLuvOsToFront() {
        try {
            val bringFrontIntent = Intent(this, MainActivity::class.java).apply {
                addFlags(
                    Intent.FLAG_ACTIVITY_NEW_TASK or
                        Intent.FLAG_ACTIVITY_REORDER_TO_FRONT or
                        Intent.FLAG_ACTIVITY_SINGLE_TOP or
                        Intent.FLAG_ACTIVITY_CLEAR_TOP
                )
            }
            startActivity(bringFrontIntent)
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
