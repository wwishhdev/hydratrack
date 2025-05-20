// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:math';

class NotificationService {
  // static final FlutterLocalNotificationsPlugin _notifications =
  // FlutterLocalNotificationsPlugin();

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
    print('Notificaciones deshabilitadas temporalmente');
  }

  static void _handleNotificationResponse(dynamic response) {
    // No hace nada
  }

  static Future<void> scheduleReminders(int intervalMinutes) async {
    print('Recordatorios programados cada $intervalMinutes minutos (deshabilitado)');
    // Las notificaciones están deshabilitadas temporalmente
  }

  static Future<void> cancelAllNotifications() async {
    // No hace nada
  }
}