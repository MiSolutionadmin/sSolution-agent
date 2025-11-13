import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../base_config/config.dart';
import '../provider/notification_state.dart';
import '../provider/user_state.dart';
import '../screen/navigation/bottom_navigator_view.dart';
import '../screen/navigation/bottom_navigator_view_model.dart';

/// 카메라 알림 관련 서비스
class CameraNotificationService {
  static final CameraNotificationService _instance = CameraNotificationService._internal();
  factory CameraNotificationService() => _instance;
  CameraNotificationService._internal();

  final config = AppConfig();

  // ⭐ NotificationState와 UserState를 안전하게 가져오기
  NotificationState get ns {
    if (!Get.isRegistered<NotificationState>()) {
      Get.put(NotificationState());
    }
    return Get.find<NotificationState>();
  }

  UserState get us {
    if (!Get.isRegistered<UserState>()) {
      Get.put(UserState());
    }
    return Get.find<UserState>();
  }
  
  final _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );

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

  /// 타입 문자열을 숫자로 변환
  int _getTypeNumber(String typeString) {
    switch (typeString) {
      case '불꽃 감지':
        return 6;
      case '연기 감지':
        return 7;
      default:
        return 7; // 기본값: 연기 감지
    }
  }

  /// 화재/비화재 버튼 클릭 시 서버로 전송
  /// falsePositive: 0 = 화재, 1 = 비화재(오탐)
  Future<void> submitCameraResponse({
    required int falsePositive,
    String? reason,
  }) async {
    final token = await _secureStorage.read(key: "jwt_token");
    final url = '${config.baseUrl}/agents/${us.userData['id']}/works';
    final typeNumber = _getTypeNumber(ns.notificationData['type'] ?? '');
    final body = {
      'agentId': us.userData['id'],
      'reason': reason,
      'type': typeNumber,
      'notiId': ns.notificationData['docId'],
      'falsePositive': falsePositive,
    };

    try {
      print("📤 Submitting camera response:");
      print("📤 - URL: $url");
      print("📤 - Body: $body");
      print("📤 - Type converted: '${ns.notificationData['type']}' → $typeNumber");
      print("📤 - Token: ${token != null ? 'Present' : 'Missing'}");

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        print("✅ Camera response submitted successfully");

        // ⭐ 알림 리스트에서 해당 알림 제거 (removeNotification 사용)
        final docId = ns.notificationData['docId'];
        if (docId != null) {
          ns.removeNotification(docId.toString());
        }
      } else {
        print("❌ Failed to submit camera response: ${response.statusCode}");
        print("❌ Response body: ${response.body}");
        throw Exception('서버 응답 오류: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Camera response submission error: $e');
      rethrow;
    }
  }

  /// 비디오 URL 가져오기
  Future<String> getVideoUrl(String notiDocId) async {
    final token = await _secureStorage.read(key: "jwt_token");
    final url = '${config.baseUrl}/video/$notiDocId';

    try {
      print("📹 Getting video URL:");
      print("📹 - URL: $url");
      print("📹 - Token: ${token != null ? 'Present' : 'Missing'}");

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        print("📹 Video URL retrieved: ${response.body}");
        return response.body;
      } else {
        print("❌ Failed to get video URL: ${response.statusCode}");
        print("❌ Response body: ${response.body}");
        throw Exception('비디오 URL 가져오기 실패: ${response.statusCode}');
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

  /// ⭐ 특정 알림의 control_complete 상태 체크
  Future<int?> checkControlComplete(String docId) async {
    final token = await _secureStorage.read(key: "jwt_token");
    final url = '${config.baseUrl}/notifications/$docId/status';

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        print('✅ control_complete API 응답 성공: ${response.body}');
        final data = jsonDecode(response.body);
        final controlComplete = data['control_complete'];

        print('✅ control_complete 체크: docId=$docId, control_complete=$controlComplete (타입: ${controlComplete.runtimeType})');

        return controlComplete as int?;
      } else if (response.statusCode == 404) {
        // 404는 알림이 이미 삭제되었거나 존재하지 않음 (정상)
        print('ℹ️ control_complete 체크: 알림이 존재하지 않음 (docId=$docId)');
        return null;
      } else {
        print('❌ control_complete 체크 실패: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ control_complete 체크 오류: $e');
      return null;
    }
  }

  /// 알림 정보 초기화
  void clearNotificationData() {
    ns.notiDocId.value = '';
    ns.alertTurnOffList.clear();
    print("📷 Camera notification data cleared");
  }

  /// ⭐ 현재 처리 대기중인 알림 목록 확인
  /// 로그인 시, 자동로그인 시, 앱 재시작 시 호출
  Future<List<Map<String, dynamic>>> checkPendingNotifications() async {
    final token = await _secureStorage.read(key: "jwt_token");
    final agentId = us.userData['id'];

    if (agentId == null) {
      print("⚠️ Agent ID is null, cannot check pending notifications");
      return [];
    }

    final url = '${config.baseUrl}/agents/$agentId/pending-notifications';

    try {
      print("🔍 Checking pending notifications:");
      print("🔍 - URL: $url");
      print("🔍 - Agent ID: $agentId");

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // ⭐ 백엔드 응답 구조: { "message": "...", "result": [...] }
        List<dynamic> notificationsList = [];

        if (data is Map && data.containsKey('result')) {
          // result 키가 있는 경우 (새로운 백엔드 구조)
          final result = data['result'];
          if (result is List) {
            notificationsList = result;
          } else if (result is Map) {
            // result가 단일 객체인 경우
            notificationsList = [result];
          }
        } else if (data is List) {
          // 직접 리스트를 반환하는 경우 (하위 호환)
          notificationsList = data;
        } else if (data is Map) {
          // 단일 알림 객체를 직접 반환하는 경우 (하위 호환)
          notificationsList = [data];
        }

        if (notificationsList.isNotEmpty) {
          final notifications = notificationsList
              .map((item) => item as Map<String, dynamic>)
              .toList();
          print("✅ Pending notifications found: ${notifications.length}개");
          return notifications;
        } else {
          print("✅ No pending notifications found (empty result)");
          return [];
        }
      } else if (response.statusCode == 404) {
        // 404는 대기중인 알림이 없다는 의미
        print("✅ No pending notifications (404)");
        return [];
      } else {
        print("❌ Failed to check pending notifications: ${response.statusCode}");
        print("❌ Response body: ${response.body}");
        return [];
      }
    } catch (e) {
      print('❌ Pending notifications check error: $e');
      return [];
    }
  }

  /// 하위 호환성을 위해 단일 알림 체크 메서드 유지 (deprecated)
  @Deprecated('Use checkPendingNotifications() instead')
  Future<Map<String, dynamic>?> checkPendingNotification() async {
    final notifications = await checkPendingNotifications();
    return notifications.isNotEmpty ? notifications.first : null;
  }

  /// ⭐ 대기중인 알림 목록을 처리하여 NotificationState에 추가
  Future<void> handlePendingNotifications(List<Map<String, dynamic>> notifications) async {
    if (notifications.isEmpty) {
      print("ℹ️ 처리할 대기 중인 알림이 없습니다");
      return;
    }

    print("📢 Handling ${notifications.length}개의 pending notifications");

    // 알림들을 NotificationState에 추가 (createDate 기준 정렬됨)
    for (final notification in notifications) {
      final docId = notification['docId'];
      final type = notification['type'];
      final cameraUid = notification['cameraUid'] ?? '';
      final ipcamId = notification['ipcamId'] ?? '';
      final createDate = notification['createDate'];

      print("📢 - docId: $docId, type: $type, createDate: $createDate");

      // 알림 데이터 생성
      final notificationData = {
        'docId': docId,
        'type': type,
        'cameraUid': cameraUid,
        'ipcamId': ipcamId,
        'title': type,
        'body': ipcamId,
        'createDate': createDate,
      };

      // NotificationState에 추가
      ns.addNotification(notificationData);
    }

    // 가장 최신 알림(마지막)을 가져와서 경보 페이지로 이동
    if (ns.notificationList.isNotEmpty) {
      final latestNotification = ns.notificationList.last;
      final docId = latestNotification['docId'];
      final type = latestNotification['type'] ?? '경보';

      // 현재 알림 데이터 설정
      ns.notificationData.value = latestNotification;

      // 알림 정보 저장
      saveCameraNotificationData(
        docId: docId.toString(),
        type: type,
        cameraUid: latestNotification['cameraUid'] ?? '',
        ipcamId: latestNotification['ipcamId'] ?? '',
      );

      // 비디오 URL 가져오기
      final videoUrl = await getVideoUrl(docId.toString());

      // 경보 페이지로 이동
      await _navigateToAlertPage(videoUrl, type, 0);
    }
  }

  /// 대기중인 알림을 처리하여 경보 페이지로 이동 (단일 알림 - 하위 호환성)
  @Deprecated('Use handlePendingNotifications() instead')
  Future<void> handlePendingNotification(Map<String, dynamic> notificationData) async {
    await handlePendingNotifications([notificationData]);
  }

  /// 경보 페이지로 이동
  Future<void> _navigateToAlertPage(String videoUrl, String type, int remainingTime) async {
    // BottomNavigator가 이미 열려있는지 확인
    if (Get.currentRoute == '/BottomNavigatorView') {
      try {
        final bottomNavViewModel = Get.find<BottomNavigatorViewModel>();
        bottomNavViewModel.navigateToAlertWithVideo(videoUrl, type);
      } catch (e) {
        // BottomNavigatorViewModel을 찾을 수 없으면 새로 이동
        Get.offAll(() => const BottomNavigatorView());
        await Future.delayed(Duration(milliseconds: 100));
        final bottomNavViewModel = Get.find<BottomNavigatorViewModel>();
        bottomNavViewModel.navigateToAlertWithVideo(videoUrl, type);
      }
    } else {
      // 다른 페이지에 있으면 BottomNavigator로 이동 후 경보 탭 설정
      Get.offAll(() => const BottomNavigatorView());
      await Future.delayed(Duration(milliseconds: 100));
      final bottomNavViewModel = Get.find<BottomNavigatorViewModel>();
      bottomNavViewModel.navigateToAlertWithVideo(videoUrl, type);
    }
  }
}