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

  static String getRandomMessage(String languageCode) {
    final random = Random();
    if (languageCode == 'en') {
      return _motivationalMessagesEn[random.nextInt(_motivationalMessagesEn.length)];
    }
    return _motivationalMessagesEs[random.nextInt(_motivationalMessagesEs.length)];
  }

  static Future<void> init() async {
    // Inicializar timezone
    tz.initializeTimeZones();

    // Inicializar configuración para Android
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    // Configuración general (solo Android)
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    // Inicializar plugin con configuraciones
    await _notifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _handleNotificationResponse,
    );

    print('Servicio de notificaciones inicializado correctamente');
  }

  static void _handleNotificationResponse(NotificationResponse response) {
    // Maneja lo que pasa cuando el usuario toca una notificación
    print('Notificación recibida: ${response.payload}');
  }

  static Future<bool> requestPermissions() async {
    // Usar permission_handler para solicitar permisos de notificaciones
    PermissionStatus status = await Permission.notification.status;

    print('Estado actual de permiso de notificación: $status');

    // Si el permiso no está concedido, solicitarlo
    if (status.isDenied || status.isRestricted || status.isLimited) {
      status = await Permission.notification.request();
      print('Nuevo estado de permiso después de solicitar: $status');
    }

    return status.isGranted;
  }

  static Future<void> scheduleReminders(int intervalMinutes) async {
    // Verificar permisos primero
    final bool permissionsGranted = await requestPermissions();
    if (!permissionsGranted) {
      print('Permisos de notificación denegados');
      return;
    }

    await cancelAllNotifications();

    // Si el intervalo es 0, no programamos nada
    if (intervalMinutes <= 0) return;

    // Configuración de los detalles de Android
    AndroidNotificationDetails androidDetails = const AndroidNotificationDetails(
      'hydratrack_reminder',
      'Water Reminders',
      channelDescription: 'Reminders to drink water throughout the day',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    // Configuración general (solo Android)
    NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
    );

    final int minutesInDay = 24 * 60;
    final int totalNotifications = minutesInDay ~/ intervalMinutes;

    // Obtenemos el idioma actual
    final String languageCode = tz.local.toString().contains('_')
        ? tz.local.toString().split('_')[0]
        : 'es';

    for (int i = 1; i <= totalNotifications; i++) {
      final DateTime now = DateTime.now();
      final DateTime scheduledTime = now.add(Duration(minutes: i * intervalMinutes));

      // Solo programamos notificaciones para hoy (no para mañana)
      if (scheduledTime.day != now.day) continue;

      await _notifications.zonedSchedule(
        i, // ID único para cada notificación
        'HydraTrack', // Título
        getRandomMessage(languageCode), // Mensaje aleatorio según idioma
        tz.TZDateTime.from(scheduledTime, tz.local),
        platformDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
      );

      print('Notificación programada para: $scheduledTime');
    }

    print('Recordatorios programados cada $intervalMinutes minutos');
  }

  static Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
    print('Todas las notificaciones han sido canceladas');
  }
}