import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:mms/components/dialogManager.dart';
import 'dart:io';
import '../../screen/navigation/bottom_navigator_view.dart';
import '../../components/dialog.dart';
import '../../db/get_monitoring_info.dart';
import '../../provider/notification_state.dart';
import '../../provider/user_state.dart';
import '../../utils/font/font.dart';
import '../../utils/loading.dart';
import 'alert_turn_off.dart';

class AlertWaterTank extends StatefulWidget {
  final bool? alarm;
  final String mms;
  final List mmsNotiList;
  const AlertWaterTank({Key? key, this.alarm, required this.mms,required this.mmsNotiList}) : super(key: key);

  @override
  State<AlertWaterTank> createState() => _AlertWaterTankState();
}

class _AlertWaterTankState extends State<AlertWaterTank> {
  final us = Get.put(UserState());
  bool switchButton = false;
  final ns = Get.put(NotificationState());
  List _alertTitle = ['저수조 고수위 경보','저수조 저수위 경보'];
  late Socket socket;
  List<int> dataToSend = [];
  bool _isLoading = true;
  String switchOpen = '';
  Timer? _timer;
  bool alarmCheck = false;
  bool switchClick = false;

  @override
  void initState() {
    Future.delayed(Duration.zero,()async{
      if(widget.alarm!=null){
        alarmCheck = true;
      }
      /// 알림 확인 체크 용
      // await alimTimerClear(
      //     widget.mms,
      //     ns.lowHighType.value==0?'waterHigh_count':'waterLow_count',
      //     ns.lowHighType.value==0?'waterHigh_time':'waterLow_time');
      /// 현재 알림의 mms의 알림 정보 가져오기
      await alimMonitoringInfo(widget.mms);
      switchButton = bool.parse('${us.alimUserMonitoring[0]['data']}');
      _isLoading = false;
      setState(() {});
      /// 3초동안 서버에 데이터 받아오기
      _timer = Timer.periodic(Duration(seconds: 2), (timer) async {
        if(mounted) {
          try {
            await fetchData();
            setState(() {});
          } catch (error) {
            print('주기적 작업 중 오류 발생: $error');
          }
        }
      });
    });
    super.initState();
  }
  Future<void> fetchData() async {
    try {
      await alimMonitoringInfo(widget.mms);
      switchButton = bool.parse('${us.alimUserMonitoring[0]['data']}');
      _isLoading = false;
    } catch (error) {
      print('데이터 가져오기 중 오류 발생: $error');
    }
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
          elevation: 0,
          leading: GestureDetector(
              onTap: (){
                if(alarmCheck){
                  us.bottomIndex.value = 2;
                  Get.offAll(()=>BottomNavigatorView());
                }else {
                  Get.back();
                }
              },
              child: Icon(Icons.arrow_back_ios)),
        ),
        backgroundColor: const Color(0xffF1F4F7),
        body: Column(
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
                  child: _isLoading?LoadingScreen():Column(
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

                            /// 0이면 고수위 1이면 저수위 default 0
                            Text('${widget.mmsNotiList[0]['title']}',style: f21wRed700Size(),),
                            const SizedBox(height: 4,),
                            Text('${widget.mmsNotiList[0]['body']}',style: f21w700Size(),),
                            const SizedBox(height: 4,),
                            Text('수위 : ${us.alimUserMonitoring[0]['waterLevel']}%',style: f18w500Size(),)
                          ],
                        ),
                      ),
                      const SizedBox(height: 10,),
                      Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                          decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), color: Colors.white),
                          width: Get.width,
                          // height: 162,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '급수밸브',
                                style: f14w600Size(),
                              ),
                              SizedBox(height: 10),
                              switchClick || us.alimUserMonitoring[0]['data'] == '대기중'
                                  ? Center(child: Text('급수 밸브가 바뀌고 있습니다 잠시만 기다려주세요'))
                                  : Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  GestureDetector(
                                      onTap:() async {
                                        if(!switchButton){
                                          await showValveTapDialog(context, '급수관 밸브를 여시겠습니까?' ,() async {
                                            _timer?.cancel();
                                            us.alimUserMonitoring[0]['data'] = '대기중';
                                            switchClick = true;
                                            Get.back();

                                            await changeSwitch(true,'급수관', widget.mms);
                                            socket = await Socket.connect('${config.sockUrl}', config.sockPort);
                                            print("us.userSocketData.value : ${us.userSocketData.value}");
                                            socket.add(us.userSocketData.value);
                                            socket.close();
                                            DialogManager.showLoading(context);

                                            await us.alimAdd('${widget.mms}','상수도유입밸브 변경','밸브 열림','noting', 'noting', '10', '${us.userList[0]['name']}', '${us.userMonitoring[0]['mmsName']??''}');
                                            Future.delayed(Duration(seconds: 11), () {
                                              DialogManager.hideLoading();
                                              _timer = Timer.periodic(Duration(seconds: 2), (timer) async {
                                                await alimMonitoringInfo(widget.mms);
                                                if(us.alimUserMonitoring[0]['data'] != '대기중') {
                                                  switchButton = bool.parse('${us.alimUserMonitoring[0]['data']}');
                                                  switchClick = false;
                                                }
                                                _isLoading = false;
                                                setState(() {});
                                              });
                                            });
                                            setState(() {});
                                          });
                                        }
                                      },
                                      child: Text('열기', style: switchButton ? f16w600GreySize() : f16w700Size(),)),
                                  switchButton ? SvgPicture.asset(
                                    'assets/icon/valve_open.svg',
                                    width: 140,
                                    height: 48,
                                  ) :  SvgPicture.asset(
                                    'assets/icon/valve_closed.svg',
                                    width: 140,
                                    height: 48,
                                  ),
                                  GestureDetector(
                                      onTap:() async {
                                        if(switchButton){
                                          await showValveTapDialog(context, '급수관 밸브를 닫으시겠습니까?' ,() async {
                                            _timer?.cancel();
                                            us.alimUserMonitoring[0]['data'] = '대기중';
                                            switchClick = true;
                                            Get.back();

                                            // await alimChangeSwitch(true,'급수관',widget.mms); // 25-02-04 주석
                                            await changeSwitch(false,'급수관', widget.mms);
                                            socket = await Socket.connect('${config.sockUrl}', config.sockPort);
                                            socket.add(us.userSocketData.value);
                                            socket.close();
                                            DialogManager.showLoading(context);

                                            await us.alimAdd('${widget.mms}','상수도유입밸브 변경','밸브 닫힘','', '', '10', '', '${us.userMonitoring[0]['mmsName']??''}');
                                            Future.delayed(Duration(seconds: 11), () {
                                              DialogManager.hideLoading();
                                              _timer = Timer.periodic(Duration(seconds: 2), (timer) async {
                                                await alimMonitoringInfo(widget.mms);
                                                if(us.alimUserMonitoring[0]['data'] != '대기중') {
                                                  switchButton = bool.parse('${us.alimUserMonitoring[0]['data']}');
                                                  switchClick = false;
                                                }
                                                _isLoading = false;
                                                setState(() {});
                                              });
                                            });
                                            setState(() {});
                                          });
                                        }
                                      },
                                      child: Text('닫기', style: !switchButton ? f16w600GreySize() : f16w700Size(),)),
                                ],
                              ),
                            ],
                          )),
                    ],
                  )
              ),
            ),
          ],
        ),
        bottomNavigationBar: GestureDetector(
          onTap: ()async{
            ns.alertTurnOffList.value = ['수위센서 오작동','사고 인지 및 해결 중','정상 복구 완료','테스트 및 시험','기타 (직접입력)'];
            Get.to(() => AlertTurnOff(field: ns.lowHighType.value==0?'waterHighCheck':'waterLowCheck',mms: widget.mms));
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
