import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'record_view_model.dart';

class RecordView extends StatefulWidget {
  const RecordView({super.key});

  @override
  State<RecordView> createState() => _RecordViewState();
}

class _RecordViewState extends State<RecordView>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final RecordViewModel viewModel = Get.put(RecordViewModel());

    // 페이지가 나타날 때마다 데이터 갱신
    WidgetsBinding.instance.addPostFrameCallback((_) {
      viewModel.refresh();
    });

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // 상단 헤더
            _buildHeader(),
            // 월별 네비게이션
            _buildMonthNavigation(viewModel),
            // 알림 내역 테이블 (무한 스크롤)
            Expanded(
              child: _buildAlertTable(viewModel),
            ),
          ],
        ),
      ),
    );
  }

  /// 상단 헤더
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
      child: const Row(
        children: [
          Text(
            '알림 내역',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  /// 월별 네비게이션
  Widget _buildMonthNavigation(RecordViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: viewModel.goToPreviousMonth,
          ),
          Obx(() => Text(
                viewModel.monthDisplayText,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              )),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: viewModel.goToNextMonth,
          ),
        ],
      ),
    );
  }

  /// 알림 내역 테이블
  Widget _buildAlertTable(RecordViewModel viewModel) {
    return Obx(() {
      if (viewModel.isLoading.value && viewModel.records.isEmpty) {
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
                ),
                child: const Row(
                  children: [
                    Expanded(
                        flex: 3,
                        child: Padding(
                          padding: EdgeInsets.only(left: 16),
                          child: Text('날짜',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                        )),
                    Expanded(
                        flex: 2,
                        child: Center(
                            child: Text('알림',
                                style:
                                    TextStyle(fontWeight: FontWeight.bold)))),
                    Expanded(
                        flex: 2,
                        child: Center(
                            child: Text('에이전트',
                                style:
                                    TextStyle(fontWeight: FontWeight.bold)))),
                    Expanded(
                        flex: 2,
                        child: Center(
                            child: Text('결과',
                                style:
                                    TextStyle(fontWeight: FontWeight.bold)))),
                    Expanded(
                        flex: 2,
                        child: Center(
                            child: Text('영상',
                                style:
                                    TextStyle(fontWeight: FontWeight.bold)))),
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
                  child: const Center(
                    child: CircularProgressIndicator(),
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
              ),
              child: const Row(
                children: [
                  Expanded(
                      flex: 3,
                      child: Padding(
                        padding: EdgeInsets.only(left: 16),
                        child: Text('날짜',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      )),
                  Expanded(
                      flex: 2,
                      child: Center(
                          child: Text('알림',
                              style: TextStyle(fontWeight: FontWeight.bold)))),
                  Expanded(
                      flex: 2,
                      child: Center(
                          child: Text('에이전트',
                              style: TextStyle(fontWeight: FontWeight.bold)))),
                  Expanded(
                      flex: 2,
                      child: Center(
                          child: Text('결과',
                              style: TextStyle(fontWeight: FontWeight.bold)))),
                  Expanded(
                      flex: 2,
                      child: Center(
                          child: Text('영상',
                              style: TextStyle(fontWeight: FontWeight.bold)))),
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
                child: viewModel.records.isEmpty
                    ? Container(
                        padding: const EdgeInsets.all(32),
                        child: const Text(
                          '알림 내역이 없습니다',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                      )
                    : NotificationListener<ScrollNotification>(
                        onNotification: (ScrollNotification scrollInfo) {
                          if (scrollInfo is ScrollUpdateNotification) {
                            final currentScroll = scrollInfo.metrics.pixels;
                            final maxScroll =
                                scrollInfo.metrics.maxScrollExtent;
                            final threshold = maxScroll - 100;

                            if ((currentScroll >= threshold ||
                                    currentScroll >= maxScroll) &&
                                viewModel.hasMoreRecords.value &&
                                !viewModel.isLoading.value) {
                              print(
                                  '🔥 알림 내역 무한스크롤 트리거! ${currentScroll.toInt()}/${maxScroll.toInt()}');
                              viewModel.loadMoreRecords();
                            }
                          }
                          return false;
                        },
                        child: ListView.builder(
                          padding: EdgeInsets.zero,
                          itemCount: viewModel.records.length +
                              (viewModel.hasMoreRecords.value ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index < viewModel.records.length) {
                              return _buildTableRow(
                                  viewModel.records[index], viewModel);
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

  /// 테이블 행
  Widget _buildTableRow(RecordItem record, RecordViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey, width: 0.2),
        ),
      ),
      child: Row(
        children: [
          // 날짜 (왼쪽 정렬)
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Text(
                record.dateText,
                style: const TextStyle(fontSize: 12),
                textAlign: TextAlign.left,
              ),
            ),
          ),
          // 알림 (불꽃 알림, 연기 알림 등)
          Expanded(
            flex: 2,
            child: Center(
              child: Text(
                record.alertType,
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ),
          // 에이전트 (화재, 비화재)
          Expanded(
            flex: 2,
            child: Center(
              child: Text(
                record.eventType,
                style: TextStyle(
                  fontSize: 12,
                  color: record.eventColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          // 결과 (NG 고정값)
          Expanded(
            flex: 2,
            child: Center(
              child: Text(
                'NG',
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ),
          // 영상 (재생 버튼)
          Expanded(
            flex: 2,
            child: Center(
              child: IconButton(
                icon: const Icon(
                  Icons.play_arrow,
                  color: Colors.blue,
                  size: 20,
                ),
                onPressed: () => viewModel.playVideo(record),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
