import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:adhan/adhan.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

import '../screens/notification_detail_screen.dart';
import '../main.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  // Full dua database for notifications
  static const List<Map<String, String>> _duaDatabase = [
    {
      'arabic':    'اللَّهُمَّ إِنِّي أَعُوذُ بِكَ مِنَ الْهَمِّ وَالْحَزَنِ',
      'english':   'O Allah I seek refuge in You from anxiety and sorrow',
      'reference': 'Sahih Bukhari',
      'title':     'Prayer for relief from anxiety and sorrow',
    },
    {
      'arabic':    'اللَّهُمَّ لَا سَهْلَ إِلَّا مَا جَعَلْتَهُ سَهْلًا',
      'english':   'O Allah there is no ease except what You make easy',
      'reference': 'Ibn Hibban',
      'title':     'Prayer for seeking ease in difficult matters',
    },
    {
      'arabic':    'حَسْبُنَا اللَّهُ وَنِعْمَ الْوَكِيلُ',
      'english':   'Allah is sufficient for us and He is the best disposer of affairs',
      'reference': 'Quran 3:173',
      'title':     'Prayer for reliance and trust upon Allah',
    },
    {
      'arabic':    'يَا حَيُّ يَا قَيُّومُ بِرَحْمَتِكَ أَسْتَغِيثُ',
      'english':   'O Ever Living O Sustainer by Your mercy I seek relief',
      'reference': 'Tirmidhi',
      'title':     'Prayer for seeking mercy and relief from hardship',
    },
    {
      'arabic':    'اللَّهُمَّ أَعِنِّي عَلَى ذِكْرِكَ وَشُكْرِكَ وَحُسْنِ عِبَادَتِكَ',
      'english':   'O Allah help me to remember You to be grateful to You and to worship You in an excellent manner',
      'reference': 'Abu Dawud',
      'title':     'Prayer for help in remembrance gratitude and worship',
    },
    {
      'arabic':    'يَا مُقَلِّبَ الْقُلُوبِ ثَبِّتْ قَلْبِي عَلَى دِينِكَ',
      'english':   'O Turner of hearts make my heart steadfast upon Your religion',
      'reference': 'Tirmidhi',
      'title':     'Prayer for steadfastness in faith and righteous deeds',
    },
    {
      'arabic':    'رَبِّ اشْرَحْ لِي صَدْرِي وَيَسِّرْ لِي أَمْرِي',
      'english':   'My Lord expand my chest for me and ease my task for me',
      'reference': 'Quran 20:25-26',
      'title':     'Prayer for expansion of the chest and ease in affairs',
    },
    {
      'arabic':    'لَا إِلَهَ إِلَّا أَنْتَ سُبْحَانَكَ إِنِّي كُنْتُ مِنَ الظَّالِمِينَ',
      'english':   'There is no deity except You exalted are You indeed I have been of the wrongdoers',
      'reference': 'Quran 21:87',
      'title':     'Prayer of the distressed person seeking Allah alone',
    },
    {
      'arabic':    'اللَّهُمَّ أَصْلِحْ لِي دِينِي وَدُنْيَايَ وَآخِرَتِي',
      'english':   'O Allah rectify for me my religion my worldly life and my hereafter',
      'reference': 'Sahih Muslim',
      'title':     'Prayer for improvement of religion worldly life and hereafter',
    },
    {
      'arabic':    'رَبَّنَا تَقَبَّلْ مِنَّا إِنَّكَ أَنْتَ السَّمِيعُ الْعَلِيمُ',
      'english':   'Our Lord accept from us indeed You are the All Hearing the All Knowing',
      'reference': 'Quran 2:127',
      'title':     'Prayer for acceptance of repentance and purification',
    },
    {
      'arabic':    'الْحَمْدُ لِلَّهِ الَّذِي بِنِعْمَتِهِ تَتِمُّ الصَّالِحَاتُ',
      'english':   'Praise be to Allah by whose grace good deeds are completed',
      'reference': 'Ibn Majah',
      'title':     'Prayer of gratitude for the completion of good deeds',
    },
    {
      'arabic':    'بِسْمِ اللَّهِ الَّذِي لَا يَضُرُّ مَعَ اسْمِهِ شَيْءٌ',
      'english':   'In the name of Allah with whose name nothing on earth or heaven can cause harm',
      'reference': 'Abu Dawud',
      'title':     'Prayer for protection from all harm',
    },
    {
      'arabic':    'اللَّهُمَّ إِنِّي أَسْأَلُكَ الْعَافِيَةَ فِي الدُّنْيَا وَالْآخِرَةِ',
      'english':   'O Allah I ask You for wellbeing in this world and the hereafter',
      'reference': 'Abu Dawud',
      'title':     'Prayer for a good life and protection from harm',
    },
    {
      'arabic':    'رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً وَفِي الْآخِرَةِ حَسَنَةً',
      'english':   'Our Lord give us good in this world and good in the hereafter and protect us from the punishment of the Fire',
      'reference': 'Quran 2:201',
      'title':     'Prayer for goodness in this world and the hereafter',
    },
    {
      'arabic':    'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ سُبْحَانَ اللَّهِ الْعَظِيمِ',
      'english':   'Glory be to Allah and praise be to Him glory be to Allah the Magnificent',
      'reference': 'Sahih Bukhari',
      'title':     'Glorification and praise of Allah the Magnificent',
    },
  ];

  static Future<void> init() async {
    tz.initializeTimeZones();
    
    // --- THIS IS THE CRITICAL FIX ---
    try {
      // Receive it as a dynamic type instead of strict String
      final dynamic localTz = await FlutterTimezone.getLocalTimezone();
      String timeZoneName;
      
      // Handle both cases depending on what your package version returns
      if (localTz is String) {
        timeZoneName = localTz;
      } else {
        // If it's a TimezoneInfo object, safely extract the name
        try {
          timeZoneName = localTz.name;
        } catch (_) {
          timeZoneName = localTz.toString();
        }
      }
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (e) {
      // Safe Fallback to Malaysia if anything fails!
      tz.setLocalLocation(tz.getLocation('Asia/Kuala_Lumpur'));
    }
    // ---------------------------------

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios     = DarwinInitializationSettings();
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: _onNotificationTap,
    );
  }

  static void _onNotificationTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null) return;
    final parts = payload.split('||');
    if (parts.length < 5) return;

    navigatorKey.currentState?.push(MaterialPageRoute(
      builder: (_) => NotificationDetailScreen(
        arabic:    parts[0],
        english:   parts[1],
        title:     parts[2],
        reference: parts[3],
        type:      parts[4],
      ),
    ));
  }

  static Future<void> cancelAll() async => await _plugin.cancelAll();

  static Future<void> showTestNotification() async {
    final dua = _duaDatabase[Random().nextInt(_duaDatabase.length)];
    await _plugin.show(
      99,
      'NurQalby Reminder 🕌',
      dua['title'],
      NotificationDetails(
        android: AndroidNotificationDetails(
          'prayer_channel', 'Prayer Reminders',
          importance: Importance.max,
          priority:   Priority.max,
          icon:       '@mipmap/ic_launcher',
          color:      const Color(0xFF1a3a2a),
          styleInformation: BigTextStyleInformation(
            '${dua['arabic']}\n\n${dua['english']}',
            contentTitle: 'NurQalby Reminder 🕌',
          ),
        ),
      ),
      payload: '${dua['arabic']}||${dua['english']}||${dua['title']}||${dua['reference']}||dua',
    );
  }

  static Map<String, String> _getRandomDua(int prayerIndex) {
    final offset = (DateTime.now().day * 5 + prayerIndex) % _duaDatabase.length;
    return _duaDatabase[offset];
  }

  static Future<void> _saveToHistory({
    required String arabic,
    required String english,
    required String title,
    required String reference,
    required String type,
    required DateTime scheduledTime,
  }) async {
    final prefs   = await SharedPreferences.getInstance();
    List<String> history = prefs.getStringList('notification_history') ?? [];

    final dateString = "${scheduledTime.year}-${scheduledTime.month}-${scheduledTime.day}";

    history.removeWhere((s) {
      final map = jsonDecode(s);
      if (map['title'] != title) return false;
      try {
        final mapTime = DateTime.parse(map['time']);
        final mapDateString = "${mapTime.year}-${mapTime.month}-${mapTime.day}";
        return mapDateString == dateString;
      } catch (_) {
        return false;
      }
    });

    history.add(jsonEncode({
      'arabic':    arabic,
      'english':   english,
      'title':     title,
      'reference': reference,
      'type':      type,
      'time':      scheduledTime.toIso8601String(),
    }));

    history.sort((a, b) {
      final timeA = DateTime.parse(jsonDecode(a)['time']);
      final timeB = DateTime.parse(jsonDecode(b)['time']);
      return timeA.compareTo(timeB);
    });

    if (history.length > 50) history = history.sublist(history.length - 50);
    await prefs.setStringList('notification_history', history);
  }

  static DateTime? _getPrayerNotifTime(
      Coordinates coords, CalculationParameters params, int idx, int dayOffset) {
    final target = DateTime.now().add(Duration(days: dayOffset));
    final times  = PrayerTimes(coords, DateComponents.from(target), params);
    final list   = [times.fajr, times.dhuhr, times.asr, times.maghrib, times.isha];
    return list[idx].subtract(const Duration(minutes: 10));
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

    final prayerNames    = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];
    final prayerEnabled  = [fajrEnabled, dhuhrEnabled, asrEnabled, maghribEnabled, ishaEnabled];
    final now = DateTime.now();

    for (int i = 0; i < 5; i++) {
      if (!prayerEnabled[i]) continue;

      DateTime? notifTime = _getPrayerNotifTime(coords, params, i, 0);
      if (notifTime == null || notifTime.isBefore(now)) {
        notifTime = _getPrayerNotifTime(coords, params, i, 1);
      }
      if (notifTime == null) continue;

      final dua = _getRandomDua(i);
      final notificationTitle = '${prayerNames[i]} Reminder';

      await _saveToHistory(
        arabic:        dua['arabic']!,
        english:       dua['english']!,
        title:         notificationTitle,
        reference:     dua['reference']!,
        type:          'dua',
        scheduledTime: notifTime,
      );

      await _plugin.zonedSchedule(
        100 + i,
        'Time to prepare for ${prayerNames[i]} 🕌',
        dua['title'],
        tz.TZDateTime.from(notifTime, tz.local),
        NotificationDetails(
          android: AndroidNotificationDetails(
            'prayer_channel',
            'Prayer Reminders',
            channelDescription: 'Quran dua reminders before prayer times',
            importance:  Importance.max,
            priority:    Priority.max,
            icon:        '@mipmap/ic_launcher',
            color:       const Color(0xFF1a3a2a),
            playSound:   true,
            enableVibration: true,
            styleInformation: BigTextStyleInformation(
              '${dua['arabic']}\n\n${dua['english']}',
              contentTitle: 'Time to prepare for ${prayerNames[i]} 🕌',
            ),
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        payload: '${dua['arabic']}||${dua['english']}||$notificationTitle||${dua['reference']}||dua',
      );
    }
  }
}