import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';

import '../../components/dialog.dart';
import '../../utils/font/font.dart';
import '../../notification/firebase_cloud_messaging.dart';
import '../../notification/local_notification_setting.dart';
import '../../provider/camera_state.dart';
import '../../provider/user_state.dart';
import '../../provider/notification_state.dart';
import '../../services/camera_notification_service.dart';
import '../main/main_view.dart';
import '../main/main_view_model.dart';
import '../video/video_page.dart';
import '../record/record_view.dart';
import '../setting/setting_view.dart';
import 'navigation_service.dart';

class BottomNavigatorViewModel extends GetxController {
  // TabController 제거 - Ticker 문제 해결

  // Reactive Variables
  final RxInt currentIndex = 0.obs;
  final RxBool isLoading = true.obs;
  final RxList<Widget> widgetOptions = <Widget>[].obs;
  final RxString alertVideoUrl = ''.obs;
  final RxString alertVideoType = ''.obs;

  // ⭐ 현재 보고 있는 영상의 인덱스 (notificationList 기준)
  final RxInt currentVideoIndex = 0.obs;

  // Dependencies
  final UserState userState = Get.put(UserState());
  final CameraState cameraState = Get.put(CameraState());
  final NavigationService navigationService = NavigationService();
  final FlutterSecureStorage storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );

  // ⭐ NotificationState 의존성 추가
  NotificationState get ns => Get.find<NotificationState>();

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
    _initializeIndex();
    _initializeWidgetOptions();
    _initializeApp();
  }

  @override
  void onClose() {
    // TabController 제거로 인해 별도 dispose 불필요
    super.onClose();
  }

  /// 초기 인덱스 설정
  void _initializeIndex() {
    try {
      final targetIndex = userState.bottomIndex.value.clamp(0, 3);
      currentIndex.value = targetIndex;
    } catch (e) {
      print('인덱스 초기화 오류: $e');
      currentIndex.value = 0;
    }
  }

  /// 위젯 옵션 초기화
  void _initializeWidgetOptions() {
    print("alertVideoUrl.value ${alertVideoUrl.value}");

    widgetOptions.value = [
      const MainView(),
      VideoPage(
          key: ValueKey(
              '${alertVideoUrl.value}_${DateTime.now().millisecondsSinceEpoch}'), // 고유 키로 새 인스턴스 보장
          videoUrl: alertVideoUrl.value,
          type: alertVideoType.value.isNotEmpty ? alertVideoType.value : '경보'),
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
  void onTabChanged(int index) async {
    navigationService.changeTab(index);
    currentIndex.value = index;

    // main 탭(index 0)으로 이동할 때 유저 정보 새로고침
    if (index == 0) {
      if (Get.isRegistered<MainViewModel>()) {
        final mainViewModel = Get.find<MainViewModel>();
        mainViewModel.refreshUserInfo(); // API 호출해서 유저 정보 갱신
        await mainViewModel.fetchWorkTimeFromAPI();
        mainViewModel.resetToCurrentMonth();
      } else {
        print('MainViewModel이 아직 등록되지 않음');
        // 메인 페이지가 아직 로드되지 않아서 ViewModel이 없는 경우
        // 메인 페이지에서 직접 새로고침이 실행될 것임
      }
    }

    // ⭐ 경보 탭(index 1)으로 이동할 때 대기 중인 알림 확인
    if (index == 1) {
      print('카메라 탭 활성화');
      await _checkPendingNotificationsOnTabChange();
    }

    // 탭 변경 시에는 VideoPage를 재생성하지 않음 (완료 상태 유지)
    // VideoPage 재생성은 새로운 FCM 알림이 올 때만 수행
  }

  /// 뒤로가기 처리
  Future<bool> handleBackPress() async {
    if (currentBackPressTime == null ||
        DateTime.now().difference(currentBackPressTime!) >
            const Duration(seconds: 2)) {
      currentBackPressTime = DateTime.now();
      return false; // 첫 번째 클릭 - 스낵바 표시
    } else {
      exit(0); // 두 번째 클릭 - 앱 종료
    }
  }

  /// 커스텀 스낵바 표시
  void showCustomSnackbar(BuildContext context, String message) {
    if (_snackBarEntry != null) return;

    // Overlay 존재 여부 확인
    final overlay = Overlay.maybeOf(context);
    if (overlay == null) {
      print('Overlay를 찾을 수 없습니다');
      return;
    }

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
                  color: Colors.black.withValues(alpha: 0.3),
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
                Text(
                  '"뒤로" 버튼을 한 번 더 누르시면 종료됩니다',
                  style: f12w700Size().copyWith(
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    overlay.insert(_snackBarEntry!);

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
  Widget get currentPageWidget {
    // 경보 탭(index 1)이고 alertVideoUrl이 비어있으면 빈 VideoPage 반환
    if (currentIndex.value == 1 && alertVideoUrl.value.isEmpty) {
      return VideoPage(
          key: ValueKey('empty_${DateTime.now().millisecondsSinceEpoch}'),
          videoUrl: '',
          type: '경보');
    }
    return widgetOptions[currentIndex.value];
  }

  /// 위젯이 준비되었는지 확인
  bool get isWidgetReady {
    try {
      return widgetOptions.length == 4;
    } catch (e) {
      print('위젯 상태 확인 오류: $e');
      return false;
    }
  }

  /// FCM에서 경보 탭으로 이동하면서 videoUrl 설정
  void navigateToAlertWithVideo(String videoUrl, String type) {
    try {
      alertVideoUrl.value = videoUrl;
      alertVideoType.value = type;

      // ⭐ 가장 최신 영상(마지막)을 먼저 보여줌
      if (ns.notificationList.isNotEmpty) {
        currentVideoIndex.value = ns.notificationList.length - 1;
        final latestNotification = ns.notificationList[currentVideoIndex.value];

        // 최신 알림의 데이터 사용
        alertVideoUrl.value = videoUrl;
        alertVideoType.value = latestNotification['type'] ?? type;
      }

      // 새로운 FCM 알림이 올 때만 VideoPage 재생성 (고유 키로 새 인스턴스 보장)
      if (widgetOptions.length >= 2) {
        widgetOptions[1] = VideoPage(
            key: ValueKey(
                '${videoUrl}_${DateTime.now().millisecondsSinceEpoch}'),
            videoUrl: videoUrl,
            type: type);
        widgetOptions.refresh(); // RxList 강제 업데이트
      } else {
        _initializeWidgetOptions();
      }

      // 경보 탭(index 1)로 이동
      onTabChanged(1);

      // TabController 제거로 인해 별도 애니메이션 처리 불필요
    } catch (e) {
      print('navigateToAlertWithVideo 오류: $e');
      // 오류 발생 시 안전하게 기본 초기화
      _initializeWidgetOptions();
      onTabChanged(1);
    }
  }

  /// ⭐ 이전 영상으로 이동 (더 최신 영상, createDate 기준 오른쪽)
  void moveToPreviousVideo() {
    if (ns.notificationList.isEmpty) return;

    // 인덱스 증가 (리스트의 뒤쪽 = 최신)
    if (currentVideoIndex.value < ns.notificationList.length - 1) {
      currentVideoIndex.value++;
      loadVideoAtIndex(currentVideoIndex.value);
    }
  }

  /// ⭐ 다음 영상으로 이동 (더 오래된 영상, createDate 기준 왼쪽)
  void moveToNextVideo() {
    if (ns.notificationList.isEmpty) return;

    // 인덱스 감소 (리스트의 앞쪽 = 오래됨)
    if (currentVideoIndex.value > 0) {
      currentVideoIndex.value--;
      loadVideoAtIndex(currentVideoIndex.value);
    }
  }

  /// ⭐ 특정 인덱스의 영상 로드 (public으로 변경하여 VideoPage에서도 접근 가능)
  Future<void> loadVideoAtIndex(int index) async {
    if (index < 0 || index >= ns.notificationList.length) return;

    final notification = ns.notificationList[index];
    final docId = notification['docId'];
    final type = notification['type'] ?? '경보';

    try {
      print('🔄 영상 전환 시작: 인덱스 $index/${ns.notificationList.length - 1}');

      // ⭐ 로딩 상태 표시를 위해 먼저 빈 VideoPage로 교체
      if (widgetOptions.length >= 2) {
        widgetOptions[1] = VideoPage(
            key: ValueKey('loading_${DateTime.now().millisecondsSinceEpoch}'),
            videoUrl: '',  // 빈 URL로 로딩 화면 표시
            type: '로딩 중...');
        widgetOptions.refresh();
      }

      // 잠시 대기 (로딩 화면이 표시되도록)
      await Future.delayed(Duration(milliseconds: 100));

      // 비디오 URL 가져오기
      final cameraService = CameraNotificationService();
      final videoUrl = await cameraService.getVideoUrl(docId);

      // 현재 알림 데이터 업데이트
      ns.notificationData.value = notification;

      // VideoPage 재생성 (새로운 영상)
      alertVideoUrl.value = videoUrl;
      alertVideoType.value = type;

      if (widgetOptions.length >= 2) {
        widgetOptions[1] = VideoPage(
            key: ValueKey('${videoUrl}_${DateTime.now().millisecondsSinceEpoch}'),
            videoUrl: videoUrl,
            type: type);
        widgetOptions.refresh();
      }

      print('✅ 영상 전환 완료: 인덱스 $index/${ns.notificationList.length - 1}');
    } catch (e) {
      print('❌ 영상 로드 실패: $e');
    }
  }

  /// ⭐ 현재 영상의 개수
  int get totalVideoCount => ns.notificationList.length;

  /// ⭐ 이전 영상이 있는지 (더 최신 영상)
  bool get hasPreviousVideo => currentVideoIndex.value < ns.notificationList.length - 1;

  /// ⭐ 다음 영상이 있는지 (더 오래된 영상)
  bool get hasNextVideo => currentVideoIndex.value > 0;

  /// ⭐ 경보 탭 활성화 시 대기 중인 알림 확인
  Future<void> _checkPendingNotificationsOnTabChange() async {
    try {
      print('🔍 경보 탭 활성화 - 대기 중인 알림 확인 시작');

      // NotificationState에 이미 알림이 있으면 새로 불러오지 않음
      if (ns.notificationList.isNotEmpty) {
        print('ℹ️ 이미 ${ns.notificationList.length}개의 알림이 있음 - 새로 불러오지 않음');
        return;
      }

      // 대기 중인 알림 목록 확인
      final cameraService = CameraNotificationService();
      final pendingNotifications = await cameraService.checkPendingNotifications();

      if (pendingNotifications.isNotEmpty) {
        print('🔔 경보 탭 활성화 시 대기중인 알림 발견: ${pendingNotifications.length}개');

        // 알림들을 NotificationState에 추가
        for (final notification in pendingNotifications) {
          ns.addNotification(notification);
        }

        // 가장 최신 알림을 표시
        if (ns.notificationList.isNotEmpty) {
          final latestNotification = ns.notificationList.last;
          final docId = latestNotification['docId'];
          final type = latestNotification['type'] ?? '경보';

          // 현재 알림 데이터 설정
          ns.notificationData.value = latestNotification;

          // 비디오 URL 가져오기
          final videoUrl = await cameraService.getVideoUrl(docId.toString());

          // VideoPage 재생성
          alertVideoUrl.value = videoUrl;
          alertVideoType.value = type;
          currentVideoIndex.value = ns.notificationList.length - 1;

          if (widgetOptions.length >= 2) {
            widgetOptions[1] = VideoPage(
                key: ValueKey('${videoUrl}_${DateTime.now().millisecondsSinceEpoch}'),
                videoUrl: videoUrl,
                type: type);
            widgetOptions.refresh();
          }

          print('✅ 경보 탭 활성화 시 알림 로드 완료');
        }
      } else {
        print('ℹ️ 경보 탭 활성화 시 대기중인 알림 없음');
      }
    } catch (e) {
      print('❌ 경보 탭 활성화 시 알림 확인 오류: $e');
    }
  }
}

