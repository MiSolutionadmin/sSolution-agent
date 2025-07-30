import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:chewie/chewie.dart';
import 'package:get/get.dart';
import 'package:flutter/cupertino.dart';
import 'package:video_player/video_player.dart';
import '../../../utils/super_put_controller.dart';

// import 'package:ssolution_mms/ssolution/lib/provider/camera_state.dart';
import 'package:vsdk/app_player.dart';
import 'package:vsdk/camera_device/camera_device.dart';
import 'package:vsdk/camera_device/commands/card_command.dart';

// import 'package:ssolution_mms/tf_play/tf_play_state.dart';
// import 'package:ssolution_mms/utils/device_manager.dart';
import '../../provider/camera_state.dart';
import '../../provider/user_state.dart';
import '../../screen/bottom_navigator.dart';
import '../../utils/device_manager.dart';
import '../../utils/number_util.dart';
import '../model/record_file_model.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

import '../vstarcam_widget/tf_scroll_view/tf_scroll_logic.dart';
import '../vstarcam_widget/tf_time_slider/tf_time_slider_logic.dart';
import 'tf_play_state.dart';

class TFPlayLogic extends SuperPutController<TFPlayState> with WidgetsBindingObserver, TFTimeSliderLogic, TFScrollLogic, SingleGetTickerProviderMixin {
  late VideoPlayerController con1;
  late AppPlayerController controller;
  late ChewieController chewieController;
  RxBool isInitialized = false.obs;
  final cs = Get.find<CameraState>();
  int initSec = 0;
  final progressing = false.obs;
  AppLifecycleState? _lastState;
  Timer? timer;
  TFPlayLogic() {
    value = TFPlayState();
    initPut();
  }

  @override
  void onInit() {
    WidgetsBinding.instance.addObserver(this);
    /// ✅ 위젯이 완성되고 플레이어 생성하도록 변경
    WidgetsBinding.instance.addPostFrameCallback((_) {
      createPlayer(); // 플레이어 생성
    });
    initTFCardStatus(); // TF 카드 상태 초기화
    if (DeviceManager.getInstance().deviceModel!.supportTimeLine.value == 0) {
      /// TF 카드가 타임라인 재생 모드를 지원하지 않음
      state!.isSupportTimeLine.value = false;
    }
    String replacedStr = cs.cameraTfDate.value.replaceAll('-', '');

    /// TF 카드에 녹화된 비디오 데이터를 가져오기
    getRecordFile(DeviceManager.getInstance().mDevice!.id, true, supportRecordTypeSeach: true, dateName: '${replacedStr}').then((fileList) {
      print('123123123123 ${replacedStr}');
      if (fileList.isEmpty) return; // 가져온 데이터가 없으면 종료
      state!.recordFileModels.value = fileList; // 녹화 파일 목록 저장
      print('목록으로 들어옴?? ${fileList}');

      /// 목록 재생 모드
      if (!state!.isSupportTimeLine.value) {
        /// 기본적으로 첫 번째 비디오 재생
        RecordFileModel model = state!.recordFileModels.value[0];
        state!.playModel.value = model;
        startVideo(); // 비디오 재생 시작
      } else {
        print('타임라인모드로 들어옴');
        // con1 = VideoPlayerController.file(File(fileList[0]!.cacheFile!.path));
        // chewieController = ChewieController(
        //   videoPlayerController: con1,
        //   autoPlay: true, // 자동 재생 설정
        //   looping: true, // 반복 재생 설정
        // );
        /// 타임라인 모드
        getTFRecordModeTimes(fileList); // 타임라인 데이터를 처리
        initAnimationController(); // 애니메이션 컨트롤러 초기화
        dealTFScrollRecordFile(fileList); // 스크롤 관련 파일 처리
      }
    });

    // 주석 처리된 코드: TF 카드 데이터가 변경될 때마다 새로고침 로직 (필요 시 활성화 가능)
    // ever(cs.cameraTfDate, (_) async {
    //   cs.needsRefresh.value = true; // 새로고침 필요 상태 설정
    //   print('support 11111 ----');
    //   await getRecordFile(DeviceManager.getInstance().mDevice!.id, true,supportRecordTypeSeach: true,dateName: '${replacedStr}')
    //   // getRecordFile(DeviceManager.getInstance().mDevice!.id, false)
    //       .then((fileList) {
    //     print('support 2222 ----');
    //     if (fileList.isEmpty) return; // 가져온 데이터가 없으면 종료
    //     state!.recordFileModels.value = fileList; // 녹화 파일 목록 저장
    //     print("------가져온 데이터 개수-----${fileList.length}");
    //
    //     /// 목록 재생 모드
    //     if (!state!.isSupportTimeLine.value) {
    //       /// 기본적으로 첫 번째 비디오 재생
    //       RecordFileModel model = state!.recordFileModels.value[0];
    //       state!.playModel.value = model;
    //       startVideo(); // 비디오 재생 시작
    //     } else {
    //       /// 타임라인 모드
    //       // getTFRecordModeTimes(fileList); // 타임라인 데이터 처리
    //       initAnimationController(); // 애니메이션 컨트롤러 초기화
    //       dealTFScrollRecordFile(fileList); // 스크롤 관련 파일 처리
    //     }
    //     print('support init2222 ----');
    //     // cs.triggerRefresh(); // 새로고침 트리거
    //     cs.needsRefresh.value = false; // 새로고침 필요 상태 해제
    //   });
    // });

    super.onInit(); // 부모 클래스의 onInit 호출
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_lastState == state) {
      return;
    }
    _lastState = state;

