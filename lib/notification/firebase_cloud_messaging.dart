import 'dart:async';
import 'dart:typed_data';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:mms/components/dialogManager.dart';
import 'package:mms/screen/video/video_page.dart';

import '../db/notificatioin_table.dart';
import '../provider/user_state.dart';
import '../routes/app_routes.dart';

import '../components/dialog.dart';
import '../db/camera_table.dart';
import '../provider/camera_state.dart';
import '../provider/notification_state.dart';
import '../screen/navigation/bottom_navigator_view.dart';
import '../screen/monitoring/monitoring_main_screen.dart';
import '../vstarcam/main/main_logic.dart';
import '../vstarcam/play/play_logic.dart';
import '../vstarcam/play/play_page.dart';
import 'alert/alert_collecting_well.dart';
import 'alert/alert_fire_receiver.dart';
import 'alert/alert_septic_tank.dart';
import 'alert/alert_transformer.dart';
import 'alert/alert_water_tank.dart';

Future<void> onBackgroundMessage(RemoteMessage message) async {
  await Firebase.initializeApp();

  if (message.data.containsKey('data')) {
    final data = message.data['data'];
  }

  if (message.data.containsKey('notification')) {
    final notification = message.data['notification'];
  }
}

class FCM {
  final ns = Get.put(NotificationState());
  final us = Get.put(UserState());
  final cs = Get.find<CameraState>();
  var flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  final streamCtlr = StreamController<String>.broadcast();
  final titleCtlr = StreamController<String>.broadcast();
  final bodyCtlr = StreamController<String>.broadcast();

  var channel = AndroidNotificationChannel(
    'sSolutionAlim2', 'sSolutionAlim2',
    description: 'this is sSolution channels', // description
    importance: Importance.max,
    playSound: true,
    sound: RawResourceAndroidNotificationSound('sounds'),
  );

  setNotifications() {
    // FirebaseMessaging.onBackgroundMessage();
    foregroundNotification();
    //
    backgroundNotification();
    //
    terminateNotification();
    // final token =// _firebaseMessaging.getToken().then((value) => print('Token: $value'));
  }

