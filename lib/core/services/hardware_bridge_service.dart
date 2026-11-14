import 'dart:async';
import 'dart:math' as math;
import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../../state/corruption_provider.dart';
import './notification_service.dart';

final hardwareBridgeProvider = Provider<HardwareBridgeService>((ref) {
  final corruptionController = ref.read(corruptionProvider.notifier);
  final notificationService = ref.read(notificationServiceProvider);
  final initialCorruption = ref.read(corruptionProvider).corruptionLevel;

  final service = HardwareBridgeService(
    corruptionController: corruptionController,
    notificationService: notificationService,
    initialCorruptionLevel: initialCorruption,
  );

  service.initialize();

  ref.listen<CorruptionState>(
    corruptionProvider,
    (previous, next) {
      service.syncCorruptionLevel(next.corruptionLevel);
      if (previous?.appLockActive != next.appLockActive ||
          previous?.remainingHeadpatsToUnlock !=
              next.remainingHeadpatsToUnlock) {
        service.syncAppLockToNative(
          locked: next.appLockActive,
          blockedCategories: next.blockedAppCategories,
          reason: next.liveLockBannerText,
          requiredHeadpats: next.remainingHeadpatsToUnlock,
        );
      }
      if (next.pendingLiveNotification.isNotEmpty &&
          previous?.pendingLiveNotification != next.pendingLiveNotification) {
        notificationService.showLiveMimiStatusNotification(
          message: next.pendingLiveNotification,
          isLocked: next.appLockActive,
        );
      }
    },
  );

  ref.onDispose(service.dispose);
  return service;
});

/// Native Hardware & Sensor Bridge for LUV.OS // Pocket Companion.
///
/// Connects battery state, accelerometer tilt/steadiness, system clock anti-cheat
/// verification, app lifecycle tracking, and the procedural Lub-Dub haptic engine
/// to [CorruptionController] with resilient fallbacks for emulators and desktop.
class HardwareBridgeService with WidgetsBindingObserver {
  final CorruptionController corruptionController;
  final NotificationService notificationService;

  final Battery _battery = Battery();
  final Stopwatch _monotonicWatch = Stopwatch();
  static const MethodChannel _nativeChannel =
      MethodChannel('luv.os/hardware_bridge');
  DateTime _wallClockAnchor = DateTime.now();

  Timer? _systemMonitorTimer;
  Timer? _heartbeatTimer;
  StreamSubscription<BatteryState>? _batteryStateSubscription;
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;

  final List<double> _accelMagnitudeWindow = <double>[];
  static const int _kAccelWindowSize = 18;
  static const double _kSteadyVarianceThreshold = 0.22;
  static const int _kClockTamperThresholdSeconds = 90;

  bool _isInitialized = false;
  bool _isDisposed = false;
  bool _isAppActive = true;
  bool _batteryOverrideActive = false;

  DateTime? _pausedAt;
  DateTime _lastSensorPushAt = DateTime.fromMillisecondsSinceEpoch(0);

  double _currentCorruptionLevel;
  int _currentHeartbeatIntervalMs = 0;

  int _batteryLevel = 84;
  bool _isCharging = false;
  double _tiltX = 0.0;
  double _tiltY = 0.0;
  bool _isDeviceSteady = true;
  bool _isNightTime = false;
  bool _timeTamperDetected = false;
  int _lastAwayMinutes = 0;

  HardwareBridgeService({
    required this.corruptionController,
    required this.notificationService,
    double initialCorruptionLevel = 0.08,
  }) : _currentCorruptionLevel = initialCorruptionLevel.clamp(0.0, 1.0);

  /// Starts all hardware listeners, anti-cheat clock monitors, lifecycle observers,
  /// and haptic heartbeat loops. Safe to call multiple times.
  Future<void> initialize() async {
    if (_isInitialized || _isDisposed) return;
    _isInitialized = true;

    try {
      WidgetsBinding.instance.addObserver(this);
    } catch (_) {
      // Safeguard if binding is not yet initialized in isolated test environments.
    }

    await notificationService.initialize();

    _nativeChannel.setMethodCallHandler((call) async {
      if (call.method == 'onBlockedAppIntercepted') {
        final args = call.arguments;
        if (args is Map) {
          final category = (args['category'] ?? 'TikTok').toString();
          await corruptionController.recordInterceptedAppAttempt(category);
        }
      }
    });

    _wallClockAnchor = DateTime.now();
    _monotonicWatch
      ..reset()
      ..start();

    _evaluateNightMode();
    await _initBatteryMonitoring();
    _initAccelerometerMonitoring();
    _startSystemMonitorLoop();
    _reconfigureHeartbeatLoop();
    await _pushHardwareSnapshot();
  }

