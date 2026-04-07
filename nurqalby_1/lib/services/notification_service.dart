import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:adhan/adhan.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../screens/notification_detail_screen.dart';
import '../main.dart'; // Make sure navigatorKey is exported from here

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  // Quotes to show before each prayer
  static const List<String> quotes = [
    'إِنَّ مَعَ الْعُسْرِ يُسْرًا — Indeed with hardship comes ease (94:6)',
    'أَلَا بِذِكْرِ اللَّهِ تَطْمَئِنُّ الْقُلُوبُ — In remembrance of Allah hearts find rest (13:28)',
    'وَاسْتَعِينُوا بِالصَّبْرِ وَالصَّلَاةِ — Seek help through patience and prayer (2:153)',
    'حَسْبُنَا اللَّهُ وَنِعْمَ الْوَكِيلُ — Allah is sufficient for us (3:173)',
    'وَمَن يَتَوَكَّلْ عَلَى اللَّهِ فَهُوَ حَسْبُهُ — Whoever relies on Allah, He is sufficient (65:3)',
  ];

  static Future<void> init() async {
    tz.initializeTimeZones();
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios     = DarwinInitializationSettings();
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: _onNotificationTap, // Wired up the tap handler
    );
  }

  static void _onNotificationTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null) return;

    final parts = payload.split('||');
    if (parts.length < 5) return;

    navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (_) => NotificationDetailScreen(
          arabic:    parts[0],
          english:   parts[1],
          title:     parts[2],
          reference: parts[3],
          type:      parts[4],
        ),
      ),
    );
  }

  // Extracted the test notification into its own properly formed method
  static Future<void> showTestNotification() async {
    await _plugin.show(
      99,
      'Test Notification 🕌',
      'Indeed with hardship comes ease (94:6)',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'prayer_channel',
          'Prayer Reminders',
          importance: Importance.high,
          priority:   Priority.high,
          icon:       '@mipmap/ic_launcher',
          color:      Color(0xFF1a3a2a),
        ),
      ),
    );
  }

  static Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  static Future<void> schedulePrayerNotifications({
    required double latitude,
    required double longitude,
    bool fajrEnabled    = true,
    bool dhuhrEnabled   = true,
    bool asrEnabled     = true,
    bool maghribEnabled = true,
    bool ishaEnabled    = true,
  }) async {
    await _plugin.cancelAll();

    final coords  = Coordinates(latitude, longitude);
    final params  = CalculationMethod.muslim_world_league.getParameters();
    final date    = DateComponents.from(DateTime.now());
    final times   = PrayerTimes(coords, date, params);

    final prayers = [
      {'time': times.fajr,    'enabled': fajrEnabled,    'name': 'Fajr'},
      {'time': times.dhuhr,   'enabled': dhuhrEnabled,   'name': 'Dhuhr'},
      {'time': times.asr,     'enabled': asrEnabled,     'name': 'Asr'},
      {'time': times.maghrib, 'enabled': maghribEnabled, 'name': 'Maghrib'},
      {'time': times.isha,    'enabled': ishaEnabled,    'name': 'Isha'},
    ];

    // Added a sample 'doa' map so your payload compiles. 
    // You can replace this with a dynamic dua fetcher if you prefer!
    final doa = {
      'arabic': 'اللَّهُمَّ أَعِنِّي عَلَى ذِكْرِكَ، وَشُكْرِكَ، وَحُسْنِ عِبَادَتِكَ',
      'translation': 'O Allah, help me remember You, to be grateful to You, and to worship You in an excellent manner.'
    };

    for (int i = 0; i < prayers.length; i++) {
      if (prayers[i]['enabled'] == false) continue;

      final prayerTime = prayers[i]['time'] as DateTime;
      final notifTime  = prayerTime.subtract(const Duration(minutes: 10));

      if (notifTime.isAfter(DateTime.now())) {
        await _plugin.zonedSchedule(
          i,
          'Time to prepare for ${prayers[i]['name']} 🕌',
          quotes[i % quotes.length],
          tz.TZDateTime.from(notifTime, tz.local),
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'prayer_channel',
              'Prayer Reminders',
              importance: Importance.high,
              priority:   Priority.high,
              icon:       '@mipmap/ic_launcher', 
              color:      Color(0xFF1a3a2a),
            ),
            iOS: DarwinNotificationDetails(),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.time,
          // Moved the payload here where it belongs!
          payload: '${doa['arabic']}||${doa['translation']}||${prayers[i]['name']} Dua||Hisnul Muslim||dua',
        );
      }
    }
  }
}