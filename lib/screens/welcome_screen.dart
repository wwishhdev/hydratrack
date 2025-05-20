import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import 'package:hydratrack/models/settings_model.dart';
import 'package:hydratrack/screens/home_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  String _selectedLanguage = 'es';
  bool _isDarkMode = false;

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
                        onChanged: (value) {
                          setState(() {
                            _isDarkMode = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  final settings = Provider.of<SettingsModel>(context, listen: false);
                  await settings.setLanguage(_selectedLanguage);
                  await settings.setDarkMode(_isDarkMode);

                  if (!mounted) return;

                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const HomeScreen()),
                  );
                },
                child: Text('get_started').tr(),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}