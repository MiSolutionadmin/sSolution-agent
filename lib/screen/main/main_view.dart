import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

import 'main_view_model.dart';
import 'skeleton_widgets.dart';

class MainView extends StatefulWidget {
  const MainView({super.key});

  @override
  State<MainView> createState() => _MainViewState();
}

class _MainViewState extends State<MainView>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final MainViewModel viewModel = Get.put(MainViewModel());

    // 페이지가 나타날 때마다 데이터 갱신
    WidgetsBinding.instance.addPostFrameCallback((_) {
      viewModel.refresh();
    });

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        top: true,
        child: Column(
          children: [
            // 상단 헤더 (사용자 정보 통합)
            _buildCombinedHeader(context, Get.find<MainViewModel>()),
            // 월별 현황 및 통계 정보 섹션 (통합)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: GetBuilder<MainViewModel>(
                builder: (viewModel) {
                  return _buildMonthlyStatusAndStatistics(viewModel);
                },
              ),
            ),
            // 이벤트 목록 테이블 (무한 스크롤)
            const SizedBox(height: 6),
            Expanded(
              child: GetBuilder<MainViewModel>(
                builder: (viewModel) {
                  return _buildEventTable(viewModel);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 상단 헤더 (사용자 정보 통합)
  Widget _buildCombinedHeader(BuildContext context, MainViewModel viewModel) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Container(
        padding: EdgeInsets.only(
          top: 19,
          left: 20,
          right: 20,
          bottom: 30,
        ),
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/main/background.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          children: [
            // 첫 번째 행: MMS 에이전트 타이틀과 캘린더 아이콘
            Row(
              children: [
                const Text(
                  'MMS 에이전트',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    fontFamily: 'Noto Sans KR',
                  ),
                ),
                const Spacer(),
                InkWell(
                  onTap: () => viewModel.onCalendarTap(context),
                  child: Container(
                    width: 60,
                    height: 40,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: SvgPicture.asset(
                        'assets/main/fi_calendar.svg',
                        width: 24,
                        height: 24,
                        colorFilter: const ColorFilter.mode(
                          Colors.white,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // 두 번째 행: 사용자 정보 (세로 정렬)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 이름
                _buildUserInfoItem('이름', viewModel.userName),
                const SizedBox(height: 8),
                // 등급
                _buildUserInfoItem('등급', viewModel.userGrade),
                const SizedBox(height: 8),
                // 관제 시간
                Obx(
                  () => _buildUserInfoItem('관제 시간', viewModel.controlTime),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 사용자 정보 아이템
  Widget _buildUserInfoItem(String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Colors.white.withOpacity(0.5),
              fontFamily: 'Noto Sans KR',
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            color: Colors.white,
            fontWeight: FontWeight.w500,
            fontFamily: 'Noto Sans KR',
          ),
        ),
      ],
    );
  }

  /// 월별 현황 및 통계 정보 섹션 (통합)
  Widget _buildMonthlyStatusAndStatistics(MainViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF595B65),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '월별 현황',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontFamily: 'Noto Sans KR',
            ),
          ),
          const SizedBox(height: 21),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: viewModel.goToPreviousMonth,
                child: SvgPicture.asset(
                  'assets/main/arrow_left.svg',
                  width: 24,
                  height: 24,
                  colorFilter: const ColorFilter.mode(
                    Colors.white,
                    BlendMode.srcIn,
                  ),
                ),
              ),
              Obx(() => Text(
                    viewModel.monthDisplayText,
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        fontFamily: "Pretendard"),
                  )),
              GestureDetector(
                onTap: viewModel.goToNextMonth,
                child: SvgPicture.asset(
                  'assets/main/arrow_right.svg',
                  width: 24,
                  height: 24,
                  colorFilter: const ColorFilter.mode(
                    Colors.white,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Obx(() => Column(
                children: [
                  _buildStatRow(
                      '응답 횟수',
                      viewModel.isStatsLoading.value
                          ? null
                          : viewModel.totalCount.value.toString() + '회'),
                  const SizedBox(height: 8),
                  _buildStatRow(
                      '응답 비율',
                      viewModel.isStatsLoading.value
                          ? null
                          : viewModel.totalRatio.value),
                  const SizedBox(height: 8),
                  _buildStatRow(
                      '응답 정확도',
                      viewModel.isStatsLoading.value
                          ? null
                          : viewModel.totalAccuracy.value),
                  const SizedBox(height: 8),
                  _buildStatRow(
                      '이달 포인트',
                      viewModel.isStatsLoading.value
                          ? null
                          : viewModel.eventPoints.value),
                ],
              )),
        ],
      ),
    );
  }

  /// 통계 행 위젯
  Widget _buildStatRow(String label, String? value) {
    return Row(
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Color(0xFFADAFBC),
              fontFamily: 'Noto Sans KR',
            ),
          ),
        ),
        Expanded(
          child: value == null
              ? SkeletonLoader(
                  child: Container(
                    height: 14,
                    width: 10,
                    decoration: BoxDecoration(
                      color: Color(0xFF595B65).withValues(alpha: 0.95),
                    ),
                  ),
                )
              : Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Noto Sans KR',
                  ),
                ),
        ),
      ],
    );
  }

  /// 이벤트 목록 테이블
  Widget _buildEventTable(MainViewModel viewModel) {
    return Obx(() {
      if (viewModel.isEventsLoading.value) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              // 테이블 헤더
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.1),
                      spreadRadius: 0,
                      blurRadius: 2,
                      offset: const Offset(0, 2),
                    ),
                  ],
                  border: Border(
                    bottom: BorderSide(color: Color(0xffd5d5d5), width: 1),
                  ),
                ),
                child: const Row(
                  children: [
                    Expanded(
                        flex: 3,
                        child: Padding(
                          padding: EdgeInsets.only(left: 16),
                          child: Text('날짜',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF9C9FB0),
                                fontFamily: 'Noto Sans KR',
                              )),
                        )),
                    Expanded(
                        flex: 2,
                        child: Center(
                            child: Text('경과',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF9C9FB0),
                                  fontFamily: 'Noto Sans KR',
                                )))),
                    Expanded(
                        flex: 2,
                        child: Center(
                            child: Text('판단',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF9C9FB0),
                                  fontFamily: 'Noto Sans KR',
                                )))),
                    Expanded(
                        flex: 2,
                        child: Center(
                            child: Text('포인트',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF9C9FB0),
                                  fontFamily: 'Noto Sans KR',
                                )))),
                  ],
                ),
              ),
              // 스켈레톤 행들
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(8),
                      bottomRight: Radius.circular(8),
                    ),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      children:
                          List.generate(5, (index) => _buildSkeletonEventRow()),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }

      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            // 테이블 헤더
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.1),
                    spreadRadius: 0,
                    blurRadius: 2,
                    offset: const Offset(0, 2),
                  ),
                ],
                border: Border(
                  bottom: BorderSide(color: Color(0xffd5d5d5), width: 1),
                ),
              ),
              child: const Row(
                children: [
                  Expanded(
                      flex: 3,
                      child: Padding(
                        padding: EdgeInsets.only(left: 16),
                        child: Text('날짜',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF9C9FB0),
                              fontFamily: 'Noto Sans KR',
                            )),
                      )),
                  Expanded(
                      flex: 2,
                      child: Center(
                          child: Text('경과',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF9C9FB0),
                                fontFamily: 'Noto Sans KR',
                              )))),
                  Expanded(
                      flex: 2,
                      child: Center(
                          child: Text('판단',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF9C9FB0),
                                fontFamily: 'Noto Sans KR',
                              )))),
                  Expanded(
                      flex: 2,
                      child: Center(
                          child: Text('포인트',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF9C9FB0),
                                fontFamily: 'Noto Sans KR',
                              )))),
                ],
              ),
            ),
            // 테이블 바디 (무한 스크롤)
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(8),
                    bottomRight: Radius.circular(8),
                  ),
                ),
                child: viewModel.eventList.isEmpty
                    ? Container(
                        width: Get.width,
                        child: Center(
                          child: const Text(
                            '이벤트 데이터가 없습니다',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                              fontFamily: 'Noto Sans KR',
                            ),
                          ),
                        ),
                      )
                    : NotificationListener<ScrollNotification>(
                        onNotification: (ScrollNotification scrollInfo) {
                          // 스크롤 정보 로깅 (디버깅용)
                          if (scrollInfo is ScrollUpdateNotification) {
                            final currentScroll = scrollInfo.metrics.pixels;
                            final maxScroll =
                                scrollInfo.metrics.maxScrollExtent;
                            final threshold = maxScroll - 100; // 임계값을 100으로 줄임

                            // print('📊 스크롤 상태: ${currentScroll.toInt()}/${maxScroll.toInt()} (임계값: ${threshold.toInt()}) hasMore: ${viewModel.hasMoreEvents.value} loading: ${viewModel.isEventsLoading.value}');

                            // 스크롤이 끝에 도달했을 때 또는 거의 도달했을 때
                            if ((currentScroll >= threshold ||
                                    currentScroll >= maxScroll) &&
                                viewModel.hasMoreEvents.value &&
                                !viewModel.isEventsLoading.value) {
                              print(
                                  '🔥 무한스크롤 트리거! ${currentScroll.toInt()}/${maxScroll.toInt()}');
                              viewModel.loadMoreEvents();
                            }
                          }
                          return false;
                        },
                        child: ListView.builder(
                          padding: EdgeInsets.zero,
                          itemCount: viewModel.eventList.length +
                              (viewModel.hasMoreEvents.value
                                  ? 1
                                  : 0), // 로딩 인디케이터용 +1
                          itemBuilder: (context, index) {
                            if (index < viewModel.eventList.length) {
                              return _buildEventRow(viewModel.eventList[index]);
                            } else {
                              // 로딩 인디케이터
                              return Container(
                                padding: const EdgeInsets.all(16),
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                      ),
              ),
            ),
          ],
        ),
      );
    });
  }

  /// 이벤트 행 위젯
  Widget _buildEventRow(EventItem event) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: const BoxDecoration(
        border: Border(
            // bottom: BorderSide(color: Colors.grey, width: 0.2),
            ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Text(
                event.date,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    fontFamily: 'Noto Sans KR'),
                textAlign: TextAlign.left,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Center(
              child: Text(
                event.elapsedTime,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    fontFamily: 'Noto Sans KR'),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Center(
              child: Text(
                event.result,
                style: TextStyle(
                    fontSize: 14,
                    color: event.resultColor,
                    fontWeight: FontWeight.w400,
                    fontFamily: 'Noto Sans KR'),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Center(
              child: Text(
                event.pointsText,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    fontFamily: 'Noto Sans KR'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 스켈레톤 이벤트 행 위젯
  Widget _buildSkeletonEventRow() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey, width: 0.2),
        ),
      ),
      child: SkeletonLoader(
        child: Row(
          children: [
            // 날짜
            Expanded(
              flex: 3,
              child: Center(
                child: Text(
                  '2025-01-15\n10:30:45',
                  style:
                      const TextStyle(fontSize: 12, color: Colors.transparent),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            // 경과
            Expanded(
              flex: 2,
              child: Center(
                child: Text(
                  '15초',
                  style:
                      const TextStyle(fontSize: 12, color: Colors.transparent),
                ),
              ),
            ),
            // 판단
            Expanded(
              flex: 2,
              child: Center(
                child: Text(
                  '화재',
                  style:
                      const TextStyle(fontSize: 12, color: Colors.transparent),
                ),
              ),
            ),
            // 포인트
            Expanded(
              flex: 2,
              child: Center(
                child: Text(
                  '1000 P',
                  style:
                      const TextStyle(fontSize: 12, color: Colors.transparent),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
