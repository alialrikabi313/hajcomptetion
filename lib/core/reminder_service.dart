import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// 🔔 تذكير يومي بالمراجعة (بلا إنترنت، عبر إشعارات الجهاز)
class ReminderService {
  ReminderService._();
  static final ReminderService instance = ReminderService._();

  static const _keyEnabled = 'reminder_enabled';
  static const _keyHour = 'reminder_hour';
  static const _keyMinute = 'reminder_minute';
  static const _notificationId = 1447;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _ready = false;
  bool enabled = false;
  TimeOfDay time = const TimeOfDay(hour: 20, minute: 0);

  bool get supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  /// تحميل الإعداد المحفوظ (بلا تهيئة ثقيلة)
  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    enabled = prefs.getBool(_keyEnabled) ?? false;
    time = TimeOfDay(
      hour: prefs.getInt(_keyHour) ?? 20,
      minute: prefs.getInt(_keyMinute) ?? 0,
    );
  }

  Future<void> _ensureReady() async {
    if (_ready || !supported) return;
    tzdata.initializeTimeZones();
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (_) {
      // يبقى التوقيت الافتراضي إن تعذّرت معرفة المنطقة
    }

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
    );
    _ready = true;
  }

  /// طلب إذن الإشعارات — يعيد true إن كان مسموحاً
  Future<bool> requestPermission() async {
    if (!supported) return false;
    await _ensureReady();

    if (defaultTargetPlatform == TargetPlatform.android) {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      final granted = await android?.requestNotificationsPermission();
      return granted ?? true;
    }

    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    final granted = await ios?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
    return granted ?? false;
  }

  /// تفعيل/تعطيل التذكير وضبط وقته
  Future<bool> apply({required bool enable, TimeOfDay? at}) async {
    if (at != null) time = at;
    enabled = enable;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyEnabled, enabled);
    await prefs.setInt(_keyHour, time.hour);
    await prefs.setInt(_keyMinute, time.minute);

    if (!supported) return false;
    await _ensureReady();
    await _plugin.cancel(id: _notificationId);
    if (!enabled) return true;

    final ok = await requestPermission();
    if (!ok) {
      enabled = false;
      await prefs.setBool(_keyEnabled, false);
      return false;
    }

    await _schedule();
    return true;
  }

  /// إعادة الجدولة عند إقلاع التطبيق (لتبقى فعّالة بعد التحديث أو تغيير الوقت)
  Future<void> rescheduleIfEnabled() async {
    await loadSettings();
    if (!enabled || !supported) return;
    try {
      await _ensureReady();
      await _schedule();
    } catch (_) {
      // لا نُفشل الإقلاع بسبب الإشعارات
    }
  }

  Future<void> _schedule() async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'daily_review',
        'التذكير اليومي',
        channelDescription: 'تذكير يومي بمراجعة أسئلة الحج',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      ),
      iOS: DarwinNotificationDetails(),
    );

    await _plugin.zonedSchedule(
      id: _notificationId,
      title: 'وقت المراجعة 🕋',
      body: 'خصّص دقائق لمراجعة أسئلة الحج اليوم.',
      scheduledDate: _nextInstance(time),
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// إشعار تجريبي فوري ليتأكد المستخدم أن الإشعارات تعمل على جهازه
  Future<bool> showTestNotification() async {
    if (!supported) return false;
    await _ensureReady();
    if (!await requestPermission()) return false;
    await _plugin.show(
      id: _notificationId + 1,
      title: 'تجربة الإشعارات ✅',
      body: 'ستصلك رسالة مثل هذه في وقت التذكير اليومي.',
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_review',
          'التذكير اليومي',
          channelDescription: 'تذكير يومي بمراجعة أسئلة الحج',
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
    return true;
  }

  tz.TZDateTime _nextInstance(TimeOfDay t) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      t.hour,
      t.minute,
    );
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}
