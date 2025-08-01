import 'dart:convert';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../base_config/config.dart';
import '../components/dialog.dart';
import '../provider/user_state.dart';
import '../screen/login/login_view.dart';
import '../utils/font/font.dart';


final config = AppConfig();
/// 선택된 관리자 삭제시키는 버튼
Future<void> deleteUser(String email) async{
  final url = '${config.baseUrl}/deleteSetting?id=${email}';
  final response = await http.get(Uri.parse(url));
  if (response.statusCode != 200) {
    print('에러에러');
    throw Exception('Failed to send email');
  }
}


/// 회원정보 가져오기
Future<Map<String, dynamic>> getUser(String id, String pw) async {

  String? token = await FirebaseMessaging.instance.getToken();

  /// 25-05-19 get방식에서 비밀번호에 #포함시 오류발생 => post로 변경
  final body = {
    'username' : id,
    'password' : pw,
    'token' : token
  };

  try {
    print("로그인 시도중...${body}");
    final response = await http.post(
        Uri.parse('${config.baseUrl}/auth/agent'),
        body: body
    );

    if( response.statusCode != 200) {
      print('로그인 실패: ${response.body}');
      throw Exception('로그인 실패');
    }

    print("로그인 성공! ${response.body}");
    final data = json.decode(response.body);
    return data;
  } catch (e) {
    throw Exception(e);
  }
}

Future<void> getUserWithOutToken(String id) async {
  final us = Get.put(UserState());
  final url = '${config.baseUrl}/loginWithoutToken?id=${id}';
  final response = await http.get(Uri.parse(url));

  List<dynamic> dataList = json.decode(response.body);
  print('????Daa ${dataList}');
  us.userList.value = dataList;

  if (response.statusCode != 200) {
    print('에러에러');
    throw Exception('Failed to send email');
  }
}
/// 로그아웃했을 시 토큰 업데이트
Future<void> tokenDelete(context) async {
  final url = '${config.baseUrl}/agent/${us.userData["id"]}/token';
  try {
    final response = await http.delete(Uri.parse(url));
    if (response.statusCode != 200) {
      throw Exception('로그아웃 실패');
    }

  } catch (e) {
    showOnlyConfirmDialog(context, "서버 오류로 로그아웃에 실패했습니다.\n잠시 후 다시 시도해주세요.");
  }
}
/// 토큰 업데이트
Future<void> userTokenUpdate(String token) async {
  final us = Get.put(UserState());
  final url = '${config.baseUrl}/insertToken?docId=${us.userList[0]['docId']}&token=${token}';
  final response = await http.get(Uri.parse(url));
  if (response.statusCode != 200) {
    print('에러에러');
    throw Exception('Failed to send email');
  }
}

/// 핸드폰 번호 변경
Future<void> changePhoneNumber(String phone) async {
  final us = Get.put(UserState());

  final url = '${config.baseUrl}/agents/${us.userData['id']}/phone';
  final response = await http.patch(
    Uri.parse(url),
    headers: {
      'Content-Type': 'application/json', // JSON으로 전송
    },
    body: jsonEncode({
      "phone": phone,
    }),
  );

  if (response.statusCode != 200) {
    throw Exception('Failed: ${response.statusCode}');
  }
}

/// 버전 정보 가져오기
Future<List> getVersion() async {
  final us = Get.put(UserState());
  final url = '${config.baseUrl}/getVersion';
  final response = await http.get(Uri.parse(url));
  List<dynamic> dataList = json.decode(response.body);
  return dataList;
  print('res?? ${response.body}');
  if (response.statusCode != 200) {
    throw Exception('Failed');
  }
}

/// 버전 정보 가져오기
Future<void> updateVersion(String field) async {
  final us = Get.put(UserState());
  final url = '${config.baseUrl}/updateVersion';
  final body = ({
    'field':'${field}',
    'docId': '${us.userList[0]['docId']}'
  });
  final response = await http.post(Uri.parse(url),body: body);
  if (response.statusCode != 200) {
    throw Exception('Failed');
  }
}

/// 2024-08-28 중복로그인 체크 함수
Future<void> checkDuplicateLogin(BuildContext context) async {

  final us = Get.put(UserState());
  final url = '${config.baseUrl}/checkDuplicateLogin';
  final body = ({
    'token':'${us.userList[0]['token'] ?? "1234"}'
  });
  final response = await http.post(Uri.parse(url),body: body);
  if(json.decode(response.body)==false){
    showOnlyDuplicateTapDialog(context, '다른 기기에서 로그인을 감지했습니다.', ()async{
      // await tokenDelete();
      await storage.delete(key: 'pws');
      us.userList.clear();
      Get.offAll(()=>LoginView());
    });
  }
  if (response.statusCode != 200) {
    throw Exception('Failed');
  }
}