import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mms/components/dialogManager.dart';

import '../../../../utils/device_manager.dart';
import '../../base_config/config.dart';
import '../../components/changeDialog.dart';
import '../../components/dialog.dart';
import '../../components/switch.dart';
import '../../db/camera_table.dart';
import '../../provider/camera_state.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../../utils/color.dart';
import '../../utils/font/font.dart';

class CameraFireAlertScreen extends StatefulWidget {
  const CameraFireAlertScreen({Key? key}) : super(key: key);

  @override
  State<CameraFireAlertScreen> createState() => _CameraFireAlertScreenState();
}

class _CameraFireAlertScreenState extends State<CameraFireAlertScreen> {
  FlutterTts flutterTts = FlutterTts();
  final cs = Get.find<CameraState>();
  final config = AppConfig();
  TextEditingController TTSEditingController = TextEditingController();

  double _currentSliderValue = 0;
  Map? fireValue;
  int selectedIndex = 0;
  @override
  void initState() {
    Future.delayed(Duration.zero,()async{
      bool test2 = await cs.cameraDevice!.customSound!.getVoiceInfo(7);
      double fireSlider = 0.0;
      fireValue = await cs.cameraDevice!.customSound!.soundData;
      print('??? ${await cs.cameraDevice!.customSound!.soundData}');
      if(cs.cameraDetailList[0]['fireSensitivity']=='1'){
        fireSlider = 0.0;
      }else if(cs.cameraDetailList[0]['fireSensitivity']=='2'){
        fireSlider = 1.5;
      }else if(cs.cameraDetailList[0]['fireSensitivity']=='3'){
        fireSlider = 3.0;
      }
      _currentSliderValue = fireSlider;
      await cameraNameGet(cs.cameraUID.value,'0');
      await checkTextIndex();
    });
    super.initState();
  }

