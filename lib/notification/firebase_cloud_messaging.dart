import 'dart:async';
import 'dart:typed_data';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';

import '../provider/notification_state.dart';
import '../screen/navigation/bottom_navigator_view.dart';
import '../screen/navigation/bottom_navigator_view_model.dart';
import '../services/camera_notification_service.dart';

Future<void> onBackgroundMessage(RemoteMessage message) async {
  await Firebase.initializeApp();
  
  // 카메라 알림만 처리
  if (message.data['destination'] == 'cameraMain') {
    print('📱 Background camera notification: ${message.data}');
  }
}

class FCM {
  final ns = Get.put(NotificationState());
  var flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  final streamCtlr = StreamController<String>.broadcast();
  final titleCtlr = StreamController<String>.broadcast();
  final bodyCtlr = StreamController<String>.broadcast();

  var channel = AndroidNotificationChannel(
    'sSolutionAlim2', 'sSolutionAlim2',
    description: 'this is sSolution channels',
    importance: Importance.max,
    playSound: true,
    sound: RawResourceAndroidNotificationSound('sounds'),
  );

  setNotifications() {
    foregroundNotification();
    backgroundNotification();
    terminateNotification();
  }

  /// 포그라운드 알림 처리
  foregroundNotification() {
    final Int64List vibrationPattern = Int64List(5);
    vibrationPattern[0] = 0;
    vibrationPattern[1] = 5000;
    vibrationPattern[2] = 0;

    const String darwinNotificationCategoryPlain = 'sSolutions3';

    DarwinNotificationCategory(
      darwinNotificationCategoryPlain,
      actions: <DarwinNotificationAction>[
        DarwinNotificationAction.plain('id_1', 'Action 1'),
        DarwinNotificationAction.plain(
          'id_2',
          'Action 2 (destructive)',
          options: <DarwinNotificationActionOption>{
            DarwinNotificationActionOption.destructive,
          },
        ),
        DarwinNotificationAction.plain(
          'id',
          'Action 3 (foreground)',
          options: <DarwinNotificationActionOption>{
            DarwinNotificationActionOption.foreground,
          },
        ),
        DarwinNotificationAction.plain(
          'id_4',
          'Action 4 (auth required)',
          options: <DarwinNotificationActionOption>{
            DarwinNotificationActionOption.authenticationRequired,
          },
        ),
      ],
      options: <DarwinNotificationCategoryOption>{
        DarwinNotificationCategoryOption.hiddenPreviewShowTitle,
      },
    );

    /// iOS 알림
    const DarwinNotificationDetails iosNotificationDetails =
        DarwinNotificationDetails(
      categoryIdentifier: darwinNotificationCategoryPlain,
      presentBadge: true,
      presentAlert: true,
      presentSound: true,
      sound: 'sounds.wav',
    );

    /// 알림 리스너 (포그라운드)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      if (ns.alimNotiId.contains(message.messageId)) {
        return;
      }
      ns.alimNotiId.add(message.messageId);
      
      print("✅ foreground notification: ${message.data}");
      
      String destination = message.data['destination'];
      String docId = message.data['docId'];
      String type = message.data['type'];
      
      // 카메라 알림만 처리
      if (destination == 'cameraMain') {
        await _handleCameraNotification(docId, type, message);
      }
      
