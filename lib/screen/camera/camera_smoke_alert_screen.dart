import 'package:dio/dio.dart' as dio;
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:get/get.dart';
import 'package:mms/components/dialogManager.dart';

import '../../../../utils/device_manager.dart';
import '../../base_config/config.dart';
import '../../components/changeDialog.dart';
import '../../components/dialog.dart';
import '../../components/switch.dart';
import '../../db/camera_table.dart';
import '../../provider/camera_state.dart';
import '../../utils/color.dart';
import '../../utils/font/font.dart';

class CameraSmokeAlertScreen extends StatefulWidget {
  const CameraSmokeAlertScreen({Key? key}) : super(key: key);

  @override
  State<CameraSmokeAlertScreen> createState() => _CameraSmokeAlertScreenState();
}

class _CameraSmokeAlertScreenState extends State<CameraSmokeAlertScreen> {
  final config = AppConfig();
  final cs = Get.find<CameraState>();
  FlutterTts flutterTts = FlutterTts();
  dio.Dio dios = dio.Dio();
  double _currentSliderValue = 0;
  Map? smokeValue;
  TextEditingController TTSEditingController = TextEditingController();


  int selectedIndex = 0;

  @override
  void initState() {
    Future.delayed(Duration.zero,()async{
      bool test2 = await cs.cameraDevice!.customSound!.getVoiceInfo(8);
      smokeValue = await cs.cameraDevice!.customSound!.soundData;
      double smokeSlider = 0.0;
      if(cs.cameraDetailList[0]['smokeSensitivity']=='1'){
        smokeSlider = 0.0;
      }else if(cs.cameraDetailList[0]['smokeSensitivity']=='2'){
        smokeSlider = 1.5;
      }else if(cs.cameraDetailList[0]['smokeSensitivity']=='3'){
        smokeSlider = 3.0;
      }
      _currentSliderValue = smokeSlider;
      await cameraNameGet(cs.cameraUID.value,'1');
      await checkTextIndex();
      setState(() {});
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        automaticallyImplyLeading: true,
        title: Text(
          '연기 감지 설정',
          style: f16w700Size(),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: GestureDetector(
              onTap: (){
                showCameraSettingValue(context);
              },
              child: Container(
                decoration: BoxDecoration(
                    color: Color(0xff89AAFF),
                    borderRadius: BorderRadius.circular(20)
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10,vertical: 5),
                  child: Text('카메라 셋팅값',style: f16w700WhiteSize(),),
                ),
              ),
            ),
          )
        ],
        centerTitle: true,
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: Get.width,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Color(0xffF1F4F7),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '연기감지',
                        style: f18w700Size(),
                      ),
                      SwitchButton(
                          onTap: () async {
                            if(cs.cameraDetailList[0]['fireDetect']=='true'){
                              /// 연기감지 끌때
                              if(cs.cameraDetailList[0]['smokeDetect']=='true'){
                                bool? test = await DeviceManager.getInstance().mDevice?.writeCgi('trans_cmd_string.cgi?cmd=2206&appCode=smokefire@YTLD&command=1&user=admin&pwd=${cs.cameraPassword}&fire_type=1');
                                if(test==true){
                                  await cameraDetailSwitch(cs.cameraUID.value,'smokeDetect', 'false');
                                  final updatedCameraDetailList = [...cs.cameraDetailList];
                                  cs.cameraDetailList[0]['smokeDetect'] = 'false';
                                  cs.cameraDetailList.assignAll(updatedCameraDetailList);
                                  cs.smokeSwitch.value = false;
                                }
                              }
                              /// 연기감지 킬때
                              else{
                                bool? test = await DeviceManager.getInstance().mDevice?.writeCgi('trans_cmd_string.cgi?cmd=2206&appCode=smokefire@YTLD&command=1&user=admin&pwd=${cs.cameraPassword}&fire_type=2');
                                if(test == true){
                                  await cameraDetailSwitch(cs.cameraUID.value,'smokeDetect', 'true');
                                  final updatedCameraDetailList = [...cs.cameraDetailList];
                                  cs.cameraDetailList[0]['smokeDetect'] = 'true';
                                  cs.cameraDetailList.assignAll(updatedCameraDetailList);
                                  cs.smokeSwitch.value = true;
                                }
                              }
                            }
                            else{
                              /// 연기감지 끌때
                              if(cs.cameraDetailList[0]['smokeDetect']=='true'){
                                bool? test = await DeviceManager.getInstance().mDevice?.writeCgi('trans_cmd_string.cgi?cmd=2206&appCode=smokefire@YTLD&command=1&user=admin&pwd=${cs.cameraPassword}&fire_type=3');
                                if(test==true){
                                  await cameraDetailSwitch(cs.cameraUID.value,'smokeDetect', 'false');
                                  final updatedCameraDetailList = [...cs.cameraDetailList];
                                  cs.cameraDetailList[0]['smokeDetect'] = 'false';
                                  cs.cameraDetailList.assignAll(updatedCameraDetailList);
                                  cs.smokeSwitch.value = false;
                                }
                              }
                              /// 연기감지 킬때
                              else{
                                bool? test = await DeviceManager.getInstance().mDevice?.writeCgi('trans_cmd_string.cgi?cmd=2206&appCode=smokefire@YTLD&command=1&user=admin&pwd=${cs.cameraPassword}&fire_type=0');
                                if(test == true){
                                  await cameraDetailSwitch(cs.cameraUID.value,'smokeDetect', 'true');
                                  final updatedCameraDetailList = [...cs.cameraDetailList];
                                  cs.cameraDetailList[0]['smokeDetect'] = 'true';
                                  cs.cameraDetailList.assignAll(updatedCameraDetailList);
                                  cs.smokeSwitch.value = true;
                                }
                              }
                            }
                            setState(() {});
                          },
                          value: bool.parse(cs.cameraDetailList[0]['smokeDetect']))
                    ],
                  ),
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              Container(
                width: Get.width,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Color(0xffF1F4F7),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '감지강도',
                        style: f18w700Size(),
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      SliderTheme(
                        data: SliderThemeData(
                          activeTrackColor: blueColor,
                          // // inactiveTrackColor: Colors.red,
                          thumbColor:  blueColor,
                          activeTickMarkColor:  blueColor,
                          valueIndicatorColor: blueColor,
                          // thumbShape: RoundSliderThumbShape(
                          //   enabledThumbRadius: enabledThumbRadius,
                          //   elevation: elevation,
                          // ),
                          overlayShape: SliderComponentShape.noOverlay,
        
                          valueIndicatorShape: PaddleSliderValueIndicatorShape(),
                        ),
                        child: Slider(
                          value: _currentSliderValue,
                          max: 3,
                          divisions: 2,
                          label: _currentSliderValue.round().toString() == '0'
                              ? '낮음'
                              : _currentSliderValue.round().toString() == '2'
                              ? '중간'
                              : '높음',
                          onChanged: (double value) async{
                            int values = 0;

                            if(value.round().toString() == '0'){
                              values =1;
                            }else if(value.round().toString() == '2'){
                              values =2;
                            }else {
                              values =3;
                            }
                            print("values ${values}");
                            bool? test2 = await DeviceManager.getInstance().mDevice?.writeCgi('trans_cmd_string.cgi?cmd=2206&appCode=smokefire@YTLD&command=1&user=admin&pwd=${cs.cameraPassword}&smoke_sensitivity=$values');
                            if(test2==true){
                              await cameraDetailSwitch(cs.cameraUID.value,'smokeSensitivity', '${values}');
                              cs.cameraDetailList[0]['smokeSensitivity'] = '${values}';
                              setState(() {
                                _currentSliderValue = value;
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(height: 10,),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '낮음',
                            style: f18w700Size(),
                          ),
                          Text(
                            '중간',
                            style: f18w700Size(),
                          ),
                          Text(
                            '높음',
                            style: f18w700Size(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20,),
              // Container(
              //   width: Get.width,
              //   decoration: BoxDecoration(
              //     borderRadius: BorderRadius.circular(10),
              //     color: Color(0xffF1F4F7),
              //   ),
              //   child: Padding(
              //     padding: const EdgeInsets.all(10.0),
              //     child: Column(
              //       crossAxisAlignment: CrossAxisAlignment.start,
              //       children: [
              //         Row(
              //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
              //           children: [
              //             Text(
              //               '카메라 알림소리',
              //               style: f18w700Size(),
              //             ),
              //             SwitchButton(
              //                 onTap: () async {
              //                   if(cs.cameraDetailList[0]['smokeTts']!=''){
              //                     if(smokeValue?['switch'].toString()=='1'){
              //                       bool test = await cs.cameraDevice!.customSound!.setVoiceInfo('http://misnetwork.iptime.org:9000/smoke/${cs.cameraUID.value}', 'smokes', 0, 8, playTimes: '1');
              //                       if(test){
              //                         smokeValue?['switch']= '0';
              //                       }
              //                       print('test ${test}');
              //                     }else{
              //                       bool test = await cs.cameraDevice!.customSound!.setVoiceInfo('http://misnetwork.iptime.org:9000/smoke/${cs.cameraUID.value}', 'smokes', 1, 8,playTimes: '1');
              //                       if(test){
              //                         smokeValue?['switch']= '1';
              //                       }
              //                     }
              //                   }
              //                   else {
              //                     if(smokeValue?['switch'].toString()=='1'){
              //                       bool test = await cs.cameraDevice!.customSound!.setVoiceInfo('http://doraemon-hongkong.camera666.com/cn_yuejie_1694252725.wav', 'smokes', 0, 8,playTimes: '1',playInDevice: true);
              //                       if(test){
              //                         smokeValue?['switch']= '0';
              //                       }
              //                     }else{
              //                       bool test = await cs.cameraDevice!.customSound!.setVoiceInfo('http://doraemon-hongkong.camera666.com/cn_yuejie_1694252725.wav', 'smokes', 1, 8,playTimes: '1',playInDevice: true);
              //                       if(test){
              //                         smokeValue?['switch']= '1';
              //                       }
              //                     }
              //                   }
              //                   setState(() {});
              //                 },
              //                 value: smokeValue?['switch'].toString()=='1'?true:false)
              //           ],
              //         ),
              //         const SizedBox(height: 10,),
              //         Text('연기 발생 시 카메라에서 소리를 낼 수 있습니다',style: f14w700BlurGrey,),
              //         const SizedBox(height: 10,),
              //         GestureDetector(
              //           onTap: ()async{
              //             showCameraTextDialog(context, () async{
              //               showLoading(context);
              //               await _save();
              //             }, TTSEditingController);
              //           },
              //           child: Row(
              //             mainAxisAlignment: MainAxisAlignment.end,
              //             children: [
              //               Text(
              //                 '${cs.cameraDetailList[0]['smokeTts']}',
              //                 style: f18w500Size(),
              //               ),
              //               const SizedBox(width: 8,),
              //               Icon(Icons.keyboard_arrow_right)
              //             ],
              //           ),
              //         ),
              //       ],
              //     ),
              //   ),
              // ),
              Container(
                width: Get.width,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Color(0xffF1F4F7),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '알림 경보음 설정',
                            style: f18w700Size(),
                          ),
                          SwitchButton(
                              onTap: () async {
                                DialogManager.showLoading(context);

                                print("smokeValue?['url'] ${smokeValue?['url']}");

                                if(cs.cameraDetailList[0]['smokeTts']!=''){
                                  if(smokeValue?['url'].toString()!='mute'){
                                    // bool test = await cs.cameraDevice!.customSound!.setVoiceInfo('${config.apiUrl}/smoke/${cs.cameraUID.value}', 'smokes', 0, 8, playTimes: '1');
                                    bool test = await cs.cameraDevice!.customSound!.setVoiceInfo('mute', 'smokes', 1, 8,playTimes: '1',playInDevice: true);
                                    bool test2 = await cs.cameraDevice!.customSound!.setVoiceInfo('mute', 'smokes', 1, 8,playTimes: '1');
                                    if(test){
                                      smokeValue?['url']= 'mute';
                                    }
                                  }else{
                                    bool test = await cs.cameraDevice!.customSound!.setVoiceInfo('${config.baseUrl}/smoke/${cs.cameraUID.value}', 'smokes', 1, 8,playTimes: '1',playInDevice: true);
                                    bool test2 = await cs.cameraDevice!.customSound!.setVoiceInfo('${config.baseUrl}/smoke/${cs.cameraUID.value}', 'smokes', 1, 8,playTimes: '1');
                                    if(test){
                                      smokeValue?['url']= '${config.baseUrl}/smoke/${cs.cameraUID.value}';
                                    }
                                  }
                                }
                                else {
                                  if(smokeValue?['url'].toString()!='mute'){
                                    bool test = await cs.cameraDevice!.customSound!.setVoiceInfo('mute', 'smokes', 1, 8,playTimes: '1',playInDevice: true);
                                    bool test2 = await cs.cameraDevice!.customSound!.setVoiceInfo('mute', 'smokes', 1, 8,playTimes: '1');
                                    if(test){
                                      smokeValue?['url']= 'mute';
                                    }
                                  }else{
                                    bool test = await cs.cameraDevice!.customSound!.setVoiceInfo('${config.baseUrl}/ttsDemo', 'smokes', 1, 8,playTimes: '1',playInDevice: true);
                                    bool test2 = await cs.cameraDevice!.customSound!.setVoiceInfo('${config.baseUrl}/ttsDemo', 'smokes', 1, 8,playTimes: '1');
                                    if(test){
                                      smokeValue?['url']= '${config.baseUrl}/smoke/${cs.cameraUID.value}';
                                    }
                                  }
                                }
                                DialogManager.hideLoading();
                                setState(() {});
                              },
                              value: smokeValue?['url'].toString()=='mute'?false:true)
                        ],
                      ),
                      const SizedBox(height: 10,),
                      Text('연기 발생 시 카메라에서 소리를 낼 수 있습니다',style: f14w700BlurGrey,),
                      const SizedBox(height: 20,),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '알림 경보음',
                            style: f18w700Size(),
                          ),
                          smokeValue?['url'].toString()=='mute'?const SizedBox():GestureDetector(
                            onTap: (){
                              showSmokeSoundChangeDialog(context,selectedIndex,'알림 경보음 선택',(int selected)async{
                                selectedIndex = selected;
                                TTSEditingController.text = cs.cameraTextList[selectedIndex];
                                cs.cameraDetailList[0]['smokeTts'] = TTSEditingController.text;
                                setState(() {});
                              },oneTimeVoiceClick,()async{
                                if(selectedIndex>3){
                                    await cameraDetailSwitch(cs.cameraUID.value,'smokeTts','화재 경보 벨소리');
                                    TTSEditingController.text = '화재 경보 벨소리';
                                    cs.cameraDetailList[0]['smokeTts'] = TTSEditingController.text;
                                    selectedIndex=0;
                                    setState(() {});
                                    String voiceUri = '${config.baseUrl}/ttsDemo';
                                    await cs.cameraDevice!.customSound!.setVoiceInfo(voiceUri, 'smokes', 1, 8, playTimes: '1',playInDevice: true);
                                }
                              },TTSEditingController);
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                  color: Color(0xff89AAFF),
                                  borderRadius: BorderRadius.circular(20)
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 10,vertical: 5),
                                child: Text('변경하기',style: f16w700WhiteSize(),),
                              ),
                            ),
                          )
                        ],
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      Obx(()=>Container(
                        width: Get.width,
                        height: 50,
                        decoration: BoxDecoration(
                            color: Color(0xff808080)
                        ),
                        child:Center(
                          child: Text(
                            '${smokeValue?['url'].toString()=='mute'?'':cs.cameraDetailList[0]['smokeTts']}',
                            style: f16w700WhiteSize(),
                          ),
                        ),
                      )),
                      const SizedBox(
                        height: 20,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '경보음 추가',
                            style: f18w700Size(),
                          ),
                          smokeValue?['url'].toString()=='mute'
                              ?const SizedBox()
                              :GestureDetector(
                                onTap: ()async{
                                  await showCameraNameAddDialog(context,'1');
                                  await checkTextIndex();
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                      color: Color(0xff89AAFF),
                                      borderRadius: BorderRadius.circular(20)
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 10,vertical: 5),
                                    child: Text('추가하기',style: f16w700WhiteSize(),),
                                  ),
                                ),
                              )
                            ],
                          ),
                      const SizedBox(
                        height: 10,
                      ),
                      Text('알림 경보음을 사용자가 직접 만들 수 있습니다',style: f10w700BlurGrey),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20,),
              GestureDetector(
                onTap: (){
                  showPlaceDialog(context,()async{
                    bool? test = await DeviceManager.getInstance().mDevice?.writeCgi('trans_cmd_string.cgi?cmd=2206&appCode=smokefire@YTLD&command=1&user=admin&pwd=${cs.cameraPassword}&fire_place=0');
                    if(test == true){
                      await cameraDetailSwitch(cs.cameraUID.value,'firePlace', '실내');
                      final updatedCameraDetailList = [...cs.cameraDetailList];
                      cs.cameraDetailList[0]['firePlace'] = '실내';
                      cs.cameraDetailList.assignAll(updatedCameraDetailList);
                      Get.back();
                    }
                  },()async{
                    bool? test = await DeviceManager.getInstance().mDevice?.writeCgi('trans_cmd_string.cgi?cmd=2206&appCode=smokefire@YTLD&command=1&user=admin&pwd=${cs.cameraPassword}&fire_place=1');
                    if(test == true){
                      await cameraDetailSwitch(cs.cameraUID.value,'firePlace', '실외');
                      final updatedCameraDetailList = [...cs.cameraDetailList];
                      cs.cameraDetailList[0]['firePlace'] = '실외';
                      cs.cameraDetailList.assignAll(updatedCameraDetailList);
                      Get.back();
                    }
                  });
                },
                child: Container(
                  width: Get.width,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Color(0xffF1F4F7),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Row(
                      // mainAxisAlignment: MainAxisAlignment.spa,
                      children: [
                        Text(
                          '사용환경',
                          style: f18w700Size(),
                        ),
                        Spacer(),
                        GestureDetector(
                          onTap: (){
                            showPlaceDialog(context,()async{
                              bool? test = await DeviceManager.getInstance().mDevice?.writeCgi('trans_cmd_string.cgi?cmd=2206&appCode=smokefire@YTLD&command=1&user=admin&pwd=${cs.cameraPassword}&fire_place=0');
                              if(test == true){
                                await cameraDetailSwitch(cs.cameraUID.value,'firePlace', '실내');
                                final updatedCameraDetailList = [...cs.cameraDetailList];
                                cs.cameraDetailList[0]['firePlace'] = '실내';
                                cs.cameraDetailList.assignAll(updatedCameraDetailList);
                                Get.back();
                              }
                            },()async{
                              bool? test = await DeviceManager.getInstance().mDevice?.writeCgi('trans_cmd_string.cgi?cmd=2206&appCode=smokefire@YTLD&command=1&user=admin&pwd=${cs.cameraPassword}&fire_place=1');
                              if(test == true){
                                await cameraDetailSwitch(cs.cameraUID.value,'firePlace', '실외');
                                final updatedCameraDetailList = [...cs.cameraDetailList];
                                cs.cameraDetailList[0]['firePlace'] = '실외';
                                cs.cameraDetailList.assignAll(updatedCameraDetailList);
                                Get.back();
                              }
                            });
                          },
                          child: Obx(()=>Text(
                            '${cs.cameraDetailList[0]['firePlace']}',
                            style: f18w500Size(),
                          )),
                        ),
                        const SizedBox(width: 8,),
                        Icon(Icons.keyboard_arrow_right)
                      ],
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Future<void> oneTimeVoiceClick ()async{

    DialogManager.showLoading(context);
    bool? voiceSet;
    if(selectedIndex==0){
      String voiceUri = '${config.baseUrl}/ttsDemo';
      voiceSet = await cs.cameraDevice!.customSound!.setVoiceInfo(voiceUri, 'smokes', 1, 8, playTimes: '1',playInDevice: true);
    }else{
      String voiceUri = '${config.baseUrl}/smoke/${cs.cameraUID.value}';
      bool? voiceSet = await cs.cameraDevice!.customSound?.setVoiceInfo(voiceUri, 'smokes', 1, 8,playInDevice: true,playTimes: '1');
    }

    Get.back();
    if (voiceSet != null && voiceSet==false) {
      showOnlyConfirmTapDialog(context, '잠시후 다시 시도해주세요', () {
        Get.back();
      });
    }
  }
  Future<void> checkTextIndex()async{

    if(cs.cameraDetailList[0]['smokeTts']==''){
      cs.cameraDetailList[0]['smokeTts'] = '화재 경보 벨소리';
      selectedIndex = 0;
    }else{
      selectedIndex = cs.cameraTextList.indexWhere((element) => element == cs.cameraDetailList[0]['smokeTts']);
      if(selectedIndex == -1){
        selectedIndex = -1;
      }
    }
    setState(() {});
  }
}
