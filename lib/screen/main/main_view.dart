import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'main_view_model.dart';

class MainView extends StatelessWidget {
  const MainView({super.key});

  @override
  Widget build(BuildContext context) {
    final MainViewModel viewModel = Get.put(MainViewModel());

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
      body: Obx(() {
        if (viewModel.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '시스템 현황',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: viewModel.statusItems.length,
                  itemBuilder: (context, index) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: const Icon(
                          Icons.info_outline,
                          color: Colors.blue,
                        ),
                        title: Text(viewModel.statusItems[index]),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          // 상세 정보 보기 등의 기능 구현
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}