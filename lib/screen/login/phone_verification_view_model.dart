import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';

import '../../components/dialog.dart';
import '../../provider/user_state.dart';
import '../navigation/bottom_navigator_view.dart';
import 'login_view.dart';
import 'phone_verification_model.dart';
import 'phone_verification_service.dart';
import 'terms_screen.dart';

class PhoneVerificationViewModel extends GetxController {
  // Dependencies
  final PhoneVerificationService _verificationService = PhoneVerificationService();
  final UserState _userState = Get.find<UserState>();
  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );

  // Reactive Variables
  final RxBool isLoading = false.obs;
  final RxBool isVerifying = false.obs;
  final Rx<PhoneVerificationModel?> userInfo = Rx<PhoneVerificationModel?>(null);
  final RxString verifiedName = ''.obs;
  final RxString verifiedPhone = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _initializeUserInfo();
    _initializeFont();
  }

  /// 사용자 정보 초기화
  void _initializeUserInfo() {
    try {
      if (_userState.userData.isNotEmpty) {
        final userData = Map<String, dynamic>.from(_userState.userData);
        userInfo.value = PhoneVerificationModel.fromUserData(userData, 'first');
        print('휴대폰 인증 - 사용자 정보 로드 성공: ${userData}');
      } else {
        print('휴대폰 인증 - 사용자 정보가 없습니다.');
      }
    } catch (e) {
      print('사용자 정보 초기화 오류: $e');
    }
  }

  /// 폰트 설정 초기화
  Future<void> _initializeFont() async {
    try {
      final fontSizes = await _storage.read(key: "fontSizes");
      switch (fontSizes) {
        case '2':
          _userState.userFont.value = 2;
          break;
        case '1':
          _userState.userFont.value = 1;
          break;
        default:
          _userState.userFont.value = 0;
          break;
      }
    } catch (e) {
      print('폰트 초기화 오류: $e');
    }
  }

  /// 휴대폰 인증 시작
  Future<void> startPhoneVerification(BuildContext context) async {
    if (userInfo.value == null) {
      _showErrorDialog(context, '사용자 정보를 불러올 수 없습니다.');
      return;
    }

    if (!userInfo.value!.isValid) {
      _showErrorDialog(context, '사용자 정보가 올바르지 않습니다.');
      return;
    }

    isVerifying.value = true;

    try {
      final response = await _verificationService.requestPhoneVerification(
        context: context,
        verificationData: userInfo.value!,
      );

      if (response.success) {
        verifiedName.value = response.data?['name'] ?? '';
        verifiedPhone.value = response.data?['phone'] ?? '';
        
        await _handleVerificationSuccess(context);
      } else {
        _showErrorDialog(context, response.message);
      }
    } catch (e) {
      print('휴대폰 인증 오류: $e');
      _showErrorDialog(context, '인증 중 오류가 발생했습니다.');
    } finally {
      isVerifying.value = false;
    }
  }

  /// 인증 성공 처리
  Future<void> _handleVerificationSuccess(BuildContext context) async {
    if (userInfo.value == null) return;

    try {
      final verificationResult = await _verificationService.verifyFirstLogin(
        userInfo: userInfo.value!,
        verifiedPhone: verifiedPhone.value,
      );

      if (verificationResult.success) {
        // 인증 성공 시 약관 동의 화면으로 이동
        _navigateToTerms();
      } else {
        _showErrorDialog(context, verificationResult.message);
      }
    } catch (e) {
      print('인증 검증 오류: $e');
      _showErrorDialog(context, '인증 검증 중 오류가 발생했습니다.');
    }
  }

  /// 약관 동의 화면으로 이동
  void _navigateToTerms() {
    Get.to(() => Terms());
  }

  /// 메인 화면으로 이동 (인증 완료 후)
  void navigateToMain() {
    Get.offAll(() => const BottomNavigatorView());
  }

  /// 에러 다이얼로그 표시
  void _showErrorDialog(BuildContext context, String message) {
    showOnlyConfirmDialog(context, message);
  }

  /// 사용자 정보 새로고침
  void refreshUserInfo() {
    _initializeUserInfo();
  }

  /// 현재 사용자 정보 가져오기
  PhoneVerificationModel? get currentUserInfo => userInfo.value;

  /// 인증 가능 여부 확인
  bool get canVerify => userInfo.value?.isValid ?? false;

  /// 뒤로가기 처리
  void handleBackPress() {
    if (isVerifying.value) {
      // 인증 중일 때는 뒤로가기 막기
      return;
    }
    
    // 현재 컨트롤러 삭제
    try {
      Get.delete<PhoneVerificationViewModel>(tag: 'phone_verification');
    } catch (e) {
      print('PhoneVerificationViewModel 삭제 오류: $e');
    }
    
    // 로그인 페이지로 이동
    Get.offAll(() => const LoginView());
  }

  /// 리소스 정리
  @override
  void onClose() {
    super.onClose();
  }
}