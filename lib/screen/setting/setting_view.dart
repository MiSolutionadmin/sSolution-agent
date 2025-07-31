import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'setting_view_model.dart';

class SettingView extends StatelessWidget {
  const SettingView({super.key});

  @override
  Widget build(BuildContext context) {
    final SettingViewModel viewModel = Get.put(SettingViewModel());

    return Scaffold(
      appBar: AppBar(
        title: Obx(() => Text(viewModel.title.value)),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: Obx(() {
        if (viewModel.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: viewModel.settingItems.length,
          itemBuilder: (context, index) {
            final item = viewModel.settingItems[index];
            return _buildSettingItem(item, viewModel);
          },
        );
      }),
    );
  }

  Widget _buildSettingItem(SettingItem item, SettingViewModel viewModel) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _getIconBackgroundColor(item.id),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            item.icon,
            color: Colors.white,
            size: 24,
          ),
        ),
        title: Text(
          item.title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          item.subtitle,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right,
          color: Colors.grey,
        ),
        onTap: () => viewModel.onSettingItemTap(item),
      ),
    );
  }

  Color _getIconBackgroundColor(String id) {
    switch (id) {
      case 'account':
        return Colors.blue;
      case 'notification':
        return Colors.green;
      case 'device':
        return Colors.purple;
      case 'security':
        return Colors.orange;
      case 'about':
        return Colors.teal;
      case 'logout':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}