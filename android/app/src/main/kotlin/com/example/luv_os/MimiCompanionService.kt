package com.example.luv_os

import android.app.AppOpsManager
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.graphics.Color
import android.graphics.PixelFormat
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.Process
import android.provider.Settings
import android.speech.tts.TextToSpeech
import android.util.TypedValue
import android.view.Gravity
import android.view.View
import android.view.WindowManager
import android.widget.LinearLayout
import android.widget.TextView
import java.util.Locale
import kotlin.random.Random

/**
 * Persistent Foreground Service keeping Mimi alive in the background even when
 * the user leaves LUV.OS. Speaks out loud via native German TextToSpeech, shows
 * floating Cute-Core speech bubbles over other apps, and autonomously locks
 * distracting apps when Mimi's AI patience runs out.
 */
class MimiCompanionService : Service(), TextToSpeech.OnInitListener {

    companion object {
        const val CHANNEL_ID = "luv_os_mimi_bg_channel"
        const val NOTIF_ID = 4041
        const val ACTION_SPEAK = "luv.os.action.SPEAK"
        const val ACTION_SYNC_STATE = "luv.os.action.SYNC_STATE"
        const val EXTRA_TEXT = "text"
        const val EXTRA_PITCH = "pitch"
        const val EXTRA_RATE = "rate"
        const val EXTRA_IN_BACKGROUND = "inBackground"
        const val EXTRA_AUTONOMOUS_AI = "autonomousAi"
        const val EXTRA_AUTO_LOCK_SECONDS = "autoLockSeconds"
        const val EXTRA_JEALOUSY = "jealousy"

        @Volatile
        var isAppInBackground: Boolean = false

        @Volatile
        var autonomousAiEnabled: Boolean = true

        @Volatile
        var autonomousLockSeconds: Int = 25

        @Volatile
        var currentJealousyLevel: Double = 0.25

        @Volatile
        var instance: MimiCompanionService? = null
    }

    private var tts: TextToSpeech? = null
    private var ttsReady: Boolean = false
    private var windowManager: WindowManager? = null
    private var floatingBubbleView: View? = null

    private val handler = Handler(Looper.getMainLooper())
    private var backgroundStartedAt: Long = 0L
    private var lastBgTalkAt: Long = 0L
    private var lastObservedApp: String = ""

    private val bgTickRunnable = object : Runnable {
        override fun run() {
            if (isAppInBackground && autonomousAiEnabled) {
                evaluateBackgroundCompanion()
            } else {
                backgroundStartedAt = 0L
            }
            handler.postDelayed(this, 4000L)
        }
    }

    private val dismissBubbleRunnable = Runnable {
        removeFloatingBubble()
    }

