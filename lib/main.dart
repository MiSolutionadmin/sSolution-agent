import 'dart:io';
import 'dart:typed_data';
import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:cupertino_will_pop_scope/cupertino_will_pop_scope.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:mms/notification/firebase_cloud_messaging.dart';
import 'package:mms/provider/camera_state.dart';
import 'package:mms/screen/splash/splash_screen.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:version/version.dart';
import 'base_config/certificate.dart';
import 'components/updateVersion.dart';
import 'db/user_table.dart';
import 'provider/user_state.dart';
import 'routes/app_routes.dart';
import 'screen/bottom_navigator.dart';
import 'screen/login/login_name_screen.dart';
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(); /// ✅ Firebase 초기화

  // HttpOverrides.global = NoCheckCertificateHttpOverrides(); /// ✅ 앱 전역 SSL인증 무시
  await SystemChrome.setPreferredOrientations([ /// ✅ 앱 화면 세로모드로 고정
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  Get.put(CameraState());

  // // Android WebView 설정
  // if (Platform.isAndroid) {
  //   WebView.platform = SurfaceAndroidWebView();
  // }
  runApp( const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
        appBarTheme: const AppBarTheme(color: Colors.white,surfaceTintColor: Colors.white),
        useMaterial3: true,
        pageTransitionsTheme: PageTransitionsTheme(
          builders: {
            TargetPlatform.android: ZoomPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoWillPopScopePageTransionsBuilder(),
          },
        ),
      ),
      home: SplashPage(),
      getPages: AppPages.pages,
    );
  }
}
