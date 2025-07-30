import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:get_ip_address/get_ip_address.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../../provider/user_state.dart';
import '../../base_config/config.dart';

final storage = FlutterSecureStorage( /// ✅ 스토리지
  aOptions: AndroidOptions(encryptedSharedPreferences: true),
);

final config = AppConfig(); /// ✅ api주소

/// ✅ 이메일 유효성 검사
bool isEmailValid(String email) {
  final pattern = r'^[\w-]+(\.[\w-]+)*@([a-zA-Z0-9-]+\.)+[a-zA-Z]{2,7}$';
  final regExp = RegExp(pattern);
  return regExp.hasMatch(email);
}

/// ✅ IP 가져오기
Future<String?> getPublicIP() async {
  final us = Get.put(UserState());
  try {
    var ipAddress = IpAddress(type: RequestType.json);
    dynamic data = await ipAddress.getIpAddress();
    us.usipAddress.value = data['ip'];
    print('현재 ip : ${us.usipAddress.value}');
  } on IpAddressException catch (exception) {
    print('IP 가져오기 실패: ${exception.message}');
  }
}

/// ✅ 로그인 로그 추가
Future<void> logAdd(String id) async {
  final us = Get.put(UserState());
  final url =
      '${config.apiUrl}/logAdd?id=${id}&ip=${us.usipAddress.value}&createDate=${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())}';
  final response = await http.get(Uri.parse(url));
  if (response.statusCode != 200) {
    throw Exception('Failed to send log');
  }
}

/// ✅ 회원정보 가져오기
// Future<bool> getUserInfo(String id, String pw) async {
//   final us = Get.put(UserState());
//   final token = await FirebaseMessaging.instance.getToken();
//
//   /// 25-05-19 get방식에서 비밀번호에 #포함시 오류발생 => post로 변경
//   final body = {
//     'id' : id,
//     'pw' : pw,
//     'token' : token
//   };
//
//
//   final response = await http.post(
//       Uri.parse('${config.apiUrl}/agent/login'),
//       body: body
//   );
//
//   if (response.statusCode != 200) {
//     throw Exception('Failed to login');
//   }
//   List<dynamic> dataList = json.decode(response.body);
//   us.userList.value = dataList;
//   return dataList.isNotEmpty;
// }
