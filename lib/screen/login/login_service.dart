import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get_ip_address/get_ip_address.dart';

import '../../base_config/config.dart';
import 'login_model.dart';

class LoginService {
  static final LoginService _instance = LoginService._internal();
  factory LoginService() => _instance;
  LoginService._internal();

  final AppConfig _config = AppConfig();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );

  /// 로그인 API 호출
  Future<LoginResponse> login(LoginModel loginData) async {
    try {
      // FCM 토큰 가져오기
      String? fcmToken = await FirebaseMessaging.instance.getToken();



      final url = Uri.parse('${_config.baseUrl}/auth/agent');
      
      final requestBody = {
        'username': loginData.id,
        'password': loginData.password,
        'token': fcmToken,
        'device_type': 'mobile',
      };


      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(requestBody),
      ).timeout(const Duration(seconds: 30));

      print("로그인 응답 상태코드: ${response.statusCode}");

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        print("로그인 응답 데이터: $responseData");
        print("토큰 존재 여부: ${responseData.containsKey('token')}");
        print("토큰 값: ${responseData['token']}");
        
        if (responseData['message'] == "로그인 성공") {
          return LoginResponse.fromJson(responseData);
        } else {
          return LoginResponse.error(
            responseData['message'] ?? '로그인에 실패했습니다.'
          );
        }
      } else if (response.statusCode == 401) {
        return LoginResponse.error('아이디 또는 비밀번호가 틀립니다.');
      } else {
        return LoginResponse.error('서버 오류가 발생했습니다.');
      }
    } catch (e) {
      print("로그인 오류: $e");
      if (e.toString().contains('TimeoutException')) {
        return LoginResponse.error('네트워크 연결 시간이 초과되었습니다.');
      } else {
        return LoginResponse.error('네트워크 오류가 발생했습니다.');
      }
    }
  }

  /// JWT 토큰 저장
  Future<void> saveToken(String token) async {
    await _secureStorage.write(key: "jwt_token", value: token);
  }

  /// JWT 토큰 가져오기
  Future<String?> getToken() async {
    return await _secureStorage.read(key: "jwt_token");
  }

  /// 토큰 삭제 (로그아웃)
  Future<void> deleteToken() async {
    await _secureStorage.delete(key: "jwt_token");
  }

  /// 자동 로그인 정보 저장
  Future<void> saveLoginInfo(String id, String password) async {
    await _secureStorage.write(key: "ids", value: id);
    await _secureStorage.write(key: "pws", value: password);
  }

  /// 자동 로그인 정보 가져오기
  Future<LoginModel?> getSavedLoginInfo() async {
    final id = await _secureStorage.read(key: "ids");
    final password = await _secureStorage.read(key: "pws");
    final isChecked = await _secureStorage.read(key: "isChecked");
    
    if (id != null && password != null && isChecked == 'true') {
      return LoginModel(
        id: id,
        password: password,
        saveId: true,
      );
    }
    
    return null;
  }

  /// 자동 로그인 정보 삭제
  Future<void> clearSavedLoginInfo() async {
    await _secureStorage.delete(key: "ids");
    await _secureStorage.delete(key: "pws");
    await _secureStorage.delete(key: "isChecked");
  }

  /// 토큰 유효성 검사
  Future<bool> validateToken() async {
    try {
      final token = await getToken();
      if (token == null) return false;

      final url = Uri.parse('${_config.baseUrl}/api/validate-token');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (e) {
      print("토큰 검증 오류: $e");
      return false;
    }
  }

  /// 로그아웃 API 호출
  Future<bool> logout() async {
    try {
      final token = await getToken();
      if (token == null) return true;

      final url = Uri.parse('${_config.baseUrl}/api/logout');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      await deleteToken();
      return response.statusCode == 200;
    } catch (e) {
      print("로그아웃 오류: $e");
      await deleteToken(); // 오류가 발생해도 로컬 토큰은 삭제
      return false;
    }
  }
}