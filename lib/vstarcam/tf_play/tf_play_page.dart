import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:intl/intl.dart';
import 'package:mms/vstarcam/tf_play/tf_play_state.dart';
import 'package:path_provider/path_provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:vsdk/app_player.dart';
import 'package:vsdk/camera_device/commands/card_command.dart';
import '../../components/dialog.dart';
import '../../components/updateVersion.dart';
import '../../provider/camera_state.dart';
import '../../utils/font/font.dart';
import '../../utils/device_manager.dart';
import '../../utils/permission_handler/permission_handler.dart';
import '../model/record_file_model.dart';
import '../model/timeData.dart';
import '../vstarcam_widget/tf_scroll_view/tf_scroll_view.dart';
import '../vstarcam_widget/virtual_three_view.dart';
import 'tf_pause_icon.dart';
import 'tf_play_logic.dart';

class TFPlayPage extends GetView<TFPlayLogic> {
  @override
  Widget build(BuildContext context) {
    GlobalKey _boundKey = GlobalKey();
    final cs = Get.find<CameraState>();
    TFPlayLogic tfPlayLogic = Get.find<TFPlayLogic>();
    TFPlayLogic logic = controller;
    TFPlayState state = logic.state!;
    int splitScreen = DeviceManager.getInstance().deviceModel?.splitScreen.value ?? 0;
    double width = MediaQuery.of(context).size.width / 2 - 5;
    double height = width * 9 / 16;

    /// 선택한 시간 구함
    void _updateTime() {
      double viewWidth = Get.width * 0.25;
      int hourIndex = ((cs.timeCon.value.offset + Get.width / 2) / viewWidth).floor() % 24;
      int minutes = 60 * ((cs.timeCon.value.offset + Get.width / 2) % viewWidth) ~/ viewWidth;
      cs.timeLineValue.value = "$hourIndex:${minutes.toString().padLeft(2, '0')}";
      DateTime currentDate = DateTime.parse(cs.cameraTfDate.value);
      DateTime nows = DateTime.now();

      /// 23시에서 00시로 가면 하루증가
      /// 00시에서 23시로 가면 하루감소
      if (cs.previousHour.value == 23 && hourIndex == 0) {
        if (!(currentDate.year == nows.year && currentDate.month == nows.month && currentDate.day == nows.day)) {
          currentDate = currentDate.add(Duration(days: 1)); // 날짜를 하루 증가시킴
          cs.cameraTfDate.value = '${DateFormat('y-MM-dd').format(currentDate)}';
          // cs.cameraTfDate.value  = '2024-04-20';
          cs.previousHour.value = hourIndex;

          TFPlayLogic tfPlayLogic = Get.find<TFPlayLogic>();
          tfPlayLogic.getDateRecordFile();
        }
      } else if (cs.previousHour.value == 0 && hourIndex == 23) {
        currentDate = currentDate.subtract(Duration(days: 1)); // 날짜를 하루 감소시킴
        cs.cameraTfDate.value = '${DateFormat('y-MM-dd').format(currentDate)}';
        cs.previousHour.value = hourIndex;
        TFPlayLogic tfPlayLogic = Get.find<TFPlayLogic>();
        tfPlayLogic.getDateRecordFile();
      }

      /// 스크롤이 오른쪽 끝에 닿았을 때 실행되는 코드
      else if (cs.nextFirst.value && cs.timeCon.value.position.pixels >= cs.timeCon.value.position.maxScrollExtent - 10) {
        if (currentDate.year == nows.year && currentDate.month == nows.month && currentDate.day == nows.day - 1) {
          cs.nextFirst.value = false;
          DateTime newDate = currentDate.add(Duration(days: 1));
          List<DateTime> newHourList = List.generate(26, (index) => DateTime(newDate.year, newDate.month, newDate.day, index));
          cs.hourList.value = [...cs.hourList, ...newHourList];
        } else if (!(currentDate.year == nows.year && currentDate.month == nows.month && currentDate.day == nows.day)) {
          cs.nextFirst.value = false;
          DateTime newDate = currentDate.add(Duration(days: 1));
          List<DateTime> newHourList = List.generate(24, (index) => DateTime(newDate.year, newDate.month, newDate.day, index));
          cs.hourList.value = [...cs.hourList, ...newHourList];
        }
      }

      /// 스크롤이 왼쪽 끝에 닿았을 때
      else if (cs.nextFirst.value && cs.timeCon.value.offset <= cs.timeCon.value.position.minScrollExtent && !cs.timeCon.value.position.outOfRange) {
        cs.nextFirst.value = false;
        DateTime newDate = currentDate.subtract(Duration(days: 1));
        List<DateTime> newHourList = List.generate(24, (index) => DateTime(newDate.year, newDate.month, newDate.day, index));
        cs.hourList.value = [...newHourList, ...cs.hourList];
        Timer(Duration(milliseconds: 1), () => cs.timeCon.value.jumpTo(24 * Get.width * 0.25));
      } else {
        cs.nextFirst.value = true;
        cs.previousHour.value = hourIndex;
      }
    }

    cs.timeCon.value.addListener(() {
      _updateTime();
    });

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      ///처음 한번 실행됬을 때
      if (cs.timeFirst.value == false) {
        DateTime select = DateTime.parse(cs.cameraTfDate.value);
        DateTime newDate = select.add(Duration(days: 1));
        List<DateTime> oldHourList = List.generate(26, (index) => DateTime(select.year, select.month, select.day, index));
        cs.hourList.value = [...oldHourList];

        /// ✅ 가져온 recordFiles의 제일 최근시간으로 타임라인 이동
        // print("state.recordFileModels ${state.recordFileModels.value}");
        if (state.recordFileModels.value.isNotEmpty) {
          DateTime currentTime = state.recordFileModels.value[0].recordTime;
          int currentHour = currentTime.hour - 2;
          int currentMinute = currentTime.minute;
          double minuteRatio = currentMinute / 60;
          double pixelValue = currentHour + minuteRatio;
          pixelValue = double.parse(pixelValue.toStringAsFixed(1));
          cs.previousHour.value = currentTime.hour;

          cs.timeCon.value.animateTo(
            pixelValue * (Get.width * 0.25),
            duration: Duration(milliseconds: 1),
            curve: Curves.easeInOut,
          );
        } else {
          // ✅ 데이터가 없을 경우 00:00 기준으로 초기화
          cs.previousHour.value = 0;

          cs.timeCon.value.animateTo(
            0.0, // 00:00 => 픽셀 0
            duration: Duration(milliseconds: 1),
            curve: Curves.easeInOut,
          );
        }

        /// 주어진 시간대별로 항목을 추가합니다.
        for (int i = 0; i < state.recordFileModels.value.length; i++) {
          DateTime recordTime = state.recordFileModels.value[i].recordTime;
          DateTime hourKey = DateTime(
            recordTime.year,
            recordTime.month,
            recordTime.day,
            recordTime.hour,
          );
          // 맵에 해당 시간대가 이미 있는지 확인하고, 없으면 0으로 초기화합니다.
          int count = cs.highlightedHours.indexWhere((element) => element.keys.first == hourKey);
          if (count == -1) {
            cs.highlightedHours.add({hourKey: 1});
          } else {
            cs.highlightedHours[count][hourKey] = (cs.highlightedHours[count][hourKey] ?? 0) + 1;
          }
        }
        cs.timeFirst.value = true;
      }
    });

    Future<void>captureScreen()async{
      RenderRepaintBoundary boundary = _boundKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      double pixelRatio = 5.0;
      ui.Image image = await boundary.toImage(pixelRatio: pixelRatio);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List? imageBytes = byteData?.buffer.asUint8List();
      final results2 = await ImageGallerySaverPlus.saveImage(imageBytes!,quality: 100,);
      Get.snackbar("사진이 캡처되었습니다", '사진첩에 들어가 사진을 확인해주세요');
    }
    
    /// ✅ 메인
    return PopScope(
        canPop: true,
        onPopInvokedWithResult: (pop, result)async{
          // await Get.offAll(() => BottomNavigatorView());
        },
        child: Obx(
              () => Scaffold(
            backgroundColor: Colors.white,
            body: cs.tfFullScreen.value
                ? BuildTfFullPlayWidget(context, logic)
                : NestedScrollView(
              headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
                return <Widget>[];
              },
              body: Column(
                children: [
                  Container(
                      height: MediaQuery.of(context).size.width * 9 / 16,
                      color: Colors.black,
                      child: Stack(
                        children: [
                          /// ✅ 카메라화면
                          Center(
                            child: RepaintBoundary(
                              key: _boundKey,
                              child: AspectRatio(
                                aspectRatio: 16 / 9,
                                child: AppPlayerView(
                                  controller: logic.controller,
                                ),
                              ),
                            ),
                          ),
                          /// ✅ 카메라화면 하단바
                          Align(
                            alignment: Alignment.bottomCenter,
                            child: Container(
                              color: Colors.black54,
                              child: Row(
                                children: [
                                  const SizedBox(
                                    width: 8,
                                  ),
                                  /// ✅ 10초전 아이콘
                                  GestureDetector(
                                      onTap: () async {
                                        /// 10초 전으로
                                        await tfPlayLogic.stopVideo();
                                        if (cs.addTime.value <= 10) {
                                          cs.addTime.value = 0;
                                        } else {
                                          cs.addTime.value = cs.addTime.value + state.playDuration - 10;
                                        }

                                        await tfPlayLogic.startVideo();
                                      },
                                      child: Image.asset(
                                        'assets/camera_icon/back_ten.png',
                                        width: 20,
                                        height: 20,
                                        color: Colors.white,
                                      )),
                                  ObxValue<Rx<VideoStatus>>((data) {
                                    return IconButton(
                                      icon: data.value == VideoStatus.PLAY || data.value == VideoStatus.STARTING
                                          ? Icon(Icons.stop)
                                          : Icon(Icons.play_arrow),
                                      color: Colors.white,
                                      onPressed: () async {
                                        print('what now : ${data.value}');
                                        if (data.value == VideoStatus.STOP) {
                                          logic.startVideo();
                                        } else {
                                          logic.stopVideo();
                                        }
                                        // else if (data.value == VideoStatus.PAUSE) {
                                        //   logic.resumeVideo();
                                        // }
                                      },
                                    );
                                  }, state.videoStatus),
                                  /// ✅ 10초 후 아이콘
                                  GestureDetector(
                                    onTap: () async {
                                      await tfPlayLogic.stopVideo();

                                      cs.addTime.value = cs.addTime.value + state.playDuration + 10;

                                      await tfPlayLogic.startVideo();
                                    },
                                    child: Image.asset(
                                      'assets/camera_icon/foward_ten.png',
                                      width: 24,
                                      height: 24,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const Spacer(),
                                  /// ✅ 영상 중지 아이콘
                                  TfPauseIcon(),

                                  /// ✅ 전체화면 아이콘
                                  IconButton(
                                    icon: Icon(Icons.fullscreen),
                                    color: Colors.white,
                                    onPressed: () {
                                      cs.tfFullScreen.value = true;
                                    },
                                  )
                                ],
                              ),
                            ),
                          ),
                        ],
                      )),

                  /// ✅ 타임라인 바
                  ObxValue<RxInt>((data) {
                    return (data.value == 1 && splitScreen != 1)
                        ? AspectRatio(
                      aspectRatio: 16 / 9, //横纵比 长宽比 16 : 9
                      child: AppPlayerView(
                        controller: state.tfPlayer2Controller!,
                      ),
                    )
                        : SizedBox();
                  }, state.tfHasSubPlay),

                  const SizedBox(height: 10),

                  ///三目或假三目
                  ObxValue<RxInt>((data) {
                    return (data.value == 1 && splitScreen == 1) //假三目
                        ? _VirtualThreeWidget(height: height, state: state, width: width)
                        : data.value == 2 //真三目
                        ? _ThreeWidget(state: state)
                        : SizedBox();
                  }, state.tfHasSubPlay),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Row(
                      children: [
                        /// ✅ 날짜 선택박스
                        InkWell(
                          onTap: () async {
                            print("눌러지긴 함?");
                            if (tfPlayLogic.progressing.value) return; /// ✅ 중복요청 막기

                            List<String> result = [];
                            int retryCount = 0;
                            const int maxRetry = 5;

                            while (result.isEmpty && retryCount < maxRetry) {
                              result = await DeviceManager.getInstance().mDevice!.getRecordTypeSearchDate();
                              retryCount++;
                              print("재시도 $retryCount회 결과: $result");

                              if (result.isEmpty && retryCount < maxRetry) {
                                await Future.delayed(Duration(milliseconds: 300)); // 약간의 간격을 줘도 좋음
                              }
                            }

                            if (result.isNotEmpty) {
                              List<DateTime> eventDates = parseDateList(result);
                              _showCalendarDialog(context, cs, eventDates);
                            } else {
                              print("❌ 최대 재시도 실패: 데이터가 비어있음");
                            }

                            tfPlayLogic.progressing.value = false;
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Obx(
                                  () => Text(
                                '${cs.cameraTfDate.value} ▼',
                                style: f16w700Size(),
                              ),
                            ),
                          ),
                        ),
                        Spacer(),
                        GestureDetector(
                            onTap: () async {
                              final status = await Permission.storage.request();
                              await showConfirmTapDialog(context, '선택된 영상을 저장하시겠습니까?\n\n(단, 다운로드 중 앱을 나가지마세요\n앱을 나가면 다운로드가 종료됩니다.', () async {
                                Get.back(); // 다이얼로그 닫기
                                try {
                                  print('here in -----1');

                                  await showTfCameraPercentageDialog(context);
                                  cs.cameraPercentage.value = '';
                                  print('here in -----2');

                                  List<RecordTimeLineModel> models = [state.playModel.value!.timeLine!];
                                  print('here in -----3');
                                  int startTime = state.playModel.value!.timeLine!.recordStart.millisecondsSinceEpoch ~/ 1000;
                                  int endTime = state.playModel.value!.timeLine!.recordEnd.millisecondsSinceEpoch ~/ 1000;

                                  List<RecordTimeLineDown> files = [];
                                  int len = (models.length > 60 ? 60 : models.length);
                                  print('here in -----4');
                                  for (var i = 0; i < len; ++i) {
                                    RecordTimeLineModel item = models[i];
                                    int startNo = 0;
                                    int endNo = item.frameLen;
                                    if (i == 0) {
                                      int sec = (startTime * 1000) - item.recordStart.millisecondsSinceEpoch;
                                      sec = sec ~/ 1000;
                                      var list = item.getFrameNo(sec);
                                      if (list.isEmpty) continue;
                                      startNo = list[0];
                                    } else if (i == models.length - 1) {
                                      int sec = (endTime * 1000) - item.recordStart.millisecondsSinceEpoch;
                                      sec = sec ~/ 1000;
                                      var list = item.getFrameNo(sec);
                                      if (list.isEmpty) continue;
                                      endNo = list[0] + 30;
                                      if (endNo > item.frameLen) endNo = item.frameLen;
                                    }
                                    if (item.recordAlarm != 13 && (endNo - startNo) < 45) continue;
                                    files.add(RecordTimeLineDown(item.recordName, startNo, endNo));
                                  }


                                  String currentTime = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
                                  String recordName = "${cs.cameraUID.value}_${currentTime}.mp4";
                                  Directory? directory;
                                  if (Platform.isIOS) {
                                    directory = await getApplicationDocumentsDirectory();
                                  }
                                  else if (Platform.isAndroid) {
                                    final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
                                    final AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;

                                    if(androidInfo.version.sdkInt<=29){
                                      directory = await getExternalStorageDirectory();
                                    }else{
                                      directory = Directory("/storage/emulated/0/Download/video");
                                    }
                                    // directory = await getDownloadsDirectory();
                                    // // print('dir??? ${directory}');
                                  } else {
                                    throw UnsupportedError("Unsupported platform");
                                  }

                                  if (!directory!.existsSync()) {
                                    print('디렉토리 생성: ${directory.path}');
                                    directory.createSync(recursive: true);
                                  }

                                  File destFile = File("${directory.path}/${recordName}");

                                  if (destFile.existsSync()) {
                                    destFile.deleteSync();
                                    await Future.delayed(Duration(milliseconds: 200));
                                  }

                                  destFile.createSync(recursive: true);
                                  bool? result = await DeviceManager.getInstance().mDevice!.startRecordLineFileDown(files);
                                  // bool? result = await Manager().getDeviceManager()!.mDevice!.startRecordLineFileDown(files);
                                  bool? result2 = await logic.controller.startDown(destFile.path);
                                  var bl = await AppPlayerController.saveMP4("${files[0].name}", destFile.path,destWidth: 1920,destHeight: 1080);
                                  if (result2) {
                                    controller.timer = Timer.periodic(Duration(seconds: 1), (timer) async {
                                      try {
                                        await cs.monitorDownloadProgress(
                                            destFile: destFile,
                                            totalSizeMB: state.selectModel.value!.recordSize /(1024 * 1024),
                                            context: context,
                                            timer: timer,
                                            controller: controller);
                                      } catch (e) {
                                        timer.cancel();
                                      }
                                    });
                                  } else {
                                    Get.back();
                                  }
                                } catch (e) {
                                  print('error check : $e');
                                  Get.back();
                                }
                              });
                            },
                            child: Icon(
                              Icons.download,
                              size: 24,
                            )),
                        const SizedBox(
                          width: 10,
                        ),
                        GestureDetector(
                          /// 스크린샷
                            onTap: () async {
                              if (Platform.isAndroid) {
                                captureScreen();
                              }else{
                                await Permission.photos.request();
                                PermissionStatus status = await Permission.photos.status;
                                // print('??${status}');
                                if(!status.isGranted){
                                  openAppSettings();
                                }
                                else if (status.isGranted) {
                                  captureScreen();
                                }
                              }
                              // RenderRepaintBoundary boundary = _boundKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
                              // double pixelRatio = 5.0;
                              // ui.Image image = await boundary.toImage(pixelRatio: pixelRatio);
                              // ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
                              // Uint8List? imageBytes = byteData?.buffer.asUint8List();
                              // final results2 = await ImageGallerySaverPlus.saveImage(imageBytes!,quality: 100,);
                              // Get.snackbar("사진이 캡처되었습니다", '사진첩에 들어가 사진을 확인해주세요');
                              // await _saveSnapshotFile(imageBytes!, '${DateTime.now()}', context);
                              },
                            child: Icon(
                              Icons.camera_alt_outlined,
                              size: 24,
                            )),
                      ],
                    ),
                  ),

                  /// 바가 멈추면 실행 하는 곳
                  Obx(() => Stack(
                    children: [
                      SizedBox(
                        height: 50,
                        child: NotificationListener<ScrollEndNotification>(
                          onNotification: (notification) {
                            Future.delayed(Duration.zero, () {
                              int index = 0;
                              double viewWidth = Get.width * 0.25;
                              int hourIndex = ((cs.timeCon.value.offset + Get.width / 2) / viewWidth).floor() % 24;
                              int minutes = 60 * ((cs.timeCon.value.offset + Get.width / 2) % viewWidth) ~/ viewWidth;

                              String formattedDateTime =
                                  "${cs.cameraTfDate.value} ${hourIndex.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}";
                              DateTime combinedDateTime = DateTime.parse(formattedDateTime);

                              /// 선택된 날짜와 시간과 가장 가까운 녹화 시간 찾기
                              DateTime closestRecordingTime = state.recordFileModels.value.fold<DateTime>(
                                DateTime(0),
                                    (previousValue, element) {
                                  DateTime recordTime = element.recordTime;

                                  /// 선택된 시간과의 차이 계산
                                  Duration difference = recordTime.difference(combinedDateTime);

                                  /// 이전값과 비교하여 차이가 작은 값 선택
                                  if (difference.abs() < previousValue.difference(combinedDateTime).abs()) {
                                    index = state.recordFileModels.value.indexOf(element);
                                    return recordTime;
                                  } else {
                                    return previousValue;
                                  }
                                },
                              );
                              state.playModel.value = state.recordFileModels.value[index];
                              state.selectModel.value = state.recordFileModels.value[index];
                              TFPlayLogic tfPlayLogic = Get.find<TFPlayLogic>();
                              tfPlayLogic.startVideo();
                              cs.cameraLoading.value = false;
                            });
                            return true;
                          },
                          child: ListView.builder(
                            physics: const ClampingScrollPhysics(),
                            shrinkWrap: true,
                            scrollDirection: Axis.horizontal,
                            controller: cs.timeCon.value,
                            itemCount: cs.hourList.length,

                            /// 격자 길이
                            itemBuilder: (context, index) {
                              return Container(
                                width: Get.width * 0.25,
                                color: Colors.white,
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: Obx(
                                            () => Container(
                                          width: Get.width *
                                              0.05 *
                                              (cs.highlightedHours.fold<int>(0, (previousValue, element) {
                                                final DateTime dataHour = element.keys.first;
                                                if (dataHour.year == cs.hourList[index].year &&
                                                    dataHour.month == cs.hourList[index].month &&
                                                    dataHour.day == cs.hourList[index].day &&
                                                    dataHour.hour == cs.hourList[index].hour) {
                                                  return element.values.first;
                                                }
                                                return previousValue;
                                              }) /
                                                  2),
                                          color:
                                          cs.highlightedHours.any((highlightedHour) => highlightedHour.keys.first == cs.hourList[index])
                                              ? Color(0xffC5EAE7)
                                              : Colors.transparent,
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      child: index == 0
                                          ? SizedBox(
                                        height: 0,
                                      )
                                          : Text('${cs.hourList[index].day} ${cs.hourList[index].hour}:00 ',
                                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                                      left: -16,
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: LayoutBuilder(
                                            builder: (context, constraints) {
                                              return Stack(
                                                children: List.generate(6, (idx) => idx).map((idx) {
                                                  return Positioned(
                                                    left: constraints.maxWidth * idx / 6,
                                                    top: idx == 0 ? 24 : 40,
                                                    bottom: 0,
                                                    child: Container(
                                                      height: 15,
                                                      width: 1,
                                                      color: Colors.black,
                                                    ),
                                                  );
                                                }).toList(),
                                              );
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      Positioned(
                        left: Get.width * 0.5,
                        top: 0,
                        bottom: 0,
                        child: Container(
                          width: 1,
                          color: Colors.lightBlue,
                        ),
                      ),
                    ],
                  )),
                  Text('${60}'),

                  /// 목록
                  TFScrollView<TFPlayState>(),
                  const SizedBox(
                    height: 160,
                  )
                ],
              ),
            ),
          ),
        ));
  }

  List<ChartData> getTimeData() {
    List<ChartData> data = [];
    for (int i = 0; i < 24; i++) {
      double time = i * 60.0; // 시간을 분으로 변환
      data.add(ChartData(times: time, value: i));
    }
    return data;
  }

  void _showCalendarDialog(BuildContext context, CameraState cs, List<DateTime> dateL) {
    DateTime? _selectedDate = DateTime.parse(cs.cameraTfDate.value);
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(builder: (context, setState) {
        return AlertDialog(
          backgroundColor: Colors.black,
          content: Container(
            width: double.maxFinite,
            height: 400,
            child: TableCalendar(
              locale: 'ko_KR',
              focusedDay: _selectedDate ?? DateTime.now(),
              availableCalendarFormats: {
                CalendarFormat.month: 'Month',
              },
              selectedDayPredicate: (day) => isSameDay(_selectedDate, day),
              onDaySelected: (selectedDay, focusedDay) {
                if (!isSameDay(_selectedDate, selectedDay)) {
                  setState(() {
                    _selectedDate = selectedDay;
                  });
                }
              },
              headerStyle: HeaderStyle(
                titleCentered: true,
                formatButtonVisible: false,
                titleTextStyle: TextStyle(color: Colors.white),
                leftChevronIcon: Icon(Icons.chevron_left, color: Colors.white),
                rightChevronIcon: Icon(Icons.chevron_right, color: Colors.white),
              ),
              daysOfWeekStyle: DaysOfWeekStyle(
                weekdayStyle: TextStyle(color: Colors.blue),
                weekendStyle: TextStyle(color: Colors.blue),
              ),
              calendarStyle: CalendarStyle(
                  defaultTextStyle: TextStyle(color: Colors.white),
                  weekendTextStyle: TextStyle(color: Colors.white),
                  outsideTextStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                  outsideDaysVisible: false,
                  isTodayHighlighted: false),
              firstDay: DateTime(1990),
              lastDay: DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day),
              calendarBuilders: CalendarBuilders(
                markerBuilder: (context, date, events) {
                  for (DateTime eventDate in dateL) {
                    if (date.year == eventDate.year && date.month == eventDate.month && date.day == eventDate.day) {
                      return Positioned(
                        right: 0,
                        left: 0,
                        bottom: 1,
                        child: Center(
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.blue,
                            ),
                            width: 7,
                            height: 7,
                          ),
                        ),
                      );
                    }
                  }
                  return null;
                },
              ),
            ),
          ),
          actions: [
            GestureDetector(
                onTap: () async {
                  String formattedSelectedDate = '${_selectedDate}'.replaceAll("Z", "");
                  DateTime formatSeleDate = DateTime.parse(formattedSelectedDate);
                  if (dateL.contains(formatSeleDate)) {
                    Future.delayed(Duration.zero, () {
                      TFPlayLogic logic = controller;
                      TFPlayState state = logic.state!;
                      TFPlayLogic tfPlayLogic = Get.find<TFPlayLogic>();
                      if (state.recordFileModels.value.isNotEmpty) {
                        DateTime currentTime = state.recordFileModels.value[0].recordTime;
                        int currentHour = currentTime.hour - 2;
                        int currentMinute = currentTime.minute;
                        double minuteRatio = currentMinute / 60;
                        double pixelValue = currentHour + minuteRatio;
                        cs.cameraTfDate.value = '${DateFormat('y-MM-dd').format(_selectedDate!)}';
                        DateTime select = DateTime.parse(cs.cameraTfDate.value);
                        DateTime newDate = select.add(Duration(days: 1));

                        if (DateTime.now().year == select.year && DateTime.now().month == select.month && DateTime.now().day == select.day) {
                          List<DateTime> oldHourList = List.generate(26, (index) => DateTime(select.year, select.month, select.day, index));
                          cs.hourList.value = [...oldHourList, newDate, newDate];
                        } else if (DateTime.now().year == select.year &&
                            DateTime.now().month == select.month &&
                            DateTime.now().day - 1 == select.day) {
                          List<DateTime> oldHourList = List.generate(24, (index) => DateTime(select.year, select.month, select.day, index));
                          cs.hourList.value = [...oldHourList];
                        } else {
                          List<DateTime> oldHourList = List.generate(24, (index) => DateTime(select.year, select.month, select.day, index));
                          List<DateTime> newHourList = List.generate(24, (index) => DateTime(newDate.year, newDate.month, newDate.day, index));
                          cs.hourList.value = [...oldHourList, ...newHourList];
                        }
                        pixelValue = double.parse(pixelValue.toStringAsFixed(1));
                        cs.timeCon.value.animateTo(
                          pixelValue * (Get.width * 0.25),
                          duration: Duration(milliseconds: 1),
                          curve: Curves.easeInOut,
                        );
                        tfPlayLogic.getDateRecordFile();
                      } else {
                        cs.cameraTfDate.value = '${DateFormat('y-MM-dd').format(_selectedDate!)}';
                        DateTime select = DateTime.parse(cs.cameraTfDate.value);
                        DateTime newDate = select.add(Duration(days: 1));

                        if (DateTime.now().year == select.year && DateTime.now().month == select.month && DateTime.now().day == select.day) {
                          List<DateTime> oldHourList = List.generate(26, (index) => DateTime(select.year, select.month, select.day, index));
                          cs.hourList.value = [...oldHourList, newDate, newDate];
                        } else if (DateTime.now().year == select.year &&
                            DateTime.now().month == select.month &&
                            DateTime.now().day - 1 == select.day) {
                          List<DateTime> oldHourList = List.generate(24, (index) => DateTime(select.year, select.month, select.day, index));
                          cs.hourList.value = [...oldHourList];
                        } else {
                          List<DateTime> oldHourList = List.generate(24, (index) => DateTime(select.year, select.month, select.day, index));
                          List<DateTime> newHourList = List.generate(24, (index) => DateTime(newDate.year, newDate.month, newDate.day, index));
                          cs.hourList.value = [...oldHourList, ...newHourList];
                        }
                        tfPlayLogic.getDateRecordFile();
                      }
                    });
                    Get.back();
                  }
                },
                child: Text(
                  '확인',
                  style: f16w700WhiteSize(),
                )),
          ],
        );
      }),
    );
  }

  List<DateTime> parseDateList(List<String> stringDates) {
    return stringDates.map((dateString) {
      return DateTime.parse(dateString);
    }).toList();
  }

  Future<void> _saveSnapshotFile(Uint8List data, String name, BuildContext context) async {
    if (Platform.isAndroid) {
      final results = await ImageGallerySaverPlus.saveImage(data.buffer.asUint8List(), quality: 100);
      print('???? ${results}');
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
          file.writeAsBytes(data);
          Get.snackbar("사진이 캡처되었습니다", '사진첩에 들어가 사진을 확인해주세요');
        }
      }
    }
  }

  Widget buildVoiceButton(TFPlayState state) {
    final cs = Get.find<CameraState>();
    return ObxValue<RxBool>((data) {
      // print("RxBool videoVoiceStop ${data.value}");
      if (data.value == false) {
        return IconButton(
          icon: Icon(Icons.volume_off),
          color: Colors.white,
          onPressed: () async {
            cs.mCameraVoice.value = true;
          },
        );
      } else {
        return IconButton(
          icon: Icon(Icons.volume_up),
          color: Colors.white,
          onPressed: () async {
            cs.mCameraVoice.value = false;
          },
        );
      }
    }, cs.mCameraVoice);
  }

  /// tf video full screen
  Widget BuildTfFullPlayWidget(BuildContext context, TFPlayLogic logic) {
    TransformationController ScaleController = TransformationController();
    // final cs = Get.put(CameraState());
    final CameraState cs = Get.find();
    return Obx(() => cs.tfFullScreen.value
        ? Center(
      child: InteractiveViewer(
        transformationController: ScaleController,
        minScale: 1.0,
        maxScale: 4.0,
        onInteractionUpdate: (details) {
          if (details.scale > 1.0) {
            cs.tfCameraDetailScale.value = details.scale;
          } else if (details.scale < 1.0) {
            cs.tfCameraDetailScale.value = 1.0;
          }
        },
        child: Stack(
          children: [
            Container(
              color: Colors.black,
              width: Get.width,
              height: Get.height,
            ),
            Center(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  height: Get.height * 0.84,
                  width: Get.width,
                  child: RotatedBox(
                    quarterTurns: 1,
                    child: AppPlayerView(
                      controller: logic.controller,
                    ),
                  ),
                ),
              ),
            ),
            // Container(
            //   margin: EdgeInsets.only(left: 20 / cs.tfCameraDetailScale.value, top: Get.height * 0.46 / cs.tfCameraDetailScale.value),
            //   child: SizedBox(
            //       width: 50 / cs.tfCameraDetailScale.value,
            //       height: 160 / cs.tfCameraDetailScale.value,
            //       child: RotatedBox(
            //         quarterTurns: 1,
            //         child: Container(
            //           decoration: BoxDecoration(borderRadius: BorderRadius.circular(8 / cs.tfCameraDetailScale.value), color: Colors.grey),
            //           child: Row(
            //             mainAxisAlignment: MainAxisAlignment.center,
            //             children: [
            //               GestureDetector(
            //                   onTap: () {
            //                     if (cs.tfCameraDetailScale.value > 1.9 && cs.tfCameraDetailScale.value < 2.9) {
            //                       cs.tfCameraDetailScale.value = 1.0;
            //                       ScaleController.value = Matrix4.identity()..scale(1.0);
            //                       // cs.cameraIconVisible.value = true;
            //                     } else if (cs.tfCameraDetailScale.value > 2.9 && cs.tfCameraDetailScale.value < 3.9) {
            //                       cs.tfCameraDetailScale.value = 2.0;
            //                       ScaleController.value = Matrix4.identity()..scale(2.0);
            //                       // cs.cameraIconVisible.value = false;
            //                     } else if (cs.tfCameraDetailScale.value > 3.9) {
            //                       cs.tfCameraDetailScale.value = 3.0;
            //                       ScaleController.value = Matrix4.identity()..scale(3.0);
            //                       // cs.cameraIconVisible.value = false;
            //                     }
            //                   },
            //                   child: Icon(
            //                     Icons.exposure_minus_1_sharp,
            //                     size: 32 / cs.tfCameraDetailScale.value,
            //                   )),
            //               SizedBox(
            //                 width: 10 / cs.tfCameraDetailScale.value,
            //               ),
            //               Text(
            //                 "  ${cs.tfCameraDetailScale.value.toStringAsFixed(1)}x  ",
            //                 style: f20w700SizeScale2(),
            //               ),
            //               SizedBox(
            //                 width: 10 / cs.tfCameraDetailScale.value,
            //               ),
            //               GestureDetector(
            //                   onTap: () {
            //                     if (cs.tfCameraDetailScale.value > 0.9 && cs.tfCameraDetailScale.value < 2.0) {
            //                       cs.tfCameraDetailScale.value = 2.0;
            //                       ScaleController.value = Matrix4.identity()..scale(2.0);
            //                       // cs.cameraIconVisible.value = false;
            //                     } else if (cs.tfCameraDetailScale.value > 1.9 && cs.tfCameraDetailScale.value < 3.0) {
            //                       cs.tfCameraDetailScale.value = 3.0;
            //                       ScaleController.value = Matrix4.identity()..scale(3.0);
            //                       // cs.cameraIconVisible.value = false;
            //                     } else if (cs.tfCameraDetailScale.value > 2.9 && cs.tfCameraDetailScale.value < 4.0) {
            //                       cs.tfCameraDetailScale.value = 4.0;
            //                       ScaleController.value = Matrix4.identity()..scale(4.0);
            //                       // cs.cameraIconVisible.value = false;
            //                     } else {
            //                       print('null');
            //                     }
            //                   },
            //                   child: Icon(
            //                     Icons.plus_one_sharp,
            //                     size: 32 / cs.tfCameraDetailScale.value,
            //                   )),
            //             ],
            //           ),
            //         ),
            //       )),
            // ),
            Positioned(
              bottom: Get.height * 0.1,
              left: Get.width * 0.1,
              child: GestureDetector(
                onTap: () {
                  cs.tfFullScreen.value = false;
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(color: Colors.white),
                  ),
                  child: Image.asset(
                    'assets/camera_icon/minimize.png',
                    width: 40,
                    height: 40,
                    color: Colors.white,
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    )
        : const SizedBox.shrink());
  }
}

class _ThreeWidget extends StatelessWidget {
  const _ThreeWidget({
    super.key,
    required this.state,
  });

  final TFPlayState state;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AspectRatio(
          aspectRatio: 16 / 9, //横纵比 长宽比 16 : 9
          child: AppPlayerView(
            controller: state.tfPlayer2Controller!, //假三目
          ),
        ),
        SizedBox(width: 10),
        AspectRatio(
          aspectRatio: 16 / 9, //横纵比 长宽比 16 : 9
          child: AppPlayerView(
            controller: state.tfPlayer3Controller!, //假三目
          ),
        ),
      ],
    );
  }
}

class _VirtualThreeWidget extends StatelessWidget {
  const _VirtualThreeWidget({
    super.key,
    required this.height,
    required this.state,
    required this.width,
  });

  final double height;
  final TFPlayState state;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      height: height,
      child: Row(
        children: [
          VirtualThreeView(
            child: AppPlayerView(
              controller: state.tfPlayer2Controller!, //假三目
            ),
            alignment: Alignment.centerLeft,
            width: width,
            height: height,
          ),
          SizedBox(width: 10),
          VirtualThreeView(
            child: AppPlayerView(
              controller: state.tfPlayer2Controller!, //假三目
            ),
            alignment: Alignment.centerRight,
            width: width,
            height: height,
          ),
        ],
      ),
    );
  }
}
