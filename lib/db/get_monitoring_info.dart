import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../base_config/config.dart';
import '../provider/user_state.dart';

final config = AppConfig();
/// 모니터링 정보 가져오기
Future<void> MonitoringInfo() async{
  final us = Get.put(UserState());
  final url = '${config.baseUrl}/monitoInfo?id=${us.userList[0]['mms']}';
  final response = await http.get(Uri.parse(url));
  Map<String, dynamic> dataList = json.decode(response.body);
  if(response.body !='{}'){
    us.userMonitoring.value = [dataList];
  }
  if (response.statusCode != 200) {
    print('에러에러');
    throw Exception('Failed to send email');
  }
}

/// 페이지 모니터링 정보 가져오기
Future<void> pageMonitoringInfo(String mms) async{
  final us = Get.put(UserState());
  final url = '${config.baseUrl}/monitoInfo?id=${mms}';
  final response = await http.get(Uri.parse(url));
  Map<String, dynamic> dataList = json.decode(response.body);
  if(response.body !='{}'){
    us.userMonitoring.value = [dataList];
    //print("모니터링 ${[dataList]}");
  }
  if (response.statusCode != 200) {
    print('에러에러');
    throw Exception('Failed to send email');
  }
}

/// 알람 모니터링 정보 가져오기
Future<void> alimMonitoringInfo(String mms) async{
  final us = Get.put(UserState());
  final url = '${config.baseUrl}/monitoInfo?id=${mms}';
  final response = await http.get(Uri.parse(url));
  Map<String, dynamic> dataList = json.decode(response.body);
  if(response.body !='{}'){
    us.alimUserMonitoring.value = [dataList];
  }
  if (response.statusCode != 200) {
    print('에러에러');
    throw Exception('Failed to send email');
  }
}

/// 소켓 스위치 함수 flutter -> server -> db -> mms
Future<void> changeSwitch(bool stw,String field,String mms) async {
  final us = Get.put(UserState());

  /// 소방수신기 알림
  List<int> dataToSend =[];
  String switchValue = '';
  String packType = ''; /// 패킷타입
  switch (field) {
    case '급수관':
      packType = '0x97';
      if(stw){
        switchValue = '0x01';
      }
      else{
        switchValue = '0x00';
      }
      break;
    case '알림방송':
      packType = '0x95';
      if(stw){
        switchValue = '0x01';
      }
      else{
        switchValue = '0x00';
      }
      break;
    case '주경종':
      packType = '0x91';
      if(stw){
        switchValue = '0x01';
      }
      else{
        switchValue = '0x00';
      }
      break;
    case '지구경종':
      packType = '0x92';
      if(stw){
        switchValue = '0x01';
      }
      else{
        switchValue = '0x00';
      }
      break;
    case '부저':
      packType = '0x93';
      if(stw){
        switchValue = '0x01';
      }
      else{
        switchValue = '0x00';
      }
      break;
    case '사이렌':
      packType = '0x94';
      if(stw){
        switchValue = '0x01';
      }
      else{
        switchValue = '0x00';
      }
      break;
  }
  // String mms = '${us.userList[0]['mms']}';
  dataToSend = [
    0xc0, // Start
    0x06, // Len
    int.parse('${packType}'), // Packet Type
    int.parse('0x${mms.substring(0, 2)}'),int.parse('0x${mms.substring(2, 4)}'),int.parse('0x${mms.substring(4, 6)}'),int.parse('${switchValue}'), //Payload
    0x34 // XOR
  ];
  us.userSocketData.value = dataToSend;
  us.update();
}

/// 소켓 스위치 함수 flutter -> server -> db -> mms 전체 스위치 키고/복구
Future<void> allSwitch(String field) async {
  final us = Get.put(UserState());

  /// 소방수신기 알림
  List<int> dataToSend =[];
  String switchValue = '';
  String packType = ''; /// 패킷타입
  switch (field) {
    case '일괄끄기':
      packType = '0x99';
      if(us.userMonitoring[0]['data'] == 'false'){
        int binaryValue = int.parse('00011111', radix: 2); // 이진수를 정수로 변환
        String hex = binaryValue.toRadixString(16).toUpperCase(); // 16진수로 변환, 대문자로 변환
        switchValue = '0x${hex}';
      }else {
        int binaryValue = int.parse('10011111', radix: 2); // 이진수를 정수로 변환
        String hex = binaryValue.toRadixString(16).toUpperCase(); // 16진수로 변환, 대문자로 변환
        switchValue = '0x${hex}';
      }
      break;
    case '일괄복구':
      packType = '0x98';
      if(us.userMonitoring[0]['data'] == 'false'){
        int binaryValue = int.parse('00011111', radix: 2); // 이진수를 정수로 변환
        String hex = binaryValue.toRadixString(16).toUpperCase(); // 16진수로 변환, 대문자로 변환
        switchValue = '0x${hex}';
      }else {
        int binaryValue = int.parse('10011111', radix: 2); // 이진수를 정수로 변환
        String hex = binaryValue.toRadixString(16).toUpperCase(); // 16진수로 변환, 대문자로 변환
        switchValue = '0x${hex}';
      }
      break;
    }
  String mms = '${us.userList[0]['mms']}';
  dataToSend = [
    0xc0, // Start
    0x06, // Len
    int.parse('${packType}'), // Packet Type
    int.parse('0x${mms.substring(0, 2)}'),int.parse('0x${mms.substring(2, 4)}'),int.parse('0x${mms.substring(4, 6)}'),int.parse('${switchValue}'), //Payload
    0x34 // XOR
  ];
  us.userSocketData.value = dataToSend;
  us.update();
}

