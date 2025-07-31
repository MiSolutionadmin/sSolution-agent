import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'main_view_model.dart';
import 'skeleton_widgets.dart';

class MainView extends StatelessWidget {
  const MainView({super.key});

  @override
  Widget build(BuildContext context) {
    final MainViewModel viewModel = Get.put(MainViewModel());

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Column(
          children: [
            // 상단 헤더
            _buildHeader(Get.find<MainViewModel>()),
            // 스크롤 가능한 콘텐츠 (Pull-to-refresh 추가)
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  await Get.find<MainViewModel>().loadMonthData();
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16.0),
                  child: GetBuilder<MainViewModel>(
                    builder: (viewModel) {
                      return Column(
                        children: [
                          // 사용자 정보 섹션
                          _buildUserInfo(viewModel),
                          const SizedBox(height: 20),
                          // 월별 현황 섹션
                          _buildMonthlyStatus(viewModel),
                          const SizedBox(height: 20),
                          // 통계 정보 섹션
                          _buildStatistics(viewModel),
                          const SizedBox(height: 20),
                          // 이벤트 목록 테이블
                          _buildEventTable(viewModel),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 상단 헤더 위젯
  Widget _buildHeader(MainViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          // MMS 에이전트 타이틀
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'MMS 에이전트',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
              Text(
                '(레드 닷 미리)',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          const Spacer(),
          // 알림 아이콘 (레드 닷)
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none),
                onPressed: viewModel.onNotificationTap,
              ),
              Positioned(
                right: 12,
                top: 12,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
          // 캘린더 아이콘
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: viewModel.onCalendarTap,
          ),
        ],
      ),
    );
  }

  /// 사용자 정보 섹션
  Widget _buildUserInfo(MainViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          // 이름
          _buildUserInfoItem('이름', viewModel.userName),
          const SizedBox(width: 20),
          // 등급
          _buildUserInfoItem('등급', viewModel.userGrade),
          const SizedBox(width: 20),
          // 관제 시간
          _buildUserInfoItem('관제 시간', viewModel.controlTime),
        ],
      ),
    );
  }

  /// 사용자 정보 아이템
  Widget _buildUserInfoItem(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 월별 현황 섹션
  Widget _buildMonthlyStatus(MainViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          const Text(
            '월별 현황',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: viewModel.goToPreviousMonth,
              ),
              Obx(() => Text(
                    viewModel.monthDisplayText,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  )),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: viewModel.goToNextMonth,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 통계 정보 섹션
  Widget _buildStatistics(MainViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Obx(() => Column(
            children: [
              _buildStatRow(
                  '응답 횟수',
                  viewModel.isStatsLoading.value
                      ? null
                      : viewModel.totalCount.value.toString() + '회'),
              const SizedBox(height: 12),
              _buildStatRow(
                  '응답 비율',
                  viewModel.isStatsLoading.value
                      ? null
                      : viewModel.totalRatio.value),
              const SizedBox(height: 12),
              _buildStatRow(
                  '응답 정확도',
                  viewModel.isStatsLoading.value
                      ? null
                      : viewModel.totalAccuracy.value),
              const SizedBox(height: 12),
              _buildStatRow(
                  '이달 포인트',
                  viewModel.isStatsLoading.value
                      ? null
                      : viewModel.eventPoints.value),
            ],
          )),
    );
  }

  /// 통계 행 위젯
  Widget _buildStatRow(String label, String? value) {
    return Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(4),
            ),
            child: value == null
                ? SkeletonLoader(
                    child: Text(
                      '로딩중...',
                      style: const TextStyle(
                          fontSize: 14, color: Colors.transparent),
                    ),
                  )
                : Text(
                    value,
                    style: const TextStyle(fontSize: 14),
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
        return const EventTableSkeleton();
      }

      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          children: [
            // 테이블 헤더
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
              ),
              child: const Row(
                children: [
                  Expanded(
                      flex: 3,
                      child: Center(
                          child: Text('날짜',
                              style: TextStyle(fontWeight: FontWeight.bold)))),
                  Expanded(
                      flex: 2,
                      child: Center(
                          child: Text('결과',
                              style: TextStyle(fontWeight: FontWeight.bold)))),
                  Expanded(
                      flex: 2,
                      child: Center(
                          child: Text('판단',
                              style: TextStyle(fontWeight: FontWeight.bold)))),
                  Expanded(
                      flex: 2,
                      child: Center(
                          child: Text('포인트',
                              style: TextStyle(fontWeight: FontWeight.bold)))),
                ],
              ),
            ),
            // 테이블 바디
            if (viewModel.eventList.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                child: const Text(
                  '이벤트 데이터가 없습니다',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
              )
            else
              ...viewModel.eventList.map((event) => _buildEventRow(event)),
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
          bottom: BorderSide(color: Colors.grey, width: 0.2),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Center(
              child: Text(
                event.date,
                style: const TextStyle(fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Center(
              child: Text(
                '${event.count}회',
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Center(
              child: Text(
                event.result,
                style: TextStyle(
                  fontSize: 12,
                  color: event.resultColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Center(
              child: Text(
                event.pointsText,
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
