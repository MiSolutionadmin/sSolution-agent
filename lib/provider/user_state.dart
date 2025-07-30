import 'dart:convert';
import 'dart:io';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import '../db/camera_table.dart';
import '../base_config/config.dart';
import 'package:http/http.dart' as http;

class UserState extends GetxController{
  final config = AppConfig();
  /// ✅ 유저데이터 (단일)
  final userList = [].obs;

  final userData = {}.obs; // 유저 데이터 (단일)

  /// ✅ mms 관련
  final userMonitoring = [].obs; // 모니터링 페이지에서 보고잇는 mms
  final alimUserMonitoring = [].obs; // 알림(fcm)발생했을때 사용할 mms Data

  /// ✅ 모니터링 페이지 관련
  List tileList = ['저수조 수위','집수정','정화조 수위','상수도유입밸브','소방수신기 상태','변압기 상태','계량기'];
  final userMmsList = [].obs; /// 유저 mmsList
  final userMmsTileList = [].obs; /// 유저 mmsTileList (설정한 mms요소 )

  /// ✅ 소켓데이터 관련
  final userSocketData = <int>[].obs;

  /// ✅ 관리자 설정 페이지
  final userSettingData = [].obs;  // 관리자 설정 페이지 - 주관리자 + 일반 userData

  /// ✅ 전역폰트 관련
  final userFont = 1.obs;

  /// ✅ 아이피관련
  final usipAddress = ''.obs;

  /// ✅ 카메라 상태 (Connet) 관련
  final cameraState = ''.obs;
  final cameraStateL = [].obs; // 카메라 init 됐는지?
  final cameraStateCheck = ''.obs;

  /// ✅ fcm세팅 관련
  final userFirst = true.obs; /// 알림 셋팅 한번만 해줄려고 하는 코드

  /// ✅ 릴리즈노트 관련
  final releaseNote = [].obs; // releaseNote ex) 2025.02.18 - fix anything

  /// ✅ 부트페이 관련
  final bootName = ''.obs;
  final bootPhone = ''.obs;

  /// ✅ bottonNavigation 관련
  final bottomIndex = 0.obs;
  final selectBottomIndex = 0.obs;

  /// ✅ 버전 관련
  final versionList = [].obs; /// 버전 담는 곳

  /// ✅ 개인정보 변경 관련
  final userInfoList = [].obs; /// 변경할 userData
  final pwChangeValue = false.obs; /// 비밀번호 변경

/// 데이터 저장 함수
  Future<void> saveDataForMms(String mms,int index) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      print("data ?? : ${userMmsTileList[index]}");
      final file = File('${directory.path}/$mms.json');
      if (await file.exists()) {
        await file.delete();
      }

      String jsonString = jsonEncode(userMmsTileList[index]);
      print('??? ${jsonString}');
      await file.writeAsString(jsonString);
      print('$mms 데이터 저장 완료: ${file.path}');
    } catch (e) {
      print('데이터 저장 실패: $e');
    }
  }

  /// 로컬에 담긴 전체 데이터 읽기 함수
  Future<void> loadDataForMms() async {
    print('?? ${userMmsList}');
    List<List<Map<String, dynamic>>> tempList = [];
    for (int i = 0; i < userMmsList.length; i++) {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/${userMmsList[i]['mms']}.json');

      if (await file.exists()) {
        String jsonString = await file.readAsString();
        List<dynamic> jsonData = jsonDecode(jsonString);
        tempList.add(jsonData.map((item) => Map<String, dynamic>.from(item)).toList());
      } else {
        tempList.add(
          List<Map<String, dynamic>>.generate(
            tileList.length,
                (index) => {
              'title': tileList[index],
              'checked': true,
              'index': index,
              'value': 0,
            },
          ),
        );
      }
    }
    userMmsTileList.assignAll(tempList);
    userMmsList.refresh();
  }

  /// 데이터 삭제
  Future<void> loadDeleteMms(String mms) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$mms.json');
      if (await file.exists()) {
       file.delete();
      }
    } catch (e) {
      print('데이터 읽기 실패: $e');
    }
  }

  /// 상수도 유입 밸브 알림 추가 함수
  Future<void> alimAdd(String mms,String title,String bodys,String cameraUid,String ipCamId,String num,String fieldCheck,String mmsName)async{
    try{
      final url = '${config.baseUrl}/notiAdd';
      final body = ({
        'mms':'${mms}',
        "title": "${title}",
        "body": "${bodys}",
        "headDocId": "${userList[0]['headDocId']}",
        "cameraUid": "${cameraUid}",
        "ipcamId": "${ipCamId}",
        "num": '${num}',
        "fieldCheck": '${userList[0]['name']}',
        "mmsName": '${mmsName}',
      });
      final response = await http.post(Uri.parse(url), body: body);
    }catch(e){
      print('ee ? ${e}');
    }

  }

  /// 4c를 L로 바꿈(16진수를 문자열로)
  String hexToChar(String hex) {
    if (hex.length == 6) {
      String remainText = hex.substring(2);
      String sliceHex = String.fromCharCode(int.parse(hex.substring(0, 2), radix: 16));
      hex = sliceHex + remainText;
    }
    return hex;
  }

  /// ✅ 릴리즈노트 리스트 받아오기
  Future<void> getReleaseNoteList()async{
    releaseNote.clear();

    try{
      final url = '${config.baseUrl}/getReleaseNoteList';
      /// get data
      final response = await http.get(Uri.parse(url));
      print("response ${response.body}");

      List<dynamic> termList = jsonDecode(response.body);

      releaseNote.addAll(termList);

      return;
    } catch(e){
      print('getReleaseNoteList error ? ${e}');
      return;
    }
  }

  /// ✅ releaseNote 확인시 => 확인처리 함수
  Future<void> trueCheckReleaseNote()async{
    final String email = userList[0]['email'];
    final body = jsonEncode({'email': email}); // JSON 형식으로 변환

    try{
      final url = '${config.baseUrl}/changeReleaseNoteStatus';
      /// get data
      final response = await http.post(
          Uri.parse(url),
          headers: {"Content-Type": "application/json"}, // JSON 요청 헤더 추가
          body : body
      );
      print("response ${response.statusCode}");
      return;
    } catch(e){
      print('getReleaseNoteList error ? ${e}');
      return;
    }
  }

}