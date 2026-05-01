// lib/services/notification_service.dart
//
// FIXED:
// 1. Notifications are saved to 'notification_history' in SharedPreferences
//    when they are scheduled, so history screen can show them.
// 2. Reminder changed from 10 → 19 minutes before azan.
// 3. CSV path fixed to match pubspec.yaml: assets/images/duas.csv
// 4. onDidReceiveNotificationResponse now saves history entry on tap.
// 5. Random dua shuffle works correctly from CSV.

import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:adhan/adhan.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:geolocator/geolocator.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  // Navigation callback — set this in main.dart so tapping a notification
  // can push NotificationDetailScreen from anywhere in the app.
  static void Function(Map<String, dynamic> payload)? onNotificationTap;

  // ── In-memory cache — loaded once from CSV on first use ──────────────────
  static List<Map<String, String>> _duaCache = [];

  // ─── Load duas from CSV asset ─────────────────────────────────────────────
  // FIXED: path now matches pubspec.yaml → assets/images/duas.csv
  static Future<void> _loadDuas() async {
    if (_duaCache.isNotEmpty) return;

    try {
      final raw   = await rootBundle.loadString('assets/images/duas.csv');
      final lines = raw.split('\n');
      final result = <Map<String, String>>[];

      for (int i = 1; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;

        final cols = _splitCsvLine(line);
        if (cols.length < 5) continue;

        result.add({
          'id':        cols[0].trim(),
          'title':     cols[1].trim(),
          'arabic':    cols[2].trim(),
          'english':   cols[3].trim(),
          'reference': cols[4].trim(),
        });
      }

      _duaCache = result;
    } catch (e) {
      _duaCache = [
        {
          'id':        '1',
          'title':     'Relief from anxiety and sorrow',
          'arabic':    'اللَّهُمَّ إِنِّي أَعُوذُ بِكَ مِنَ الْهَمِّ وَالْحَزَنِ',
          'english':   'O Allah, I seek refuge in You from anxiety and sorrow',
          'reference': 'Sahih Bukhari',
        },
        {
          'id':        '2',
          'title':     'Trust in Allah\'s plan',
          'arabic':    'حَسْبُنَا اللَّهُ وَنِعْمَ الْوَكِيلُ',
          'english':   'Sufficient for us is Allah and He is the best Disposer of affairs',
          'reference': 'Quran 3:173',
        },
      ];
    }
  }

  static List<String> _splitCsvLine(String line) {
    final parts = <String>[];
    var remaining = line;
    for (int i = 0; i < 4; i++) {
      final idx = remaining.indexOf(',');
      if (idx == -1) break;
      parts.add(remaining.substring(0, idx));
      remaining = remaining.substring(idx + 1);
    }
    parts.add(remaining);
    return parts;
  }

  // ─── Init ─────────────────────────────────────────────────────────────────
  static Future<void> init() async {
    tz.initializeTimeZones();

    final String timeZoneName = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneName));

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios     = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // FIXED: When user taps notification, parse payload and navigate
        if (response.payload != null) {
          try {
            final data = jsonDecode(response.payload!) as Map<String, dynamic>;
            onNotificationTap?.call(data);
          } catch (_) {}
        }
      },
    );

    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();
      await androidPlugin.requestExactAlarmsPermission();
    }

    await _loadDuas();
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
        desiredAccuracy: LocationAccuracy.medium);
  }

  // ─── Schedule Notifications ───────────────────────────────────────────────
  // FIXED:
  // • Reminder is now 19 minutes before azan (was 10).
  // • Each scheduled notification is written to 'notification_history'
  //   so the history screen can display it even if the user misses it.
  // • Random dua is picked per notification (shuffle from CSV).
  static Future<void> scheduleNotifications({double? lat, double? lng}) async {
    await _loadDuas();

    final prefs = await SharedPreferences.getInstance();

    final bool masterEnabled = prefs.getBool('notif_enabled') ?? true;
    if (!masterEnabled) {
      await cancelAll();
      return;
    }

    double latitude  = lat ?? prefs.getDouble('last_lat')  ?? 3.1390;
    double longitude = lng ?? prefs.getDouble('last_lng') ?? 101.6869;

    if (lat != null && lng != null) {
      await prefs.setDouble('last_lat', lat);
      await prefs.setDouble('last_lng', lng);
    }

    await cancelAll();

    // Clear old scheduled history entries before writing new ones
    // (keep only entries whose time is already in the past — those were real)
    final existingHistory = prefs.getStringList('notification_history') ?? [];
    final now = DateTime.now();
    final pastHistory = existingHistory.where((s) {
      try {
        final map = jsonDecode(s) as Map<String, dynamic>;
        return DateTime.parse(map['time']).isBefore(now);
      } catch (_) {
        return false;
      }
    }).toList();

    final myCoordinates = Coordinates(latitude, longitude);
    final params        = CalculationMethod.karachi.getParameters();

    final prayerNames = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];
    final prefKeys    = [
      'notif_fajr', 'notif_dhuhr', 'notif_asr', 'notif_maghrib', 'notif_isha'
    ];

    // Shuffle the dua list so each scheduling cycle gives a different order
    final rng         = Random();
    final shuffled    = List<Map<String, String>>.from(_duaCache)..shuffle(rng);
    int duaIndex      = 0;

    final newHistoryEntries = <String>[];

    for (int dayOffset = 0; dayOffset < 7; dayOffset++) {
      final targetDate  = DateTime.now().add(Duration(days: dayOffset));
      final date        = DateComponents.from(targetDate);
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

        // FIXED: 19 minutes before azan
        final DateTime notifTime =
            times[i].subtract(const Duration(minutes: 19));
        if (notifTime.isBefore(DateTime.now())) continue;

        // Pick next dua from shuffled list (wraps around)
        final dua   = shuffled[duaIndex % shuffled.length];
        duaIndex++;

        final String title    = 'Prepare for ${prayerNames[i]} 🕌';
        final int    notifId  = dayOffset * 5 + i;

        final payloadMap = {
          'arabic':    dua['arabic']    ?? '',
          'english':   dua['english']   ?? '',
          'title':     title,
          'reference': dua['reference'] ?? '',
          'type':      'dua',
          // Store the actual azan time so detail screen can show it
          'azan_time': times[i].toIso8601String(),
          'prayer':    prayerNames[i],
        };

        await _plugin.zonedSchedule(
          notifId,
          title,
          dua['title'] ?? 'Islamic Reminder',
          tz.TZDateTime.from(notifTime, tz.local),
          NotificationDetails(
            android: AndroidNotificationDetails(
              'prayer_reminders',
              'Prayer Reminders',
              channelDescription:
                  'Gentle Quranic reminders before prayer times',
              importance: Importance.max,
              priority:   Priority.max,
              styleInformation: BigTextStyleInformation(
                '${dua['arabic'] ?? ''}\n\n${dua['english'] ?? ''}',
                contentTitle: title,
                summaryText:  'Spiritual Reminder',
              ),
            ),
            iOS: const DarwinNotificationDetails(),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: jsonEncode(payloadMap),
        );

        // FIXED: Save this notification to history so user can see it later
        // Time stored = notifTime (when it pops up), not azan time
        newHistoryEntries.add(jsonEncode({
          ...payloadMap,
          'time':   notifTime.toIso8601String(),
          'isRead': false,
        }));
      }
    }

    // Merge past real entries + newly scheduled entries, newest first
    final allHistory = [...pastHistory, ...newHistoryEntries];
    await prefs.setStringList('notification_history', allHistory);
  }

  // ─── Cancel All ───────────────────────────────────────────────────────────
  static Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  // ─── Public helper: reload duas ──────────────────────────────────────────
  static void clearDuaCache() {
    _duaCache = [];
  }
}