  ///버튼 눌렀을 때 포그라운드
  foregroundNotification() {
    final Int64List vibrationPattern = Int64List(5);

    vibrationPattern[0] = 0; // 진동 시작 전 대기 시간 (0초)
    vibrationPattern[1] = 5000;
    vibrationPattern[2] = 0; // 진동 시작 전 대기 시간 (0초)

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

    ///IOS 알림
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
      print("✅ foreground 2 : ${message.data}");
      String destination = message.data['destination'];
      String docId = message.data['docId'];
      String type = message.data['type'];
      String deviceId = message.data['deviceId'] ?? '';
      List notificationList = await getAlimNotification(docId);
      ns.notificationData.value = notificationList[0];
      Map<String, dynamic> data = await getAllNotificationData();
      ns.notificationList.value =
          List<Map<String, dynamic>>.from(data["notifications"]);
      print(" foreground 3 : ${notificationList}");
      switch (destination) {
        case 'AlertFireReceiver':
          print("✅ foreground 4 : ${notificationList[0]['title']}");
          print("✅ foreground 4.1 : ${notificationList[0]['body']}");
          print("✅ foreground 4.2 : ${notificationList[0]['mms']}");
          print("✅ foreground 4.3 : ${notificationList[0]['mmsName']}");
          Get.dialog(CustomAlertDialog(
            title: '${notificationList[0]['title']}',
            body: '${notificationList[0]['body']}',
            onTap: () {
              Get.back();
              ns.notiDocId.value = docId;

              /// 알림 닥아이디
              ns.alertTurnOffList.value = [
                '소방수신기 오작동',
                '소방서 신고',
                '불꽃 원인 해결',
                '테스트 및 시험',
                '기타 (직접입력)'
              ];
              Get.back();
              Get.to(() => AlertFireReceiver(
                  alarm: true, mms: deviceId, mmsNotiList: notificationList));
            },
            mms: notificationList[0]['mms'],
            mmsName: notificationList[0]['mmsName'],
          ));
          break;
        case 'AlertCollectingWell':
          Get.dialog(CustomAlertDialog(
              title: '${notificationList[0]['title']}',
              body: '${notificationList[0]['body']}',
              onTap: () {
                ns.notiDocId.value = docId;

                /// 알림 닥아이디
                ns.alertTurnOffList.value = [
                  '소방수신기 오작동',
                  '소방서 신고',
                  '불꽃 원인 해결',
                  '테스트 및 시험',
                  '기타 (직접입력)'
                ];
                Get.back();
                Get.to(() => AlertCollectingWell(
                    alarm: true, mms: deviceId, mmsNotiList: notificationList));
              },
              mms: us.hexToChar(notificationList[0]['mms']),
              mmsName: notificationList[0]['mmsName']));
          break;
        case 'AlertWaterTank':
          Get.dialog(CustomAlertDialog(
              title: '${notificationList[0]['title']}',
              body: '${notificationList[0]['body']}',
              onTap: () {
                ns.notiDocId.value = docId;

                /// 알림 닥아이디
                ns.alertTurnOffList.value = [
                  '소방수신기 오작동',
                  '소방서 신고',
                  '불꽃 원인 해결',
                  '테스트 및 시험',
                  '기타 (직접입력)'
                ];
                ns.lowHighType.value = int.parse(type);

                /// 0이면 고수위 1이면 저수위
                Get.back();
                Get.to(() => AlertWaterTank(
                      alarm: true,
                      mms: deviceId,
                      mmsNotiList: notificationList,
                    ));
              },
              mms: us.hexToChar(notificationList[0]['mms']),
              mmsName: notificationList[0]['mmsName']));
          break;
        case 'AlertTransFormer':
          Get.dialog(CustomAlertDialog(
              title: '${notificationList[0]['title']}',
              body: '${notificationList[0]['body']}',
              onTap: () {
                ns.notiDocId.value = docId;

                /// 알림 닥아이디
                ns.alertTurnOffList.value = [
                  '소방수신기 오작동',
                  '소방서 신고',
                  '불꽃 원인 해결',
                  '테스트 및 시험',
                  '기타 (직접입력)'
                ];
                Get.back();
                Get.to(() => AlertTransFormer(
                    alarm: true, mms: deviceId, mmsNotiList: notificationList));
              },
              mms: us.hexToChar(notificationList[0]['mms']),
              mmsName: notificationList[0]['mmsName']));
          break;
        case 'AlertSepticTank':
          Get.dialog(CustomAlertDialog(
              title: '${notificationList[0]['title']}',
              body: '${notificationList[0]['body']}',
              onTap: () {
                ns.notiDocId.value = docId;

                /// 알림 닥아이디
                ns.alertTurnOffList.value = [
                  '소방수신기 오작동',
                  '소방서 신고',
                  '불꽃 원인 해결',
                  '테스트 및 시험',
                  '기타 (직접입력)'
                ];
                Get.back();
                Get.to(() => AlertSepticTank(
                    alarm: true, mms: deviceId, mmsNotiList: notificationList));
              },
              mms: us.hexToChar(notificationList[0]['mms']),
              mmsName: notificationList[0]['mmsName']));
          break;
        case 'AlertFireFighting': // 25-05-09 소방장치
          Get.dialog(CustomAlertDialog(
              title: '${notificationList[0]['title']}',
              body: '${notificationList[0]['body']}',
              onTap: () {
                ns.notiDocId.value = docId;

                /// 알림 닥아이디
                ns.alertTurnOffList.value = [
                  '소방수신기 오작동',
                  '소방서 신고',
                  '불꽃 원인 해결',
                  '테스트 및 시험',
                  '기타 (직접입력)'
                ];
                Get.back();
                Get.to(() => AlertSepticTank(
                    alarm: true, mms: deviceId, mmsNotiList: notificationList));
              },
              mms: us.hexToChar(notificationList[0]['mms']),
              mmsName: notificationList[0]['mmsName']));
          break;
        case 'cameraMain':
          String cameraUid = '${message.data['cameraUid']}';

          /// cameraUId
          String ipcamId = '${message.data['ipcamId']}';

          /// 캠 이름
          String cameraType = '${message.data['type'] ?? 0}';

          // 2. 알림 다이얼로그
          if (Get.isDialogOpen == true) {
            print("다이얼로그 상태 ${Get.isDialogOpen}");
            Get.back();
          }

          ns.notiDocId.value = docId;

          Get.dialog(CameraAlertDialog(
            title: cameraType == "소화장치 안내" ? cameraType : '카메라 알림 경보',
            body: '${notificationList[0]['body']}',
            onTap: () async {
              final isFireFightingGuide = cameraType == '소화장치 안내';
              final isFlameDetection = cameraType == '불꽃 감지';
              final isSmokeDetection = cameraType == '연기 감지';
              final notificationBody = notificationList[0];

              // 확인 버튼을 누를시 다이얼로그를 닫음
              Get.back();

              // 알림 해제 내역 세팅
              if (isFlameDetection) {
                ns.alertTurnOffList.value = ['불꽃 감지 오류', '기타 (직접입력)'];
              } else if (isSmokeDetection) {
                ns.alertTurnOffList.value = ['연기 감지 오류', '기타 (직접입력)'];
              } else {
                ns.alertTurnOffList.value = ['센서 감지 오류', '기타 (직접입력)'];
              }

              // 소화장치일 시 페이지 이동 하지않음.
              if (isFireFightingGuide) {
                return;
              }

              print("type ? ${cameraType}");
              print("ns.alertTurnOffList.value ? ${ns.alertTurnOffList.value}");

              openAgentVideoPage(docId, message.data['type']);
            },
            cameraName: '${notificationList[0]['ipcamId']}',
          ));
          break;
      }
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
          // payload: '${message.data}'
          payload: 'ㅇㄴㅁ');
    });
  }

  backgroundNotification() async {
    FirebaseMessaging.onMessageOpenedApp.listen(
      (message) async {
        String destination = message.data['destination'];
        String docId = message.data['docId'];
        String type = message.data['type'];
        String deviceId = message.data['deviceId'] ?? '';
        List notificationList = await getAlimNotification(docId);
        ns.notificationData.value = notificationList[0];
        Map<String, dynamic> data = await getAllNotificationData();
        ns.notificationList.value =
            List<Map<String, dynamic>>.from(data["notifications"]);

        print('noti 정보? back ${message.data}');

        switch (destination) {
          case 'AlertFireReceiver':
            ns.notiDocId.value = docId;

            /// 알림 닥아이디
            ns.alertTurnOffList.value = [
              '소방수신기 오작동',
              '소방서 신고',
              '불꽃 원인 해결',
              '테스트 및 시험',
              '기타 (직접입력)'
            ];
            Get.to(() => AlertFireReceiver(
                alarm: true, mms: deviceId, mmsNotiList: notificationList));
            break;
          case 'AlertCollectingWell':
            ns.notiDocId.value = docId;

            /// 알림 닥아이디
            ns.alertTurnOffList.value = [
              '소방수신기 오작동',
              '소방서 신고',
              '불꽃 원인 해결',
              '테스트 및 시험',
              '기타 (직접입력)'
            ];
            Get.to(() => AlertCollectingWell(
                alarm: true, mms: deviceId, mmsNotiList: notificationList));
            break;
          case 'AlertWaterTank':
            ns.notiDocId.value = docId;

            /// 알림 닥아이디
            ns.alertTurnOffList.value = [
              '소방수신기 오작동',
              '소방서 신고',
              '불꽃 원인 해결',
              '테스트 및 시험',
              '기타 (직접입력)'
            ];
            ns.lowHighType.value = int.parse(type);

            /// 0이면 고수위 1이면 저수위
            Get.to(() => AlertWaterTank(
                  alarm: true,
                  mms: deviceId,
                  mmsNotiList: notificationList,
                ));
            break;
          case 'AlertTransFormer':
            ns.notiDocId.value = docId;

            /// 알림 닥아이디
            ns.alertTurnOffList.value = [
              '소방수신기 오작동',
              '소방서 신고',
              '불꽃 원인 해결',
              '테스트 및 시험',
              '기타 (직접입력)'
            ];
            Get.to(() => AlertTransFormer(
                alarm: true, mms: deviceId, mmsNotiList: notificationList));
            break;
          case 'AlertSepticTank':
            ns.notiDocId.value = docId;

            /// 알림 닥아이디
            ns.alertTurnOffList.value = [
              '소방수신기 오작동',
              '소방서 신고',
              '불꽃 원인 해결',
              '테스트 및 시험',
              '기타 (직접입력)'
            ];
            Get.to(() => AlertSepticTank(
                alarm: true, mms: deviceId, mmsNotiList: notificationList));
            break;
          case 'cameraMain':
            String cameraType = '${message.data['type'] ?? 0}';

            if (cameraType == '불꽃 감지') {
              ns.alertTurnOffList.value = ['불꽃 감지 오류', '기타 (직접입력)'];
            } else if (cameraType == '연기 감지') {
              ns.alertTurnOffList.value = ['연기 감지 오류', '기타 (직접입력)'];
            } else {
              ns.alertTurnOffList.value = ['센서 감지 오류', '기타 (직접입력)'];
            }

            openAgentVideoPage(docId, message.data['type']);
        }
      },
    );
  }

  /// 종료되었을 떄
  terminateNotification() async {
    RemoteMessage? initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      String destination = initialMessage.data['destination'];
      String docId = initialMessage.data['docId'];
      String type = initialMessage.data['type'];
      String deviceId = initialMessage.data['deviceId'] ?? '';
      List notificationList = await getAlimNotification(docId);
      ns.notificationData.value = notificationList[0];
      Map<String, dynamic> data = await getAllNotificationData();
      ns.notificationList.value =
          List<Map<String, dynamic>>.from(data["notifications"]);

      print('noti 정보? terminate ${initialMessage.data}');

      switch (destination) {
        case 'AlertFireReceiver':
          ns.notiDocId.value = docId;

          /// 알림 닥아이디
          ns.alertTurnOffList.value = [
            '소방수신기 오작동',
            '소방서 신고',
            '불꽃 원인 해결',
            '테스트 및 시험',
            '기타 (직접입력)'
          ];
          Get.to(() => AlertFireReceiver(
              alarm: true, mms: deviceId, mmsNotiList: notificationList));
          break;
        case 'AlertCollectingWell':
          ns.notiDocId.value = docId;

          /// 알림 닥아이디
          ns.alertTurnOffList.value = [
            '소방수신기 오작동',
            '소방서 신고',
            '불꽃 원인 해결',
            '테스트 및 시험',
            '기타 (직접입력)'
          ];
          Get.to(() => AlertCollectingWell(
              alarm: true, mms: deviceId, mmsNotiList: notificationList));
          break;
        case 'AlertWaterTank':
          ns.notiDocId.value = docId;

          /// 알림 닥아이디
          ns.alertTurnOffList.value = [
            '소방수신기 오작동',
            '소방서 신고',
            '불꽃 원인 해결',
            '테스트 및 시험',
            '기타 (직접입력)'
          ];
          ns.lowHighType.value = int.parse(type);

          /// 0이면 고수위 1이면 저수위
          Get.to(() => AlertWaterTank(
                alarm: true,
                mms: deviceId,
                mmsNotiList: notificationList,
              ));
          break;
        case 'AlertTransFormer':
          ns.notiDocId.value = docId;

          /// 알림 닥아이디
          ns.alertTurnOffList.value = [
            '소방수신기 오작동',
            '소방서 신고',
            '불꽃 원인 해결',
            '테스트 및 시험',
            '기타 (직접입력)'
          ];
          ns.lowHighType.value = int.parse(type);

          /// 0이면 고수위 1이면 저수위
          Get.to(() => AlertTransFormer(
              alarm: true, mms: deviceId, mmsNotiList: notificationList));
          break;
        case 'AlertSepticTank':
          ns.notiDocId.value = docId;

          /// 알림 닥아이디
          ns.alertTurnOffList.value = [
            '소방수신기 오작동',
            '소방서 신고',
            '불꽃 원인 해결',
            '테스트 및 시험',
            '기타 (직접입력)'
          ];
          Get.to(() => AlertSepticTank(
              alarm: true, mms: deviceId, mmsNotiList: notificationList));
          break;
        case 'cameraMain':
          String cameraType = '${initialMessage.data['type'] ?? 0}';

          if (cameraType == '불꽃 감지') {
            ns.alertTurnOffList.value = ['불꽃 감지 오류', '기타 (직접입력)'];
          } else if (cameraType == '연기 감지') {
            ns.alertTurnOffList.value = ['연기 감지 오류', '기타 (직접입력)'];
          } else {
            ns.alertTurnOffList.value = ['센서 감지 오류', '기타 (직접입력)'];
          }

          openAgentVideoPage(docId, initialMessage.data['type']);
      }
      titleCtlr.sink.add(initialMessage.notification!.title!);
      bodyCtlr.sink.add(initialMessage.notification!.body!);
    }
  }

  dispose() {
    streamCtlr.close();
    bodyCtlr.close();
    titleCtlr.close();
  }

  /// agent 비디오 다시보기로 이동
  Future<void> openAgentVideoPage(String docId, String type) async {
    // 확인 버튼을 누를시 다이얼로그를 닫음
    Get.back();

    final videoUrl = await getVideoUrl(docId);

    Get.to(() => VideoPage(videoUrl: videoUrl, type: type));
  }

  Future<void> _cameraLogicInit(String cameraUid) async {
    if (Get.currentRoute == AppRoutes.play) {
      if (cameraUid == cs.cameraUID.value) {
        return;
      }
      Get.back();
    }

    //로딩 시작
    Get.dialog(CustomAlertDialog2());

    //DialogManager.showLoginLoading(Build);

    print("??? 111");
    await Future.delayed(Duration(milliseconds: 500));

    print("???");
    // 기존 카메라 장치 제거
    if (cs.cameraDevice != null) {
      await cs.cameraDevice!.deviceDestroy();
    }

    // MainLogic 주입
    if (!Get.isRegistered<MainLogic>()) {
      Get.put(MainLogic());
    }

    final mainLogic = Get.find<MainLogic>();
    await mainLogic.init('$cameraUid', 'admin', '${cs.cameraPassword}');

    print("MainLogic init 완료");
    // 로딩 닫기 (조건부)
    if (Get.isDialogOpen ?? false) {
      Get.back();
    }
  }
}


