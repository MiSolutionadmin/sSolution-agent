
import 'dart:typed_data';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:timezone/data/latest.dart' as tz;
import '../db/notificatioin_table.dart';
import '../provider/notification_state.dart';
import 'alert/alert_collecting_well.dart';
import 'alert/alert_fire_receiver.dart';
import 'alert/alert_septic_tank.dart';
import 'alert/alert_transformer.dart';
import 'alert/alert_water_tank.dart';
class LocalNotifyCation {

  final ns = Get.put(NotificationState());
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  //initialized
  Future<void> initializeNotification() async {

    tz.initializeTimeZones();
    // 진동 시작 전 대기 시간 (0초)
    ///IOS
    final DarwinInitializationSettings initializationSettingsIOS = DarwinInitializationSettings(
        requestSoundPermission: true,
        requestBadgePermission: true,
        requestAlertPermission: true,
        defaultPresentAlert: true,
        defaultPresentBadge: true,
        defaultPresentSound: true,
        defaultPresentList: true,
        );
    /// 안드로이드
    var initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher'); // <- default icon name is @mipmap/ic_launcher

    final InitializationSettings initializationSettings = InitializationSettings(
      iOS: initializationSettingsIOS,
      android: initializationSettingsAndroid,
    );

    await flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onDidReceiveNotificationResponse: selectNotification,
    );
  }

  Future onDidbackNotification(int id, String? title, String? body, String? payload) async {
    print('test notification print');
  }
  /// foreground 상태
  void selectNotification(NotificationResponse payloads,) async {
    List<String> data = [payloads.payload!];

  /// 문자열에서 값을 직접 추출
    String payloadString = data[0];
    RegExp regExp = RegExp(r'(\w+):\s*([\w\d-]+)');
    Map<String, dynamic> dataMap = Map.fromEntries(regExp.allMatches(payloadString).map((match) =>
        MapEntry(match.group(1)!, match.group(2)!)
    ));
    String destination = dataMap['destination'];
    String docId = dataMap['docId'];
    String type = dataMap['type'];
    String deviceId = dataMap['deviceId'];
    List notificationList = await getAlimNotification(docId);
    switch (destination) {
      case 'AlertFireReceiver':
        ns.notiDocId.value = docId; /// 알림 닥아이디
        ns.alertTurnOffList.value = ['소방수신기 오작동','소방서 신고','불꽃 원인 해결','테스트 및 시험','기타 (직접입력)'];
        ns.notiFireList.clear(); /// 해당 시도 시군구 담을라고
        Get.to(()=>AlertFireReceiver(alarm: true,mms: deviceId,mmsNotiList: notificationList));
        break;
      case 'AlertCollectingWell':
        ns.notiDocId.value = docId; /// 알림 닥아이디
        ns.alertTurnOffList.value = ['소방수신기 오작동','소방서 신고','불꽃 원인 해결','테스트 및 시험','기타 (직접입력)'];
        ns.notiFireList.clear(); /// 해당 시도 시군구 담을라고
        Get.to(()=>AlertCollectingWell(alarm: true,mms: deviceId,mmsNotiList: notificationList));
        break;
      case 'AlertWaterTank':
        ns.notiDocId.value = docId; /// 알림 닥아이디
        ns.alertTurnOffList.value = ['소방수신기 오작동','소방서 신고','불꽃 원인 해결','테스트 및 시험','기타 (직접입력)'];
        ns.lowHighType.value = int.parse(type); /// 0이면 고수위 1이면 저수위
        ns.notiFireList.clear(); /// 해당 시도 시군구 담을라고
        Get.to(()=>AlertWaterTank(alarm: true,mms: deviceId,mmsNotiList: notificationList));
        break;
      case 'AlertTransFormer':
        ns.notiDocId.value = docId; /// 알림 닥아이디
        ns.alertTurnOffList.value = ['소방수신기 오작동','소방서 신고','불꽃 원인 해결','테스트 및 시험','기타 (직접입력)'];
        ns.notiFireList.clear(); /// 해당 시도 시군구 담을라고
        Get.to(()=>AlertTransFormer(alarm: true,mms: deviceId,mmsNotiList: notificationList));
        break;
      case 'AlertSepticTank':
        ns.notiDocId.value = docId; /// 알림 닥아이디
        ns.alertTurnOffList.value = ['소방수신기 오작동','소방서 신고','불꽃 원인 해결','테스트 및 시험','기타 (직접입력)'];
        ns.notiFireList.clear(); /// 해당 시도 시군구 담을라고
        Get.to(()=>AlertSepticTank(alarm: true,mms: deviceId,mmsNotiList: notificationList));
        break;
    }

  }
}
