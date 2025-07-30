import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';

import '../components/dialog.dart';
import '../notification/firebase_cloud_messaging.dart';
import '../notification/local_notification_setting.dart';
import '../provider/user_state.dart';
import '../provider/camera_state.dart';
import '../utils/font/font.dart';
import 'alim/alim_main_page.dart';
import 'camera/camera_main.dart';
import 'monitoring/monitoring_main_screen.dart';
import 'setting/setting_main_screen.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';


class BottomNavigator extends StatefulWidget {
  static final String id = '/bottom';

  const BottomNavigator({Key? key}) : super(key: key);

  @override
  State<BottomNavigator> createState() => _BottomNavigatorState();
}

class _BottomNavigatorState extends State<BottomNavigator> with TickerProviderStateMixin  {
  ///fcm
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  AndroidNotificationChannel? androidNotificationChannel;

  final storage = new FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );
  final us = Get.put(UserState());
  final cs = Get.put(CameraState());
  List<Widget> _widgetOptions = [];
  late TabController _bottomTabController;
  int _currentIndex = 0;
  String? fontSizes;
  bool _isLoading = true;
  DateTime? currentBackPressTime;

  @override
  void initState() {
    Future.delayed(Duration.zero, () async {

      if(us.userFirst.value){
        us.userFirst.value = false;
        LocalNotifyCation().initializeNotification();
        FCM().setNotifications();
      }

      fontSizes = (await storage.read(key: "fontSizes"));
      switch (fontSizes) {
        case '2':
          us.userFont.value = 2;
          break;
        case '1':
          us.userFont.value = 1;
          break;
        case '0':
          us.userFont.value = 0;
          break;
      }
      _isLoading = false;
      setState(() {});
    });

    super.initState();
    _widgetOptions = [MonitoringMainPage(), CameraMain(), AlimScreen(), SettingMain()];
    // _widgetOptions = [MonitoringTestPage(),CameraMain(), AlimScreen(),SettingMain()];
    _bottomTabController = TabController(length: 4, vsync: this);
    _bottomTabController.animateTo(us.bottomIndex.value);

    _currentIndex = us.bottomIndex.value;
    setState(() {});

    // checkRelease != true
    if (us.userList.isNotEmpty && us.userList[0]['checkRelease'] != 'true') {
      releaseNoteDialog(context);
    }
  }


  @override
  Widget build(BuildContext context) {

    return _isLoading
        ? Container()
        : PopScope(
            canPop: false,
            onPopInvoked: (bool pop)async{
              if(currentBackPressTime ==null || DateTime.now().difference(currentBackPressTime!) > Duration(seconds: 2)) {
                currentBackPressTime = DateTime.now();
                showCustomSnackbar(context, '"뒤로" 버튼을 한 번 더 누르시면 종료됩니다');
              }else{
                exit(0);
              }
            },
            // onWillPop: () async {
            //   if (currentBackPressTime == null || DateTime.now().difference(currentBackPressTime!) > Duration(seconds: 2)) {
            //     currentBackPressTime = DateTime.now();
            //     ScaffoldMessenger.of(context).showSnackBar(
            //       SnackBar(
            //         behavior: SnackBarBehavior.floating,
            //         // width: ,
            //         width: Get.width*0.8,
            //         // content: Text('"뒤로" 버튼을 한 번 더 누르시면 종료됩니다'),
            //         content: Row(
            //           mainAxisAlignment: MainAxisAlignment.center,
            //           // mainAxisAlignment: MainAxisAlignment.spaceBetween,
            //           children: [
            //             Container(
            //               decoration: BoxDecoration(
            //                 borderRadius: BorderRadius.circular(8),
            //                 color: Colors.white
            //               ),
            //                 padding: EdgeInsets.symmetric(horizontal: 2,vertical: 2),
            //                 child: Image.asset(
            //               'assets/icon/ssolution_logo.png',
            //               width: 24,
            //               height: 24,
            //             )),
            //             const SizedBox(width: 20,),
            //             Text('"뒤로" 버튼을 한 번 더 누르시면 종료됩니다'),
            //           ],
            //         ),
            //         shape: RoundedRectangleBorder(
            //           borderRadius: BorderRadius.circular(16.0),
            //         ),
            //         // margin: EdgeInsets.only(bottom: 20.0),
            //       ),
            //     );
            //     return false;
            //   }
            //   return true;
            // },
            child: Scaffold(
              backgroundColor: Colors.white,
              bottomNavigationBar: Container(
                decoration: BoxDecoration(
                    border: Border(
                  top: BorderSide(width: 2.0, color: Color(0xffF1F4F7)),
                )),
                padding: Platform.isAndroid ? const EdgeInsets.all(0) : const EdgeInsets.only(bottom: 10),
                child: TabBar(
                  onTap: (index) {
                    if(index!=1){
                      cs.cameraList.clear();
                    }
                    us.bottomIndex.value = 0;
                    setState(() {
                      _currentIndex = index;
                      us.selectBottomIndex.value = index;
                    });
                  },
                  dividerColor: Colors.transparent,
                  indicatorColor: Colors.transparent,
                  indicatorSize: TabBarIndicatorSize.label,
                  controller: _bottomTabController,
                  unselectedLabelStyle: hintf14w700,
                  labelStyle: f14w700,
                  labelColor: Colors.black,
                  padding: EdgeInsets.only(left: 10, right: 10, bottom: 8),
                  labelPadding: EdgeInsets.zero,
                  tabs: <Widget>[
                    Tab(
                      icon: ColorFiltered(
                        colorFilter: ColorFilter.mode(
                          _currentIndex == 0 ? Colors.black : Colors.grey,
                          BlendMode.srcIn,
                        ),
                        child: Icon(FontAwesomeIcons.home, size:24),
                      ),
                      text: '모니터링',
                    ),
                    Tab(
                      icon: ColorFiltered(
                        colorFilter: ColorFilter.mode(
                          _currentIndex == 1 ? Colors.black : Colors.grey,
                          BlendMode.srcIn,
                        ),
                        child: Icon(FontAwesomeIcons.exclamationTriangle, size:24),
                      ),
                      text: '카메라',
                    ),
                    Tab(
                      icon: ColorFiltered(
                        colorFilter: ColorFilter.mode(
                          _currentIndex == 2 ? Colors.black : Colors.grey,
                          BlendMode.srcIn,
                        ),
                        child: Icon(FontAwesomeIcons.file, size:24),
                      ),
                      text: '알림',
                    ),
                    Tab(
                      icon: SvgPicture.asset(
                        'assets/icon/setting.svg',
                        width: 24,
                        height: 24,
                        colorFilter:
                            _currentIndex == 3 ? ColorFilter.mode(Colors.black, BlendMode.srcIn) : ColorFilter.mode(Colors.grey, BlendMode.srcIn),
                      ),
                      text: '설정',
                    ),
                  ],
                ),
              ),
              body: TabBarView(
                physics: const NeverScrollableScrollPhysics(),
                children: _widgetOptions,
                controller: _bottomTabController,
              ),
            ),
          );
  }


  static OverlayEntry? _snackBarEntry;

  /// 커스텀 스낵바 표시
  /// 커스텀 스낵바 표시
  static void showCustomSnackbar(BuildContext context, String message) {
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
                  offset: Offset(0, 4),
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
                  padding: EdgeInsets.all(2),
                  child: Image.asset(
                    'assets/icon/ssolution_logo.png',
                    width: 24,
                    height: 24,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '"뒤로" 버튼을 한 번 더 누르시면 종료됩니다',
                  style: f12Whitew700,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_snackBarEntry!);

    // 일정 시간 뒤 자동 제거
    Future.delayed(Duration(seconds: 2), () {
      _snackBarEntry?.remove();
      _snackBarEntry = null;
    });
  }
}
