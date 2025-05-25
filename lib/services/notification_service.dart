import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:math';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
  FlutterLocalNotificationsPlugin();

  static bool _isInitialized = false;

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
      if (_isInitialized) return;

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

      _isInitialized = true;
      print('Notification service initialized successfully');
    } catch (e) {
      print('Error initializing notification service: $e');
      _isInitialized = false;
    }
  }

  /**
   * Handle notification response when user taps on notification
   */
  static void _handleNotificationResponse(NotificationResponse response) {
    print('Notification received: ${response.payload}');
  }

  /**
   * Request notification permissions with proper dialog
   */
  static Future<bool> requestPermissions() async {
    try {
      // Primero verificar si el servicio está inicializado
      if (!_isInitialized) {
        await init();
      }

      // Usar el plugin de notificaciones locales para solicitar permisos
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
      _notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

      if (androidImplementation != null) {
        // Solicitar permisos de notificación exacta (Android 13+)
        final bool? exactAlarmGranted = await androidImplementation.requestExactAlarmsPermission();
        print('Exact alarm permission: $exactAlarmGranted');

        // Solicitar permisos de notificación
        final bool? notificationGranted = await androidImplementation.requestNotificationsPermission();
        print('Notification permission: $notificationGranted');

        return notificationGranted ?? false;
      }

      // Fallback usando permission_handler
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
      // Verificar que el servicio esté inicializado
      if (!_isInitialized) {
        print('Notification service not initialized');
        return;
      }

      // Check permissions first
      final bool permissionsGranted = await requestPermissions();
      if (!permissionsGranted) {
        print('Notification permissions denied');
        return;
      }

      // Cancel all existing notifications SOLO si tenemos permisos
      try {
        await _notifications.cancelAll();
        print('Previous notifications cancelled');
      } catch (e) {
        print('Error cancelling notifications (this is OK on first run): $e');
      }

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
        enableVibration: true,
        playSound: true,
      );

      // General configuration (Android only)
      const NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
      );

      // Schedule notifications only for the next 24 hours
      final DateTime now = DateTime.now();
      final DateTime tomorrow = DateTime(now.year, now.month, now.day + 1);

      int scheduledCount = 0;
      int notificationId = 1;

      // Programar notificaciones cada X minutos hasta mañana
      DateTime nextNotification = now.add(Duration(minutes: intervalMinutes));

      while (nextNotification.isBefore(tomorrow) && scheduledCount < 50) { // Límite de seguridad
        // Get current language (simplificado)
        const String languageCode = 'es'; // Por ahora usar español por defecto

        await _notifications.zonedSchedule(
          notificationId,
          'HydraTrack',
          getRandomMessage(languageCode),
          tz.TZDateTime.from(nextNotification, tz.local),
          platformDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: null,
        );

        print('Notification $notificationId scheduled for: $nextNotification');

        scheduledCount++;
        notificationId++;
        nextNotification = nextNotification.add(Duration(minutes: intervalMinutes));
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
      if (!_isInitialized) {
        print('Notification service not initialized');
        return;
      }

      await _notifications.cancelAll();
      print('All notifications have been cancelled');
    } catch (e) {
      print('Error canceling notifications: $e');
    }
  }

  /**
   * Check if notifications are enabled
   */
  static Future<bool> areNotificationsEnabled() async {
    try {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
      _notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

      if (androidImplementation != null) {
        final bool? enabled = await androidImplementation.areNotificationsEnabled();
        return enabled ?? false;
      }

      return false;
    } catch (e) {
      print('Error checking notification status: $e');
      return false;
    }
  }
}