// lib/services/notification_service.dart
//
// KEY CHANGE: One Android notification channel per prayer time.
// This makes Android show each prayer as a separate toggle in
// Settings → Apps → NurQalby → Notifications  (exactly like Muslim Pro).
//
// Channel IDs:
//   prayer_fajr_v1 | prayer_dhuhr_v1 | prayer_asr_v1
//   prayer_maghrib_v1 | prayer_isha_v1
//
// Bump the suffix (v2, v3 …) any time you change importance/sound on a channel
// because Android locks channel settings after first creation.

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

// ── One entry per prayer ──────────────────────────────────────────────────────
class _PrayerChannel {
  final String id;          // Android channel ID
  final String name;        // Shown in Android notification settings
  final String description;
  const _PrayerChannel(this.id, this.name, this.description);
}

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  // Minutes before adhan to send notification
  static const _minutesBefore = 10;

  // ── Per-prayer channel definitions ─────────────────────────────────────────
  static const _prayerChannels = [
    _PrayerChannel('prayer_fajr_v1',    'Fajr',    'Subuh / Fajr prayer reminder'),
    _PrayerChannel('prayer_dhuhr_v1',   'Dhuhr',   'Zuhur / Dhuhr prayer reminder'),
    _PrayerChannel('prayer_asr_v1',     'Asr',     'Asar / Asr prayer reminder'),
    _PrayerChannel('prayer_maghrib_v1', 'Maghrib', 'Maghrib prayer reminder'),
    _PrayerChannel('prayer_isha_v1',    'Isha',    "Isyak / Isha'a prayer reminder"),
  ];

  // Matching display names and pref keys (index must stay in sync with above)
  static const _prayerNames = ['Subuh', 'Zuhur', 'Asar', 'Maghrib', 'Isyak'];
  static const _prefKeys = [
    'notif_fajr', 'notif_dhuhr', 'notif_asr', 'notif_maghrib', 'notif_isha'
  ];

  // Navigation callback — set this in main.dart
  static void Function(Map<String, dynamic> payload)? onNotificationTap;

  // ── In-memory dua cache ───────────────────────────────────────────────────
  static List<Map<String, String>> _duaCache = [];

  // ─── Load duas from CSV asset ─────────────────────────────────────────────
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
          'title':     "Trust in Allah's plan",
          'arabic':    'حَسْبُنَا اللَّهُ وَنِعْمَ الْوَكِيلُ',
          'english':   'Sufficient for us is Allah, the best Disposer of affairs',
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
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.payload != null) {
          try {
            final data = jsonDecode(response.payload!) as Map<String, dynamic>;
            onNotificationTap?.call(data);
          } catch (_) {}
        }
      },
      onDidReceiveBackgroundNotificationResponse: _backgroundHandler,
    );

    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();
      await androidPlugin.requestExactAlarmsPermission();

      // ── Register all 5 prayer channels so Android shows them immediately ──
      // Even before any notification fires, the toggles appear in system settings.
      for (final ch in _prayerChannels) {
        await androidPlugin.createNotificationChannel(
          AndroidNotificationChannel(
            ch.id,
            ch.name,
            description: ch.description,
            importance: Importance.max,
            playSound: true,
            enableVibration: true,
            showBadge: true,
          ),
        );
      }
    }

    await _loadDuas();
  }

  // Background handler must be a top-level / static function
  @pragma('vm:entry-point')
  static void _backgroundHandler(NotificationResponse response) {
    if (response.payload != null) {
      _storePendingTap(response.payload!);
    }
  }

  static Future<void> _storePendingTap(String payload) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pending_notification_tap', payload);
  }

  // Call this in main.dart after init() to handle taps from terminated state
  static Future<void> checkPendingTap() async {
    final prefs   = await SharedPreferences.getInstance();
    final pending = prefs.getString('pending_notification_tap');
    if (pending != null) {
      await prefs.remove('pending_notification_tap');
      try {
        final data = jsonDecode(pending) as Map<String, dynamic>;
        onNotificationTap?.call(data);
      } catch (_) {}
    }
  }

  // ─── Build Notification Details (per-prayer channel) ─────────────────────
  static NotificationDetails _buildNotificationDetails({
    required _PrayerChannel channel,   // ← now uses the per-prayer channel
    required String title,
    required String arabicText,
    required String englishText,
    required String duaTitle,
  }) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        channel.id,           // ← per-prayer channel ID
        channel.name,         // ← per-prayer channel name
        channelDescription: channel.description,
        importance:  Importance.max,
        priority:    Priority.max,
        category:    AndroidNotificationCategory.reminder,
        visibility:  NotificationVisibility.public,
        fullScreenIntent: false,
        ticker: 'Prayer reminder',
        styleInformation: BigTextStyleInformation(
          '$arabicText\n\n$englishText',
          contentTitle:  title,
          summaryText:   duaTitle,
          htmlFormatBigText:      false,
          htmlFormatContentTitle: false,
          htmlFormatSummaryText:  false,
        ),
        autoCancel: true,
        ongoing:    false,
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }

  // ─── Schedule Notifications ───────────────────────────────────────────────
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

    // Keep only past entries in history (they already fired)
    final existingHistory = prefs.getStringList('notification_history') ?? [];
    final now = DateTime.now();
    final pastHistory = existingHistory.where((s) {
      try {
        final map = jsonDecode(s) as Map<String, dynamic>;
        return DateTime.parse(map['time'] as String).isBefore(now);
      } catch (_) {
        return false;
      }
    }).toList();

    final coordinates = Coordinates(latitude, longitude);
    final params      = CalculationMethod.karachi.getParameters();

    final rng      = Random();
    final shuffled = List<Map<String, String>>.from(_duaCache)..shuffle(rng);
    int   duaIndex = 0;

    final newHistoryEntries = <String>[];

    for (int dayOffset = 0; dayOffset < 7; dayOffset++) {
      final targetDate  = now.add(Duration(days: dayOffset));
      final date        = DateComponents.from(targetDate);
      final prayerTimes = PrayerTimes(coordinates, date, params);

      final List<DateTime> times = [
        prayerTimes.fajr,
        prayerTimes.dhuhr,
        prayerTimes.asr,
        prayerTimes.maghrib,
        prayerTimes.isha,
      ];

      for (int i = 0; i < times.length; i++) {
        final bool isEnabled = prefs.getBool(_prefKeys[i]) ?? true;
        if (!isEnabled) continue;

        final DateTime notifTime =
            times[i].subtract(const Duration(minutes: _minutesBefore));
        if (notifTime.isBefore(now)) continue;

        final dua = shuffled[duaIndex % shuffled.length];
        duaIndex++;

        final String notifTitle =
            '🕌 ${_prayerNames[i]} in $_minutesBefore minutes';

        // Unique stable ID: dayOffset 0-6, prayer index 0-4
        final int notifId = (dayOffset * 10) + i;

        final payloadMap = <String, dynamic>{
          'arabic':    dua['arabic']    ?? '',
          'english':   dua['english']   ?? '',
          'title':     notifTitle,
          'dua_title': dua['title']     ?? '',
          'reference': dua['reference'] ?? '',
          'type':      'dua',
          'azan_time': times[i].toIso8601String(),
          'prayer':    _prayerNames[i],
        };

        await _plugin.zonedSchedule(
          notifId,
          notifTitle,
          dua['title'] ?? 'Islamic Reminder',
          tz.TZDateTime.from(notifTime, tz.local),
          _buildNotificationDetails(
            channel:     _prayerChannels[i],   // ← per-prayer channel
            title:       notifTitle,
            arabicText:  dua['arabic']  ?? '',
            englishText: dua['english'] ?? '',
            duaTitle:    dua['title']   ?? '',
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: jsonEncode(payloadMap),
        );

        newHistoryEntries.add(jsonEncode({
          ...payloadMap,
          'time':   notifTime.toIso8601String(),
          'isRead': false,
        }));
      }
    }

    final allHistory = [...pastHistory, ...newHistoryEntries];
    await prefs.setStringList('notification_history', allHistory);
  }

  // ─── Cancel All ───────────────────────────────────────────────────────────
  static Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  // ─── Public helpers ───────────────────────────────────────────────────────
  static void clearDuaCache() {
    _duaCache = [];
  }

  // Call this in main.dart after app resumes — reschedules if Android killed alarms
  static Future<void> rescheduleIfNeeded() async {
    final prefs       = await SharedPreferences.getInstance();
    final lastLat     = prefs.getDouble('last_lat');
    final lastLng     = prefs.getDouble('last_lng');
    final masterEnabled = prefs.getBool('notif_enabled') ?? true;

    if (!masterEnabled) return;

    final pending = await _plugin.pendingNotificationRequests();
    if (pending.isEmpty && lastLat != null && lastLng != null) {
      await scheduleNotifications(lat: lastLat, lng: lastLng);
    }
  }
}
