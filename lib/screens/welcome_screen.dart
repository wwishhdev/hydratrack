import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import 'package:hydratrack/models/settings_model.dart';
import 'package:hydratrack/screens/home_screen.dart';
import 'package:hydratrack/services/notification_service.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  String _selectedLanguage = 'es';
  bool _isDarkMode = false;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Icon(
                Icons.water_drop,
                size: 100,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(height: 24),
              Text(
                'welcome_title',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ).tr(),
              const SizedBox(height: 16),
              Text(
                'welcome_subtitle',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ).tr(),
              const Spacer(),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('select_language').tr(),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _selectedLanguage,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'es',
                            child: Text('Español'),
                          ),
                          DropdownMenuItem(
                            value: 'en',
                            child: Text('English'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedLanguage = value!;
                          });
                          context.setLocale(Locale(_selectedLanguage));
                        },
                      ),
                      const SizedBox(height: 16),
                      Text('select_theme').tr(),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        title: Text('dark_mode').tr(),
                        value: _isDarkMode,
                        contentPadding: EdgeInsets.zero,
                        onChanged: (value) async {
                          setState(() {
                            _isDarkMode = value;
                          });
                          // Aplicar el tema inmediatamente
                          final settings = Provider.of<SettingsModel>(context, listen: false);
                          await settings.setDarkMode(value);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _getStarted,
                child: _isLoading
                    ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    )
                )
                    : Text('get_started').tr(),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _getStarted() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final settings = Provider.of<SettingsModel>(context, listen: false);
      await settings.setLanguage(_selectedLanguage);

      // Solicitar permisos de notificaciones antes de navegar
      final bool permissionGranted = await NotificationService.requestPermissions();
      print('Permiso de notificación concedido: $permissionGranted');

      // Si hay un intervalo de recordatorio configurado y los permisos se concedieron, programar notificaciones
      final reminderInterval = settings.reminderInterval;
      if (reminderInterval > 0 && permissionGranted) {
        await NotificationService.scheduleReminders(reminderInterval);
      }

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } catch (e) {
      print('Error al iniciar la aplicación: $e');
      // Mostrar un mensaje de error si algo sale mal
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ha ocurrido un error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}