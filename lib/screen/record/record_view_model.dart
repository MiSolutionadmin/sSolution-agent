import 'package:flutter/material.dart';
import 'package:get/get.dart';

class RecordViewModel extends GetxController {
  // 로딩 상태
  final RxBool isLoading = false.obs;
  
  // 기록 데이터
  final RxString title = '기록'.obs;
  final RxList<RecordItem> records = <RecordItem>[].obs;
  final RxString selectedFilter = '전체'.obs;
  
  // 필터 옵션
  final List<String> filterOptions = ['전체', '화재감지', '연기감지', '정상'];
  
  @override
  void onInit() {
    super.onInit();
    _loadRecords();
  }
  
  @override
  void onClose() {
    super.onClose();
  }
  
  /// 기록 데이터 로드
  void _loadRecords() {
    isLoading.value = true;
    
    try {
      // 샘플 데이터 - 실제로는 API에서 가져와야 함
      final sampleRecords = [
        RecordItem(
          id: '1',
          type: '화재감지',
          timestamp: DateTime.now().subtract(const Duration(hours: 2)),
          location: '1층 사무실',
          status: '처리완료',
        ),
        RecordItem(
          id: '2',
          type: '연기감지',
          timestamp: DateTime.now().subtract(const Duration(hours: 5)),
          location: '2층 회의실',
          status: '확인중',
        ),
        RecordItem(
          id: '3',
          type: '정상',
          timestamp: DateTime.now().subtract(const Duration(days: 1)),
          location: '3층 복도',
          status: '정상',
        ),
      ];
      
      records.assignAll(sampleRecords);
    } catch (e) {
      print('기록 로드 오류: $e');
    } finally {
      isLoading.value = false;
    }
  }
  
  /// 새로고침
  void refresh() {
    _loadRecords();
  }
  
  /// 필터 변경
  void changeFilter(String filter) {
    selectedFilter.value = filter;
    _applyFilter();
  }
  
  /// 필터 적용
  void _applyFilter() {
    _loadRecords(); // 실제로는 필터링된 데이터를 로드해야 함
  }
  
  /// 기록 상세 보기
  void viewRecordDetail(RecordItem record) {
    // 상세 화면으로 이동 또는 다이얼로그 표시
    Get.dialog(
      AlertDialog(
        title: Text('기록 상세'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('유형: ${record.type}'),
            Text('시간: ${_formatDateTime(record.timestamp)}'),
            Text('위치: ${record.location}'),
            Text('상태: ${record.status}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }
  
  /// 날짜 시간 포맷
  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
           '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
  
  /// 상대적 시간 표시
  String getRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}분 전';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}시간 전';
    } else {
      return '${difference.inDays}일 전';
    }
  }
}

class RecordItem {
  final String id;
  final String type;
  final DateTime timestamp;
  final String location;
  final String status;
  
  RecordItem({
    required this.id,
    required this.type,
    required this.timestamp,
    required this.location,
    required this.status,
  });
}