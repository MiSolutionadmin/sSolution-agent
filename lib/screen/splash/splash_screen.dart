import 'dart:io';
import 'dart:typed_data';
import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import '../../provider/term_state.dart';
import '../../provider/user_state.dart';
import '../../services/camera_notification_service.dart';
import '../navigation/bottom_navigator_view.dart';
import '../login/login_view.dart';
import '../login/login_service.dart';
import '../login/login_model.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({Key? key}) : super(key: key);

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  final us = Get.put(UserState());
  final ts = Get.put(TermState());

  String? fontSizes;
  bool isLoading = true;

  /// ✅ splash 화면 로딩

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  /// ✅ fcm 푸시알림 instance 생성
  AndroidNotificationChannel? androidNotificationChannel;

  /// ✅ android용 푸시알림 채널 객체

  static final storage = new FlutterSecureStorage(
    /// ✅ 로컬스토리지 객체
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );

  @override
  void initState() {
    fetchInitWithVersionUpdate();

    /// ✅ init + 버전업데이트
    super.initState();
  }

  /// ✅ init + 버전 업데이트 함수
  void fetchInitWithVersionUpdate() async {
    await requestPermissions();

    /// ✅ 알림권한 여부설정

    await autoLogin();

    /// ✅ 자동로그인

    setState(() {});
  }

  /// ✅ 알림 권한 여부 설정
  Future<void> requestPermissions() async {
    Int64List vibrationPattern = Int64List(3);

    vibrationPattern[0] = 0; // 진동 시작 전 대기 시간 (0초)
    vibrationPattern[1] = 5000;
    vibrationPattern[2] = 0;

    /// 안드로이드 일때
    if (Platform.isAndroid) {
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
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }

    /// Ios 일 때
    else {
      await FirebaseMessaging.instance.requestPermission(
        badge: true,
        alert: true,
        sound: true,
      );
      flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
    }
  }

  /// ✅ 저장된아이디 불러오기 함수
  Future<void> autoLogin() async {
    String? username = (await storage.read(key: "ids"));
    String? password = (await storage.read(key: "pws"));

    if (username != null && password != null) {
      try {
        print("🔄 자동로그인 시도 중... (ID: $username)");

        final loginService = LoginService();
        final loginData = LoginModel(
          id: username,
          password: password,
          saveId: true,
        );

        final response = await loginService.login(loginData);

        if (response.success && response.user.isNotEmpty) {
          print("✅ 자동로그인 성공");

          // 사용자 데이터 저장
          us.userData.value = response.user;

          // 토큰 저장
          if (response.token.isNotEmpty) {
            await loginService.saveToken(response.token);
          }

          // ⭐ 자동로그인 성공 시 대기중인 알림 확인
          await _checkAndHandlePendingNotification();
        } else {
          print("❌ 자동로그인 실패: ${response.message}");
          // 실패 시 저장된 비밀번호 삭제
          await storage.delete(key: "pws");
        }
      } catch (e) {
        print("❌ 자동로그인 오류: $e");
        // 오류 시 저장된 비밀번호 삭제
        await storage.delete(key: "pws");
      }
    }

    // ⭐ 핵심: 로딩 완료 후 isLoading을 false로 설정
    isLoading = false;
  }

  /// ⭐ 대기중인 알림 목록 확인 및 처리
  Future<void> _checkAndHandlePendingNotification() async {
    try {
      final cameraService = CameraNotificationService();
      final pendingNotifications = await cameraService.checkPendingNotifications();

      if (pendingNotifications.isNotEmpty) {
        print("🔔 자동로그인 시 대기중인 알림 발견: ${pendingNotifications.length}개");
        // 대기중인 알림들을 NotificationState에 추가하고 경보 페이지로 이동
        // 스플래쉬 화면이 표시된 후 이동하도록 처리
        Future.delayed(Duration(milliseconds: 100), () async {
          await cameraService.handlePendingNotifications(pendingNotifications);
        });
      } else {
        print("✅ 자동로그인 시 대기중인 알림 없음");
      }
    } catch (e) {
      print("❌ 대기중인 알림 확인 오류: $e");
      // 오류가 발생해도 계속 진행
    }
  }

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? Container(color: Colors.white)

        /// ✅ 로딩
        : AnimatedSplashScreen.withScreenFunction(
            splashIconSize: double.maxFinite,
            splash: Container(
              height: Get.height,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/icon/logo.png',
                      width: Get.width * 0.5,
                      fit: BoxFit.contain,
                    ),
                    const Text(
                      '에이전트',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            screenFunction: () async {
              return us.userData.isNotEmpty
                  ? BottomNavigatorView()
                  :

                  /// ✅ 메인화면
                  LoginView();

              /// ✅ 로그인화면
            },
          );
  }
}
