import 'dart:convert';
import 'dart:math';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:adhan/adhan.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:geolocator/geolocator.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  // ─── Dua Database for Reminders ───────────────────────────────────────────
  static const List<Map<String, String>> _duaDatabase = [
    {
      'arabic':    'اللَّهُمَّ إِنِّي أَعُوذُ بِكَ مِنَ الْهَمِّ وَالْحَزَنِ',
      'english':   'O Allah I seek refuge in You from anxiety and sorrow',
      'reference': 'Sahih Bukhari',
      'title':     'Relief from anxiety and sorrow',
    },
    {
      'arabic':    'اللَّهُمَّ لَا سَهْلَ إِلَّا مَا جَعَلْتَهُ سَهْلًا',
      'english':   'O Allah there is no ease except what You make easy',
      'reference': 'Ibn Hibban',
      'title':     'Ease in difficult matters',
    },
    {
      'arabic':    'حَسْبُنَا اللَّهُ وَنِعْمَ الْوَكِيلُ',
      'english':   'Sufficient for us is Allah, and He is the best Disposer of affairs',
      'reference': 'Quran 3:173',
      'title':     'Trust in Allah\'s plan',
    },
    {
      'arabic':    'رَبِّ إِنِّي لِمَا أَنزَلْتَ إِلَيَّ مِنْ خَيْرٍ فَقِيرٌ',
      'english':   'My Lord, indeed I am, for whatever good You would send down to me, in need.',
      'reference': 'Quran 28:24',
      'title':     'Seeking Allah\'s bounty',
    },
    {
      'arabic':    'يَا حَيُّ يَا قَيُّومُ بِرَحْمَتِكَ أَسْتَغِيثُ',
      'english':   'O Ever Living, O Sustainer, in Your mercy I seek relief',
      'reference': 'Tirmidhi',
      'title':     'Seeking mercy and relief',
    },
    {
      'arabic':    'أَعُوذُ بِاللَّهِ مِنَ الشَّيْطَانِ الرَّجِيمِ',
      'english':   'I seek refuge with Allah from the accursed devil',
      'reference': 'Sahih Bukhari',
      'title':     'Protection from evil',
    },
    {
      'arabic':    'رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً وَفِي الْآخِرَةِ حَسَنَةً',
      'english':   'Our Lord, give us good in this world and good in the hereafter',
      'reference': 'Quran 2:201',
      'title':     'Good in both worlds',
    },
  ];

  // ─── Init ─────────────────────────────────────────────────────────────────
  static Future<void> init() async {
    tz.initializeTimeZones();

    // flutter_timezone v3 returns a plain String
    final String timeZoneName = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneName));

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Notification tapped — handle navigation if needed
      },
    );

    // Request Android 13+ POST_NOTIFICATIONS permission
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();
      await androidPlugin.requestExactAlarmsPermission();
    }
  }

  // ─── Location Helper ──────────────────────────────────────────────────────
  static Future<Position?> getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }

    if (permission == LocationPermission.deniedForever) return null;

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.low,
    );
  }

  // ─── Schedule Notifications ───────────────────────────────────────────────
  /// Schedules prayer reminder notifications for the next 7 days.
  /// Call this at app start and whenever settings are changed.
  static Future<void> scheduleNotifications({double? lat, double? lng}) async {
    final prefs = await SharedPreferences.getInstance();

    // Master toggle — if disabled, cancel all and exit
    final bool masterEnabled = prefs.getBool('notif_enabled') ?? true;
    if (!masterEnabled) {
      await cancelAll();
      return;
    }

    double latitude  = lat ?? prefs.getDouble('last_lat') ?? 3.1390;
    double longitude = lng ?? prefs.getDouble('last_lng') ?? 101.6869;

    if (lat != null && lng != null) {
      await prefs.setDouble('last_lat', lat);
      await prefs.setDouble('last_lng', lng);
    }

    await cancelAll();

    final myCoordinates = Coordinates(latitude, longitude);
    final params        = CalculationMethod.karachi.getParameters();

    final List<String> prayerNames = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];
    final List<String> prefKeys    = [
      'notif_fajr', 'notif_dhuhr', 'notif_asr', 'notif_maghrib', 'notif_isha'
    ];

    // Schedule 7 days ahead so notifications survive without relaunching the app
    for (int dayOffset = 0; dayOffset < 7; dayOffset++) {
      final targetDate = DateTime.now().add(Duration(days: dayOffset));
      final date       = DateComponents.from(targetDate);
      final prayerTimes = PrayerTimes(myCoordinates, date, params);

      final List<DateTime> times = [
        prayerTimes.fajr,
        prayerTimes.dhuhr,
        prayerTimes.asr,
        prayerTimes.maghrib,
        prayerTimes.isha,
      ];

      for (int i = 0; i < times.length; i++) {
        final bool isEnabled = prefs.getBool(prefKeys[i]) ?? true;
        if (!isEnabled) continue;

        // Remind 10 minutes before prayer
        final DateTime notifTime = times[i].subtract(const Duration(minutes: 10));

        // Skip if already in the past
        if (notifTime.isBefore(DateTime.now())) continue;

        final dua   = _duaDatabase[Random().nextInt(_duaDatabase.length)];
        final title = 'Prepare for ${prayerNames[i]} 🕌';

        // Unique ID: day * 5 + prayer index  →  range 0–34
        final int notifId = dayOffset * 5 + i;

        await _plugin.zonedSchedule(
          notifId,
          title,
          dua['title'],
          tz.TZDateTime.from(notifTime, tz.local),
          NotificationDetails(
            android: AndroidNotificationDetails(
              'prayer_reminders',
              'Prayer Reminders',
              channelDescription: 'Gentle Quranic reminders before prayer times',
              importance:         Importance.max,
              priority:           Priority.max,
              styleInformation:   BigTextStyleInformation(
                '${dua['arabic']}\n\n${dua['english']}',
                contentTitle: title,
                summaryText:  'Spiritual Reminder',
              ),
            ),
            iOS: const DarwinNotificationDetails(),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: jsonEncode({
            'arabic':    dua['arabic'],
            'english':   dua['english'],
            'title':     title,
            'reference': dua['reference'],
            'type':      'dua',
          }),
        );
      }
    }
  }

  // ─── Cancel All ───────────────────────────────────────────────────────────
  static Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}
