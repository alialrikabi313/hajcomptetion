import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../core/arabic.dart';
import '../../core/constants.dart';
import '../../core/reminder_service.dart';
import '../../core/settings_service.dart';
import '../widgets/app_background.dart';
import '../widgets/glass_card.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _reminder = ReminderService.instance;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _reminder.loadSettings().then((_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _save() => SettingsService.save();

  String _fmt(TimeOfDay t) {
    final h12 = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final period = t.period == DayPeriod.am ? 'صباحاً' : 'مساءً';
    return '${Ar.n(h12)}:${Ar.n(t.minute.toString().padLeft(2, '0'))} $period';
  }

  Future<void> _toggleReminder(bool value) async {
    setState(() => _busy = true);
    final ok = await _reminder.apply(enable: value);
    if (!mounted) return;
    setState(() => _busy = false);
    if (value && !ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لم يُسمح بالإشعارات. فعّلها من إعدادات الجهاز.'),
        ),
      );
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _reminder.time,
      helpText: 'وقت التذكير اليومي',
      builder: (context, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: child ?? const SizedBox.shrink(),
      ),
    );
    if (picked == null) return;
    setState(() => _busy = true);
    await _reminder.apply(enable: _reminder.enabled, at: picked);
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(title: const Text('الإعدادات')),
        body: AppBackground(
          child: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                18,
                kToolbarHeight + 8,
                18,
                28,
              ),
              children: [
                // ===== المظهر =====
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.brightness_6_rounded,
                            color: p.gold,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'المظهر',
                            style: TextStyle(
                              color: p.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ValueListenableBuilder<ThemeMode>(
                        valueListenable: appThemeMode,
                        builder: (context, mode, _) => SegmentedButton<ThemeMode>(
                          segments: const [
                            ButtonSegment(
                              value: ThemeMode.system,
                              label: Text('النظام'),
                              icon: Icon(Icons.phone_android_rounded),
                            ),
                            ButtonSegment(
                              value: ThemeMode.light,
                              label: Text('فاتح'),
                              icon: Icon(Icons.light_mode_rounded),
                            ),
                            ButtonSegment(
                              value: ThemeMode.dark,
                              label: Text('داكن'),
                              icon: Icon(Icons.dark_mode_rounded),
                            ),
                          ],
                          selected: {mode},
                          showSelectedIcon: false,
                          onSelectionChanged: (v) {
                            appThemeMode.value = v.first;
                            _save();
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // ===== المؤقّت =====
                GlassCard(
                  child: Column(
                    children: [
                      _SwitchRow(
                        icon: Icons.timer_rounded,
                        title: 'تشغيل المؤقّت',
                        subtitle:
                            'عند انتهاء الوقت تُحتسب الإجابة خاطئة ويظهر الجواب الصحيح.',
                        value: K.showTimer,
                        onChanged: (v) {
                          setState(() => K.showTimer = v);
                          _save();
                        },
                      ),
                      AnimatedCrossFade(
                        duration: const Duration(milliseconds: 250),
                        crossFadeState: K.showTimer
                            ? CrossFadeState.showFirst
                            : CrossFadeState.showSecond,
                        firstChild: Column(
                          children: [
                            const Divider(height: 26),
                            _SliderRow(
                              icon: Icons.hourglass_bottom_rounded,
                              title: 'مدة السؤال',
                              valueLabel: '${Ar.n(K.secondsPerQuestion)} ثانية',
                              value: K.secondsPerQuestion.toDouble(),
                              min: K.minSeconds.toDouble(),
                              max: K.maxSeconds.toDouble(),
                              divisions:
                                  ((K.maxSeconds - K.minSeconds) / 5).round(),
                              onChanged: (v) => setState(
                                () => K.secondsPerQuestion = v.round(),
                              ),
                              onChangeEnd: (_) => _save(),
                            ),
                          ],
                        ),
                        secondChild: const SizedBox(width: double.infinity),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // ===== التذكير اليومي =====
                if (_reminder.supported) ...[
                  GlassCard(
                    child: Column(
                      children: [
                        _SwitchRow(
                          icon: Icons.notifications_active_rounded,
                          title: 'تذكير يومي',
                          subtitle:
                              'إشعار واحد كل يوم يذكّرك بالمراجعة، بلا إنترنت.',
                          value: _reminder.enabled,
                          onChanged: _busy ? null : _toggleReminder,
                        ),
                        AnimatedCrossFade(
                          duration: const Duration(milliseconds: 250),
                          crossFadeState: _reminder.enabled
                              ? CrossFadeState.showFirst
                              : CrossFadeState.showSecond,
                          firstChild: Column(
                            children: [
                              const Divider(height: 26),
                              InkWell(
                                onTap: _busy ? null : _pickTime,
                                borderRadius: BorderRadius.circular(12),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 6,
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.schedule_rounded,
                                        color: p.gold,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          'وقت التذكير',
                                          style: TextStyle(
                                            color: p.textPrimary,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: p.gold.withValues(alpha: 0.14),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: Text(
                                          _fmt(_reminder.time),
                                          style: TextStyle(
                                            color: p.gold,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13.5,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Align(
                                alignment: AlignmentDirectional.centerStart,
                                child: TextButton.icon(
                                  onPressed: _busy
                                      ? null
                                      : () async {
                                          final ok = await _reminder
                                              .showTestNotification();
                                          if (!context.mounted) return;
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                ok
                                                    ? 'أُرسل إشعار تجريبي الآن.'
                                                    : 'الإشعارات غير مسموحة على هذا الجهاز.',
                                              ),
                                            ),
                                          );
                                        },
                                  icon: const Icon(
                                    Icons.notifications_none_rounded,
                                    size: 18,
                                  ),
                                  label: const Text('إرسال إشعار تجريبي'),
                                ),
                              ),
                            ],
                          ),
                          secondChild: const SizedBox(width: double.infinity),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                GlassCard(
                  child: _SwitchRow(
                    icon: Icons.volume_up_rounded,
                    title: 'المؤثرات الصوتية',
                    subtitle: 'صوت عند الإجابة الصحيحة والخاطئة.',
                    value: K.soundEnabled,
                    onChanged: (v) {
                      setState(() => K.soundEnabled = v);
                      _save();
                    },
                  ),
                ),
                const SizedBox(height: 14),

                // ===== حجم الخط =====
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SliderRow(
                        icon: Icons.format_size_rounded,
                        title: 'حجم الخط',
                        valueLabel: Ar.n(K.fontSize.toStringAsFixed(0)),
                        value: K.fontSize,
                        min: K.minFontSize,
                        max: K.maxFontSize,
                        divisions: (K.maxFontSize - K.minFontSize).round(),
                        onChanged: (v) => setState(() => K.fontSize = v),
                        onChangeEnd: (_) => _save(),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: p.surfaceHigh.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: p.stroke),
                        ),
                        child: Text(
                          'مثال: يجب على الحاج أن يطوف بالبيت سبعة أشواط.',
                          style: TextStyle(
                            fontFamily: fontDisplay,
                            color: p.textPrimary,
                            fontSize: K.fontSize + 3,
                            height: 1.7,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 26),
                Center(
                  child: Text(
                    'الإصدار ٨٫١٫٠',
                    style: TextStyle(color: p.textMuted, fontSize: 12.5),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  const _SwitchRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: p.gold.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: p.gold, size: 21),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: p.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: TextStyle(
                  color: p.textMuted,
                  fontSize: 12.5,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        Switch(value: value, onChanged: onChanged),
      ],
    );
  }
}

class _SliderRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String valueLabel;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final ValueChanged<double> onChanged;
  final ValueChanged<double> onChangeEnd;

  const _SliderRow({
    required this.icon,
    required this.title,
    required this.valueLabel,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
    required this.onChangeEnd,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: p.gold, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: p.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: p.gold.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                valueLabel,
                style: TextStyle(
                  color: p.gold,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        Slider(
          value: value.clamp(min, max),
          min: min,
          max: max,
          divisions: divisions,
          label: valueLabel,
          onChanged: onChanged,
          onChangeEnd: onChangeEnd,
        ),
      ],
    );
  }
}
