import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';

// import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:mms/db/camera_table.dart';
import 'package:vsdk/camera_device/camera_device.dart';
import 'package:async/async.dart';

import '../components/dialog.dart';
import 'package:http/http.dart' as http;

class CameraState extends GetxController {
  /// ✅ 카메라 기능 Status(활성아이콘/비활성아이콘) 관련
  final cameraIconL = [
    false,
    false,
    false,
    false,
    false,
    false,
    false,
    false,
    false
  ].obs; // 불꽃감지 ~ 사이렌 On/Off 상태
  final cameraFullIconL = [false, false, false, false, false, false, false]
      .obs; // 불꽃감지 ~ 사이렌 On/Off 상태 (전체화면)

  /// ✅ 전체화면 관련
  final fullScreen = false.obs;

  /// ✅ 카메라 정보관련
  final cameraUID = ''.obs;
  final cameraName = ''.obs;
  final ipList = [].obs; // 카메라 ip주소
  final ptzList = [].obs; // 카메라의 sysver,sd용량등 정보관련
  final cameraDetailList = [].obs; // db의 카메라 설정값

  //2025-06-09 수정
  final cameraPassword = 'Ss4552613*'.obs; // 카메라 비밀번호
//#sdf<>1234#
  /// ✅ 카메라 기능 On/Off 관련 (불꽃감지 ~ 모션감지)
  // true - false 변환만 시켜주고 사용하는곳은 없음 ( 아마 쓰레기값으로 추정 )
  final fireSwitch = true.obs;
  final motionSwitch = true.obs;
  final smokeSwitch = true.obs;
  final sound_stream_status = false.obs; // 카메라 소리송신
  final mCameraVoice = false.obs; // 카메라 마이크송출
  final fireExtinguisher = false.obs; // 소화장치

  /// ✅ 실시간화면/메모리카드화면 페이지 Index
  final cameraIndex = 0.obs;

  /// ✅ 카메라 캡쳐관련
  final cameraCapture = ''.obs;

  final test = false.obs; // 화면 갱신용 더미

  /// ✅ 카메라 메모리카드 관련
  final timeFirst = false.obs; // 메모리화면 처음 실행될때
  final cameraTfDate =
      '${DateFormat('y-MM-dd').format(DateTime.now())}'.obs; // 보고있는 메모리카드 날짜
  final timeCon = ScrollController().obs; // 모든시간 Controller ?
  final highlightedHours = <dynamic>[].obs; // 색칠할 메모리카드 구간 (메모리에 존재하는 시간)
  final hourList = [].obs; // 시간 리스트 ?
  final previousHour = 0.obs; // 이전시간 ?
  final nextFirst = true.obs; // 앞으로 갈때 한번만 실행
  final stopScroll = true.obs; // 스크롤멈추기
  final addTime = 0.obs; // 현재 보고있는 시간

  /// ✅ 카메라 메모리카드 영상 관련
  final tfcardIndex = 0.obs; // 정체불명
  final cameraPercentage = ''.obs; // 메모리카드 영상 다운로드 퍼센트
  final lastCameraPercentage = ''.obs;

  /// 카메라 퍼센트
  final cameraDownloadCnt = 0.obs;

  /// 카메라 다운로드 카운트
  final tfFullScreen = false.obs; // 메모리카드 전체화면
  final tfCameraDetailScale = 1.0.obs; // 메모리카드 detail 크기
  final tfCameraChangeMp4 = false.obs; // 메모리카드 영상 변환상태

  /// ✅ 카메라 페이지 Icon 표시,크기,위치 여부
  final cameraIconVisible = true.obs;
  final cameraDetailScale = 1.0.obs;
  final currentPosition = 0.obs;

  /// ✅ 카메라 Device 관련
  final Rx<CameraDevice?> _cameraDevice = Rx<CameraDevice?>(null);
  CameraDevice? get cameraDevice => _cameraDevice.value;
  set cameraDevice(CameraDevice? value) => _cameraDevice.value = value;
  final cancelableOperation = Rx<CancelableOperation?>(null); // 잘 모르겠음

  /// ✅ 펌웨어 버전업데이트 관련 함수
  final cameraList = [].obs;

  /// 전체 카메라 리스트
  //final cameraListClick = [].obs; /// 카메라 업데이트 클릭 리스트
  final cameraUpdateClick = false.obs;

