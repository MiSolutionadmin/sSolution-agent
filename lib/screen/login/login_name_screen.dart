import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:get_ip_address/get_ip_address.dart';
import 'package:intl/intl.dart';
import 'package:mms/components/dialogManager.dart';
import 'package:mms/db/user_table.dart';
import '../../base_config/config.dart';
import '../../function/login/login_name_screen_func.dart';
import '../../utils/font/font.dart';
import '../../widget/login/login_name_screen_widget.dart';
import '../alim/alim_main_page.dart';
import '../bottom_navigator.dart';
import '../../components/dialog.dart';
import '../../db/get_monitoring_info.dart';
import '../../provider/user_state.dart';
import '../../utils/loading.dart';
import 'admin_confirm_screen.dart';
import 'package:http/http.dart' as http;
import 'find/find_id_screen.dart';
import 'find/find_pw_screen.dart';
import 'pw_change_screen.dart';

class LoginName extends StatefulWidget {
  const LoginName({super.key});

  @override
  State<LoginName> createState() => _LoginNameState();
}

class _LoginNameState extends State<LoginName> {
  /// ✅ api주소
  final config = AppConfig();

  /// ✅ 전역상태 관련
  final us = Get.put(UserState());

  /// ✅ 로딩 관련
  bool isLoading = true;

  /// ✅ 로그인 관련
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  final FocusNode _loginButtonFocusNode = FocusNode();
  TextEditingController _idCon = TextEditingController();
  TextEditingController _pwCon = TextEditingController();
  bool isChecked = false;
  bool loginCheck = false;
  bool _obscurePassword = true;

