import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import '../../screen/bottom_navigator.dart';
import '../../provider/notification_state.dart';
import '../../db/get_monitoring_info.dart';
import '../../utils/font/font.dart';
import '../../utils/loading.dart';
import 'alert_turn_off.dart';

class AlertTransFormer extends StatefulWidget {
  final bool? alarm;
  final String mms;
  final List mmsNotiList;
  const AlertTransFormer({Key? key, this.alarm, required this.mms, required this.mmsNotiList}) : super(key: key);

  @override
  State<AlertTransFormer> createState() => _AlertTransFormerState();
}

class _AlertTransFormerState extends State<AlertTransFormer> {
  bool switchButton = false;
  final ns = Get.put(NotificationState());
  Timer? _timer;
  bool isLoading = true;
  bool alarmCheck = false;
  @override
  void initState() {
    Future.delayed(Duration.zero,()async{
      if(widget.alarm!=null){
        alarmCheck = true;
      }
      // await alimTimerClear(widget.mms, 'temp_count', 'temp_time');
      await alimMonitoringInfo(widget.mms);
      isLoading = false;
      setState(() {});
    });
    /// 3초동안 서버에 데이터 받아오기
    _timer=Timer.periodic(Duration(seconds: 2), (timer) async {
      await alimMonitoringInfo(widget.mms);
      if(mounted) {
        try {
          setState(() {});
        } catch (error) {
          print('주기적 작업 중 오류 발생: $error');
        }
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('알림발생',style: f16w900Size(),),
          centerTitle: true,
          leading: GestureDetector(
              onTap: (){
                if(alarmCheck){
                  us.bottomIndex.value = 2;
                  Get.offAll(()=>BottomNavigator());
                }else {
                  Get.back();
                }
              },
              child: Icon(Icons.arrow_back_ios)),
        ),
        backgroundColor: const Color(0xffF1F4F7),
        body: isLoading?LoadingScreen():Column(
          children: [
            Container(
              decoration: BoxDecoration(color: Colors.white,
                  borderRadius: BorderRadius.circular(8)),
              child: Padding(
                padding: const EdgeInsets.only(left: 10,right: 10),
                child: Row(
                  children: [
                    Container(
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Center(child: Text('${us.hexToChar('${widget.mms}')}',style: f16w700Size())),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        color: Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.all(9),
                          child: Text('${widget.mmsNotiList[0]['mmsName']??'${us.hexToChar('${widget.mms}')}'}',style: f16w700Size()),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
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
                          Text('${widget.mmsNotiList[0]['title']}',style: f21wRed700Size(),),
                          const SizedBox(height: 4,),
                          Text('${widget.mmsNotiList[0]['body']}',style: f21w700Size(),),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10,),
                    Container(
                      width: Get.width,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Spacer(),
                          Container(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  '변압기 온도',
                                  style: grf14w600(),
                                ),
                                Center(
                                  child: Row(
                                    children: [
                                      Text(
                                        '${us.alimUserMonitoring[0]['tempMain']}',
                                        style: f28w700Size(),
                                      ),
                                      const SizedBox(
                                        width: 4,
                                      ),
                                      Text(
                                        '°C',
                                        style: f18w400Size(),
                                      )
                                    ],
                                  ),
                                )
                              ],
                            ),
                          ),
                          Spacer(),
                          Container(
                            height: 38,
                            child: VerticalDivider(
                              color: Color(0xffC5C9CC),
                              thickness: 1,
                            ),
                          ),
                          Spacer(),
                          Container(
                            child: Column(
                              children: [
                                Text(
                                  '변압기 주변 온도',
                                  style: grf14w600(),
                                ),
                                Row(
                                  children: [
                                    Text(
                                      '${us.alimUserMonitoring[0]['tempside']}',
                                      style: f28w700Size(),
                                    ),
                                    const SizedBox(
                                      width: 4,
                                    ),
                                    Text(
                                      '°C',
                                      style: f18w400Size(),
                                    )
                                  ],
                                )
                              ],
                            ),
                          ),
                          Spacer(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: GestureDetector(
          onTap: ()async{
            ns.alertTurnOffList.value = ['온도센서 오작동','사고 인지 및 해결 중','정상 복구 완료','테스트 및 시험','기타 (직접입력)'];
            Get.to(() => AlertTurnOff(field: 'tempCheck',mms: widget.mms));
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
