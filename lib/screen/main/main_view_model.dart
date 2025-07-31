import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../provider/user_state.dart';
import 'main_api_service.dart';

class MainViewModel extends GetxController {
  // Dependencies
  final UserState _userState = Get.find<UserState>();
  final MainApiService _apiService = MainApiService();

  // 로딩 상태들
  final RxBool isStatsLoading = false.obs;
  final RxBool isEventsLoading = false.obs;

  // 현재 선택된 월
  final Rx<DateTime> selectedMonth = DateTime.now().obs;

  // 선택된 근무 날짜들 (다중 선택)
  final RxSet<DateTime> selectedWorkDates = <DateTime>{}.obs;

  // 원본 근무 날짜들 (GET으로 받아온 기존 데이터)
  final RxSet<DateTime> originalWorkDates = <DateTime>{}.obs;

  // 삭제할 날짜들 (기존에서 해제한 것들)
  final RxSet<DateTime> deleteDates = <DateTime>{}.obs;

  // 추가할 날짜들 (새로 선택한 것들)
  final RxSet<DateTime> addDates = <DateTime>{}.obs;

  // 달력 포커스 날짜
  final Rx<DateTime> focusedDay = DateTime.now().obs;

  // 통계 데이터
  final RxInt totalCount = 25.obs;
  final RxString totalRatio = '93.8% (15 / 16회)'.obs;
  final RxString totalAccuracy = '100% (15 / 15회)'.obs;
  final RxString eventPoints = '341,000 P'.obs;

  // 이벤트 목록
  final RxList<EventItem> eventList = <EventItem>[].obs;

  @override
  void onInit() {
    super.onInit();
    _initializeData();
  }

  @override
  void onClose() {
    super.onClose();
  }

  /// 데이터 초기화
  void _initializeData() {
    print('메인 데이터 초기화');
    loadMonthData();
  }

  /// 새로고침
  void refresh() {
    _initializeData();
    _loadScheduledWorkDates();
  }

  /// 등록된 근무 날짜 로드
  Future<void> _loadScheduledWorkDates() async {
    try {
      // 먼저 모든 날짜 데이터 초기화
      selectedWorkDates.clear();
      originalWorkDates.clear();
      addDates.clear();
      deleteDates.clear();

      final agentId = _userState.userData['id']?.toString() ?? '';

      final result = await _apiService.getWorkDates(agentId: agentId);

      if (result['success'] == true) {
        final workDates = result['data']['result'] as List?;
        if (workDates != null) {
          // work_date 필드에서 DateTime으로 변환
          final dateList = workDates
              .map((item) {
                try {
                  final workDate = item['work_date']?.toString();
                  if (workDate != null) {
                    return DateTime.parse(workDate);
                  }
                  return null;
                } catch (e) {
                  print('날짜 파싱 오류: ${item['work_date']}');
                  return null;
                }
              })
              .where((date) => date != null)
              .cast<DateTime>()
              .toList();

          // 원본 데이터와 현재 선택된 데이터에 설정
          originalWorkDates.assignAll(dateList);
          selectedWorkDates.assignAll(dateList);

          print('로드된 근무 날짜: ${dateList.length}개');
        } else {
          print('근무 날짜 데이터가 없습니다 - 모든 날짜 초기화됨');
        }
      } else {
        print('근무 날짜 로드 실패 - 모든 날짜 초기화됨');
      }
    } catch (e) {
      print('등록된 근무 날짜 로드 오류: $e');
    }
  }

  /// 이전 달로 이동
  void goToPreviousMonth() {
    selectedMonth.value = DateTime(
      selectedMonth.value.year,
      selectedMonth.value.month - 1,
    );
    loadMonthData();
  }

  /// 다음 달로 이동
  void goToNextMonth() {
    selectedMonth.value = DateTime(
      selectedMonth.value.year,
      selectedMonth.value.month + 1,
    );
    loadMonthData();
  }

  /// 월별 데이터 로드
  Future<void> loadMonthData() async {
    final agentId = _userState.userData['id']?.toString() ?? '';
    final year = selectedMonth.value.year.toString();
    final month = selectedMonth.value.month.toString().padLeft(2, '0');

    // 통계와 이벤트를 병렬로 로드
    await Future.wait([
      _loadStats(agentId, year, month),
      _loadEvents(agentId, year, month),
    ]);
  }

