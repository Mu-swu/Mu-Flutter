import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

class NotificationService {
  NotificationService._privateConstructor();

  static final NotificationService instance =
  NotificationService._privateConstructor();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Seoul'));

    const AndroidInitializationSettings androidSettings =
    AndroidInitializationSettings('ic_notification');

    const DarwinInitializationSettings iosSettings =
    DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _flutterLocalNotificationsPlugin.initialize(settings);

    if (Platform.isAndroid) {
      // permission_handler 사용
      final status = await Permission.notification.status;
      if (!status.isGranted) {
        await Permission.notification.request();
      }
      // (플러그인 자체 요청 API도 안전하게 호출)
      await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    }
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduleDate,
  }) async {
    final status = await Permission.scheduleExactAlarm.status;

    if (!status.isGranted) {
      // 권한이 없으면 사용자에게 설정 변경을 유도
      await openAppSettings();
      // 알림이 예약되지 않았음을 알리는 로그를 추가하거나 팝업을 띄울 수 있습니다.
      print("🚨 알림 예약 실패: 정확한 알람 권한이 없습니다. 설정에서 mu 앱의 권한을 확인해주세요.");
      return;
    }
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    final tz.TZDateTime tzScheduledDate = tz.TZDateTime.from(
      scheduleDate,
      tz.local,
    );
    if (tzScheduledDate.isBefore(now)) {
      return;
    }

    AndroidScheduleMode mode = AndroidScheduleMode.exactAllowWhileIdle;
    try {
      final exact = await Permission.scheduleExactAlarm.status;
      if (!exact.isGranted) {
        // 폴백: inexact로라도 스케줄
        mode = AndroidScheduleMode.inexactAllowWhileIdle;
        print("⚠️ exact alarm 미허용 → inexact로 폴백합니다.");
      }
    } catch (_) {
      // API 미지원 기기 등은 그대로 진행
    }
    const AndroidNotificationDetails androidDetails =
    AndroidNotificationDetails(
      'd_day_channel_id',
      'D-Day 임박 알림',
      channelDescription: '보관함 아이템의 기한 임박 시 알림을 보냅니다.',
      importance: Importance.high,
      priority: Priority.high,
      subText: 'MU',
      largeIcon: DrawableResourceAndroidBitmap('ic_launcher'),

    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,

    );

    await _flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tzScheduledDate,
      const NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      ),
      androidScheduleMode: mode,
    );
  }

  Future<void> cancelAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
  }
}
