import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  // Channel definitions for Android
  static const String _turnChannelId = 'digiqueue_turn_channel';
  static const String _turnChannelName = 'Queue Turn Alerts';
  static const String _turnChannelDesc =
      'High priority alerts when it is your turn to be served';

  static const String _appointmentChannelId = 'digiqueue_appointment_channel';
  static const String _appointmentChannelName = 'Appointment Updates';
  static const String _appointmentChannelDesc =
      'Notifications for appointment replies and status changes';

  /// Initialize notifications on app launch
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Android Settings
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS / macOS Settings
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // Linux Settings
    const linuxSettings =
        LinuxInitializationSettings(defaultActionName: 'Open DigiQueue');

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
      linux: linuxSettings,
    );

    try {
      await _notificationsPlugin.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          debugPrint('Notification clicked with payload: ${response.payload}');
        },
      );

      // Create Android Notification Channels
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        final androidPlugin = _notificationsPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();

        if (androidPlugin != null) {
          await androidPlugin.createNotificationChannel(
            const AndroidNotificationChannel(
              _turnChannelId,
              _turnChannelName,
              description: _turnChannelDesc,
              importance: Importance.max,
              enableVibration: true,
              playSound: true,
            ),
          );

          await androidPlugin.createNotificationChannel(
            const AndroidNotificationChannel(
              _appointmentChannelId,
              _appointmentChannelName,
              description: _appointmentChannelDesc,
              importance: Importance.high,
              enableVibration: true,
              playSound: true,
            ),
          );
        }
      }

      _isInitialized = true;
    } catch (e) {
      debugPrint('Notification initialization error: $e');
    }
  }

  /// Request runtime permissions (required for Android 13+ and iOS)
  Future<bool> requestPermissions() async {
    try {
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        final androidPlugin = _notificationsPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        final granted = await androidPlugin?.requestNotificationsPermission();
        return granted ?? false;
      } else if (!kIsWeb &&
          (defaultTargetPlatform == TargetPlatform.iOS ||
              defaultTargetPlatform == TargetPlatform.macOS)) {
        final iosPlugin = _notificationsPlugin
            .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>();
        final granted = await iosPlugin?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return granted ?? false;
      }
    } catch (e) {
      debugPrint('Error requesting notification permissions: $e');
    }
    return false;
  }

  /// Show high-priority "It's Your Turn!" notification
  Future<void> showTurnNotification({
    required String professorName,
    required String roomNumber,
    required int tokenNumber,
  }) async {
    // Trigger tactile haptic feedback
    try {
      await HapticFeedback.heavyImpact();
    } catch (_) {}

    const androidDetails = AndroidNotificationDetails(
      _turnChannelId,
      _turnChannelName,
      channelDescription: _turnChannelDesc,
      importance: Importance.max,
      priority: Priority.max,
      fullScreenIntent: true,
      enableVibration: true,
      playSound: true,
      icon: '@mipmap/ic_launcher',
    );

    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
    );

    try {
      await _notificationsPlugin.show(
        id: 1001, // Unique ID for turn notifications
        title: "🔔 It's Your Turn! (Token #$tokenNumber)",
        body:
            'Prof. $professorName is ready for you in $roomNumber. Head to the office now!',
        notificationDetails: details,
        payload: 'turn_notification',
      );
    } catch (e) {
      debugPrint('Error showing turn notification: $e');
    }
  }

  /// Show Appointment Reply / Status Update notification
  Future<void> showAppointmentNotification({
    required String title,
    required String body,
    String? payload,
    int? notificationId,
  }) async {
    try {
      await HapticFeedback.mediumImpact();
    } catch (_) {}

    const androidDetails = AndroidNotificationDetails(
      _appointmentChannelId,
      _appointmentChannelName,
      channelDescription: _appointmentChannelDesc,
      importance: Importance.high,
      priority: Priority.high,
      enableVibration: true,
      playSound: true,
      icon: '@mipmap/ic_launcher',
    );

    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
    );

    try {
      final id =
          notificationId ?? DateTime.now().millisecondsSinceEpoch ~/ 1000;
      await _notificationsPlugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: details,
        payload: payload ?? 'appointment_notification',
      );
    } catch (e) {
      debugPrint('Error showing appointment notification: $e');
    }
  }

  /// Show Queue Hold notification
  Future<void> showQueueHoldNotification({
    required String professorName,
    required int minutes,
  }) async {
    try {
      await HapticFeedback.mediumImpact();
    } catch (_) {}

    const androidDetails = AndroidNotificationDetails(
      _turnChannelId,
      _turnChannelName,
      channelDescription: _turnChannelDesc,
      importance: Importance.high,
      priority: Priority.high,
      enableVibration: true,
      playSound: true,
      icon: '@mipmap/ic_launcher',
    );

    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
    );

    try {
      await _notificationsPlugin.show(
        id: 1002,
        title: '⏸️ Queue On Hold',
        body:
            'Prof. $professorName placed the queue on hold for $minutes minutes. Please wait nearby.',
        notificationDetails: details,
        payload: 'hold_notification',
      );
    } catch (e) {
      debugPrint('Error showing hold notification: $e');
    }
  }
}
