import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';

import '../../components/dialog.dart';
import '../../provider/user_state.dart';
import '../navigation/bottom_navigator_view.dart';
import 'login_view.dart';
import 'password_reset_view.dart';
import 'phone_verification_model.dart';
import 'phone_verification_service.dart';

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

    // 이미 인증 중이면 중복 실행 방지
    if (isVerifying.value) {
      print('이미 인증이 진행 중입니다.');
      return;
    }

    isVerifying.value = true;

    try {
      print('Bootpay 인증 요청 시작');
      final response = await _verificationService.requestPhoneVerification(
        context: context,
        verificationData: userInfo.value!,
      );

      print('Bootpay 인증 응답 받음: ${response.toString()}');

      if (response.success) {
        print('Bootpay 인증 성공 - 데이터 설정 중');
        verifiedName.value = response.data?['name'] ?? '';
        verifiedPhone.value = response.data?['phone'] ?? '';
        
        print('verifiedName: ${verifiedName.value}');
        print('verifiedPhone: ${verifiedPhone.value}');
        
        print('_handleVerificationSuccess 호출 시작');
        await _handleVerificationSuccess(context);
        print('_handleVerificationSuccess 완료');
        // 성공 후에만 로딩 해제
        isVerifying.value = false;
        print('isVerifying을 false로 설정 완료');
      } else {
        print('Bootpay 인증 실패: ${response.message}');
        // 실패 시 로딩 해제
        isVerifying.value = false;
        // 취소나 에러 메시지 표시
        if (response.message != '인증이 취소되었습니다.') {
          _showErrorDialog(context, response.message);
        } else {
          print('인증 취소됨 - 에러 다이얼로그 표시 안함');
        }
      }
    } catch (e) {
      print('휴대폰 인증 오류: $e');
      isVerifying.value = false;
      _showErrorDialog(context, '인증 중 오류가 발생했습니다.');
    }
  }

  /// 인증 성공 처리
  Future<void> _handleVerificationSuccess(BuildContext context) async {
    if (userInfo.value == null) {
      print('휴대폰 인증 성공 처리 - userInfo가 null입니다.');
      return;
    }

    print('휴대폰 인증 성공 처리 시작');
    print('verifiedPhone: ${verifiedPhone.value}');
    print('userInfo: ${userInfo.value?.toString()}');

    try {
      print('verifyFirstLogin 호출 시작');
      final verificationResult = await _verificationService.verifyFirstLogin(
        userInfo: userInfo.value!,
        verifiedPhone: verifiedPhone.value,
      );

      print('verifyFirstLogin 결과: ${verificationResult.toString()}');

      if (verificationResult.success) {
        print('인증 성공 - 비밀번호 변경 화면으로 이동');
        print('_navigateToPasswordReset 호출 시작');
        // 인증 성공 시 비밀번호 초기화 화면으로 이동
        _navigateToPasswordReset();
        print('_navigateToPasswordReset 완료');
      } else {
        print('인증 실패: ${verificationResult.message}');
        _showErrorDialog(context, verificationResult.message);
      }
    } catch (e) {
      print('인증 검증 오류: $e');
      _showErrorDialog(context, '인증 검증 중 오류가 발생했습니다.');
    }
  }

  /// 비밀번호 초기화 화면으로 이동
  void _navigateToPasswordReset() {
    print('PasswordResetView로 네비게이션 시작');
    try {
      Get.to(() => const PasswordResetView());
      print('PasswordResetView로 네비게이션 완료');
    } catch (e) {
      print('네비게이션 오류: $e');
    }
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
    // 인증 중이면 로딩 상태 해제
    if (isVerifying.value) {
      isVerifying.value = false;
      print('인증 취소 - 로딩 상태 해제');
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