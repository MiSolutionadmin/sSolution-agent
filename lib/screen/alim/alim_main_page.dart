import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:mms/components/dialogManager.dart';
import 'package:mms/notification/firebase_cloud_messaging.dart';
import 'package:mms/screen/video/video_page.dart';
import '../../base_config/config.dart';
import '../../routes/app_routes.dart';
import '../../components/dialog.dart';
import '../../db/camera_table.dart';
import '../../db/user_table.dart';
import '../../notification/alert/alert_collecting_well.dart';
import '../../notification/alert/alert_fire_receiver.dart';
import '../../notification/alert/alert_septic_tank.dart';
import '../../notification/alert/alert_transformer.dart';
import '../../notification/alert/alert_water_tank.dart';
import '../../provider/notification_state.dart';
import '../../provider/user_state.dart';
import '../../utils/font/font.dart';
import '../../vstarcam/main/main_logic.dart';
import 'package:http/http.dart' as http;
import '../../utils/loading.dart';
import 'package:async/async.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../login/login_name_screen.dart';

class AlimScreen extends StatefulWidget {
  const AlimScreen({Key? key}) : super(key: key);

  @override
  State<AlimScreen> createState() => _AlimScreenState();
}

class _AlimScreenState extends State<AlimScreen> {
  /// Secret Storage (JWT)
  final secureStorage = FlutterSecureStorage();

  /// ✅ GetX
  final ns = Get.put(NotificationState());
  final us = Get.put(UserState());
  final config = AppConfig();

  /// ✅ 알림리스트 데이터
  List<Map<String, dynamic>> alimData = [];

  /// ✅ 페이지 로딩 관련
  var isLoading = false.obs;

  /// ✅ 무한스크롤 관련
  ScrollController scrollController = ScrollController();
  bool _isNextLoading = false; // 무한스크롤 로딩
  int currentPage = 0; // 페이지 인덱스
  String restorationResult = '';

  /// ✅ 알림복구 관련
  bool alimCheck = false; // 알림복구 가능? 상태
  List<dynamic> filteredData = []; // 알림복구시 필요한 filteredData

  /// ✅ 테스트계정 email
  List<String> emails = ['test-1@test.com', 'test-2@test.com', 'test-3@test.com', 'test-4@test.com'];

  /// 4c를 L로 바꿈(16진수를 문자열로)
  String hexToChar(String hex) {
    if (hex.length == 6) {
      String remainText = hex.substring(2);
      String sliceHex = String.fromCharCode(int.parse(hex.substring(0, 2), radix: 16)); // ex) L
      hex = sliceHex + remainText;
    }
    return hex;
  }

  /// 데이터 가져오기
  Future<void> fetchData() async {
    isLoading.value = true;
    try{
      Map<String, dynamic> data = await getAllNotificationData();

      ns.notificationList.value = List<Map<String, dynamic>>.from(data["notifications"]);
      print("akakak ${ns.notificationList}");

    } catch (e) {
      print('알림 데이터 가져오기 실패: $e');
    } finally {
      isLoading.value = false;
      setState(() {});
    }
  }

  /// 스크롤 데이터
  // Future<void> scrollData() async {
  //   try {
  //     final response = await getNotificationData();
  //
  //     if (response.statusCode == 200) {
  //       List<Map<String, dynamic>> a = List<Map<String, dynamic>>.from(json.decode(response.body));
  //       alimData.addAll(a);
  //       if (a.length != 0) {
  //         currentPage++;
  //       }
  //       setState(() {});
  //     } else {
  //       print('서버 응답 실패: ${response.reasonPhrase}');
  //     }
  //   } catch (e) {
  //     print('에러 발생: $e');
  //   }
  // }

