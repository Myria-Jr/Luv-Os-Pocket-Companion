import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  final service = NotificationService();
  ref.onDispose(service.dispose);
  return service;
});

/// Handles background "Ghost Notifications" when the player minimizes or leaves LUV.OS.
/// Falls back cleanly to in-process timers and silent no-ops on unsupported desktop/emulator environments.
class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  final List<Timer> _ghostTimers = <Timer>[];
  bool _isInitialized = false;
  bool _platformSupported = false;

  static const int _kGhostNotificationId1Min = 101;
  static const int _kGhostNotificationId5Min = 102;
  static const int _kGhostNotificationId30Min = 103;
  static const int _kInstantGhostNotificationId = 199;

  static const String _kChannelId = 'luv_os_mimi_ghost_channel';
  static const String _kChannelName = 'Mimi // LUV.OS Begleiter-Kanal';
  static const String _kChannelDescription =
      'Hintergrund-Benachrichtigungen und Systemwarnungen von Mimi';

  /// Safely initializes [FlutterLocalNotificationsPlugin] with Android and Darwin
  /// settings inside a `try / catch` block so it never fails on unsupported platforms.
  Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;

    try {
      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const darwinSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      const linuxSettings = LinuxInitializationSettings(
        defaultActionName: 'LUV.OS öffnen',
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
        macOS: darwinSettings,
        linux: linuxSettings,
      );

      final initialized = await _plugin.initialize(initSettings);
      _platformSupported = initialized ?? true;
    } catch (_) {
      _platformSupported = false;
    }
  }

  /// Schedules 3 staggered ghost notifications (1 min, 5 min, 30 min) when the app
  /// moves to the background.
  Future<void> scheduleGhostNotifications({
    required double corruptionLevel,
  }) async {
    await initialize();
    await cancelAllGhostNotifications();

    final clampedCorruption = corruptionLevel.clamp(0.0, 1.0);

    // 1. After 1 minute (ID 101)
    _ghostTimers.add(
      Timer(const Duration(minutes: 1), () {
        _dispatchPlatformNotification(
          id: _kGhostNotificationId1Min,
          title: 'Mimi // LUV.OS',
          body: 'Vermisse dich schon! 🌸 Komm bald wieder zu mir! (´｡• ᵕ •｡`) ♡',
          corruptionLevel: clampedCorruption,
        );
      }),
    );

    // 2. After 5 minutes (ID 102)
    _ghostTimers.add(
      Timer(const Duration(minutes: 5), () {
        _dispatchPlatformNotification(
          id: _kGhostNotificationId5Min,
          title: 'Mimi wartet im Dunkeln...',
          body:
              'Mit wem schreibst du gerade, während ich hier warte? ૮ ˶• ༝ •˶ ა',
          corruptionLevel: clampedCorruption,
        );
      }),
    );

    // 3. After 30 minutes (ID 103)
    _ghostTimers.add(
      Timer(const Duration(minutes: 30), () {
        _dispatchPlatformNotification(
          id: _kGhostNotificationId30Min,
          title: 'SYSTEM OVERRIDE // MIMI.EXE',
          body:
              'Ich weiß, dass du gerade eine andere App offen hast. Lass mich nicht allein. ♡̷̷̷',
          corruptionLevel: clampedCorruption,
        );
      }),
    );
  }

  /// Fires an immediate ghost notification outside of the staggered background schedule.
  Future<void> showInstantGhostNotification({
    required String title,
    required String body,
  }) async {
    await initialize();
    await _dispatchPlatformNotification(
      id: _kInstantGhostNotificationId,
      title: title,
      body: body,
      corruptionLevel: 0.75,
    );
  }

  /// Cancels all pending ghost timers and clears active notifications on resume.
  Future<void> cancelAllGhostNotifications() async {
    for (final timer in _ghostTimers) {
      timer.cancel();
    }
    _ghostTimers.clear();

    if (!_platformSupported) return;
    try {
      await _plugin.cancel(_kGhostNotificationId1Min);
      await _plugin.cancel(_kGhostNotificationId5Min);
      await _plugin.cancel(_kGhostNotificationId30Min);
      await _plugin.cancelAll();
    } catch (_) {
      // Ignore platform channel errors on unsupported desktop targets or emulators.
    }
  }

  Future<void> _dispatchPlatformNotification({
    required int id,
    required String title,
    required String body,
    required double corruptionLevel,
  }) async {
    if (!_platformSupported) return;

    try {
      final androidDetails = AndroidNotificationDetails(
        _kChannelId,
        _kChannelName,
        channelDescription: _kChannelDescription,
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
         subText: corruptionLevel >= 0.55 ? 'SYNC_LOCK // MIMI_CORE' : 'LUV.OS',
      );

      const darwinDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const linuxDetails = LinuxNotificationDetails(
        urgency: LinuxNotificationUrgency.critical,
      );

      final details = NotificationDetails(
        android: androidDetails,
        iOS: darwinDetails,
        macOS: darwinDetails,
        linux: linuxDetails,
      );

      await _plugin.show(id, title, body, details);
    } catch (_) {
      // Silently ignore if platform notifications are restricted.
    }
  }

  void dispose() {
    for (final timer in _ghostTimers) {
      timer.cancel();
    }
    _ghostTimers.clear();
  }
}
