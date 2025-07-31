import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:mms/components/dialogManager.dart';

import '../../base_config/config.dart';
import '../../components/dialog.dart';
import '../../provider/user_state.dart';
import '../navigation/bottom_navigator_view.dart';
import 'login_model.dart';
import 'login_service.dart';
import 'phone_verification_view.dart';

class LoginViewModel extends GetxController {
  // Controllers
  final TextEditingController idController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  
  // Focus Nodes
  final FocusNode emailFocusNode = FocusNode();
  final FocusNode passwordFocusNode = FocusNode();
  final FocusNode loginButtonFocusNode = FocusNode();
  
  // Reactive Variables
  final RxBool isLoading = true.obs;
  final RxBool isChecked = false.obs;
  final RxBool obscurePassword = true.obs;
  final RxBool loginCheck = false.obs;
  
  // Dependencies
  final config = AppConfig();
  final userState = Get.put(UserState());
  final loginService = LoginService();
  final storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );
  
  // Back press handling
  DateTime? currentBackPressTime;
  
  @override
  void onInit() {
    super.onInit();
    initializeLogin();
  }
  
  @override
  void onClose() {
    // Controller와 FocusNode가 아직 사용 중이 아닐 때만 dispose
    try {
      if (!idController.hasListeners) {
        idController.dispose();
      }
      if (!passwordController.hasListeners) {
        passwordController.dispose();
      }
      if (!emailFocusNode.hasListeners) {
        emailFocusNode.dispose();
      }
      if (!passwordFocusNode.hasListeners) {
        passwordFocusNode.dispose();
      }
      if (!loginButtonFocusNode.hasListeners) {
        loginButtonFocusNode.dispose();
      }
    } catch (e) {
      print('LoginViewModel dispose 오류: $e');
    }
    super.onClose();
  }
  
  /// 로그인 진입시 초기세팅
  Future<void> initializeLogin() async {
    isLoading.value = false;
    
    // 저장된 아이디 불러오기
    String? userId = await storage.read(key: "ids");
    String? checkId = await storage.read(key: "isChecked");
    
    if (checkId == 'true') {
      idController.text = userId ?? '';
      isChecked.value = true;
    }
    
    // 폰트 크기 설정
    String? fontSizes = await storage.read(key: "fontSizes");
    switch (fontSizes) {
      case '2':
        userState.userFont.value = 2;
        break;
      case '1':
        userState.userFont.value = 1;
        break;
      default:
        userState.userFont.value = 0;
        break;
    }
  }
  
  /// 뒤로가기 처리
  Future<bool> handleWillPop(BuildContext context) async {
    if (currentBackPressTime == null || 
        DateTime.now().difference(currentBackPressTime!) > const Duration(seconds: 2)) {
      currentBackPressTime = DateTime.now();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          width: Get.width * 0.8,
          content: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8), 
                  color: Colors.white
                ),
                padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                child: Image.asset(
                  'assets/icon/ssolution_logo.png', 
                  width: 24, 
                  height: 24
                )
              ),
              const SizedBox(width: 20),
              const Text('"뒤로" 버튼을 한 번 더 누르시면 종료됩니다'),
            ],
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0)
          ),
        ),
      );
      return false;
    }
    return true;
  }
  
  /// 비밀번호 보기/숨기기 토글
  void togglePasswordVisibility() {
    obscurePassword.value = !obscurePassword.value;
  }
  
  /// 아이디 저장 체크박스 토글
  Future<void> toggleSaveId() async {
    isChecked.value = !isChecked.value;
    
    if (isChecked.value) {
      await storage.write(key: "isChecked", value: 'true');
      if (idController.text.isNotEmpty) {
        await storage.write(key: "ids", value: idController.text);
      }
    } else {
      await storage.delete(key: "isChecked");
    }
  }
  
  /// 아이디 변경 시 저장
  Future<void> onIdChanged() async {
    if (isChecked.value) {
      await storage.write(key: "ids", value: idController.text);
    }
  }
  
  /// 로그인 처리
  Future<void> loginAction() async {
    if (idController.text.isEmpty || passwordController.text.isEmpty) {
      Get.snackbar('오류', '아이디와 비밀번호를 입력해주세요.');
      return;
    }
    
    // Context 확인
    if (Get.context == null) {
      Get.snackbar('오류', '화면을 찾을 수 없습니다.');
      return;
    }
    
    DialogManager.showLoginLoading(Get.context!);
    
    try {
      final loginData = LoginModel(
        id: idController.text,
        password: passwordController.text,
        saveId: isChecked.value,
      );
      
      final response = await loginService.login(loginData);
      
      print("로그인 응답: ${response.toString()}");
      
      if (!response.success) {
        throw Exception(response.message ?? '로그인 실패');
      }
      
      // 응답 데이터 검증
      if (response.user.isEmpty || response.token.isEmpty) {
        throw Exception('서버 응답 데이터가 올바르지 않습니다.');
      }
      
      userState.userData.value = response.user;
      
      // 유저정보 및 토큰 저장
      print("저장할 토큰: ${response.token}");
      await loginService.saveLoginInfo(idController.text, passwordController.text);
      await loginService.saveToken(response.token);
      
      // 토큰 저장 확인
      final savedToken = await loginService.getToken();
      print("저장된 토큰: $savedToken");
      
      // 로그인 성공 후 공통 처리
      _safeHideLoading();
      
      // 현재 컨트롤러 삭제
      try {
        Get.delete<LoginViewModel>(tag: 'login');
      } catch (e) {
        print('LoginViewModel 삭제 오류: $e');
      }
      
      await handleLoginSuccess(response.user);
      
    } catch (e) {
      print("로그인 오류: $e");
      _safeHideLoading();
      
      // 에러 메시지 표시
      if (Get.context != null) {
        if (e.toString().contains('아이디 또는 비밀번호가 틀립니다')) {
          showOnlyConfirmDialog(Get.context!, '아이디 또는 비밀번호가 틀립니다');
        } else {
          showOnlyConfirmDialog(Get.context!, e.toString().replaceAll('Exception: ', ''));
        }
      }
    }
  }
  
  /// 안전하게 로딩 숨기기
  void _safeHideLoading() {
    try {
      DialogManager.safeHideLoading();
    } catch (e) {
      print("로딩 숨기기 오류: $e");
      // 오류가 발생해도 계속 진행
    }
  }

  /// 로그인 성공 후 공통 처리 함수
  static Future<void> handleLoginSuccess(Map<String, dynamic> userData) async {
    final user = UserModel.fromJson(userData);
    print("유저 정보 first: ${user.first}");
    print("유저 정보 전체: ${user.toString()}");
    
    // 약간의 지연 후 네비게이션
    await Future.delayed(const Duration(milliseconds: 200));
    
    if (user.first == 1) {
      print("최초 로그인 사용자 - 휴대폰 인증 화면으로 이동");
      Get.offAll(() => const PhoneVerificationView());
    } else {
      print("기존 사용자 - 메인 화면으로 이동");
      Get.offAll(() => const BottomNavigatorView());
    }
  }
}