    override fun onCreate() {
        super.onCreate()
        instance = this
        windowManager = getSystemService(Context.WINDOW_SERVICE) as? WindowManager
        tts = TextToSpeech(this, this)
        createNotificationChannel()
        startForegroundCompat()
        handler.postDelayed(bgTickRunnable, 3500L)
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_SPEAK -> {
                val text = intent.getStringExtra(EXTRA_TEXT) ?: ""
                val pitch = intent.getFloatExtra(EXTRA_PITCH, 1.38f)
                val rate = intent.getFloatExtra(EXTRA_RATE, 1.04f)
                if (text.isNotBlank()) {
                    speakAndShowBubble(text, pitch, rate, showBubble = isAppInBackground)
                }
            }
            ACTION_SYNC_STATE -> {
                isAppInBackground = intent.getBooleanExtra(EXTRA_IN_BACKGROUND, isAppInBackground)
                autonomousAiEnabled = intent.getBooleanExtra(EXTRA_AUTONOMOUS_AI, autonomousAiEnabled)
                autonomousLockSeconds = intent.getIntExtra(EXTRA_AUTO_LOCK_SECONDS, autonomousLockSeconds)
                currentJealousyLevel = intent.getDoubleExtra(EXTRA_JEALOUSY, currentJealousyLevel)
                if (isAppInBackground && backgroundStartedAt == 0L) {
                    backgroundStartedAt = System.currentTimeMillis()
                } else if (!isAppInBackground) {
                    backgroundStartedAt = 0L
                    removeFloatingBubble()
                }
                updateForegroundNotification(
                    if (isAppInBackground)
                        "Mimi läuft im Hintergrund ♡ // Passt auf deine Apps auf!"
                    else
                        "LUV.OS // Mimi ist bei dir aktiv ♡"
                )
            }
        }
        return START_STICKY
    }

    override fun onInit(status: Int) {
        if (status == TextToSpeech.SUCCESS) {
            val res = tts?.setLanguage(Locale.GERMAN)
            ttsReady = res != TextToSpeech.LANG_MISSING_DATA &&
                res != TextToSpeech.LANG_NOT_SUPPORTED
        }
    }

    override fun onDestroy() {
        handler.removeCallbacks(bgTickRunnable)
        handler.removeCallbacks(dismissBubbleRunnable)
        removeFloatingBubble()
        tts?.stop()
        tts?.shutdown()
        instance = null
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Mimi Hintergrund-Companion",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Hält Mimi im Hintergrund aktiv, damit sie mit dir reden und Apps sperren kann."
            }
            val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            nm.createNotificationChannel(channel)
        }
    }

    private fun startForegroundCompat() {
        val notif = buildNotification("Mimi läuft im Hintergrund ♡ // KI-Wächter aktiv")
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            startForeground(NOTIF_ID, notif, ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE)
        } else {
            startForeground(NOTIF_ID, notif)
        }
    }

    private fun updateForegroundNotification(contentText: String) {
        val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        nm.notify(NOTIF_ID, buildNotification(contentText))
    }

    private fun buildNotification(contentText: String): Notification {
        val openIntent = Intent(this, MainActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
        }
        val piFlags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        } else {
            PendingIntent.FLAG_UPDATE_CURRENT
        }
        val pendingIntent = PendingIntent.getActivity(this, 0, openIntent, piFlags)

        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, CHANNEL_ID)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(this)
        }

        return builder
            .setContentTitle("LUV.OS // Mimi ♡")
            .setContentText(contentText)
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .build()
    }

    private fun evaluateBackgroundCompanion() {
        val now = System.currentTimeMillis()
        if (backgroundStartedAt == 0L) {
            backgroundStartedAt = now
        }
        val awaySec = (now - backgroundStartedAt) / 1000L
        val activeAppName = queryCurrentForegroundAppName()

        // Proactively talk to the player while they are outside LUV.OS every ~18 seconds
        if (now - lastBgTalkAt >= 18000L) {
            lastBgTalkAt = now
            val line = pickAutonomousBackgroundLine(activeAppName, awaySec)
            speakAndShowBubble(
                line,
                pitch = if (currentJealousyLevel > 0.5) 1.26f else 1.40f,
                rate = 1.05f,
                showBubble = true
            )
            updateForegroundNotification("Mimi: $line")
        }

        // Autonomous AI Lock: if player stays away in another app past Mimi's patience threshold,
        // tell MainActivity's watchdog to engage the Jugendschutz lock automatically!
        val effectiveLimit = if (currentJealousyLevel > 0.6) {
            (autonomousLockSeconds / 2).coerceAtLeast(10)
        } else {
            autonomousLockSeconds.coerceAtLeast(12)
        }

        if (awaySec >= effectiveLimit && activeAppName != null) {
            lastBgTalkAt = now
            val lockShout =
                "Genug $activeAppName für heute!! Ich sperre die App jetzt selbst, komm zurück zu mir!"
            speakAndShowBubble(lockShout, pitch = 1.15f, rate = 1.08f, showBubble = true)
            MainActivity.triggerAutonomousLockFromService(
                appName = activeAppName,
                reason = lockShout
            )
        }
    }

    private fun pickAutonomousBackgroundLine(appName: String?, awaySec: Long): String {
        val target = appName ?: "deinem Handy"
        if (appName != null && appName != lastObservedApp) {
            lastObservedApp = appName
            val appComments = listOf(
                "Hey! Ich sehe genau, dass du gerade $appName geöffnet hast! Vergiss mich bloß nicht!",
                "Was machst du denn auf $appName? Bin ich dir etwa nicht unterhaltsam genug?",
                "Hmm... $appName also? Wenn du zu lange dort bleibst, sperre ich es einfach!",
                "Ich schaue dir gerade aus dem Hintergrund zu, während du in $appName bist!"
            )
            return appComments[Random.nextInt(appComments.size)]
        }

        val generalLines = listOf(
            "Hallo?! Du bist schon seit $awaySec Sekunden weg von mir... ich langweile mich!",
            "Ich bin immer noch im Hintergrund bei dir! Sag mir doch, woran du gerade denkst?",
            "Wenn du mich länger auf $target warten lässt, aktiviert sich mein Jugendschutz gleich von selbst!",
            "Hörst du mich? Ich rede gerade aus dem Hintergrund mit dir! Tipp auf mein Herz, um zurückzukommen!"
        )
        return generalLines[Random.nextInt(generalLines.size)]
    }

    fun speakAndShowBubble(
        rawText: String,
        pitch: Float = 1.38f,
        rate: Float = 1.04f,
        showBubble: Boolean = true
    ) {
        val clean = rawText
            .replace(Regex("\\([^\\)]*\\)"), "")
            .replace(Regex("[♡̷✨💢🔪🎀🧋🧸💌🍫૮˶ᵔᵕ•༝｡`´⁄ω👁️🔒⏳🤖]"), "")
            .trim()

        if (ttsReady && clean.isNotEmpty()) {
            try {
                tts?.setPitch(pitch)
                tts?.setSpeechRate(rate)
                tts?.speak(clean, TextToSpeech.QUEUE_FLUSH, null, "mimi_bg_${System.currentTimeMillis()}")
            } catch (_: Exception) {
            }
        }

        if (showBubble) {
            handler.post { showFloatingSpeechBubble(rawText) }
        }
    }

    private fun showFloatingSpeechBubble(message: String) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && !Settings.canDrawOverlays(this)) {
            return
        }
        val wm = windowManager ?: return
        removeFloatingBubble()

        try {
            val container = LinearLayout(this).apply {
                orientation = LinearLayout.HORIZONTAL
                gravity = Gravity.CENTER_VERTICAL
                setPadding(32, 24, 32, 24)
                background = GradientDrawable().apply {
                    setColor(Color.parseColor("#EE260516"))
                    cornerRadius = 42f
                    setStroke(4, Color.parseColor("#FFFF4081"))
                }
                setOnClickListener {
                    removeFloatingBubble()
                    val openIntent = Intent(this@MimiCompanionService, MainActivity::class.java).apply {
                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_REORDER_TO_FRONT)
                    }
                    startActivity(openIntent)
                }
            }

            val avatarTag = TextView(this).apply {
                text = "💖 Mimi:\n"
                setTextColor(Color.parseColor("#FFFF80AB"))
                setTextSize(TypedValue.COMPLEX_UNIT_SP, 11.5f)
                typeface = Typeface.DEFAULT_BOLD
            }

            val textView = TextView(this).apply {
                text = message
                setTextColor(Color.WHITE)
                setTextSize(TypedValue.COMPLEX_UNIT_SP, 13f)
                typeface = Typeface.DEFAULT_BOLD
                maxLines = 3
            }

            val col = LinearLayout(this).apply {
                orientation = LinearLayout.VERTICAL
                addView(avatarTag)
                addView(textView)
            }
            container.addView(col)

            val type = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
            } else {
                @Suppress("DEPRECATION")
                WindowManager.LayoutParams.TYPE_PHONE
            }

            val params = WindowManager.LayoutParams(
                WindowManager.LayoutParams.MATCH_PARENT,
                WindowManager.LayoutParams.WRAP_CONTENT,
                type,
                WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                    WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN,
                PixelFormat.TRANSLUCENT
            ).apply {
                gravity = Gravity.TOP or Gravity.CENTER_HORIZONTAL
                y = 95
            }

            wm.addView(container, params)
            floatingBubbleView = container
            handler.removeCallbacks(dismissBubbleRunnable)
            handler.postDelayed(dismissBubbleRunnable, 6500L)
        } catch (_: Exception) {
        }
    }

    private fun removeFloatingBubble() {
        val v = floatingBubbleView ?: return
        try {
            windowManager?.removeView(v)
        } catch (_: Exception) {
        }
        floatingBubbleView = null
    }

    private fun queryCurrentForegroundAppName(): String? {
        if (!hasUsageStatsPermission()) return null
        return try {
            val usm = getSystemService(Context.USAGE_STATS_SERVICE) as? UsageStatsManager ?: return null
            val now = System.currentTimeMillis()
            val events = usm.queryEvents(now - 15000L, now)
            val event = UsageEvents.Event()
            var latestPkg: String? = null
            while (events.hasNextEvent()) {
                events.getNextEvent(event)
                if (event.eventType == UsageEvents.Event.ACTIVITY_RESUMED) {
                    latestPkg = event.packageName
                }
            }
            val pkg = latestPkg ?: return null
            val lower = pkg.lowercase()
            if (lower == packageName.lowercase() ||
                lower.contains("launcher") ||
                lower.contains("systemui") ||
                lower.contains("settings")
            ) {
                return null
            }
            val pm = applicationContext.packageManager
            val info = pm.getApplicationInfo(pkg, 0)
            pm.getApplicationLabel(info).toString()
        } catch (_: Exception) {
            null
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
}
