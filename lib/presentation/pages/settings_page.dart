import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String difficulty = 'سهل';
  bool timerEnabled = K.showTimer;
  double tempFontSize = K.fontsize;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final data = await SettingsService.loadSettings();
    setState(() {
      difficulty = data['difficulty'];
      timerEnabled = data['showTimer'];
      tempFontSize = data['fontSize'];
      K.passScore = data['passScore'];
      K.fontsize = tempFontSize;
      K.showTimer = timerEnabled;
      _loading = false;
    });
  }

  Future<void> _saveSettings() async {
    await SettingsService.saveSettings(
      difficulty: difficulty,
      showTimer: timerEnabled,
      fontSize: tempFontSize,
      passScore: K.passScore,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0A3D2E),
        body: Center(child: CircularProgressIndicator(color: Colors.amber)),
      );
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF0A3D2E),
        appBar: AppBar(
          backgroundColor: const Color(0xFF06442E),
          title: const Text('الإعدادات'),
          centerTitle: true,
        ),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: ListView(
            children: [
              const SizedBox(height: 10),
              const Text(
                'مستوى الصعوبة',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _buildDifficultySelector(),

              const Divider(color: Colors.white30, height: 40),

              _buildSwitchTile(
                title: 'تشغيل المؤقت',
                value: timerEnabled,
                onChanged: (v) {
                  setState(() {
                    timerEnabled = v;
                    K.showTimer = v;
                  });
                  _saveSettings();
                },
              ),

              const Divider(color: Colors.white30, height: 40),

              const Text(
                'حجم الخط',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
              Slider(
                value: tempFontSize,
                min: 14,
                max: 28,
                divisions: 14,
                label: tempFontSize.toStringAsFixed(0),
                activeColor: Colors.amber,
                inactiveColor: Colors.white24,
                onChanged: (v) {
                  setState(() {
                    tempFontSize = v;
                    K.fontsize = v;
                  });
                  _saveSettings();
                },
              ),
              Center(
                child: Text(
                  'الحجم الحالي: ${tempFontSize.toStringAsFixed(0)}',
                  style: const TextStyle(color: Colors.white54),
                ),
              ),

              const SizedBox(height: 40),
              const Center(
                child: Text(
                  'الإصدار 1.0.0',
                  style: TextStyle(color: Colors.white38, fontSize: 13),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDifficultySelector() {
    return Column(
      children: [
        RadioListTile<String>(
          title: const Text('سهل (يسمح ب5 أخطاء لعبور المرحلة)',
              style: TextStyle(color: Colors.white)),
          activeColor: Colors.amber,
          value: 'سهل',
          groupValue: difficulty,
          onChanged: (v) {
            setState(() {
              difficulty = v!;
              K.passScore = 15;
            });
            _saveSettings();
          },
        ),
        RadioListTile<String>(
          title: const Text('متوسط (يسمح ب3 أخطاء فقط)',
              style: TextStyle(color: Colors.white)),
          activeColor: Colors.amber,
          value: 'متوسط',
          groupValue: difficulty,
          onChanged: (v) {
            setState(() {
              difficulty = v!;
              K.passScore = 17;
            });
            _saveSettings();
          },
        ),
        RadioListTile<String>(
          title: const Text('صعب (يسمح بخطأ واحد فقط)',
              style: TextStyle(color: Colors.white)),
          activeColor: Colors.amber,
          value: 'صعب',
          groupValue: difficulty,
          onChanged: (v) {
            setState(() {
              difficulty = v!;
              K.passScore = 19;
            });
            _saveSettings();
          },
        ),
      ],
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      title: Text(title, style: const TextStyle(color: Colors.white)),
      value: value,
      activeColor: Colors.amber,
      onChanged: onChanged,
    );
  }
}
