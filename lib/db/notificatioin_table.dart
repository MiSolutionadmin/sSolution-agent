import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../provider/user_state.dart';
import 'get_monitoring_info.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// 버전 정보 가져오기
Future<List> getAlimNotification(String docId) async {


  final us = Get.put(UserState());
  final url = '${config.baseUrl}/getNotificationData?docId=${docId}';
  final response = await http.get(Uri.parse(url));
  List<dynamic> dataList = json.decode(response.body);
  return dataList;
}

Future<Map<String, dynamic>> getAllNotificationData() async {
  /// Secret Storage (JWT)
  final secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );

  try {
    final token = await secureStorage.read(key: "jwt_token");

    print("token jwt ?? ${token}");

    final response = await http.get(
      Uri.parse('${config.baseUrl}/notis'),
      headers: {
        "Content-Type": "application/json",
        "authorization": "Bearer $token", // ✅ 토큰 포함 필수
      },
    );


    if( response.statusCode != 200) {
      print('리스트 불러오기 실패: ${response.body}');
      throw Exception('리스트 불러오기 실패');
    }

    print("리스트 불러오기 성공! ${response.body}");
    final data = json.decode(response.body);
    return data;
  } catch (e) {
    throw Exception(e);
  }
}