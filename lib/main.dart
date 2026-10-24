import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'theme/app_theme.dart';
import 'screens/main_navigation_screen.dart';
import 'services/notification_service.dart';
import 'services/sound_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );

  await initializeDateFormatting('ko_KR');
  await SoundService.init();
  await NotificationService.initTimeZone();
  await NotificationService.initNotifications();
  NotificationService.startMonitoring();

  runApp(const AudistineApp());
}

class AudistineApp extends StatelessWidget {
  const AudistineApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'audistine?',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        return MediaQuery(
          data: mediaQuery.copyWith(
            textScaler: TextScaler.linear(
              mediaQuery.textScaler.scale(1.0) * 1.15,
            ),
          ),
          child: child!,
        );
      },
      home: const MainNavigationScreen(),
    );
  }
}
