import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart' as dio;
import 'package:flutter/cupertino.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:mms/components/dialogManager.dart';
import '../base_config/config.dart';
import '../components/dialog.dart';
import '../provider/camera_state.dart';
import '../provider/notification_state.dart';
import '../provider/user_state.dart';
import 'package:path_provider/path_provider.dart';

final config = AppConfig();

Future<void> getCameraDetail(String cameraUid) async {
  final us = Get.put(UserState());
  final cs = Get.find<CameraState>();
  final url = '${config.baseUrl}/getCameraDetail?cameraUid=$cameraUid';
  final response = await http.get(Uri.parse(url));
  List<dynamic> data = jsonDecode(response.body);
  cs.cameraDetailList.value = data;

  if(cs.cameraDetailList[0]['fireDetect']=='false'){
    cs.fireSwitch.value = false;
  }

  if (response.statusCode != 200) {
    print('에러에러');
    throw Exception('Failed to send email');
  }
}

Future<String> getVideoUrl(String notiDocId) async {
  final url = '${config.baseUrl}/video/$notiDocId';

  final response = await http.get(Uri.parse(url));

  print("url  ? : ${response.body}");
  String videoUrl = response.body;

  if (response.statusCode != 200) {
    print('에러에러');
    throw Exception('Failed to send email');
    return "";
  } else {
    return videoUrl;
  }
}

/// 관리자 추가
// Future<void> addNotiDelete(String reson) async{
//   final us= Get.put(UserState());
//   final ns = Get.put(NotificationState());
//   final url = 'http://misnetwork.iptime.org:9000/notiDeleteAdd';
//   final body = ({
//     'name':'${us.userList[0]['name']}',
//     'email' : '${us.userList[0]['email']}',
//     'mms' : '${us.userList[0]['mms']}',
//     'reason' : '${reson}',
//     'createDate' : '${DateTime.now()}',
//     'docId' : '${ns.notiDocId.value}',
//   });
//   final response = await http.post(Uri.parse(url), body: body);
//   // List<dynamic> dataList = json.decode(response.body);
//   if (response.statusCode != 200) {
//     throw Exception('Failed to send email');
//   }
// }
/// 관리자 추가
Future<void> addNotiDeleteCamera(String reson) async{
  final ns = Get.put(NotificationState());
  final us= Get.put(UserState());
  final url = '${config.baseUrl}/notiDeleteAdd';
  final body = ({
    'name':'${us.userList[0]['name']}',
    'email' : '${us.userList[0]['email']}',
    'mms' : '',
    'reason' : '${reson}',
    'createDate' : '${DateTime.now()}',
    'docId' : '${ns.notiDocId.value}',
  });
  final response = await http.post(Uri.parse(url), body: body);
  if (response.statusCode != 200) {
    print('에러에러');
    throw Exception('Failed to send email');
  }
}

// completeAgentWork 함수는 CameraNotificationService로 이동됨


/// cameraDetail switch
Future<void> cameraDetailSwitch(String cameraUid,String field, String value) async{
  final us= Get.put(UserState());
  final url = '${config.baseUrl}/getCameraDetailSwitch';
  final body = {
    'cameraUid':cameraUid,
    'field':field,
    'value':value,
  };
  final response = await http.post(Uri.parse(url), body: body);
  print('??? ${response.body}');
  if (response.statusCode != 200) {
    print('에러에러');
    throw Exception('Failed to send email');
  }
}

Future<void> cameraScanResult(String cameraUid,String field, String value, String scanresult) async{
  final us= Get.put(UserState());
  final url = '${config.baseUrl}/updatescan';
  final body = {
    'cameraUid':cameraUid,
    'field':field,
    'value':value,
    'scanresult':scanresult,
  };
  final response = await http.post(Uri.parse(url), body: body);
  if (response.statusCode != 200) {
    print('에러에러');
    throw Exception('Failed to send email');
  }
}

/// 카메라 이름 변경

/// cameraDetail switch
Future<void> cameraNameChange(String cameraUid,String cameraName) async{
  final us= Get.put(UserState());
  final url = '${config.baseUrl}/cameraNameChange';
  final body = {
    'cameraUid':cameraUid,
    'ipcamId':cameraName,
  };
  final response = await http.post(Uri.parse(url), body: body);
  if (response.statusCode != 200) {
    print('에러에러');
    throw Exception('Failed to send email');
  }
}