      // 로컬 알림 표시
      flutterLocalNotificationsPlugin.show(
          message.hashCode,
          message.notification?.title,
          message.notification?.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              channel.id,
              channel.name,
              importance: Importance.max,
              priority: Priority.high,
              channelDescription: channel.description,
              icon: '@mipmap/ic_launcher',
              playSound: true,
              sound: RawResourceAndroidNotificationSound('sounds'),
            ),
            iOS: iosNotificationDetails,
          ),
          payload: 'camera_notification');
    });
  }

  /// 백그라운드 알림 처리
  backgroundNotification() async {
    FirebaseMessaging.onMessageOpenedApp.listen(
      (message) async {
        String destination = message.data['destination'];
        String docId = message.data['docId'];
        String type = message.data['type'];

        print('📱 background notification: ${message.data}');

        // 카메라 알림만 처리
        if (destination == 'cameraMain') {
          await _handleCameraNotification(docId, type, message);
        }
      },
    );
  }

  /// 종료 상태에서 알림 처리
  terminateNotification() async {
    RemoteMessage? initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      String destination = initialMessage.data['destination'];
      String docId = initialMessage.data['docId'];
      String type = initialMessage.data['type'];

      print('📱 terminate notification: ${initialMessage.data}');

      // 카메라 알림만 처리
      if (destination == 'cameraMain') {
        await _handleCameraNotification(docId, type, initialMessage);
      }
      
      titleCtlr.sink.add(initialMessage.notification!.title!);
      bodyCtlr.sink.add(initialMessage.notification!.body!);
    }
  }

  /// 카메라 알림 처리
  Future<void> _handleCameraNotification(String docId, String type, RemoteMessage message) async {
    final notificationData = {
      'docId': docId,
      'type': type,
      'cameraUid': message.data['cameraUid'] ?? '',
      'ipcamId': message.data['ipcamId'] ?? '',
      'title': message.notification?.title ?? '',
      'body': message.notification?.body ?? '',
      'createDate': message.data['createDate'] ?? DateTime.now().toIso8601String(), // ⭐ 서버의 createDate 사용
    };

    // ⭐ 알림을 리스트에 추가 (중복 체크 및 정렬 포함)
    ns.addNotification(notificationData);

    // 현재 보고 있는 알림도 업데이트 (하위 호환성)
    ns.notificationData.value = notificationData;

    // 새로운 서비스를 사용하여 알림 정보 저장
    final cameraService = CameraNotificationService();
    cameraService.saveCameraNotificationData(
      docId: docId,
      type: type,
      cameraUid: message.data['cameraUid'] ?? '',
      ipcamId: message.data['ipcamId'] ?? '',
    );

    // 소화장치 안내일 경우 페이지 이동하지 않음
    if (type == '소화장치 안내') {
      return;
    }

    print("📷 FCM message data: ${message.data}");
    print("📷 Notification: ${message.notification?.title} - ${message.notification?.body}");

    // 비디오 페이지로 이동 (가장 최신 영상을 보여줌)
    await openAgentVideoPage(docId, type);
  }

  /// 비디오 페이지로 이동
  Future<void> openAgentVideoPage(String docId, String type) async {
    final cameraService = CameraNotificationService();
    final videoUrl = await cameraService.getVideoUrl(docId);

    // BottomNavigator가 이미 열려있는지 확인
    if (Get.currentRoute == BottomNavigatorView.routeName) {
      // 이미 메인 페이지에 있으면 BottomNavigatorViewModel을 찾아서 경보 탭으로 이동
      try {
        final bottomNavViewModel = Get.find<BottomNavigatorViewModel>();
        bottomNavViewModel.navigateToAlertWithVideo(videoUrl, type);
      } catch (e) {
        // BottomNavigatorViewModel을 찾을 수 없으면 새로 이동
        Get.offAll(() => const BottomNavigatorView());
        await Future.delayed(Duration(milliseconds: 100)); // 페이지 로딩 대기
        final bottomNavViewModel = Get.find<BottomNavigatorViewModel>();
        bottomNavViewModel.navigateToAlertWithVideo(videoUrl, type);
      }
    } else {
      // 다른 페이지에 있으면 BottomNavigator로 이동 후 경보 탭 설정
      Get.offAll(() => const BottomNavigatorView());
      await Future.delayed(Duration(milliseconds: 100)); // 페이지 로딩 대기
      final bottomNavViewModel = Get.find<BottomNavigatorViewModel>();
      bottomNavViewModel.navigateToAlertWithVideo(videoUrl, type);
    }
  }

  dispose() {
    streamCtlr.close();
    bodyCtlr.close();
    titleCtlr.close();
  }
}