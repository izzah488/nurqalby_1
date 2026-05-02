import 'package:flutter/material.dart';

import 'package:shared_preferences/shared_preferences.dart';

import 'services/notification_service.dart'; // local notification (KEEP)
import 'services/location_service.dart';


import 'screens/welcome_screen.dart';
import 'screens/home_screen.dart';
import 'screens/mood_history_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();




  // ✅ STEP 3 — Initialize LOCAL notification (KEEP THIS)
  await NotificationService.init();

  // ✅ STEP 4 — Get location
  final position  = await LocationService.getCurrentLocation();
  final latitude  = position?.latitude  ?? 3.1390;
  final longitude = position?.longitude ?? 101.6869;

  // ✅ STEP 5 — Schedule prayer notifications (LOCAL)
  await NotificationService.scheduleNotifications(
    lat: latitude,
    lng: longitude,
  );

  // ✅ STEP 6 — Check onboarding
  final prefs       = await SharedPreferences.getInstance();
  final seenWelcome = prefs.getBool('seen_welcome') ?? false;

  runApp(MyApp(showWelcome: !seenWelcome));
}

class MyApp extends StatelessWidget {
  final bool showWelcome;
  const MyApp({super.key, required this.showWelcome});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NurQalby',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      theme: ThemeData(
        fontFamily: 'sans-serif',
        scaffoldBackgroundColor: const Color(0xFF0d2016),
      ),
      routes: {
        '/mood-history': (context) => const MoodHistoryScreen(),
      },
      home: showWelcome
          ? const WelcomeScreen()
          : const HomeScreen(),
    );
  }
}
