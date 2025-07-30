import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

import '../../components/color_radio.dart';
import '../../provider/notification_state.dart';
import '../../utils/font/font.dart';
import 'alert_turn_off.dart';

class AlertCamera extends StatefulWidget {
  const AlertCamera({Key? key}) : super(key: key);

  @override
  State<AlertCamera> createState() => _AlertCameraState();
}

class _AlertCameraState extends State<AlertCamera> {
  bool switchButton = false;
  final ns = Get.put(NotificationState());
  // int _type = 0;

  List _alertTitle = ['불꽃 감지 경보','움직임 감지 경보','제한구역 침입 경보'];
  List _turnOffTitle = ['불꽃 감지 오류','소방서 신고','불꽃 원인 해결','테스트 및 시험','기타 (직접입력)'];
  List _turnOffTitle2 = ['센서 감지 오류','현장 확인','테스트 및 시험','기타 (직접입력)'];



  @override
  void initState() {
    // ns.cameraType.value = 1;
    super.initState();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('알림발생',style: f16w900Size(),),
          centerTitle: true,
          shape: Border(
            bottom: BorderSide(
              color:  const Color(0xffEFF0F0),
              width: 1,
            ),
          ),
        ),
        backgroundColor: const Color(0xffF1F4F7),
        body: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10,horizontal: 10),
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  width: Get.width,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: Colors.white
                  ),
                  child: Column(
                    children: [
                      SvgPicture.asset('assets/icon/alert.svg',width: 80,height: 80,),
                      const SizedBox(height: 8,),
                      Text('${_alertTitle[ns.cameraType.value]}',style: f21wRed700Size(),),
                      const SizedBox(height: 8,),
                    ],
                  ),
                ),
                const SizedBox(height: 10,),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {},
                  child: Container(
                    width: Get.width,
                    height: 75,
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                    child: Padding(
                      padding: const EdgeInsets.only(left: 20, right: 18),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Text(
                            '정화조 수위',
                            style: f18w700Size(),
                          ),
                          Spacer(),
                          BlueRadio(),
                          const SizedBox(
                            width: 6,
                          ),
                          Text(
                            '정상',
                            style: bluef18w700(),
                          ),
                          const SizedBox(
                            width: 14,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: GestureDetector(
          onTap: ()async{
            switch (ns.cameraType.value) {
              case 0 :
                ns.alertTurnOffList.value = _turnOffTitle;
                break;
              case 1  :
                ns.alertTurnOffList.value = _turnOffTitle2;
                break;
              case 2  :
                ns.alertTurnOffList.value = _turnOffTitle2;
                break;
            }
            Get.to(() => AlertTurnOff(field: 'fireCheck',mms: ''));
          },
          child: Container(
            width: Get.width,
            height: 60,
            color: Color(0xff1955EE),
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(child: Text('알림해제',style: f18w700WhiteSize(),)),
          ),
        )
    );
  }
}
