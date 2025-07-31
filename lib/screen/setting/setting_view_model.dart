import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SettingViewModel extends GetxController {
  // 로딩 상태
  final RxBool isLoading = false.obs;
  
  // 설정 데이터
  final RxString title = '설정'.obs;
  final RxList<SettingItem> settingItems = <SettingItem>[].obs;
  
  @override
  void onInit() {
    super.onInit();
    _initializeSettings();
  }
  
  @override
  void onClose() {
    super.onClose();
  }
  
  /// 설정 아이템 초기화
  void _initializeSettings() {
    isLoading.value = true;
    
    try {
      final items = [
        SettingItem(
          id: 'account',
          title: '계정 관리',
          subtitle: '비밀번호 변경, 계정 정보',
          icon: Icons.account_circle,
          onTap: _navigateToAccountSettings,
        ),
        SettingItem(
          id: 'notification',
          title: '알림 설정',
          subtitle: '푸시 알림, 소리 설정',
          icon: Icons.notifications,
          onTap: _navigateToNotificationSettings,
        ),
        SettingItem(
          id: 'device',
          title: '장치 관리',
          subtitle: '연결된 장치 설정',
          icon: Icons.devices,
          onTap: _navigateToDeviceSettings,
        ),
        SettingItem(
          id: 'security',
          title: '보안 설정',
          subtitle: '보안 옵션 및 권한',
          icon: Icons.security,
          onTap: _navigateToSecuritySettings,
        ),
        SettingItem(
          id: 'about',
          title: '앱 정보',
          subtitle: '버전 정보, 이용약관',
          icon: Icons.info,
          onTap: _navigateToAboutApp,
        ),
        SettingItem(
          id: 'logout',
          title: '로그아웃',
          subtitle: '계정에서 로그아웃',
          icon: Icons.logout,
          onTap: _showLogoutDialog,
        ),
      ];
      
      settingItems.assignAll(items);
    } catch (e) {
      print('설정 초기화 오류: $e');
    } finally {
      isLoading.value = false;
    }
  }
  
  /// 계정 설정으로 이동
  void _navigateToAccountSettings() {
    // 계정 설정 화면으로 이동
    Get.snackbar('알림', '계정 설정 화면으로 이동합니다');
  }
  
  /// 알림 설정으로 이동
  void _navigateToNotificationSettings() {
    // 알림 설정 화면으로 이동
    Get.snackbar('알림', '알림 설정 화면으로 이동합니다');
  }
  
  /// 장치 설정으로 이동
  void _navigateToDeviceSettings() {
    // 장치 설정 화면으로 이동
    Get.snackbar('알림', '장치 설정 화면으로 이동합니다');
  }
  
  /// 보안 설정으로 이동
  void _navigateToSecuritySettings() {
    // 보안 설정 화면으로 이동
    Get.snackbar('알림', '보안 설정 화면으로 이동합니다');
  }
  
  /// 앱 정보로 이동
  void _navigateToAboutApp() {
    // 앱 정보 화면으로 이동
    Get.snackbar('알림', '앱 정보 화면으로 이동합니다');
  }
  
  /// 로그아웃 다이얼로그 표시
  void _showLogoutDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('로그아웃'),
        content: const Text('정말로 로그아웃하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              _performLogout();
            },
            child: const Text(
              '로그아웃',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
  
  /// 로그아웃 수행
  void _performLogout() {
    // 로그아웃 로직 구현
    Get.snackbar('알림', '로그아웃되었습니다');
  }
  
  /// 설정 아이템 탭 처리
  void onSettingItemTap(SettingItem item) {
    item.onTap?.call();
  }
}

class SettingItem {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onTap;
  
  SettingItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.onTap,
  });
}