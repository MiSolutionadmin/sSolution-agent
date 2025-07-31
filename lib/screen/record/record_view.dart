import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'record_view_model.dart';

class RecordView extends StatelessWidget {
  const RecordView({super.key});

  @override
  Widget build(BuildContext context) {
    final RecordViewModel viewModel = Get.put(RecordViewModel());

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Column(
          children: [
            // 상단 헤더
            _buildHeader(),
            // 월별 네비게이션
            _buildMonthNavigation(viewModel),
            // 알림 내역 테이블
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
        border: Border(
          bottom: BorderSide(color: Colors.grey, width: 0.5),
        ),
      ),
      child: const Row(
        children: [
          Text(
            '알림 내역',
            style: TextStyle(
              fontSize: 18,
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
      color: Colors.grey[200],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
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
    return Container(
      margin: const EdgeInsets.all(16),
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
                Expanded(flex: 3, child: Center(child: Text('날짜', style: TextStyle(fontWeight: FontWeight.bold)))),
                Expanded(flex: 2, child: Center(child: Text('알림', style: TextStyle(fontWeight: FontWeight.bold)))),
                Expanded(flex: 2, child: Center(child: Text('이벤트', style: TextStyle(fontWeight: FontWeight.bold)))),
                Expanded(flex: 2, child: Center(child: Text('결과', style: TextStyle(fontWeight: FontWeight.bold)))),
                Expanded(flex: 2, child: Center(child: Text('영상', style: TextStyle(fontWeight: FontWeight.bold)))),
              ],
            ),
          ),
          // 테이블 바디
          Expanded(
            child: Obx(() {
              if (viewModel.isLoading.value) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              if (viewModel.records.isEmpty) {
                return const Center(
                  child: Text(
                    '알림 내역이 없습니다',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                );
              }

              return ListView.builder(
                itemCount: viewModel.records.length,
                itemBuilder: (context, index) {
                  final record = viewModel.records[index];
                  return _buildTableRow(record, viewModel);
                },
              );
            }),
          ),
        ],
      ),
    );
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
          // 날짜
          Expanded(
            flex: 3,
            child: Center(
              child: Text(
                record.dateText,
                style: const TextStyle(fontSize: 12),
                textAlign: TextAlign.center,
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
          // 이벤트 (비정상, 화재 등)
          Expanded(
            flex: 2,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: record.eventColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  record.eventType,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          // 결과 (OK, NG)
          Expanded(
            flex: 2,
            child: Center(
              child: Text(
                record.result,
                style: TextStyle(
                  fontSize: 12,
                  color: record.result == 'OK' ? Colors.black : Colors.red,
                  fontWeight: FontWeight.w500,
                ),
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