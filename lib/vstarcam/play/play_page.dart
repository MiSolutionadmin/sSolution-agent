import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:http/http.dart' as http;
import 'package:cupertino_will_pop_scope/cupertino_will_pop_scope.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:mms/components/dialogManager.dart';
import 'package:mms/components/fireFIghtingIcon.dart';
import 'package:mms/provider/user_state.dart';
import 'package:mms/screen/alim/alim_main_page.dart';
import 'package:mms/utils/permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vsdk/app_player.dart';
import 'package:mms/utils/device_manager.dart';
import 'package:get/get.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:vsdk/p2p_device/p2p_command.dart';

import '../../base_config/config.dart';
import '../../components/dialog.dart';
import '../../db/camera_table.dart';
import '../../provider/camera_state.dart';
import '../../provider/notification_state.dart';
import '../../screen/navigation/bottom_navigator_view.dart';
import '../../screen/camera/camera_fire_alert_screen.dart';
import '../../screen/camera/camera_motion_alert_screen.dart';
import '../../screen/camera/camera_setting_screen.dart';
import '../../screen/camera/camera_smoke_alert_screen.dart';
import '../../utils/font/font.dart';
import '../main/main_logic.dart';
import '../model/device_model.dart';
import '../settings_alarm/detect_area_draw/detect_area_draw_logic.dart';
import '../settings_alarm/detect_area_draw/detect_area_draw_page.dart';
import '../settings_main/settings_main.dart';
import '../settings_main/settings_main_logic.dart';
import '../settings_main/settings_main_state.dart';
import '../settings_normal/settings_normal_logic.dart';
import '../settings_normal/settings_normal_state.dart';

import '../tf_play/tf_play_logic.dart';
import '../tf_play/tf_play_page.dart';

import '../vstarcam_widget/focal_point_widget.dart';
import '../vstarcam_widget/scale_offset_widget.dart';
import '../vstarcam_widget/virtual_three_view.dart';
import 'app_player_slider.dart';
import 'app_extension.dart';
import 'package:path_provider/path_provider.dart';

import 'play_logic.dart';
import 'play_state.dart';

class PlayerPage extends GetView<PlayLogic> {
  /// ✅ GetX
  final cs = Get.find<CameraState>();
  final ns = Get.put(NotificationState());
  final us = Get.find<UserState>();

  late final PlayLogic logic;
  late final PlayState state;
  late final SettingsNormalState nState;
  late final SettingsNormalLogic nLogic;
  GlobalKey playKey = GlobalKey();


  PlayerPage({super.key});

  /// ✅ 소화장치 눌렀을때 함수
  void pressedFireFightingButton (BuildContext context, int milliseconds) async {

    print("firefight ${cs.fireFightingData['fireFightingStatus']}");
    if (cs.fireFightingData['fireFightingStatus'] == 0) {
      showFireFightingDialog(context, cs.cameraUID.value, cs.cameraName.value, milliseconds);
      return;
    }

    // 완료상태일시 완료 다이얼로그 띄움
    if (cs.fireFightingData.value['fireFightingStatus'] == 2) {
      showFireFightingCompleteDialog(context);
      return;
    }
  }

  /// ✅ 카메라화면 / 메모리카드화면 전환 함수
  void pressedBottomNavigation(int index) {
    if (double.parse(cs.ptzList[0].sourceData!['sdtotal']) > 5.0) {
      if (index == 0 && cs.cameraIndex.value == 1) {
        TFPlayLogic logic = Get.find<TFPlayLogic>();
        logic.pauseVideo();
      }
      cs.cameraIndex.value = index;
    }
  }
  
  /// ✅ 전체화면 기능아이콘 함수
  void pressedFullScreenButton(BuildContext context,int index) {
    switch (index) {
      case 0 :  /// 서치라이트
        pressedSearchLight(); /// ✅ 서치라이트 함수
        break;
      case 1 :  /// 사이렌
        pressedSiren(); /// ✅ 사이렌 함수
        break;
      case 2 :  /// 화면 캡쳐
        pressedCapture(); /// ✅ 캡쳐 함수
        break;
      case 3 :
        break;
      case 4 :  /// 소리 설정
        if (cs.sound_stream_status.value == true || cs.sound_stream_status.value == false) {
          pressedSound(index); /// ✅ 소리 수신 함수
        }
        break;
      case 5 :  /// 전체 화면 해제
        cs.fullScreen.value = !cs.fullScreen.value; /// ✅ 전체화면 해제
        break;
      case 6 :  /// 119 문자신고
        cs.fullScreen.value = !cs.fullScreen.value; /// ✅ 전체화면 해제
        pressedMessageReport(context); /// ✅ 문자신고 함수
        break;
      default :
        break;
    }
  }

  /// ✅ 일반화면 기능아이콘 함수
  void pressedNormalScreenButton(BuildContext context,int index) async{
    switch (index) {
      case 0: // 불꽃 감지
        Get.to(() => CameraFireAlertScreen());
        break;
      case 1: // 연기 감지
        Get.to(() => CameraSmokeAlertScreen());
        break;
      case 2: // 모션 감지
        Get.to(() => CameraMotionAlertScreen());
        break;
      case 3: // 감지 영역
        Get.put<DetectAreaDrawLogic>(DetectAreaDrawLogic());
        Get.to(() => DetectAreaDrawPage());
        break;
      case 5: // 화면 캡쳐
        pressedCaptureAtNormalScreen(); // ✅ 캡쳐 함수 (일반화면)
        break;
      case 6: // 서치 라이트
        pressedSearchLight(); // ✅ 서치라이트 함수
        break;
      case 7: // 사이렌
        pressedSiren(); // ✅ 사이렌 함수
        break;
      case 8: // 119 문자신고꽃
      // 소화장치 0 테스트용 코드
      //   cs.cameraDevice!.writeCgi("trans_cmd_string.cgi?cmd=2109&command=0&alarmLed=0&");
      //   return;
        pressedMessageReport(context); // ✅ 119 문자신고 함수
        break;
      default:
        break;
    }
  }

