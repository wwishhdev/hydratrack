import 'package:flutter/material.dart';
import 'package:hydratrack/services/storage_service.dart';

class SettingsModel extends ChangeNotifier {
  final StorageService _storage;

  // Valores predeterminados
  static const int defaultDailyGoal = 2000; // 2L en ml
  static const int defaultReminderInterval = 60; // 60 minutos

  SettingsModel(this._storage) {
    _loadSettings();
  }

  int _dailyGoal = defaultDailyGoal;
  int _reminderInterval = defaultReminderInterval;
  bool _isDarkMode = false;
  String _language = 'es'; // Español por defecto

  int get dailyGoal => _dailyGoal;
  int get reminderInterval => _reminderInterval;
  bool get isDarkMode => _isDarkMode;
  String get language => _language;

  Future<void> _loadSettings() async {
    _dailyGoal = _storage.getDailyGoal() ?? defaultDailyGoal;
    _reminderInterval = _storage.getReminderInterval() ?? defaultReminderInterval;
    _isDarkMode = _storage.isDarkMode() ?? false;
    _language = _storage.getLanguage() ?? 'es';
    notifyListeners();
  }

  Future<void> setDailyGoal(int value) async {
    _dailyGoal = value;
    await _storage.saveDailyGoal(value);
    notifyListeners();
  }

  Future<void> setReminderInterval(int value) async {
    _reminderInterval = value;
    await _storage.saveReminderInterval(value);
    notifyListeners();
  }

  Future<void> setDarkMode(bool value) async {
    _isDarkMode = value;
    await _storage.saveDarkMode(value);
    notifyListeners();
  }

  Future<void> setLanguage(String value) async {
    _language = value;
    await _storage.saveLanguage(value);
    notifyListeners();
  }
}