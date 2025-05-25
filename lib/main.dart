import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:hydratrack/services/notification_service.dart';
import 'package:hydratrack/services/storage_service.dart';
import 'package:hydratrack/theme/app_theme.dart';
import 'package:hydratrack/models/settings_model.dart';
import 'package:hydratrack/screens/home_screen.dart';
import 'package:hydratrack/screens/welcome_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  // Inicializar servicios
  final storageService = await StorageService.init();
  await NotificationService.init();

  // Verificar si es la primera vez que se ejecuta la app
  final bool isFirstRun = storageService.isFirstRun();

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('es'), Locale('en')],
      path: 'assets/translations',
      fallbackLocale: const Locale('es'),
      child: MultiProvider(
        providers: [
          Provider<StorageService>.value(value: storageService), // Añadimos esta línea
          ChangeNotifierProvider(create: (_) => SettingsModel(storageService)),
        ],
        child: HydraTrackApp(isFirstRun: isFirstRun),
      ),
    ),
  );
}

class HydraTrackApp extends StatelessWidget {
  final bool isFirstRun;

  const HydraTrackApp({
    Key? key,
    required this.isFirstRun,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final settingsModel = Provider.of<SettingsModel>(context);

    return MaterialApp(
      title: 'HydraTrack',
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      theme: getLightTheme(),
      darkTheme: getDarkTheme(),
      themeMode: settingsModel.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: isFirstRun ? const WelcomeScreen() : const HomeScreen(),
    );
  }
}