  final storage = new FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );
  String? fontSizes;
  DateTime? currentBackPressTime;

  @override
  void initState() {
    super.initState();
    initializeLogin();
  }

  /// ✅ 로그인 진입시 초기세팅
  Future<void> initializeLogin() async {
    isLoading = false;
    String? userId = await storage.read(key: "ids");
    String? checkId = await storage.read(key: "isChecked");
    if (checkId == 'true') {
      _idCon.text = userId ?? '';
      isChecked = true;
    }
    fontSizes = await storage.read(key: "fontSizes");
    switch (fontSizes) {
      case '2':
        us.userFont.value = 2;
        break;
      case '1':
        us.userFont.value = 1;
        break;
      default:
        us.userFont.value = 0;
        break;
    }
    if (us.userList.isNotEmpty && us.userList[0]['first'] == 'false' && us.userList[0]['changePw'] == 'true') {
      showOnlyConfirmTapDialogWillpop(context, '비밀번호를 재 설정해주세요', () {
        Get.back();
        Get.to(() => PwChange());
      });
    }
    setState(() {});
  }

  /// ✅ 뒤로가기 막기
  Future<bool> handleWillPop() async {
    if (currentBackPressTime == null || DateTime.now().difference(currentBackPressTime!) > Duration(seconds: 2)) {
      currentBackPressTime = DateTime.now();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          width: Get.width * 0.8,
          content: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: Colors.white),
                  padding: EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                  child: Image.asset('assets/icon/ssolution_logo.png', width: 24, height: 24)),
              const SizedBox(width: 20),
              Text('"뒤로" 버튼을 한 번 더 누르시면 종료됩니다'),
            ],
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
        ),
      );
      return false;
    }
    return true;
  }

  /// ✅ 로그인 처리함수
  Future<void> loginAction(username, password) async {
    DialogManager.showLoginLoading(context);
    try {
      // 1. secureStorage 초기화
      final secureStorage = FlutterSecureStorage();

      final data = await getUser(username, password);

      if (data.isEmpty) {
        throw Exception('로그인 실패');
      }

      us.userData.value = data["user"];

      // 2. 유저정보 스토리지 담기(자동로그인용)
      await storage.write(key: "ids", value: _idCon.text);
      await storage.write(key: "pws", value: _pwCon.text);

      final token = data['token'];

      // 3. JWT 토큰 저장
      await secureStorage.write(key: "jwt_token", value: token);

      print("token success jwt");

      // Get.offAll(() => AlimScreen());

      Get.offAll(() => BottomNavigator());
    }catch(e){
      if (e.toString().contains('로그인 실패'))
      {
        showOnlyConfirmDialog(context, '아이디 또는 비밀번호가 틀립니다');
      } else {
        showOnlyConfirmDialog(context, "서버 오류로 로그인에 실패했습니다.\n잠시 후 다시 시도해주세요.");
      }
    }
    DialogManager.hideLoading();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: WillPopScope(
        onWillPop: handleWillPop,
        child: Scaffold(
          backgroundColor: Colors.white,
          body: isLoading ? LoadingScreen() : loginBody(),
        ),
      ),
    );
  }

  /// ✅ 로그인창
  Widget loginBody() {
    return SingleChildScrollView(
      physics: ClampingScrollPhysics(),
      child: Container(
        height: Get.height,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// ✅ 로고
            Image.asset('assets/icon/logo.png', width: Get.width * 0.5, fit: BoxFit.contain),
            const SizedBox(height: 60),
            
            /// ✅ 아이디 입력창
            Text('아이디', style: f16w700Size()),
            const SizedBox(height: 10),
            idInputField(_idCon, _emailFocusNode, _passwordFocusNode, (v) async {
              if (isChecked) await storage.write(key: "ids", value: _idCon.text);
            }),
            const SizedBox(height: 20),
            
            /// ✅ 비밀번호 입력창
            Text('비밀번호', style: f16w700Size()),
            const SizedBox(height: 10),
            pwInputField(_pwCon, _passwordFocusNode, _loginButtonFocusNode, _obscurePassword, () {
              setState(() {
                _obscurePassword = !_obscurePassword;
              });
            }),
            const SizedBox(height: 20),
            
            /// ✅ 아이디 저장
            saveIdCheckbox(isChecked, () async {
              isChecked = !isChecked;
              if (isChecked) {
                await storage.write(key: "isChecked", value: 'true');
              } else {
                await storage.delete(key: "isChecked");
              }
              setState(() {});
            }),
            const SizedBox(height: 30),
            
            /// ✅ 로그인 버튼
            Center(
              child: ElevatedButton(
                focusNode: _loginButtonFocusNode,
                style: ButtonStyle(
                  shape: WidgetStateProperty.all<RoundedRectangleBorder>(RoundedRectangleBorder(borderRadius: BorderRadius.circular(4))),
                  minimumSize: WidgetStateProperty.all(Size(double.infinity, 52)),
                  backgroundColor: WidgetStateProperty.all(Color(0xFF1955EE)),
                ),
                onPressed: (() =>
                    loginAction(_idCon.text, _pwCon.text)),
                child: Text('로그인', style: f16w700WhiteSize()),
              ),
            ),
            const SizedBox(height: 20),
            // loginBottomLinks(),
          ],
        ),
      ),
    );
  }

  /// ✅ 아이디찾기 / 비밀번호 찾기
  // Widget loginBottomLinks() {
  //   return Row(
  //     mainAxisAlignment: MainAxisAlignment.center,
  //     children: [
  //       /// ✅ 아이디 찾기
  //       GestureDetector(
  //         onTap: () => Get.to(() => FindId()),
  //         child: Text('아이디 찾기', style: hintf14w400Size()),
  //       ),
  //       SizedBox(width: 42),
  //       Text('|', style: hintf14w400Size()),
  //
  //       /// ✅ 비밀번호 찾기
  //       SizedBox(width: 42),
  //       GestureDetector(
  //         onTap: () => Get.to(() => FindPw()),
  //         child: Text('비밀번호 찾기', style: hintf14w400Size()),
  //       ),
  //     ],
  //   );
  // }
}
