import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'services/notification_service.dart';
import 'services/location_service.dart';

import 'screens/welcome_screen.dart';
import 'screens/home_screen.dart';
import 'screens/mood_history_screen.dart';
import 'screens/notification_detail_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set up notification tap handler BEFORE init()
  // so taps from terminated state are caught immediately
  NotificationService.onNotificationTap = (payload) {
    navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (_) => NotificationDetailScreen(
          arabic:    payload['arabic']    ?? '',
          english:   payload['english']   ?? '',
          title:     payload['title']     ?? 'Reminder',
          reference: payload['reference'] ?? '',
          type:      payload['type']      ?? 'dua',
        ),
      ),
    );
  };

  await NotificationService.init();

  // NEW: Handle tap if user opened app by tapping a notification
  // while app was fully killed
  await NotificationService.checkPendingTap();

  final position  = await LocationService.getCurrentLocation();
  final latitude  = position?.latitude  ?? 3.1390;
  final longitude = position?.longitude ?? 101.6869;

  await NotificationService.scheduleNotifications(
    lat: latitude,
    lng: longitude,
  );

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
      // NEW: wrap home in lifecycle watcher to recover killed alarms
      home: AppLifecycleWrapper(
        child: showWelcome ? const WelcomeScreen() : const HomeScreen(),
      ),
    );
  }
}

// NEW: Watches app resume to silently reschedule if Android killed alarms
class AppLifecycleWrapper extends StatefulWidget {
  final Widget child;
  const AppLifecycleWrapper({super.key, required this.child});

  @override
  State<AppLifecycleWrapper> createState() => _AppLifecycleWrapperState();
}

class _AppLifecycleWrapperState extends State<AppLifecycleWrapper>
    with WidgetsBindingObserver {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // If Android killed exact alarms (battery optimization),
      // this quietly reschedules them next time user opens the app
      NotificationService.rescheduleIfNeeded();
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}