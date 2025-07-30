import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import '../../screen/bottom_navigator.dart';
import '../../components/color_radio.dart';
import '../../db/get_monitoring_info.dart';
import '../../provider/notification_state.dart';
import '../../utils/font/font.dart';
import '../../utils/loading.dart';
import 'alert_turn_off.dart';

class AlertCollectingWell extends StatefulWidget {
  final bool? alarm;
  final String mms;
  final List mmsNotiList;
  const AlertCollectingWell({Key? key, this.alarm, required this.mms, required this.mmsNotiList}) : super(key: key);

  @override
  State<AlertCollectingWell> createState() => _AlertCollectingWellState();
}

class _AlertCollectingWellState extends State<AlertCollectingWell> {
  bool switchButton = false;
  final ns = Get.put(NotificationState());
  bool alarmCheck = false;
  bool isLoading = true;

  @override
  void initState() {
    Future.delayed(Duration.zero,()async{
      if(widget.alarm!=null){
        alarmCheck = true;
      }
      // await alimTimerClear(widget.mms, 'jib_count', 'jib_time');
      await alimMonitoringInfo(widget.mms);
      isLoading = false;
      setState(() {});
    });
    super.initState();
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
                          const SizedBox(height: 8,),
                          Text('${widget.mmsNotiList[0]['body']}',style: f21w700Size(),),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10,),
                    Container(
                      width: Get.width,
                      height: 75,
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                      child: Padding(
                        padding: const EdgeInsets.only(left: 20, right: 18),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Text(
                              '집수정',
                              style: f18w700Size(),
                            ),
                            Spacer(),
                            us.alimUserMonitoring[0]['jibsu']=='0'
                                ? Row(
                              children: [
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
                            )
                                : Row(
                              children: [
                                RedRadio(),
                                const SizedBox(
                                  width: 6,
                                ),
                                Text(
                                  '비정상',
                                  style: redf18w700(),
                                ),
                                const SizedBox(
                                  width: 14,
                                ),
                              ],
                            )
                          ],
                        ),
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
            ns.alertTurnOffList.value = ['수위센서 오작동','사고 인지 및 해결 중','정상 복구 완료','테스트 및 시험','기타 (직접입력)'];
            Get.to(() => AlertTurnOff(field: 'jibCheck',mms: widget.mms));
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