  /// 알림내역 가져오기 25-05-13 중복코드 함수화
  // Future<http.Response> getNotificationData() async {
  //
  //   final response = emails.contains(us.userList[0]['email'])
  //       ? await http.post(Uri.parse('${config.apiUrl}/sendTestData'),
  //       headers: {
  //         'Content-Type': 'application/json', // JSON 형식임을 명시
  //       },
  //       body: json.encode({
  //         'page': currentPage,
  //         // 'mms': us.userList[0]['mms'],
  //         // 'uidList': uidList,
  //         'email': us.userList[0]['email'], /// 25-05-13 test계정 파라미터 수정
  //       }))
  //       : await http.get(Uri.parse('${config.apiUrl}/senddata?page=${currentPage}&headDocId=${us.userList[0]['headDocId']}'));
  //
  //   return response;
  // }


  /// 1분 이내의 알림내역 모두 가져오기
  Future<Map<String, dynamic>> getAllNotificationData() async {
    try {
      final token = await secureStorage.read(key: "jwt_token");

      final response = await http.get(
        Uri.parse('${config.apiUrl}/notis'),
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

  /// ✅ 무한스크롤 리스너
  // void _scrollListener() async {
  //   /// 현재 스크롤 위치가 최대 스크롤 위치에 도달하면
  //   if (scrollController.position.pixels == scrollController.position.maxScrollExtent) {
  //     setState(() {
  //       _isNextLoading = true;
  //     });
  //
  //     /// 다음 페이지 데이터 가져오기
  //     await scrollData();
  //     setState(() {
  //       _isNextLoading = false;
  //     });
  //   }
  // }

  /// ✅ cameraDetail 가져오기
  Future<void> getCameraDetail(String cameraUid) async {
    final url = '${config.apiUrl}/getCameraDetail?cameraUid=$cameraUid';
    final response = await http.get(Uri.parse(url));
    List<dynamic> data = jsonDecode(response.body);
    cs.cameraDetailList.value = data;

    if (cs.cameraDetailList[0]['fireDetect'] == 'false') {
      cs.fireSwitch.value = false;
    }
    if (response.statusCode != 200) {
      print('에러에러');
      throw Exception('Failed to send email');
    }
  }

  /// 일괄복구
  Future<void> restoration() async {
    final us = Get.put(UserState());
    try {
      final jsonData = jsonEncode(filteredData);
      bool testcheck = emails.contains(us.userList[0]['email']);
      final response = await http.get(Uri.parse('${config.apiUrl}/allFalse?headDocId=${us.userList[0]['headDocId']}&testCheck=${testcheck}&testMms=${us.userList[0]['mms']}&filterList=${jsonData}'));
      if (response.statusCode == 200) {
        restorationResult = response.body;
      } else {
        restorationResult = '';
      }
    } catch (e) {
      restorationResult = 'error';
      print('알림 복구 에러 $e');
    }
  }

  // /// 알림 보낸게 있는지 없는지 체크
  // Future<void> checkAlim() async {
  //   final us = Get.put(UserState());
  //   try {
  //     bool testcheck = emails.contains(us.userList[0]['email']);
  //     final url = '${config.apiUrl}/getcamera2?email=${us.userList[0]['headDocId']}&mms=${us.userList[0]['mms']}&testcheck=${testcheck}&testEmail=${us.userList[0]['email']}';
  //     /// 카메라 정보 가져오기
  //     final response3 = await http.get(Uri.parse(url));
  //     final List<dynamic> datas = jsonDecode(response3.body);
  //     final response = await http
  //         .get(Uri.parse('${config.apiUrl}/checkAlim?headDocId=${us.userList[0]['headDocId']}&mms=${us.userList[0]['mms']}&testcheck=$testcheck'));
  //     final List<dynamic> data = jsonDecode(response.body);
  //
  //     // 카메라 데이터 필터링
  //     filteredData = (datas.isNotEmpty)
  //         ? datas.where((item) {
  //       return item['cameraNotiCheck'] == 'true' ||
  //           item['cameraSmokeCheck'] == 'true' ||
  //           item['cameraMotionCheck'] == 'true';
  //     }).toList()
  //         : [];
  //     print('?? ${filteredData}');
  //     // mms 데이터 필드 체크
  //     const keyCheck = [
  //       'waterLowCheck',
  //       'waterHighCheck',
  //       'jibCheck',
  //       'fireReceiveCheck',
  //       'tempCheck',
  //       'cleanCheck'
  //     ];
  //
  //     print('알림 데이터: $data');
  //
  //     // 알림 체크 결과
  //     alimCheck = (filteredData.isNotEmpty) ||
  //         (data.isNotEmpty &&
  //             data.any((item) => keyCheck.any((key) => item[key] == 'true')));
  //     print('알림 체크 결과: $alimCheck');
  //   } catch (e) {
  //     print('알림 복구 확인 에러 $e');
  //   }
  // }

  /// 카메라 들어가는 부분
  Future<void> cameraInit(int index) async {
    final mainLogic = Get.find<MainLogic>();

    cs.getFireFightingData(ns.notificationList[index]['cameraUid']); // 25-05-09 알림페이지 진입시 소화장치 데이터 새로 불러오게

    cs.cancelableOperation.value = CancelableOperation.fromFuture(
      mainLogic.init('${ns.notificationList[index]['cameraUid']}', 'admin', '${cs.cameraPassword}'),
      onCancel: () {
        DialogManager.hideLoading();
      },
    );
    try {
      await cs.cancelableOperation.value?.value;
      mainLogic.disconnectStatus('${ns.notificationList[index]['cameraUid']}', 'admin', '${cs.cameraPassword}');
      if (us.cameraState.value == '2') {
        DialogManager.hideLoading();
        showOnlyConfirmDialog(context, '현재 연결할 수 없습니다');
        return;
      } else if (us.cameraState.value == '1') {


        /// 메모리카드 초기화
        cs.timeFirst.value = false;
        cs.hourList.clear();
        cs.highlightedHours.clear();
        cs.timeLineValue.value = '';
        cs.hourCount.clear();
        cs.previousHour.value = 0;
        cs.nextFirst.value = true;
        cs.cameraTfDate.value = '${DateFormat('y-MM-dd').format(DateTime.now())}';
        await getCameraDetail(ns.notificationList[index]['cameraUid']);
        cs.cameraName.value = ns.notificationList[index]['ipcamId'];
        cs.cameraUID.value = ns.notificationList[index]['cameraUid'];
        print("put ${cs.cameraName.value}");
      }
    } catch (e) {
      print("CancelableOperation 중 오류 발생: $e");
    }

    DialogManager.hideLoading();
    ns.fireStationSend.value = false;
    await Get.toNamed(AppRoutes.play)?.then((value) async {
      if (ns.cameraNotiCanCel.value != '') {
        ns.notificationList[index]['result'] = ns.cameraNotiCanCel.value;
        ns.notificationList[index]['fieldCheck'] = ns.cameraNotiCheckEmail.value;
        ns.cameraNotiCanCel.value = '';
        ns.cameraNotiCheckEmail.value = '';
      }
      setState(() {});
    });
  }


  void logOut() {
    showConfirmTapDialog(context, '로그아웃 하시겠습니까?', () async{
      DialogManager.showLoading(context);
        await tokenDelete(context);
        await storage.delete(key: 'pws');
        us.userData.clear();
      DialogManager.hideLoading();
        Get.offAll(()=>LoginName());
    });
  }


  @override
  void initState() {
    super.initState();

   fetchData();

    FCM().setNotifications();
  }


  /// ✅ 알림내역 카드 눌렀을때
  void pressedAlimData(int index) async {

      ns.notificationData.value = ns.notificationList[index];

      print("무슨타입? ${ns.notificationData['type']}");
      /// 모니터링
      /// type 추가시 여기도 추가해야함
      switch (ns.notificationData['type']) {
        case '1':
          ns.lowHighType.value = alimData[index]['body'] == '저수조 고수위 경보' ? 0 : 1;
          Get.to(() => AlertWaterTank(mms: alimData[index]['mms'],mmsNotiList: [alimData[index]],));
          break;
        case '2':
          Get.to(() => AlertCollectingWell(mms: alimData[index]['mms'],mmsNotiList: [alimData[index]]));
          break;
        case '3':
          ns.notiFireList.clear();
          ns.notiFireList.add(alimData[index]);
          ns.notiDocId.value = alimData[index]['docId'];
          Get.to(() => AlertFireReceiver(
              mms: alimData[index]['mms'],
              mmsNotiList: [alimData[index]]
          ));
          break;
        case '4':
          Get.to(() => AlertTransFormer(mms: alimData[index]['mms'],mmsNotiList: [alimData[index]]));
          break;
        case '5':
          Get.to(() => AlertSepticTank(mms: alimData[index]['mms'],mmsNotiList: [alimData[index]]));
          break;
        case '6':
          if (!Get.isRegistered<MainLogic>()) {
            Get.put(MainLogic());
          }
          //ns.alertTurnOffList.value = ['불꽃 감지 오류', '소방서 신고', '불꽃 원인 해결', '테스트 및 시험', '기타 (직접입력)'];
          ns.alertTurnOffList.value = ['불꽃 감지 오류', '기타 (직접입력)'];
          DialogManager.showLoginLoading(context);
          //showLoadingDialog2(context);
          await cameraInit(index);
          break;
        case '7':
          if (!Get.isRegistered<MainLogic>()) {
            Get.put(MainLogic());
          }
          ns.alertTurnOffList.value = ['연기 감지 오류', '기타 (직접입력)'];
          //ns.alertTurnOffList.value = ['연기 감지 오류', '소방서 신고', '연기 원인 해결', '테스트 및 시험', '기타 (직접입력)'];
          DialogManager.showLoginLoading(context);
          await cameraInit(index);
          break;
        case '8':
          if (!Get.isRegistered<MainLogic>()) {
            Get.put(MainLogic());
          }
          ns.alertTurnOffList.value = ['센서 감지 오류', '기타 (직접입력)'];
          DialogManager.showLoginLoading(context);
          await cameraInit(index);
          break;
    }
  }

  @override
  void dispose() {
    //scrollController.removeListener(_scrollListener);
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        centerTitle: false,
        title: Padding(
          padding: const EdgeInsets.only(left: 20),
          child: GestureDetector(
            onTap: () {
              fetchData();
            },
            child: Text(
              '알림 내역',
              style: f18w700Size(),
            ),
          ),
        ),
        actions: [
          GestureDetector(
            onTap: () {
              // 로그아웃 로직
              logOut();
            },
            child: Padding(
              padding: const EdgeInsets.only(right: 20),
              child: Text(
                '로그아웃',
                style: redf18w700(), // 또는 원하는 스타일
              ),
            ),
          ),
        ],
      ),
      body: Obx(() {
        return isLoading.value
            ? LoadingScreen()
            : ListView.builder( // ✅ 알림 내역 리스트
          shrinkWrap: true,
          controller: scrollController,
          physics: const ClampingScrollPhysics(),
          itemCount: ns.notificationList.length,
          itemBuilder: (_, index) {
            return GestureDetector(
              onTap: () async {
                // pressedAlimData(index); // ✅ 알림내역 카드 눌렀을때
                /// agent 비디오 다시보기로 이동
                Future<void> openAgentVideoPage(String docId, String type) async{
                  // 확인 버튼을 누를시 다이얼로그를 닫음
                  Get.back();

                  final videoUrl = await getVideoUrl(docId);

                  Get.to(() => VideoPage(videoUrl: videoUrl, type: type));
                }

                final docId = ns.notificationList[index]['docId'];
                final type = ns.notificationList[index]['type'] == "6" ? "불꽃 감지" : "연기 감지";

                if (type == "6") {
                  ns.alertTurnOffList.value = ['불꽃 감지 오류', '기타 (직접입력)'];
                } else {
                  ns.alertTurnOffList.value = ['연기 감지 오류', '기타 (직접입력)'];
                }

                openAgentVideoPage(docId,type);
              },
              child: Column(
                children: [
                  alimCard(index), // ✅ 알림내역 카드
                ],
              ),
            );
          },
        );
      }),
    );
  }

  /// ✅ 알림내역 카드
  Widget alimCard(int index) {
    return Container(
      width: Get.width,
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xffF1F4F7)))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          /// ✅ 알림 발생 일시
          Text(
            '${DateFormat('yyyy년 MM월 dd일 HH:mm').format(DateTime.parse(ns.notificationList[index]['createDate']))}',
            style: f15w600Grey(),
          ),
          /// ✅ 알림title
          Text(
            ns.notificationList[index]['title'],
            style: f15w600Blue(),
          ),
          /// ✅ 알림body
          Text(
            ns.notificationList[index]['body'],
            style: f16w700Size(), // 25-05-15 폰트 18 => 16 수정
          ),
          /// ✅ 기기 별칭 / UID
          // Text(
          //       () {
          //     // type 추가시 여기도 추가해야함 25-05-13 *
          //     switch (alimData[index]['type']) {
          //       case '1':
          //       case '2':
          //       case '3':
          //       case '4':
          //       case '5':
          //         return '단말기 이름 : ${alimData[index]['mmsName'] ?? hexToChar('${alimData[index]['mms']}')}\n단말기 UID : ${hexToChar('${alimData[index]['mms']}')}';
          //       case '6':
          //       case '7':
          //       case '8':
          //         return '카메라 이름 : ${alimData[index]['ipcamId']}\n카메라 UID : ${alimData[index]['cameraUid']}';
          //       case '9':
          //         return '카메라 이름 : ${alimData[index]['ipcamId']}\n카메라 UID : ${alimData[index]['cameraUid']}';
          //       case '10':
          //         return '단말기 이름 : ${alimData[index]['mmsName'] ?? hexToChar('${alimData[index]['mms']}')}\n단말기 UID : ${hexToChar('${alimData[index]['mms']}')}';
          //       case '11':
          //         return '단말기 이름 : ${alimData[index]['mmsName'] ?? hexToChar('${alimData[index]['mms']}')}\n단말기 UID : ${hexToChar('${alimData[index]['mms']}')}';
          //       case '12':
          //         return '카메라 이름 : ${alimData[index]['ipcamId']}\n카메라 UID : ${alimData[index]['cameraUid']}';
          //       default:
          //         return '알 수 없는 경보';
          //     }
          //   }(),
          //   style: f14w500Size(),
          // ),
          /// ✅ 알림 해제한 사람 / 사유
          // alimData[index]['type']=='11'?const SizedBox():Text(
          //       () {
          //     // type 추가시 여기도 추가해야함 25-05-13 *
          //     switch (alimData[index]['type']) {
          //       case '1':
          //       case '2':
          //       case '3':
          //       case '4':
          //       case '5':
          //       case '6':
          //       case '7':
          //       case '8':
          //         return '알림해제 : ${alimData[index]['fieldCheck'] ?? '없음'} / ${alimData[index]['result'] ?? '미등록'}';
          //       case '9':
          //         return '신고자 : ${alimData[index]['fieldCheck'] ?? '없음'}';
          //       case '10':
          //         return '작업자 : ${alimData[index]['fieldCheck'] ?? '없음'}';
          //       case '12':
          //         return '작업자 : ${alimData[index]['fieldCheck'] ?? '없음'}';
          //       default:
          //         return '알 수 없는 경보';
          //     }
          //   }(),
          //   style: f14w500Size(),
          // ),
        ],
      ),
    );
  }
}
