import 'package:cupertino_will_pop_scope/cupertino_will_pop_scope.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:mms/provider/camera_state.dart';
import 'package:mms/provider/user_state.dart';
import 'package:mms/screen/splash/splash_screen.dart';
import 'package:mms/services/camera_notification_service.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  /// ✅ Firebase 초기화

  // HttpOverrides.global = NoCheckCertificateHttpOverrides(); /// ✅ 앱 전역 SSL인증 무시
  await SystemChrome.setPreferredOrientations([
    /// ✅ 앱 화면 세로모드로 고정
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  Get.put(CameraState());

  // // Android WebView 설정
  // if (Platform.isAndroid) {
  //   WebView.platform = SurfaceAndroidWebView();
  // }
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    // AppLifecycle 관찰자 등록
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    // AppLifecycle 관찰자 제거
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // 백그라운드에서 포그라운드로 복귀했을 때
    if (state == AppLifecycleState.resumed) {
      print("📱 앱이 포그라운드로 복귀");
      _checkPendingNotificationOnResume();
    }
  }

  /// ⭐ 앱 복귀 시 대기중인 알림 목록 확인
  Future<void> _checkPendingNotificationOnResume() async {
    try {
      // UserState가 초기화되어 있는지 확인
      if (!Get.isRegistered<UserState>()) {
        print("⚠️ UserState가 초기화되지 않음");
        return;
      }

      final us = Get.find<UserState>();

      // 로그인 상태 확인 (userData에 id가 있는지 확인)
      if (us.userData['id'] == null) {
        print("⚠️ 로그인되지 않은 상태");
        return;
      }

      final cameraService = CameraNotificationService();
      final pendingNotifications = await cameraService.checkPendingNotifications();

      if (pendingNotifications.isNotEmpty) {
        print("🔔 앱 복귀 시 대기중인 알림 발견: ${pendingNotifications.length}개");
        await cameraService.handlePendingNotifications(pendingNotifications);
      } else {
        print("✅ 앱 복귀 시 대기중인 알림 없음");
      }
    } catch (e) {
      print("❌ 앱 복귀 시 대기중인 알림 확인 오류: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      navigatorKey: navigatorKey,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaleFactor: 1),
          child: child!,
        );
      },
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      debugShowCheckedModeBanner: false,
      title: 'mms',
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
            color: Colors.white, surfaceTintColor: Colors.white),
        useMaterial3: true,
        pageTransitionsTheme: PageTransitionsTheme(
          builders: {
            TargetPlatform.android: ZoomPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoWillPopScopePageTransionsBuilder(),
          },
        ),
      ),
      home: SplashPage(),
    );
  }
}
