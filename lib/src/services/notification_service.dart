import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:workmanager/workmanager.dart';

import 'local_storage_service.dart';

const _workoutReminderTask = 'workout_reminder_task';
const _notificationId = 42;

/// Called by WorkManager in the background (top-level, not a closure).
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    if (taskName != _workoutReminderTask) return true;

    await LocalStorageService.init();
    final session = LocalStorageService.getActiveSession();
    if (session == null) return true; // workout finished – no notification needed

    await NotificationService._showReminderNotification();
    return true;
  });
}

abstract final class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static bool get _supported => !kIsWeb && (Platform.isIOS || Platform.isAndroid || Platform.isMacOS);

  static Future<void> init() async {
    if (!_supported) return;

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const macos = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios, macOS: macos),
    );
    _initialized = true;

    if (!kIsWeb && (Platform.isIOS || Platform.isAndroid)) {
      await Workmanager().initialize(callbackDispatcher);
      await requestPermission();
    }
  }

  static Future<bool> requestPermission() async {
    if (!_supported) return false;
    if (Platform.isIOS || Platform.isMacOS) {
      final granted = await _plugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      return granted ?? false;
    }
    if (Platform.isAndroid) {
      final granted = await _plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      return granted ?? false;
    }
    return false;
  }

  /// Schedule a repeating background reminder every 15 minutes.
  static Future<void> scheduleWorkoutReminder() async {
    if (!_supported) return;
    if (!LocalStorageService.getNotificationsEnabled()) return;
    if (!kIsWeb && (Platform.isIOS || Platform.isAndroid)) {
      await Workmanager().registerPeriodicTask(
        _workoutReminderTask,
        _workoutReminderTask,
        frequency: const Duration(minutes: 15),
        initialDelay: const Duration(minutes: 15),
        existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
        constraints: Constraints(networkType: NetworkType.notRequired),
      );
    }
  }

  /// Cancel the background reminder (called when workout finishes or is cancelled).
  static Future<void> cancelWorkoutReminder() async {
    if (!_supported) return;
    if (!kIsWeb && (Platform.isIOS || Platform.isAndroid)) {
      await Workmanager().cancelByUniqueName(_workoutReminderTask);
    }
    await _plugin.cancel(_notificationId);
  }

  static Future<void> _showReminderNotification() async {
    if (!_initialized) {
      await _plugin.initialize(
        const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(),
          macOS: DarwinInitializationSettings(),
        ),
      );
      _initialized = true;
    }

    const android = AndroidNotificationDetails(
      'workout_reminder',
      'Workout Reminders',
      channelDescription: 'Reminds you when a workout is still open',
      importance: Importance.high,
      priority: Priority.high,
      ongoing: false,
    );
    const ios = DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
      presentBadge: false,
    );

    await _plugin.show(
      _notificationId,
      'Still training? 💪',
      'You have an open workout. Tap to continue or finish it.',
      const NotificationDetails(android: android, iOS: ios, macOS: ios),
    );
  }
}
