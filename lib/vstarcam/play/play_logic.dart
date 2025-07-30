import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mms/utils/manager.dart';
// import 'package:mms/play/play_state.dart';
// import 'package:mms/ssolution/lib/provider/notification_state.dart';
// import 'package:mms/ssolution/lib/provider/user_state.dart';
import 'package:vsdk/app_player.dart';
import 'package:vsdk/camera_device/camera_device.dart';
import 'package:vsdk/camera_device/commands/video_command.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:vsdk/p2p_device/p2p_command.dart';
// import '../client/config.dart';
import '../../base_config/config.dart';
import '../../provider/camera_state.dart';
import '../../provider/notification_state.dart';
import '../../provider/user_state.dart';
import '../../utils/device_manager.dart';
import '../../utils/super_put_controller.dart';
import '../main/main_logic.dart';
import '../model/device_model.dart';
import '../settings_main/settings_main_logic.dart';
// import '../ssolution/lib/provider/camera_state.dart';
// import '../utils/device_manager.dart';
// import '../utils/super_put_controller.dart';
// import '../widget/scale_offset_gesture_detector.dart';
import 'package:path_provider/path_provider.dart';

import '../vstarcam_widget/scale_offset_gesture_detector.dart';
import 'play_state.dart';

class PlayLogic extends SuperPutController<PlayState>{
  final cs = Get.find<CameraState>();
  final ns = Get.put(NotificationState());
  final config = AppConfig();
  AppPlayerController? controller;
  LiveVideoSource? videoSource;
  ValueNotifier<ScaleOffset>? videoScaleNotifierFirst;
  ValueNotifier<ScaleOffset>? videoScaleNotifierSecond;
  double defaultValue = 1.0;

  PlayLogic() {
    value = PlayState();
  }


  @override
  void onInit() {
    print("시작시작시작");
    handleInitAsync();
    // WidgetsBinding.instance.addObserver(this);
    super.onInit();
  }

  Future<void> handleInitAsync() async {
    await onCameraDeviceReady(); // 여기서 await 사용 가능
    print("📸 카메라 준비 완료");
  }

