import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:http/http.dart' as http;
import 'package:vsdk/camera_device/camera_device.dart';
import 'package:vsdk/camera_device/commands/param_command.dart';
import 'package:vsdk/p2p_device/p2p_command.dart';
import '../../base_config/config.dart';
import '../../components/dialogManager.dart';
import '../../components/updateVersion.dart';
import '../../db/camera_table.dart';
import '../../provider/notification_state.dart';
import '../../routes/app_routes.dart';
import '../../components/dialog.dart';
import '../../db/user_table.dart';
import '../../provider/camera_state.dart';
import '../../provider/user_state.dart';
import '../../utils/font/font.dart';
import '../../vstarcam/main/main_logic.dart';
import 'package:path_provider/path_provider.dart';
import 'package:async/async.dart';

import '../../utils/loading.dart';

/* 카메라 리스트 페이지 */
class CameraMain extends StatefulWidget  {
  const CameraMain({Key? key}) : super(key: key);

  @override
  State<CameraMain> createState() => _CameraMainState();

}

class _CameraMainState extends State<CameraMain>  {
  /// ✅ GetX
  final us = Get.put(UserState());
  final cs = Get.find<CameraState>();
  final ns = Get.put(NotificationState());
  final config = AppConfig();

  /// ✅ camera 정보 변경 관련
  TextEditingController _uidCon = TextEditingController();
  TextEditingController _idCon = TextEditingController();
  TextEditingController _pwCon = TextEditingController();
  TextEditingController _cameraNameCon = TextEditingController();

  /// ✅ 스크롤 컨트롤러
  ScrollController _scrollController = ScrollController();

  /// ✅ 카메라 전체 관련
  bool isLoading = true; // 카메라 로딩
  List _dataL = []; /// ✅ 카메라 전체 데이터
  List _filePath = []; /// ✅ 각 카메라 썸네일 경로

  /// ✅ 무한스크롤 관련
  int _limit = 10; /// 불러올 수
  int _pageNum = 1; /// 페이지 인덱스
  bool _isNextLoading = false; /// 페이지 로딩

  /// ✅ Camera Detail 관련
  ParamResult? paramResult; // DB의 detail에 업데이트하기전 임시로 담고있을 모델

  /// ✅ 사용되는곳 없음
  // CancelableOperation? _cameraInitOperation;
  // Barcode? result; // camera
  // QRViewController? controller;

  /// ✅ 이름/순서 변경 관련
  int _currIndex = 1; // 0 = 변경상태, 1 = 일반 카메라보기 상태
  bool changeClick = false; // true = 변경상테, false = 일반 카메라보기 상태

  @override
  void initState() {
    /// ✅ 카메라 상태관련 초기화
    ns.cameraNoti.value = false;
    us.cameraStateL.clear();

    fetchInit();
    _scrollController.addListener(_scrollListener);
    super.initState();
  }


  /// ✅ CameraPage Init함수
  void fetchInit() async {
    /// ✅ 중복로그인 체크
    await checkDuplicateLogin(context);

    if (!Get.isRegistered<MainLogic>()) {
      Get.put(MainLogic());
    }
    _filePath.clear(); /// ✅ 카메라 썸네일 Path 초기화

    /// ✅ 카메라 펌웨어 업데이트 다이얼로그
    if (us.userList[0]['head'] == 'true' && (us.userList[0]['cameraVersionCheck'] != 'false' || us.userList[0]['cameraVersionCheck'] == null)) {
      await updateCameraDialog(context);
    }

    /// ✅ camera불러오기
    await getCameraInit(false);
  }

