import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:mms/components/dialog.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../provider/user_state.dart';
import '../../base_config/config.dart';
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

  // 관제 시간 데이터
  final RxString dayStart = '08:00:00'.obs;
  final RxString dayEnd = '18:00:00'.obs;
  final RxString nightStart = '20:00:00'.obs;
  final RxString nightEnd = '07:00:00'.obs;

  // 이벤트 목록
  final RxList<EventItem> eventList = <EventItem>[].obs;
  
  // 무한 스크롤 관련
  String? lastEventId; // 마지막 이벤트 ID (cursor)
  final RxBool hasMoreEvents = true.obs; // 더 가져올 데이터가 있는지

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
    fetchWorkTimeFromAPI();  // API에서 작업 시간 가져오기
    _loadAgentInfo();
  }

  /// 새로고침
  void refresh() {
    _initializeData();
    _loadScheduledWorkDates();
  }

  /// private_change_screen의 _getWorkTime 엔드포인트를 사용하여 작업 시간 가져오기
  Future<void> fetchWorkTimeFromAPI() async {
    try {
      final config = AppConfig();
      final url = '${config.baseUrl}/config/agent/date';
      print("작업 시간 API 호출: $url");
      
      final response = await http.get(Uri.parse(url));
      print("작업 시간 API 응답 상태: ${response.statusCode}");
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print("작업 시간 API 응답 데이터: $data");
        
        if (data != null) {
          final result = data['result'];
          
          if (result != null) {
            dayStart.value = result['dayStart']?.toString() ?? '08:00:00';
            dayEnd.value = result['dayEnd']?.toString() ?? '18:00:00';
            nightStart.value = result['nightStart']?.toString() ?? '20:00:00';
            nightEnd.value = result['nightEnd']?.toString() ?? '07:00:00';
            
            print('작업 시간 업데이트 완료 - 주간: ${dayStart.value} ~ ${dayEnd.value}, 야간: ${nightStart.value} ~ ${nightEnd.value}');
          }
        }
      } else {
        print('작업 시간 API 호출 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('작업 시간 API 호출 오류: $e');
    }
  }

  /// 에이전트 관제 시간 데이터 로드 (기존 메서드 - 더 이상 사용하지 않음)
  Future<void> _loadAgentDate() async {
    try {
      final result = await _apiService.getAgentDate();

      if (result['success'] == true) {
        final agentData = result['data']['result'];
        print('에이전트 관제 시간 데이터: $agentData');

        if (agentData != null) {
          dayStart.value = agentData['dayStart']?.toString() ?? '08:00:00';
          dayEnd.value = agentData['dayEnd']?.toString() ?? '18:00:00';
          nightStart.value = agentData['nightStart']?.toString() ?? '20:00:00';
          nightEnd.value = agentData['nightEnd']?.toString() ?? '07:00:00';

          print('관제 시간 업데이트 - 주간: ${dayStart.value} ~ ${dayEnd.value}, 야간: ${nightStart.value} ~ ${nightEnd.value}');
        }
      } else {
        print('에이전트 관제 시간 로드 실패: ${result['error']}');
      }
    } catch (e) {
      print('에이전트 관제 시간 로드 오류: $e');
    }
  }

  /// 에이전트 정보 로드 및 유저 상태 업데이트
  Future<void> _loadAgentInfo() async {
    try {
      final agentId = _userState.userData['id']?.toString() ?? '';
      if (agentId.isEmpty) {
        print('에이전트 ID가 없습니다.');
        return;
      }

      final result = await _apiService.getAgentInfo(agentId: agentId);

      if (result['success'] == true) {
        final agentData = result['data'];
        print('에이전트 정보 데이터: $agentData');

        if (agentData != null) {
          // 필요한 필드들 업데이트
          if (agentData['name'] != null) {
            _userState.userData['name'] = agentData['name'];
          }
          if (agentData['grade'] != null) {
            _userState.userData['grade'] = agentData['grade'];
          }
          if (agentData['control_type'] != null) {
            _userState.userData['control_type'] = agentData['control_type'];
          }
          
          print('에이전트 정보 업데이트 완료 - 이름: ${_userState.userData['name']}, 등급: ${_userState.userData['grade']}, 관제타입: ${_userState.userData['control_type']}');
        }
      } else {
        print('에이전트 정보 로드 실패: ${result['error']}');
      }
    } catch (e) {
      print('에이전트 정보 로드 오류: $e');
    }
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
    final now = DateTime.now();
    final threeYearsAgo = DateTime(now.year - 3, now.month);
    
    final newMonth = DateTime(
      selectedMonth.value.year,
      selectedMonth.value.month - 1,
    );
    
    // 3년 전까지만 이동 가능
    if (newMonth.isAfter(threeYearsAgo) || 
        (newMonth.year == threeYearsAgo.year && newMonth.month == threeYearsAgo.month)) {
      selectedMonth.value = newMonth;
      loadMonthData();
    }
  }

  /// 다음 달로 이동
  void goToNextMonth() {
    final now = DateTime.now();
    final twoMonthsLater = DateTime(now.year, now.month + 2);
    
    final newMonth = DateTime(
      selectedMonth.value.year,
      selectedMonth.value.month + 1,
    );
    
    // 2달 후까지만 이동 가능
    if (newMonth.isBefore(twoMonthsLater) || 
        (newMonth.year == twoMonthsLater.year && newMonth.month == twoMonthsLater.month)) {
      selectedMonth.value = newMonth;
      loadMonthData();
    }
  }
  
  /// 현재 달로 리셋
  void resetToCurrentMonth() {
    selectedMonth.value = DateTime.now();
    loadMonthData();
  }

  /// 월별 데이터 로드
  Future<void> loadMonthData() async {
    final agentId = _userState.userData['id']?.toString() ?? '';
    final year = selectedMonth.value.year.toString();
    final month = selectedMonth.value.month.toString().padLeft(2, '0');

    // 이벤트 목록 초기화
    eventList.clear();
    lastEventId = null;
    hasMoreEvents.value = true;

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
          // 총 횟수 업데이트 (응답횟수 사용)
          if (statsData['responseRate'] != null) {
            final responseRate = statsData['responseRate'].toString();
            final parts = responseRate.split('/');
            if (parts.length >= 2) {
              totalCount.value = int.tryParse(parts.first) ?? totalCount.value;
            }
          }

          // 총 비율 업데이트
          if (statsData['responseRate'] != null) {
            final raw = statsData['responseRate'].toString();
            final parts = raw.split('/');
            if (parts.length >= 2) {
              final num = int.tryParse(parts.first) ?? 0;
              final den = int.tryParse(parts.last) ?? 1;
              final percentValue = den > 0 ? (num / den) * 100 : 0.0;
              final percent = percentValue % 1 == 0 
                  ? percentValue.toInt().toString() 
                  : percentValue.toStringAsFixed(1);
              totalRatio.value = '$percent% (${parts.first} / ${parts.last}회)';
            }
          }

          // 정확도 업데이트
          if (statsData['responseAccuracy'] != null) {
            final raw = statsData['responseAccuracy'].toString();
            final parts = raw.split('/');
            if (parts.length >= 2) {
              final num = int.tryParse(parts.first) ?? 0;
              final den = int.tryParse(parts.last) ?? 1;
              final percentValue = den > 0 ? (num / den) * 100 : 0.0;
              final percent = percentValue % 1 == 0 
                  ? percentValue.toInt().toString() 
                  : percentValue.toStringAsFixed(1);
              totalAccuracy.value = '$percent% (${parts.first} / ${parts.last}회)';
            }
          }

          // 포인트 업데이트
          if (statsData['monthPoint'] != null) {
            final point = int.tryParse(statsData['monthPoint'].toString()) ?? 0;
            final formatter = NumberFormat('#,###');
            eventPoints.value = '${formatter.format(point)}P';
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
        cursor: lastEventId, // cursor 추가
      );

      if (eventsResult['success'] == true) {
        final eventsData = eventsResult['data']['result'] as List?;
        final apiHasMore = eventsResult['data']['hasMore']; // API에서 hasMore 필드가 있다면
        print('이벤트 데이터: ${eventsData?.length}개, API hasMore: $apiHasMore');

        if (eventsData != null && eventsData.isNotEmpty) {
          final events = eventsData
              .map((event) => EventItem(
                    id: event['id']?.toString() ?? '', // ID 추가
                    date: _formatEventDate(event['create_date']),
                    count: _getEventCount(event),
                    result: _getEventResult(event['false_positive']),
                    elapsedTime: _calculateElapsedTime(
                        event['create_date'], event['notiDate']),
                    points:
                        int.tryParse(event['point']?.toString() ?? '0') ?? 0,
                  ))
              .toList();

          if (lastEventId == null) {
            // 첫 로드시 새로 할당
            eventList.assignAll(events);
          } else {
            // 무한스크롤시 추가
            eventList.addAll(events);
          }

          // 마지막 ID 업데이트
          if (events.isNotEmpty) {
            final previousCursor = lastEventId;
            lastEventId = events.last.id;
            print('📌 Cursor 업데이트: $previousCursor → $lastEventId');
          }

          // 더 가져올 데이터가 있는지 확인
          if (apiHasMore != null) {
            // API에서 hasMore 필드를 제공하는 경우
            hasMoreEvents.value = apiHasMore == true;
            print('📊 hasMoreEvents 업데이트: ${hasMoreEvents.value} (API hasMore 필드 사용)');
          } else {
            // API에서 hasMore 필드가 없는 경우 데이터 개수로 판단
            hasMoreEvents.value = events.length >= 10; // 임계값 조정
            print('📊 hasMoreEvents 업데이트: ${hasMoreEvents.value} (받은 데이터: ${events.length}개, 임계값: 10개)');
          }

          print('이벤트 목록 업데이트 완료: ${events.length}개, 총 ${eventList.length}개');
        } else {
          // 빈 목록이면 더 이상 데이터 없음
          hasMoreEvents.value = false;
          print('🚫 더 이상 로드할 데이터 없음 (빈 응답)');
          if (lastEventId == null) {
            eventList.clear();
            print('이벤트 데이터가 없어서 목록을 초기화했습니다.');
          }
        }
      } else {
        print('이벤트 데이터 로드 실패: ${eventsResult['error']}');
        hasMoreEvents.value = false;
      }
    } catch (e) {
      print('이벤트 데이터 로드 오류: $e');
      hasMoreEvents.value = false;
    } finally {
      isEventsLoading.value = false;
    }
  }

  /// 더 많은 이벤트 로드 (무한 스크롤)
  Future<void> loadMoreEvents() async {
    if (!hasMoreEvents.value || isEventsLoading.value) {
      print('무한스크롤 중단: hasMoreEvents=${hasMoreEvents.value}, isLoading=${isEventsLoading.value}');
      return;
    }

    print('🔄 무한스크롤 시작 - cursor: $lastEventId, 현재 이벤트 수: ${eventList.length}');

    final agentId = _userState.userData['id']?.toString() ?? '';
    final year = selectedMonth.value.year.toString();
    final month = selectedMonth.value.month.toString().padLeft(2, '0');

    await _loadEvents(agentId, year, month);
    
    print('✅ 무한스크롤 완료 - 총 이벤트 수: ${eventList.length}, hasMoreEvents: ${hasMoreEvents.value}');
  }

  /// 월 표시 문자열
  String get monthDisplayText {
    return '${selectedMonth.value.year}.${selectedMonth.value.month.toString().padLeft(2, '0')}';
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
  void onCalendarTap(BuildContext context) {
    _loadScheduledWorkDates().then((_) {
      _showCalendarDialog(context);
    });
  }

  /// 달력 다이얼로그 표시 (근무 날짜 선택)
  void _showCalendarDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 10,
          bottom: MediaQuery.of(context).padding.bottom + 20,
        ),
        margin: const EdgeInsets.only(top: 50),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(10),
            topRight: Radius.circular(10),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 네비게이션 바 힌트 (작대기)
            Center(
              child: Container(
                width: 46,
                height: 4,
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 30),
            // 다이얼로그 제목
            const Text(
              '근무일 선택',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                fontFamily: 'Noto Sans KR',
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '오늘로부터 5일 이내 날짜는 수정이 불가합니다.',
              style: TextStyle(
                fontSize: 15,
                color: Color(0xff9C9FB0),
                fontWeight: FontWeight.w400,
                fontFamily: 'Noto Sans KR',
              ),
            ),
            const SizedBox(height: 36),

            // 달력
            SizedBox(
              height: 450, // 달력 최대 높이 고정
              child: Obx(() => TableCalendar<DateTime>(
                  firstDay: DateTime.now(),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: focusedDay.value,
                  selectedDayPredicate: (day) {
                    return selectedWorkDates
                        .any((selected) => isSameDay(selected, day));
                  },
                  calendarFormat: CalendarFormat.month,
                  daysOfWeekHeight: 48,
                  rowHeight: 56,
                  headerStyle: HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                    leftChevronPadding: const EdgeInsets.only(left: 0),
                    rightChevronPadding: const EdgeInsets.only(right: 0),
                    headerMargin: const EdgeInsets.only(bottom: 20),
                    leftChevronIcon: SvgPicture.asset(
                      'assets/main/calendar_arrow_left.svg',
                      width: 24,
                      height: 24,
                    ),
                    rightChevronIcon: SvgPicture.asset(
                      'assets/main/calendar_arrow_right.svg',
                      width: 24,
                      height: 24,
                    ),
                  ),
                  calendarBuilders: CalendarBuilders(
                    dowBuilder: (context, day) {
                      final text = ['일', '월', '화', '수', '목', '금', '토'][day.weekday % 7];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        height: 40,
                        child: Center(
                          child: Text(
                            text,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w400,
                              color: Color(0xff989BA9),
                              fontFamily: "Pretendard",
                              height: 1.0,
                            ),
                          ),
                        ),
                      );
                    },
                    headerTitleBuilder: (context, day) {
                      return Center(
                        child: Text(
                          '${day.year}.${day.month.toString().padLeft(2, '0')}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      );
                    },
                  ),
                  calendarStyle: CalendarStyle(
                    outsideDaysVisible: true,
                    weekendTextStyle: const TextStyle(
                      color: Color(0xFF4D505E),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      fontFamily: "Pretendard",
                    ),
                    defaultTextStyle: const TextStyle(
                      color: Color(0xFF4D505E),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      fontFamily: "Pretendard",
                    ),
                    cellMargin: const EdgeInsets.only(bottom: 12), // 날짜 아래 12px 간격
                    selectedDecoration: const BoxDecoration(
                      color: Color(0xFFD6E2FF),
                      shape: BoxShape.rectangle,
                    ),
                    selectedTextStyle: const TextStyle(
                      color: Color(0xFF1955EE),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      fontFamily: "Pretendard",
                    ),
                    todayDecoration: const BoxDecoration(
                      color: Color(0xFF1955EE),
                      shape: BoxShape.rectangle,
                    ),
                    // 과거 날짜 비활성화
                    disabledDecoration: const BoxDecoration(
                      color: Colors.transparent,
                      shape: BoxShape.rectangle,
                    ),
                    disabledTextStyle: TextStyle(
                      color: Color(0xFFCACAD7),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      fontFamily: "Pretendard",
                    ),
                    outsideTextStyle: TextStyle(
                      color: Color(0xFFCACAD7),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      fontFamily: "Pretendard",
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
            ),
            const SizedBox(height: 70),
            // 버튼들
            Obx(() => Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        backgroundColor: const Color(0xFFF6F6F7),
                        minimumSize: const Size(164, 46),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      child: const Text(
                        '취소',
                        style: TextStyle(
                          color: Color(0xFF5C5E6B),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Noto Sans KR',
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: (addDates.isNotEmpty || deleteDates.isNotEmpty)
                          ? () {
                              _showWorkDateConfirmDialog(context);
                            }
                          : null,
                      style: TextButton.styleFrom(
                        backgroundColor: (addDates.isNotEmpty || deleteDates.isNotEmpty)
                            ? const Color(0xFFD6E2FF)
                            : const Color(0xFFF6F6F7),
                        foregroundColor: (addDates.isNotEmpty || deleteDates.isNotEmpty)
                            ? const Color(0xFF1955EE)
                            : const Color(0xFF5C5E6B),
                        minimumSize: const Size(164, 46),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      child: const Text(
                        '저장',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Noto Sans KR',
                        ),
                      ),
                    ),
                  ],
                )),
          ],
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

        // Get.snackbar(
        //   '성공',
        //   message.isNotEmpty ? message : '근무 날짜가 성공적으로 업데이트되었습니다.',
        //   backgroundColor: Colors.green,
        //   colorText: Colors.white,
        // );
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

  /// 근무 날짜 수정 확인 다이얼로그
  void _showWorkDateConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xffF1F4F7),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          content: Container(
            width: Get.width,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    '근무일을 저장 하시겠습니까?',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Get.back();
                    },
                    behavior: HitTestBehavior.opaque,
                    child: Center(
                      child: Container(
                        width: Get.width,
                        height: 42,
                        decoration: BoxDecoration(
                          color: Color(0xffD3D8DE),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            '취소',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Noto Sans KR',
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      Get.back();
                      Get.back();
                      await _submitWorkDates();
                    },
                    behavior: HitTestBehavior.opaque,
                    child: Center(
                      child: Container(
                        width: Get.width,
                        height: 42,
                        decoration: BoxDecoration(
                          color: Color(0xff1955EE),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            '확인',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              fontFamily: 'Noto Sans KR',
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            )
          ],
        );
      },
    );
  }

  /// 날짜 선택/해제 처리
  void _handleDateSelection(DateTime selectedDay) {
    final isCurrentlySelected =
        selectedWorkDates.any((date) => isSameDay(date, selectedDay));
    final isOriginalDate =
        originalWorkDates.any((date) => isSameDay(date, selectedDay));

    if (isCurrentlySelected) {
      // 현재 선택된 날짜를 해제하는 경우
      if (isOriginalDate) {
        // 원본 데이터에 있던 날짜면 확인 모달 표시
        _showDeleteConfirmDialog(selectedDay);
      } else {
        // 새로 추가했던 날짜면 바로 추가 목록에서 제거
        selectedWorkDates.removeWhere((date) => isSameDay(date, selectedDay));
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

  /// 날짜 삭제 확인 모달
  void _showDeleteConfirmDialog(DateTime selectedDay) {
    showDialog(
      context: Get.context!,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xffF1F4F7),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          content: Container(
            width: Get.width,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    '${selectedDay.month}/${selectedDay.day}을 결근으로 처리하시겠습니까?\n\n결근으로 처리시 해당 날짜에는 알림을 받을 수 없습니다.',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Get.back();
                    },
                    behavior: HitTestBehavior.opaque,
                    child: Center(
                      child: Container(
                        width: Get.width,
                        height: 42,
                        decoration: BoxDecoration(
                          color: Color(0xffD3D8DE),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            '취소',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      // 모달 닫기
                      Get.back();

                      // 날짜 삭제 처리
                      selectedWorkDates.removeWhere(
                          (date) => isSameDay(date, selectedDay));
                      deleteDates.add(selectedDay);
                      print('기존 날짜 삭제 예정: $selectedDay');

                      // UI 강제 업데이트
                      final temp = focusedDay.value;
                      focusedDay.value =
                          temp.add(const Duration(milliseconds: 1));
                      focusedDay.value = temp;
                    },
                    behavior: HitTestBehavior.opaque,
                    child: Center(
                      child: Container(
                        width: Get.width,
                        height: 42,
                        decoration: BoxDecoration(
                          color: Color(0xff1955EE),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            '확인',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            )
          ],
        );
      },
    );
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
    
    // 시간에서 초 제거 (HH:MM:SS -> HH:MM)
    String formatTime(String time) {
      if (time.length >= 5) {
        return time.substring(0, 5); // HH:MM만 추출
      }
      return time;
    }
    
    switch (controlType) {
      case 1:
        return '주간 ${formatTime(dayStart.value)} ~ ${formatTime(dayEnd.value)}';
      case 2:
        return '야간 ${formatTime(nightStart.value)} ~ ${formatTime(nightEnd.value)}';
      case 3:
        return '주+야간 ${formatTime(dayStart.value)} ~ ${formatTime(dayEnd.value)}, ${formatTime(nightStart.value)} ~ ${formatTime(nightEnd.value)}';
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

    print("create ? : ${createDate}");
    print("noti ? : ${notiDate}");

    try {
      // createDate 파싱 (UTC)
      final create = DateTime.parse(createDate);

      // notiDate 형식 처리
      String formattedNotiDate = notiDate;
      if (notiDate.contains(' ') && !notiDate.contains('T')) {
        formattedNotiDate = notiDate.replaceFirst(' ', 'T');
      }

      // Z가 없으면 로컬 시간으로 간주, UTC로 변환
      if (!formattedNotiDate.endsWith('Z')) {
        formattedNotiDate += 'Z';
      }

      final noti = DateTime.parse(formattedNotiDate);

      print("create parsed : ${create}");
      print("noti parsed : ${noti}");

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
  final String id;
  final String date;
  final int count;
  final String result;
  final String elapsedTime;
  final int points;

  EventItem({
    required this.id,
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
        return Colors.black;
      case '미정':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  /// 포인트 표시 문자열
  String get pointsText => '${points.toString()} P';
}