  /// ✅ 서치라이트 눌렀을때 함수
  void pressedSearchLight() async {
    if (cs.cameraDetailList[0]['searchLight'] == 'false') {
      bool result1 = await DeviceManager.getInstance().mDevice!.lightCommand!.controlLight(true);
      if (result1 == true) {
        await cameraDetailSwitch(cs.cameraUID.value, 'searchLight', 'true');
        final updatedCameraDetailList = [...cs.cameraDetailList];
        cs.cameraDetailList[0]['searchLight'] = 'true';
        cs.cameraDetailList.assignAll(updatedCameraDetailList);
      }
    } else {
      bool result2 = await DeviceManager.getInstance().mDevice!.lightCommand!.controlLight(false);
      if (result2 == true) {
        await cameraDetailSwitch(cs.cameraUID.value, 'searchLight', 'false');
        final updatedCameraDetailList = [...cs.cameraDetailList];
        cs.cameraDetailList[0]['searchLight'] = 'false';
        cs.cameraDetailList.assignAll(updatedCameraDetailList);
      }
    }
  }
  
  /// ✅ 사이렌 눌렀을때 함수
  void pressedSiren() async {
    if (cs.cameraDetailList[0]['siren'] == 'false') {
      bool siren1 = await DeviceManager.getInstance().mDevice!.sirenCommand!.controlSiren(true, timeout: 5);
      if (siren1 == true) {
        await cameraDetailSwitch(cs.cameraUID.value, 'siren', 'true');
        final updatedCameraDetailList = [...cs.cameraDetailList];
        cs.cameraDetailList[0]['siren'] = 'true';
        cs.cameraDetailList.assignAll(updatedCameraDetailList);
      }
    } else {
      bool siren2 = await DeviceManager.getInstance().mDevice!.sirenCommand!.controlSiren(false, timeout: 5);
      if (siren2 == true) {
        await cameraDetailSwitch(cs.cameraUID.value, 'siren', 'false');
        final updatedCameraDetailList = [...cs.cameraDetailList];
        cs.cameraDetailList[0]['siren'] = 'false';
        cs.cameraDetailList.assignAll(updatedCameraDetailList);
      }
    }
  }

  /// ✅ 캡쳐 눌렀을때 함수 (전체화면)
  void pressedCapture() async {
    bool snapBool = await cs.cameraDevice!.writeCgi('snapshot.cgi?res=2');
    if (snapBool) {
      CommandResult result = await cs.cameraDevice!.waitCommandResult((int cmd, Uint8List data) {
        return cmd == 24597;
      }, 5);
      if (Platform.isAndroid) {
        RenderRepaintBoundary boundary = playKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
        double pixelRatio = 5.0;
        ui.Image image = await boundary.toImage(pixelRatio: pixelRatio);
        ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        Uint8List? imageBytes = byteData?.buffer.asUint8List();
        final results2 = await ImageGallerySaverPlus.saveImage(
          imageBytes!,
          quality: 100,
        );
        Get.snackbar("사진이 캡처되었습니다", '사진첩에 들어가 사진을 확인해주세요');
      } else {
        var status = await Permission.storage.status;
        if (!status.isGranted) {
          await Permission.storage.request();
        } else if (status.isGranted) {
          if (Platform.isIOS) {
            Directory? appDocDir = await getApplicationDocumentsDirectory();

            /// 폴더 만들고
            final screenshotsDirectory = Directory('${appDocDir!.path}/Download/screenshots');
            if (!await screenshotsDirectory.exists()) {
              await screenshotsDirectory.create(recursive: true);
            }
            final file = File('${screenshotsDirectory.path}/${DateTime.now()}.jpg');
            file.writeAsBytes(result.data!);
            Get.snackbar("사진이 캡처되었습니다", '사진이 캡처되었습니다');
          }
        }
      }
    }
  }

  /// ✅ 소리 수신 함수
  void pressedSound(int index) async {
    if (state.videoVoiceStop.value) {
      DeviceManager.getInstance().mDevice?.startSoundStream();
      logic.controller?.startVoice();
      state.videoVoiceStop.value = false;

      cs.sound_stream_status.value = false;
      cs.cameraFullIconL[index] = !cs.cameraFullIconL[index];
    } else {
      DeviceManager.getInstance().mDevice?.stopSoundStream();
      logic.controller?.stopVoice();
      state.videoVoiceStop.value = true;

      cs.sound_stream_status.value = true;
      cs.cameraFullIconL[index] = !cs.cameraFullIconL[index];
    }
  }

  /// ✅ 마이크권한 요청 함수
  void requiredMic() {
    Get.snackbar(
      "마이크 권한 허용이 필요합니다",
      '마이크 권한 허용이 필요합니다',
      onTap: (controller) {
        MainLogic logic = Get.find<MainLogic>();
        logic.removeListeners();
        us.bottomIndex.value = 1;
        cs.fullScreen.value = false;
        Get.offAll(() => BottomNavigatorView());
        WidgetsBinding.instance!.addPostFrameCallback((_) {
          openAppSettings();
        });
      },
    );
  }

  /// ✅ 캡쳐 눌렀을때 함수 (일반화면)
  void pressedCaptureAtNormalScreen() async {
    bool snapBool = await cs.cameraDevice!.writeCgi('snapshot.cgi?res=2');
    if (snapBool) {
      CommandResult result = await cs.cameraDevice!.waitCommandResult((int cmd, Uint8List data) {
        return cmd == 24597;
      }, 5);
      if (Platform.isAndroid) {
        captureScreen();
      } else {
        await Permission.photos.request();
        PermissionStatus status = await Permission.photos.status;
        // print('??${status}');
        if (!status.isGranted) {
          openAppSettings();
        } else if (status.isGranted) {
          captureScreen();
        }
      }
    }
  }

  /// ✅ 화면 캡쳐 함수
  Future<void> captureScreen() async {
    RenderRepaintBoundary boundary = playKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    double pixelRatio = 5.0;
    ui.Image image = await boundary.toImage(pixelRatio: pixelRatio);
    ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    Uint8List? imageBytes = byteData?.buffer.asUint8List();
    final results2 = await ImageGallerySaverPlus.saveImage(
      imageBytes!,
      quality: 100,
    );
    Get.snackbar("사진이 캡처되었습니다", '사진첩에 들어가 사진을 확인해주세요');
  }

