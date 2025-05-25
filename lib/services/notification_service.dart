import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:math';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
  FlutterLocalNotificationsPlugin();

  static final List<String> _motivationalMessagesEs = [
    "¡Recuerda hidratarte!",
    "El agua es vida, ¡toma un sorbo!",
    "Tu cuerpo necesita agua, ¡hidrátate ahora!",
    "¿Ya bebiste agua? ¡Es momento de hacerlo!",
    "Mantenerse hidratado mejora tu concentración",
    "Un poco de agua te ayudará a sentirte mejor",
    "Hidrátate para una piel más saludable",
    "¡Agua, el secreto para una mente clara!",
  ];

  static final List<String> _motivationalMessagesEn = [
    "Remember to hydrate!",
    "Water is life, take a sip!",
    "Your body needs water, hydrate now!",
    "Have you had water yet? It's time to do so!",
    "Staying hydrated improves your focus",
    "A bit of water will help you feel better",
    "Hydrate for healthier skin",
    "Water, the secret to a clear mind!",
  ];

  /**
   * Get a random motivational message based on language code
   */
  static String getRandomMessage(String languageCode) {
    final random = Random();
    if (languageCode == 'en') {
      return _motivationalMessagesEn[random.nextInt(_motivationalMessagesEn.length)];
    }
    return _motivationalMessagesEs[random.nextInt(_motivationalMessagesEs.length)];
  }

  /**
   * Initialize the notification service
   */
  static Future<void> init() async {
    try {
      // Initialize timezone
      tz.initializeTimeZones();

      // Initialize Android settings
      const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

      // General configuration (Android only)
      const InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
      );

      // Initialize plugin with configurations
      await _notifications.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _handleNotificationResponse,
      );

      print('Notification service initialized successfully');
    } catch (e) {
      print('Error initializing notification service: $e');
    }
  }

  /**
   * Handle notification response when user taps on notification
   */
  static void _handleNotificationResponse(NotificationResponse response) {
    print('Notification received: ${response.payload}');
  }

  /**
   * Request notification permissions
   */
  static Future<bool> requestPermissions() async {
    try {
      PermissionStatus status = await Permission.notification.status;
      print('Current notification permission status: $status');

      if (status.isDenied || status.isRestricted || status.isLimited) {
        status = await Permission.notification.request();
        print('New permission status after request: $status');
      }

      return status.isGranted;
    } catch (e) {
      print('Error requesting permissions: $e');
      return false;
    }
  }

  /**
   * Schedule water reminder notifications
   */
  static Future<void> scheduleReminders(int intervalMinutes) async {
    try {
      // Check permissions first
      final bool permissionsGranted = await requestPermissions();
      if (!permissionsGranted) {
        print('Notification permissions denied');
        return;
      }

      // Cancel all existing notifications
      await _notifications.cancelAll();

      // If interval is 0, don't schedule anything
      if (intervalMinutes <= 0) return;

      // Configure Android notification details
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'hydratrack_reminder',
        'Water Reminders',
        channelDescription: 'Reminders to drink water throughout the day',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );

      // General configuration (Android only)
      const NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
      );

      final int minutesInDay = 24 * 60;
      final int totalNotifications = minutesInDay ~/ intervalMinutes;

      // Get current language
      final String languageCode = tz.local.toString().contains('_')
          ? tz.local.toString().split('_')[0]
          : 'es';

      int scheduledCount = 0;
      for (int i = 1; i <= totalNotifications; i++) {
        final DateTime now = DateTime.now();
        final DateTime scheduledTime = now.add(Duration(minutes: i * intervalMinutes));

        // Only schedule notifications for today (not tomorrow)
        if (scheduledTime.day != now.day) continue;

        await _notifications.zonedSchedule(
          i, // Unique ID for each notification
          'HydraTrack', // Title
          getRandomMessage(languageCode), // Random message based on language
          tz.TZDateTime.from(scheduledTime, tz.local),
          platformDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
        );

        scheduledCount++;
        print('Notification scheduled for: $scheduledTime');
      }

      print('$scheduledCount reminders scheduled every $intervalMinutes minutes');
    } catch (e) {
      print('Error scheduling reminders: $e');
    }
  }

  /**
   * Cancel all scheduled reminders
   */
  static Future<void> cancelAllReminders() async {
    try {
      await _notifications.cancelAll();
      print('All notifications have been cancelled');
    } catch (e) {
      print('Error canceling notifications: $e');
    }
  }
}