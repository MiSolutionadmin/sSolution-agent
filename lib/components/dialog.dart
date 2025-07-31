import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:mms/components/dialogManager.dart';
import 'package:mms/utils/device_manager.dart';

import '../db/camera_table.dart';
import '../provider/camera_state.dart';
import '../provider/notification_state.dart';
import '../provider/user_state.dart';
import '../screen/alim/alim_main_page.dart';
import '../utils/font/font.dart';
import '../utils/loading.dart';

import 'package:http/http.dart' as http;

showFireStationDialog(BuildContext context, String agency,String address,String cameraName,String cameraPath, VoidCallback onTap) {
  showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Color(0xffF1F4F7),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          contentPadding: const EdgeInsets.only(top: 10, bottom: 10),
          content: Container(
            width: Get.width,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Image.asset(
                      'assets/camera_icon/119.png',
                      width: 80,
                      height: 50,
                      color: Colors.red,
                    ),
                    const SizedBox(width: 4,),
                    Text(
                      '문자신고',
                      style: f22w700RedSize(),
                    ),
                  ],
                ),
                const SizedBox(height: 10,),
                Container(
                  
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10)
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('현장명 : ${agency}',style: f14w700Black,),
                        const SizedBox(height: 2,),
                        Text('주소 : ${address}',style: f14w700Black),
                        const SizedBox(height: 2,),
                        Text('카메라 이름 : ${cameraName}',style: f14w700Black),
                        const SizedBox(height: 2,),
                        Text('카메라 영상 실시간 보기',style: f14w700Black),
                        Text(': ${cameraPath}',style: f12w500Blue(),),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10,),
                Text(
                  '\n아래 신고 버튼을 누르면 신고자의 핸드폰 번호로 소방서 문자 신고가 진행됩니다.\n\n문자 화면으로 이동 후 문자 전송\n 버튼을 눌러주시길 바랍니다.',
                  style: f12w600Size(),
                  textAlign: TextAlign.center,
                ),
              ],
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
                SizedBox(
                  width: 8,
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: onTap,
                    behavior: HitTestBehavior.opaque,
                    child: Center(
                      child: Container(
                        width: Get.width,
                        height: 42,
                        decoration: BoxDecoration(color: Color(0xff1955EE), borderRadius: BorderRadius.circular(8)),
                        child: Center(
                            child: Text(
                              '신고',
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
      });
}

showOnlyFireStationConfirmDialog(BuildContext context) {
  showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          contentPadding: const EdgeInsets.only(top: 35, bottom: 35),
          content: Container(
            width: Get.width,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "119 문자 신고가 정상 발송되었습니다.\n소방서에서 연락이 올 수 있으니 휴대폰을 소지하고 계시기 바랍니다.",
                  style: f16w700Size(),
                ),
                const SizedBox(height: 16),
                Text(
                  '화재 발생시 대응 방법(행동요령)',
                  style: f16w700Size(),
                ),
                const SizedBox(height: 8),
                RichText(
                  text: TextSpan(
                    style: f16w400Size(),
                    children: [
                      TextSpan(
                        text: "1. ",
                      ),
                      TextSpan(
                        text: "안내방송",
                        style: f14RedColorw700,
                      ),
                      TextSpan(
                        text: "을 실시.\n",
                        style: f12w500
                      ),
                      WidgetSpan(
                        child: SizedBox(height: 24),
                      ),
                      TextSpan(
                        text: "2. ",
                      ),
                      TextSpan(
                        text: "아파트 출입구의 자동문",
                        style: f14RedColorw700,
                      ),
                      TextSpan(
                        text: "을 ",
                          style: f12w500
                      ),
                      TextSpan(
                        text: "일괄 개방.\n",
                        style: f14RedColorw700,
                      ),
                      WidgetSpan(
                        child: SizedBox(height: 24),
                      ),
                      TextSpan(
                        text: "3. ",
                      ),
                      TextSpan(
                        text: "입주민을 ",
                          style: f12w500
                      ),
                      TextSpan(
                        text: "피난통로",
                        style: f14RedColorw700,
                      ),
                      TextSpan(
                        text: "로 ",
                          style: f12w500
                      ),
                      TextSpan(
                        text: "대피",
                        style: f14RedColorw700,
                      ),
                      TextSpan(
                        text: "하도록 안내.\n",
                          style: f12w500
                      ),
                      WidgetSpan(
                        child: SizedBox(height: 24),
                      ),
                      TextSpan(
                        text: "4. ",
                      ),
                      TextSpan(
                        text: "화재발생지역 ",
                        style: f14RedColorw700,
                      ),
                      TextSpan(
                        text: "스프링클러",
                        style: f14RedColorw700,
                      ),
                      TextSpan(
                        text: "를 ",
                          style: f12w500
                      ),
                      TextSpan(
                        text: "수동 개방.\n",
                        style: f14RedColorw700,
                      ),
                      WidgetSpan(
                        child: SizedBox(height: 24),
                      ),
                      TextSpan(
                        text: "5. ",
                      ),
                      TextSpan(
                        text: "화재초기를 제외하고 ",
                          style: f12w500
                      ),
                      TextSpan(
                        text: "직접진압",
                        style: f14RedColorw700,
                      ),
                      TextSpan(
                        text: "은 ",
                          style: f12w500
                      ),
                      TextSpan(
                        text: "자제.",
                        style: f14RedColorw700,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  "무엇보다 인명피해가 발생하지 않도록 대비하시기 바랍니다.",
                  style: TextStyle(fontSize: 16),
                ),
              ],
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
                        decoration: BoxDecoration(color: Color(0xff1955EE), borderRadius: BorderRadius.circular(8)),
                        child: Center(
                            child: Text(
                              '확인',
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
      });
}
/// 로그인 로딩
showLoadingDialog(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return PopScope(
        canPop: false,
        child: AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          contentPadding: const EdgeInsets.only(top: 35, bottom: 35),
          content: Container(
            width: Get.width,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Text(
                  "로그인 중...",
                  style: f16w700Size(),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

/// 로그인 로딩 테스트
showLoadingDialog2(BuildContext context) {
  final ns = Get.put(NotificationState());
  final cs = Get.find<CameraState>();
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return PopScope(
        canPop: false,
        onPopInvoked: (bool pop) async {
          if (pop) {
            return;
          }
          cs.cancelableOperation.value?.cancel();
        },
        child: AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          contentPadding: const EdgeInsets.only(top: 35, bottom: 35),
          content: Container(
            width: Get.width,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Text(
                  "로그인 중...",
                  style: f16w700Size(),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}


showAlimCheckTapDialog(BuildContext context, String title) {
  final ns = Get.find<NotificationState>();
  final cs = Get.find<CameraState>();
  int? _selectedIndex;
  TextEditingController _reasonCon = TextEditingController();
  showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {

        return StatefulBuilder(
          builder: (context,StateSetter setState){
            return AlertDialog(
              backgroundColor: const Color(0xffF1F4F7),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              contentPadding: const EdgeInsets.only(top: 35, bottom: 35),
              content: Container(
                width: Get.width,
                height: 500,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    child: Column(
                      children: [
                        Text('${title}'),
                        const SizedBox(height: 10,),
                        ListView.builder(
                            itemCount: ns.alertTurnOffList.length,
                            shrinkWrap: true,
                            physics: const ClampingScrollPhysics(),
                            itemBuilder: (_, index) {
                              // bool _isLastIndex = index == _alertTitle.length - 1;
                              return GestureDetector(
                                onTap: () {
                                  // _isLastIndex = index == _alertTitle.length - 1;
                                  _selectedIndex = index;
                                  if(_selectedIndex==ns.alertTurnOffList.length - 1){
                                    _reasonCon.text = '';
                                  } else {
                                    // 선택한 박스의 텍스트를 _reasonCon.text에 설정
                                    _reasonCon.text = ns.alertTurnOffList[index];
                                  }

                                  setState(() {});
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: _selectedIndex == index ? const Color(0xffE83B3B) : Colors.transparent),
                                    color: Colors.white,
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
                                  width: Get.width,
                                  child: Text(
                                    '${ns.alertTurnOffList[index]}',
                                    style: f20w500Size(),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              );
                            }),
                        AnimatedContainer(
                          width: _selectedIndex == ns.alertTurnOffList.length - 1 ? Get.width : 0,
                          height: _selectedIndex == ns.alertTurnOffList.length - 1 ? 160 : 0,
                          duration: Duration(milliseconds: 500),
                          curve: Curves.fastOutSlowIn,
                          child:  TextFormField(
                            controller: _reasonCon,
                            minLines: 3,
                            maxLines: 3,
                            decoration: InputDecoration(
                              hintText: '사유를 입력해주세요',
                              hintStyle: hintf14w400Size(),
                              // contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 16),
                              filled: true,
                              fillColor: Colors.white,
                              enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: _selectedIndex == ns.alertTurnOffList.length - 1 ? Color(0xffE83B3B) : Colors.transparent,
                                    width: 1.0,
                                  ),
                                  borderRadius: BorderRadius.circular(12)
                              ),
                              focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: _selectedIndex == ns.alertTurnOffList.length - 1 ? Color(0xffE83B3B) : Colors.transparent,
                                    width: 1.0,
                                  ),
                                  borderRadius: BorderRadius.circular(12)
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
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
                        onTap: ()async{
                          /// 만약 기타 면
                          if(_selectedIndex==null){
                            showOnlyConfirmDialog(context, '해제 사유를 선택해주세요');
                          } else if(_selectedIndex==ns.alertTurnOffList.length - 1 && _reasonCon.text.trim().isEmpty){
                            showOnlyConfirmDialog(context, '해제 사유를 입력해주세요');
                          }
                          else{
                            Get.back();
                            DialogManager.showLoading(context);
                            try {

                              await completeAgentWork(_reasonCon.text, 1);
                              showOnlyConfirmTapDialog(context, '서버로 전송에 선공하였습니다.', () {
                                //Get.offAll(()=> AlimScreen());
                              });
                            } catch (e) {
                              showOnlyConfirmTapDialog(context, '서버 연결에 실패하였습니다.\n 다시 시도해 주세요.', () {
                                //Get.offAll(()=> AlimScreen());
                              });
                            }
                            DialogManager.hideLoading();
                            Get.back();
                            Get.back();
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
                                  '확인',
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
      });
}



showLoading(BuildContext context) {
  showDialog(
    barrierDismissible: false,
    builder: (ctx) {
      return Center(child: WillPopScope(
          onWillPop: () async => false,
          child: LoadingScreen()));
    },
    context: context,
  );
}

showLoadingNotBarrier(BuildContext context) {
  showDialog(
    barrierDismissible: true,
    builder: (ctx) {
      return Center(child: LoadingScreen());
    },
    context: context,
  );
}


Future<void>showConfirmTapDialog(BuildContext context, String title,VoidCallback onTap)async {
  showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          contentPadding: const EdgeInsets.only(top: 35, bottom: 35),
          content: Container(
            width: Get.width,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              '${title}',
              style: f16w700Size(),
              textAlign: TextAlign.center,
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
                    onTap: onTap,
                    behavior: HitTestBehavior.opaque,
                    child: Center(
                      child: Container(
                        width: Get.width,
                        height: 42,
                        decoration: BoxDecoration(color: Color(0xff1955EE), borderRadius: BorderRadius.circular(8)),
                        child: Center(
                            child: Text(
                              '확인',
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
      });
}



showOnlyConfirmDialog(BuildContext context, String title) {
  showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          contentPadding: const EdgeInsets.only(top: 35, bottom: 35),
          content: Container(
            width: Get.width,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              '${title}',
              style: f16w700Size(),
              textAlign: TextAlign.center,
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
                        decoration: BoxDecoration(color: Color(0xff1955EE), borderRadius: BorderRadius.circular(8)),
                        child: Center(
                            child: Text(
                              '확인',
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
      });
}


showOnlyConfirmTapDialog(BuildContext context, String title,VoidCallback ontap) {
  showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          contentPadding: const EdgeInsets.only(top: 35, bottom: 35),
          content: Container(
            width: Get.width,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              '${title}',
              style: f16w700Size(),
              textAlign: TextAlign.center,
            ),
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: ontap,
                    behavior: HitTestBehavior.opaque,
                    child: Center(
                      child: Container(
                        width: Get.width,
                        height: 42,
                        decoration: BoxDecoration(color: Color(0xff1955EE), borderRadius: BorderRadius.circular(8)),
                        child: Center(
                            child: Text(
                              '확인',
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
      });
}
showOnlyConfirmTapDialogWillpop(BuildContext context, String title,VoidCallback ontap) {
  showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async => false,
          child: AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            contentPadding: const EdgeInsets.only(top: 35, bottom: 35),
            content: Container(
              width: Get.width,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                '${title}',
                style: f16w700Size(),
                textAlign: TextAlign.center,
              ),
            ),
            actions: [
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: ontap,
                      behavior: HitTestBehavior.opaque,
                      child: Center(
                        child: Container(
                          width: Get.width,
                          height: 42,
                          decoration: BoxDecoration(color: Color(0xff1955EE), borderRadius: BorderRadius.circular(8)),
                          child: Center(
                              child: Text(
                                '확인',
                                style: f16w700WhiteSize(),
                              )),
                        ),
                      ),
                    ),
                  ),
                ],
              )
            ],
          ),
        );
      });
}
showSettingValueDialog(BuildContext context,  TextEditingController _con1,VoidCallback onTap) {
  showDialog(
      context: context,
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async => false,
          child: AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            contentPadding: const EdgeInsets.only(top: 35, bottom: 35),
            content: Container(
                width: Get.width,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '계량기 세팅 값을 입력해주세요',
                      style: f16w700Size(),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10,),
                    TextFormField(
                      // obscuringCharacter: "*",
                      controller: _con1,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(20)
                      ],
                      decoration: InputDecoration(
                        hintText: '값 입력',
                        hintStyle: TextStyle(
                          fontSize: 12,
                          fontFamily: 'Pretendard',
                          fontWeight: FontWeight.w400,
                          color: Color(0xffB5B5B5),
                        ),
                        contentPadding: EdgeInsets.fromLTRB(15, 18, 0, 18),
                        filled: true,
                        fillColor: Color(0xFFF5F6F7),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ],
                )
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
                  const SizedBox(width: 8,),
                  Expanded(
                    child: GestureDetector(
                      onTap: onTap,
                      behavior: HitTestBehavior.opaque,
                      child: Center(
                        child: Container(
                          width: Get.width,
                          height: 42,
                          decoration: BoxDecoration(color: Color(0xff1955EE), borderRadius: BorderRadius.circular(8)),
                          child: Center(
                              child: Text(
                                '확인',
                                style: f16w700WhiteSize(),
                              )),
                        ),
                      ),
                    ),
                  ),
                ],
              )
            ],
          ),
        );
      });
}

showCameraAddDialog(BuildContext context,VoidCallback onTap,TextEditingController _con1, TextEditingController _con2, TextEditingController _con3) {
  showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          contentPadding: const EdgeInsets.only(top: 35, bottom: 35),
          content: SingleChildScrollView(
            child: Container(
                width: Get.width,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '카메라 모델명과 카메라이름 그리고 비밀번호를 입력해주세요',
                      style: f16w700Size(),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10,),
                    TextFormField(
                      // obscuringCharacter: "*",
                      controller: _con1,
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(20)
                      ],
                      decoration: InputDecoration(
                        hintText: '카메라 uid 입력',
                        hintStyle: TextStyle(
                          fontSize: 12,
                          fontFamily: 'Pretendard',
                          fontWeight: FontWeight.w400,
                          color: Color(0xffB5B5B5),
                        ),
                        contentPadding: EdgeInsets.fromLTRB(15, 18, 0, 18),
                        filled: true,
                        fillColor: Color(0xFFF5F6F7),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10,),
                    TextFormField(
                      controller: _con2,
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(20)
                      ],
                      decoration: InputDecoration(
                        hintText: '카메라 id 입력',
                        hintStyle: TextStyle(
                          fontSize: 12,
                          fontFamily: 'Pretendard',
                          fontWeight: FontWeight.w400,
                          color: Color(0xffB5B5B5),
                        ),
                        contentPadding: EdgeInsets.fromLTRB(15, 18, 0, 18),
                        filled: true,
                        fillColor: Color(0xFFF5F6F7),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10,),
                    TextFormField(
                      controller: _con3,
                      obscuringCharacter: "*",
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(20)
                      ],
                      obscureText: true,
                      decoration: InputDecoration(
                        hintText: '카메라 비밀번호 입력',
                        hintStyle: TextStyle(
                          fontSize: 12,
                          fontFamily: 'Pretendard',
                          fontWeight: FontWeight.w400,
                          color: Color(0xffB5B5B5),
                        ),
                        contentPadding: EdgeInsets.fromLTRB(15, 18, 0, 18),
                        filled: true,
                        fillColor: Color(0xFFF5F6F7),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
            
                  ],
                )
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
                const SizedBox(width: 8,),
                Expanded(
                  child: GestureDetector(
                    onTap: onTap,
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
      });
}

showIpCamIdAddDialog(BuildContext context,VoidCallback onTap,TextEditingController _con1) {
  showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          contentPadding: const EdgeInsets.only(top: 35, bottom: 35),
          content: SingleChildScrollView(
            child: Container(
                width: Get.width,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'IpCamId를 입력해주세요',
                      style: f16w700Size(),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10,),
                    TextFormField(
                      // obscuringCharacter: "*",
                      controller: _con1,
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(20)
                      ],
                      decoration: InputDecoration(
                        hintText: 'IpCamId 입력',
                        hintStyle: TextStyle(
                          fontSize: 12,
                          fontFamily: 'Pretendard',
                          fontWeight: FontWeight.w400,
                          color: Color(0xffB5B5B5),
                        ),
                        contentPadding: EdgeInsets.fromLTRB(15, 18, 0, 18),
                        filled: true,
                        fillColor: Color(0xFFF5F6F7),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10,),

                  ],
                )
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
                const SizedBox(width: 8,),
                Expanded(
                  child: GestureDetector(
                    onTap: onTap,
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
      });
}

showValveTapDialog(BuildContext context, String title,VoidCallback onTap) {
  showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          contentPadding: const EdgeInsets.only(top: 35, bottom: 35),
          content: Container(
            width: Get.width,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              '${title}',
              style: f16w700Size(),
              textAlign: TextAlign.center,
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
                              '아니오',
                              style: f16w700Size(),
                            )),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8,),
                Expanded(
                  child: GestureDetector(
                    onTap: onTap,
                    behavior: HitTestBehavior.opaque,
                    child: Center(
                      child: Container(
                        width: Get.width,
                        height: 42,
                        decoration: BoxDecoration(color: Color(0xff1955EE), borderRadius: BorderRadius.circular(8)),
                        child: Center(
                            child: Text(
                              '네',
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
      });
}


showPlaceDialog(BuildContext context,VoidCallback onTap,VoidCallback onTap2,) {
  showCupertinoModalPopup(
    context: context,
    builder: (BuildContext context) => CupertinoActionSheet(
      message: const Text('사용 환경을 설정해주세요'),
      actions: <Widget>[
        CupertinoActionSheetAction(
          child: Text(
            '실내',
            style: f18w500Size(),
          ),
          onPressed: onTap,
        ),
        CupertinoActionSheetAction(
          child: Text(
            '실외',
            style: f18w500Size(),
          ),
          onPressed: onTap2,
        )
      ],
    ),
  );
}

showOnlyDuplicateTapDialog(BuildContext context, String title,VoidCallback ontap) {
  showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return PopScope(
          canPop: false,
          child: AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            contentPadding: const EdgeInsets.only(top: 35, bottom: 35),
            content: Container(
              width: Get.width,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                '${title}',
                style: f16w700Size(),
                textAlign: TextAlign.center,
              ),
            ),
            actions: [
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: ontap,
                      behavior: HitTestBehavior.opaque,
                      child: Center(
                        child: Container(
                          width: Get.width,
                          height: 42,
                          decoration: BoxDecoration(color: Color(0xff1955EE), borderRadius: BorderRadius.circular(8)),
                          child: Center(
                              child: Text(
                                '확인',
                                style: f16w700WhiteSize(),
                              )),
                        ),
                      ),
                    ),
                  ),
                ],
              )
            ],
          ),
        );
      });
}
/// mms 다이얼로그
class CustomAlertDialog extends StatefulWidget {
  final String title;
  final String body;
  final String mms;
  final String mmsName;
  final VoidCallback? onTap;

  const CustomAlertDialog({Key? key, required this.title, this.onTap, required this.mms, required this.mmsName, required this.body}) : super(key: key);

  @override
  _CustomAlertDialogState createState() => _CustomAlertDialogState();
}

class _CustomAlertDialogState extends State<CustomAlertDialog> {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      contentPadding: const EdgeInsets.only(top: 35, bottom: 35),
      content: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset('assets/icon/alert.svg'),
            const SizedBox(height: 10,),
            Text(
              widget.title,
              textAlign: TextAlign.center,
              style: f21wRed700Size(),
            ),
            Text('${widget.body}',style: f20w700Size(),),
            const SizedBox(height: 10,),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('${widget.mms} ',style: f14w700Black,),
                Text('(${widget.mmsName})',style: f14w700Black,)
              ],
            )
          ],
        ),
      ),
      actions: [
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: widget.onTap ?? () {},
                behavior: HitTestBehavior.opaque,
                child: Center(
                  child: Container(
                    height: 42,
                    decoration: BoxDecoration(color: Color(0xff1955EE), borderRadius: BorderRadius.circular(8)),
                    child: Center(
                      child: Text(
                        '확인',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        )
      ],
    );
  }
}