  Future<void> onCameraDeviceReady() async {
    if(cs.test.value == false)
      {
        print("카메라 디바이스 준비 완료");
        // 카메라 디바이스가 준비되면 필요한 초기화 작업을 수행합니다.
        // 예: 카메라 스트림 시작, UI 업데이트 등
        print("put?? ${cs.cameraName.value}");

        if (Get.isRegistered<CameraState>()) {
          print("✅ CameraState는 이미 등록되어 있음 (find 사용)");
        } else {
          print("🆕 CameraState가 등록되어 있지 않음 (put으로 새로 등록)");
        }

        init(DeviceManager.getInstance().mDevice!).then((data) {
          if (DeviceManager.getInstance().deviceModel!.supportPinInPic.value == 1 ||
              DeviceManager.getInstance()
                  .deviceModel!
                  .supportMutilSensorStream
                  .value ==
                  1) {
            getLinkableEnable();
          }
        });
        videoScaleNotifierFirst = ValueNotifier(ScaleOffset());
        videoScaleNotifierSecond = ValueNotifier(ScaleOffset());

        state!.zoomValue.value = DeviceManager.getInstance().deviceModel!.CurZoomMultiple.value;
        currentFirmware();
        ns.fireStationSend.value = false;
        cs.cameraInsert.value = true;
        screenShots();
        cs.test.value = true;
        Future.delayed(Duration(milliseconds: 1000), () async{
          cs.test.value = false;
        });
      }
  }


  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      print("컨트롤러에서 포그라운드 복귀 감지");
      // 원하는 동작 실행
      await onCameraDeviceReady();

    }
  }

  @override
  void dispose() {
    print("종료종료종료");
    // 위젯이 dispose될 때 호출되는 메소드
    cs.cameraDevice?.deviceDestroy();
    super.dispose();
  }

  Future<void> stopNotification(String body) async {
    try {
      final response = await http.post(
        Uri.parse('${config.cameraNotiUrl}/stopNotification'),
        // Uri.parse('http://misnetwork.iptime.org:9090/stopNotification'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'vuid': body,
        }),
      );
      if (response.statusCode == 200) {
        print('Notification stopped successfully');
      } else {
        print('Failed to stop notification: ${response.statusCode}');
      }
    } catch (e) {
      print('Error stopping notification: $e');
    }
  }

  void addScaleOffset() {
    initScaleNotifier();
    defaultValue++;
    if (defaultValue > 5) {
      defaultValue = 5.0;
    }
    setScaleNotifier();
  }

  void setScaleNotifier() {
    if (state!.select.value == 1) {
      ///第一个枪机
      videoScaleNotifierFirst!.value.scale = defaultValue;
      videoScaleNotifierFirst!.notifyListeners();
    } else if (state!.select.value == 2) {
      ///第二个枪机
      videoScaleNotifierSecond!.value.scale = defaultValue;
      videoScaleNotifierSecond!.notifyListeners();
    }
  }

  void initScaleNotifier() {
    bool split =
        DeviceManager.getInstance().deviceModel?.splitScreen.value == 1;
    if (videoScaleNotifierFirst == null && state!.hasSubPlay.value != 0) {
      videoScaleNotifierFirst = ValueNotifier(ScaleOffset());
    }
    if (videoScaleNotifierSecond == null &&
        ((state!.hasSubPlay.value == 1 && split) ||
            state!.hasSubPlay.value == 2)) {
      videoScaleNotifierSecond = ValueNotifier(ScaleOffset());
    }
  }


  /// 처음 preview
  void screenShots()async{
    if (Platform.isIOS) {
      /// 스크린샷 가져오기
      bool snapBool = await DeviceManager.getInstance().mDevice!.writeCgi('snapshot.cgi?sensor=0&');

      CommandResult result = await DeviceManager.getInstance().mDevice!.waitCommandResult((int cmd, Uint8List data) {
        return cmd == 24597;
      }, 5);

      Directory? appDocDir = await getApplicationDocumentsDirectory();
      /// 폴더 만들고
      final screenshotsDirectory = Directory('${appDocDir!.path}/preview');
      if (!await screenshotsDirectory.exists()) {
        await screenshotsDirectory.create(recursive: true);
      }
      String filePath = '${screenshotsDirectory.path}/images/${DeviceManager.getInstance().mDevice!.id}_snapshot';
      File(filePath).create(recursive: true);
      final file = File(filePath);
      file.writeAsBytes(result.data!);

      if (snapBool) {
        state?.snapshotFile.value = file;
      }
    }
    else {
      bool snapBool = await DeviceManager.getInstance().mDevice!.writeCgi('snapshot.cgi?sensor=0&');
      CommandResult result = await DeviceManager.getInstance().mDevice!.waitCommandResult((int cmd, Uint8List data) {
        return cmd == 24597;
      }, 5);
      Directory directory = await DeviceManager.getInstance().mDevice!.getDeviceDirectory();
      String filePath = '${directory.path}/images/${DeviceManager.getInstance().mDevice!.id}_snapshot';
      File(filePath).createSync(recursive: true);
      final file = File(filePath);
      if(result.data == null) {
        print("스크린샷 데이터가 없습니다.");
        return;
      }
      file.writeAsBytes(result.data!);
      if (snapBool == true) {
        ///d.snapshotCacheFile = File(filePath);
        state?.snapshotFile.value = file;
      }
    }
  }
  void reduceScaleOffset() {
    initScaleNotifier();
    defaultValue--;
    if (defaultValue < 1) {
      defaultValue = 1.0;
    }
    setScaleNotifier();
  }

  /// 현재 펌웨어
  Future<void> currentFirmware() async {
    try {
      final url = '${config.apiUrl}/currentFirmware?currentVersion=${cs.ptzList[0].sourceData!['sys_ver']}&uid=${cs.cameraUID.value}';
      await http.get(Uri.parse(url));
      cs.cameraDetailList[0]['currentFirmware'] = cs.ptzList[0].sourceData!['sys_ver'] == '' ? '없음' : cs.ptzList[0].sourceData!['sys_ver'];
    } catch (error) {
      print('에러 currentFirmware $error');
      print('에러 currentFirmware ${cs.cameraDetailList}');
      print('에러 currentFirmware ${cs.ptzList}');
    }
  }

  @override
  void onClose() async {
    // 카메라 디바이스 제거
    await cs.cameraDevice?.deviceDestroy();

    // 위젯 옵저버 제거
    WidgetsBinding.instance.removeObserver(this);

    final us = Get.find<UserState>();

    // 알림에서 들어온 경우 처리
    if (ns.cameraNoti.value) {
      ns.cameraNoti.value = false;

      // MainLogic 등록 여부 확인 후 등록
      if (!Get.isRegistered<MainLogic>()) {
        Get.put(MainLogic());
      }

      MainLogic logic = Get.find<MainLogic>();
      logic.removeListeners(); // 리스너 제거

      // 하단 탭 인덱스 설정 및 상태 초기화
      us.bottomIndex.value = 2;
      cs.fullScreen.value = false;
      cs.cameraBack.value = true;

      // 두 번 뒤로가기 (이전 화면으로 이동)
      // Get.back();
       Get.back();


    } else if (cs.fullScreen.value || cs.tfFullScreen.value) {
      // 전체화면 또는 tf전체화면이면 해당 상태 해제
      cs.fullScreen.value = false;
      cs.tfFullScreen.value = false;

    } else {

      // 현재 선택된 카메라 정보 업데이트
      var camera = cs.cameraDetailSelectList.firstWhere(
            (camera) => camera['cameraUid'] == cs.ptzList[0].deviceid,
        orElse: () => null,
      );

      if (camera != null) {
        camera['currentFirmware'] = cs.ptzList[0].sys_ver;

        // 펌웨어 버전 비교 후 리스트에서 제거
        var currentVersion = int.tryParse(camera['currentFirmware'].split('.').last);
        var minVersion = int.tryParse(us.versionList[0]['camera'].split('.').last);

        if (currentVersion != null && minVersion != null && minVersion <= currentVersion) {
          cs.cameraList.removeWhere((data) => data['cameraUid'] == cs.ptzList[0].deviceid);
          cs.cameraDetailSelectList.removeWhere((data) => data['cameraUid'] == cs.ptzList[0].deviceid);
        }
      }

      ns.cameraNoti.value = false;

      // MainLogic 등록 여부 확인 후 등록
      if (!Get.isRegistered<MainLogic>()) {
        Get.put(MainLogic());
      }

      MainLogic logic = Get.find<MainLogic>();
      logic.removeListeners();

      // 상태값 초기화
      cs.cameraDevice = null;
      us.bottomIndex.value = 1;
      cs.fullScreen.value = false;
      cs.tfFullScreen.value = false;
      cs.cameraBack.value = true;

      Get.back(); // 이전 화면으로 이동
    }

    // 비디오 진행도 콜백 제거 및 컨트롤러 정리
    controller?.removeProgressChangeCallback(onProgress);
    controller?.dispose();

    // 플레이어 컨트롤러 정리
    state?.player2Controller?.stop();
    state?.player2Controller?.dispose();

    state?.player3Controller?.stop();
    state?.player3Controller?.dispose();

    // 비디오 스케일 관련 리스너 제거
    videoScaleNotifierFirst?.dispose();
    videoScaleNotifierSecond?.dispose();

    // 위젯 옵저버 재차 제거 (중복 대비)
    WidgetsBinding.instance.removeObserver(this);

    // GetX 컨트롤러 삭제
    Get.delete<PlayLogic>();
    Get.delete<SettingsMainLogic>();

    // 전체화면 및 카메라 삽입 상태 초기화
    cs.fullScreen.value = false;
    cs.cameraInsert.value = false;

    print("종료");

    // 부모의 onClose 호출
    super.onClose();
  }

  ///视频播放状态监听回调
  void playChange(userData, VideoStatus videoStatus, VoiceStatus voiceStatus,
      RecordStatus recordStatus, SoundTouchType touchType) {
    state?.playChange.value = state?.playChange.value ?? 0 + 1;
    state?.voiceStatus = voiceStatus;
    state?.recordStatus = recordStatus;
    state?.videoStatus.value = videoStatus;
    state?.videoStop.value = videoStatus == VideoStatus.STOP;
    state?.videoPause.value = videoStatus == VideoStatus.PAUSE;

    print(
        "videoStatus:$videoStatus voiceStatus:$voiceStatus recordStatus:$recordStatus touchType:$touchType");
  }

  // 영상이 시작 되면
  // void onProgress(dynamic userData, int totalSec, int playSec, int progress,
  //     int loadState, int velocity) async {
  void onProgress(dynamic userData, int totalSec, int playSec, int progress,
      int loadState, int velocity, int time) async {
    // print(
    //     "player currentSec:$playSec, totalSec:$totalSec, progress:$progress loadState:$loadState flow:$velocity)");

    if (velocity != state?.velocity.value) {
      state?.velocity.value = velocity;
    }

    // 0초가 전부면 멈추기
    if (totalSec >= 0) {
      state?.duration = totalSec;
    }

    // 0 초면 시작 한 번
    if (playSec >= 0) {
      state?.progress = playSec;

      // 사진 찍는 함수 만들기
      if (state?.videoRecord.value == true) {
        state?.recordProgress.value = playSec - state!.recordStartSec;
      }
    };
    /// 스샷 버튼 눌렀을 때
    if (cs.cameraCapture.value == 'screenShot') {

      Directory? appDocDir = await getApplicationDocumentsDirectory();

      String filePath = '${appDocDir.path}/images/${DeviceManager.getInstance().mDevice!.id}_snapshot';
      // DeviceManager.getInstance().mDevice!.writeCgi("snapshot.cgi?user=testrad@naver.com&pwd=1234&loginuse=admin&loginpas=888888&res=2&", timeout: 5);
      bool bl = await controller!.screenshot(filePath);

      if (bl) {
        state?.snapshotFile.value = File(filePath);
        cs.cameraCapture.value = '';
      }
      else {
        cs.cameraCapture.value = '';
      }

    }
    if (playSec == 1) {
      if (Platform.isIOS) {
        /// 스크린샷 가져오기
        bool snapBool = await DeviceManager.getInstance().mDevice!.writeCgi('snapshot.cgi?sensor=0&');

        CommandResult result = await DeviceManager.getInstance().mDevice!.waitCommandResult((int cmd, Uint8List data) {
          return cmd == 24597;
        }, 5);

        Directory? appDocDir = await getApplicationDocumentsDirectory();
        /// 폴더 만들고
        final screenshotsDirectory = Directory('${appDocDir!.path}/preview');
        if (!await screenshotsDirectory.exists()) {
          await screenshotsDirectory.create(recursive: true);
        }
        String filePath = '${screenshotsDirectory.path}/images/${DeviceManager.getInstance().mDevice!.id}_snapshot';
        File(filePath).create(recursive: true);
        final file = File(filePath);
        file.writeAsBytes(result.data!);

        if (snapBool) {
          state?.snapshotFile.value = file;
        }
      }
      else {
        bool snapBool = await DeviceManager.getInstance().mDevice!.writeCgi('snapshot.cgi?sensor=0&');
        CommandResult result = await DeviceManager.getInstance().mDevice!.waitCommandResult((int cmd, Uint8List data) {
          return cmd == 24597;
        }, 5);

        Directory directory = await DeviceManager.getInstance().mDevice!.getDeviceDirectory();
        String filePath = '${directory.path}/images/${DeviceManager.getInstance().mDevice!.id}_snapshot';
        File(filePath).createSync(recursive: true);
        final file = File(filePath);
        if(result.data == null) {
          print("스크린샷 데이터가 없습니다.");
          return;
        }
        file.writeAsBytes(result.data!);
        bool bl = await controller!.screenshot(filePath);
        if (bl == true) {
          ///d.snapshotCacheFile = File(filePath);
          state?.snapshotFile.value = File(filePath);
        }
      }
    }

    if (loadState != 0 && playSec == totalSec) {
      stopPlay();
    }
  }

  Future<void> init(CameraDevice device) async {
    print("init ??");
    if (DeviceManager.getInstance().deviceModel!.connectState.value ==
        DeviceConnectState.disconnect ||
        DeviceManager.getInstance().deviceModel!.connectState.value ==
            DeviceConnectState.none ||
        DeviceManager.getInstance().deviceModel!.connectState.value ==
            DeviceConnectState.timeout) {
      print("-----------reconnect-------------");

      ///重新连接
      CameraConnectState connectState = await DeviceManager.getInstance().mDevice!.connect();
      if (connectState == CameraConnectState.disconnect ||
          connectState == CameraConnectState.none ||
          connectState == CameraConnectState.timeout) {
        return;
      }
    }
    controller = AppPlayerController(changeCallback: playChange);
    state?.playerController = controller;

    controller!.setCreatedCallback((data) async {
      print("--------------setCreatedCallback---------------");
      DeviceManager.getInstance().setController(controller!);

      ///判断是否要加载多目播放器
      await setSubPlayer();

      await start(device);
      return;
    });
    if (controller!.isCreated) {
      await controller!.start();
    } else {
      await controller!.create();
      await controller!.start();
      print("--------------controller.create---------------");
    }

    controller!.addProgressChangeCallback(onProgress);
  }

  Future<void> start(CameraDevice device) async {
    if (controller == null) return;
    print('1——— : ${controller == null}');

    videoSource = LiveVideoSource(device.clientPtr!);
    print('2———');

    await controller!.setVideoSource(videoSource!);
    print('3———');

    int resolution = await DeviceManager.getInstance().getResolutionValue(device.id);
    print('4———');

    var live = await device.startStream(resolution: _intToResolution(resolution));
    print("———live———$live———");
    await controller!.stop();
    await controller!.start();
    print('5———');

    device.keepAlive(time: 10);

    state?.videoStop.value = false;
    state?.videoPause.value = false;

    print('`start` in ———');
  }


  ///设置多目播放器
  Future<bool> setSubPlayer() async {
    bool bl = false;

    ///创建多目设备的播放控制器
    int sensor = DeviceManager.getInstance()
        .deviceModel
        ?.supportMutilSensorStream
        .value ??
        0;

    int splitScreen =
        DeviceManager.getInstance().deviceModel?.splitScreen.value ?? 0;

    ///splitScreen=1 代表二目分屏为三目，为假三目。只有splitScreen !=1 时才是真三目
    if (sensor == 3 && splitScreen != 1) {
      bl = await enableSubPlayer(sub2Player: true);
      print("-----------3-------enableSubPlayer---$bl---------------");
    } else if (sensor == 1 || (sensor == 3 && splitScreen == 1)) {
      ///二目或者假三目
      bl = await enableSubPlayer();
      print("-----------2-------enableSubPlayer---$bl---------------");
    }
    return bl;
  }

  VideoResolution _intToResolution(int value) {
    if (value == 4) {
      return VideoResolution.low;
    } else if (value == 2) {
      return VideoResolution.general;
    } else if (value == 1) {
      return VideoResolution.high;
    } else if (value == 100) {
      return VideoResolution.superHD;
    }
    return VideoResolution.general;
  }

  Future<void> stopPlay() async {
    if (controller != null && controller!.isCreated) {
      await controller!.stop();
    }
    state?.videoStop.value = true;
  }

  @override
  void onHidden() {
    if(cs.cameraBackgroundCheck.value){
      print("화면 복구");
     //cs.cameraDevice!.connect();
      //  final MainLogic mainLogic = Get.find<MainLogic>();
      //  mainLogic.connectDevice(DevicGeManager.getInstance().mDevice!).then((v) {
      //   print('offline connect device $v');
      //   if (!v) {
      //     start(DeviceManager.getInstance().mDevice!);
      //     controller?.start();
      //     DeviceManager.getInstance().deviceModel!.connectState.value = DeviceConnectState.connected;
      //   }
      // });
      cs.cameraBackgroundCheck.value = false;
    }else{
      //cs.cameraDevice!.deviceDestroy();
      cs.cameraDevice!.disconnect();
      cs.cameraBackgroundCheck.value = true;
    }
  }

  void startVideo() async {
    if (controller == null || videoSource ==null) return;
    await controller!.setVideoSource(LiveVideoSource(videoSource!.clientPtr));
    bool test = await cs.cameraDevice!.startStream(resolution: VideoResolution.general);
    controller!.start();
    state?.videoStop.value = false;
  }

  ///创建多目播放器
  Future<bool> enableSubPlayer({bool sub2Player = false}) async {
    if (controller!.sub_controller != null) return true;
    var subController = AppPlayerController();

    var result = await subController.create();
    if (result != true) {
      print("-------------subController.create---false---------------");
      return false;
    }
    result = await subController.setVideoSource(SubPlayerSource());
    if (result != true) {
      print("-------------subController.setVideoSource---false---------------");
      return false;
    }
    await subController.start();
    result = await controller!.enableSubPlayer(subController);
    if (result != true) {
      print("-------------enableSubPlayer---false---------------");
      return false;
    }
    state?.player2Controller = subController;

    //sub2Player
    if (sub2Player == true) {
      if (controller!.sub2_controller != null) return true;
      var sub2Controller = AppPlayerController();
      var result = await sub2Controller.create();
      if (result != true) {
        print("-------------sub2Controller.create---false---------------");
        return false;
      }
      result = await sub2Controller.setVideoSource(SubPlayerSource());
      if (result != true) {
        print(
            "-------------sub2Controller.setVideoSource---false---------------");
        return false;
      }
      await sub2Controller.start();
      result = await controller!.enableSub2Player(sub2Controller);
      if (result != true) {
        print("-------------enableSub2Player---false---------------");
        return false;
      }
      state?.player3Controller = sub2Controller;
    }
    if (sub2Player) {
      state?.hasSubPlay.value = 2;
    } else {
      state?.hasSubPlay.value = 1;
    }
    return true;
  }

  ///二目联动
  linkable(int xPercent, int yPercent) async {
    if (DeviceManager.getInstance().deviceModel!.isSupportLowPower.value &&
        DeviceManager.getInstance().deviceModel!.batteryRate.value < 20) {
      EasyLoading.showToast("电量不足，云台无法使用");
      return;
    }
    bool bl = await DeviceManager.getInstance()
        .mDevice!
        .qiangQiuCommand
        ?.controlFocalPoint(xPercent, yPercent) ??
        false;
    if (bl) {
      print("------------------");
    }
  }

  ///获取联动开关状态
  getLinkableEnable() async {
    bool bl = await DeviceManager.getInstance()
        .mDevice!
        .qiangQiuCommand
        ?.getLinkageEnable() ??
        false;
    if (bl) {
      state!.isLinkableOpen.value = DeviceManager.getInstance()
          .mDevice!
          .qiangQiuCommand
          ?.gblinkage_enable ==
          1;
    }
  }

  ///设置光学变焦
  setZoom(int scale) async {
    bool bl = false;
    if (DeviceManager.getInstance().deviceModel!.MaxZoomMultiple.value > 0) {
      //新版本固件
      // bl = await DeviceManager.getInstance()
      //         .mDevice!
      //         .multipleZoomCommand
      //         ?.multipleZoomCommand(scale) ??
      //     false;
      bl = await DeviceManager.getInstance()
          .mDevice!
          .multipleZoomCommand
          ?.multipleZoomCommand(scale) ??
          false;
    } else {
      //老版本固件
      bl = await DeviceManager.getInstance()
          .mDevice!
          .multipleZoomCommand
          ?.multipleZoom4XCommand(scale) ??
          false;
    }
    if (bl) {
      state!.zoomValue.value = scale;
      print("——setZoom——true————");
    }
  }
}