/// 카메라 경보음 추가
Future<void> cameraNameAdd(String cameraUid,String cameraText,String type) async{
  final us= Get.put(UserState());
  final url = '${config.baseUrl}/cameraNameAddType';
  final body = {
    'cameraUid':cameraUid,
    'alimText':cameraText,
    'type': type
  };
  final response = await http.post(Uri.parse(url), body: body);
  if (response.statusCode != 200) {
    print('에러에러');
    throw Exception('Failed to send email');
  }
}
/// 카메라 경보음 가져오기
Future<List> cameraNameGet(String cameraUid,String type) async{
  final us= Get.put(UserState());
  final cs = Get.find<CameraState>();
  final initialCameraTextList = [
    '화재 경보 벨소리',
    '화재가 감지되었습니다. 안전한 곳으로 대피하시기 바랍니다.',
    '이곳은 CCTV 녹화중입니다',
    '쓰레기 분리배출을 잘 해주셔서 감사합니다'
  ];
  cs.cameraTextList.value = initialCameraTextList;
  final url = '${config.baseUrl}/cameraNameGetType?cameraUid=$cameraUid&type=${type}';
  final response = await http.get(Uri.parse(url));
  List dataList = json.decode(response.body);
  cs.cameraTextList.addAll(dataList.map((item) => item['alimText'].toString()));
  print('불꽃감지 전체 데이터? ${cs.cameraTextList}');
  return dataList;
}
/// 카메라 경보음 삭제하기
Future<void> cameraNameDelete(String alimText,String type) async{
  final us= Get.put(UserState());
  final url = '${config.baseUrl}/cameraNameDeleteType?alimText=$alimText&type=${type}';
  final response = await http.get(Uri.parse(url));
  if (response.statusCode != 200) {
    print('에러에러');
    throw Exception('Failed to send email');
  }
}

/////////

enum TtsType { fire, smoke, motion }


/// 통합된 TTS 저장 함수
Future<void> saveTts(BuildContext context, TextEditingController ttsEditingController, bool change, TtsType type) async {
  final flutterTts = FlutterTts();
  final dios = dio.Dio(dio.BaseOptions(
      connectTimeout: 10000,
      receiveTimeout: 10000
  ));
  final cs = Get.find<CameraState>();
  final appDocDir = await getApplicationDocumentsDirectory();

  // 타입별 설정
  final config = _getTtsConfig(type);
  final filePath = '${appDocDir.path}/${config.fileName}';
  final fileName = Platform.isAndroid ? filePath : config.fileName;

  try {
    // iOS 설정
    if (Platform.isIOS) {
      await flutterTts.setSharedInstance(true);
      await flutterTts.setIosAudioCategory(
        IosTextToSpeechAudioCategory.ambient,
        [
          IosTextToSpeechAudioCategoryOptions.allowBluetooth,
          IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
          IosTextToSpeechAudioCategoryOptions.mixWithOthers
        ],
        IosTextToSpeechAudioMode.voicePrompt,
      );
    }

    // TTS 설정
    await flutterTts.setLanguage('ko-KR');
    await flutterTts.setSpeechRate(0.5);

    // 에러 핸들러 설정
    flutterTts.setErrorHandler((message) {
      print('TTS Error: $message');
      DialogManager.hideLoading();
      showOnlyConfirmTapDialog(
        context,
        'TTS 오류가 발생했습니다. 다시 시도해주세요.',
            () {
          cs.cameraSuccess.value = false;
          _navigateBack(change);
        },
      );
    });

    // 완료 핸들러 설정
    flutterTts.setCompletionHandler(() async {
      try {
        // 파일 존재 확인
        final file = File(filePath);
        if (!await file.exists()) {
          throw Exception('음성 파일 생성에 실패했습니다.');
        }

        final url = '${config.apiUrl}?cameraUid=${cs.cameraUID.value}';
        print('File path: $filePath');

        // 파일을 MultipartFormData로 변환
        final formData = await dio.FormData.fromMap({
          "file": await dio.MultipartFile.fromFile(
            filePath,
            filename: "${cs.cameraUID.value}.wav",
          ),
        });

        final response = await dios.post(url, data: formData);
        final voiceUri = response.data as String;
        print("Voice URI: $voiceUri");

        final voiceSet = await cs.cameraDevice!.customSound!.setVoiceInfo(
          voiceUri,
          config.soundType,
          1,
          config.soundId,
          playTimes: '1',
          playInDevice: true,
        );

        if (voiceSet == true) {
          // 성공 처리
          final ttsText = ttsEditingController.text;
          await cameraDetailSwitch(cs.cameraUID.value, config.ttsKey, ttsText);
          cs.cameraDetailList[0][config.ttsKey] = ttsText;
          cs.cameraSuccess.value = true;

          if (!change) {
            await cameraNameAdd(cs.cameraUID.value, ttsText, config.nameAddType);
            cs.cameraTextList.add(ttsText);
            cs.cameraDetailList[0][config.ttsKey] = ttsText;
            cs.cameraDetailList.refresh();
          }

          showOnlyConfirmTapDialog(context, '등록되었습니다.', () {
            _navigateBack(change);
          });
        } else {
          // 실패 처리
          showOnlyConfirmTapDialog(
            context,
            '알림소리 변경을 실패하였습니다. 잠시 후 다시 실행해주세요.',
                () {
              cs.cameraSuccess.value = false;
              _navigateBack(change);
            },
          );
        }
      } catch (e) {
        print('API Error: $e');
        showOnlyConfirmTapDialog(
          context,
          '오류가 발생했습니다. 잠시 후 다시 시도해주세요.',
              () {
            cs.cameraSuccess.value = false;
            _navigateBack(change);
          },
        );
      } finally {
        DialogManager.hideLoading();
        // 임시 파일 정리
        try {
          final file = File(filePath);
          if (await file.exists()) {
            await file.delete();
          }
        } catch (e) {
          print('File cleanup error: $e');
        }
      }
    });

    // TTS 파일 생성
    await flutterTts.synthesizeToFile(ttsEditingController.text, fileName);

  } catch (e) {
    print('TTS Setup Error: $e');
    DialogManager.hideLoading();
    showOnlyConfirmTapDialog(
      context,
      'TTS 설정 중 오류가 발생했습니다.',
          () {
        cs.cameraSuccess.value = false;
        _navigateBack(change);
      },
    );
  }
}



