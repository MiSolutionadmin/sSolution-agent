import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:get/get.dart';
import 'package:mms/components/dialogManager.dart';
import '../db/camera_table.dart';
// import '../utils/font/font.dart';
import 'monitoring_dialog.dart';
import '../utils/font/font.dart';

/// 연기 경보음 선택
showSmokeSoundChangeDialog(
    BuildContext context,
    int selectedRadio,
    String title,
    ValueChanged<int> onSelectionChanged,
    VoidCallback onTap,
    VoidCallback onDelete,
    TextEditingController con,
    ) {
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (context, StateSetter setState) {
          return Obx(()=>AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            title: Text('알림 경보음 선택', style: f20w700Size()),
            content: Container(
              width: Get.width,
              height: 500,
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('연기 발생 시 카메라에서 소리를 낼 수 있습니다.', style: f12w700BlurGrey),
                    const SizedBox(height: 14),
                    ListView.builder(
                      itemCount: cs.cameraTextList.length,
                      shrinkWrap: true,
                      physics: const ClampingScrollPhysics(),
                      itemBuilder: (_, index) {
                        return Column(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: Color(0xff808080),
                              ),
                              width: Get.width,
                              child: Padding(
                                padding: const EdgeInsets.only(right: 10),
                                child: Row(
                                  children: [
                                    Radio<int>(
                                      value: index,
                                      groupValue: selectedRadio,
                                      activeColor: Colors.white,
                                      onChanged: (int? value)async{
                                        setState(() {
                                          selectedRadio = value!;
                                          con.text = cs.cameraTextList[selectedRadio];
                                        });
                                        DialogManager.showLoading(context);
                                        if(value ==0){
                                          await demoSaveTts(context, con,true,'smoks');
                                        }else{
                                          await saveTts(context, con, true, TtsType.smoke);
                                        }
                                        onSelectionChanged(value!);
                                      },
                                    ),
                                    SizedBox(width: 8), // 간격을 조절하려면 이 값을 변경하세요
                                    Expanded(
                                      child: Text(
                                        cs.cameraTextList[index],
                                        style: f12w700WhiteSize(),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 2, // 필요한 경우 조정 가능
                                      ),
                                    ),
                                    index==selectedRadio?GestureDetector(
                                      onTap:onTap,
                                      child: Container(
                                          decoration: BoxDecoration(
                                              border: Border.all(color: Colors.white)
                                          ),
                                          child: Icon(CupertinoIcons.speaker_2,color: Colors.white,)),
                                    ):SizedBox()
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Get.back();
                      },
                      behavior: HitTestBehavior.opaque,
                      child: Center(
                        child: Container(
                          width: Get.width,
                          height: 42,
                          decoration: BoxDecoration(
                            color: Color(0xffD3D8DE),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              '돌아가기',
                              style: f16w700Size(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: (){
                        if(selectedRadio>3){
                          showConfirmTapDialog(context, '삭제하시겠습니까?', ()async{
                            await cameraNameDelete(cs.cameraTextList[selectedRadio],'1');
                            cs.cameraTextList.removeAt(selectedRadio);
                            selectedRadio = 0;
                            onDelete();
                            Get.back();
                            setState(() {});
                          });
                        }
                      },
                      behavior: HitTestBehavior.opaque,
                      child: Center(
                        child: Container(
                          width: Get.width,
                          height: 42,
                          decoration: BoxDecoration(
                            color:selectedRadio>3?Colors.red:Colors.grey,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              '삭제',
                              style: f16w700WhiteSize(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ));
        },
      );
    },
  );
}
/// 불꽃 경보음 선택 다이얼로그
showAlimSoundChangeDialog(
    BuildContext context,
    int selectedRadio,
    String title,
    ValueChanged<int> onSelectionChanged,
    VoidCallback onTap,
    VoidCallback onDelete,
    TextEditingController con,
    ) {
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (context, StateSetter setState) {
          return Obx(()=>AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            title: Text('알림 경보음 선택', style: f20w700Size()),
            content: Container(
              width: Get.width,
              height: 500,
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('불꽃 발생 시 카메라에서 소리를 낼 수 있습니다.', style: f12w700BlurGrey),
                    const SizedBox(height: 14),
                    ListView.builder(
                      itemCount: cs.cameraTextList.length,
                      shrinkWrap: true,
                      physics: const ClampingScrollPhysics(),
                      itemBuilder: (_, index) {
                        return Column(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: Color(0xff808080),
                              ),
                              width: Get.width,
                              child: Padding(
                                padding: const EdgeInsets.only(right: 10),
                                child: Row(
                                  children: [
                                    Radio<int>(
                                      value: index,
                                      groupValue: selectedRadio,
                                      activeColor: Colors.white,
                                      onChanged: (int? value)async{
                                        setState(() {
                                          selectedRadio = value!;
                                          con.text = cs.cameraTextList[selectedRadio];
                                        });
                                        DialogManager.showLoading(context);
                                        if(value == 0){
                                          await demoSaveTts(context, con,true,'fire');
                                        }else{
                                          await saveTts(context, con, true, TtsType.fire);
                                        }
                                        onSelectionChanged(value!);
                                      },
                                    ),
                                    SizedBox(width: 8), // 간격을 조절하려면 이 값을 변경하세요
                                    Expanded(
                                      child: Text(
                                        cs.cameraTextList[index],
                                        style: f12w700WhiteSize(),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 2, // 필요한 경우 조정 가능
                                      ),
                                    ),
                                    index==selectedRadio?GestureDetector(
                                      onTap:onTap,
                                      child: Container(
                                          decoration: BoxDecoration(
                                              border: Border.all(color: Colors.white)
                                          ),
                                          child: Icon(CupertinoIcons.speaker_2,color: Colors.white,)),
                                    ):SizedBox()
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Get.back();
                      },
                      behavior: HitTestBehavior.opaque,
                      child: Center(
                        child: Container(
                          width: Get.width,
                          height: 42,
                          decoration: BoxDecoration(
                            color: Color(0xffD3D8DE),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              '돌아가기',
                              style: f16w700Size(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: (){
                        if(selectedRadio>3){
                          showConfirmTapDialog(context, '삭제하시겠습니까?', ()async{
                            await cameraNameDelete(cs.cameraTextList[selectedRadio],'0');
                            cs.cameraTextList.removeAt(selectedRadio);
                            con.text = '화재 경보 벨소리';
                            selectedRadio = 0;
                            onDelete();
                            Get.back();
                            setState(() {});
                          });
                        }
                      },
                      behavior: HitTestBehavior.opaque,
                      child: Center(
                        child: Container(
                          width: Get.width,
                          height: 42,
                          decoration: BoxDecoration(
                            color:selectedRadio>3?Colors.red:Colors.grey,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              '삭제',
                              style: f16w700WhiteSize(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ));
        },
      );
    },
  );
}
/// 모션 경보음 선택 다이얼로그
showMotionSoundChangeDialog(
    BuildContext context,
    int selectedRadio,
    String title,
    ValueChanged<int> onSelectionChanged,
    VoidCallback onTap,
    VoidCallback onDelete,
    TextEditingController con,
    ) {
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (context, StateSetter setState) {
          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            title: Text('알림 경보음 선택', style: f20w700Size()),
            content: Container(
              width: Get.width,
              height: 500,
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('모션 발생 시 카메라에서 소리를 낼 수 있습니다.', style: f12w700BlurGrey),
                    const SizedBox(height: 14),
                    ListView.builder(
                      itemCount: cs.cameraTextList.length,
                      shrinkWrap: true,
                      physics: const ClampingScrollPhysics(),
                      itemBuilder: (_, index) {
                        return Column(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: Color(0xff808080),
                              ),
                              width: Get.width,
                              child: Padding(
                                padding: const EdgeInsets.only(right: 10),
                                child: Row(
                                  children: [
                                    Radio<int>(
                                      value: index,
                                      groupValue: selectedRadio,
                                      activeColor: Colors.white,
                                      onChanged: (int? value)async{
                                        setState(() {
                                          selectedRadio = value!;
                                          con.text = cs.cameraTextList[selectedRadio];
                                        });
                                        DialogManager.showLoading(context);
                                        if(value == 0){
                                          await demoSaveTts(context, con,true,'motion');
                                        }else{
                                          await saveTts(context, con, true, TtsType.motion);
                                        }
                                          onSelectionChanged(value!);
                                      },
                                    ),
                                    SizedBox(width: 8), // 간격을 조절하려면 이 값을 변경하세요
                                    Expanded(
                                      child: Text(
                                        cs.cameraTextList[index],
                                        style: f12w700WhiteSize(),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 2, // 필요한 경우 조정 가능
                                      ),
                                    ),
                                    index==selectedRadio?GestureDetector(
                                      onTap:onTap,
                                      child: Container(
                                          decoration: BoxDecoration(
                                              border: Border.all(color: Colors.white)
                                          ),
                                          child: Icon(CupertinoIcons.speaker_2,color: Colors.white,)),
                                    ):SizedBox()
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Get.back();
                      },
                      behavior: HitTestBehavior.opaque,
                      child: Center(
                        child: Container(
                          width: Get.width,
                          height: 42,
                          decoration: BoxDecoration(
                            color: Color(0xffD3D8DE),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              '돌아가기',
                              style: f16w700Size(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: (){
                        if(selectedRadio>3){
                          showConfirmTapDialog(context, '삭제하시겠습니까?', ()async{
                            await cameraNameDelete(cs.cameraTextList[selectedRadio],'2');
                            cs.cameraTextList.removeAt(selectedRadio);
                            selectedRadio = 0;
                            onDelete();
                            Get.back();
                            setState(() {});
                          });
                        }
                      },
                      behavior: HitTestBehavior.opaque,
                      child: Center(
                        child: Container(
                          width: Get.width,
                          height: 42,
                          decoration: BoxDecoration(
                            color:selectedRadio>3?Colors.red:Colors.grey,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              '삭제',
                              style: f16w700WhiteSize(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      );
    },
  );
}

/// 알림 경보음 추가 다이얼로그가
Future<void> showCameraNameAddDialog(BuildContext context,String type)async{
  TextEditingController con = TextEditingController();
  final FlutterTts tts = FlutterTts();
  Timer? _timer;
  bool visual = false;
  String generatedVoice = '1';
  bool refresh = true;
  await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context,StateSetter setState){
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              title: Text('경보음 추가하기',style: f20w700Size(),),
              content: Container(
                width: Get.width,
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('음성 합성하기 위한 경보음 문구를 입력하세요.',style: hintf14w400Size(),),
                      const SizedBox(height: 10,),
                      Text('텍스트 길이는 2~26자로 제한됩니다.',style: hintf14w400Size(),),
                      const SizedBox(height: 30,),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: TextFormField(
                          controller: con,
                          maxLength: 26,
                          enabled: refresh,
                          buildCounter: (
                              BuildContext context, {
                                required int currentLength,
                                required bool isFocused,
                                required int? maxLength,
                              }) {
                            return Padding( // 카운터 텍스트에 패딩 추가
                              padding: const EdgeInsets.only(bottom: 5),
                              child: Text(
                                '$currentLength/$maxLength',
                                style: TextStyle(
                                  fontSize: 12,
                                ),
                              ),
                            );
                          },
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.only(top: 10,bottom: 10,left: 20,right: 20),
                            hintText: '이곳에 글자를 입력하세요',
                            hintStyle: hintf14w400Size(),
                            filled: true,
                            fillColor: Colors.grey[200],
                            enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Colors.transparent,
                                  width: 1.0,
                                ),
                                borderRadius: BorderRadius.circular(12)
                            ),
                            focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Colors.transparent,
                                  width: 1.0,
                                ),
                                borderRadius: BorderRadius.circular(12)
                            ),
                            disabledBorder: OutlineInputBorder( // 추가된 부분
                                borderSide: BorderSide(
                                  color: Colors.transparent,
                                  width: 1.0,
                                ),
                                borderRadius: BorderRadius.circular(12)
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14,),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          GestureDetector(
                            onTap: (){
                              if(con.text.length<2){
                                showOnlyConfirmDialog(context, '2자 ~ 26자로 입력해주세요');
                              }else{
                                if(generatedVoice =='1'){
                                  refresh = false;
                                  generatedVoice = '2';
                                  setState(() {});
                                  _timer?.cancel(); // 이전 타이머를 취소
                                  _timer = Timer.periodic(Duration(seconds: 2), (timer) {
                                    setState(() {
                                      visual = !visual;
                                    });
                                  });
                                  Future.delayed(Duration(seconds: 7), () {
                                    setState(() {
                                      generatedVoice = '3';
                                      _timer?.cancel();
                                    });
                                  });
                                }
                              }
                            },
                            child: generatedVoice=='1'?Container(
                              decoration: BoxDecoration(
                                  color: Color(0xff9DC280),
                                  borderRadius: BorderRadius.circular(20)
                              ),
                              child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 14,horizontal: 20),
                                  child: Text('소리 합성하기',style: f16w700WhiteSize(),)),
                            ):generatedVoice=='2'
                                ?Container(
                              decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(20)
                              ),
                              child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 14,horizontal: 20),
                                  child: Text('합 성 중',style: f16w700WhiteSize(),)),
                            ):Container(
                              decoration: BoxDecoration(
                                  border: Border.all(color: Color(0xff9DC280)),
                                  borderRadius: BorderRadius.circular(20)
                              ),
                              child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 14,horizontal: 20),
                                  child: Text('합성 완료',style: f16w700BrownSize(),)),
                            ),
                          ),
                          const SizedBox(width: 20),
                          generatedVoice=='3'?GestureDetector(
                            onTap:(){
                              tts.speak(con.text);
                            },
                            child: Container(
                                decoration: BoxDecoration(
                                    border: Border.all(color: Colors.brown)
                                ),
                                child: Icon(CupertinoIcons.speaker_2,color: Colors.brown,)),
                          )
                              :AnimatedContainer(
                            duration: Duration(seconds: 2),
                            decoration: BoxDecoration(
                              border: Border.all(color: visual ? Colors.red : Colors.white),
                            ),
                            child: AnimatedSwitcher(
                              duration: Duration(seconds: 2),
                              child: Icon(
                                CupertinoIcons.speaker_2,
                                key: ValueKey<bool>(visual),
                                color: visual ? Colors.red : Colors.white,
                              ),
                              transitionBuilder: (Widget child, Animation<double> animation) {
                                return FadeTransition(opacity: animation, child: child);
                              },
                            ),
                          ),
                          const SizedBox(width: 30),
                          GestureDetector(
                            onTap:(){
                              visual = false;
                              refresh = true;
                              con.text = '';
                              generatedVoice = '1';
                              setState(() {});
                            },
                            child: Container(
                                decoration: BoxDecoration(
                                    border: Border.all(color: Color(0xff9DC280))
                                ),
                                child: Icon(Icons.refresh,color: Color(0xff9DC280),)),
                          )
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Get.back();
                        },
                        behavior: HitTestBehavior.opaque,
                        child: Center(
                          child: Container(
                            width: Get.width,
                            height: 42,
                            decoration: BoxDecoration(color: Color(0xffD3D8DE), borderRadius: BorderRadius.circular(8)),
                            child: Center(
                                child: Text(
                                  '취소',
                                  style: f16w700Size(),
                                )),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 8,),
                    Expanded(
                      child: GestureDetector(
                        onTap: (){
                          if(cs.cameraTextList.length>9){
                            showOnlyConfirmDialog(context, '경보음은 최대 10개까지 사용할 수 있습니다.불필요한 경보음을 삭제한 후 새로운 경보음을 추가 할 수 있습니다.');
                          }
                          else if(con.text.length<2){
                            showOnlyConfirmDialog(context, '2자 ~ 26자로 입력해주세요');
                          }else{
                            showConfirmTapDialog(context, '해당 경보음을 추가하시겠습니까?', () async{
                              Get.back();
                              DialogManager.showLoading(context);
                              if(type =='0'){
                                await saveTts(context, con, false, TtsType.fire);
                              }else if(type =='1'){
                                await saveTts(context, con, false, TtsType.smoke);
                              }else if(type =='2'){
                                await saveTts(context, con, false, TtsType.motion);
                              }
                            });
                          }
                        },
                        behavior: HitTestBehavior.opaque,
                        child: Center(
                          child: Container(
                            width: Get.width,
                            height: 42,
                            decoration: BoxDecoration(color: Color(0xff1955EE), borderRadius: BorderRadius.circular(8)),
                            child: Center(
                                child: Text(
                                  '등록',
                                  style: f16w700WhiteSize(),
                                )),
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              ],
            );
          },
        );
      }).then((_){
    _timer?.cancel();
  });
}

/// 카메라 셋팅값 가져오기
showCameraSettingValue(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (context, StateSetter setState) {
          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            title: Text('카메라 셋팅 값', style: f20w700Size()),
            content: Container(
              width: Get.width,
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('fire_enable ${cs.cameraDetailInfo[0]['fire_enable']}', style: f12w700BlurGrey),
                    const SizedBox(height: 14),
                    Text('fire_sensitivity ${cs.cameraDetailInfo[0]['fire_sensitivity']}', style: f12w700BlurGrey),
                    const SizedBox(height: 14),
                    Text('smoke_sensitivity ${cs.cameraDetailInfo[0]['smoke_sensitivity']}', style: f12w700BlurGrey),
                    const SizedBox(height: 14),
                    Text('fire_type ${cs.cameraDetailInfo[0]['fire_type']}', style: f12w700BlurGrey),
                    const SizedBox(height: 14),
                    Text('fire_place ${cs.cameraDetailInfo[0]['fire_place']}', style: f12w700BlurGrey),
                    const SizedBox(height: 14),
                    Text('alarm_motion_armed ${cs.ipList[0].sourceData!['alarm_motion_armed']}', style: f12w700BlurGrey),
                    const SizedBox(height: 14),
                    Text('alarm_motion_sensitivity ${cs.ipList[0].sourceData!['alarm_motion_sensitivity']}', style: f12w700BlurGrey),
                    const SizedBox(height: 14),
                  ],
                ),
              ),
            ),
            actions: [
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Get.back();
                      },
                      behavior: HitTestBehavior.opaque,
                      child: Center(
                        child: Container(
                          width: Get.width,
                          height: 42,
                          decoration: BoxDecoration(
                            color: Color(0xffD3D8DE),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              '확인',
                              style: f16w700Size(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      );
    },
  );
}


