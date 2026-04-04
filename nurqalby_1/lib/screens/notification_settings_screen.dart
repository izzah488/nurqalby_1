import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_service.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  bool _notificationsEnabled = true;
  bool _fajrEnabled          = true;
  bool _dhuhrEnabled         = true;
  bool _asrEnabled           = true;
  bool _maghribEnabled       = true;
  bool _ishaEnabled          = true;
  bool _isLoading            = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notif_enabled')  ?? true;
      _fajrEnabled          = prefs.getBool('notif_fajr')     ?? true;
      _dhuhrEnabled         = prefs.getBool('notif_dhuhr')    ?? true;
      _asrEnabled           = prefs.getBool('notif_asr')      ?? true;
      _maghribEnabled       = prefs.getBool('notif_maghrib')  ?? true;
      _ishaEnabled          = prefs.getBool('notif_isha')     ?? true;
      _isLoading            = false;
    });
  }

  Future<void> _saveAndApply() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notif_enabled', _notificationsEnabled);
    await prefs.setBool('notif_fajr',    _fajrEnabled);
    await prefs.setBool('notif_dhuhr',   _dhuhrEnabled);
    await prefs.setBool('notif_asr',     _asrEnabled);
    await prefs.setBool('notif_maghrib', _maghribEnabled);
    await prefs.setBool('notif_isha',    _ishaEnabled);

    if (_notificationsEnabled) {
      await NotificationService.schedulePrayerNotifications(
        latitude:      3.1390,
        longitude:     101.6869,
        fajrEnabled:   _fajrEnabled,
        dhuhrEnabled:  _dhuhrEnabled,
        asrEnabled:    _asrEnabled,
        maghribEnabled: _maghribEnabled,
        ishaEnabled:   _ishaEnabled,
      );
    } else {
      await NotificationService.cancelAll();
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Settings saved'),
          backgroundColor: Color(0xFF1a3a2a),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0),
      body: SafeArea(
        child: Column(
          children: [

            // --- Header ---
            Container(
              width: double.infinity,
              color: const Color(0xFF1a3a2a),
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back_ios,
                        color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Reminders',
                          style: TextStyle(
                              color: Color(0xFF9fd4b0), fontSize: 12)),
                      Text('Notification Settings',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
              ),
            ),

            // --- Body ---
            _isLoading
                ? const Expanded(
                    child: Center(
                      child: CircularProgressIndicator(
                          color: Color(0xFF1a3a2a)),
                    ),
                  )
                : Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [

                        // Master toggle
                        _SectionCard(
                          child: _ToggleRow(
                            icon:    Icons.notifications_rounded,
                            label:   'Prayer Notifications',
                            subtitle: 'Receive verse reminders before prayers',
                            value:   _notificationsEnabled,
                            isMain:  true,
                            onChanged: (val) {
                              setState(() => _notificationsEnabled = val);
                              _saveAndApply();
                            },
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Individual prayer toggles
                        if (_notificationsEnabled) ...[
                          const Padding(
                            padding: EdgeInsets.only(left: 4, bottom: 8),
                            child: Text(
                              'PRAYER TIMES',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey,
                                  letterSpacing: 0.8),
                            ),
                          ),
                          _SectionCard(
                            child: Column(
                              children: [
                                _ToggleRow(
                                  icon:     Icons.wb_twilight_rounded,
                                  label:    'Fajr',
                                  subtitle: '10 min before Fajr',
                                  value:    _fajrEnabled,
                                  onChanged: (val) {
                                    setState(() => _fajrEnabled = val);
                                    _saveAndApply();
                                  },
                                ),
                                _Divider(),
                                _ToggleRow(
                                  icon:     Icons.wb_sunny_rounded,
                                  label:    'Dhuhr',
                                  subtitle: '10 min before Dhuhr',
                                  value:    _dhuhrEnabled,
                                  onChanged: (val) {
                                    setState(() => _dhuhrEnabled = val);
                                    _saveAndApply();
                                  },
                                ),
                                _Divider(),
                                _ToggleRow(
                                  icon:     Icons.light_mode_rounded,
                                  label:    'Asr',
                                  subtitle: '10 min before Asr',
                                  value:    _asrEnabled,
                                  onChanged: (val) {
                                    setState(() => _asrEnabled = val);
                                    _saveAndApply();
                                  },
                                ),
                                _Divider(),
                                _ToggleRow(
                                  icon: Icons.wb_cloudy_rounded,
                                  label:    'Maghrib',
                                  subtitle: '10 min before Maghrib',
                                  value:    _maghribEnabled,
                                  onChanged: (val) {
                                    setState(() => _maghribEnabled = val);
                                    _saveAndApply();
                                  },
                                ),
                                _Divider(),
                                _ToggleRow(
                                  icon:     Icons.nightlight_round,
                                  label:    'Isha',
                                  subtitle: '10 min before Isha',
                                  value:    _ishaEnabled,
                                  onChanged: (val) {
                                    setState(() => _ishaEnabled = val);
                                    _saveAndApply();
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Info card
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFf0f7f3),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: const Color(0xFFc8e6d4)),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.info_outline,
                                    color: Color(0xFF5a8a6a), size: 18),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Notifications will show a Quran verse 10 minutes before each selected prayer time.',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF5a8a6a)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// Helper widgets
// ─────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final Widget child;
  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: child,
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final IconData icon;
  final String   label;
  final String   subtitle;
  final bool     value;
  final bool     isMain;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.isMain = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width:  36,
            height: 36,
            decoration: BoxDecoration(
              color:        const Color(0xFFf0f7f3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon,
                color: const Color(0xFF1a3a2a),
                size: isMain ? 20 : 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize:   isMain ? 15 : 14,
                        fontWeight: FontWeight.w500,
                        color:      Colors.black87)),
                Text(subtitle,
                    style: const TextStyle(
                        fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
          Switch(
            value:            value,
            onChanged:        onChanged,
            activeColor:      const Color(0xFF1a3a2a),
            activeTrackColor: const Color(0xFFc8e6d4),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, color: Color(0xFFEEEEEE));
  }
}