// 타입별 설정을 반환하는 헬퍼 함수
class TtsConfig {
  final String fileName;
  final String apiUrl;
  final String soundType;
  final int soundId;
  final String ttsKey;
  final String nameAddType;

  TtsConfig({
    required this.fileName,
    required this.apiUrl,
    required this.soundType,
    required this.soundId,
    required this.ttsKey,
    required this.nameAddType,
  });
}

TtsConfig _getTtsConfig(TtsType type) {
  switch (type) {
    case TtsType.fire:
      return TtsConfig(
        fileName: 'tts.wav',
        apiUrl: '${config.baseUrl}/tts',
        soundType: 'fire',
        soundId: 7,
        ttsKey: 'fireTts',
        nameAddType: '0',
      );
    case TtsType.smoke:
      return TtsConfig(
        fileName: 'ttsSmoke.wav',
        apiUrl: '${config.baseUrl}/ttsSmoke',
        soundType: 'smoks',
        soundId: 8,
        ttsKey: 'smokeTts',
        nameAddType: '1',
      );
    case TtsType.motion:
      return TtsConfig(
        fileName: 'ttsMotion.wav',
        apiUrl: '${config.baseUrl}/ttsMotion',
        soundType: 'motion',
        soundId: 3,
        ttsKey: 'motionTts',
        nameAddType: '2',
      );
  }
}

// 네비게이션 헬퍼 함수
void _navigateBack(bool change) {
  if (change) {
    Get.back();
  } else {
    Get.back();
    Get.back();
  }
}
/////////