  /// ✅ 문자신고 함수
  void pressedMessageReport(BuildContext context,{bool setFireStationSend = false}) async {
    showFireStationDialog(context, us.userList[0]['agency'], us.userList[0]['address'], cs.cameraName.value, 'http://mmskorea.com:4014/checkcam/${cs.cameraUID.value}', () async {
      Get.back();
      String phoneNumber = "119";
      String message = Uri.encodeComponent('''
!!! 화재 신고 !!!
안녕하세요!
화재가 발생했으니 아래 현장으로 소방차를 빠르게 출동시켜주시기 바랍니다!

현장명: ${us.userList[0]['agency']}
주소: ${us.userList[0]['address']}, ${us.userList[0]['addressDetail']}
신고자: ${us.userList[0]['name']} ${us.userList[0]['phoneNumber']}
카메라이름: ${cs.cameraName.value}
카메라 영상 실시간보기:
(비밀번호: ${cs.cameraUID.value.substring(0, 10)})
http://mmskorea.com:4014/checkcam/${cs.cameraUID.value}

본 문자는 지능형 화재감지 모니터링 시스템 MMS를 활용한 자동화된 신고입니다. 본 문자를 받은 후 119 출동차량이 화재 현장에 신속하게 이동할 수 있도록 확인해 주시기 바랍니다.

문의: 1522-7688
''');
      String smsUri = "sms:$phoneNumber?body=$message";
      await _launchURL(Uri.parse(smsUri));

      if (setFireStationSend) { /// ✅ 함수화
        ns.fireStationSend.value = true;
      }

      final url = '${config.baseUrl}/notiAdd';
      final body = ({
        "mms": 'noting',
        "title": "119 문자신고",
        "body": "소방서 신고",
        "headDocId": "${us.userList[0]['headDocId']}",
        "cameraUid": "${cs.cameraUID.value}",
        "ipcamId": "${cs.cameraName.value}",
        "num": '9',
        "fieldCheck": '${us.userList[0]['name']}',
        "mmsName": 'nothing',
      });
      await http.post(Uri.parse(url), body: body);
      showOnlyFireStationConfirmDialog(context);
    });
  }

  /// ✅ 문자발송 url함수
  Future<void> _launchURL(Uri url) async {
    if (!await launchUrl(
      url,
      mode: LaunchMode.externalApplication,
    )) {
      throw 'could not launch $url';
    }
  }

  /// ✅ 전체화면 IconColor 반환함수
  Color getFullIconColor(String icon, int index) {
    if (icon == 'mute') {
      return !state.videoVoiceStop.value ? Colors.blue : Colors.white;
    }

    switch (index) {
      case 0: // 서치라이트
        return cs.cameraDetailList[0]['searchLight'] == 'true' ? Colors.blue : Colors.white;
      case 1: // 사이렌
        return cs.cameraDetailList[0]['siren'] == 'true' ? Colors.blue : Colors.white;
      case 5:
        return Colors.white;
      case 6:
        return Colors.red;
      default:
        return cs.cameraFullIconL[index] ? Colors.blue : Colors.white;
    }
  }

  /// ✅ 일반화면 IconColor 반환함수
  Color getNormalIconColor(int index) {
    if (cs.cameraDetailList.isEmpty) return Colors.black;

    switch (index) {
      case 0: // ✅ 불꽃 감지
        return cs.cameraDetailList[0]['fireDetect'] == 'true' ? Colors.blue : Colors.black;
      case 1: // ✅ 연기 감지
        return cs.cameraDetailList[0]['smokeDetect'] == 'true' ? Colors.blue : Colors.black;
      case 2: // ✅ 모션 감지
        return cs.cameraDetailList[0]['motionDetect'] == 'true' ? Colors.blue : Colors.black;
      case 6: // ✅ 서치라이트
        return cs.cameraDetailList[0]['searchLight'] == 'true' ? Colors.blue : Colors.black;
      case 7: // ✅ 사이렌
        return cs.cameraDetailList[0]['siren'] == 'true' ? Colors.blue : Colors.black;
      case 8: // ✅ 119 문자신고
        return Colors.red;
      default:
        return cs.cameraIconL[index] ? Colors.blue : Colors.black;
    }
  }

  @override
  Widget build(BuildContext context) {
    Get.put(TFPlayLogic());

    logic = controller;
    state = logic.state!;
    cs.timeCon.value = ScrollController();
    cs.tfFullScreen.value = false;
    int a = 0;
    /// 25-05-09 작동완료 다이얼로그용 context 상속
    cs.context = context;

    Future<bool> backPress() async {
      await cs.cameraDevice?.deviceDestroy();
      /// 알림에서 들어왔을 떄
      if (ns.cameraNoti.value) {
        print("나니나니나니");
        ns.cameraNoti.value = false;
        if (!Get.isRegistered<MainLogic>()) {
          Get.put(MainLogic());
        }
        Get.put(MainLogic());
        MainLogic logic = Get.find<MainLogic>();
        logic.removeListeners();
        cs.cameraDevice = null;
        us.bottomIndex.value = 2;
        cs.fullScreen.value = false;
        cs.cameraBack.value = true;
        Get.back();
        Get.back();
        return true;
      } else if (cs.fullScreen.value || cs.tfFullScreen.value) {
        cs.fullScreen.value = false;
        cs.tfFullScreen.value = false;
        return false;
      } else if (a == 0) {
        a++;
        print('hey there ----------------- ${a}: ${cs.cameraDevice}');

        await cs.cameraDevice!.deviceDestroy();
        print('hey there ----------------- 11111');

        var camera = cs.cameraDetailSelectList.firstWhere((camera) => camera['cameraUid'] == cs.ptzList[0].deviceid, orElse: () => null);
        if (camera != null) {
          camera['currentFirmware'] = cs.ptzList[0].sys_ver;
        }
        if (camera != null && int.parse('${us.versionList[0]['camera'].split('.').last}') <= int.parse('${camera['currentFirmware'].split('.').last}')) {
          cs.cameraList.removeWhere((data) => data['cameraUid'] == cs.ptzList[0].deviceid);
          cs.cameraDetailSelectList.removeWhere((data) => data['cameraUid'] == cs.ptzList[0].deviceid);
        }
        ns.cameraNoti.value = false;
        if (!Get.isRegistered<MainLogic>()) {
          Get.put(MainLogic());
        }
        MainLogic logic = Get.find<MainLogic>();
        logic.removeListeners();
        cs.cameraDevice = null;
        us.bottomIndex.value = 1;
        cs.fullScreen.value = false;
        cs.tfFullScreen.value = false;
        cs.cameraBack.value = true;

        Get.back();
        return true;
      }
      return true;
    }

    /// ✅ 메인 위젯
    return Obx(() => ConditionalWillPopScope(
          onWillPop: backPress,
          shouldAddCallback: cs.fullScreen.value || cs.tfFullScreen.value ? true : false,
          child: Obx(() => Scaffold(
                appBar: cs.tfFullScreen.value || cs.fullScreen.value
                    ? null
                    : AppBar(
                        backgroundColor: Colors.white,
                        automaticallyImplyLeading: false,
                        centerTitle: false,

                        /// ✅ Camera Name
                        title: Text(
                          '${cs.cameraName.value}',
                          style: f16w700Size(),
                        ),
                      ),
                backgroundColor: Colors.white,
                body: cs.fullScreen.value
                    /// ✅ 전체화면 페이지
                    ? buildSinglePlayWidget(context)

                    : !cs.tfFullScreen.value
                        ? // 메모리 카드 재생 에서 전체 화면 일 때 스크롤 삭제 위함
                        /// ✅ 일반화면 페이지
                        CustomScrollView(
                            slivers: [SliverFillRemaining(hasScrollBody: false, child: cs.cameraIndex.value == 0 ? buildSinglePlayWidget(context) : _MemoryPage(context))],
                          )
                        /// ✅ 메모리카드 페이지
                        : _MemoryPage(context),

              )),
        ));
  }

