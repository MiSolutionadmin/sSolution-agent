import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';

import '../../utils/font/font.dart';
import 'bottom_navigator_model.dart';
import 'bottom_navigator_view_model.dart';

class BottomNavigatorView extends StatelessWidget {
  static const String routeName = '/main';
  
  const BottomNavigatorView({super.key});

  @override
  Widget build(BuildContext context) {
    final BottomNavigatorViewModel viewModel = Get.put(BottomNavigatorViewModel());
    
    return Obx(() => viewModel.isLoading.value 
      ? _buildLoadingScreen() 
      : _buildMainScreen(viewModel)
    );
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
            Get.context!, 
            '"뒤로" 버튼을 한 번 더 누르시면 종료됩니다'
          );
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        bottomNavigationBar: _buildBottomNavigationBar(viewModel),
        body: _buildTabBarView(viewModel),
      ),
    );
  }

  /// 하단 네비게이션 바
  Widget _buildBottomNavigationBar(BottomNavigatorViewModel viewModel) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(width: 2.0, color: Color(0xffF1F4F7)),
        ),
      ),
      padding: Platform.isAndroid 
        ? const EdgeInsets.all(0) 
        : const EdgeInsets.only(bottom: 10),
      child: TabBar(
        onTap: viewModel.onTabChanged,
        dividerColor: Colors.transparent,
        indicatorColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.label,
        controller: viewModel.bottomTabController,
        unselectedLabelStyle: hintf14w700,
        labelStyle: f14w700,
        labelColor: Colors.black,
        padding: const EdgeInsets.only(left: 10, right: 10, bottom: 8),
        labelPadding: EdgeInsets.zero,
        tabs: _buildTabs(viewModel),
      ),
    );
  }

  /// 탭 목록 생성
  List<Widget> _buildTabs(BottomNavigatorViewModel viewModel) {
    final navigationConfig = NavigationConfig.getDefault();
    
    return navigationConfig.tabs.map((tabItem) => 
      Obx(() => Tab(
        icon: _buildTabIcon(tabItem, viewModel.currentIndex.value == tabItem.index),
        text: tabItem.label,
      ))
    ).toList();
  }

  /// 탭 아이콘 생성
  Widget _buildTabIcon(NavigationTabItem tabItem, bool isSelected) {
    switch (tabItem.index) {
      case 0: // 모니터링
        return ColorFiltered(
          colorFilter: ColorFilter.mode(
            isSelected ? Colors.black : Colors.grey,
            BlendMode.srcIn,
          ),
          child: const Icon(FontAwesomeIcons.home, size: 24),
        );
      case 1: // 카메라
        return ColorFiltered(
          colorFilter: ColorFilter.mode(
            isSelected ? Colors.black : Colors.grey,
            BlendMode.srcIn,
          ),
          child: const Icon(FontAwesomeIcons.exclamationTriangle, size: 24),
        );
      case 2: // 알림
        return ColorFiltered(
          colorFilter: ColorFilter.mode(
            isSelected ? Colors.black : Colors.grey,
            BlendMode.srcIn,
          ),
          child: const Icon(FontAwesomeIcons.file, size: 24),
        );
      case 3: // 설정
        return SvgPicture.asset(
          'assets/icon/setting.svg',
          width: 24,
          height: 24,
          colorFilter: ColorFilter.mode(
            isSelected ? Colors.black : Colors.grey, 
            BlendMode.srcIn
          ),
        );
      default:
        return const Icon(Icons.help, size: 24, color: Colors.grey);
    }
  }

  /// 탭 바 뷰
  Widget _buildTabBarView(BottomNavigatorViewModel viewModel) {
    return TabBarView(
      physics: const NeverScrollableScrollPhysics(),
      controller: viewModel.bottomTabController,
      children: viewModel.widgetOptions,
    );
  }
}