  /// ✅ 클릭시 이름변경 다이얼로그
  void changeCameraName(int index) async {
      showCameraNameChangeDialog(context, _cameraNameCon, '${_dataL[index]['cameraUid']}', () {
        showConfirmTapDialog(context, '이름을 변경하시겠습니까?', () async {
          if (_cameraNameCon.text.length <= 1) {
            showOnlyConfirmDialog(context, '2자~15자 사이에서 입력해주세요');
            Get.back();
          } else {
            await cameraNameChange(_dataL[index]['cameraUid'], _cameraNameCon.text);
            _dataL[index]['ipcamId'] = _cameraNameCon.text;
            _cameraNameCon.text = '';
            cs.cameraName.value = _cameraNameCon.text;
            Get.back();
            Get.back();
            setState(() {});
          }
        });
      });
  }


  /**
   * 함수 설명: 카메라 불러온 후 => 카메라 페이지 이동 (예외처리 포함)
   *
   * 작성자: 이호준
   * 최초 작성일: 모름
   * 수정 이력:
   *   - 2025-06-19: 카메라 로그인 시 비밀번호가 기본값 888888 인 경우 Ss 로 변경 (이호준)
   */
  Future<void> loadCamera(int index) async {

    final cameraState = us.cameraStateL[index];

    // 카메라 상태에 따른 처리
    if (cameraState.isEmpty) {
      showOnlyConfirmDialog(context, '잠시만 기다려주세요');
      return;
    }

    if (cameraState == '2') {
      showOnlyConfirmDialog(context, '미연결 상태입니다');
      return;
    }

    // 카메라 로딩된 상태에서 클릭시 => 카메라 불러오기
    cs.cameraIndex.value = 0;
    final mainLogic = Get.find<MainLogic>();

    // 카메라 불러오기 (로딩) 다이얼로그
    DialogManager.showLoginLoading(context);

    //print("아아아아 ${cs.cameraList[index]["password"]}");

    cs.cancelableOperation.value = CancelableOperation.fromFuture(
      mainLogic.init(
        _dataL[index]['cameraUid'],
        _dataL[index]['cameraId'],
        _dataL[index]['password'],
      ),
      onCancel: () => Get.back(),
    );

    // 초기화 완료까지 기다리기
    await cs.cancelableOperation.value?.value;

    if (us.cameraState.value == '2') {
      // 카메라 연결 불가시 로딩 OFF
      DialogManager.hideLoading();
      showOnlyConfirmDialog(context, '현재 연결할 수 없습니다');
      return;
    }

    if (us.cameraState.value != '1') return;

    // 카메라 불러와졌을때
    await checkCameraInfo();

    // 메모리카드 초기화
    cs.timeFirst.value = false;
    cs.hourList.clear();
    cs.highlightedHours.clear();
    cs.timeLineValue.value = '';
    cs.hourCount.clear();
    cs.previousHour.value = 0;
    cs.nextFirst.value = true;
    cs.cameraTfDate.value = DateFormat('y-MM-dd').format(DateTime.now());

    // 카메라 Detail 정보 불러오기 및 소화장치 데이터 불러오기
    await Future.wait([
      getCameraDetail(_dataL[index]['cameraUid']),
      cs.getFireFightingData(_dataL[index]['cameraUid']),
    ]);

    // 카메라 연결시 로딩 OFF
    DialogManager.hideLoading();

    cs.cameraName.value = _dataL[index]['ipcamId'] ?? '';
    cs.cameraUID.value = _dataL[index]['cameraUid'];


      // 비밀번호가 기본값인 경우 Ss4552613* 변경
      String newPassword = 'Ss4552613*';
      String cameraUid = _dataL[index]['cameraUid'];
      bool result = await cs.cameraDevice!.writeCgi("set_users.cgi?pwd_change_realtime=1&users3=admin&pwd3=${newPassword}&appid=&loginuse=admin&loginpas=888888");
      if (result) {
        //await updateCameraPassword(cameraUid, newPassword);
        print("비밀번호 변경 성공: $newPassword");
        _dataL[index]['password'] = newPassword; // 비밀번호 업데이트
      } else {
        print("비밀번호 변경 실패");
      }

    ns.cameraNoti.value = false;

    print("check test 1 ");
    // 카메라 화면페이지로 이동
    Get.toNamed(AppRoutes.play)?.then((result) async {
      // print("check test 2 ");
      //
      // cs.cameraDetailTotalList.clear();
      // cs.cameraList.clear();
      // cs.cameraListClick.clear();
      // cs.cameraDetailSelectList.clear();
      //
      //
      // for (int j = 0; j < _dataL.length; j++) {
      //   print("check test 3 ");
      //
      //   await Future.wait([
      //     getCameraDetail2('${_dataL[j]['cameraUid']}'),
      //     getCameraRefresh(j),
      //   ]);
      // }
    });
  }