// class FCMController {
//   final String _serverKey =
//       "AAAA6RlPOZ0:APA91bHl4TNWSQH8O9s83Qbof11BZgLGrBH3AdM0zZiM4C_152I19xwVS_V8pDQ3aJmw3s88V07pGf9sHy41NsGtuFtJqqkB6rrGPjDlXjHG4U_y3fjfQFqacWW4ppIrVJPbjASu38mp";
//
//   Future<void> sendMessage({
//     required String userToken,
//     required String title,
//     required String body,
//   }) async {
//     http.Response response;
//
//     NotificationSettings settings = await FirebaseMessaging.instance.requestPermission(
//       alert: true,
//       announcement: false,
//       badge: true,
//       carPlay: false,
//       criticalAlert: false,
//       provisional: false,
//       sound: true,
//     );
//
//     if (settings.authorizationStatus == AuthorizationStatus.authorized) {
//       print('User granted permission');
//     } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
//       print('User granted provisional permission');
//     } else {
//       print('User declined or has not accepted permission');
//     }
//
//     try {
//       response = await http.post(Uri.parse('https://fcm.googleapis.com/fcm/send'),
//           headers: <String, String>{'Content-Type': 'application/json', 'Authorization': 'key=$_serverKey'},
//           body: jsonEncode({
//             'notification': {'title': title, 'body': body, 'sound': 'true'},
//             'ttl': '60s',
//             "content_available": true,
//             'data': {
//               'click_action': 'FLUTTER_NOTIFICATION_CLICK',
//               'id': '1',
//               'status': 'done',
//               "action": 'clickSound',
//             },
//             // 'topic': 'community',
//             // 상대방 토큰 값, to -> 단일, registration_ids -> 여러명
//             'to': userToken
//             // 'registration_ids': tokenList
//           }));
//     } catch (e) {
//       print('error $e');
//     }
//   }
// }
