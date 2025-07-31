import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';

import '../../components/dialog.dart';
import '../../notification/firebase_cloud_messaging.dart';
import '../../notification/local_notification_setting.dart';
import '../../provider/camera_state.dart';
import '../../provider/user_state.dart';
import '../main/main_view.dart';
import '../video/video_page.dart';
import '../record/record_view.dart';
import '../setting/setting_view.dart';
import 'navigation_service.dart';

class BottomNavigatorViewModel extends GetxController with GetTickerProviderStateMixin {
  // Tab Controller
  late TabController bottomTabController;
  
  // Reactive Variables
  final RxInt currentIndex = 0.obs;
  final RxBool isLoading = true.obs;
  final RxList<Widget> widgetOptions = <Widget>[].obs;
  final RxString alertVideoUrl = ''.obs;
  final RxString alertVideoType = ''.obs;
  
  // Dependencies
  final UserState userState = Get.put(UserState());
  final CameraState cameraState = Get.put(CameraState());
  final NavigationService navigationService = NavigationService();
  final FlutterSecureStorage storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );
  
  // FCM 관련
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = 
      FlutterLocalNotificationsPlugin();
  AndroidNotificationChannel? androidNotificationChannel;
  
  // Back press handling
  DateTime? currentBackPressTime;
  static OverlayEntry? _snackBarEntry;

  @override
  void onInit() {
    super.onInit();
    _initializeTabController();
    _initializeWidgetOptions();
    _initializeApp();
  }

  @override
  void onClose() {
    try {
      // TabController가 사용 중이 아닐 때만 dispose
      if (!bottomTabController.indexIsChanging) {
        bottomTabController.dispose();
      }
    } catch (e) {
      print('TabController dispose 오류: $e');
      try {
        bottomTabController.dispose();
      } catch (e2) {
        print('TabController 강제 dispose 오류: $e2');
      }
    }
    super.onClose();
  }

  /// 탭 컨트롤러 초기화
  void _initializeTabController() {
    try {
      bottomTabController = TabController(length: 4, vsync: this);
      final targetIndex = userState.bottomIndex.value.clamp(0, 3);
      bottomTabController.animateTo(targetIndex);
      currentIndex.value = targetIndex;
    } catch (e) {
      print('TabController 초기화 오류: $e');
      // 기본값으로 초기화
      bottomTabController = TabController(length: 4, vsync: this);
      currentIndex.value = 0;
    }
  }

  /// 위젯 옵션 초기화
  void _initializeWidgetOptions() {
    widgetOptions.value = [
      const MainView(),
      Obx(() => alertVideoUrl.value.isNotEmpty 
        ? VideoPage(videoUrl: alertVideoUrl.value, type: alertVideoType.value)
        : const VideoPage(videoUrl: "http://misnetwork.iptime.org:9099/videos/record_2025-07-29-16-05-38.mp4", type: '경보')), // 기본 경보용 비디오 페이지
      const RecordView(),
      const SettingView(),
    ];
  }

  /// 앱 초기화
  Future<void> _initializeApp() async {
    try {
      // FCM 및 로컬 알림 초기화
      if (userState.userFirst.value) {
        userState.userFirst.value = false;
        LocalNotifyCation().initializeNotification();
        FCM().setNotifications();
      }

      // 폰트 사이즈 설정
      await _initializeFontSize();

      // 릴리즈 노트 체크
      _checkReleaseNote();

      isLoading.value = false;
    } catch (e) {
      print('앱 초기화 오류: $e');
      isLoading.value = false;
    }
  }

  /// 폰트 사이즈 초기화
  Future<void> _initializeFontSize() async {
    final fontSizes = await storage.read(key: "fontSizes");
    switch (fontSizes) {
      case '2':
        userState.userFont.value = 2;
        break;
      case '1':
        userState.userFont.value = 1;
        break;
      case '0':
        userState.userFont.value = 0;
        break;
      default:
        userState.userFont.value = 0;
        break;
    }
  }

  /// 릴리즈 노트 체크
  void _checkReleaseNote() {
    if (userState.userList.isNotEmpty && 
        userState.userList[0]['checkRelease'] != 'true') {
      // releaseNoteDialog 호출 - context가 필요하므로 View에서 처리
      Get.find<BottomNavigatorViewModel>().showReleaseNoteDialog();
    }
  }

  /// 탭 변경 처리
  void onTabChanged(int index) {
    navigationService.changeTab(index);
    currentIndex.value = index;
  }

  /// 뒤로가기 처리
  Future<bool> handleBackPress() async {
    if (currentBackPressTime == null || 
        DateTime.now().difference(currentBackPressTime!) > const Duration(seconds: 2)) {
      currentBackPressTime = DateTime.now();
      return false; // 첫 번째 클릭 - 스낵바 표시
    } else {
      exit(0); // 두 번째 클릭 - 앱 종료
    }
  }

  /// 커스텀 스낵바 표시
  void showCustomSnackbar(BuildContext context, String message) {
    if (_snackBarEntry != null) return;

    _snackBarEntry = OverlayEntry(
      builder: (context) => Positioned(
        bottom: 100,
        left: MediaQuery.of(context).size.width * 0.1,
        width: MediaQuery.of(context).size.width * 0.8,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.white,
                  ),
                  padding: const EdgeInsets.all(2),
                  child: Image.asset(
                    'assets/icon/ssolution_logo.png',
                    width: 24,
                    height: 24,
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  '"뒤로" 버튼을 한 번 더 누르시면 종료됩니다',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_snackBarEntry!);

    // 일정 시간 뒤 자동 제거
    Future.delayed(const Duration(seconds: 2), () {
      _snackBarEntry?.remove();
      _snackBarEntry = null;
    });
  }

  /// 릴리즈 노트 다이얼로그 표시
  void showReleaseNoteDialog() {
    if (Get.context != null) {
      releaseNoteDialog(Get.context!);
    }
  }

  /// 탭 인덱스 getter
  int get selectedIndex => currentIndex.value;

  /// 탭 바 visible 여부
  bool get isTabBarVisible => !isLoading.value;

  /// 현재 페이지 위젯
  Widget get currentPageWidget => widgetOptions[currentIndex.value];

  /// TabController가 사용 가능한지 확인
  bool get isTabControllerReady {
    try {
      return bottomTabController.length == 4 && widgetOptions.length == 4;
    } catch (e) {
      print('TabController 상태 확인 오류: $e');
      return false;
    }
  }

  /// FCM에서 경보 탭으로 이동하면서 videoUrl 설정
  void navigateToAlertWithVideo(String videoUrl, String type) {
    try {
      alertVideoUrl.value = videoUrl;
      alertVideoType.value = type;
      
      // 안전하게 위젯 옵션 업데이트 (재초기화 대신 직접 업데이트)
      if (widgetOptions.length >= 2) {
        widgetOptions[1] = VideoPage(videoUrl: videoUrl, type: type);
      } else {
        _initializeWidgetOptions();
      }
      
      // 경보 탭(index 1)로 이동
      onTabChanged(1);
      
      // TabController 상태를 체크하고 안전하게 이동
      Future.delayed(Duration(milliseconds: 100), () {
        if (isTabControllerReady && !isClosed) {
          try {
            bottomTabController.animateTo(1);
          } catch (e) {
            print('TabController animateTo 오류: $e');
          }
        }
      });
    } catch (e) {
      print('navigateToAlertWithVideo 오류: $e');
      // 오류 발생 시 안전하게 기본 초기화
      _initializeWidgetOptions();
      onTabChanged(1);
    }
  }
}