/// 카메라 알림 다이얼로그
class CameraAlertDialog extends StatefulWidget {
  final String title;
  final String cameraName;
  final String body;
  final VoidCallback? onTap;

  const CameraAlertDialog({Key? key, required this.title, this.onTap, required this.cameraName, required this.body,}) : super(key: key);

  @override
  _CameraAlertDialogState createState() => _CameraAlertDialogState();
}

class _CameraAlertDialogState extends State<CameraAlertDialog> {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      contentPadding: const EdgeInsets.only(top: 35, bottom: 20),
      content: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset('assets/icon/alert.svg'),
            const SizedBox(height: 10,),
            Text(
              widget.title,
              textAlign: TextAlign.center,
              style: f21wRed700Size(),
            ),
            Text('${widget.body}',style: f20w700Size(),textAlign: TextAlign.center,),
            const SizedBox(height: 10,),
            // Text('${widget.cameraName} ',style: f14w700Black,),
          ],
        ),
      ),
      actions: [
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: widget.onTap ?? () {},
                behavior: HitTestBehavior.opaque,
                child: Center(
                  child: Container(
                    height: 42,
                    decoration: BoxDecoration(color: Color(0xff1955EE), borderRadius: BorderRadius.circular(8)),
                    child: Center(
                      child: Text(
                        '확인',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        )
      ],
    );
  }
}