  /// Synchronizes the current corruption level with the Haptic Heartbeat Engine.
  void syncCorruptionLevel(double corruptionLevel) {
    if (_isDisposed) return;
    final clamped = corruptionLevel.clamp(0.0, 1.0);
    if ((clamped - _currentCorruptionLevel).abs() < 0.005) return;
    _currentCorruptionLevel = clamped;
    _reconfigureHeartbeatLoop();
  }

  Future<void> _initBatteryMonitoring() async {
    try {
      final level = await _battery.batteryLevel;
      if (!_batteryOverrideActive && level >= 0 && level <= 100) {
        _batteryLevel = level;
      }
    } catch (_) {
      // Fallback for emulators or desktop platforms without battery reporting.
    }

    try {
      final initialState = await _battery.batteryState;
      if (!_batteryOverrideActive) {
        _isCharging = initialState == BatteryState.charging ||
            initialState == BatteryState.full;
      }
    } catch (_) {
      // Ignore if battery state query is unsupported.
    }

    try {
      _batteryStateSubscription = _battery.onBatteryStateChanged.listen(
        (BatteryState state) async {
          if (_isDisposed) return;
          _batteryOverrideActive = false;
          final charging =
              state == BatteryState.charging || state == BatteryState.full;
          if (_isCharging != charging) {
            _isCharging = charging;
            await _refreshBatteryLevel();
            await _pushHardwareSnapshot();
          }
        },
        onError: (_) {
          // Suppress stream errors on emulators without battery services.
        },
        cancelOnError: false,
      );
    } catch (_) {
      // Fallback if battery state stream cannot be opened.
    }
  }

  Future<void> _refreshBatteryLevel() async {
    if (_batteryOverrideActive) return;
    try {
      final level = await _battery.batteryLevel;
      if (level >= 0 && level <= 100) {
        _batteryLevel = level;
      }
    } catch (_) {
      // Keep last known or default emulator battery level.
    }
  }

  void _initAccelerometerMonitoring() {
    try {
      _accelerometerSubscription = accelerometerEventStream().listen(
        (AccelerometerEvent event) {
          if (_isDisposed || !_isAppActive) return;

          final x = event.x;
          final y = event.y;
          final z = event.z;

          // Calculate pitch/roll tilt in degrees (-45.0 to 45.0)
          final rawTiltX =
              math.atan2(x, math.sqrt(y * y + z * z)) * (180.0 / math.pi);
          final rawTiltY =
              math.atan2(y, math.sqrt(x * x + z * z)) * (180.0 / math.pi);

          _tiltX = rawTiltX.clamp(-45.0, 45.0);
          _tiltY = rawTiltY.clamp(-45.0, 45.0);

          // Compute acceleration magnitude variance to determine if hand is steady
          final magnitude = math.sqrt(x * x + y * y + z * z);
          _accelMagnitudeWindow.add(magnitude);
          if (_accelMagnitudeWindow.length > _kAccelWindowSize) {
            _accelMagnitudeWindow.removeAt(0);
          }

          if (_accelMagnitudeWindow.length >= 4) {
            var sum = 0.0;
            for (final sample in _accelMagnitudeWindow) {
              sum += sample;
            }
            final mean = sum / _accelMagnitudeWindow.length;

            var varianceSum = 0.0;
            for (final sample in _accelMagnitudeWindow) {
              final diff = sample - mean;
              varianceSum += diff * diff;
            }
            final variance = varianceSum / _accelMagnitudeWindow.length;
            _isDeviceSteady = variance < _kSteadyVarianceThreshold;
          }

          final now = DateTime.now();
          if (now.difference(_lastSensorPushAt).inMilliseconds >= 350) {
            _lastSensorPushAt = now;
            _pushHardwareSnapshot();
          }
        },
        onError: (_) {
          // Emulators without hardware sensors stay smoothly in steady default state.
          _isDeviceSteady = true;
        },
        cancelOnError: false,
      );
    } catch (_) {
      _isDeviceSteady = true;
    }
  }

