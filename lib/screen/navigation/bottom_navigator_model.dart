import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// 네비게이션 탭 아이템 모델
class NavigationTabItem {
  final int index;
  final String label;
  final Widget icon;
  final Widget selectedIcon;
  final String routeName;

  NavigationTabItem({
    required this.index,
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.routeName,
  });

  /// 탭 선택 상태에 따른 아이콘 반환
  Widget getIcon(bool isSelected) {
    return isSelected ? selectedIcon : icon;
  }

  /// 탭 선택 상태에 따른 색상 반환
  Color getColor(bool isSelected) {
    return isSelected ? Colors.black : Colors.grey;
  }
}

/// 네비게이션 설정 모델
class NavigationConfig {
  final List<NavigationTabItem> tabs;
  final int initialIndex;
  final bool showLabels;
  final EdgeInsets padding;
  final Color backgroundColor;
  final Color selectedColor;
  final Color unselectedColor;

  NavigationConfig({
    required this.tabs,
    this.initialIndex = 0,
    this.showLabels = true,
    this.padding = const EdgeInsets.only(left: 10, right: 10, bottom: 8),
    this.backgroundColor = Colors.white,
    this.selectedColor = Colors.black,
    this.unselectedColor = Colors.grey,
  });

  /// 기본 네비게이션 설정 생성
  static NavigationConfig getDefault() {
    return NavigationConfig(
      tabs: [
        NavigationTabItem(
          index: 0,
          label: '메인',
          icon: const Icon(FontAwesomeIcons.home, size: 24, color: Colors.grey),
          selectedIcon: const Icon(FontAwesomeIcons.home, size: 24, color: Colors.black),
          routeName: '/main',
        ),
        NavigationTabItem(
          index: 1,
          label: '경보',
          icon: const Icon(FontAwesomeIcons.exclamationTriangle, size: 24, color: Colors.grey),
          selectedIcon: const Icon(FontAwesomeIcons.exclamationTriangle, size: 24, color: Colors.black),
          routeName: '/alert',
        ),
        NavigationTabItem(
          index: 2,
          label: '기록',
          icon: const Icon(FontAwesomeIcons.file, size: 24, color: Colors.grey),
          selectedIcon: const Icon(FontAwesomeIcons.file, size: 24, color: Colors.black),
          routeName: '/record',
        ),
        NavigationTabItem(
          index: 3,
          label: '설정',
          icon: SvgPicture.asset(
            'assets/icon/setting.svg',
            width: 24,
            height: 24,
            colorFilter: const ColorFilter.mode(Colors.grey, BlendMode.srcIn),
          ),
          selectedIcon: SvgPicture.asset(
            'assets/icon/setting.svg',
            width: 24,
            height: 24,
            colorFilter: const ColorFilter.mode(Colors.black, BlendMode.srcIn),
          ),
          routeName: '/settings',
        ),
      ],
    );
  }

  /// 탭 인덱스로 탭 아이템 가져오기
  NavigationTabItem? getTabByIndex(int index) {
    try {
      return tabs.firstWhere((tab) => tab.index == index);
    } catch (e) {
      return null;
    }
  }

  /// 탭 개수
  int get tabCount => tabs.length;

  /// 유효한 인덱스인지 확인
  bool isValidIndex(int index) {
    return index >= 0 && index < tabs.length;
  }
}

/// 뒤로가기 처리 모델
class BackPressModel {
  final DateTime pressTime;
  final String message;
  final Duration exitThreshold;

  BackPressModel({
    required this.pressTime,
    this.message = '"뒤로" 버튼을 한 번 더 누르시면 종료됩니다',
    this.exitThreshold = const Duration(seconds: 2),
  });

  /// 현재 뒤로가기가 앱 종료인지 확인
  bool shouldExit() {
    return DateTime.now().difference(pressTime) <= exitThreshold;
  }

  /// 새로운 뒤로가기 모델 생성
  BackPressModel copyWith({
    DateTime? pressTime,
    String? message,
    Duration? exitThreshold,
  }) {
    return BackPressModel(
      pressTime: pressTime ?? this.pressTime,
      message: message ?? this.message,
      exitThreshold: exitThreshold ?? this.exitThreshold,
    );
  }
}

/// 스낵바 설정 모델
class SnackBarConfig {
  final String message;
  final Duration duration;
  final EdgeInsets margin;
  final BorderRadius borderRadius;
  final Color backgroundColor;
  final TextStyle textStyle;
  final Widget? leadingIcon;

  SnackBarConfig({
    required this.message,
    this.duration = const Duration(seconds: 2),
    this.margin = const EdgeInsets.only(bottom: 100),
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
    this.backgroundColor = Colors.black,
    this.textStyle = const TextStyle(
      color: Colors.white,
      fontSize: 12,
      fontWeight: FontWeight.w700,
    ),
    this.leadingIcon,
  });

  /// 기본 스낵바 설정
  static SnackBarConfig getDefault(String message) {
    return SnackBarConfig(
      message: message,
      leadingIcon: Container(
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
    );
  }
}

/// 앱 상태 모델
class AppState {
  final bool isLoading;
  final bool isInitialized;
  final String? error;
  final Map<String, dynamic> userData;
  final int selectedTabIndex;

  AppState({
    this.isLoading = true,
    this.isInitialized = false,
    this.error,
    this.userData = const {},
    this.selectedTabIndex = 0,
  });

  AppState copyWith({
    bool? isLoading,
    bool? isInitialized,
    String? error,
    Map<String, dynamic>? userData,
    int? selectedTabIndex,
  }) {
    return AppState(
      isLoading: isLoading ?? this.isLoading,
      isInitialized: isInitialized ?? this.isInitialized,
      error: error ?? this.error,
      userData: userData ?? this.userData,
      selectedTabIndex: selectedTabIndex ?? this.selectedTabIndex,
    );
  }

  /// 앱이 사용 가능한 상태인지 확인
  bool get isReady => isInitialized && !isLoading && error == null;

  /// 에러 상태인지 확인
  bool get hasError => error != null;

  @override
  String toString() {
    return 'AppState(isLoading: $isLoading, isInitialized: $isInitialized, error: $error, selectedTabIndex: $selectedTabIndex)';
  }
}