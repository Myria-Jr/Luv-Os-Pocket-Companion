package com.example.luv_os

import android.content.Context
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "luv.os/hardware_bridge"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "triggerHeartbeatPulse" -> {
                        val intensity = call.argument<Double>("intensity") ?: 0.5
                        vibratePattern(longArrayOf(0, 45, 95, 75), (intensity * 255).toInt().coerceIn(40, 255))
                        result.success(true)
                    }
                    "triggerGlitchHapticBurst" -> {
                        vibratePattern(longArrayOf(0, 30, 40, 55, 35, 70), 255)
                        result.success(true)
                    }
                    "getDeviceName" -> {
                        result.success("${Build.MANUFACTURER} ${Build.MODEL}")
                    }
                    else -> result.notImplemented()
                }
            }
    }

    @Suppress("DEPRECATION")
    private fun vibratePattern(pattern: LongArray, amplitude: Int) {
        try {
            val vibrator = getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator ?: return
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val amplitudes = IntArray(pattern.size) { index -> if (index % 2 == 1) amplitude else 0 }
                vibrator.vibrate(VibrationEffect.createWaveform(pattern, amplitudes, -1))
            } else {
                vibrator.vibrate(pattern, -1)
            }
        } catch (_: Exception) {
        }
    }
}

