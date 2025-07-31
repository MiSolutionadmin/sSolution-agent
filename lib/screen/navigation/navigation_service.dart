import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';

import '../../provider/user_state.dart';
import 'bottom_navigator_model.dart';

class NavigationService {
  static final NavigationService _instance = NavigationService._internal();
  factory NavigationService() => _instance;
  NavigationService._internal();

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );
  final UserState _userState = Get.put(UserState());

  /// 네비게이션 초기화
  Future<NavigationConfig> initializeNavigation() async {
    try {
      // 사용자 설정에 따른 네비게이션 구성
      final config = NavigationConfig.getDefault();
      
      // 저장된 탭 인덱스 복원
      final savedIndex = await getSavedTabIndex();
      if (config.isValidIndex(savedIndex)) {
        _userState.bottomIndex.value = savedIndex;
        _userState.selectBottomIndex.value = savedIndex;
      }

      return config;
    } catch (e) {
      print('네비게이션 초기화 오류: $e');
      return NavigationConfig.getDefault();
    }
  }

  /// 탭 변경 처리
  Future<void> changeTab(int newIndex) async {
    try {
      final config = NavigationConfig.getDefault();
      
      if (!config.isValidIndex(newIndex)) {
        throw Exception('잘못된 탭 인덱스: $newIndex');
      }

      // 탭 변경 로직
      await _handleTabChange(newIndex);
      
      // 상태 업데이트
      _userState.bottomIndex.value = 0; // 기본값으로 리셋
      _userState.selectBottomIndex.value = newIndex;
      
      // 탭 인덱스 저장
      await saveTabIndex(newIndex);
      
    } catch (e) {
      print('탭 변경 오류: $e');
    }
  }

  /// 탭 변경 시 추가 로직 처리
  Future<void> _handleTabChange(int newIndex) async {
    switch (newIndex) {
      case 0: // 모니터링
        await _handleMonitoringTab();
        break;
      case 1: // 카메라
        await _handleCameraTab();
        break;
      case 2: // 알림
        await _handleNotificationTab();
        break;
      case 3: // 설정
        await _handleSettingsTab();
        break;
    }
  }

  /// 모니터링 탭 처리
  Future<void> _handleMonitoringTab() async {
    // 카메라 리스트 클리어 (카메라 탭이 아닌 경우)
    try {
      final cameraState = Get.find<dynamic>(); // CameraState 가져오기
      if (cameraState.cameraList != null) {
        cameraState.cameraList.clear();
      }
    } catch (e) {
      print('카메라 상태 처리 오류: $e');
    }
  }

  /// 카메라 탭 처리
  Future<void> _handleCameraTab() async {
    // 카메라 탭 진입 시 특별한 처리가 필요한 경우
    print('카메라 탭 활성화');
  }

  /// 알림 탭 처리
  Future<void> _handleNotificationTab() async {
    // 알림 데이터 새로고침 등
    print('알림 탭 활성화');
  }

  /// 설정 탭 처리
  Future<void> _handleSettingsTab() async {
    // 설정 데이터 로드 등
    print('설정 탭 활성화');
  }

  /// 저장된 탭 인덱스 가져오기
  Future<int> getSavedTabIndex() async {
    try {
      final savedIndex = await _storage.read(key: 'saved_tab_index');
      return int.tryParse(savedIndex ?? '0') ?? 0;
    } catch (e) {
      print('저장된 탭 인덱스 가져오기 오류: $e');
      return 0;
    }
  }

  /// 탭 인덱스 저장
  Future<void> saveTabIndex(int index) async {
    try {
      await _storage.write(key: 'saved_tab_index', value: index.toString());
    } catch (e) {
      print('탭 인덱스 저장 오류: $e');
    }
  }

  /// 네비게이션 권한 확인
  bool hasNavigationPermission(int tabIndex) {
    // 사용자 권한에 따른 탭 접근 제어
    final userData = _userState.userData.value;
    
    if (userData.isEmpty) {
      return false;
    }

    // 권한별 탭 접근 제어 로직
    switch (tabIndex) {
      case 0: // 모니터링
        return true; // 모든 사용자 접근 가능
      case 1: // 카메라
        return _hasPermission('camera');
      case 2: // 알림
        return _hasPermission('notification');
      case 3: // 설정
        return _hasPermission('settings');
      default:
        return false;
    }
  }

  /// 특정 권한 확인
  bool _hasPermission(String permission) {
    final userData = _userState.userData.value;
    final userRole = userData['role']?.toString().toLowerCase();
    
    // 관리자는 모든 권한 보유
    if (userRole == 'admin' || userRole == 'administrator') {
      return true;
    }

    // 권한별 체크 로직
    switch (permission) {
      case 'camera':
        return userData['cameraPermission'] == true || 
               userData['permissions']?.contains('camera') == true;
      case 'notification':
        return userData['notificationPermission'] == true || 
               userData['permissions']?.contains('notification') == true;
      case 'settings':
        return userData['settingsPermission'] == true || 
               userData['permissions']?.contains('settings') == true;
      default:
        return false;
    }
  }

  /// 네비게이션 상태 리셋
  Future<void> resetNavigation() async {
    try {
      _userState.bottomIndex.value = 0;
      _userState.selectBottomIndex.value = 0;
      await saveTabIndex(0);
    } catch (e) {
      print('네비게이션 리셋 오류: $e');
    }
  }

  /// 특정 탭으로 네비게이션
  Future<void> navigateToTab(int tabIndex, {bool saveState = true}) async {
    try {
      if (!hasNavigationPermission(tabIndex)) {
        throw Exception('해당 탭에 접근할 권한이 없습니다.');
      }

      await changeTab(tabIndex);
      
      if (saveState) {
        await saveTabIndex(tabIndex);
      }
    } catch (e) {
      print('탭 네비게이션 오류: $e');
      Get.snackbar('오류', e.toString());
    }
  }

  /// 뒤로가기 처리
  Future<bool> handleBackPress() async {
    final currentIndex = _userState.selectBottomIndex.value;
    
    // 첫 번째 탭이 아닌 경우 첫 번째 탭으로 이동
    if (currentIndex != 0) {
      await navigateToTab(0, saveState: false);
      return false; // 앱 종료하지 않음
    }
    
    return true; // 앱 종료 허용
  }

  /// 네비게이션 상태 정보
  Map<String, dynamic> getNavigationState() {
    return {
      'currentIndex': _userState.selectBottomIndex.value,
      'bottomIndex': _userState.bottomIndex.value,
      'hasPermissions': {
        'camera': hasNavigationPermission(1),
        'notification': hasNavigationPermission(2),
        'settings': hasNavigationPermission(3),
      },
    };
  }
}