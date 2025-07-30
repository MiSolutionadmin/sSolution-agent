import 'dart:async';

import 'package:get/get.dart';

class NotificationState extends GetxController{
  final alertTurnOffList = [].obs;
  final alimNotiId = [].obs;
  /// water tank
  final lowHighType = 0.obs;

  RxBool cameraDialogOpen = false.obs;

  /// camera
  final cameraType = 0.obs;
  final cameraNoti = false.obs;
  final fireStationSend = false.obs;
  final cameraNotiCanCel = ''.obs; /// 알림해제사유
  final cameraNotiCheckEmail = ''.obs; /// 알림해제사유 한 사람
  /// 소방수신기 경보 알림 리스트
  final notiFireList = [].obs;

  final notiDocId = ''.obs;

  /// 알림 단일 데이터
  final notificationData = {}.obs;

  /// 알림 리스트
  final notificationList = [].obs;

  NotificationState() {
    // 생성자에서 주기적으로 확인
    Timer.periodic(Duration(seconds: 10), (_) => removeExpiredNotifications());
  }

  void removeExpiredNotifications() {
    final now = DateTime.now();

    print('[removeExpiredNotifications] 실행됨: ${now.toIso8601String()}');

    notificationList.removeWhere((item) {
      try {
        final rawDate = item['createDate'];

        if (rawDate == null) return true;

        // ✅ 문자열 그대로 DateTime으로 변환 가능
        final createDate = DateTime.parse(rawDate);
        final diff = now.difference(createDate).inMinutes;

        print('→ 알림 createDate: $createDate | 경과 시간: ${diff}분');

        return diff >= 1;
      } catch (e) {
        print('🛑 알림 제거 중 오류: $e');
        return true;
      }
    });
  }
}