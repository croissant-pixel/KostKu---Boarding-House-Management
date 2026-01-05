import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter/foundation.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  // Initialize notification service
  Future<void> initialize() async {
    if (_isInitialized) return; // Prevent duplicate initialization

    try {
      tz.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('Asia/Jakarta')); // ✅ Set timezone

      const androidSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );
      const iosSettings = DarwinInitializationSettings();
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTap,
      );

      // Request permission (Android 13+)
      await _requestPermissions();

      _isInitialized = true;
      print('✅ NotificationService initialized successfully');
    } catch (e) {
      print('❌ Error initializing notifications: $e');
      // Don't throw error, just log it
    }
  }

  Future<void> _requestPermissions() async {
    try {
      final androidPlugin = _notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      if (androidPlugin != null) {
        // Request notification permission
        final granted = await androidPlugin.requestNotificationsPermission();
        print('📱 Notification permission: $granted');

        // Request exact alarm permission (Android 12+)
        final exactAlarmGranted = await androidPlugin
            .requestExactAlarmsPermission();
        print('⏰ Exact alarm permission: $exactAlarmGranted');
      }
    } catch (e) {
      print('⚠️ Error requesting permissions: $e');
    }
  }

  void _onNotificationTap(NotificationResponse response) {
    print('🔔 Notification tapped: ${response.payload}');
  }

  // ✅ FIXED: Schedule contract reminder with better error handling
  Future<void> scheduleContractReminder({
    required int tenantId,
    required String tenantName,
    required DateTime checkoutDate,
  }) async {
    try {
      // Ensure initialized
      if (!_isInitialized) {
        await initialize();
      }

      // Calculate reminder date (7 days before checkout)
      final reminderDate = checkoutDate.subtract(const Duration(days: 7));

      // Don't schedule if reminder date is in the past
      if (reminderDate.isBefore(DateTime.now())) {
        print('⚠️ Reminder date is in the past, skipping notification');
        return;
      }

      final scheduledDate = tz.TZDateTime.from(reminderDate, tz.local);

      // ✅ Try exact schedule first, fallback to inexact
      try {
        await _notifications.zonedSchedule(
          tenantId,
          '⏰ Kontrak Akan Habis',
          'Kontrak $tenantName akan berakhir dalam 7 hari pada ${_formatDate(checkoutDate)}',
          scheduledDate,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'contract_reminder',
              'Contract Reminders',
              channelDescription: 'Notifications for contract expiry',
              importance: Importance.high,
              priority: Priority.high,
              icon: '@mipmap/ic_launcher',
            ),
            iOS: DarwinNotificationDetails(),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: 'tenant_$tenantId',
        );

        print(
          '✅ Scheduled exact reminder for $tenantName on ${_formatDate(reminderDate)}',
        );
      } catch (e) {
        // ✅ Fallback: Use inexact schedule if exact not permitted
        print('⚠️ Exact alarm not permitted, using inexact schedule: $e');

        await _notifications.zonedSchedule(
          tenantId,
          '⏰ Kontrak Akan Habis',
          'Kontrak $tenantName akan berakhir dalam 7 hari pada ${_formatDate(checkoutDate)}',
          scheduledDate,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'contract_reminder',
              'Contract Reminders',
              channelDescription: 'Notifications for contract expiry',
              importance: Importance.high,
              priority: Priority.high,
              icon: '@mipmap/ic_launcher',
            ),
            iOS: DarwinNotificationDetails(),
          ),
          androidScheduleMode:
              AndroidScheduleMode.inexactAllowWhileIdle, // ✅ Inexact
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: 'tenant_$tenantId',
        );

        print('✅ Scheduled inexact reminder for $tenantName');
      }
    } catch (e) {
      // ✅ Don't throw error, just log it
      print('❌ Error scheduling contract reminder: $e');

      // Show user-friendly message in debug mode
      if (kDebugMode) {
        print(
          '💡 Tenant saved successfully, but notification scheduling failed',
        );
        print('💡 This is OK - the app will still work normally');
      }
    }
  }

  // Schedule daily check for expiring contracts
  Future<void> scheduleDailyContractCheck() async {
    try {
      if (!_isInitialized) await initialize();

      final now = DateTime.now();
      final tomorrow = DateTime(now.year, now.month, now.day + 1, 9, 0);
      final scheduledDate = tz.TZDateTime.from(tomorrow, tz.local);

      await _notifications.zonedSchedule(
        999,
        '🏠 KostKu - Cek Kontrak Harian',
        'Ada kontrak yang akan berakhir minggu ini',
        scheduledDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'daily_check',
            'Daily Contract Check',
            channelDescription: 'Daily check for expiring contracts',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );

      print('✅ Scheduled daily contract check');
    } catch (e) {
      print('⚠️ Error scheduling daily check: $e');
    }
  }

  // Cancel notification for a tenant
  Future<void> cancelContractReminder(int tenantId) async {
    try {
      await _notifications.cancel(tenantId);
      print('✅ Cancelled reminder for tenant $tenantId');
    } catch (e) {
      print('⚠️ Error cancelling reminder: $e');
    }
  }

  // Show immediate notification
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      if (!_isInitialized) await initialize();

      await _notifications.show(
        id,
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'general',
            'General Notifications',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
        payload: payload,
      );
    } catch (e) {
      print('⚠️ Error showing notification: $e');
    }
  }

  // Get pending notifications
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    try {
      return await _notifications.pendingNotificationRequests();
    } catch (e) {
      print('⚠️ Error getting pending notifications: $e');
      return [];
    }
  }

  // Cancel all notifications
  Future<void> cancelAllNotifications() async {
    try {
      await _notifications.cancelAll();
      print('✅ Cancelled all notifications');
    } catch (e) {
      print('⚠️ Error cancelling all notifications: $e');
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
