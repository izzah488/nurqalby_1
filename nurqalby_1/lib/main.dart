import 'package:flutter/material.dart';
import 'services/notification_service.dart';
import 'screens/welcome_screen.dart';

void main() async  {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.init();
  // Kuala Lumpur coordinates — change to user's location later
  await NotificationService.schedulePrayerNotifications(
    latitude:  3.1390,
    longitude: 101.6869,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quran Recommender',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'sans-serif',
        scaffoldBackgroundColor: const Color(0xFFF5F5F0),
      ),
      home: const WelcomeScreen(),
      
    );
  }
}