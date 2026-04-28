import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_service.dart'; // ✅ ADDED: to reschedule on save
import 'notification_history_screen.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  bool _notificationsEnabled = true;
  bool _fajrEnabled    = true;
  bool _dhuhrEnabled   = true;
  bool _asrEnabled     = true;
  bool _maghribEnabled = true;
  bool _ishaEnabled    = true;
  bool _isLoading      = true;
  bool _isSaving       = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notif_enabled') ?? true;
      _fajrEnabled          = prefs.getBool('notif_fajr')    ?? true;
      _dhuhrEnabled         = prefs.getBool('notif_dhuhr')   ?? true;
      _asrEnabled           = prefs.getBool('notif_asr')     ?? true;
      _maghribEnabled       = prefs.getBool('notif_maghrib') ?? true;
      _ishaEnabled          = prefs.getBool('notif_isha')    ?? true;
      _isLoading            = false;
    });
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notif_enabled',  _notificationsEnabled);
    await prefs.setBool('notif_fajr',     _fajrEnabled);
    await prefs.setBool('notif_dhuhr',    _dhuhrEnabled);
    await prefs.setBool('notif_asr',      _asrEnabled);
    await prefs.setBool('notif_maghrib',  _maghribEnabled);
    await prefs.setBool('notif_isha',     _ishaEnabled);

    // ✅ FIXED: Re-schedule notifications so changes take effect immediately
    await NotificationService.scheduleNotifications();

    setState(() => _isSaving = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Settings saved — notifications updated ✅'),
          backgroundColor: const Color(0xFF9966CC),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5FB),
      appBar: AppBar(
        title: const Text(
          'Notification Settings',
          style: TextStyle(color: Color(0xFF2D1B4E), fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2D1B4E)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF9966CC)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── History Shortcut ──────────────────────────────────────
                  _sectionLabel('HISTORY'),
                  _historyShortcutCard(),
                  const SizedBox(height: 25),

                  // ── Master Toggle ─────────────────────────────────────────
                  _sectionLabel('GENERAL'),
                  _sectionCard(
                    child: _toggleRow(
                      'Allow Notifications',
                      _notificationsEnabled,
                      (v) => setState(() => _notificationsEnabled = v),
                    ),
                  ),
                  const SizedBox(height: 25),

                  // ── Per-Prayer Toggles ────────────────────────────────────
                  _sectionLabel('PRAYER REMINDERS'),
                  AnimatedOpacity(
                    opacity: _notificationsEnabled ? 1.0 : 0.4,
                    duration: const Duration(milliseconds: 200),
                    child: IgnorePointer(
                      ignoring: !_notificationsEnabled,
                      child: _sectionCard(
                        padding: EdgeInsets.zero,
                        child: Column(
                          children: [
                            _toggleRow('Fajr',    _fajrEnabled,    (v) => setState(() => _fajrEnabled    = v)),
                            const Divider(height: 1),
                            _toggleRow('Dhuhr',   _dhuhrEnabled,   (v) => setState(() => _dhuhrEnabled   = v)),
                            const Divider(height: 1),
                            _toggleRow('Asr',     _asrEnabled,     (v) => setState(() => _asrEnabled     = v)),
                            const Divider(height: 1),
                            _toggleRow('Maghrib', _maghribEnabled, (v) => setState(() => _maghribEnabled = v)),
                            const Divider(height: 1),
                            _toggleRow('Isha',    _ishaEnabled,    (v) => setState(() => _ishaEnabled    = v)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  _saveButton(),
                ],
              ),
            ),
    );
  }

  // ── Widgets ───────────────────────────────────────────────────────────────

  Widget _historyShortcutCard() {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const NotificationHistoryScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color:        Colors.white,
          borderRadius: BorderRadius.circular(14),
          border:       Border.all(color: const Color(0xFFD4B8E8)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color:        const Color(0xFFEDE5F8),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.history_rounded, color: Color(0xFF9966CC)),
            ),
            const SizedBox(width: 15),
            const Expanded(
              child: Text(
                'View Notification History',
                style: TextStyle(
                    fontWeight: FontWeight.w600, color: Color(0xFF2D1B4E)),
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFFD4B8E8)),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize:    12,
          fontWeight:  FontWeight.bold,
          color:       const Color(0xFF2D1B4E).withOpacity(0.5),
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  Widget _sectionCard({required Widget child, EdgeInsets? padding}) {
    return Container(
      padding: padding ?? const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.circular(14),
        border:       Border.all(color: const Color(0xFFD4B8E8)),
      ),
      child: child,
    );
  }

  Widget _toggleRow(String label, bool value, Function(bool) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF2D1B4E)),
            ),
          ),
          Switch(
            value:       value,
            onChanged:   onChanged,
            activeColor: const Color(0xFF9966CC),
          ),
        ],
      ),
    );
  }

  Widget _saveButton() {
    return SizedBox(
      width:  double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _saveSettings,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF9966CC),
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFF9966CC).withOpacity(0.6),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: _isSaving
            ? const SizedBox(
                width:  22,
                height: 22,
                child:  CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2),
              )
            : const Text(
                'Save Changes',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }
}
