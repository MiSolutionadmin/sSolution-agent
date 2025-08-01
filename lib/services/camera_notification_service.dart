import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../base_config/config.dart';
import '../provider/notification_state.dart';
import '../provider/user_state.dart';

/// 카메라 알림 관련 서비스
class CameraNotificationService {
  static final CameraNotificationService _instance = CameraNotificationService._internal();
  factory CameraNotificationService() => _instance;
  CameraNotificationService._internal();

  final config = AppConfig();
  final ns = Get.find<NotificationState>();
  final us = Get.find<UserState>();

  /// FCM에서 받은 카메라 알림 정보 저장
  void saveCameraNotificationData({
    required String docId,
    required String type,
    required String cameraUid,
    required String ipcamId,
  }) {
    ns.notiDocId.value = docId;
    
    // 타입별 알림 해제 리스트 설정
    if (type == '불꽃 감지') {
      ns.alertTurnOffList.value = ['불꽃 감지 오류', '기타 (직접입력)'];
    } else if (type == '연기 감지') {
      ns.alertTurnOffList.value = ['연기 감지 오류', '기타 (직접입력)'];
    } else {
      ns.alertTurnOffList.value = ['센서 감지 오류', '기타 (직접입력)'];
    }

    print("📷 Camera notification saved:");
    print("📷 - docId: $docId");
    print("📷 - type: $type");
    print("📷 - cameraUid: $cameraUid");
    print("📷 - ipcamId: $ipcamId");
  }

  /// 화재/비화재 버튼 클릭 시 서버로 전송
  /// falsePositive: 0 = 화재, 1 = 비화재(오탐)
  Future<void> submitCameraResponse({
    required int falsePositive,
    String? reason,
  }) async {
    final url = '${config.baseUrl}/agents/${us.userData['id']}/works';
    final body = {
      'agentId': us.userData['id'],
      'reason': reason,
      'type': ns.notificationData['type'],
      'notiId': ns.notificationData['docId'],
      'falsePositive': falsePositive,
    };

    try {
      print("📤 Submitting camera response:");
      print("📤 - URL: $url");
      print("📤 - Body: $body");

      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        print("✅ Camera response submitted successfully");
        
        // 알림 리스트에서 해당 알림 제거
        ns.notificationList.removeWhere(
          (item) => item['docId'] == ns.notificationData['docId']
        );
      } else {
        print("❌ Failed to submit camera response: ${response.statusCode}");
        throw Exception('서버 응답 오류: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Camera response submission error: $e');
      rethrow;
    }
  }

  /// 비디오 URL 가져오기
  Future<String> getVideoUrl(String notiDocId) async {
    final url = '${config.baseUrl}/video/$notiDocId';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        print("📹 Video URL retrieved: ${response.body}");
        return response.body;
      } else {
        print("❌ Failed to get video URL: ${response.statusCode}");
        throw Exception('비디오 URL 가져오기 실패');
      }
    } catch (e) {
      print('❌ Video URL error: $e');
      rethrow;
    }
  }

  /// 현재 저장된 알림 정보 확인
  Map<String, dynamic> getCurrentNotificationInfo() {
    return {
      'docId': ns.notiDocId.value,
      'type': ns.notificationData['type'] ?? '',
      'alertTurnOffList': ns.alertTurnOffList,
    };
  }

  /// 알림 정보 초기화
  void clearNotificationData() {
    ns.notiDocId.value = '';
    ns.alertTurnOffList.clear();
    print("📷 Camera notification data cleared");
  }
}