  /// ✅ 카메라 페이지 ---- 单目(단일렌즈?)
  Widget buildSinglePlayWidget(BuildContext context) {
    TransformationController ScaleController = TransformationController();
    final cs = Get.find<CameraState>();
    final ns = Get.put(NotificationState());
    final config = AppConfig();

    return Obx(() => cs.fullScreen.value
        /// ✅ 전체화면 구성
        ? Center(
            child: InteractiveViewer(
              transformationController: ScaleController,
              minScale: 1.0,
              maxScale: 4.0,
              onInteractionUpdate: (details) {
                if (details.scale > 1.0) {
                  cs.cameraDetailScale.value = details.scale;
                  cs.cameraIconVisible.value = false;
                } else if (details.scale < 1.0) {
                  cs.cameraDetailScale.value = 1.0;
                  cs.cameraIconVisible.value = true;
                } else {}
              },
              child: Stack(
                children: [
                  Container(
                    color: Colors.black,
                    width: Get.width,
                    height: Get.height,
                  ),
                  /// ✅ 카메라 화면
                  Center(
                    child: FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        height: Get.height * 0.84,
                        width: Get.width,
                        child: RotatedBox(
                          quarterTurns: 1,
                          child: RepaintBoundary(
                            key: playKey,
                            child: AppPlayerView(
                              controller: logic.controller!,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  /// ✅ 좌측 아이콘
                  // Positioned(
                  //     top: Get.height * 0.1,
                  //     right: Get.width * 0.3,
                  //     child: Visibility(
                  //       visible: cs.cameraIconVisible.value,
                  //       child: RotatedBox(
                  //         quarterTurns: 1,
                  //         child: Column(
                  //           children: [
                  //             /// ✅ 서치라이트
                  //             _cameraFullScreenIcons(context, 'light', 0),
                  //             const SizedBox(
                  //               height: 20,
                  //             ),
                  //             /// ✅ 사이렌
                  //             _cameraFullScreenIcons(context, 'alert', 1),
                  //             const SizedBox(
                  //               height: 20,
                  //             ),
                  //             /// ✅ 119신고
                  //             _cameraFullScreenIcons(context, '119', 6),
                  //           ],
                  //         ),
                  //       ),
                  //     )),
                  // /// ✅ 우측 아이콘
                  Positioned(
                      bottom: Get.height * 0.1,
                      right: Get.width * 0.1,
                      child: Visibility(
                        visible: cs.cameraIconVisible.value,
                        child: RotatedBox(
                          quarterTurns: 1,
                          child: Column(
                            children: [
                              // /// ✅ 캡쳐
                              // _cameraFullScreenIcons(context, 'capture', 2),
                              // const SizedBox(
                              //   height: 20,
                              // ),
                              // /// ✅ 마이크
                              // _cameraFullScreenIcons(context, 'mic', 3),
                              // const SizedBox(
                              //   height: 20,
                              // ),
                              // /// ✅ 소리
                              // _cameraFullScreenIcons(context, 'mute', 4),
                              // const SizedBox(
                              //   height: 20,
                              // ),
                              /// ✅ 화면축소 (일반화면 전환)
                              _cameraFullScreenIcons(context, 'minimize', 5),
                            ],
                          ),
                        ),
                      )),
                ],
              ),
            ),
          )
        /// ✅ 일반화면 구성
        : Column(
            children: [
              Container(
                color: Colors.black,
                height: 250,
                child: Stack(
                  children: [
                    /// ✅ 카메라 화면
                    Center(
                      child: RepaintBoundary(
                        key: playKey,
                        child: AspectRatio(
                          aspectRatio: 16 / 9,
                          child: AppPlayerView(
                            controller: logic.controller!,
                          ),
                        ),
                      ),
                    ),

                    ///로딩중
                    //StartingWaveWidget(state: state),
                    /// ✅ 카메라 하단바 (시작버튼, 소리버튼, 전체화면버튼)
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        color: Colors.black54,
                        child: Row(
                          children: [
                            /// ✅ 시작,중지 버튼
                            buildStartButton(logic, state),
                            /// ✅ 소리버튼
                            buildVoiceButton(logic, state),
                            const Spacer(),
                            /// ✅ 전체화면버튼
                            IconButton(
                              icon: const Icon(Icons.fullscreen),
                              color: Colors.white,
                              onPressed: () {
                                cs.fullScreen.value = !cs.fullScreen.value;
                              },
                            )
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              /// ✅ 아이콘 모음
              ns.cameraNoti.value
                  /// ✅ fcm알림 || 알림내역에서 들어왔을때 (아이콘3개만 표시)
                  ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 30),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _CameraIcons(context, 'mic', '카메라 통화', 4),
                              _CameraIcons(context, 'light', '서치 라이트', 6),
                              _CameraIcons(context, 'alert', '사이렌', 7),
                            ],
                          ),
                        ],
                      ),
                    )
                  /// ✅ 그 외 모든 카메라아이콘 표시
                  : Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TextButton(
                            onPressed: () {
                              // 화재감지 버튼 클릭 시 처리
                              showConfirmTapDialog(
                                context,
                                "서버로 전송 하시겠습니까?",
                                    () async {
                                  DialogManager.showLoading(context);
                                  await completeAgentWork(null, 0);
                                  DialogManager.hideLoading();
                                  Get.back();
                                  Get.back();
                                  //Get.offAll(() => AlimScreen());
                                },
                              ); // ✅ 화재감지 버튼 함수
                            },
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              ns.notificationData['type'] == '6' ? '화재감지' : '연기감지',
                            ),
                          ),
                          SizedBox(width: 16),
                          TextButton(
                            onPressed: () {
                              // 오탐 버튼 클릭 시 처리
                              showAlimCheckTapDialog(context, "");
                            },
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.grey,        // 배경색
                              foregroundColor: Colors.white,       // 텍스트 색
                              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text('오탐'),
                          ),
                        ],
                      ),
                    ],
                  )
              ),

              /// ✅ 여백
              ns.cameraNoti.value
                  ? const SizedBox(
                      height: 24,
                    )
                  : const SizedBox.shrink(),

              /// ✅ 119신고 주의문구
              ns.cameraNoti.value
                  ? Column(
                      children: [
                        RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: '실시간 영상을 통해 화재가 확인되었다면,\n\n아래 버튼을 눌러 ',
                                style: f14w700Size(),
                              ),
                              TextSpan(
                                text: '119 문자신고',
                                style: f14w700Size().copyWith(color: Colors.red),
                              ),
                              TextSpan(
                                text: '를 진행해주세요\n',
                                style: f14w700Size(),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(
                          height: 8,
                        ),
                        Text(
                          '(119 허위 신고는 119구조ㆍ구급에 관한 법률  제30조에 의해 처벌될 수 있습니다.)',
                          style: f14wSky700Size(),
                          textAlign: TextAlign.center,
                        )
                      ],
                    )
                  : const SizedBox.shrink(),

              /// ✅ 여백
              ns.cameraNoti.value
                  ? const SizedBox(
                      height: 24,
                    )
                  : const SizedBox.shrink(),

              /// ✅ 문자신고 버튼
              ns.cameraNoti.value
                  ? ElevatedButton.icon(
                      onPressed: () {
                        if (ns.fireStationSend.value) {
                          return;
                        }
                        pressedMessageReport(context,setFireStationSend : true); /// ✅ 문자신고 함수
                      },
                      icon: Image.asset(
                        'assets/camera_icon/119.png',
                        width: 50,
                        height: 50,
                        color: Colors.white,
                      ),
                      label: Text(
                        '문자 신고',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.black,
                        backgroundColor: ns.fireStationSend.value ? Colors.grey[300] : Colors.red,
                        minimumSize: const Size(200, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
              
              const SizedBox(height: 40),
            ],
          ));
  }