/// fire
// Future<void> saveTts(BuildContext context, TextEditingController ttsEditingController, bool change) async {
//   final flutterTts = FlutterTts();
//   final dios = dio.Dio();
//   final cs = Get.find<CameraState>();
//   final appDocDir = await getApplicationDocumentsDirectory();
//   final filePath = '${appDocDir.path}/tts.wav';
//   final fileName = Platform.isAndroid ? filePath : 'tts.wav';
//
//   try {
//     // iOS 설정
//     if (Platform.isIOS) {
//       await flutterTts.setSharedInstance(true);
//       await flutterTts.setIosAudioCategory(
//         IosTextToSpeechAudioCategory.ambient,
//         [
//           IosTextToSpeechAudioCategoryOptions.allowBluetooth,
//           IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
//           IosTextToSpeechAudioCategoryOptions.mixWithOthers
//         ],
//         IosTextToSpeechAudioMode.voicePrompt,
//       );
//     }
//
//     // TTS 설정
//     await flutterTts.setLanguage('ko-KR');
//     await flutterTts.setSpeechRate(0.5);
//
//     // 에러 핸들러 설정
//     flutterTts.setErrorHandler((message) {
//       print('TTS Error: $message');
//     });
//
//     // 완료 핸들러 설정
//     flutterTts.setCompletionHandler(() async {
//       try {
//         final url = '${config.apiUrl}/tts?cameraUid=${cs.cameraUID.value}';
//         print('File path: $filePath');
//
//         // 파일을 MultipartFormData로 변환
//         final formData = await dio.FormData.fromMap({
//           "file": await dio.MultipartFile.fromFileSync(
//             filePath,
//             filename: "${cs.cameraUID.value}.wav",
//           ),
//         });
//
//         final response = await dios.post(url, data: formData);
//         final voiceUri = response.data as String;
//         print("Voice URI: $voiceUri");
//
//         final voiceSet = await cs.cameraDevice!.customSound!.setVoiceInfo(
//           voiceUri,
//           'fire',
//           1,
//           7,
//           playTimes: '1',
//           playInDevice: true,
//         );
//
//         if (voiceSet == true) {
//           // 성공 처리
//           final ttsText = ttsEditingController.text;
//           await cameraDetailSwitch(cs.cameraUID.value, 'fireTts', ttsText);
//           cs.cameraDetailList[0]['fireTts'] = ttsText;
//           cs.cameraSuccess.value = true;
//
//           if (!change) {
//             await cameraNameAdd(cs.cameraUID.value, ttsText, '0');
//             cs.cameraTextList.add(ttsText);
//             cs.cameraDetailList[0]['fireTts'] = ttsText;
//             cs.cameraDetailList.refresh();
//           }
//
//           showOnlyConfirmTapDialog(context, '등록되었습니다.', () {
//            if(change) {
//               Get.back();
//            }else {
//               Get.back();
//               Get.back();
//            }
//           });
//         } else {
//           // 실패 처리
//           showOnlyConfirmTapDialog(
//             context,
//             '알림소리 변경을 실패하였습니다 잠시후 다시 실행해주세요',
//                 () {
//               cs.cameraSuccess.value = false;
//               Get.back();
//             },
//           );
//         }
//       } catch (e) {
//         // 기타 오류 처리
//         print('API Error: $e');
//         showOnlyConfirmTapDialog(
//           context,
//           '오류가 발생했습니다. 잠시 후 다시 시도해주세요.',
//               () {
//             cs.cameraSuccess.value = false;
//             Get.back();
//           },
//         );
//       } finally {
//         DialogManager.hideLoading();
//       }
//     });
//
//     // TTS 파일 생성
//     await flutterTts.synthesizeToFile(ttsEditingController.text, fileName);
//
//   } catch (e) {
//     // 기타 오류 처리
//     print('API Error: $e');
//     showOnlyConfirmTapDialog(
//       context,
//       '오류가 발생했습니다. 잠시 후 다시 시도해주세요.',
//           () {
//         cs.cameraSuccess.value = false;
//         Get.back();
//       },
//     );
//   }
// }
/// smoke
// Future<void> smokeSaveTts(BuildContext context,TextEditingController TTSEditingController,bool change) async {
//   FlutterTts flutterTts = FlutterTts();
//   dio.Dio dios = dio.Dio(dio.BaseOptions(
//       connectTimeout: 10000,
//       receiveTimeout: 10000
//   ));
//   final cs = Get.find<CameraState>();
//   Directory? appDocDir = await getApplicationDocumentsDirectory();
//   String filePath = '${appDocDir.path}/ttsSmoke.wav';
//   String filePath2 = 'ttsSmoke.wav';
//   if(Platform.isIOS){
//     await flutterTts.setSharedInstance(true);
//     await flutterTts.setIosAudioCategory(IosTextToSpeechAudioCategory.ambient,
//         [
//           IosTextToSpeechAudioCategoryOptions.allowBluetooth,
//           IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
//           IosTextToSpeechAudioCategoryOptions.mixWithOthers
//         ],
//         IosTextToSpeechAudioMode.voicePrompt
//     );
//   }
//   await flutterTts.setLanguage('ko-KR');
//   await flutterTts.setSpeechRate(0.5);
//   await flutterTts.synthesizeToFile(TTSEditingController.text, Platform.isAndroid?filePath:filePath2);
//   flutterTts.setCompletionHandler(() async{
//     final url = '${config.apiUrl}/ttsSmoke?cameraUid=${cs.cameraUID.value}';
//     /// 파일을 MultipartFormData로 변환
//     final formData = await dio.FormData.fromMap({
//       "file": await dio.MultipartFile.fromFileSync(filePath, filename: "${cs.cameraUID.value}.wav"),
//     });
//     try{
//       var response = await dios.post(url, data: formData).then((value)async{
//         String voiceUri = value.data;
//         bool? voiceSet = await cs.cameraDevice!.customSound?.setVoiceInfo(voiceUri, 'smoks', 1, 8,playTimes: '1',playInDevice: true);
//         Get.back();
//         if(voiceSet !=null && voiceSet){
//           await cameraDetailSwitch(cs.cameraUID.value,'smokeTts','${TTSEditingController.text}');
//           cs.cameraSuccess.value = true;
//           if(!change){
//             await cameraNameAdd(cs.cameraUID.value, TTSEditingController.text,'1');
//             cs.cameraTextList.add(TTSEditingController.text);
//             cs.cameraDetailList[0]['smokeTts'] = TTSEditingController.text;
//             cs.cameraDetailList.refresh();
//           }
//           showOnlyConfirmTapDialog(context, '등록되었습니다.', () {
//             if(change==true){
//               Get.back();
//             }else{
//               Get.back();
//               Get.back();
//             }
//           });
//         }else{
//           cs.cameraSuccess.value = false;
//           showOnlyConfirmTapDialog(context, '알림소리 변경을 실패하였습니다 잠시후 다시 실행해주세요', () {
//             if(change==true){
//               Get.back();
//             }else{
//               Get.back();
//               Get.back();
//             }
//           });
//         }
//       });
//     }catch(e){
//       cs.cameraSuccess.value = false;
//       if(change==true){
//         Get.back();
//       }else{
//         Get.back();
//         Get.back();
//       }
//     }
//   });
//   flutterTts.setErrorHandler((message) {print('mess?? ${message}');});
// }
/// motion
// Future<void> motionSaveTts(BuildContext context,TextEditingController TTSEditingController,bool change) async {
//   FlutterTts flutterTts = FlutterTts();
//   dio.Dio dios = dio.Dio(dio.BaseOptions(
//       connectTimeout: 10000,
//       receiveTimeout: 10000
//   ));
//   final cs = Get.find<CameraState>();
//   Directory? appDocDir = await getApplicationDocumentsDirectory();
//   String filePath = '${appDocDir.path}/ttsMotion.wav';
//   String filePath2 = 'ttsMotion.wav';
//   if(Platform.isIOS){
//     await flutterTts.setSharedInstance(true);
//     await flutterTts.setIosAudioCategory(IosTextToSpeechAudioCategory.ambient,
//         [
//           IosTextToSpeechAudioCategoryOptions.allowBluetooth,
//           IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
//           IosTextToSpeechAudioCategoryOptions.mixWithOthers
//         ],
//         IosTextToSpeechAudioMode.voicePrompt
//     );
//   }
//   await flutterTts.setLanguage('ko-KR');
//   await flutterTts.setSpeechRate(0.5);
//   await flutterTts.synthesizeToFile(TTSEditingController.text, Platform.isAndroid?filePath:filePath2);
//   flutterTts.setCompletionHandler(() async{
//     final url = '${config.apiUrl}/ttsMotion?cameraUid=${cs.cameraUID.value}';
//     /// 파일을 MultipartFormData로 변환
//     final formData = await dio.FormData.fromMap({
//       "file": await dio.MultipartFile.fromFileSync(filePath, filename: "${cs.cameraUID.value}.wav"),
//     });
//     try{
//       var response = await dios.post(url, data: formData).then((value)async{
//         String voiceUri = value.data;
//         bool? voiceSet = await cs.cameraDevice!.customSound!.setVoiceInfo(voiceUri, 'motion', 1, 3, playTimes: '1',playInDevice: true);
//         Get.back();
//         if(voiceSet !=null && voiceSet){
//           await cameraDetailSwitch(cs.cameraUID.value,'motionTts','${TTSEditingController.text}');
//           cs.cameraSuccess.value = true;
//           if(!change){
//             await cameraNameAdd(cs.cameraUID.value, TTSEditingController.text,'2');
//             cs.cameraTextList.add(TTSEditingController.text);
//             cs.cameraDetailList[0]['motionTts'] = TTSEditingController.text;
//             cs.cameraDetailList.refresh();
//           }
//           showOnlyConfirmTapDialog(context, '등록되었습니다.', () {
//             if(change==true){
//               Get.back();
//             }else{
//               Get.back();
//               Get.back();
//             }
//           });
//         }else{
//           cs.cameraSuccess.value = false;
//           showOnlyConfirmTapDialog(context, '알림소리 변경을 실패하였습니다 잠시후 다시 실행해주세요', () {
//             if(change==true){
//               Get.back();
//             }else{
//               Get.back();
//               Get.back();
//             }
//           });
//         }
//       });
//     }catch(e){
//       cs.cameraSuccess.value = false;
//       if(change==true){
//         Get.back();
//       }else{
//         Get.back();
//         Get.back();
//       }
//     }
//   });
//   flutterTts.setErrorHandler((message) {print('mess?? ${message}');});
// }