  @override
  void dispose() {
    TTSEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: FocusScope.of(context).unfocus,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          automaticallyImplyLeading: true,
          title: Text(
            '불꽃 감지 설정',
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
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '불꽃감지',
                          style: f18w700Size(),
                        ),
                        SwitchButton(
                            onTap: () async {
                              if(cs.cameraDetailList[0]['smokeDetect']=='true'){
                                /// 불꽃감지 끌때
                                if(cs.cameraDetailList[0]['fireDetect']=='true'){
                                  bool? test = await DeviceManager.getInstance().mDevice?.writeCgi('trans_cmd_string.cgi?cmd=2206&appCode=smokefire@YTLD&command=1&user=admin&pwd=${cs.cameraPassword}&fire_type=0');
                                  if(test==true){
                                    await cameraDetailSwitch(cs.cameraUID.value,'fireDetect', 'false');
                                    final updatedCameraDetailList = [...cs.cameraDetailList];
                                    cs.cameraDetailList[0]['fireDetect'] = 'false';
                                    cs.cameraDetailList.assignAll(updatedCameraDetailList);
                                    cs.fireSwitch.value = false;
                                  }
                                }
                                /// 불꽃감지 킬때
                                else{
                                  bool? test = await DeviceManager.getInstance().mDevice?.writeCgi('trans_cmd_string.cgi?cmd=2206&appCode=smokefire@YTLD&command=1&user=admin&pwd=${cs.cameraPassword}&fire_type=2');
                                  if(test == true){
                                    await cameraDetailSwitch(cs.cameraUID.value,'fireDetect', 'true');
                                    final updatedCameraDetailList = [...cs.cameraDetailList];
                                    cs.cameraDetailList[0]['fireDetect'] = 'true';
                                    cs.cameraDetailList.assignAll(updatedCameraDetailList);
                                    cs.fireSwitch.value = true;
                                  }
                                }
                              }
                              else{
                                /// 불꽃감지 끌때
                                if(cs.cameraDetailList[0]['fireDetect']=='true'){
                                  bool? test = await DeviceManager.getInstance().mDevice?.writeCgi('trans_cmd_string.cgi?cmd=2206&appCode=smokefire@YTLD&command=1&user=admin&pwd=${cs.cameraPassword}&fire_type=3');
                                  if(test==true){
                                    await cameraDetailSwitch(cs.cameraUID.value,'fireDetect', 'false');
                                    final updatedCameraDetailList = [...cs.cameraDetailList];
                                    cs.cameraDetailList[0]['fireDetect'] = 'false';
                                    cs.cameraDetailList.assignAll(updatedCameraDetailList);
                                    cs.fireSwitch.value = false;
                                  }
                                }
                                /// 불꽃감지 킬때
                                else{
                                  bool? test = await DeviceManager.getInstance().mDevice?.writeCgi('trans_cmd_string.cgi?cmd=2206&appCode=smokefire@YTLD&command=1&user=admin&pwd=${cs.cameraPassword}&fire_type=1');
                                  if(test == true){
                                    await cameraDetailSwitch(cs.cameraUID.value,'fireDetect', 'true');
                                    final updatedCameraDetailList = [...cs.cameraDetailList];
                                    cs.cameraDetailList[0]['fireDetect'] = 'true';
                                    cs.cameraDetailList.assignAll(updatedCameraDetailList);
                                    cs.fireSwitch.value = true;
                                  }
                                }
                              }
                              setState(() {});
                            },
                            value:bool.parse(cs.cameraDetailList[0]['fireDetect']))
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
                            onChanged: (double value)async {
                              int values = 0;
                              if(value.round().toString() == '0'){
                                values = 1;
                              }else if(value.round().toString() == '2'){
                                values =2;
                              }else {
                                values =3;
                              }
                              bool? test2 = await DeviceManager.getInstance().mDevice?.writeCgi('trans_cmd_string.cgi?cmd=2206&appCode=smokefire@YTLD&command=1&user=admin&pwd=${cs.cameraPassword}&fire_sensitivity=$values');
                              if(test2==true){
                                await cameraDetailSwitch(cs.cameraUID.value, 'fireSensitivity', '${values}');
                                cs.cameraDetailList[0]['fireSensitivity'] = '${values}';
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
                                  if(cs.cameraDetailList[0]['fireTts']!=''){
                                    if(fireValue?['url'].toString()!='mute'){
                                      // bool test = await cs.cameraDevice!.customSound!.setVoiceInfo('${config.apiUrl}/voice/${cs.cameraUID.value}', 'fires', 0, 7,playTimes: '1');
                                      bool test = await cs.cameraDevice!.customSound!.setVoiceInfo('mute', 'fires', 1, 7,playTimes: '1', playInDevice: true);
                                      bool test2 = await cs.cameraDevice!.customSound!.setVoiceInfo('mute', 'fires', 1, 7,playTimes: '1'); // 25/1/9 추가 해야 url이 바뀜
                                      if(test){
                                        fireValue?['url'] = 'mute';
                                      }
                                    }else{
                                      bool test = await cs.cameraDevice!.customSound!.setVoiceInfo('${config.baseUrl}/voice/${cs.cameraUID.value}', 'fires', 1, 7,playTimes: '1', playInDevice: true);
                                      bool test2 = await cs.cameraDevice!.customSound!.setVoiceInfo('${config.baseUrl}/voice/${cs.cameraUID.value}', 'fires', 1, 7,playTimes: '1'); // 25/1/9 추가 해야 url이 바뀜
                                      if(test){
                                        fireValue?['url']= '${config.baseUrl}/voice/${cs.cameraUID.value}';
                                      }
                                    }
                                  }
                                  else if(cs.cameraDetailList[0]['fireTts']==''){
                                    if(fireValue?['url'].toString()!='mute'){
                                      // bool test = await cs.cameraDevice!.customSound!.setVoiceInfo('${config.apiUrl}/ttsDemo', 'fires', 0, 7,playTimes: '1');
                                      bool test = await cs.cameraDevice!.customSound!.setVoiceInfo('mute', 'fires', 1, 7,playTimes: '1', playInDevice: true);
                                      bool test2 = await cs.cameraDevice!.customSound!.setVoiceInfo('mute', 'fires', 1, 7,playTimes: '1'); // 25/1/9 추가 해야 url이 바뀜
                                      if(test){
                                        fireValue?['url'] = 'mute';
                                      }
                                    }else{
                                      bool test = await cs.cameraDevice!.customSound!.setVoiceInfo('${config.baseUrl}/ttsDemo', 'fires', 1, 7,playTimes: '1' ,playInDevice: true);
                                      bool test2 = await cs.cameraDevice!.customSound!.setVoiceInfo('${config.baseUrl}/ttsDemo', 'fires', 1, 7,playTimes: '1'); // 25/1/9 추가 해야 url이 바뀜
                                      if(test){
                                        fireValue?['url']= '${config.baseUrl}/voice/${cs.cameraUID.value}';
                                      }
                                    }
                                  }
                                  DialogManager.hideLoading();
                                  setState(() {
                                  });
                                },
                                value: fireValue?['url'].toString()=='mute'?false:true)
                          ],
                        ),
                        const SizedBox(height: 10,),
                        Text('불꽃 발생 시 카메라에서 소리를 낼 수 있습니다',style: f14w700BlurGrey,),
                        const SizedBox(height: 20,),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '알림 경보음',
                              style: f18w700Size(),
                            ),
                            fireValue?['url'].toString()=='mute'?const SizedBox():GestureDetector(
                              onTap: (){
                                showAlimSoundChangeDialog(
                                    context,
                                    selectedIndex,
                                    '알림 경보음 선택',
                                        (int selected)async{
                                      print("여기");
                                      selectedIndex = selected;
                                      TTSEditingController.text = cs.cameraTextList[selectedIndex];
                                      cs.cameraDetailList[0]['fireTts'] = TTSEditingController.text;
                                      setState(() {});
                                    },
                                    oneTimeVoiceClick,()async{
                                      if(selectedIndex>3){
                                        print("여기");
                                        await cameraDetailSwitch(cs.cameraUID.value,'fireTts','화재 경보 벨소리');
                                        TTSEditingController.text = '화재 경보 벨소리';
                                        cs.cameraDetailList[0]['fireTts'] = TTSEditingController.text;
                                        selectedIndex=0;
                                        setState(() {});
                                        String voiceUri = '${config.baseUrl}/ttsDemo';
                                        await cs.cameraDevice!.customSound!.setVoiceInfo(voiceUri, 'fire', 1, 7, playTimes: '1',playInDevice: true);
                                      }
                                    },
                                    TTSEditingController);
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
                              '${fireValue?['url'].toString()=='mute'?'':cs.cameraDetailList[0]['fireTts']}',
                              style: f16w700WhiteSize(),
                            ),
                          ),
                        ),),
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
                            fireValue?['url'].toString()=='mute'?const SizedBox():GestureDetector(
                              onTap: ()async{
                                await showCameraNameAddDialog(context,'0');
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
                          Obx(()=>Text(
                            '${cs.cameraDetailList[0]['firePlace']}',
                            style: f18w500Size(),
                          )),
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
      ),
    );
  }
  Future<void> oneTimeVoiceClick ()async{

    DialogManager.showLoading(context);
    bool? voiceSet;
    print("여기2");
    if(selectedIndex==0){
      String voiceUri = '${config.baseUrl}/ttsDemo';
      voiceSet = await cs.cameraDevice!.customSound!.setVoiceInfo(voiceUri, 'fire', 1, 7, playTimes: '1',playInDevice: true);
    }else{
      String voiceUri = '${config.baseUrl}/voice/${cs.cameraUID.value}';
      voiceSet = await cs.cameraDevice!.customSound?.setVoiceInfo(voiceUri, 'fire', 1, 7,playInDevice: true,playTimes: '1');
    }
    Get.back();
    if (voiceSet != null && voiceSet==false) {
      showOnlyConfirmTapDialog(context, '잠시후 다시 시도해주세요', () {
        Get.back();
      });
    }
  }

  Future<void> checkTextIndex ()async{

    if(cs.cameraDetailList[0]['fireTts']==''){
      cs.cameraDetailList[0]['fireTts'] = '화재 경보 벨소리';
      selectedIndex = 0;
    }else{
      selectedIndex = cs.cameraTextList.indexWhere((element) => element == cs.cameraDetailList[0]['fireTts']);
      if(selectedIndex == -1){
        selectedIndex = -1;
      }
    }
    setState(() {});
  }
}
