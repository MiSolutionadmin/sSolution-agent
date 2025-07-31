import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../../base_config/config.dart';
import '../../screen/navigation/bottom_navigator_view.dart';
import '../../components/dialog.dart';
import '../../db/get_monitoring_info.dart';
import '../../provider/notification_state.dart';
import '../../provider/user_state.dart';
import '../../utils/font/font.dart';

class AlertTurnOff extends StatefulWidget {
  final String mms;
  final String field; /// 파베에서 알림 다시 울리게 만드는 코드
  const AlertTurnOff({Key? key, required this.field, required this.mms}) : super(key: key);

  @override
  State<AlertTurnOff> createState() => _AlertTurnOffState();
}

class _AlertTurnOffState extends State<AlertTurnOff> {
  final ns = Get.put(NotificationState());
  final config = AppConfig();
  TextEditingController _reasonCon = TextEditingController();
  List _alertTitle = [];
  int? _selectedIndex;

  @override
  void initState() {
    _alertTitle = ns.alertTurnOffList.value;
    super.initState();
  }

  @override
  void dispose() {
    _reasonCon.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
          appBar: AppBar(
            title: Text(
              '알림해제',
              style: f16w900Size(),
            ),
            centerTitle: true,
            shape: Border(
              bottom: BorderSide(
                color: const Color(0xffEFF0F0),
                width: 1,
              ),
            ),
          ),
          backgroundColor: const Color(0xffF1F4F7),
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Column(
                children: [
                  ListView.builder(
                      itemCount: _alertTitle.length,
                      shrinkWrap: true,
                      physics: const ClampingScrollPhysics(),
                      itemBuilder: (_, index) {
                        // bool _isLastIndex = index == _alertTitle.length - 1;
                        return GestureDetector(
                          onTap: () {
                            // _isLastIndex = index == _alertTitle.length - 1;
                            _selectedIndex = index;
                            if(_selectedIndex==4){
                              _reasonCon.text = '';
                            }
                            setState(() {});
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: _selectedIndex == index ? const Color(0xff1955EE) : Colors.transparent),
                              color: Colors.white,
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
                            width: Get.width,
                            child: Text(
                              '${_alertTitle[index]}',
                              style: f20w500Size(),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        );
                      }),
                  AnimatedContainer(
                    width: _selectedIndex == _alertTitle.length - 1 ? Get.width : 0,
                    height: _selectedIndex == _alertTitle.length - 1 ? 160 : 0,
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
                              color: _selectedIndex == _alertTitle.length - 1 ? Color(0xff1955EE) : Colors.transparent,
                              width: 1.0,
                            ),
                          borderRadius: BorderRadius.circular(12)
                        ),
                        focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: _selectedIndex == _alertTitle.length - 1 ? Color(0xff1955EE) : Colors.transparent,
                              width: 1.0,
                            ),
                            borderRadius: BorderRadius.circular(12)
                        ),
                      ),
                    ),
                    // child: Text(
                    //   '직접 입력',
                    //   style: f20w500Size(),
                    //   textAlign: TextAlign.center,
                    // ),
                  ),
                ],
              ),
            ),
          ),
          bottomNavigationBar: GestureDetector(
            onTap: () async {
              /// 만약 기타 면
              if(_selectedIndex==null){
                showOnlyConfirmDialog(context, '해제 사유를 선택헤주세요');
              } else if(_selectedIndex==4 && _reasonCon.text.trim().isEmpty){
                showOnlyConfirmDialog(context, '해제 사유를 선택헤주세요');
              }
              else{
                if(_selectedIndex!=4){
                  _reasonCon.text = _alertTitle[_selectedIndex!];
                }
                switch (widget.field) {
                  case 'waterHighCheck':
                    await alimTimerClear(widget.mms, 'waterHigh_count', 'waterHigh_time');
                    break;
                  case 'waterLowCheck':
                    await alimTimerClear(widget.mms, 'waterLow_count', 'waterLow_time');
                    break;
                  case 'jibCheck':
                    await alimTimerClear(widget.mms, 'jib_count', 'jib_time');
                    break;
                  case 'fireReceiveCheck':
                    await alimTimerClear(widget.mms, 'fireReceive_count', 'fireReceive_time');
                    break;
                  case 'tempCheck':
                    await alimTimerClear(widget.mms, 'temp_count', 'temp_time');
                    break;
                  case 'cleanCheck':
                    await alimTimerClear(widget.mms, 'clean_count', 'clean_time');
                    break;
                  default:
                    print('da ?? ${widget.field}');
                }
                await addNotiDelete().then((value){
                  showOnlyConfirmTapDialog(context, '알림이 해제되었습니다', () {
                    us.bottomIndex.value = 2;
                    Get.offAll(()=>BottomNavigatorView());
                  });
                });
              }
              // showOnlyConfirmTapDialog(context, '해제를 했습니다', () {
              //   Get.offAll(BottomNavigatorView());
              // });
            },
            child: Container(
              width: Get.width,
              height: 60,
              color: _selectedIndex == null ? const Color(0xffD3D8DE) : const Color(0xff1955EE),
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                  child: Text(
                '선택',
                style: f18w700WhiteSize(),
              )),
            ),
          )),
    );
  }

  /// 관리자 추가
  Future<void> addNotiDelete() async{
    final us= Get.put(UserState());
    final url = '${config.baseUrl}/notiDeleteAdd';
    final body = ({
      'name':'${us.userList[0]['name']}',
      'email' : '${us.userList[0]['email']}',
      'mms' : '${widget.mms}',
      'reason' : '${_reasonCon.text}',
      'createDate' : '${DateTime.now()}',
      'docId' : '${ns.notiDocId.value}',
      'notiCheck':'${widget.field}',
    });
    final response = await http.post(Uri.parse(url), body: body);
    if (response.statusCode != 200) {
      print('에러에러');
      throw Exception('Failed to send email');
    }
  }
}
