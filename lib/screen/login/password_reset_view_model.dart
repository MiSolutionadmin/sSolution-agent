import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../../base_config/config.dart';
import '../../components/dialog.dart';
import '../../provider/user_state.dart';
import '../navigation/bottom_navigator_view.dart';

class PasswordResetViewModel extends GetxController {
  // Dependencies
  final AppConfig _config = AppConfig();
  final UserState _userState = Get.find<UserState>();
  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );

  // Controllers
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  // Focus Nodes
  final FocusNode passwordFocusNode = FocusNode();
  final FocusNode confirmPasswordFocusNode = FocusNode();

  // Reactive Variables
  final RxBool isLoading = false.obs;
  final RxBool obscurePassword = true.obs;
  final RxBool obscureConfirmPassword = true.obs;
  final RxString passwordError = ''.obs;
  final RxString confirmPasswordError = ''.obs;
  final RxBool isFormValid = false.obs;
  final secureStorage = FlutterSecureStorage();

  // Page type (초기 비밀번호 설정 vs 설정에서 변경)
  final RxString pageType = 'initial'.obs; // 'initial' or 'setting'

  @override
  void onInit() {
    super.onInit();
    _setupValidation();
  }

  @override
  void onClose() {
    _disposeControllers();
    super.onClose();
  }

  /// 컨트롤러 및 포커스 노드 정리
  void _disposeControllers() {
    try {
      passwordController.dispose();
      confirmPasswordController.dispose();
      passwordFocusNode.dispose();
      confirmPasswordFocusNode.dispose();
    } catch (e) {
      print('PasswordResetViewModel dispose 오류: $e');
    }
  }

  /// 폼 유효성 검사 설정
  void _setupValidation() {
    // 패스워드 입력 리스너
    passwordController.addListener(() {
      _validatePassword();
      _validateConfirmPassword();
      _updateFormValidation();
    });

    // 패스워드 확인 입력 리스너
    confirmPasswordController.addListener(() {
      _validateConfirmPassword();
      _updateFormValidation();
    });
  }

  /// 비밀번호 유효성 검사
  void _validatePassword() {
    final password = passwordController.text.trim();

    if (password.isEmpty) {
      passwordError.value = '';
      return;
    }

    if (!isValidPassword(password)) {
      passwordError.value = '9자리 이상, 숫자/영문/특수문자 중 3가지 조합으로 입력해주세요';
    } else {
      passwordError.value = '';
    }
  }

  /// 비밀번호 확인 유효성 검사
  void _validateConfirmPassword() {
    final password = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    if (confirmPassword.isEmpty) {
      confirmPasswordError.value = '';
      return;
    }

    if (password != confirmPassword) {
      confirmPasswordError.value = '비밀번호가 일치하지 않습니다';
    } else {
      confirmPasswordError.value = '';
    }
  }

  /// 폼 전체 유효성 검사
  void _updateFormValidation() {
    final password = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    isFormValid.value = password.isNotEmpty &&
        confirmPassword.isNotEmpty &&
        passwordError.value.isEmpty &&
        confirmPasswordError.value.isEmpty;
  }

  /// 비밀번호 유효성 체크
  bool isValidPassword(String password) {
    if (password.length < 9) return false;

    bool hasUpperCase = false;
    bool hasLowerCase = false;
    bool hasDigits = false;
    bool hasSpecialCharacters = false;

    final specialCharacters = RegExp(r'[!@#$%^&*()]+');

    for (int i = 0; i < password.length; i++) {
      if (password[i].contains(RegExp(r'[A-Z]'))) {
        hasUpperCase = true;
      } else if (password[i].contains(RegExp(r'[a-z]'))) {
        hasLowerCase = true;
      } else if (password[i].contains(RegExp(r'[0-9]'))) {
        hasDigits = true;
      } else if (specialCharacters.hasMatch(password[i])) {
        hasSpecialCharacters = true;
      }
    }

    int criteriaMet = 0;
    if (hasUpperCase) criteriaMet++;
    if (hasLowerCase) criteriaMet++;
    if (hasDigits) criteriaMet++;
    if (hasSpecialCharacters) criteriaMet++;

    return criteriaMet >= 3;
  }

  /// 비밀번호 보기/숨기기 토글
  void togglePasswordVisibility() {
    obscurePassword.value = !obscurePassword.value;
  }

  /// 비밀번호 확인 보기/숨기기 토글
  void toggleConfirmPasswordVisibility() {
    obscureConfirmPassword.value = !obscureConfirmPassword.value;
  }

  /// 페이지 타입 설정
  void setPageType(String type) {
    pageType.value = type;
  }

  /// 비밀번호 변경 처리
  Future<void> changePassword(BuildContext context) async {
    if (!isFormValid.value) {
      _showErrorDialog(context, '입력된 정보를 확인해주세요');
      return;
    }

    isLoading.value = true;

    try {
      await _performPasswordChange(passwordController.text.trim());

      // 성공 메시지 표시 후 적절한 화면으로 이동
      if (pageType.value == 'setting') {
        _showSuccessDialog(context, '비밀번호가 변경되었습니다', () {
          Get.back(); // 설정 화면으로 돌아가기
        });
      } else {
        _showSuccessDialog(context, '비밀번호가 설정되었습니다', () {
          Get.offAll(() => const BottomNavigatorView());
        });
      }
    } catch (e) {
      print('비밀번호 변경 오류: $e');
      _showErrorDialog(context, '비밀번호 변경 중 오류가 발생했습니다');
    } finally {
      isLoading.value = false;
    }
  }

  /// 비밀번호 변경 API 호출
  Future<void> _performPasswordChange(String password) async {
    final body = {
      'id': _userState.userData['email'],
      'pw': password,
    };

    final token = await secureStorage.read(key: "jwt_token");

    final response = await http.patch(
      Uri.parse(
          '${_config.baseUrl}/agents/${_userState.userData['id']}/password'),
      body: body,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('서버 오류가 발생했습니다');
    }

    // 사용자 상태 업데이트
    _userState.userData['pw'] = password;
    await _storage.write(key: "pws", value: password);
  }

  /// 에러 다이얼로그 표시
  void _showErrorDialog(BuildContext context, String message) {
    showOnlyConfirmDialog(context, message);
  }

  /// 성공 다이얼로그 표시
  void _showSuccessDialog(
      BuildContext context, String message, VoidCallback onConfirm) {
    showOnlyConfirmTapDialogWillpop(context, message, onConfirm);
  }

  /// 뒤로가기 처리
  void handleBackPress() {
    Get.back();
  }

  /// 다음 포커스로 이동
  void moveToConfirmPasswordField() {
    FocusScope.of(Get.context!).requestFocus(confirmPasswordFocusNode);
  }

  /// 포커스 해제
  void unfocusAll() {
    FocusScope.of(Get.context!).unfocus();
  }
}
