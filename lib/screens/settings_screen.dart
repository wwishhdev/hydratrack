import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import 'package:hydratrack/models/settings_model.dart';
import 'package:hydratrack/services/notification_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late int _dailyGoal;
  late int _reminderInterval;
  late bool _isDarkMode;
  late String _language;

  @override
  void initState() {
    super.initState();
    final settings = Provider.of<SettingsModel>(context, listen: false);
    _dailyGoal = settings.dailyGoal;
    _reminderInterval = settings.reminderInterval;
    _isDarkMode = settings.isDarkMode;
    _language = settings.language;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('settings').tr(),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildDailyGoalSection(),
          const SizedBox(height: 16.0),
          _buildReminderSection(),
          const SizedBox(height: 16.0),
          _buildAppearanceSection(),
          const SizedBox(height: 16.0),
          _buildAboutSection(),
        ],
      ),
    );
  }

  Widget _buildDailyGoalSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'daily_goal',
              style: Theme.of(context).textTheme.titleMedium,
            ).tr(),
            const SizedBox(height: 16.0),
            Text('$_dailyGoal ml'),
            Slider(
              value: _dailyGoal.toDouble(),
              min: 1000,
              max: 5000,
              divisions: 40,
              label: '$_dailyGoal ml',
              onChanged: (value) {
                setState(() {
                  _dailyGoal = value.toInt();
                });
              },
              onChangeEnd: (value) {
                final settings = Provider.of<SettingsModel>(context, listen: false);
                settings.setDailyGoal(value.toInt());
              },
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('1000 ml'),
                Text('5000 ml'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReminderSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'reminders',
              style: Theme.of(context).textTheme.titleMedium,
            ).tr(),
            const SizedBox(height: 16.0),
            Text(
              '$_reminderInterval ${_reminderInterval == 1 ? "minute".tr() : "minutes".tr()}',
            ),
            Slider(
              value: _reminderInterval.toDouble(),
              min: 15,
              max: 120,
              divisions: 7,
              label: '$_reminderInterval min',
              onChanged: (value) {
                setState(() {
                  _reminderInterval = value.toInt();
                });
              },
              onChangeEnd: (value) async {
                final settings = Provider.of<SettingsModel>(context, listen: false);
                await settings.setReminderInterval(value.toInt());

                // Mantenemos la llamada, pero ahora no hará nada
                await NotificationService.scheduleReminders(_reminderInterval);

                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Las notificaciones están temporalmente deshabilitadas'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('15 min'),
                Text('120 min'),
              ],
            ),
            const SizedBox(height: 12),
            // Mensaje informativo sobre notificaciones
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.amber),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Las notificaciones estarán disponibles en la próxima actualización.",
                      style: TextStyle(
                        color: Colors.amber[800],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppearanceSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'appearance',
              style: Theme.of(context).textTheme.titleMedium,
            ).tr(),
            const SizedBox(height: 16.0),
            SwitchListTile(
              title: Text('dark_mode').tr(),
              value: _isDarkMode,
              onChanged: (value) async {
                setState(() {
                  _isDarkMode = value;
                });
                final settings = Provider.of<SettingsModel>(context, listen: false);
                await settings.setDarkMode(value);
              },
            ),
            const Divider(),
            ListTile(
              title: Text('language').tr(),
              trailing: DropdownButton<String>(
                value: _language,
                onChanged: (value) async {
                  if (value == null) return;
                  setState(() {
                    _language = value;
                  });
                  final settings = Provider.of<SettingsModel>(context, listen: false);
                  await settings.setLanguage(value);

                  if (!mounted) return;
                  context.setLocale(Locale(value));
                },
                items: [
                  DropdownMenuItem(
                    value: 'es',
                    child: Text('Spanish').tr(),
                  ),
                  DropdownMenuItem(
                    value: 'en',
                    child: Text('English').tr(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'about',
              style: Theme.of(context).textTheme.titleMedium,
            ).tr(),
            const SizedBox(height: 16.0),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: Text('app_version').tr(),
              trailing: const Text('1.0.0'),
            ),
            ListTile(
              leading: const Icon(Icons.star_outline),
              title: Text('rate_app').tr(),
              onTap: () {
                // Implementar acción para calificar la app
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('rate_coming_soon').tr(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.apps),
              title: Text('more_apps').tr(),
              onTap: () {
                // Implementar acción para ver más apps
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('more_apps_coming_soon').tr(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}