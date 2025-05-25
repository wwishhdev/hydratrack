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
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : Text(
                  'get_started',
                  style: const TextStyle(fontSize: 16),
                ).tr(),
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

      // Guardar configuraciones básicas
      await settings.setLanguage(_selectedLanguage);
      print('Language set to: $_selectedLanguage');

      // Re-inicializar el servicio de notificaciones para asegurar que esté listo
      await NotificationService.init();
      print('Notification service re-initialized');

      // Mostrar dialog explicativo antes de solicitar permisos
      final bool shouldRequestPermissions = await _showPermissionExplanationDialog();

      bool permissionGranted = false;
      if (shouldRequestPermissions) {
        // Solicitar permisos de notificaciones
        permissionGranted = await NotificationService.requestPermissions();
        print('Permission granted: $permissionGranted');

        // Si se concedieron permisos, programar notificaciones
        if (permissionGranted) {
          final reminderInterval = settings.reminderInterval;
          if (reminderInterval > 0) {
            await NotificationService.scheduleReminders(reminderInterval);
            print('Reminders scheduled with interval: $reminderInterval minutes');
          }
        }
      }

      // Mostrar resultado de permisos
      await _showPermissionResultDialog(permissionGranted, shouldRequestPermissions);

      // Navegar a la pantalla principal
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } catch (e) {
      print('Error during app initialization: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al inicializar la aplicación. La app funcionará sin notificaciones.'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 4),
          ),
        );

        // Continuar a la app principal aunque haya errores
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
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

  Future<bool> _showPermissionExplanationDialog() async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.notifications_outlined, color: Theme.of(context).primaryColor),
            const SizedBox(width: 8),
            const Text('Notificaciones'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'HydraTrack puede enviarte recordatorios para beber agua durante el día.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Text(
              '¿Deseas activar las notificaciones?',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '(Puedes cambiar esto más tarde en Configuración)',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Ahora no'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Activar'),
          ),
        ],
      ),
    ) ?? false;
  }

  Future<void> _showPermissionResultDialog(bool granted, bool wasRequested) async {
    if (!wasRequested) return;

    String title;
    String message;
    IconData icon;
    Color iconColor;

    if (granted) {
      title = '¡Perfecto!';
      message = 'Las notificaciones están activadas. Te recordaremos beber agua regularmente.';
      icon = Icons.check_circle_outline;
      iconColor = Colors.green;
    } else {
      title = 'Sin notificaciones';
      message = 'No hay problema. Puedes activar las notificaciones más tarde desde Configuración si cambias de opinión.';
      icon = Icons.info_outline;
      iconColor = Colors.orange;
    }

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(icon, color: iconColor),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Text(message),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Continuar'),
          ),
        ],
      ),
    );
  }
}