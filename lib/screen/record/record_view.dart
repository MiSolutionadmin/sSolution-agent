import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'record_view_model.dart';

class RecordView extends StatelessWidget {
  const RecordView({super.key});

  @override
  Widget build(BuildContext context) {
    final RecordViewModel viewModel = Get.put(RecordViewModel());

    return Scaffold(
      appBar: AppBar(
        title: Obx(() => Text(viewModel.title.value)),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: viewModel.refresh,
          ),
        ],
      ),
      body: Column(
        children: [
          // 필터 영역
          Container(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const Text(
                  '필터: ',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Expanded(
                  child: Obx(() => DropdownButton<String>(
                    value: viewModel.selectedFilter.value,
                    isExpanded: true,
                    items: viewModel.filterOptions.map((String filter) {
                      return DropdownMenuItem<String>(
                        value: filter,
                        child: Text(filter),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        viewModel.changeFilter(newValue);
                      }
                    },
                  )),
                ),
              ],
            ),
          ),
          // 기록 목록
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
                    '기록이 없습니다',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                itemCount: viewModel.records.length,
                itemBuilder: (context, index) {
                  final record = viewModel.records[index];
                  return _buildRecordCard(record, viewModel);
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordCard(RecordItem record, RecordViewModel viewModel) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => viewModel.viewRecordDetail(record),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getTypeColor(record.type),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      record.type,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Text(
                    viewModel.getRelativeTime(record.timestamp),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                record.location,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '상태: ${record.status}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    color: Colors.grey,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case '화재감지':
        return Colors.red;
      case '연기감지':
        return Colors.orange;
      case '정상':
        return Colors.green;
      default:
        return Colors.blue;
    }
  }
}