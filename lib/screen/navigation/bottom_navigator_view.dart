import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

import '../../utils/font/font.dart';
import 'bottom_navigator_model.dart';
import 'bottom_navigator_view_model.dart';
import '../video/video_page.dart';

class BottomNavigatorView extends StatelessWidget {
  static const String routeName = '/main';

  const BottomNavigatorView({super.key});

  @override
  Widget build(BuildContext context) {
    final BottomNavigatorViewModel viewModel =
        Get.put(BottomNavigatorViewModel());

    return Obx(() => viewModel.isLoading.value
        ? _buildLoadingScreen()
        : _buildMainScreen(viewModel));
  }

  /// 로딩 화면
  Widget _buildLoadingScreen() {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  /// 메인 화면
  Widget _buildMainScreen(BottomNavigatorViewModel viewModel) {
    return PopScope(
      canPop: false,
      onPopInvoked: (bool pop) async {
        final shouldExit = await viewModel.handleBackPress();
        if (!shouldExit && Get.context != null) {
          viewModel.showCustomSnackbar(
              Get.context!, '"뒤로" 버튼을 한 번 더 누르시면 종료됩니다');
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        extendBody: false,
        extendBodyBehindAppBar: false,
        resizeToAvoidBottomInset: false,
        bottomNavigationBar: _buildBottomNavigationBar(viewModel),
        body: _buildTabBarView(viewModel),
      ),
    );
  }

  /// 하단 네비게이션 바
  Widget _buildBottomNavigationBar(BottomNavigatorViewModel viewModel) {
    return Builder(
      builder: (context) {
        final mediaQuery = MediaQuery.of(context);
        final bottomPadding = mediaQuery.padding.bottom;

        return Container(
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(width: 2.0, color: Color(0xffF1F4F7)),
            ),
            color: Colors.white,
          ),
          padding: EdgeInsets.only(
            bottom: Platform.isAndroid
                ? (bottomPadding > 0 ? bottomPadding + 0 : 0)
                : (bottomPadding > 0 ? bottomPadding + 0 : 0),
          ),
          child: _buildFallbackNavigationBar(viewModel),
        );
      },
    );
  }

  /// 탭 아이콘 생성
  Widget _buildTabIcon(NavigationTabItem tabItem, bool isSelected) {
    switch (tabItem.index) {
      case 0: // 메인
        return SvgPicture.asset(
          'assets/bottom_icon/fi_home.svg',
          width: 24,
          height: 24,
          colorFilter: ColorFilter.mode(
            isSelected ? Colors.black : Colors.grey,
            BlendMode.srcIn,
          ),
        );
      case 1: // 경보
        return SvgPicture.asset(
          'assets/bottom_icon/fi_alert-triangle.svg',
          width: 24,
          height: 24,
          colorFilter: ColorFilter.mode(
            isSelected ? Colors.black : Colors.grey,
            BlendMode.srcIn,
          ),
        );
      case 2: // 기록
        return SvgPicture.asset(
          'assets/bottom_icon/u_history.svg',
          width: 24,
          height: 24,
          colorFilter: ColorFilter.mode(
            isSelected ? Colors.black : Colors.grey,
            BlendMode.srcIn,
          ),
        );
      case 3: // 설정
        return SvgPicture.asset(
          'assets/bottom_icon/fi_settings.svg',
          width: 24,
          height: 24,
          colorFilter: ColorFilter.mode(
              isSelected ? Colors.black : Colors.grey, BlendMode.srcIn),
        );
      default:
        return const Icon(Icons.help, size: 24, color: Colors.grey);
    }
  }

  /// 네비게이션 바
  Widget _buildFallbackNavigationBar(BottomNavigatorViewModel viewModel) {
    final navigationConfig = NavigationConfig.getDefault();

    return Obx(() => Row(
          children: navigationConfig.tabs
              .map((tabItem) => Expanded(
                    child: GestureDetector(
                      onTap: () => viewModel.onTabChanged(tabItem.index),
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 16, horizontal: 8),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildTabIcon(tabItem,
                                viewModel.currentIndex.value == tabItem.index),
                            const SizedBox(height: 6),
                            Text(
                              tabItem.label,
                              style:
                                  viewModel.currentIndex.value == tabItem.index
                                      ? f12w700
                                      : f12w700BlurGrey,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ))
              .toList(),
        ));
  }

  /// 탭 바 뷰
  Widget _buildTabBarView(BottomNavigatorViewModel viewModel) {
    return Obx(() {
      // 경보 탭(index 1)인 경우 매번 새로운 VideoPage 생성
      if (viewModel.currentIndex.value == 1) {
        return VideoPage(
          videoUrl: viewModel.alertVideoUrl.value,
          type: viewModel.alertVideoType.value.isNotEmpty
              ? viewModel.alertVideoType.value
              : '경보',
        );
      }

      // 다른 탭들은 기존 위젯 사용
      return IndexedStack(
        index: viewModel.currentIndex.value,
        children: viewModel.widgetOptions,
      );
    });
  }
}
