import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:adhan/adhan.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;


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
    );
  }

  static Future<void> cancelAll() async {
     {
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
         icon:               '@mipmap/ic_launcher',
        color:              Color(0xFF1a3a2a),
      ),
    ),
  );
}
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
           NotificationDetails(
            android: AndroidNotificationDetails(
              'prayer_channel',
              'Prayer Reminders',
              importance: Importance.high,
              priority:   Priority.high,
              icon:               '@mipmap/ic_launcher',  // ← add this line
              color:              Color(0xFF1a3a2a),
            ),
            iOS: DarwinNotificationDetails(),
          ),
          androidScheduleMode:
              AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
              matchDateTimeComponents: DateTimeComponents.time,
        );
      }
    }
  }
}