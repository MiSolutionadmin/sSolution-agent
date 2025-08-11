import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mms/db/camera_table.dart';
import 'package:mms/provider/notification_state.dart';
import 'package:mms/screen/navigation/bottom_navigator_view.dart';
import 'package:mms/screen/navigation/bottom_navigator_view_model.dart';
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

  // 무한 스크롤 관련
  String? lastRecordCreateDate; // 마지막 레코드 createDate (cursor)
  final RxBool hasMoreRecords = true.obs; // 더 가져올 데이터가 있는지

  @override
  void onInit() {
    super.onInit();
    _loadRecords();
  }

  /// 새로고침
  void refresh() {
    // 리스트 초기화
    records.clear();
    lastRecordCreateDate = null;
    hasMoreRecords.value = true;
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
    // 리스트 초기화
    records.clear();
    lastRecordCreateDate = null;
    hasMoreRecords.value = true;
    _loadRecords();
  }

  /// 다음 달로 이동
  void goToNextMonth() {
    selectedMonth.value = DateTime(
      selectedMonth.value.year,
      selectedMonth.value.month + 1,
    );
    // 리스트 초기화
    records.clear();
    lastRecordCreateDate = null;
    hasMoreRecords.value = true;
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
        cursor: lastRecordCreateDate,
        limit: 20,
      );

      if (result['success'] == true) {
        final notisData = result['data']['result'] as List?;
        print('알림 내역 데이터: ${notisData}개');

        if (notisData != null && notisData.isNotEmpty) {
          final recordItems = notisData
              .map((item) => RecordItem(
                    id: item['id']?.toString() ?? '',
                    docId: item['docId']?.toString() ?? '',
                    dateText: _formatDateText(item['createDate']),
                    alertType: _getAlertType(item['type']),
                    eventType: _getEventType(item['false_positive']),
                    result: item['admin_false_positive'] == null
                        ? ""
                        : item['false_positive'] == item['admin_false_positive']
                            ? "OK"
                            : "NG",
                  ))
              .toList();

          if (lastRecordCreateDate == null) {
            // 첫 로드시 새로 할당
            records.assignAll(recordItems);
          } else {
            // 무한스크롤시 추가
            records.addAll(recordItems);
          }

          // 마지막 createDate 업데이트
          if (recordItems.isNotEmpty) {
            final previousCursor = lastRecordCreateDate;
            lastRecordCreateDate = recordItems.last.dateText
                .replaceAll('\n', ' '); // createDate를 cursor로 사용
            print(
                '📌 Record Cursor 업데이트: $previousCursor → $lastRecordCreateDate');
          }

          // 더 가져올 데이터가 있는지 확인
          hasMoreRecords.value = recordItems.length >= 10;
          print(
              '📊 hasMoreRecords 업데이트: ${hasMoreRecords.value} (받은 데이터: ${recordItems.length}개)');

          print('알림 내역 로드 완료: ${recordItems.length}개, 총 ${records.length}개');
        } else {
          // 빈 목록이면 더 이상 데이터 없음
          hasMoreRecords.value = false;
          print('🚫 더 이상 로드할 알림 내역 없음 (빈 응답)');
          if (lastRecordCreateDate == null) {
            records.clear();
            print('알림 내역 데이터가 없습니다.');
          }
        }
      } else {
        print('알림 내역 로드 실패: ${result['error']}');
        hasMoreRecords.value = false;
      }
    } catch (e) {
      print('알림 내역 로드 오류: $e');
      hasMoreRecords.value = false;
    } finally {
      isLoading.value = false;
    }
  }

  /// 더 많은 알림 내역 로드 (무한 스크롤)
  Future<void> loadMoreRecords() async {
    if (!hasMoreRecords.value || isLoading.value) {
      print(
          '무한스크롤 중단: hasMoreRecords=${hasMoreRecords.value}, isLoading=${isLoading.value}');
      return;
    }

    print(
        '🔄 알림 내역 무한스크롤 시작 - cursor: $lastRecordCreateDate, 현재 레코드 수: ${records.length}');

    await _loadRecords();

    print(
        '✅ 알림 내역 무한스크롤 완료 - 총 레코드 수: ${records.length}, hasMoreRecords: ${hasMoreRecords.value}');
  }

  /// 알림 내역 API 호출
  Future<Map<String, dynamic>> _getNotifications({
    required String agentId,
    required String year,
    required String month,
    String? cursor,
    int limit = 20,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('로그인이 필요합니다.');
      }

      // URL에 cursor, limit 파라미터 추가
      String url =
          '${_config.baseUrl}/agents/$agentId/notis?targetMonth=$year-$month&limit=$limit';
      if (cursor != null && cursor.isNotEmpty) {
        url += '&cursor=$cursor';
      }

      final response = await http.get(
        Uri.parse(url),
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
    // createDate를 2025-07-21 10:29:24 형식에서 2025-07-21-10-29-24 형식으로 변환
    String videoUrl = _generateVideoUrl(record.dateText);

    // 저장 영상 재생 페이지로 이동
    Get.to(() => SavedVideoView(
          recordId: record.id,
          date: record.dateText,
          alertType: record.alertType,
          eventType: record.eventType,
          result: record.result,
          videoUrl: videoUrl,
        ));
  }

  /// videoUrl을 생성하는 함수
  String _generateVideoUrl(String dateText) {
    try {
      // dateText는 "2025-07-21\n10:29:24" 형식일 수 있으므로 변환
      String cleanedDate = dateText.replaceAll('\n', ' ');
      DateTime date = DateTime.parse(cleanedDate);

      String formattedDate =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}-${date.hour.toString().padLeft(2, '0')}-${date.minute.toString().padLeft(2, '0')}-${date.second.toString().padLeft(2, '0')}';

      return 'http://misnetwork.iptime.org:9099/videos/record_$formattedDate.mp4';
    } catch (e) {
      print('날짜 변환 오류: $e');
      return 'http://misnetwork.iptime.org:9099/videos/record_2025-01-01-00-00-00.mp4';
    }
  }

  /// videoUrl이 직접 주어진 경우의 agent 비디오 다시보기로 BottomNavigator 경보 탭으로 이동
  Future<void> openAgentVideoPageWithUrl(String videoUrl, String type) async {
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

  /// agent 비디오 다시보기로 BottomNavigator 경보 탭으로 이동
  Future<void> openAgentVideoPage(String docId, String type) async {
    final videoUrl = await getVideoUrl(docId);

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
}

class RecordItem {
  final String id;
  final String docId;
  final String dateText;
  final String alertType;
  final String eventType;
  final String result;

  RecordItem({
    required this.id,
    required this.docId,
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
        return Colors.black;
      case '미정':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  // 결과 유형에 따른 색상 변경
  Color get resultColor {
    switch (result) {
      case 'NG':
        return Colors.red;
      case 'OK':
        return Colors.black;
      default:
        return Colors.grey;
    }
  }
}