    if (cs.cameraPercentage.value != '') {
      if (state == AppLifecycleState.paused) {
        _handlePausedState();
      }
    }
  }

  Future<void> _handlePausedState() async {
    final us = Get.put(UserState());
    try {
      bool? result2 = await controller.stopDown();
      if (timer != null && timer!.isActive) {
        timer!.cancel();
        timer = null;
      }
      cs.tfCameraChangeMp4.value = false;
      cs.cameraPercentage.value = '';
      us.bottomIndex.value = 1;
      Get.offAll(()=>BottomNavigator());
    } catch (e) {
      print("다운로드 중지 중 오류 발생: $e");
    }
  }
  List<RecordFileModel> recordFiles = [];

  void initTFCardStatus() async {
    CameraDevice device = DeviceManager.getInstance().mDevice!;
    bool bl = await device.getRecordParam();
    if (bl) {
      String sdStatus = device.recordResult.record_sd_status;
      String sdFree = device.recordResult.sdfree;
      String sdTotal = device.recordResult.sdtotal;
      print("---sdStatus-$sdStatus----sdFree-$sdFree-----sdTotal-$sdTotal---------");
    }
  }

  ///创建播放器
  void createPlayer() {
    controller = AppPlayerController();
    controller.setStateChangeCallback(onStateChange);
    controller.setCreatedCallback(onCreated);
    controller.addProgressChangeCallback(onProgress);
    state?.tfPlayer = controller;

    setSubPlayer();
  }

  void onStateChange(dynamic userData, VideoStatus videoStatus, VoiceStatus voiceStatus, RecordStatus recordStatus, SoundTouchType touchType) {
    ///视频播放状态回调
    state?.videoStatus(videoStatus);
    state?.voiceStatus = voiceStatus;
  }

  void onCreated(dynamic userData) {
    print("onCreated");
  }

  ///视频信息监听回调
  // void onProgress(dynamic userData, int totalSec, int playSec, int progress, int loadState, int velocity) async {
  //   state?.duration = totalSec;
  //   state?.playDuration = playSec;
  //   cs.currentPosition.value = playSec;
  //   print("player currentSec:$playSec, totalSec:$totalSec, progress:$progress loadState:$loadState flow:$velocity)");
  // }

  void onProgress(dynamic userData, int totalSec, int playSec, int progress,
      int loadState, int velocity, int time) async {
    state?.duration = totalSec;
    state?.playDuration = playSec;
    print(
        "player currentSec:$playSec, totalSec:$totalSec, progress:$progress loadState:$loadState flow:$velocity)");
  }

  /// 보이드 만들어서 갱신해서 가져와야함 getRecordFile참고
  void getDateRecordFile() async {
    resultMap.clear();

    print('support 처음처음 : ${resultMap.length} ----');
    String replacedStr = cs.cameraTfDate.value.replaceAll('-', '');

    ///获取TF卡录制的视频数据

    print('support 0000 ---- ${replacedStr}');
    print('support 11111 ---- ${DeviceManager.getInstance().mDevice!.id}');
    await getRecordFile(DeviceManager.getInstance().mDevice!.id, true, supportRecordTypeSeach: true, dateName: '${replacedStr}')
    // getRecordFile(DeviceManager.getInstance().mDevice!.id, false)
        .then((fileList) {
      print('support 2222 ----');
      print('support 3333 : ${fileList} ----');

      /// 주어진 시간대별로 항목을 추가합니다.

      if (fileList.isEmpty) return;
      // state!.playModel.value = null;
      state!.recordFileModels.value = fileList;
      print("------获取到了数据-----${fileList.length}");
      for (int i = 0; i < state!.recordFileModels.value.length; i++) {
        DateTime recordTime = state!.recordFileModels.value[i].recordTime;
        // 해당 항목의 날짜와 시간을 추출합니다.
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
      print('강조효과 ${cs.highlightedHours.value}');

      ///列表播放模式
      if (!state!.isSupportTimeLine.value) {
        print('서포트라인밸류1');

        ///默认播放第一个视频
        RecordFileModel model = state!.recordFileModels.value[0];
        state!.playModel.value = model;
        startVideo();
      } else {
        print('서포트라인밸류22 ${state!.recordFileModels.value[0]}');

        ///时间轴模式
        // getTFRecordModeTimes(fileList);
        RecordFileModel model = state!.recordFileModels.value[0];
        state!.playModel.value = model;
        initAnimationController();
        dealTFScrollRecordFile(fileList);
      }
      print('support 끝끝 : ${resultMap.length} ----');
      print('support init2222 ----');
      // cs.triggerRefresh();
      // cs.needsRefresh.value = false;
    });
  }

  ///demo只拿了10条数据
  ///demo에서 10개의 데이터만 가져오는 함수
  Future<List<RecordFileModel>> getRecordFile(
      String deviceId,
      bool loadMore, {
        bool loadAll = false,
        String? dateName,
        bool supportRecordTypeSeach = false,
      }) async {
    CameraDevice device = DeviceManager.getInstance().mDevice!;
    List<RecordFile> files = device.recordFileList;

    print('레코드 가져오는 중------ $files'); // 시작 로그
    files = [];
    files.clear();

    /// 녹화 영상 타입 검색 기능은 아직 구현되지 않음
    if (supportRecordTypeSeach == true) {
      print('타입 검색 활성화됨 - 날짜: $dateName, 전체로드: $loadAll');
      if (dateName != null) {
        // try {
        //   // print("일로들어왔음 $dateName");
        //   files = await device.getRecordFile(supportRecordTypeSeach: true, dateName: '${dateName}');
        //   // print("일로들어왔음222 $dateName");
        // } catch (e) {
        //   print('왜에러? $e : $dateName');
        // }

        files = await device.getRecordFile(supportRecordTypeSeach: true, dateName: '${dateName}');
        print('특정 날짜 파일 가져옴: $files');
      } else if (loadAll == true) {
        print("일로들어왔음22");
        files = await device.getRecordFile(supportRecordTypeSeach: true, cache: false);
        print('전체 파일 가져옴: $files');
      } else {
        print("일로들어왔음33");
        DateTime nowDateTime = DateTime.now();
        String year = nowDateTime.year.toString();
        String month = twoDigits(nowDateTime.month);
        String day = twoDigits(nowDateTime.day);
        String nowdDateName = year + month + day;

        print('현재 날짜: $nowdDateName');
        if (device.recordFileList.isEmpty) {
          print('기록 파일이 비어있음, 날짜 검색 시작');
          List<DateTime> dateTimes = await getRecordTypeSearchDate(deviceId);
          if (dateTimes.isNotEmpty) {
            print('날짜 검색 결과: $dateTimes');
            dateTimes.sort((a, b) => a.compareTo(b));
            DateTime nearDateTime = dateTimes.last;
            year = nearDateTime.year.toString();
            month = twoDigits(nearDateTime.month);
            day = twoDigits(nearDateTime.day);
            String nearDateName = year + month + day;
            files = await device.getRecordFile(supportRecordTypeSeach: true, dateName: nearDateName);
            print('가장 가까운 날짜 파일 가져옴: $files');
          }
        }
        if (loadMore == true) {
          files = await device.getRecordFile(supportRecordTypeSeach: true);
          print('추가 파일 가져옴: $files');
        } else {
          files = await device.getRecordFile(supportRecordTypeSeach: true, dateName: nowdDateName);
          print('현재 날짜 파일 가져옴: $files');
        }
      }
    } else {
      print('타입 검색 비활성화됨 -날짜: $dateName, 전체 로드: $loadAll');
      if (loadAll == true) {
        files = await device.getRecordFile(cache: false);
        print('전체 파일 가져옴: $files');
      } else {
        print('처으므으므으으으므 ${dateName}');
        int pageIndex = 0;
        if (loadMore == true) {
          pageIndex = device.recordFileList.length ~/ 10;
          print('페이지 인덱스 계산: $pageIndex');
        }
        var oldList = device.recordFileList;

        /// 녹화 데이터 가져오기
        files = await device.getRecordFile(
          pageIndex: pageIndex,
          pageSize: 20,
          dateName: dateName,
        );
        print('첫 번째 페이지 파일 가져옴: $files');

        if (oldList.length == files.length) {
          print('파일 크기 동일, 다음 페이지 시도');
          files = await device.getRecordFile(
            pageIndex: pageIndex + 1,
            pageSize: 20,
            dateName: dateName,
          );
          print('두 번째 페이지 파일 가져옴: $files');
        }

        Directory dir = await device.getDeviceDirectory();
        dir = Directory("${dir.path}/tf_cache");
        print('캐시 디렉토리 확인: $dir');
        if (dir.existsSync()) {
          files.forEach((element) {
            File file = File("${dir.path}/${element.record_name}");
            print('파일 경로 확인: ${file.path}');
            if (file.existsSync()) {
              element.record_cache_size = File("${dir.path}/${element.record_name}").lengthSync();
              if (element.record_cache_size > element.record_size) {
                element.record_cache_size = element.record_size;
              }
              print('캐시 파일 크기 업데이트: ${element.record_cache_size}');
            }
          });
        }
      }
    }

    recordFiles.clear();
    recordFiles = [];

    files.forEach((element) {
      RecordTimeLineModel? timeLine;
      if (element.lineFile != null) {
        var line = element.lineFile!;
        print("---------------------------record_name:${line.record_name}");
        if (line.record_duration < 4 || line.record_duration > 1000) {
          print("tf 파일 오류: record_name:${line.record_name}, record_duration:${line.record_duration}");
          return;
        }
        timeLine = RecordTimeLineModel(line.record_name, line.record_time, line.record_alarm, line.record_start!, line.record_end!,
            line.record_duration, line.frame_len, line.frame_interval);
        line.frames.forEach((item) {
          timeLine!.frames.add(RecordTimeFrameModel(item.timestamp!, item.frame_no!, item.frame_gop!));
        });
      }

      /// 녹화 모델 생성
      RecordFileModel model = RecordFileModel(
          element.record_name!, element.record_alarm!, element.record_time!, element.record_size, element.record_head!,
          timeLine: timeLine);
      recordFiles.add(model);
      print('추가된 모델: ${model.recordName}');
    });

    print('최종 레코드 개수: ${recordFiles.length}');
    return recordFiles;
  }

  Future<void> dealTFScrollRecordFile(List<RecordFileModel> allData) async {
    //print("_dealTFScrollRecordFile:$pullType,$loadCount,${allData.isNotEmpty}");
    List<DateTime> tabData = [];
    print("-------------dealTFScrollRecordFile ${allData.length}-------------");
    if (allData.isNotEmpty) {
      state!.filterMap.clear();
      allData.forEach((element) {
        state!.filterMap[element.recordName] = element;
        DateTime time = DateTime(element.recordTime.year, element.recordTime.month, element.recordTime.day);
        if (!tabData.contains(time)) {
          tabData.add(time);
        }
      });
      tabData.sort((a, b) {
        return b.compareTo(a);
      });

      allData = state!.filterMap.values.toList();
      getTFRecordModeTimes(allData);
    }

    if (state!.selectTime.value == null && tabData.isNotEmpty) {
      state!.selectTime(tabData.first);
    }
    state!.tabData.value.clear();
    // state!.tabData.addAll(tabData);
    state!.tabData.addAll(tabData);
    if (allData.isNotEmpty && state!.selectTime.value != null) {
      ///获取当前下标
      int index = state!.tabData
          .indexWhere((element) =>
      element.year == state!.selectTime.value!.year &&
          element.month == state!.selectTime.value!.month &&
          element.day == state!.selectTime.value!.day)
          .toInt();
      if (index < 0) {
        //刷新最新数据
        getTFRecordModeTimes(allData);
        index = 0;
      }
      if (index > tabData.length - 1) {
        index = tabData.length - 1;
        EasyLoading.showToast('后面没有录像视频了'.tr, maskType: EasyLoadingMaskType.clear);
        return;
      }

      ///选中的日历
      state!.selectTime(tabData[index]);

      ///数据排序
      allData.sort((a, b) {
        return b.recordTime.compareTo(a.recordTime);
      });
      state!.recordFileModels.value.clear();
      state!.recordFileModels.value = allData;

      var model = allData.first;
      if (state!.selectModel.value == null) {
        state!.tfTimeLoading.value = false;
        startSliderAnimate();
        state!.selectModel(model);
        state!.playModel(model);
        startVideo();
      }
    }
    return;
  }

  Map<String, RecordFileModel> resultMap = Map();

  void getTFRecordModeTimes(List<RecordFileModel> lists) {
    resultMap.clear();
    lists.forEach((model) {
      if (model.timeLine == null || model.timeLine?.recordStart == null) {
        print("----timeLine---${model.timeLine}-----recordStart--${model.timeLine?.recordStart}-----------------");
        return;
      }
      resultMap[model.recordName] = model;
    });
    print('리절트맵 ${resultMap.length}');
    List<RecordFileModel> recordLists = resultMap.values.toList() ?? [];

    recordLists.sort((a, b) => (b.recordTime).compareTo(a.recordTime));
    state!.allRecordTimes.value.clear();
    state!.allRecordTimes.value.addAll(recordLists);
    if (recordLists.length > 0 && state!.selectModel.value == null) {
      var model = state!.allRecordTimes.value.last;
      Future.delayed(Duration(milliseconds: 500), () {
        setSliderCurrentTime(model.timeLine!.endTime);
      });
    }
  }

  Future<List<DateTime>> getRecordTypeSearchDate(String deviceId) async {
    CameraDevice cameraDevice = DeviceManager.getInstance().mDevice!;
    List<String> listDates = await cameraDevice.getRecordTypeSearchDate();
    if (listDates.isNotEmpty) {
      List<DateTime> dateTimes = [];
      listDates.forEach((element) {
        if (element.length == 8) {
          int year = int.tryParse(element.substring(0, 4)) ?? 0;
          int month = int.tryParse(element.substring(4, 6)) ?? 0;
          int day = int.tryParse(element.substring(6, 8)) ?? 0;
          DateTime time = DateTime(year, month, day);
          dateTimes.add(time);
        }
      });
      return dateTimes;
    }
    return [];
  }

  Future<bool> setVideoSource(String deviceId, RecordFileModel model) async {
    CameraDevice? cameraDevice = DeviceManager.getInstance().mDevice;
    if (cameraDevice == null) return false;

    if (controller == null) return false;

    if (state?.playModel != null && model.recordName == state?.playModel.value!.recordName && model.loadSize >= model.recordSize) return true;

    var clientPtr = cameraDevice.clientPtr;
    if (clientPtr == null) return false;

    print("setVideoSource in tf :${model.recordName} ${model.recordHead}");
    state!.playDuration = 0;
    initSec = 0;
    await controller.stop();
    state!.videoStatus(VideoStatus.STARTING);
    var result = false;
    if (model.timeLine == null) {
      result = await controller.setVideoSource(CardVideoSource(clientPtr, model.recordSize, checkHead: (model.recordHead == true ? 1 : 0)));
    } else {
      result = await controller.setVideoSource(TimeLineSource(clientPtr));
    }
    print('resrse?? ${result}');
    if (result == true) {
      state!.playModel.value = model..loadSize = 0;
      Directory dir = await cameraDevice.getDeviceDirectory();
      dir = Directory("${dir.path}/tf_cache");
      print('dir?? ${dir}');
      if (!dir.existsSync()) dir.createSync(recursive: true);
      state!.cacheFile = File("${dir.path}/${model.recordName}");
    }
    return result;
  }

  ///开始播放视频，timestamp时间戳，可通过时间戳获取对应的视频文件
  Future<bool> startPlayer({int? timestamp}) async {
    print('start player in -------');

    final cs = Get.find<CameraState>();
    var model = state!.playModel.value;
    CameraDevice? device = DeviceManager.getInstance().mDevice;
    if (model == null) return false;
    if (device == null) return false;
    if (state!.supportTimeLine.value) {
      bool bl = await setVideoSource(DeviceManager.getInstance().mDevice!.id, model);
      // controller!.stop();
    }
    var result = true;
    if (model.timeLine == null) {
      // print("startPlayer:${model.recordName} loadSize:${model.loadSize} recordSize:${model.recordSize}");
      initSec = 0;
      if (model.loadSize < model.recordSize) result = await device.startRecordFile(model.recordName, 0);
    } else {
      RecordTimeLineModel? lineModel;
      int sec = 0;
      if (timestamp == null) {
        lineModel = model.timeLine;
        if (lineModel == null) return false;

        sec = (cs.addTime.value * 1000);
        sec = sec ~/ 1000;
      } else {
        lineModel = await findTimeLineModel(timestamp);
        if (lineModel == null) return false;
        // sec = (timestamp * 1000) - lineModel.recordStart.millisecondsSinceEpoch + (seconds * 1000);
        sec = (timestamp * 1000) - lineModel.recordStart.millisecondsSinceEpoch;
        sec = sec ~/ 1000;
      }
      print('start player in 2------- : ${sec}');

      var list = lineModel.getFrameNo(sec);
      if (list.isEmpty) return false;
      print('what is list : ${lineModel}');
      sec = list[1];
      print(
          "time:${lineModel.recordTime} name:${lineModel.recordName} event:${lineModel.recordAlarm} duration:${lineModel.recordDuration} frameLen:${lineModel.frameLen} "
              "sec:$sec frameNo:${list[0]}");

      state!.playDuration = sec;
      var channel = state!.channel == 2 ? 3 : 2;
      int key = Random().nextInt(9999);
      initSec = sec;
      controller.setChannelKey(channel, key);
      result = await device.startRecordLineFile(lineModel.recordTime, lineModel.recordAlarm, channel: channel, frameNo: list[0], key: key);
      state!.channel = channel;
      state!.duration = lineModel.recordDuration;
    }

    if (state!.isSupportTimeLine.value&& model.timeLine !=null) {
      setSliderCurrentTime(model.timeLine!.startTime);
    }
    if (state!.playRate == 1.0) {
      result = await controller.startVoice();
    }

    /// ✅ 플레이어 attach 확인 후 start 25-04-29
    Future.delayed(Duration(milliseconds: 100), () async {
      result = await controller.start();
    });

    return result;
  }

  Future<bool> jumpToTimestamp({int? timestamp, int? seconds}) async {
    print('start player in -------');
    var model = state!.playModel.value;
    CameraDevice? device = DeviceManager.getInstance().mDevice;
    if (model == null) return false;
    if (device == null) return false;
    if (seconds == null) return false;
    if (state!.supportTimeLine.value) {
      bool bl = await setVideoSource(DeviceManager.getInstance().mDevice!.id, model);
      // controller!.stop();
    }
    var result = true;
    if (model.timeLine == null) {
      // print("startPlayer:${model.recordName} loadSize:${model.loadSize} recordSize:${model.recordSize}");
      initSec = 0;
      if (model.loadSize < model.recordSize) result = await device.startRecordFile(model.recordName, 0);
    } else {
      RecordTimeLineModel? lineModel;
      int sec = 0;
      if (timestamp == null) {
        lineModel = model.timeLine;
        if (lineModel == null) return false;

        sec = (seconds * 1000);
        sec = sec ~/ 1000;
      } else {
        lineModel = await findTimeLineModel(timestamp);
        if (lineModel == null) return false;
        sec = (timestamp * 1000) - lineModel.recordStart.millisecondsSinceEpoch + (seconds * 1000);
        // sec = (timestamp * 1000) - lineModel.recordStart.millisecondsSinceEpoch;
        sec = sec ~/ 1000;
      }
      print('start player in 2------- : ${sec}');

      var list = lineModel.getFrameNo(sec);
      if (list.isEmpty) return false;
      print('what is list : ${lineModel}');
      sec = list[1];
      print(
          "time:${lineModel.recordTime} name:${lineModel.recordName} event:${lineModel.recordAlarm} duration:${lineModel.recordDuration} frameLen:${lineModel.frameLen} "
              "sec:$sec frameNo:${list[0]}");

      state!.playDuration = sec;
      var channel = state!.channel == 2 ? 3 : 2;
      int key = Random().nextInt(9999);
      initSec = sec;
      controller.setChannelKey(channel, key);
      result = await device.startRecordLineFile(lineModel.recordTime, lineModel.recordAlarm, channel: channel, frameNo: list[0], key: key);
      state!.channel = channel;
      state!.duration = lineModel.recordDuration;
    }

    if (state!.isSupportTimeLine.value) {
      setSliderCurrentTime(model.timeLine!.startTime);
    }
    if (state!.playRate == 1.0) {
      result = await controller.startVoice();
    }
    result = await controller.start();

    return result;
  }

  Future<RecordTimeLineModel?> findTimeLineModel(int timestamp) async {
    var dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    var list = DeviceManager.getInstance().mDevice!.getAllLineFile();
    print('dateTime?? ${dateTime}');
    print('? ? times ${timestamp}');
    list.sort((a, b) {
      return a.record_start!.compareTo(b.record_start!);
    });
    print('?????? lisrt?? ${list}');
    var lineFile = list.lastWhere((element) {
      var bl = element.record_start!.isBefore(dateTime) || element.record_start == dateTime;
      return bl;
    });
    if (lineFile == null) return null;
    RecordTimeLineModel lineModel = RecordTimeLineModel(lineFile.record_name, lineFile.record_time, lineFile.record_alarm, lineFile.record_start!,
        lineFile.record_end!, lineFile.record_duration, lineFile.frame_len, lineFile.frame_interval);
    lineFile.frames.forEach((item) {
      lineModel.frames.add(RecordTimeFrameModel(item.timestamp!, item.frame_no!, item.frame_gop!));
    });
    return lineModel;
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    controller.dispose();
    super.onClose();
  }

  Future<bool> stopPlayer() async {
    DeviceManager.getInstance().mDevice?.stopRecordFile();
    var result = await controller.stop() ?? false;
    return result;
  }

  bool _isVideoPlaying = false;

  Future<void> startVideo() async {

    if (_isVideoPlaying) {
      return;
    }
    _isVideoPlaying = true;

    try {
      if (state?.recordFileModels != null && state!.recordFileModels.value.isNotEmpty) {
        state!.videoStartTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        bool bl = await setVideoSource(DeviceManager.getInstance().mDevice!.id, state!.playModel.value!);
        if (!bl) state!.videoStatus(VideoStatus.STOP);
        await startPlayer();
      }
    } finally {
      _isVideoPlaying = false;
    }
  }

  AnimationController? animationControllerController;

  startSliderAnimate() {
    animationControllerController?.value = 1.0;
    animationControllerController?.animateTo(14400.0, duration: const Duration(milliseconds: 1000));
  }

  void initAnimationController() async {
    animationControllerController = AnimationController(vsync: this, lowerBound: 1.0, upperBound: 14400.0);
    animationControllerController!.addListener(_sliderAnimationListener);
  }

  void _sliderAnimationListener() {
    var value = animationControllerController!.value;
    Future.delayed(Duration(milliseconds: 1), () {
      var startTime = state!.selectModel.value?.timeLine?.startTime;
      if (startTime != null) {
        double time = startTime.toDouble() - 14400;
        time = time + value;
        Get.tryFind<TFTimeSliderLogic>(tag: 'TFPlayState').setSliderCurrentTime(time.toInt());
      }
    });
  }

  Future<void> stopVideo() async {
    await stopPlayer();
  }

  void pauseVideo() {
    controller.pause();
  }

  void resumeVideo() {
    controller.resume();
  }

  @override
  void onHidden() {
    // TODO: implement onHidden
  }

  ///删除tf录像文件(녹화파일삭제)
  Future<List<RecordFileModel>> deleteRecordFile(RecordFileModel recordFile, bool localFile) async {
    //yield CameraDeleteRecordFileState.start(did, result: event.recordFile);
    bool result = false;
    print("------delete recordName ${recordFile.recordName}-----------------");
    if (localFile != true) {
      result = await DeviceManager.getInstance().mDevice!.deleteRecordFile(recordFile.recordName);
      // print("------delete result $result-----------------");
      // EasyLoading.showToast("数据删除成功！");
    } else {
      result = true;
    }
    if (result == true) {
      Directory dir = await DeviceManager.getInstance().mDevice!.getDeviceDirectory();
      dir = Directory("${dir.path}/tf_cache");
      if (!dir.existsSync()) {
        dir.createSync(recursive: true);
      }
      File file = File("${dir.path}/${recordFile.recordName}");
      if (file.existsSync()) {
        file.deleteSync();
      }
      file = File("${file.path}_head");
      if (file.existsSync()) {
        file.deleteSync();
      }
      recordFile.videoProgress.value = 0;
    }

    recordFiles.clear();
    DeviceManager.getInstance().mDevice!.recordFileList.forEach((element) {
      RecordFileModel model =
      RecordFileModel(element.record_name!, element.record_alarm!, element.record_time!, element.record_size, element.record_head!);
      recordFiles.add(model);
    });

    ///数据排序 데이터 정렬

    recordFiles.sort((a, b) {
      return b.recordTime.compareTo(a.recordTime);
    });
    state!.recordFileModels.value = recordFiles;
    return recordFiles;
  }

  ///设置多目播放器
  Future<bool> setSubPlayer() async {
    bool bl = false;

    ///创建多目设备的播放控制器
    int sensor = DeviceManager.getInstance().deviceModel?.supportMutilSensorStream.value ?? 0;

    int splitScreen = DeviceManager.getInstance().deviceModel?.splitScreen.value ?? 0;

    ///splitScreen=1 代表二目分屏为三目，为假三目。只有splitScreen !=1 时才是真三目
    if (sensor == 3 && splitScreen != 1) {
      bl = await enableCloudSubPlayer(sub2Player: true);
      print("-----------3-------enableSubPlayer---$bl---------------");
    } else if (sensor == 1 || (sensor == 3 && splitScreen == 1)) {
      ///二目或者假三目
      bl = await enableCloudSubPlayer();
      print("-----------2-------enableSubPlayer---$bl---------------");
    }
    return bl;
  }

  ///创建多目播放器
  Future<bool> enableCloudSubPlayer({bool sub2Player = false}) async {
    if (controller.sub_controller != null) return true;
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
    result = await controller.enableSubPlayer(subController);
    if (result != true) {
      print("-------------enableSubPlayer---false---------------");
      return false;
    }
    state?.tfPlayer2Controller = subController;

    //sub2Player
    if (sub2Player == true) {
      if (controller.sub2_controller != null) return true;
      var sub2Controller = AppPlayerController();
      var result = await sub2Controller.create();
      if (result != true) {
        print("-------------sub2Controller.create---false---------------");
        return false;
      }
      result = await sub2Controller.setVideoSource(SubPlayerSource());
      if (result != true) {
        print("——————sub2Controller.setVideoSource—false———————");
        return false;
      }
      await sub2Controller.start();
      result = await controller.enableSub2Player(sub2Controller);
      if (result != true) {
        print("——————enableSub2Player—false———————");
        return false;
      }
      state?.tfPlayer3Controller = sub2Controller;
    }
    if (sub2Player) {
      state?.tfHasSubPlay.value = 2;
    } else {
      state?.tfHasSubPlay.value = 1;
    }
    return true;
  }

}