  void _startSystemMonitorLoop() {
    _systemMonitorTimer?.cancel();
    _systemMonitorTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      if (_isDisposed || !_isAppActive) return;

      // 1. Anti-Cheat Clock Tamper Detection: compare wall clock vs monotonic Stopwatch
      final now = DateTime.now();
      final wallElapsedSeconds = now.difference(_wallClockAnchor).inSeconds;
      final monoElapsedSeconds = _monotonicWatch.elapsed.inSeconds;
      final driftSeconds = (wallElapsedSeconds - monoElapsedSeconds).abs();

      if (driftSeconds > _kClockTamperThresholdSeconds) {
        _timeTamperDetected = true;
        _wallClockAnchor = now;
        _monotonicWatch
          ..reset()
          ..start();
        await triggerGlitchBurstHaptic();
        await corruptionController.reportTimeTamper(driftSeconds);
      }

      // 2. Check Night-Mode (23:00 - 04:59)
      _evaluateNightMode();

      // 3. Refresh Battery Level
      await _refreshBatteryLevel();

      // 4. Synchronize Snapshot with CorruptionController
      await _pushHardwareSnapshot();
    });
  }

  void _evaluateNightMode() {
    final hour = DateTime.now().hour;
    _isNightTime = hour >= 23 || hour < 5;
  }

  Future<void> _pushHardwareSnapshot() async {
    if (_isDisposed) return;
    final currentHw = corruptionController.currentState.hardware;
    final snapshot = currentHw.copyWith(
      batteryLevel: _batteryLevel,
      isCharging: _isCharging,
      tiltX: _tiltX,
      tiltY: _tiltY,
      isDeviceSteady: _isDeviceSteady,
      isNightTime: _isNightTime,
      timeTamperDetected: _timeTamperDetected,
      lastAwayMinutes: _lastAwayMinutes,
    );
    await corruptionController.updateHardwareSnapshot(snapshot);
  }

  // ===========================================================================
  // HAPTIK-ENGINE (HEARTBEAT & GLITCH PULSES)
  // ===========================================================================

  void _reconfigureHeartbeatLoop() {
    if (_isDisposed || !_isAppActive || _currentCorruptionLevel < 0.25) {
      _heartbeatTimer?.cancel();
      _heartbeatTimer = null;
      _currentHeartbeatIntervalMs = 0;
      return;
    }

    // Scale interval proportionally from 2400ms at corruption 0.25 down to 680ms at 1.0
    final normalized =
        ((_currentCorruptionLevel - 0.25) / 0.75).clamp(0.0, 1.0);
    final targetIntervalMs =
        (2400 - (normalized * (2400 - 680))).round().clamp(680, 2400);

    // Avoid resetting the timer if the interval hasn't shifted by at least 60ms
    if (_heartbeatTimer != null &&
        (_currentHeartbeatIntervalMs - targetIntervalMs).abs() < 60) {
      return;
    }

    _currentHeartbeatIntervalMs = targetIntervalMs;
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(
      Duration(milliseconds: targetIntervalMs),
      (_) {
        if (_isDisposed || !_isAppActive || _currentCorruptionLevel < 0.25) {
          return;
        }
        triggerHeartbeatBurst();
      },
    );
  }

  /// Gentle tactile click for cute interactions and UI buttons.
  Future<void> triggerCuteTapHaptic() async {
    try {
      await HapticFeedback.selectionClick();
    } catch (_) {
      // No-op on platforms without haptic motor.
    }
  }

  /// Manual or periodic "Lub-Dub" double pulse (mediumImpact -> 140ms -> heavyImpact).
  Future<void> triggerHeartbeatBurst() async {
    if (_isDisposed) return;
    try {
      await HapticFeedback.mediumImpact();
      await Future<void>.delayed(const Duration(milliseconds: 140));
      if (_isDisposed) return;
      await HapticFeedback.heavyImpact();
    } catch (_) {
      // No-op on platforms without haptic motor.
    }
  }

  /// Stuttered triple vibration burst for shader glitches, scares, and tamper alerts.
  Future<void> triggerGlitchBurstHaptic() async {
    if (_isDisposed) return;
    try {
      await HapticFeedback.heavyImpact();
      await Future<void>.delayed(const Duration(milliseconds: 55));
      if (_isDisposed) return;
      await HapticFeedback.vibrate();
      await Future<void>.delayed(const Duration(milliseconds: 65));
      if (_isDisposed) return;
      await HapticFeedback.heavyImpact();
    } catch (_) {
      // No-op on platforms without haptic motor.
    }
  }

  // ===========================================================================
  // APP LIFECYCLE OBSERVER (GHOST NOTIFICATIONS & AWAY DURATION)
  // ===========================================================================

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_isDisposed) return;

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      if (_isAppActive) {
        _isAppActive = false;
        _pausedAt = DateTime.now();
        _monotonicWatch.stop();
        _reconfigureHeartbeatLoop();
        notificationService.showLiveMimiStatusNotification(
          message:
              'Mimi läuft im Hintergrund ♡ // Aufmerksamkeits-Wächter aktiv! Geh bloß nicht auf TikTok!',
          isLocked: corruptionController.currentState.appLockActive,
        );
        notificationService.scheduleGhostNotifications(
          corruptionLevel: _currentCorruptionLevel,
        );
      }
    } else if (state == AppLifecycleState.resumed) {
      _isAppActive = true;
      notificationService.cancelAllGhostNotifications();

      // Re-anchor monotonic anti-cheat clock after returning from background
      _wallClockAnchor = DateTime.now();
      _monotonicWatch
        ..reset()
        ..start();

      if (_pausedAt != null) {
        final awayDuration = DateTime.now().difference(_pausedAt!);
        _pausedAt = null;
        _lastAwayMinutes = awayDuration.inMinutes;
        corruptionController.handleAppAwayDuration(awayDuration);
      }

      _evaluateNightMode();
      _reconfigureHeartbeatLoop();
      _pushHardwareSnapshot();
    }
  }

  // ===========================================================================
  // EMULATOR & TESTING SIMULATION HELPERS
  // ===========================================================================

  /// Simulates a critical low-battery state (14%, unplugged) for testing Mimi's panic response.
  Future<void> simulateLowBatteryPanic() async {
    if (_isDisposed) return;
    _batteryOverrideActive = true;
    _batteryLevel = 14;
    _isCharging = false;
    await triggerHeartbeatBurst();
    await _pushHardwareSnapshot();
  }

  /// Simulates a 1-hour system clock manipulation to trigger Mimi's Chrono-Lock anti-cheat.
  Future<void> simulateTimeTravelTamper() async {
    if (_isDisposed) return;
    _timeTamperDetected = true;
    _wallClockAnchor = DateTime.now();
    _monotonicWatch
      ..reset()
      ..start();
    await triggerGlitchBurstHaptic();
    await corruptionController.reportTimeTamper(3600);
  }

  /// Simulates physical device tilt angles in degrees (-45.0 to 45.0) for parallax and sensor logs.
  Future<void> simulateDeviceTilt(double degX, double degY) async {
    if (_isDisposed) return;
    _tiltX = degX.clamp(-45.0, 45.0);
    _tiltY = degY.clamp(-45.0, 45.0);
    _isDeviceSteady = degX.abs() < 12.0 && degY.abs() < 12.0;
    await triggerCuteTapHaptic();
    await _pushHardwareSnapshot();
  }

  /// Synchronizes Mimi's V3 App-Locker state with the native Android UsageStats watchdog.
  Future<void> syncAppLockToNative({
    required bool locked,
    required List<String> blockedCategories,
    required String reason,
    required int requiredHeadpats,
  }) async {
    try {
      await _nativeChannel.invokeMethod<bool>('setAppLockState', {
        'locked': locked,
        'blockedCategories': blockedCategories,
        'reason': reason,
        'requiredHeadpats': requiredHeadpats,
      });
    } catch (_) {
      // Ignored on desktop/web test targets.
    }
  }

  /// Checks whether the user has granted Android Usage Access (`PACKAGE_USAGE_STATS`)
  /// so Mimi can intercept TikTok/Instagram/YouTube in real time.
  Future<bool> checkUsageStatsPermission() async {
    try {
      final granted =
          await _nativeChannel.invokeMethod<bool>('checkUsageStatsPermission');
      return granted ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Opens Android's Usage Access settings page so the player can grant Mimi
  /// foreground app interception privileges.
  Future<void> openUsageStatsSettings() async {
    try {
      await _nativeChannel.invokeMethod<bool>('openUsageStatsSettings');
    } catch (_) {
      // Ignored on non-Android platforms.
    }
  }

  /// Checks whether `SYSTEM_ALERT_WINDOW` ("Über anderen Apps einblenden") is granted.
  Future<bool> checkOverlayPermission() async {
    try {
      final granted =
          await _nativeChannel.invokeMethod<bool>('checkOverlayPermission');
      return granted ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Opens Android's Overlay Permission screen ("Über anderen Apps einblenden").
  Future<void> openOverlaySettings() async {
    try {
      await _nativeChannel.invokeMethod<bool>('openOverlaySettings');
    } catch (_) {
      // Ignored on non-Android platforms.
    }
  }

  /// Enables or disables Mimi's background guardian watchdog when the user leaves the app.
  Future<void> setBackgroundGuardian(bool enabled) async {
    try {
      await _nativeChannel
          .invokeMethod<bool>('setBackgroundGuardian', {'enabled': enabled});
    } catch (_) {}
  }

  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    _systemMonitorTimer?.cancel();
    _heartbeatTimer?.cancel();
    _batteryStateSubscription?.cancel();
    _accelerometerSubscription?.cancel();
    _monotonicWatch.stop();
    try {
      WidgetsBinding.instance.removeObserver(this);
    } catch (_) {
      // Ignore if observer removal occurs after binding teardown.
    }
  }
}
