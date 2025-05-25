import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:math';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

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

      print('Initializing notification service...');

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
      final bool? initialized = await _notifications.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _handleNotificationResponse,
      );

      _isInitialized = initialized ?? false;
      print('Notification service initialized: $_isInitialized');
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
   * Request notification permissions - SIMPLIFICADO
   */
  static Future<bool> requestPermissions() async {
    try {
      print('Requesting notification permissions...');

      // Asegurar que el servicio esté inicializado
      if (!_isInitialized) {
        await init();
        if (!_isInitialized) {
          print('Failed to initialize notification service');
          return false;
        }
      }

      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
      _notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

      if (androidImplementation == null) {
        print('Android implementation not found');
        return false;
      }

      // Primero verificar si ya tenemos permisos
      final bool? alreadyEnabled = await androidImplementation.areNotificationsEnabled();
      print('Notifications already enabled: $alreadyEnabled');

      if (alreadyEnabled == true) {
        return true;
      }

      // Solicitar permisos de notificación (esto debería mostrar el diálogo nativo)
      print('Requesting notification permission...');
      final bool? notificationPermission = await androidImplementation.requestNotificationsPermission();
      print('Notification permission result: $notificationPermission');

      // Para Android 12+ solicitar permisos de alarma exacta si es necesario
      try {
        print('Requesting exact alarms permission...');
        final bool? exactAlarmPermission = await androidImplementation.requestExactAlarmsPermission();
        print('Exact alarm permission result: $exactAlarmPermission');
      } catch (e) {
        print('Exact alarm permission error (this is OK on older Android versions): $e');
      }

      return notificationPermission ?? false;
    } catch (e) {
      print('Error requesting permissions: $e');
      return false;
    }
  }

  /**
   * Check if notifications are enabled
   */
  static Future<bool> areNotificationsEnabled() async {
    try {
      if (!_isInitialized) {
        print('Service not initialized, cannot check permissions');
        return false;
      }

      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
      _notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

      if (androidImplementation != null) {
        final bool? enabled = await androidImplementation.areNotificationsEnabled();
        print('Notifications enabled status: $enabled');
        return enabled ?? false;
      }

      return false;
    } catch (e) {
      print('Error checking notification status: $e');
      return false;
    }
  }

  /**
   * Schedule water reminder notifications
   */
  static Future<void> scheduleReminders(int intervalMinutes) async {
    try {
      print('Scheduling reminders with interval: $intervalMinutes minutes');

      // Verificar que el servicio esté inicializado
      if (!_isInitialized) {
        print('Notification service not initialized');
        await init();
        if (!_isInitialized) {
          print('Failed to initialize service for scheduling');
          return;
        }
      }

      // Verificar permisos primero
      final bool enabled = await areNotificationsEnabled();
      if (!enabled) {
        print('Notifications not enabled, cannot schedule');
        return;
      }

      // Cancelar notificaciones existentes
      try {
        await _notifications.cancelAll();
        print('Previous notifications cancelled');
      } catch (e) {
        print('Error cancelling notifications: $e');
      }

      // Si el intervalo es 0, no programar nada
      if (intervalMinutes <= 0) {
        print('Interval is 0, not scheduling any notifications');
        return;
      }

      // Configurar detalles de notificación para Android
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'hydratrack_reminder',
        'Water Reminders',
        channelDescription: 'Reminders to drink water throughout the day',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        enableVibration: true,
        playSound: true,
        autoCancel: true,
      );

      const NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
      );

      // Programar notificaciones para las próximas 24 horas
      final DateTime now = DateTime.now();
      final DateTime tomorrow = DateTime(now.year, now.month, now.day + 1);

      int scheduledCount = 0;
      int notificationId = 1;

      DateTime nextNotification = now.add(Duration(minutes: intervalMinutes));

      while (nextNotification.isBefore(tomorrow) && scheduledCount < 50) {
        const String languageCode = 'es'; // Por ahora usar español por defecto

        try {
          await _notifications.zonedSchedule(
            notificationId,
            'HydraTrack',
            getRandomMessage(languageCode),
            tz.TZDateTime.from(nextNotification, tz.local),
            platformDetails,
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
          );

          print('Notification $notificationId scheduled for: $nextNotification');
          scheduledCount++;
        } catch (e) {
          print('Error scheduling notification $notificationId: $e');
        }

        notificationId++;
        nextNotification = nextNotification.add(Duration(minutes: intervalMinutes));
      }

      print('Successfully scheduled $scheduledCount reminders');
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
   * Show a test notification immediately
   */
  static Future<void> showTestNotification() async {
    try {
      if (!_isInitialized) {
        await init();
      }

      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'hydratrack_test',
        'Test Notifications',
        channelDescription: 'Test notifications',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );

      const NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
      );

      await _notifications.show(
        999,
        'HydraTrack Test',
        '¡Las notificaciones funcionan correctamente!',
        platformDetails,
      );

      print('Test notification sent');
    } catch (e) {
      print('Error showing test notification: $e');
    }
  }
}