  /// 확인버튼 눌를 때
  final cameraDetailSelectList = [].obs;

  /// 디테일 리스트중에서 업데이트할 목록들
  final cameraDetailTotalList = [].obs;

  /// 전체 디테일 리스트
  final cameraAllCheck = false.obs;

  /// 카메라 한번 클릭
  //final cameraCopyList = [].obs; /// cameraList 카피

  /// ✅ 카메라 init 관련
  final cameraInsert = false.obs;

  ///카메라에 들어가있나 없나

  /// ✅ 카메라 detail 관련 (안쓸 가능성 있음)
  final cameraDetailInfo = [].obs;

  /// 카메라 디테일 리스트

  /// ✅ 카메라 알림소리 등록상태
  final cameraSuccess = false.obs;

  /// ✅ 앱 숨김상태일때 작동 ?
  final cameraBackgroundCheck = false.obs;

  /// ✅ 카메라 기본 경보음
  final cameraTextList = [
    /// 11-25 추가
    '화재 경보 벨소리',
    '화재가 감지되었습니다. 안전한 곳으로 대피하시기 바랍니다.',
    '이곳은 CCTV 녹화중입니다',
    '쓰레기 분리배출을 잘 해주셔서 감사합니다'
  ].obs;

  /// ✅ 카메라 소방장치 관련
  final fireFightingData = {}.obs;

  /// 소방장치 상태 데이터
  Timer? _fireFightingApiTimer;

  /// 소방장치 데이터 2초주기 갱신 타이머
  BuildContext? context;

  /// 작동완료 다이얼로그용 context

  /// X✅X 사용되는곳 없음
  final zoom = 1.obs;
  final manual_light_status = false.obs;
  final camerapot = <Offset>[].obs;
  final needsRefresh = false.obs;
  final cameraBackgroundFirst = RxBool(false);
  final isNavigating = false.obs;
  final timeLineValue = ''.obs;

  /// 내가 현재 가르키는 시간 (나중에 삭제) /// ✅ 값만 변경하고 사용하는곳 X
  final hourCount = [].obs;

  /// 날짜 갯수 /// ✅ 클리어만 하고 사용하지 않음
  final cameraLoading = true.obs;

  /// ✅ 변경만하고 사용하는곳 x
  final cameraBack = false.obs;

  /// 카메라 메인으로 이동 변수  /// ✅ 변경만하고 사용하는곳 x

  /// ✅ agent
  final agentNotiUrl = "".obs;

  /// 카메라 메인으로 이동 변수  /// ✅ 변경만하고 사용하는곳 x

  @override
  void onInit() {
    super.onInit();
  }

  @override
  void dispose() {
    timeCon.value.dispose();
    super.dispose();
  }

  void cameraReset() {
    print("this?");
    cameraDetailTotalList.clear();
    // cameraListClick.clear();
    cameraDetailSelectList.clear();
    cameraList.clear();
    cameraAllCheck.value = false;
  }

