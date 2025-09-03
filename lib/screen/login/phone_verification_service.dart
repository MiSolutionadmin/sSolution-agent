import 'dart:async';
import 'dart:convert';
import 'package:bootpay/bootpay.dart';
import 'package:bootpay/model/extra.dart';
import 'package:bootpay/model/payload.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../base_config/config.dart';
import 'phone_verification_model.dart';

class PhoneVerificationService {
  static final PhoneVerificationService _instance = PhoneVerificationService._internal();
  factory PhoneVerificationService() => _instance;
  PhoneVerificationService._internal();

  final AppConfig _config = AppConfig();

  /// 부트페이 휴대폰 인증 요청
  Future<PhoneVerificationResponse> requestPhoneVerification({
    required BuildContext context,
    required PhoneVerificationModel verificationData,
  }) async {
    try {
      final completer = Completer<PhoneVerificationResponse>();
      
      final payload = _createBootpayPayload();
      
      Bootpay().requestAuthentication(
        context: context,
        payload: payload,
        showCloseButton: true,
        onDone: (String json) async {
          print('부트페이 인증 완료: $json');
          try {
            final receiptId = jsonDecode(json)['data']['receipt_id'] as String;
            print('영수증 ID 추출 성공: $receiptId');
            final response = await _verifyBootpayReceipt(receiptId);
            print('영수증 검증 완료: ${response.toString()}');
            
            Bootpay().dismiss(context);
            if (!completer.isCompleted) {
              print('Completer에 성공 응답 완료');
              completer.complete(response);
            } else {
              print('Completer가 이미 완료됨 - 중복 호출 방지');
            }
          } catch (e) {
            print('onDone에서 오류 발생: $e');
            Bootpay().dismiss(context);
            if (!completer.isCompleted) {
              completer.complete(PhoneVerificationResponse.error('인증 처리 중 오류가 발생했습니다: $e'));
            }
          }
        },
        onCancel: (String json) {
          print('부트페이 인증 취소: $json');
          Bootpay().dismiss(context);
          if (!completer.isCompleted) {
            print('Completer에 취소 응답 완료');
            completer.complete(PhoneVerificationResponse.error('인증이 취소되었습니다.'));
          } else {
            print('Completer가 이미 완료됨 - onCancel 무시');
          }
        },
        onError: (String json) {
          print('Bootpay 오류: $json');
          Bootpay().dismiss(context);
          if (!completer.isCompleted) {
            print('Completer에 에러 응답 완료');
            completer.complete(PhoneVerificationResponse.error('인증 중 오류가 발생했습니다.'));
          } else {
            print('Completer가 이미 완료됨 - onError 무시');
          }
        },
      );
      
      return completer.future;
    } catch (e) {
      print('휴대폰 인증 요청 오류: $e');
      return PhoneVerificationResponse.error('인증 요청 중 오류가 발생했습니다.');
    }
  }

  /// 부트페이 Payload 생성
  Payload _createBootpayPayload() {
    final payload = Payload();
    payload.androidApplicationId = '6596075a00be04001bd30ae4';
    payload.iosApplicationId = '6596075a00be04001bd30ae5';
    payload.webApplicationId = '6596075a00be04001bd30ae3';
    
    payload.pg = 'danal';
    payload.method = 'auth';
    payload.orderName = '휴대폰인증';
    payload.authenticationId = DateTime.now().millisecondsSinceEpoch.toString();
    
    final extra = Extra();
    extra.appScheme = '에스솔루션';
    
    if (kIsWeb) {
      payload.extra?.openType = "iframe";
    }
    
    return payload;
  }