  /// ✅ CameraIndex 업데이트
  void updateCameraIndex(int oldIndex, int newIndex) async {
    setState(() {
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }
      final item = _dataL.removeAt(oldIndex);
      final item2 = _filePath.removeAt(oldIndex);
      final item3 = us.cameraStateL.removeAt(oldIndex);
      _dataL.insert(newIndex, item);
      _filePath.insert(newIndex, item2);
      us.cameraStateL.insert(newIndex, item3);
    });

    List uidStr = [];

    for (int i = 0; i < _dataL.length; i++) {
      uidStr.add('${_dataL[i]['cameraUid']}');
    }
    for (int i = 0; i < _dataL.length; i++) {
      final url = '${config.apiUrl}/updateindex?email=${us.userList[0]['email']}&newindex=${i}&uid=${uidStr[i]}';
      final response = await http.get(Uri.parse(url));
    }
  }


  /// ✅ cameraInit 함수 (리팩토링)
  Future<void> getCameraInit(bool isScroll) async {

    if (!mounted) return;

    final startTime = DateTime.now();
    print('카메라 초기화 시작: $startTime');

    try {
      // 초기화 작업
      if (!isScroll) {
        imageCache.clear();
        imageCache.clearLiveImages();
        cs.cameraReset();
      }

      final startIndex = _dataL.length;

      // API 호출로 카메라 정보 가져오기
      final url = '${config.apiUrl}/getNormalCamera?email=${us.userList[0]['email']}&page=${_pageNum}&limit=${_limit}';
      print('API 호출 시작: ${DateTime.now()}');

      final response = await http.get(Uri.parse(url));
      if (!mounted) return;

      final fetchedData = jsonDecode(response.body);
      print('API 응답 처리 완료: ${DateTime.now()}');

      // 빈 데이터 처리
      if (fetchedData.isEmpty) {
        _pageNum--;
        isLoading = false;
        setState(() {});
        print('빈 데이터로 인한 조기 종료');
        return;
      }

      // 데이터 추가 및 카메라 상세 정보 가져오기
      _dataL.addAll(fetchedData);
      print('카메라 상세 정보 가져오기 시작: ${DateTime.now()}');

      // for (int i = startIndex; i < _dataL.length; i++) {
      //   if (!mounted) return;
      //   await getCameraDetail2('${_dataL[i]['cameraUid']}');
      // }

      // 카메라 상태 리스트 확장
      us.cameraStateL.addAll(List.generate(fetchedData.length, (_) => ''));

      // 썸네일 파일 경로 생성
      final isIOS = Platform.isIOS;
      final newFilePaths = <String>[];

      if (isIOS) {
        final appDocDir = await getApplicationDocumentsDirectory();
        for (final data in _dataL.sublist(startIndex)) {
          newFilePaths.add('${appDocDir.path}/preview/images/${data['cameraUid']}_snapshot');
        }
      } else {
        for (final data in _dataL.sublist(startIndex)) {
          newFilePaths.add('/data/user/0/com.Ssolutions.sSolution/app_flutter/${data['cameraUid']}/images/${data['cameraUid']}_snapshot');
        }
      }

      _filePath.addAll(newFilePaths);
      print('파일 경로 생성 완료: ${DateTime.now()}');

      // 카메라 연결 상태 확인
      final mainLogic = Get.find<MainLogic>();
      final newDataCount = fetchedData.length;

      print('카메라 연결 상태 확인 시작 - 대상: $newDataCount개');

      // 병렬로 카메라 연결 상태 확인
      Future.wait(
        List.generate(newDataCount, (index) async {
          if (!mounted) throw Exception("작업 중단: 화면이 사라짐");
          await checkSingleCameraConnection(mainLogic, startIndex + index, '888888');
        }),
      );

      print('카메라 연결 상태 확인 완료: ${DateTime.now()}');

      // UI 업데이트
      isLoading = false;
      if (mounted) setState(() {});

      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);
      print('카메라 초기화 완료: $endTime (총 소요시간: ${duration.inMilliseconds}ms)');

    } catch (e) {
      print('getCameraInit 에러 발생: $e');
      isLoading = false;
      if (mounted) setState(() {});
    }
  }
  /// 스크롤 리스너 가져오기
  Future<void> _scrollListener() async {
    /// 현재 스크롤 위치가 최대 스크롤 위치에 도달하면
    if (_currIndex==1&&_isNextLoading==false&&_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      setState(() {
        _pageNum++;
        _isNextLoading = true;
      });
      await getCameraInit(true);
      setState(() {
        _isNextLoading = false;
      });
    }
  }

  /**
   * 함수 설명: 카메라 연결 상태 확인 함수
   *
   * 작성자: 이호준
   * 최초 작성일: 모름
   * 수정 이력: 최초 888 재시도 Ss455로 연결 시도 하도록 변경
   *   -
   */
  Future<void> checkSingleCameraConnection(
      MainLogic mainLogic,
      int cameraIndex,
      String password,
      {bool retried = false}) async {
    try {
      us.cameraStateL[cameraIndex] = '';

      final connectionState = await mainLogic.connectStatus(
        _dataL[cameraIndex]['cameraUid'],
        'admin',
        password,
      );

      if (connectionState == CameraConnectState.connected) {

        print("data ?? : ${_dataL[cameraIndex]}");

        String test = await getCameraDetail2(_dataL[cameraIndex]);

        //
        //
        // final currentFirmware = cs.cameraDetailTotalList[cameraIndex]['currentFirmware'];
        // final latestVersion = us.versionList[0]['camera'];
        //
        //
        //
        // print(" firm 1 : ${changeLastNumber(cs.cameraDetailTotalList[cameraIndex]['currentFirmware'])}");
        // print(" firm 2 : ${cs.cameraDetailTotalList[cameraIndex]['currentFirmware']}");
        // print(" firm 3 : ${changeLastNumber(us.versionList[0]['camera'])}");
        //
        // print("${cs.cameraDetailTotalList}");
        //
        // if (currentFirmware.isNotEmpty &&
        //     changeLastNumber(latestVersion) > changeLastNumber(currentFirmware)) {
        //   cs.cameraList.add(_dataL[cameraIndex]);
        //   cs.cameraListClick.add(false);
        //   cs.cameraDetailSelectList.add(cs.cameraDetailTotalList[cameraIndex]);
        // }
        //
        //
        // print(" firm 4 : ${cs.cameraList}");

        _dataL[cameraIndex]['password'] = password; // 비밀번호 업데이트

        us.cameraStateL[cameraIndex] = '1';
      } else {
        // 재시도 여부
        if (!retried) {
          await checkSingleCameraConnection(mainLogic, cameraIndex, 'Ss4552613*', retried: true);
        } else {
          us.cameraStateL[cameraIndex] = '2';
        }
      }
    } catch (e) {
      us.cameraStateL[cameraIndex] = '2';
    }
  }

  /// ✅ CameraDetail 가져오기
  Future<void> getCameraDetail(String cameraUid) async {
    if (!Get.isRegistered<MainLogic>()) {
      Get.put(MainLogic());
    }
    final us = Get.put(UserState());
    final url = '${config.apiUrl}/getCameraDetail?cameraUid=$cameraUid';
    final response = await http.get(Uri.parse(url));
    List<dynamic> data = jsonDecode(response.body);
    cs.cameraDetailList.value = data;
    print('카메라디테일 ${cs.cameraDetailList}');

    if (cs.cameraDetailList[0]['fireDetect'] == 'false') {
      cs.fireSwitch.value = false;
    }
    if (response.statusCode != 200) {
      print('에러에러');
      throw Exception('Failed to send email');
    }
    try {
      final url = '${config.apiUrl}/currentFirmware?currentVersion=${cs.ptzList[0].sourceData!['sys_ver']}&uid=${cs.cameraUID.value}';
      await http.get(Uri.parse(url));
      cs.cameraDetailList[0]['currentFirmware'] = cs.ptzList[0].sourceData!['sys_ver'] == '' ? '없음' : cs.ptzList[0].sourceData!['sys_ver'];
    } catch (error) {
      print('에러 getCameraDetail $error');
    }
  }

  /// ✅ 카메라 목록 새로고침
  Future<void> getCameraRefresh(int i) async {
    if (cs.cameraDetailTotalList[i]['currentFirmware'] != '' &&
        changeLastNumber(us.versionList[0]['camera']) > changeLastNumber(cs.cameraDetailTotalList[i]['currentFirmware'])) {
      cs.cameraList.add(_dataL[i]);

      print("_dataL[i] $_dataL[i]}");
      //cs.cameraListClick.add(false);
      cs.cameraDetailSelectList.add(cs.cameraDetailTotalList[i]);
    }
  }

  /// 전체 카메라 디테일 넣기
  Future<String> getCameraDetail2(Map<String, dynamic> camera) async {

    final url = '${config.apiUrl}/getCameraDetail?cameraUid=${camera['cameraUid']}';
    final response = await http.get(Uri.parse(url));
    List<dynamic> data = jsonDecode(response.body);

    print("카메라 디테일 데이터 ${data[0]}");

    print("${us.versionList[0]['camera']} asdfasdfasdfasdf ${data[0]['cameraUid']} ${data[0]['currentFirmware']}");

    if(data[0]['currentFirmware'] != us.versionList[0]['camera']) {
      print("카메라 펌웨어 업데이트 필요: ${camera['cameraUid']}");
      cs.cameraDetailTotalList.add(data[0]);
      cs.cameraList.add(camera);
    }

    print("카메라 펌웨어 업데이트 필요 리스트 ${cs.cameraList}");

    return "true";
    //return;
    // final url = '${config.apiUrl}/getCameraDetail?cameraUid=$cameraUid';
    // final response = await http.get(Uri.parse(url));
    // List<dynamic> data = jsonDecode(response.body);
    // //cs.cameraDetailTotalList.add(data[0]);
    // if(data[0]['currentFirmware'] != us.versionList[0]['camera'])
    //   cs.cameraList.add(element)
    //
    //
    // if (response.statusCode != 200) {
    //   print('에러에러');
    //   throw Exception('Failed to send email');
    // }
  }

  /// ✅ 카메라 첫로딩/새로고침시 마지막번호 업데이트 ?
  int changeLastNumber(String value) {
    int lastNum = int.parse('${value.split('.').last}');
    return lastNum;
  }

  /// ✅ 카메라 정보 (Detail)
  Future<void> checkCameraInfo() async {
    bool result1 = await cs.cameraDevice!.writeCgi(
      "trans_cmd_string.cgi?cmd=2206&appCode=smokefire@YTLD&command=1&user=admin&pwd=888888",
    );
    if (result1) {
      CommandResult result = await cs.cameraDevice!.waitCommandResult((int cmd, Uint8List data) {
        return true;
      }, 10);
      if (result.isSuccess) {
        paramResult = ParamResult.form(result);
        await cameraDetailInsert(
            paramResult!.sourceData!['fire_enable'],
            paramResult!.sourceData!['fire_sensitivity'],
            paramResult!.sourceData!['smoke_sensitivity'],
            paramResult!.sourceData!['fire_type'],
            paramResult!.sourceData!['fire_place'],
            paramResult!.sourceData!['uid']);
      }
    }
  }

  /// ✅ 받은 Camera Detail 정보를 DB에 삽입하는 함수
  Future<void> cameraDetailInsert(
      String fire_enable, String fire_sensitivity, String smoke_sensitivity, String fire_type, String fire_place, String uid) async {
    final us = Get.put(UserState());
    final url = '${config.apiUrl}/insertCameraInfo';
    print('montionDetect ${cs.ipList[0].sourceData!['alarm_motion_armed']}');
    final body = {
      'fire_enable': fire_enable,
      'fire_sensitivity': fire_sensitivity,
      'smoke_sensitivity': smoke_sensitivity,
      'fire_type': fire_type,
      'fire_place': fire_place,
      'uid': uid,
      'alarm_motion_armed': cs.ipList[0].sourceData!['alarm_motion_armed'],
      'alarm_motion_sensitivity': cs.ipList[0].sourceData!['alarm_motion_sensitivity']
    };
    cs.cameraDetailInfo.value = [body];
    final response = await http.post(Uri.parse(url), body: body);
    print('응답받은 결과물 ${response.body}');
    if (response.statusCode != 200) {
      print('에러에러');
      throw Exception('Failed to send email');
    }
  }

  @override
  void dispose() {
    cs.cameraBack.value = false;
    _uidCon.dispose();
    _idCon.dispose();
    _pwCon.dispose();
    _cameraNameCon.dispose();
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            /// ✅ 기관명
            Container(
              width: Get.width * 0.6,
              child: Text(
                '${us.userList[0]['agency']}',
                style: f20w700Size(),
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.left,
              ),
            ),
            Spacer(),

            /// ✅ 펌웨어 업데이트 버튼 (Obx 적용)
            Obx(() {
              return us.userList[0]['head'] == 'true' && cs.cameraList.length > 0
                  ? GestureDetector(
                onTap: () async {
                  if (_dataL.length == 0) {
                    showOnlyConfirmDialog(context, '업데이트 하실 펌웨어가 없습니다.');
                  } else {
                    showCameraUpdateDialog(context);
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.blue,
                  ),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        '펌웨어 업데이트',
                        style: f14Whitew700Size(),
                      ),
                    ),
                  ),
                ),
              )
                  : SizedBox();
            }),
          ],
        ),
      ),
      body: isLoading
          ? LoadingScreen()
          : Obx(() => Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              _currIndex == 0
                  ? Padding(
                padding: const EdgeInsets.only(left: 10),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text('이름/순서 변경', style: f15w600Grey()),
                ),
              )
                  : SizedBox(),
              Spacer(),
              
              /// ✅ 새로고침 버튼
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                  onTap: () async {
                  us.cameraStateL.clear();
                    setState(() {
                      _dataL.clear();
                      _pageNum = 1;
                    });
                    await getCameraInit(false);
                  },
                  child: Icon(Icons.refresh)),
              const SizedBox(
                width: 10,
              ),

              /// ✅ 이름/순서 변경 버튼
              IconButton(
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(),
                onPressed: () {
                  changeClick = !changeClick;
                  setState(() {
                    _currIndex = _currIndex == 0 ? 1 : 0;
                  });
                  // primary: true,
                },
                hoverColor: Colors.transparent,
                splashColor: Colors.transparent,
                icon: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 350),
                    transitionBuilder: (child, anim) => RotationTransition(
                      turns: child.key == ValueKey('icon1')
                          ? Tween<double>(begin: 1, end: 0.75).animate(anim)
                          : Tween<double>(begin: 0.75, end: 1).animate(anim),
                      child: ScaleTransition(scale: anim, child: child),
                    ),
                    child: _currIndex == 0
                        ? Icon(Icons.close, size: 32, key: const ValueKey('icon1'))
                        : Icon(
                      Icons.list,
                      size: 38,
                      key: const ValueKey('icon2'),
                    )),
              ),
            ],
          ),
          /// ✅ 카메라 없을때
          if (us.cameraStateL.length == 0)
            SizedBox()
          else
            /// ✅ 카메라 있을때
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  us.cameraStateL.clear();
                  setState(() {
                    _dataL.clear();
                    _pageNum = 1;
                  });
                  await getCameraInit(false);
                },
                child: cameraListWidget(), /// ✅ 카메라 리스트 위젯
              ),
            ),
        ],
      )),
    );
  }

  /// ✅ 카메라 리스트 위젯
  Widget cameraListWidget() {
    return ReorderableListView(
      shrinkWrap: true,
      scrollController: _scrollController,
      buildDefaultDragHandles: _currIndex == 1 ? false : true,
      children: [
        for (int index = 0; index < _dataL.length; index += 1)
          Container(
            key: Key('${index}'),
            child: Padding(
              padding: const EdgeInsets.only(left: 10, right: 10),
              child: GestureDetector(
                onTap: () async {
                  if (changeClick&&us.userList[0]['head']=='true') { /// ✅ 이름/순서 변경 활성화시
                    changeCameraName(index);   /// ✅ 클릭시 이름변경 다이얼로그
                  } else if(!changeClick){
                    loadCamera(index); /// ✅ 카메라 불러온 후 => 카메라 페이지 이동 (예외처리 포함)
                  }
                },
                child: Container(
                  width: Get.width,
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration:
                  BoxDecoration(borderRadius:  BorderRadius.circular(8), border: Border.all(color: Colors.black, width: 2)),
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),

                  /// ✅ Camera 카드 
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      index < _filePath.length &&File(_filePath[index]).existsSync() && File(_filePath[index]).lengthSync() > 0
                          ? Image.file( /// ✅ 썸네일
                        File(_filePath[index]),
                        width: Get.width * 0.3,
                        height: 100,
                        fit: BoxFit.fill,
                      )
                          : Image.asset( /// ✅ Play버튼 (이미지)
                        'assets/icon/play_button.png',
                        width: Get.width * 0.3,
                        height: 100,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(
                        width: 10,
                      ),

                      /// ✅ 카메라 정보 요소들
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded( /// ✅ IpcamId
                                  child: Text(
                                    '${_dataL[index]['ipcamId']}',
                                    style: f14w700Size(),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                index < us.cameraStateL.length && us.cameraStateL[index] == ''
                                    ? LoadingAnimationWidget.prograssiveDots( /// ✅ ... (연결중) 애니메이션
                                  color: Colors.blue,
                                  size: 24,
                                )
                                    : index < us.cameraStateL.length &&us.cameraStateL[index] == '2'
                                    ? Row(
                                  children: [
                                    Container( /// ✅ 미연결
                                      decoration:
                                      BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(100)),
                                      width: 16,
                                      height: 16,
                                    ),
                                    const SizedBox(
                                      width: 4,
                                    ),
                                    Text(
                                      '미연결',
                                      style: f14w700Size(),
                                    )
                                  ],
                                )
                                    : Row(
                                  children: [
                                    Container( /// ✅ 연결
                                      decoration: BoxDecoration(
                                          color: Colors.lightGreenAccent, borderRadius: BorderRadius.circular(100)),
                                      width: 16,
                                      height: 16,
                                    ),
                                    const SizedBox(
                                      width: 4,
                                    ),
                                    Text(
                                      '연결',
                                      style: f14w700Size(),
                                    )
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(
                              height: 8,
                            ),
                            Text( /// ✅ CameraUid
                              '${_dataL[index]['cameraUid']}',
                              style: f13w500Grey(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        /// ✅ 무한스크롤 (로딩중)일때 리스트 최하단로딩
        if(_isNextLoading==true)
          Container(
            key: ValueKey('loading'),
            padding: const EdgeInsets.all(20),
            child: Center(child: CircularProgressIndicator()),
          )
      ],
      onReorder: (int oldIndex, int newIndex) async {
        updateCameraIndex(oldIndex, newIndex);   /// ✅ CameraIndex 업데이트
      },
    );
  }
}