  /// 통계 데이터 로드
  Future<void> _loadStats(String agentId, String year, String month) async {
    try {
      isStatsLoading.value = true;

      final statsResult = await _apiService.getMonthlyStats(
        agentId: agentId,
        year: year,
        month: month,
      );

      if (statsResult['success'] == true) {
        final statsData = statsResult['data'];
        print('통계 데이터 업데이트: $statsData');

        // 통계 데이터 업데이트 - null 체크 강화
        if (statsData != null) {
          // 총 횟수 업데이트
          if (statsData['responseRate'] != null) {
            final responseRate = statsData['responseRate'].toString();
            final parts = responseRate.split('/');
            if (parts.length >= 2) {
              totalCount.value = int.tryParse(parts.last) ?? totalCount.value;
            }
          }

          // 총 비율 업데이트
          if (statsData['responseRate'] != null) {
            final raw = statsData['responseRate'].toString();
            final parts = raw.split('/');
            if (parts.length >= 2) {
              final num = int.tryParse(parts.first) ?? 0;
              final den = int.tryParse(parts.last) ?? 1;
              final percent =
                  den > 0 ? ((num / den) * 100).toStringAsFixed(1) : '0.0';
              totalRatio.value = '$percent% ($raw)';
            }
          }

          // 정확도 업데이트
          if (statsData['responseAccuracy'] != null) {
            final raw = statsData['responseAccuracy'].toString();
            final parts = raw.split('/');
            if (parts.length >= 2) {
              final num = int.tryParse(parts.first) ?? 0;
              final den = int.tryParse(parts.last) ?? 1;
              final percent =
                  den > 0 ? ((num / den) * 100).toStringAsFixed(1) : '0.0';
              totalAccuracy.value = '$percent% ($raw)';
            }
          }

          // 포인트 업데이트
          if (statsData['monthPoint'] != null) {
            eventPoints.value = statsData['monthPoint'].toString();
          }

          print(
              '업데이트된 통계 - 총횟수: ${totalCount.value}, 비율: ${totalRatio.value}, 정확도: ${totalAccuracy.value}, 포인트: ${eventPoints.value}');
        }
      } else {
        print('통계 데이터 로드 실패: ${statsResult['error']}');
      }
    } catch (e) {
      print('통계 데이터 로드 오류: $e');
    } finally {
      isStatsLoading.value = false;
    }
  }

  /// 이벤트 목록 로드
  Future<void> _loadEvents(String agentId, String year, String month) async {
    try {
      isEventsLoading.value = true;

      final eventsResult = await _apiService.getEventList(
        agentId: agentId,
        year: year,
        month: month,
      );

      if (eventsResult['success'] == true) {
        final eventsData = eventsResult['data']['result'] as List?;
        print('이벤트 데이터: $eventsData');

        if (eventsData != null && eventsData.isNotEmpty) {
          final events = eventsData
              .map((event) => EventItem(
                    date: _formatEventDate(event['create_date']),
                    count: _getEventCount(event),
                    result: _getEventResult(event['false_positive']),
                    elapsedTime: _calculateElapsedTime(
                        event['create_date'], event['notiDate']),
                    points:
                        int.tryParse(event['point']?.toString() ?? '0') ?? 0,
                  ))
              .toList();

          eventList.assignAll(events);
          print('이벤트 목록 업데이트 완료: ${events.length}개');
        } else {
          // 빈 목록으로 초기화
          eventList.clear();
          print('이벤트 데이터가 없어서 목록을 초기화했습니다.');
        }
      } else {
        print('이벤트 데이터 로드 실패: ${eventsResult['error']}');
      }
    } catch (e) {
      print('이벤트 데이터 로드 오류: $e');
    } finally {
      isEventsLoading.value = false;
    }
  }

  /// 월 표시 문자열
  String get monthDisplayText {
    return '${selectedMonth.value.year}년 ${selectedMonth.value.month}월';
  }

  /// 선택된 근무 날짜들 표시 문자열
  String get selectedWorkDatesText {
    if (selectedWorkDates.isEmpty) {
      return '근무 날짜를 선택해주세요';
    }

    final sortedDates = selectedWorkDates.toList()..sort();
    if (sortedDates.length == 1) {
      final date = sortedDates.first;
      return '${date.month}/${date.day}';
    } else if (sortedDates.length <= 3) {
      return sortedDates.map((date) => '${date.month}/${date.day}').join(', ');
    } else {
      return '${sortedDates.first.month}/${sortedDates.first.day} 외 ${sortedDates.length - 1}일';
    }
  }

  /// 캘린더 아이콘 클릭
  void onCalendarTap() {
    _loadScheduledWorkDates().then((_) {
      _showCalendarDialog();
    });
  }

