import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../base_config/config.dart';
import '../../provider/user_state.dart';
import 'saved_video_view.dart';

class RecordViewModel extends GetxController {
  // Dependencies
  final UserState _userState = Get.find<UserState>();
  final AppConfig _config = AppConfig();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );

  // 로딩 상태
  final RxBool isLoading = false.obs;

  // 현재 선택된 월
  final Rx<DateTime> selectedMonth = DateTime.now().obs;

  // 알림 내역 데이터
  final RxList<RecordItem> records = <RecordItem>[].obs;

  @override
  void onInit() {
    super.onInit();
    _loadRecords();
  }

  @override
  void onClose() {
    super.onClose();
  }

  /// 월 표시 문자열
  String get monthDisplayText {
    return '${selectedMonth.value.year}년 ${selectedMonth.value.month}월';
  }

  /// 이전 달로 이동
  void goToPreviousMonth() {
    selectedMonth.value = DateTime(
      selectedMonth.value.year,
      selectedMonth.value.month - 1,
    );
    _loadRecords();
  }

  /// 다음 달로 이동
  void goToNextMonth() {
    selectedMonth.value = DateTime(
      selectedMonth.value.year,
      selectedMonth.value.month + 1,
    );
    _loadRecords();
  }

  /// JWT 토큰 가져오기
  Future<String?> _getToken() async {
    return await _secureStorage.read(key: "jwt_token");
  }

  /// 알림 내역 데이터 로드
  Future<void> _loadRecords() async {
    isLoading.value = true;

    try {
      final agentId = _userState.userData['id']?.toString() ?? '';
      final year = selectedMonth.value.year.toString();
      final month = selectedMonth.value.month.toString().padLeft(2, '0');

      final result = await _getNotifications(
        agentId: agentId,
        year: year,
        month: month,
      );

      if (result['success'] == true) {
        final notisData = result['data']['result'] as List?;
        print('알림 내역 데이터: $notisData');

        if (notisData != null && notisData.isNotEmpty) {
          final recordItems = notisData
              .map((item) => RecordItem(
                    id: item['id']?.toString() ?? '',
                    dateText: _formatDateText(item['createDate']),
                    alertType: _getAlertType(item['type']),
                    eventType: _getEventType(item['false_positive']),
                    result: _getResult(item['status']),
                  ))
              .toList();

          records.assignAll(recordItems);
          print('알림 내역 로드 완료: ${recordItems.length}개');
        } else {
          records.clear();
          print('알림 내역 데이터가 없습니다.');
        }
      } else {
        print('알림 내역 로드 실패: ${result['error']}');
        records.clear();
      }
    } catch (e) {
      print('알림 내역 로드 오류: $e');
      records.clear();
    } finally {
      isLoading.value = false;
    }
  }

  /// 알림 내역 API 호출
  Future<Map<String, dynamic>> _getNotifications({
    required String agentId,
    required String year,
    required String month,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('로그인이 필요합니다.');
      }

      final response = await http.get(
        Uri.parse(
            '${_config.baseUrl}/agents/$agentId/notis?targetMonth=$year-$month'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 30));

      print('알림 내역 응답 상태: ${response.statusCode}');
      print('알림 내역 응답 내용: ${response.body}');

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': json.decode(response.body),
        };
      } else {
        return {
          'success': false,
          'error': '서버 오류: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('알림 내역 API 오류: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// 날짜 텍스트 포맷
  String _formatDateText(String? dateStr) {
    if (dateStr == null) return '';

    try {
      final date = DateTime.parse(dateStr);
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}\n'
          '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}:${date.second.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateStr;
    }
  }

  /// 알림 타입 변환
  String _getAlertType(String? type) {
    switch (type) {
      case '6':
        return '불꽃 알림';
      case '7':
        return '연기 알림';
      default:
        return '알림';
    }
  }

  /// 이벤트 타입 변환 (false_positive 기준)
  String _getEventType(dynamic falsePositive) {
    // false_positive가 1이면 비화재, 0이면 화재
    if (falsePositive == 1 || falsePositive == '1') {
      return '비화재';
    } else if (falsePositive == 0 || falsePositive == '0') {
      return '화재';
    } else {
      return '미정';
    }
  }

  /// 결과 변환
  String _getResult(String? status) {
    // 실제 status 값에 따라 변환 로직 구현
    return status == 'resolved' ? 'OK' : 'NG';
  }

  /// 영상 재생
  void playVideo(RecordItem record) {
    print('영상 재생: ${record.id}');
    
    // TODO: 실제 비디오 URL을 API에서 가져와야 함
    // 현재는 임시로 동일한 URL 사용
    const tempVideoUrl = 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4';
    
    // 저장 영상 재생 페이지로 이동
    Get.to(() => SavedVideoView(
      recordId: record.id,
      date: record.dateText,
      alertType: record.alertType,
      eventType: record.eventType,
      result: record.result,
      videoUrl: tempVideoUrl,
    ));
  }
}

class RecordItem {
  final String id;
  final String dateText;
  final String alertType;
  final String eventType;
  final String result;

  RecordItem({
    required this.id,
    required this.dateText,
    required this.alertType,
    required this.eventType,
    required this.result,
  });

  /// 이벤트 유형에 따른 색상 반환
  Color get eventColor {
    switch (eventType) {
      case '화재':
        return Colors.red;
      case '비화재':
        return Colors.orange;
      case '미정':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }
}
