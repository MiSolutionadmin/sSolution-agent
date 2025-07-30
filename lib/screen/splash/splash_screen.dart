import 'dart:io';
import 'dart:typed_data';
import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:mms/utils/permission_handler/permission_handler.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:version/version.dart';

import '../../components/dialog.dart';
import '../../components/updateVersion.dart';
import '../../db/user_table.dart';
import '../../provider/term_state.dart';
import '../../provider/user_state.dart';
import '../alim/alim_main_page.dart';
import '../bottom_navigator.dart';
import '../login/login_name_screen.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({Key? key}) : super(key: key);

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  final us = Get.put(UserState());
  final ts = Get.put(TermState());

  String? fontSizes;
  bool isLoading = true; /// ✅ splash 화면 로딩

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin(); /// ✅ fcm 푸시알림 instance 생성
  AndroidNotificationChannel? androidNotificationChannel; /// ✅ android용 푸시알림 채널 객체

  static final storage = new FlutterSecureStorage( /// ✅ 로컬스토리지 객체
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );

  @override
  void initState() {
    fetchInitWithVersionUpdate(); /// ✅ init + 버전업데이트
    super.initState();
  }


  /// ✅ init + 버전 업데이트 함수
  void fetchInitWithVersionUpdate () async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();


    await requestPermissions(); /// ✅ 알림권한 여부설정


    await autoLogin(); /// ✅ 자동로그인






    //us.versionList.value = await getVersion(); /// ✅ 앱 버전 가져오기

    //String fullVersion = "${packageInfo.version}+${packageInfo.buildNumber}";
    /// 강제 업데이트
    // if(Version.parse(fullVersion)<Version.parse(us.versionList[0]['force_version'])&& us.versionList[0]['force']=='true'){
    //   await forceUpdateVersionDialog(context);
    // }

    /// 일반 업데이트
    // else if(us.userList.isNotEmpty&&us.userList[0]['appVersionCheck']!='false'){
    //   if (Platform.isIOS) {
    //     if (Version.parse(fullVersion) < Version.parse(us.versionList[0]['ios_app'])) {
    //       await updateVersionDialog(context);
    //     }
    //   } else if (Platform.isAndroid) {
    //     if (Version.parse(fullVersion) < Version.parse(us.versionList[0]['android_app'])) {
    //       await updateVersionDialog(context);
    //     }
    //   }
    // }
    setState(() {});
  }


  /// ✅ 알림 권한 여부 설정
  Future<void> requestPermissions() async{
    Int64List vibrationPattern = Int64List(3);

    vibrationPattern[0] = 0;      // 진동 시작 전 대기 시간 (0초)
    vibrationPattern[1] = 5000;
    vibrationPattern[2] = 0;

    /// 안드로이드 일때
    if (Platform.isAndroid){
      var channel = AndroidNotificationChannel(
        'sSolutionAlim2', 'sSolutionAlim2',
        description: 'this is sSolution channeld', // description
        importance: Importance.max,
        enableVibration: true,
        vibrationPattern: vibrationPattern,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('sounds'),
      );
      await FirebaseMessaging.instance.requestPermission(
        badge: true,
        alert: true,
        sound: true,
      );
      flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }

    /// Ios 일 때
    else {
      await FirebaseMessaging.instance.requestPermission(
        badge: true,
        alert: true,
        sound: true,
      );
      flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }



  /// ✅ 저장된아이디 불러오기 함수
  Future<void> autoLogin () async {
    String? username = (await storage.read(key: "ids"));
    String? password = (await storage.read(key: "pws"));

    try {

      final data = await getUser(username!, password!);

      if (data.isEmpty) {
        throw Exception('로그인 실패');
      }

      us.userData.value = data["user"];

      // Get.offAll(() => AlimScreen());
      Get.offAll(() => BottomNavigator());

    }catch(e){
      if (e.toString().contains('로그인 실패'))
      {
        showOnlyConfirmDialog(context, '아이디 또는 비밀번호가 틀립니다');
      } else {
        showOnlyConfirmDialog(context, "서버 오류로 로그인에 실패했습니다.\n잠시 후 다시 시도해주세요.");
      }
      Get.offAll(() => LoginName());
    }
  }

  @override
  Widget build(BuildContext context) {
    return isLoading
        ?
    Container(color: Colors.white) /// ✅ 로딩
        :
    AnimatedSplashScreen.withScreenFunction(
      splashIconSize: double.maxFinite,
      // pageTransitionType: PageTransitionType.rightToLeft,
      splash: Container(
        height: Get.height,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset('assets/icon/logo.png',width: Get.width*0.5,fit: BoxFit.contain,),
            ],
          ),
        ),
      ),
      screenFunction: () async {
        return us.userList.length == 1 ?
        BottomNavigator() : /// ✅ 메인화면
        LoginName(); /// ✅ 로그인화면
      },
    );
  }


}