class CustomAlertDialog2 extends StatefulWidget {
  final VoidCallback? onTap;

  const CustomAlertDialog2({Key? key, this.onTap}) : super(key: key);

  @override
  _CustomAlertDialog2State createState() => _CustomAlertDialog2State();
}

class _CustomAlertDialog2State extends State<CustomAlertDialog2> {
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        contentPadding: const EdgeInsets.only(top: 35, bottom: 35),
        content: Container(
          width: Get.width,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text(
                "로그인 중...",
                style: f16w700Size(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

showCameraTextDialog(BuildContext context,VoidCallback onTap,TextEditingController _con1) {
  showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          contentPadding: const EdgeInsets.only(top: 35, bottom: 35),
          content: SingleChildScrollView(
            child: Container(
                width: Get.width,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '변경하실 카메라 알림소리를 입력해주세요',
                      style: f16w700Size(),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20,),
                    TextFormField(
                      // obscuringCharacter: "*",
                      controller: _con1,
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(20)
                      ],
                      decoration: InputDecoration(
                        hintText: '알림소리 입력',
                        hintStyle: TextStyle(
                          fontSize: 12,
                          fontFamily: 'Pretendard',
                          fontWeight: FontWeight.w400,
                          color: Color(0xffB5B5B5),
                        ),
                        contentPadding: EdgeInsets.fromLTRB(15, 18, 0, 18),
                        filled: true,
                        fillColor: Color(0xFFF5F6F7),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10,),

                  ],
                )
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
                const SizedBox(width: 8,),
                Expanded(
                  child: GestureDetector(
                    onTap: onTap,
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
      });
}
/// 카메라 이름 변경 다이얼로그
showCameraNameChangeDialog(BuildContext context,TextEditingController Con, String cameraUid,VoidCallback onTap) {
  showDialog(
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
              title: Text('카메라 이름 변경',style: f20w700Size(),),
              content: Container(
                width: Get.width,
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('UID : ${cameraUid}',style: hintf14w400Size(),),
                      const SizedBox(height: 30,),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                        ),
                        child: TextFormField(
                          controller: Con,
                          maxLength: 15,
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
                            hintText: '사용할 이름을 입력하세요',
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

                          ),
                        ),
                      )
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
                        onTap: onTap,
                        behavior: HitTestBehavior.opaque,
                        child: Center(
                          child: Container(
                            width: Get.width,
                            height: 42,
                            decoration: BoxDecoration(color: Color(0xff1955EE), borderRadius: BorderRadius.circular(8)),
                            child: Center(
                                child: Text(
                                  '확인',
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
      });
}

/// mms 이름 변경 다이얼로그
showMmsNameChangeDialog(BuildContext context,TextEditingController Con, String mms,VoidCallback onTap) {
  showDialog(
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
              title: Text('mms 이름 변경',style: f20w700Size(),),
              content: Container(
                width: Get.width,
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('MMS : ${mms}',style: hintf14w400Size(),),
                      const SizedBox(height: 30,),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: TextFormField(
                          controller: Con,
                          maxLength: 15,
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
                            hintText: '사용할 이름을 입력하세요',
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

                          ),
                        ),
                      )
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
                        onTap: onTap,
                        behavior: HitTestBehavior.opaque,
                        child: Center(
                          child: Container(
                            width: Get.width,
                            height: 42,
                            decoration: BoxDecoration(color: Color(0xff1955EE), borderRadius: BorderRadius.circular(8)),
                            child: Center(
                                child: Text(
                                  '확인',
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
      });
}

Future<void> releaseNoteDialog(BuildContext context) async {
  final UserState us = Get.find<UserState>();

  await us.getReleaseNoteList(); /// get releasenote list from DB

  return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return PopScope(
          canPop: false,
          child: AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            /// padding
            contentPadding: const EdgeInsets.only(top: 20, bottom: 35),
            content: Container(
              width: Get.width,
              height: Get.height * 0.5,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '릴리즈노트',
                    style: f30blackW700(),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Scrollbar(
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              ListView.builder(
                                  shrinkWrap: true, // ListView가 Column 내부에서 크기 문제를 일으키지 않도록 설정
                                  physics: NeverScrollableScrollPhysics(), // SingleChildScrollView가 스크롤을 관리하므로 ListView는 자체 스크롤 비활성화
                                  itemCount: us.releaseNote.length,
                                  itemBuilder: (context,index) {
                                    return Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        /// date
                                        Text("${us.releaseNote[index]['version']} ver ${index == 0 ? "[현재버전]" : ""}",
                                          style : f18greyW700(),
                                        ),
                                        const SizedBox(height: 4),
                                        /// date
                                        Text(us.releaseNote[index]['content'].replaceAll(r'\n', '\n'),
                                          style : f14blackW600(),
                                          softWrap: true,          // 자동 줄 바꿈 허용
                                          overflow: TextOverflow.visible, // 줄 바꿈이 필요한 경우 내용을 숨기지 않음
                                        ),
                                        const SizedBox(height: 14),
                                      ],
                                    );
                                  }
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
            actions: [
              SizedBox(
                width: double.infinity,
                child: GestureDetector(
                  onTap: () async {
                    await us.trueCheckReleaseNote();
                    Get.back();
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Center(
                    child: Container(
                      width: Get.width,
                      height: 42,
                      decoration: BoxDecoration(color: Color(0xff1955EE), borderRadius: BorderRadius.circular(8)),
                      child: Center(
                          child: Text(
                            '확인',
                            style: f16w700WhiteSize(),
                          )),
                    ),
                  ),
                ),
              )
            ],
          ),
        );
      });
}

/// 소화장치 작동 다이얼로그
showFireFightingDialog(BuildContext context,String? cameraUid, String cameraName, int millisecond) {
  showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Color(0xffF1F4F7),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
          content: Container(
            width: Get.width,
            // padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '소화장치 작동',
                      style: f22w700RedSize(),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  width: Get.width,
                  padding: EdgeInsets.symmetric(vertical: 16,horizontal: 16),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10)
                  ),
                  child: Text('카메라 이름 : ${cameraName != null ? cameraName : cameraUid}',style: f14w700Black,),
                ),
                const SizedBox(height: 10),
                Text(
                  '\n아래 소화 버튼을 누르면 현장의 소화장치가 작동합니다.\n필요시에는 "119문자 신고"도 진행 바랍니다.',
                  style: f12w600Size(),
                  textAlign: TextAlign.start,
                ),
                const SizedBox(height: 10),
              ],
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
                SizedBox(
                  width: 8,

                ),
                Expanded(
                  child: GestureDetector(
                    // onTap: onTap,
                    onTap: () async {


                      // 1. 더블체크
                      final response = await http.get(Uri.parse('${config.baseUrl}/getFireFightingData?cameraUid=$cameraUid'));
                      Map<dynamic,dynamic> data = jsonDecode(response.body);

                      if (data['fireFighting'] == 0 || data['fireFightingStatus'] != 0) {
                        Get.back();
                        return; // 이미 작동했거나 작동중일시 리턴
                      }

                      Get.back();

                      DialogManager.showLoading(context);


                      // print("send 1");
                      // 2. 소화장치 실행

                      print("cameraDevice : ${cs.cameraDevice}");
                      final cgi1 = "trans_cmd_string.cgi?cmd=2109&command=0&alarmLed=1&";
                      final resp = await cs.cameraDevice!.writeCgi("trans_cmd_string.cgi?cmd=2109&command=0&alarmLed=1&");
                      print("보냄 1 ${cgi1}");
                      print("보냄 1.5 ${resp}");
                      cs.cameraDevice!.writeCgi("trans_cmd_string.cgi?cmd=2109&command=0&light=1&");

                      // 2-1. 1.5초뒤에 다시 0 보냄
                      Future.delayed(Duration(milliseconds: millisecond), () async{
                        final cgi2 = "trans_cmd_string.cgi?cmd=2109&command=0&alarmLed=0&";
                         final resp2 = await cs.cameraDevice!.writeCgi("trans_cmd_string.cgi?cmd=2109&command=0&alarmLed=0&");
                         print("보냄 2 ${cgi2}");
                        print("보냄 2.5 ${resp2}");
                         cs.cameraDevice!.writeCgi("trans_cmd_string.cgi?cmd=2109&command=0&light=0&");
                         print("${millisecond}초 후 실행됨!!");
                         DialogManager.hideLoading();


                         // print("확인 1 ");
                         // 3.5 fcm알림 보내기
                         final fcmBody = {
                           "vuid" : cameraUid,
                           "name" : us.userList?[0]['name'] ?? "",
                         };
                         await http.post(
                           Uri.parse('http://${config.cameraNotiUrl}/fireFightingOperated'),
                           headers: {
                             "Content-Type": "application/json",
                           },
                           body: jsonEncode(fcmBody),
                         );


                         //  Get.back();
                      });

                      // 3. db값 변경
                      final body = {
                        "cameraUid" : cameraUid,
                        "fireFightingStatus" : 1,
                      };
                      await http.post(
                        Uri.parse('${config.baseUrl}/changeFireFightingData'),
                        headers: {
                          "Content-Type": "application/json",
                        },
                        body: jsonEncode(body),
                      );

                      // print("확인 2 ");
                      // 4. 소방장치 데이터 갱신
                      cs.getFireFightingData(cameraUid ?? "");

                    },
                    behavior: HitTestBehavior.opaque,
                    child: Center(
                      child: Container(
                        width: Get.width,
                        height: 42,
                        decoration: BoxDecoration(color: Color(0xff1955EE), borderRadius: BorderRadius.circular(8)),
                        child: Center(
                            child: Text(
                              '소화',
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
      });
}

/// 소화장치 작동완료 다이얼로그
showFireFightingCompleteDialog(BuildContext context) {
  showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Color(0xffF1F4F7),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
          content: Container(
            width: Get.width,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '소화장치 작동 완료',
                      style: f22w700RedSize(),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                Container(
                  // width: Get.width,
                  child: Text(
                    '소화장치 사용이 완료되었습니다.\n교체를 위해 아래 번호로 문의 바랍니다.',
                    style: f12w600Size(),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 30),
                Text(
                  '에스솔루션\n1522-7688',
                  style: f18w700Size(),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
          actions: [
            SizedBox(
              width: Get.width,
              child: GestureDetector(
                onTap: () async {
                  Get.back();
                },
                behavior: HitTestBehavior.opaque,
                child: Center(
                  child: Container(
                    width: Get.width,
                    height: 42,
                    decoration: BoxDecoration(
                        color: Color(0xff1955EE),
                        borderRadius: BorderRadius.circular(8)
                    ),
                    child: Center(
                        child: Text(
                          '확인',
                          style: f16w700WhiteSize(),
                        )),
                  ),
                ),
              ),
            )
          ],
        );
      });
}