/// demo
Future<void> demoSaveTts(BuildContext context, TextEditingController ttsEditingController, bool change, String type) async {
  final cs = Get.find<CameraState>();

  // 타입별 설정값 맵핑
  final typeConfigs = {
    'fire': {'soundType': 7, 'ttsType': 'fireTts'},
    'smoks': {'soundType': 8, 'ttsType': 'smokeTts'},
  };

  final soundType = typeConfigs[type]?['soundType'] ?? 3;
  final ttsType = typeConfigs[type]?['ttsType'] ?? 'motionTts';
  final voiceUri = '${config.baseUrl}/ttsDemo';

  try {
    final voiceSet = await cs.cameraDevice!.customSound!.setVoiceInfo(
        voiceUri,
        type,
        1,
        soundType as int,
        playTimes: '1',
        playInDevice: true
    );

    final message = voiceSet
        ? '등록되었습니다.'
        : '알림소리 변경을 실패하였습니다 잠시후 다시 실행해주세요';

    cs.cameraSuccess.value = voiceSet;

    if (voiceSet) {
      Get.back();
      await cameraDetailSwitch(cs.cameraUID.value, ttsType as String, ttsEditingController.text);
    }

    showOnlyConfirmTapDialog(context, message, () {
      if (!change) Get.back();
      if (voiceSet && !change) Get.back();
    });

  } catch (e) {
    cs.cameraSuccess.value = false;
    Get.back();
    if (!change) Get.back();
  } finally {
    DialogManager.hideLoading();
  }
}