  /// ✅ 메모리카드 영상 다운로드
  Future<void> monitorDownloadProgress({
    required File destFile,
    required double totalSizeMB,
    required BuildContext context,
    required Timer timer,
  }) async {
    /// 파일이 존재하면 진행률 계산
    if (await destFile.exists()) {
      final fileSize = await destFile.length();
      final downloadedSizeInMB = fileSize / (1024 * 1024);
      final progress = (downloadedSizeInMB / totalSizeMB) * 100;
      lastCameraPercentage.value = cameraPercentage.value;
      cameraPercentage.value = progress.toStringAsFixed(2);
      print('??다운로드 카메라 퍼센테이지? ${downloadedSizeInMB}');
      if (lastCameraPercentage == cameraPercentage.value) {
        cameraDownloadCnt.value++;
        if (cameraDownloadCnt.value >= 3) {
          tfCameraChangeMp4.value = true;
          cameraDownloadCnt.value = 0;
          timer.cancel();
          final outputPath = destFile.path.replaceFirst('.mp4', '_.mp4');
          // '-i "${destFile.path}" -c copy "${outputPath}" -y',
          // await FFmpegKit.executeAsync(
          //   Platform.isAndroid?'-i "${destFile.path}" -c copy "${outputPath}" -y':'-i "${destFile.path}" -c:v mpeg4 "${outputPath}"',
          //       (session) async {
          //     final returnCode = await session.getReturnCode();
          //     if (returnCode != null && returnCode.isValueSuccess()) {
          //       tfCameraChangeMp4.value = false;
          //       print('종료???');
          //       destFile.deleteSync();
          //       bool? result2 = await controller.controller.stopDown();
          //       Get.back();
          //       showOnlyConfirmTapDialog(context, '다운이 완료되었습니다', () {
          //         Get.back();
          //       });
          //     } else {
          //       print("비디오 변환 실패: 코드 ${returnCode?.getValue()}");
          //       final logs = await session.getLogs();
          //       print("FFmpeg 로그: $logs");
          //     }
          //   }, (log) {
          //   print('FFmpeg 로그: ${log.getMessage()}');
          // }, (statistics) {
          //   print('비디오 변환 진행률: ${statistics.getTime() / 1000} 초');
          // },
          // );
        }
      } else {
        cameraDownloadCnt.value = 0;
      }
      // 다운로드 완료 처리
      // if (progress >= 99) {
      //   tfCameraChangeMp4.value = true;
      //   timer.cancel();
      //   final outputPath = destFile.path.replaceFirst('.mp4', '_.mp4');
      //   // '-i "${destFile.path}" -c copy "${outputPath}" -y',
      //   await FFmpegKit.executeAsync(
      //     Platform.isAndroid?'-i "${destFile.path}" -c copy "${outputPath}" -y':'-i "${destFile.path}" -c:v mpeg4 "${outputPath}"',
      //         (session) async {
      //       final returnCode = await session.getReturnCode();
      //       if (returnCode != null && returnCode.isValueSuccess()) {
      //         tfCameraChangeMp4.value = false;
      //         print('종료???');
      //         destFile.deleteSync();
      //         bool? result2 = await controller.controller.stopDown();
      //         Get.back();
      //         showOnlyConfirmTapDialog(context, '다운이 완료되었습니다', () {
      //           Get.back();
      //         });
      //       } else {
      //         print("비디오 변환 실패: 코드 ${returnCode?.getValue()}");
      //         final logs = await session.getLogs();
      //         print("FFmpeg 로그: $logs");
      //       }
      //     }, (log) {
      //       print('FFmpeg 로그: ${log.getMessage()}');
      //     }, (statistics) {
      //       print('비디오 변환 진행률: ${statistics.getTime() / 1000} 초');
      //     },
      //   );
      // }
    }
  }

  /// ✅ 소방장치 데이터 가져오기
  Future<void> getFireFightingData(String cameraUid) async {
    if (cameraUid == '') return;

    try {
      // 1. api 요청
      final response = await http.get(Uri.parse(
          '${config.baseUrl}/getFireFightingData?cameraUid=$cameraUid'));

      Map<dynamic, dynamic> data = jsonDecode(response.body);

      // 2. GetX에 값 세팅
      fireFightingData.value = data;

      // 3. 완료상태가 아니며, 타이머가 없을시 타이머 시작
      if (fireFightingData.value['fireFightingStatus'] != 2) {
        print("로그 1");
        startFireFightingFetchTimer();
      }
      print("소방장치 ? : ${fireFightingData.value}");
    } catch (e) {
      print("Failed to getFireFightingData $e");
    }

    return;
  }

  /// 소방장치 타이머 관련

  void startFireFightingFetchTimer() {
    // 타이머 시작
    // if (_fireFightingApiTimer != null) return;
    //
    // _fireFightingApiTimer = Timer.periodic(Duration(seconds: 2), (timer) async {
    //   await getFireFightingData(cameraUID.value ?? '');
    //
    //   if (context != null && fireFightingData.value['fireFightingStatus'] == 2) {
    //     print("로그 3");
    //     // showFireFightingCompleteDialog(context!); // 완료 다이얼로그
    //     stopFireFightingFetchTimer(); // 타이머 종료
    //   }
    // });
  }

  void stopFireFightingFetchTimer() {
    // 타이머 종료
    if (_fireFightingApiTimer != null) {
      _fireFightingApiTimer!.cancel();
      _fireFightingApiTimer = null;
      context = null; // context도 같이 초기화
    }
  }
}