  /// 달력 다이얼로그 표시 (근무 날짜 선택)
  void _showCalendarDialog() {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 다이얼로그 제목
              const Text(
                '근무 날짜 선택',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '여러 날짜를 선택할 수 있습니다',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 16),
              // 선택된 날짜 개수 표시
              // Obx(() => Container(
              //       padding:
              //           const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              //       decoration: BoxDecoration(
              //         color: Colors.orange.withOpacity(0.1),
              //         borderRadius: BorderRadius.circular(12),
              //       ),
              //       child: Text(
              //         '선택된 날짜: ${selectedWorkDates.length}일',
              //         style: const TextStyle(
              //           fontSize: 12,
              //           fontWeight: FontWeight.w500,
              //           color: Colors.orange,
              //         ),
              //       ),
              //     )),
              // const SizedBox(height: 16),
              // 달력
              Obx(() => TableCalendar<DateTime>(
                    firstDay: DateTime.now(),
                    lastDay: DateTime.utc(2030, 12, 31),
                    focusedDay: focusedDay.value,
                    selectedDayPredicate: (day) {
                      return selectedWorkDates
                          .any((selected) => isSameDay(selected, day));
                    },
                    calendarFormat: CalendarFormat.month,
                    headerStyle: const HeaderStyle(
                      formatButtonVisible: false,
                      titleCentered: true,
                      leftChevronIcon: Icon(
                        Icons.chevron_left,
                        color: Colors.orange,
                      ),
                      rightChevronIcon: Icon(
                        Icons.chevron_right,
                        color: Colors.orange,
                      ),
                    ),
                    calendarStyle: CalendarStyle(
                      outsideDaysVisible: false,
                      weekendTextStyle: const TextStyle(color: Colors.red),
                      selectedDecoration: const BoxDecoration(
                        color: Colors.orange,
                        shape: BoxShape.circle,
                      ),
                      todayDecoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      // 과거 날짜 비활성화
                      disabledDecoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      disabledTextStyle: TextStyle(
                        color: Colors.grey.withOpacity(0.5),
                      ),
                    ),
                    enabledDayPredicate: (day) {
                      // 오늘 + 6일 후부터 선택 가능
                      final minSelectableDate =
                          DateTime.now().add(const Duration(days: 6));
                      return day.isAfter(minSelectableDate
                              .subtract(const Duration(days: 1))) ||
                          isSameDay(day, minSelectableDate);
                    },
                    onDaySelected: (selectedDay, focusedDay) {
                      _handleDateSelection(selectedDay);
                      this.focusedDay.value = focusedDay;

                      // UI 강제 업데이트를 위해 focusedDay를 살짝 변경했다가 다시 원래대로
                      final temp = this.focusedDay.value;
                      this.focusedDay.value =
                          temp.add(const Duration(milliseconds: 1));
                      this.focusedDay.value = temp;
                    },
                    onPageChanged: (focusedDay) {
                      this.focusedDay.value = focusedDay;
                    },
                  )),
              const SizedBox(height: 20),
              // 버튼들
              Obx(() => Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TextButton(
                        onPressed: () => Get.back(),
                        child: const Text(
                          '취소',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                      ElevatedButton(
                        onPressed:
                            (addDates.isNotEmpty || deleteDates.isNotEmpty)
                                ? () {
                                    _submitWorkDates();
                                    Get.back();
                                  }
                                : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('확인'),
                      ),
                    ],
                  )),
            ],
          ),
        ),
      ),
    );
  }

  /// 근무 날짜 제출 (POST API 호출)
  Future<void> _submitWorkDates() async {
    if (addDates.isEmpty && deleteDates.isEmpty) {
      Get.snackbar('알림', '변경된 내용이 없습니다.');
      return;
    }

    try {
      // 추가할 날짜들을 문자열로 변환
      final addDateStrings = addDates.map((date) {
        return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      }).toList();

      // 삭제할 날짜들을 문자열로 변환
      final deleteDateStrings = deleteDates.map((date) {
        return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      }).toList();

      final result = await _apiService.submitWorkDates(
        agentId: _userState.userData['id']?.toString() ?? '',
        workDates: addDateStrings,
        control_type: _userState.userData['control_type'],
        deleteDates: deleteDateStrings.isNotEmpty ? deleteDateStrings : null,
      );

      if (result['success'] == true) {
        String message = '';
        if (addDates.isNotEmpty) {
          message += '${addDates.length}개 날짜 추가 완료. ';
        }
        if (deleteDates.isNotEmpty) {
          message += '${deleteDates.length}개 날짜 삭제 완료. ';
        }

        Get.snackbar(
          '성공',
          message.isNotEmpty ? message : '근무 날짜가 성공적으로 업데이트되었습니다.',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else {
        throw Exception('업데이트 실패: ${result['message']}');
      }

      // 성공 후 원본 데이터 업데이트 및 추가/삭제 목록 초기화
      originalWorkDates.assignAll(selectedWorkDates);
      addDates.clear();
      deleteDates.clear();

      // 데이터 새로고침
      await _loadScheduledWorkDates();
    } catch (e) {
      print('근무 날짜 제출 오류: $e');
      Get.snackbar(
        '오류',
        '네트워크 오류가 발생했습니다: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  /// 날짜 선택/해제 처리
  void _handleDateSelection(DateTime selectedDay) {
    final isCurrentlySelected =
        selectedWorkDates.any((date) => isSameDay(date, selectedDay));
    final isOriginalDate =
        originalWorkDates.any((date) => isSameDay(date, selectedDay));

    if (isCurrentlySelected) {
      // 현재 선택된 날짜를 해제하는 경우
      selectedWorkDates.removeWhere((date) => isSameDay(date, selectedDay));

      if (isOriginalDate) {
        // 원본 데이터에 있던 날짜면 삭제 목록에 추가
        deleteDates.add(selectedDay);
        print('기존 날짜 삭제 예정: $selectedDay');
      } else {
        // 새로 추가했던 날짜면 추가 목록에서 제거
        addDates.removeWhere((date) => isSameDay(date, selectedDay));
        print('신규 날짜 선택 취소: $selectedDay');
      }
    } else {
      // 현재 선택되지 않은 날짜를 선택하는 경우
      selectedWorkDates.add(selectedDay);

      if (isOriginalDate) {
        // 원본 데이터에 있던 날짜면 삭제 목록에서 제거 (다시 선택)
        deleteDates.removeWhere((date) => isSameDay(date, selectedDay));
        print('기존 날짜 삭제 취소: $selectedDay');
      } else {
        // 새로운 날짜면 추가 목록에 추가
        addDates.add(selectedDay);
        print('신규 날짜 추가: $selectedDay');
      }
    }

    print(
        '선택된 날짜: ${selectedWorkDates.length}개, 추가: ${addDates.length}개, 삭제: ${deleteDates.length}개');
  }

  /// 알림 아이콘 클릭
  void onNotificationTap() {
    // 알림 페이지로 이동
    print('알림 클릭');
  }

  /// 사용자 이름
  String get userName => _userState.userData['name'] ?? '사용자';

  /// 사용자 등급
  String get userGrade => _userState.userData['grade'] ?? 'A';

  /// 관제 시간 (control_type 기준)
  String get controlTime {
    final controlType = _userState.userData['control_type'];
    switch (controlType) {
      case 1:
        return '주간';
      case 2:
        return '야간';
      case 3:
        return '주+야간';
      default:
        return '미정';
    }
  }

  /// 이벤트 날짜 포맷
  String _formatEventDate(String? dateStr) {
    if (dateStr == null) return '';

    try {
      final date = DateTime.parse(dateStr);
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}\n${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}:${date.second.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateStr;
    }
  }

  /// 이벤트 횟수 계산
  int _getEventCount(Map<String, dynamic> event) {
    // 실제 이벤트 횟수 계산 로직 - API 구조에 따라 수정
    return int.tryParse(event['count']?.toString() ?? '1') ?? 1;
  }

  /// 이벤트 결과 변환
  String _getEventResult(dynamic falsePositive) {
    // false_positive 값에 따라 결과 결정
    if (falsePositive == 1 || falsePositive == '1') {
      return '비화재';
    } else if (falsePositive == 0 || falsePositive == '0') {
      return '화재';
    } else {
      return '미정';
    }
  }

  /// create_date와 notiDate 간의 시간차 계산
  String _calculateElapsedTime(String? createDate, String? notiDate) {
    if (createDate == null || notiDate == null) return '0초';

    try {
      final create = DateTime.parse(createDate);
      final noti = DateTime.parse(notiDate);

      final difference = create.difference(noti).abs();

      return '${difference.inSeconds}초';
    } catch (e) {
      print('시간차 계산 오류: $e');
      return '0초';
    }
  }
}

/// 이벤트 아이템 모델
class EventItem {
  final String date;
  final int count;
  final String result;
  final String elapsedTime;
  final int points;

  EventItem({
    required this.date,
    required this.count,
    required this.result,
    required this.elapsedTime,
    required this.points,
  });

  /// 결과에 따른 색상 반환
  Color get resultColor {
    switch (result) {
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

  /// 포인트 표시 문자열
  String get pointsText => '${points.toString()} P';
}