Future<void> stopNotification(String body) async {
  final config = AppConfig();

  try {
    final response = await http.post(
      // Uri.parse('http://mmskorea.net/stopNotification'),
      Uri.parse('http://${config.cameraNotiUrl}/stopNotification'),
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

/// 사유 추가 할 때 시간 업데이트
Future<void> cameraLastSendTime(String body) async {
  final config = AppConfig();

  try {
    final response = await http.post(
      Uri.parse('http://${config.cameraNotiUrl}/cameraLastSendTime'),
      // Uri.parse('http://misnetwork.iptime.org:9090/cameraLastSendTime'),
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
/// 카메라 알림 해제
Future<void> cameraTimeUpdateNull(String cameraUid,String field) async{
  final us= Get.put(UserState());
  final url = '${config.baseUrl}/cameraTimeUpdate?cameraUid=$cameraUid&field=${field}';
  final response = await http.get(Uri.parse(url));
  if (response.statusCode != 200) {
    print('에러에러');
    throw Exception('Failed to send email');
  }
}

/**
 * 함수 설명: 카메라 비밀번호 DB 갱신
 *
 * 작성자: 이호준
 * 최초 작성일: 2024-12-01
 * 수정 이력:
 *   -
 */
Future<void> updateCameraPassword(String cameraUid, String password) async {
  final url = '${config.baseUrl}/cameras/$cameraUid/password';
  final body = {
    'password': password,
  };

  final response = await http.patch(
    Uri.parse(url),
    headers: {
      'Content-Type': 'application/json',
    },
    body: jsonEncode(body),
  );

  if (response.statusCode != 200) {
    print('응답 코드: ${response.statusCode}');
    print('응답 내용: ${response.body}');
    throw Exception('카메라 비밀번호 변경 실패');
  }
}