  /// 부트페이 영수증 검증
  Future<PhoneVerificationResponse> _verifyBootpayReceipt(String receiptId) async {
    try {
      final url = '${_config.baseUrl}/auth/$receiptId';
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode != 200) {
        return PhoneVerificationResponse.error('인증 검증에 실패했습니다.');
      }
      
      final data = jsonDecode(response.body);
      final authenticateData = data['authenticate_data'];
      
      if (authenticateData == null) {
        return PhoneVerificationResponse.error('인증 데이터를 찾을 수 없습니다.');
      }
      
      final verifiedName = authenticateData['name']?.toString() ?? '';
      final verifiedPhone = authenticateData['phone']?.toString() ?? '';
      
      if (verifiedName.isEmpty || verifiedPhone.isEmpty) {
        return PhoneVerificationResponse.error('인증된 정보가 올바르지 않습니다.');
      }
      
      return PhoneVerificationResponse.success(
        '휴대폰 인증이 완료되었습니다.',
        data: {
          'name': verifiedName,
          'phone': verifiedPhone,
        },
      );
    } catch (e) {
      print('부트페이 영수증 검증 오류: $e');
      return PhoneVerificationResponse.error('인증 검증 중 오류가 발생했습니다.');
    }
  }

  /// 사용자 정보와 인증된 정보 비교
  bool validateUserInfo({
    required PhoneVerificationModel userInfo,
    required String verifiedPhone,
  }) {
    final cleanUserPhone = userInfo.phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
    final cleanVerifiedPhone = verifiedPhone.replaceAll(RegExp(r'[^\d]'), '');
    
    print('전화번호 검증 - 유저폰: $cleanUserPhone, 인증폰: $cleanVerifiedPhone');
    final isValid = cleanUserPhone == cleanVerifiedPhone;
    print('전화번호 검증 결과: $isValid');
    
    return isValid;
  }

  /// 아이디 찾기 API 호출
  Future<String> findUserByPhone(String phoneNumber) async {
    try {
      final url = '${_config.baseUrl}/findid?phoneNumber=$phoneNumber';
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode != 200) {
        throw Exception('아이디 찾기에 실패했습니다.');
      }
      
      return response.body;
    } catch (e) {
      print('아이디 찾기 오류: $e');
      throw Exception('아이디 찾기 중 오류가 발생했습니다.');
    }
  }

  /// 휴대폰 번호 변경 API 호출
  Future<PhoneVerificationResponse> changePhoneNumber(String newPhoneNumber) async {
    try {
      final url = '${_config.baseUrl}/change-phone';
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'phoneNumber': newPhoneNumber,
        }),
      );
      
      if (response.statusCode == 200) {
        return PhoneVerificationResponse.success('휴대폰 번호가 성공적으로 변경되었습니다.');
      } else {
        return PhoneVerificationResponse.error('휴대폰 번호 변경에 실패했습니다.');
      }
    } catch (e) {
      print('휴대폰 번호 변경 오류: $e');
      return PhoneVerificationResponse.error('휴대폰 번호 변경 중 오류가 발생했습니다.');
    }
  }

  /// 최초 로그인 휴대폰 인증 검증
  Future<PhoneVerificationResponse> verifyFirstLogin({
    required PhoneVerificationModel userInfo,
    required String verifiedPhone,
  }) async {
    try {
      if (!validateUserInfo(userInfo: userInfo, verifiedPhone: verifiedPhone)) {
        return PhoneVerificationResponse.error('등록된 휴대폰 번호와 일치하지 않습니다.');
      }
      
      return PhoneVerificationResponse.success('인증이 완료되었습니다.');
    } catch (e) {
      print('최초 로그인 인증 검증 오류: $e');
      return PhoneVerificationResponse.error('인증 검증 중 오류가 발생했습니다.');
    }
  }

  /// 아이디/비밀번호 찾기 휴대폰 인증 검증
  Future<PhoneVerificationResponse> verifyForAccountRecovery({
    required String inputPhone,
    required String verifiedPhone,
    required bool isIdRecovery,
  }) async {
    try {
      if (!validateUserInfo(
        userInfo: PhoneVerificationModel(
          name: '',
          agency: '',
          group: '0',
          phoneNumber: inputPhone,
          password: '',
          verificationType: isIdRecovery ? 'id' : 'pw',
        ),
        verifiedPhone: verifiedPhone,
      )) {
        return PhoneVerificationResponse.error('입력한 휴대폰 번호와 인증된 번호가 일치하지 않습니다.');
      }
      
      final foundUsers = await findUserByPhone(verifiedPhone);
      
      if (foundUsers == '[]') {
        return PhoneVerificationResponse.error('등록된 계정이 없습니다.');
      }
      
      return PhoneVerificationResponse.success(
        isIdRecovery ? '아이디를 찾았습니다.' : '비밀번호 재설정이 가능합니다.',
        data: {'users': foundUsers},
      );
    } catch (e) {
      print('계정 찾기 인증 검증 오류: $e');
      return PhoneVerificationResponse.error('계정 찾기 중 오류가 발생했습니다.');
    }
  }
}