  /// 전체 화면 (아이콘)
  Widget _cameraFullScreenIcons(BuildContext context, String icon, int index) {
    final cs = Get.find<CameraState>();
    return GestureDetector(
      onTap: () async {
        pressedFullScreenButton(context,index); /// ✅ 전체화면 버튼 함수
      },

      /// 마이크
      onLongPressStart: (details) async { /// ✅ 꾹눌렀을때
        var status = await Permission.microphone.request();

        /// ✅ 권한 필요할시
        if (!status!.isGranted) {
          requiredMic(); // 마이크권한 요청
        } else if (index == 3) {
          SettingsMainLogic sLogic = Get.find<SettingsMainLogic>();
          sLogic.startTalk(); // 마이크 송신 시작
          cs.cameraFullIconL[index] = !cs.cameraFullIconL[index];
        }
      },
      onLongPressEnd: (details) { /// ✅ 누르는걸 끝냈을때
        if (index == 3) {
          SettingsMainLogic sLogic = Get.find<SettingsMainLogic>();
          sLogic.stopTalk(); // 마이크 송신 중단
          cs.cameraFullIconL[index] = !cs.cameraFullIconL[index];
        }
      },

      /// ✅ 전체화면 아이콘들
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(100),
              border: Border.all(color: getFullIconColor(icon, index)),
            ),
            child: icon == 'mute'
            /// ✅ 소리 아이콘은 따로표시
                ? Icon(
              !state.videoVoiceStop.value ? Icons.volume_up : Icons.volume_off,
              size: 40,
              color: getFullIconColor(icon, index),
            )
            /// ✅ 그외 아이콘
                : Image.asset(
              'assets/camera_icon/$icon.png',
              width: 40,
              height: 40,
              color: getFullIconColor(icon, index),
            ),
          ),
        ],
      ),
    );
  }

  /// 일반 화면 (아이콘)
  Widget _CameraIcons(BuildContext context, String icon, String title, int index) {
    final cs = Get.find<CameraState>();
    return GestureDetector(
      onTap: () async {
        pressedNormalScreenButton(context,index); /// ✅ 일반화면 버튼 함수
      },

      /// ✅ 마이크 꾹 눌렀을때
      onLongPressStart: (details) async {
        if (index == 4) {
          var status = await Permission.microphone.status;

          if (!status.isGranted) {
            await Permission.microphone.request();
            Get.snackbar(
              "마이크 권한 허용이 필요합니다",
              '마이크 권한 허용이 필요합니다',
              onTap: (controller) {
                MainLogic logic = Get.find<MainLogic>();
                logic.removeListeners();
                us.bottomIndex.value = 1;
                cs.fullScreen.value = false;
                Get.offAll(() => BottomNavigatorView());
                WidgetsBinding.instance!.addPostFrameCallback((_) {
                  openAppSettings();
                });
              },
            );
          } else {
            SettingsMainLogic sLogic = Get.find<SettingsMainLogic>();
            sLogic.startTalk(); // 마이크 송신 시작
            print("송신시작??");
            cs.cameraIconL[index] = !cs.cameraIconL[index];
          }
        }
      },

      /// ✅ 마이크 버튼 뗏을때
      onLongPressEnd: (details) async {
        // 마이크송신 중단
        if (index == 4) {
          final status = await Permission.microphone.status;

          if (status.isGranted) {
            SettingsMainLogic sLogic = Get.find<SettingsMainLogic>();
            sLogic.stopTalk();
            cs.cameraIconL[index] = !cs.cameraIconL[index];
            print("송신끝??");
          }
        }
      },

      /// ✅ 일반화면 아이콘들
      child: Column(
        children: [
          Obx(
            () => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: index == 8 ? BorderRadius.zero : BorderRadius.circular(100),
                border: Border.all(color: getNormalIconColor(index)),
              ),
              child: Image.asset(
                'assets/camera_icon/$icon.png',
                width: 40,
                height: 40,
                color: getNormalIconColor(index),
              ),
            ),
          ),
          const SizedBox(
            height: 4,
          ),
          Text(
            '$title',
            style: (() {
              if (index == 0 && cs.cameraDetailList[0]['fireDetect'] == 'true') {
                return f14w700CameraBlueSize();
              } else if (index == 1 && cs.cameraDetailList[0]['smokeDetect'] == 'true') {
                return f14w700CameraBlueSize();
              } else if (index == 2 && cs.cameraDetailList[0]['motionDetect'] == 'true') {
                return f14w700CameraBlueSize();
              } else if (index == 6 && cs.cameraDetailList[0]['searchLight'] == 'true') {
                return f14w700CameraBlueSize();
              } else if (index == 7 && cs.cameraDetailList[0]['siren'] == 'true') {
                return f14w700CameraBlueSize();
              } else {
                if (cs.cameraIconL[index]) {
                  return f14w700CameraBlueSize();
                } else {
                  return f14w700;
                }
              }
            })(),
            // style: f14w700,
          ),
        ],
      ),
    );
  }

  /// 메모리카드 페이지
  Widget _MemoryPage(BuildContext context) {
    return Container(width: Get.width, height: Get.height, child: TFPlayPage());
  }

  /// ✅ 일반화면 - 카메라 재생/정지 버튼
  Widget buildStartButton(PlayLogic logic, PlayState state) {
    return ObxValue<RxBool>((data) {
      if (data.value == true) {
        return IconButton(
          icon: const Icon(Icons.play_arrow),
          color: Colors.white,
          onPressed: () async {
            logic.startVideo();
          },
        );
      } else {
        return IconButton(
          icon: const Icon(Icons.stop),
          color: Colors.white,
          onPressed: () async {
            logic.stopPlay();
          },
        );
      }
    }, state.videoStop);
  }

  /// ✅ 일반화면 - 카메라소리 수신/차단 버튼
  Widget buildVoiceButton(PlayLogic logic, PlayState state) {
    return ObxValue<RxBool>((data) {
      if (data.value) {
        return IconButton(
          icon: const Icon(Icons.volume_off),
          color: Colors.white,
          onPressed: () {
            DeviceManager.getInstance().mDevice?.startSoundStream();
            logic.controller?.startVoice();
            state.videoVoiceStop.value = false;

            ///保存静音状态
            DeviceManager().setMonitorState(false);
          },
        );
      } else {
        return IconButton(
          icon: const Icon(Icons.volume_up),
          color: Colors.white,
          onPressed: () {
            SettingsMainLogic settingsLogic = Get.find<SettingsMainLogic>();
            if (settingsLogic.state?.voiceState.value == VoiceState.play) {
              EasyLoading.showToast("대화 중이라 음성을 끌 수 없습니다");
              return;
            }
            DeviceManager.getInstance().mDevice?.stopSoundStream();
            logic.controller?.stopVoice();
            state.videoVoiceStop.value = true;
          },
        );
      }
    }, state.videoVoiceStop);
  }

  /// 소방장치 아이콘
  Widget FireExtinguisherIcon(BuildContext context) {
    final isFireFightComplete = cs.fireFightingData['fireFightingStatus'] == 2;

    return Row(
      // mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children : [
        /// 소방장치 아이콘
        Column(
          children: [
            GestureDetector(
              onTap: () async {
                pressedFireFightingButton(context, 4500);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                decoration: BoxDecoration(
                  border: Border.all(
                     color: isFireFightComplete
                         ?
                         Colors.grey
                         :
                         Colors.red,
                  width: 1
                  ),
                ),
                child: Image.asset(
                  width: 40,
                  height: 40,
                  'assets/camera_icon/fire_fighting.png', // 소화기 아이콘
                  color: isFireFightComplete
                      ?
                      Colors.grey
                      :
                      Colors.red,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text("소화장치 작동", style: f14w700)
          ],
        ),
        /// 소화장치 작동 아이콘
        if (cs.fireFightingData['fireFightingStatus'] != 0)
              Firefightingicon(),

        ///화면 갱신용.... 더미
        if(cs.test.value)
          Text("",style: f14w700)
      ]
    );
  }

  ///三目或假三目 /// ✅ 쓰는페이지 없음
// Widget buildThreePlay(BuildContext context) {
//   double width = MediaQuery.of(context).size.width / 2 - 5;
//   double height = width * 9 / 16;
//   bool split = DeviceManager.getInstance().deviceModel?.splitScreen.value == 1;
//   return ObxValue<RxInt>((data) {
//     return data.value == 2 || (data.value == 1 && split)
//         ? Column(
//             children: [
//               SizedBox(height: 10),
//               Text("追踪球机"),
//               SizedBox(height: 10),
//               AspectRatio(
//                 aspectRatio: 16 / 9, //横纵比 长宽比 16 : 9
//                 child: Stack(
//                   children: [
//                     InkWell(
//                         onTap: () {
//                           ///点击了球机
//                           state.select(0);
//                         },
//                         child: ObxValue<RxInt>((data) {
//                           return Container(
//                             decoration: BoxDecoration(border: data.value == 0 ? Border.all(color: Colors.red, width: 2) : null),
//                             child: AppPlayerView(
//                               controller: state.playerController!,
//                             ),
//                           );
//                         }, state.select)),
//                     Align(
//                       alignment: Alignment.bottomCenter,
//                       child: Container(
//                         color: Colors.black54,
//                         child: Row(
//                           children: [
//                             buildStartButton(logic, state),
//                             buildPlayButton(logic, state),
//                             buildVoiceButton(logic, state),
//                           ],
//                         ),
//                       ),
//                     ),
//                     RecordProgressWidget(state: state)
//                   ],
//                 ),
//               ),
//               SizedBox(height: 10),
//               Text("全景枪机"),
//               SizedBox(height: 10),
//               Row(
//                 children: [
//                   InkWell(
//                     onTap: () {
//                       ///点击第一个枪机
//                       state.select(1);
//                     },
//                     child: ObxValue<RxInt>((data) {
//                       return Container(
//                         width: width,
//                         decoration: BoxDecoration(border: data.value == 1 ? Border.all(color: Colors.red, width: 2) : null),
//                         child: AspectRatio(
//                             aspectRatio: 16 / 9, //横纵比 长宽比 16 : 9
//                             child: split
//                                 ? ScaleOffsetView(
//                                     notifier: logic.videoScaleNotifierFirst!,
//                                     supportBinocular: DeviceManager.getInstance().deviceModel!.supportBinocular.value,
//                                     child: VirtualThreeView(
//                                       child: AppPlayerView(
//                                         controller: state.player2Controller!, //假三目
//                                       ),
//                                       alignment: Alignment.centerLeft,
//                                       width: width,
//                                       height: height,
//                                     ),
//                                   )
//                                 : ScaleOffsetView(
//                                     notifier: logic.videoScaleNotifierFirst!,
//                                     supportBinocular: DeviceManager.getInstance().deviceModel!.supportBinocular.value,
//                                     child: AppPlayerView(
//                                       controller: state.player2Controller!, //真三目
//                                     ),
//                                   )),
//                       );
//                     }, state.select),
//                   ),
//                   SizedBox(width: 10),
//                   InkWell(
//                     onTap: () {
//                       ///点击了第二个枪机
//                       state.select(2);
//                     },
//                     child: ObxValue<RxInt>((data) {
//                       return Container(
//                         width: MediaQuery.of(context).size.width / 2 - 5,
//                         decoration: BoxDecoration(border: data.value == 2 ? Border.all(color: Colors.red, width: 2) : null),
//                         child: AspectRatio(
//                             aspectRatio: 16 / 9, //横纵比 长宽比 16 : 9
//                             child: split
//                                 ? ScaleOffsetView(
//                                     notifier: logic.videoScaleNotifierSecond!,
//                                     supportBinocular: DeviceManager.getInstance().deviceModel!.supportBinocular.value,
//                                     child: VirtualThreeView(
//                                       child: AppPlayerView(
//                                         controller: state.player2Controller!, //假三目
//                                       ),
//                                       alignment: Alignment.centerRight,
//                                       width: width,
//                                       height: height,
//                                     ),
//                                   )
//                                 : ScaleOffsetView(
//                                     notifier: logic.videoScaleNotifierSecond!,
//                                     supportBinocular: DeviceManager.getInstance().deviceModel!.supportBinocular.value,
//                                     child: AppPlayerView(
//                                       controller: state.player3Controller!, //真三目
//                                     ),
//                                   )),
//                       );
//                     }, state.select),
//                   )
//                 ],
//               ),
//               SizedBox(height: 20),
//               ScaleButtonWidget(logic: logic),
//               Container(
//                   height: MediaQuery.of(context).size.height - MediaQuery.of(context).size.width * 9 / 16 - MediaQuery.of(context).size.width / 2 * 9 / 16 - MediaQuery.of(context).padding.top - 180,
//                   child: SingleChildScrollView(child: SettingsMain()))
//             ],
//           )
//         : Container();
//   }, state.hasSubPlay);
// }

  ///双目 /// ✅ 쓰는페이지 없음
// Widget buildTwoPlay(BuildContext context) {
//   double width = MediaQuery.of(context).size.width;
//   return ObxValue<RxInt>((data) {
//     if (data.value == 1) {
//       return Column(
//         children: [
//           Text("追踪球机"),
//           Container(
//             color: Colors.black,
//             height: 250,
//             child: Stack(
//               children: [
//                 Center(
//                   child: AspectRatio(
//                     aspectRatio: 16 / 9, //横纵比 长宽比 16 : 9
//                     child: AppPlayerView(
//                       controller: logic.controller!,
//                     ),
//                   ),
//                 ),
//
//                 ///视频加载中
//                 StartingWaveWidget(state: state),
//                 Align(
//                   alignment: Alignment.bottomCenter,
//                   child: Container(
//                     color: Colors.black54,
//                     child: Row(
//                       children: [
//                         buildStartButton(logic, state),
//                         buildPlayButton(logic, state),
//                         buildVoiceButton(logic, state),
//                       ],
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           Text("全景枪机"),
//           Stack(
//             children: [
//               AspectRatio(
//                 aspectRatio: 16 / 9, //横纵比 长宽比 16 : 9
//                 child: AppPlayerView(
//                   controller: state.player2Controller!,
//                 ),
//               ),
//               ObxValue<RxBool>((data) {
//                 return data.value
//                     ? Visibility(
//                     visible: (DeviceManager.getInstance().deviceModel!.supportPinInPic.value == 1 || DeviceManager.getInstance().deviceModel!.supportMutilSensorStream.value == 1),
//                     child: FocalPointWidget(
//                       width / 2,
//                       width * 9 / 16 / 2 - 20,
//                       Colors.red,
//                       onDragEndListener: (x, y) {
//                         logic.linkable(x, y);
//                       },
//                     ))
//                     : SizedBox();
//               }, state.isLinkableOpen),
//             ],
//           ),
//           SizedBox(height: 10),
//           Container(
//             height: MediaQuery.of(context).size.height - MediaQuery.of(context).size.width * 9 / 16 * 2 - MediaQuery.of(context).padding.top - 150,
//             child: SingleChildScrollView(
//               child: SettingsMain(),
//             ),
//           )
//         ],
//       );
//     } else {
//       return Container();
//     }
//   }, state.hasSubPlay);
// }

  /// ✅ 쓰는페이지 없음
// Widget buildPlayButton(PlayLogic logic, PlayState state) {
//   return ObxValue<RxBool>((data) {
//     if (data.value == true) {
//       return IconButton(
//         icon: Icon(Icons.play_circle_outline),
//         color: Colors.white,
//         onPressed: () {
//           logic.controller?.resume();
//           state.videoPause.value = false;
//         },
//       );
//     } else {
//       return IconButton(
//         icon: Icon(Icons.pause_circle_outline),
//         color: Colors.white,
//         onPressed: () {
//           logic.controller?.pause();
//           state.videoPause.value = true;
//         },
//       );
//     }
//   }, state.videoPause);
// }
}

/// ✅ 카메라 로딩? 위젯 (왠지 모르겠는데 제대로 작동안함)
class StartingWaveWidget extends StatelessWidget {
  const StartingWaveWidget({
    super.key,
    required this.state,
  });

  final PlayState state;

  @override
  Widget build(BuildContext context) {
    return ObxValue<Rx<VideoStatus>>((data) {
      if (data.value == VideoStatus.STARTING) {
        print('data value check : ${data.value}');

        return Center(
            child: SpinKitWave(
              color: Colors.white,
              size: 32,
            ));
      } else {
        return const SizedBox.shrink();
      }
    }, state.videoStatus);
  }
}

/// ✅ 안사용하는 위젯들
//
// class ScaleButtonWidget extends StatelessWidget {
//   const ScaleButtonWidget({
//     super.key,
//     required this.logic,
//   });
//
//   final PlayLogic logic;
//
//   @override
//   Widget build(BuildContext context) {
//     return ObxValue<RxInt>((data) {
//       return data.value == 0
//           ? SizedBox()
//           : Row(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 InkWell(
//                     onTap: () {
//                       logic.addScaleOffset();
//                     },
//                     child: Text("   +   ")),
//                 Text("  变倍  "),
//                 InkWell(
//                     onTap: () {
//                       logic.reduceScaleOffset();
//                     },
//                     child: Text("   -   ")),
//               ],
//             );
//     }, logic.state!.select);
//   }
// }
//
// class ReConnectWidget extends StatelessWidget {
//   const ReConnectWidget({
//     super.key,
//     required this.logic,
//     required this.deviceModel,
//   });
//
//   final PlayLogic logic;
//   final DeviceModel? deviceModel;
//
//   void _attemptReconnect(BuildContext context) {
//     final MainLogic mainLogic = Get.find<MainLogic>();
//     final PlayLogic playLogic = Get.find<PlayLogic>();
//
//     print('device name check : ${DeviceManager.getInstance().mDevice!}');
//
//     mainLogic.connectDevice(DeviceManager.getInstance().mDevice!).then((v) {
//       print('offline connect device $v');
//       if (v) {
//         print("connected");
//         playLogic.start(DeviceManager.getInstance().mDevice!);
//         playLogic.controller?.start();
//         deviceModel!.connectState.value = DeviceConnectState.connected;
//       }
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return ObxValue<Rx<DeviceConnectState>>((data) {
//       print('data check : ${data.value}');
//       if (data.value == DeviceConnectState.disconnect || data.value == DeviceConnectState.timeout) {
//         return Center(
//             child: InkWell(
//           onTap: () {
//             ///重新连接
//             MainLogic mainLogic = Get.find<MainLogic>();
//             mainLogic.connectDevice(DeviceManager.getInstance().mDevice!).then((v) {
//               if (v) {
//                 _attemptReconnect(context);
//               }
//             });
//           },
//           child: Container(
//             color: Colors.white,
//             padding: EdgeInsets.all(6),
//             child: Text("로딩중입니다 잠시만 기다려주세요", style: TextStyle(color: Colors.blue)),
//           ),
//         ));
//       } else if (data.value == DeviceConnectState.offline) {
//         return Center(
//             child: InkWell(
//           onTap: () {
//             _attemptReconnect(context);
//           },
//           child: Container(
//             color: Colors.white,
//             padding: EdgeInsets.all(6),
//             child: Text("Camera Offline", style: TextStyle(color: Colors.blue)),
//           ),
//         ));
//       } else {
//         return SizedBox();
//       }
//     }, deviceModel!.connectState);
//   }
// }
//
// class RecordProgressWidget extends StatelessWidget {
//   const RecordProgressWidget({
//     super.key,
//     required this.state,
//   });
//
//   final PlayState state;
//
//   @override
//   Widget build(BuildContext context) {
//     return ObxValue<RxBool>((data) {
//       return Visibility(
//         visible: data.value,
//         child: ObxValue<RxInt>((data) {
//           return Align(
//             alignment: Alignment.bottomRight,
//             child: Container(
//               color: Colors.white,
//               child: Text("正在录制中。。。 ${data.value}  ", style: TextStyle(color: Colors.red)),
//             ),
//           );
//         }, state.recordProgress),
//       );
//     }, state.videoRecord);
//   }
// }
//
// class ProgressBar extends StatefulWidget {
//   const ProgressBar({required Key key, required this.controller}) : super(key: key);
//   final AppPlayerController controller;
//
//   _ProgressBarState createState() => _ProgressBarState();
// }
//
// class _ProgressBarState extends State<ProgressBar> {
//   int totalSec = 0, playSec = 0, loadProgress = 0, loadState = 0, velocity = 0;
//   final cs = Get.put(CameraState());
//   final ns = Get.put(NotificationState());
//
//   void progressCallback(userData, totalSec, playSec, loadProgress, loadState, velocity) {
//     print("11totalSec:$totalSec playSec:$playSec loadProgress:$loadProgress loadState:$loadState velocity:$velocity ");
//     setState(() {
//       this.totalSec = totalSec;
//       this.playSec = playSec;
//       this.loadProgress = loadProgress;
//       this.loadState = loadState;
//       this.velocity = velocity;
//     });
//   }
//
//   @override
//   void initState() {
//     widget.controller.addProgressChangeCallback(progressCallback);
//     super.initState();
//   }
//
//   @override
//   void dispose() async {
//     widget.controller.removeProgressChangeCallback(progressCallback);
//     cs.fireExtinguisher.value = false; // 소방장치 초기화
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     var sliderTheme = SliderTheme.of(context).copyWith(
//         trackHeight: 2,
//         overlayShape: const RoundSliderOverlayShape(overlayRadius: 0),
//         tickMarkShape: const RoundSliderTickMarkShape(tickMarkRadius: 0),
//         thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6));
//
//     var textStyle = TextStyle(fontSize: 10.0, color: Colors.white);
//     int value = playSec;
//     int total = totalSec;
//     var startText = "${(value ~/ 60).toStringDigits(2)}:${(value % 60).toStringDigits(2)}";
//     var endText = "${(total ~/ 60).toStringDigits(2)}:${(total % 60).toStringDigits(2)}";
//     double loadProgress = this.loadProgress / 100;
//     return SliderTheme(
//       data: sliderTheme,
//       child: Container(
//         height: 30,
//         child: Row(
//           children: <Widget>[
//             Container(
//               width: 40,
//               alignment: Alignment.center,
//               child: Text(startText, style: textStyle),
//             ),
//             Expanded(
//               child: Stack(
//                 children: [
//                   Padding(
//                     padding: EdgeInsets.only(left: 2, right: 8),
//                     child: Center(
//                       child: LinearProgressIndicator(
//                         value: loadProgress,
//                         valueColor: AlwaysStoppedAnimation(Colors.white),
//                       ),
//                     ),
//                   ),
//                   AppPlayerSlider(
//                     totalValue: totalSec ~/ (loadProgress == 0 ? 1 : loadProgress),
//                     currentValue: playSec,
//                     onChanged: (change) {
//                       widget.controller.setProgress(change.toInt());
//                     },
//                   ),
//                   // ///视频加载中
//                   // StartingWaveWidget(state: widget.controller.state),
//                 ],
//               ),
//             ),
//             Container(
//               width: 40,
//               alignment: Alignment.center,
//               child: Text(endText, style: textStyle),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
