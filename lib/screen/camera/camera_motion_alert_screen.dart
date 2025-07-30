import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../utils/device_manager.dart';
import '../../base_config/config.dart';
import '../../components/changeDialog.dart';
import '../../components/dialog.dart';
import '../../components/dialogManager.dart';
import '../../components/switch.dart';
import '../../db/camera_table.dart';
import '../../provider/camera_state.dart';
import '../../utils/color.dart';
import '../../utils/font/font.dart';

class CameraMotionAlertScreen extends StatefulWidget {
  const CameraMotionAlertScreen({Key? key}) : super(key: key);

  @override
  State<CameraMotionAlertScreen> createState() => _CameraMotionAlertScreenState();
}

class _CameraMotionAlertScreenState extends State<CameraMotionAlertScreen> {
  final cs = Get.find<CameraState>();
  final config = AppConfig();
  Map? motionValue;
  double _currentSliderValue = 0;
  TextEditingController TTSEditingController = TextEditingController();
  int selectedIndex = 0;

  @override
  void initState() {
    Future.delayed(Duration.zero,()async{
      bool test2 = await  cs.cameraDevice!.customSound!.getVoiceInfo(3);
      motionValue = await cs.cameraDevice!.customSound!.soundData;
      double motionSlider = 0.0;
      if(cs.cameraDetailList[0]['motionSensitivity']=='1'){
        motionSlider = 0.0;
      }else if(cs.cameraDetailList[0]['motionSensitivity']=='5'){
        motionSlider = 1.5;
      }else if(cs.cameraDetailList[0]['motionSensitivity']=='9'){
        motionSlider = 3.0;
      }
      _currentSliderValue = motionSlider;
      await cameraNameGet(cs.cameraUID.value,'2');
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
          '모션 감지 설정',
          style: f16w700Size(),
        ),
        centerTitle: true,
      ),
      backgroundColor: Colors.white,
      body: Padding(
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
              child:Padding(
                padding: const EdgeInsets.all(10.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '모션감지',
                      style: f18w700Size(),
                    ),
                    SwitchButton(
                        onTap: () async {
                          await motionSwitcher();
                        },
                        value: bool.parse(cs.cameraDetailList[0]['motionDetect']))
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
                        thumbColor:  blueColor,
                        activeTickMarkColor:  blueColor,
                        valueIndicatorColor: blueColor,
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
                          motionSensitiveSwitcher(value);
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
                              if(cs.cameraDetailList[0]['motionTts']!=null){
                                if(motionValue?['url'].toString()!='mute'){
                                  // bool test = await DeviceManager.getInstance().mDevice!.customSound!.setVoiceInfo('${config.apiUrl}/motion/${cs.cameraUID.value}', 'motion',0,3, playTimes: '1');
                                  bool test = await DeviceManager.getInstance().mDevice!.customSound!.setVoiceInfo('mute','motion',1,3, playTimes: '1', playInDevice: true);
                                  bool test2 = await DeviceManager.getInstance().mDevice!.customSound!.setVoiceInfo('mute','motion',1,3, playTimes: '1');
                                  if(test){
                                    motionValue?['url']= 'mute';
                                  }
                                }else{
                                  bool test =  await DeviceManager.getInstance().mDevice!.customSound!.setVoiceInfo('${config.apiUrl}/motion/${cs.cameraUID.value}','motion',1,3,playTimes: '1', playInDevice: true);
                                  bool test2 =  await DeviceManager.getInstance().mDevice!.customSound!.setVoiceInfo('${config.apiUrl}/motion/${cs.cameraUID.value}','motion',1,3,playTimes: '1',);
                                  if(test){
                                    motionValue?['url'] = '${config.apiUrl}/motion/${cs.cameraUID.value}';
                                  }
                                }
                              }
                              else {
                                if(motionValue?['url'].toString()!='mute'){
                                  // bool test = await cs.cameraDevice!.customSound!.setVoiceInfo('${config.apiUrl}/ttsDemo', 'motion', 0, 3,playTimes: '1');
                                  bool test = await cs.cameraDevice!.customSound!.setVoiceInfo('mute', 'motion', 1, 3,playTimes: '1', playInDevice: true);
                                  bool test2 = await cs.cameraDevice!.customSound!.setVoiceInfo('mute', 'motion', 1, 3,playTimes: '1');
                                  if(test){
                                    motionValue?['url']= 'mute';
                                  }
                                }else{
                                  bool test = await cs.cameraDevice!.customSound!.setVoiceInfo('${config.apiUrl}/ttsDemo', 'motion', 1, 3,playTimes: '1', playInDevice: true);
                                  bool test2 = await cs.cameraDevice!.customSound!.setVoiceInfo('${config.apiUrl}/ttsDemo', 'motion', 1, 3,playTimes: '1');
                                  if(test){
                                    motionValue?['url']= '${config.apiUrl}/motion/${cs.cameraUID.value}';
                                  }
                                }
                              }
                              setState(() {});
                              DialogManager.hideLoading();
                            },
                            value: motionValue?['url'].toString()=='mute'?false:true)
                      ],
                    ),
                    const SizedBox(height: 10,),
                    Text('움직임 발생 시 카메라에서 소리를 낼 수 있습니다',style: f14w700BlurGrey,),
                    const SizedBox(height: 20,),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '알림 경보음',
                          style: f18w700Size(),
                        ),
                        motionValue?['url'].toString()=='mute'?const SizedBox():GestureDetector(
                          onTap: ()
                          {
                            showMotionSoundChangeDialog(context,selectedIndex,'알림 경보음 선택',(int selected)async{
                              selectedIndex = selected;
                              TTSEditingController.text = cs.cameraTextList[selectedIndex];
                              cs.cameraDetailList[0]['motionTts'] = TTSEditingController.text;
                              setState(() {});
                            },oneTimeVoiceClick,()async{
                              if(selectedIndex>3){
                                await cameraDetailSwitch(cs.cameraUID.value,'motionTts','화재 경보 벨소리');
                                TTSEditingController.text = '화재 경보 벨소리';
                                cs.cameraDetailList[0]['motionTts'] = TTSEditingController.text;
                                selectedIndex=0;
                                setState(() {});
                                String voiceUri = '${config.apiUrl}/ttsDemo';
                                await cs.cameraDevice!.customSound!.setVoiceInfo(voiceUri, 'motion', 1, 3, playTimes: '1',playInDevice: true);
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
                          '${motionValue?['url'].toString()=='mute'?'':cs.cameraDetailList[0]['motionTts']}',
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
                        motionValue?['url'].toString()=='mute'?const SizedBox():GestureDetector(
                          onTap: ()async{
                            await showCameraNameAddDialog(context,'2');
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
                          '경보 라이트',
                          style: f18w700Size(),
                        ),
                        SwitchButton(
                            onTap: () async {
                              await motionLightSwitcher();
                            },
                            value: bool.parse(cs.cameraDetailList[0]['motionLight']))
                      ],
                    ),
                    const SizedBox(height: 10,),
                    Text('움직임 감지시 자동으로 라이트를 점등합니다',style: f14w700BlurGrey,),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }


  /// 모션감지 on/off
  Future<void> motionSwitcher() async {
    /// 모션감지 끌때
    if(cs.cameraDetailList[0]['motionDetect']=='true'){
      bool test1 = await DeviceManager.getInstance().mDevice
          ?.setAlarmMotionDetection(false, int.parse('${cs.cameraDetailList[0]['motionSensitivity']}')) ?? false;
      bool? test = await DeviceManager.getInstance().mDevice?.setAlarmPlan(
          2,
          0,
          -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
          -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
          -1
      );
      if(test==true){
        await cameraDetailSwitch(cs.cameraUID.value,'motionDetect', 'false');
        final updatedCameraDetailList = [...cs.cameraDetailList];
        cs.cameraDetailList[0]['motionDetect'] = 'false';
        cs.cameraDetailList.assignAll(updatedCameraDetailList);
        cs.motionSwitch.value = false;
      }
    }
    /// 모션감지 킬때
    else{
      bool test = await DeviceManager.getInstance().mDevice
          ?.setAlarmMotionDetection(true, int.parse('${cs.cameraDetailList[0]['motionSensitivity']}')) ?? false;
      bool? test1 = await DeviceManager.getInstance().mDevice?.setAlarmPlan(
          2,
          1,
          -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
          -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
          -1
      );
      if(test1==true){
        await cameraDetailSwitch(cs.cameraUID.value,'motionDetect', 'true');
        final updatedCameraDetailList = [...cs.cameraDetailList];
        cs.cameraDetailList[0]['motionDetect'] = 'true';
        cs.cameraDetailList.assignAll(updatedCameraDetailList);
        cs.motionSwitch.value = true;
      }
    }
    setState(() {});
  }
  /// 모션감지 민감도 설정
  Future<void> motionSensitiveSwitcher(value) async {
    int level = 0;
    if(value.round().toString() == '0'){
      level = 1;
    }else if(value.round().toString() == '2'){
      level = 5;
    }else {
      level = 9;
    }
    bool test = await DeviceManager.getInstance().mDevice
        ?.setAlarmMotionDetection(bool.parse(cs.cameraDetailList[0]['motionDetect']), level) ?? false;
    if(test){
      await cameraDetailSwitch(cs.cameraUID.value,'motionSensitivity', '${level}');
      cs.cameraDetailList[0]['motionSensitivity'] = '${level}';
      setState(() {
        _currentSliderValue = value;
      });
    }
  }
  ///모션 경보라이트 on/off
  Future<void> motionLightSwitcher() async {
    /// 모션감지 끌때
    if(cs.cameraDetailList[0]['motionLight']=='true'){
      bool test1 = await DeviceManager.getInstance()
          .mDevice
          ?.lightCommand
          ?.controlLightMode(0) ?? false;
      if(test1){
        await cameraDetailSwitch(cs.cameraUID.value,'motionLight', 'false');
        final updatedCameraDetailList = [...cs.cameraDetailList];
        cs.cameraDetailList[0]['motionLight'] = 'false';
        cs.cameraDetailList.assignAll(updatedCameraDetailList);
        // _alertLight = false;
      }
    }
    /// 모션감지 킬때
    else{
      bool test1 = await DeviceManager.getInstance()
          .mDevice
          ?.lightCommand
          ?.controlLightMode(2) ?? false;
      if(test1){
        await cameraDetailSwitch(cs.cameraUID.value,'motionLight', 'true');
        final updatedCameraDetailList = [...cs.cameraDetailList];
        cs.cameraDetailList[0]['motionLight'] = 'true';
        cs.cameraDetailList.assignAll(updatedCameraDetailList);
        // _alertLight = true;
      }
    }
    setState(() {});
  }

  Future<void> oneTimeVoiceClick ()async{

    DialogManager.showLoading(context);
    bool? voiceSet;
    if(selectedIndex==0){
      String voiceUri = '${config.apiUrl}/ttsDemo';
      voiceSet = await cs.cameraDevice!.customSound!.setVoiceInfo(voiceUri, 'motion', 1, 3, playTimes: '1',playInDevice: true);
    }else{
      String voiceUri = '${config.apiUrl}/motion/${cs.cameraUID.value}';
      voiceSet = await cs.cameraDevice!.customSound?.setVoiceInfo(voiceUri, 'motion', 1, 3,playInDevice: true,playTimes: '1');
    }

    Get.back();
    if (voiceSet != null && voiceSet==false) {
      showOnlyConfirmTapDialog(context, '잠시후 다시 시도해주세요', () {
        Get.back();
      });
    }
  }
  Future<void> checkTextIndex()async{
    if(cs.cameraDetailList[0]['motionTts']==null){
      cs.cameraDetailList[0]['motionTts'] = '화재 경보 벨소리';
      selectedIndex = 0;
    }else{
      selectedIndex = cs.cameraTextList.indexWhere((element) => element == cs.cameraDetailList[0]['motionTts']);
      if(selectedIndex == -1){
        selectedIndex = -1;
      }
    }
  }
}
