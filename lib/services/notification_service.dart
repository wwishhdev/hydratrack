import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:math';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
  FlutterLocalNotificationsPlugin();

  static final List<String> _motivationalMessages = [
    "¡Recuerda hidratarte!",
    "El agua es vida, ¡toma un sorbo!",
    "Tu cuerpo necesita agua, ¡hidrátate ahora!",
    "¿Ya bebiste agua? ¡Es momento de hacerlo!",
    "Mantenerse hidratado mejora tu concentración",
    "Un poco de agua te ayudará a sentirte mejor",
    "Hidrátate para una piel más saludable",
    "¡Agua, el secreto para una mente clara!",
  ];

  static String get _randomMessage {
    final random = Random();
    return _motivationalMessages[random.nextInt(_motivationalMessages.length)];
  }

  static Future<void> init() async {
    const AndroidInitializationSettings androidSettings =
    AndroidInitializationSettings('app_icon');

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _handleNotificationResponse,
    );
  }

  static void _handleNotificationResponse(NotificationResponse response) {
    // Aquí manejaremos las acciones desde notificaciones
  }

  static Future<void> scheduleReminders(int intervalMinutes) async {
    await cancelAllNotifications();

    // Programar notificaciones periódicas
    await _notifications.periodicallyShow(
      0,
      'HydraTrack',
      _randomMessage,
      RepeatInterval.hourly, // Esto se ajustará según el intervalo
      NotificationDetails(
        android: AndroidNotificationDetails(
          'hydratrack_channel',
          'Recordatorios de agua',
          channelDescription: 'Canal para los recordatorios de consumo de agua',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }

  static Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }
}