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

  static Future<void> schedulePrayerNotifications({
    required double latitude,
    required double longitude,
  }) async {
    // Cancel all existing notifications first
    await _plugin.cancelAll();

    final coords  = Coordinates(latitude, longitude);
    final params  = CalculationMethod.muslim_world_league.getParameters();
    final date    = DateComponents.from(DateTime.now());
    final times   = PrayerTimes(coords, date, params);

    final prayers = [
      times.fajr,
      times.dhuhr,
      times.asr,
      times.maghrib,
      times.isha,
    ];

    for (int i = 0; i < prayers.length; i++) {
      final prayerTime = prayers[i];
      // 10 minutes before prayer
      final notifTime  = prayerTime.subtract(const Duration(minutes: 10));

      if (notifTime.isAfter(DateTime.now())) {
        await _plugin.zonedSchedule(
          i,
          'Time to prepare for prayer 🕌',
          quotes[i % quotes.length],
          tz.TZDateTime.from(notifTime, tz.local),
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'prayer_channel',
              'Prayer Reminders',
              importance: Importance.high,
              priority:   Priority.high,
            ),
            iOS: DarwinNotificationDetails(),
          ),
          androidScheduleMode:
              AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      }
    }
  }
}