/// mms 타이머 초기화
Future<void> alimTimerClear(String mms,String field,String timeField) async {
  final us = Get.put(UserState());
  final url = '${config.baseUrl}/mmsTimerClear';
  final body = {
    'mms': mms,
    'field': field,
    'timeField':timeField
  };
  final response = await http.post(Uri.parse(url), body: body);
}
/// 알림스위치
Future<void> alimChangeSwitch(bool stw,String field,String mms) async {
  final us = Get.put(UserState());

  /// 소방수신기 알림
  List<int> dataToSend =[];
  String switchValue = '';
  String packType = ''; /// 패킷타입
  switch (field) {
    case '급수관':
      packType = '0x97';
      if(stw){
        switchValue = '0x01';
      }
      else{
        switchValue = '0x00';
      }
      break;
    case '알림방송':
      packType = '0x95';
      if(stw){
        switchValue = '0x01';
      }
      else{
        switchValue = '0x00';
      }
      break;
    case '주경종':
      packType = '0x91';
      if(stw){
        switchValue = '0x01';
      }
      else{
        switchValue = '0x00';
      }
      break;
    case '지구경종':
      packType = '0x92';
      if(stw){
        switchValue = '0x01';
      }
      else{
        switchValue = '0x00';
      }
      break;
    case '부저':
      packType = '0x93';
      if(stw){
        switchValue = '0x01';
      }
      else{
        switchValue = '0x00';
      }
      break;
    case '사이렌':
      packType = '0x94';
      if(stw){
        switchValue = '0x01';
      }
      else{
        switchValue = '0x00';
      }
      break;
  }

  dataToSend = [
    0xc0, // Start
    0x06, // Len
    int.parse('${packType}'), // Packet Type
    int.parse('0x${mms.substring(0, 2)}'),int.parse('0x${mms.substring(2, 4)}'),int.parse('0x${mms.substring(4, 6)}'),int.parse('${switchValue}'), //Payload
    0x34 // XOR
  ];
  us.userSocketData.value = dataToSend;
  us.update();
}

/// mms 목록 가져오기
Future<void> getMmsList() async {
  List<String> emails = ['test-1@test.com', 'test-2@test.com', 'test-3@test.com', 'test-4@test.com'];
  final us = Get.put(UserState());
  String? url;
  if(emails.contains(us.userList[0]['email'])){
    url = '${config.baseUrl}/getTestIndexmms?email=${us.userList[0]['email']}';
  }else{
    url = '${config.baseUrl}/getIndexmms?headDocId=${us.userList[0]['headDocId']}&userDocId=${us.userList[0]['docId']}';
  }

  final response = await http.get(Uri.parse(url));
  final List<dynamic> data = jsonDecode(response.body);
  us.userMmsList.value = data;
  // us.userMmsList.value = us.userMmsList.map((item) {
  //   if(item['mms']==us.userList[0]['mms']){
  //     item['checked'] = true;
  //   }else{
  //     item['checked'] = false;
  //   }
  //   return item;
  // }).toList();
  us.userMmsList.value = us.userMmsList.map((item) {
    item['checked'] = false;
    return item;
  }).toList();
  if (response.statusCode != 200) {
    print('에러에러');
    throw Exception('Failed to send email');
  }
}

/// 유저에 있는 mms 업데이트
Future<void> userMmsUpdate(String mms) async{
  final us = Get.put(UserState());
  final url = '${config.baseUrl}/updatemms?mms=${mms}&email=${us.userList[0]['email']}';
  final response = await http.get(Uri.parse(url));
  if (response.statusCode != 200) {
    print('에러에러');
    throw Exception('Failed to send email');
  }
}

/// 유저에 mmsList 설정값 변경
Future<void> userMmsListUpdate(List mmsList) async{
  final us = Get.put(UserState());
  final response = await http.post(
      Uri.parse('${config.baseUrl}/getMmsIndexUpdate'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'mmsList': mmsList,
        'userDocId':'${us.userList[0]['docId']}',
      }));
  if (response.statusCode != 200) {
    print('에러에러');
    throw Exception('Failed to send email');
  }
}