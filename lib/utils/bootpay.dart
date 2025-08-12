import 'dart:async';
import 'dart:convert';
import 'package:bootpay/bootpay.dart';
import 'package:bootpay/model/extra.dart';
import 'package:bootpay/model/payload.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../base_config/config.dart';
import '../components/dialog.dart';
import '../db/user_table.dart';
import '../provider/user_state.dart';
import '../screen/login/find/find_id_result_screen.dart';
import '../screen/login/find/find_pw_change_screen.dart';
import '../screen/login/terms_screen.dart';
import '../screen/setting/private/private_change_screen.dart';

Future<void> goBootpayRequest(
    BuildContext context, String pw, String email, String path) async {
  final us = Get.put(UserState());
  final config = AppConfig();
  Payload payload = Payload();
  payload.androidApplicationId = '6596075a00be04001bd30ae4';
  payload.iosApplicationId = '6596075a00be04001bd30ae5';
  payload.webApplicationId = '6596075a00be04001bd30ae3';

  payload.pg = 'danal';
  payload.method = 'auth';
  payload.orderName = '휴대폰인증';
  payload.authenticationId = DateTime.now().millisecondsSinceEpoch.toString();

  Extra extra = Extra();
  extra.appScheme = '에스솔루션';

  if (kIsWeb) {
    payload.extra?.openType = "iframe";
  }

  Bootpay().requestAuthentication(
    context: context,
    payload: payload,
    showCloseButton: true,
    onClose: () {
      Bootpay().dismiss(context);
    },
    onDone: (String json) async {
      String receipt = jsonDecode(json)['data']['receipt_id'];
      String url = '${config.baseUrl}/auth/${receipt}';
      http.Response response = await http.get(Uri.parse(url));
      try {
        var data = response.body;
        us.bootName.value =
            jsonDecode(data)['authenticate_data']['name'].toString();
        us.bootPhone.value =
            jsonDecode(data)['authenticate_data']['phone'].toString();

        /// 아이디 찾기일떄
        switch (path) {
          case 'id':
            String responseBody = await findId(pw);
            if (pw != us.bootPhone.value) {
              showOnlyConfirmDialog(context, '정보가 일치하지 않습니다');
            } else if ((responseBody == '[]')) {
              showOnlyConfirmDialog(context, '등록된 아이디가 없습니다');
            } else {
              Get.to(() => FindIdResult(
                    responseBody: responseBody,
                  ));
            }
            break;
          case 'pw':
            String responseBody = await findPw(pw, email);
            if (pw != us.bootPhone.value) {
              showOnlyConfirmDialog(context, '정보가 일치하지 않습니다');
            } else if ((responseBody == '[]')) {
              showOnlyConfirmDialog(context, '등록된 아이디가 없습니다');
            } else {
              Get.to(() => FindPwChange(
                    responseBody: responseBody,
                  ));
            }
            break;

          /// 개인정보 변경 핸드폰 번호 변경
          case 'setting':
            await changePhoneNumber(us.bootPhone.value);
            us.userData.value = Map<String, dynamic>.from(us.userData.value);
            us.userData.value['phone_number'] = us.bootPhone.value;
            us.userData.refresh();
            showOnlyConfirmDialog(context, '휴대폰 번호가 변경되었습니다');
            break;
          case 'first':
            if (us.userList[0]['phoneNumber'] != us.bootPhone.value) {
              showOnlyConfirmDialog(context, '잘못된 휴대폰 정보입니다');
            } else {
              Get.to(() => Terms());
            }
        }
      } catch (e) {
        us.bootName.value = '';
        us.bootPhone.value = '';
      }
    },
    onCancel: (String json) {
      Get.back();
      // print('onCancel: $json');
    },
    onError: (String json) {
      // Get.back();
      print('onError: $json');
    },
  );
}

/// 아이디 찾기
Future<String> findId(String phoneNum) async {
  // Secure Storage 인스턴스 생성
  const storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );

  final params = {"phoneNumber": phoneNum, "status": "1"};

  final url =
      Uri.parse('${config.baseUrl}/agents').replace(queryParameters: params);
  final response = await http.get(url);

  if (response.statusCode != 200) {
    throw Exception('Failed');
  }

  print("response.body ${response.body}");

  // 아이디 찾기가 성공하면 임시 JWT 토큰 발급 요청
  try {
    final tokenUrl = Uri.parse('${config.baseUrl}/auth/phone'); // 임시 토큰 엔드포인트
    final tokenResponse = await http.post(
      tokenUrl,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'phoneNumber': phoneNum,
        '': 'find_id' // 용도 구분
      }),
    );

    if (tokenResponse.statusCode == 200) {
      final tokenData = jsonDecode(tokenResponse.body);
      if (tokenData['token'] != null) {
        await storage.write(key: 'temp_jwt_token', value: tokenData['token']);
        print("임시 JWT 토큰 저장 완료");
      }
    }
  } catch (e) {
    print("임시 토큰 발급 실패: $e");
  }

  return response.body;
}

/// 아이디 찾기
Future<String> findPw(String phoneNum, String email) async {
  // Secure Storage 인스턴스 생성
  const storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );

  final params = {"phoneNumber": phoneNum, "email": email, "status": "1"};

  final url =
      Uri.parse('${config.baseUrl}/agents').replace(queryParameters: params);
  final response = await http.get(url);

  if (response.statusCode != 200) {
    throw Exception('Failed');
  }

  print("response.body ${response.body}");

  // 아이디 찾기가 성공하면 임시 JWT 토큰 발급 요청
  try {
    final tokenUrl = Uri.parse('${config.baseUrl}/auth/phone'); // 임시 토큰 엔드포인트
    final tokenResponse = await http.post(
      tokenUrl,
      headers: {'Content-Type': 'application/json'},
    );

    if (tokenResponse.statusCode == 200) {
      final tokenData = jsonDecode(tokenResponse.body);
      if (tokenData['token'] != null) {
        await storage.write(key: 'temp_jwt_token', value: tokenData['token']);
        print("임시 JWT 토큰 저장 완료");
      }
    }
  } catch (e) {
    print("임시 토큰 발급 실패: $e");
  }

  return response.body;
}
