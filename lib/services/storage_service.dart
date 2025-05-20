import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hydratrack/models/consumption_model.dart';

class StorageService {
  static const String _keyDailyGoal = 'daily_goal';
  static const String _keyReminderInterval = 'reminder_interval';
  static const String _keyDarkMode = 'dark_mode';
  static const String _keyLanguage = 'language';
  static const String _keyFirstRun = 'first_run';
  static const String _keyConsumptionPrefix = 'consumption_';

  late final SharedPreferences _prefs;

  static Future<StorageService> init() async {
    final instance = StorageService();
    instance._prefs = await SharedPreferences.getInstance();
    return instance;
  }

  // Primera ejecución
  bool isFirstRun() {
    bool first = _prefs.getBool(_keyFirstRun) ?? true;
    if (first) {
      _prefs.setBool(_keyFirstRun, false);
    }
    return first;
  }

  // Configuraciones
  int? getDailyGoal() => _prefs.getInt(_keyDailyGoal);
  Future<void> saveDailyGoal(int value) => _prefs.setInt(_keyDailyGoal, value);

  int? getReminderInterval() => _prefs.getInt(_keyReminderInterval);
  Future<void> saveReminderInterval(int value) => _prefs.setInt(_keyReminderInterval, value);

  bool? isDarkMode() => _prefs.getBool(_keyDarkMode);
  Future<void> saveDarkMode(bool value) => _prefs.setBool(_keyDarkMode, value);

  String? getLanguage() => _prefs.getString(_keyLanguage);
  Future<void> saveLanguage(String value) => _prefs.setString(_keyLanguage, value);

  // Consumos
  Future<void> saveConsumption(Consumption consumption) async {
    String dateKey = _getDateKey(consumption.timestamp);
    List<Consumption> dayConsumptions = await getConsumptionsByDate(consumption.timestamp);
    dayConsumptions.add(consumption);

    List<Map<String, dynamic>> serialized =
    dayConsumptions.map((c) => c.toJson()).toList();
    await _prefs.setString(dateKey, jsonEncode(serialized));
  }

  Future<List<Consumption>> getConsumptionsByDate(DateTime date) async {
    String dateKey = _getDateKey(date);
    String? data = _prefs.getString(dateKey);

    if (data == null) return [];

    List<dynamic> jsonData = jsonDecode(data);
    return jsonData
        .map((item) => Consumption.fromJson(item))
        .toList();
  }

  Future<Map<DateTime, int>> getWeeklyConsumption() async {
    final Map<DateTime, int> result = {};
    final now = DateTime.now();

    // Obtener los últimos 7 días
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateOnly = DateTime(date.year, date.month, date.day);
      final consumptions = await getConsumptionsByDate(dateOnly);
      final totalAmount = consumptions.fold(0, (sum, item) => sum + item.amount);
      result[dateOnly] = totalAmount;
    }

    return result;
  }

  String _getDateKey(DateTime date) {
    final dateString = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return _keyConsumptionPrefix + dateString;
  }
}