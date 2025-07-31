// import 'dart:async';
// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:intl/intl.dart';
// import '../../../../../client/config.dart';
// import '../../../components/color_radio.dart';
// import '../../../components/monitoring_dialog.dart';
// import '../../../components/text_container.dart';
// import '../../../db/get_monitoring_info.dart';
// import '../../../notification/alert/alert_turn_off.dart';
// import '../../../provider/notification_state.dart';
// import '../../../provider/user_state.dart';
// import '../../login/login_view.dart';
// import '../../util/color.dart';
// import '../../util/font/font.dart';
// import '../../util/loading.dart';
// import 'package:http/http.dart' as http;
//
// class FireSettingScreen extends StatefulWidget {
//   final String? text;
//
//   const FireSettingScreen({Key? key, this.text}) : super(key: key);
//
//   @override
//   State<FireSettingScreen> createState() => _FireSettingScreenState();
// }
//
// class _FireSettingScreenState extends State<FireSettingScreen> {
//   final us = Get.put(UserState());
//   final ns = Get.put(NotificationState());
//   final config = AppConfig();
//   List item = ['알림방송', '주경종', '지구경종', '부저', '사이렌'];
//   List field = ['alim', 'mainjong', 'subjong', 'buzzer', 'siren'];
//   List checkField = ['alimCheck', 'mainjongCheck', 'subjongCheck', 'buzzerCheck', 'sirenCheck'];
//   List alimCheck = [];
//
//   late Socket socket;
//   bool _isLoading = true;
//   Timer? _timer;
//
//   @override
//   void initState() {
//     alimCheck = List.generate(5, (index) => false);
//     setState(() {});
//     _timer = Timer.periodic(Duration(seconds: 2), (timer) async {
//       try {
//         await fetchData();
//       } catch (error) {
//         _timer?.cancel();
//         showOnlyConfirmTapDialog(context, '서버가 종료되었습니다.', () {
//           Get.offAll(() => LoginView());
//         });
//       }
//     });
//     super.initState();
//   }
//
//   @override
//   void dispose() {
//     _timer?.cancel();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//         appBar: AppBar(
//           title: GestureDetector(
//             onTap: () async {
//               await updateSendTime();
//             },
//             child: Text(
//               '소방수신기 상태',
//               style: f16w800Size(),
//             ),
//           ),
//           titleSpacing: -15,
//           centerTitle: true,
//           actions: [
//             Padding(
//               padding: const EdgeInsets.only(right: 12),
//               child: us.userMonitoring[0]['firestate'] == '0'
//                   ? Row(
//                       children: [
//                         BlueRadio(),
//                         const SizedBox(
//                           width: 6,
//                         ),
//                         Text(
//                           '정상',
//                           style: bluef18w700(),
//                         ),
//                       ],
//                     )
//                   : Row(
//                       children: [
//                         RedRadio(),
//                         const SizedBox(
//                           width: 6,
//                         ),
//                         Text(
//                           '불꽃 경보',
//                           style: redf18w700(),
//                         ),
//                       ],
//                     ),
//             )
//           ],
//           shape: Border(
//             bottom: BorderSide(
//               color: Color(0xffEFF0F0),
//               width: 1,
//             ),
//           ),
//         ),
//         body: _isLoading
//             ? LoadingScreen()
//             : Container(
//                 height: Get.height,
//                 color: Color(0xffF1F4F7),
//                 child: Padding(
//                   padding: const EdgeInsets.only(left: 20, right: 20),
//                   child: Column(
//                     children: [
//                       ListView.builder(
//                           shrinkWrap: true,
//                           physics: const ClampingScrollPhysics(),
//                           itemCount: item.length,
//                           itemBuilder: (_, index) {
//                             return Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 index == 0
//                                     ? SizedBox(
//                                         height: 10,
//                                       )
//                                     : SizedBox(),
//                                 TextContainer(
//                                     onTap: () async {
//                                       _timer?.cancel();
//                                       showLoading(context);
//                                       if (bool.parse('${us.userMonitoring[0][field[index]]}')) {
//                                         us.userMonitoring[0][field[index]] = 'false';
//                                       } else {
//                                         us.userMonitoring[0][field[index]] = 'true';
//                                       }
//                                       await changeSwitch(bool.parse('${us.userMonitoring[0][field[index]]}'), '${item[index]}');
//                                       socket = await Socket.connect('${config.sockUrl}', config.sockPort);
//                                       socket.add(us.userSocketData.value);
//                                       socket.close();
//                                       Future.delayed(Duration(seconds: 8), () {
//                                         Get.back();
//                                         _timer = Timer.periodic(Duration(seconds: 2), (timer) async {
//                                           try {
//                                             await fetchData();
//                                           } catch (error) {
//                                             _timer?.cancel();
//                                             showOnlyConfirmTapDialog(context, '서버가 종료되었습니다.', () {
//                                               Get.offAll(() => LoginView());
//                                             });
//                                           }
//                                         });
//                                       });
//                                       setState(() {});
//                                     },
//                                     value: us.userMonitoring[0][field[index]] == '0' ? false : bool.parse(us.userMonitoring[0][field[index]]),
//                                     name: '${item[index]}',
//                                     value2: us.userMonitoring[0][checkField[index]]),
//                                 const SizedBox(
//                                   height: 10,
//                                 )
//                               ],
//                             );
//                           }),
//                       const SizedBox(
//                         height: 20,
//                       ),
//                       Row(
//                         children: [
//                           Expanded(
//                             child: GestureDetector(
//                               onTap: () async {
//                                 showLoading(context);
//                                 allSwitch('일괄끄기');
//
//                                 /// fire에 알림 울릴 시간 업데이트
//                                 await updateSendTime();
//                                 socket = await Socket.connect('${config.sockUrl}', config.sockPort);
//                                 socket.add(us.userSocketData.value);
//                                 socket.close();
//                                 Future.delayed(Duration(seconds: 12), () {
//                                   Get.back();
//                                 });
//                               },
//                               child: Container(
//                                 decoration: BoxDecoration(
//                                   borderRadius: BorderRadius.circular(10),
//                                   color: blueColor,
//                                 ),
//                                 height: 50,
//                                 child: Center(
//                                     child: Text(
//                                   '일괄끄기',
//                                   style: f16w400WhiteSize(),
//                                 )),
//                               ),
//                             ),
//                           ),
//                           const SizedBox(
//                             width: 50,
//                           ),
//                           Expanded(
//                             child: GestureDetector(
//                               onTap: () async {
//                                 showLoading(context);
//                                 allSwitch('일괄복구');
//                                 socket = await Socket.connect('${config.sockUrl}', config.sockPort);
//                                 socket.add(us.userSocketData.value);
//                                 socket.close();
//                                 Future.delayed(Duration(seconds: 12), () {
//                                   Get.back();
//                                 });
//                               },
//                               child: Container(
//                                 height: 50,
//                                 decoration: BoxDecoration(
//                                   borderRadius: BorderRadius.circular(10),
//                                   color: Colors.red,
//                                 ),
//                                 child: Center(
//                                     child: Text(
//                                   '일괄 복구',
//                                   style: f16w400WhiteSize(),
//                                 )),
//                               ),
//                             ),
//                           )
//                         ],
//                       ),
//                       const SizedBox(
//                         height: 20,
//                       ),
//                       Text(
//                         '일괄 끄기를 눌렀을 경우 1시간 이후 자동으로 복구 됩니다',
//                         style: f14w700Size(),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//         bottomNavigationBar: widget.text == 'noti'
//             ? GestureDetector(
//                 onTap: () async {
//                   ns.alertTurnOffList.value = ['소방수신기 오작동', '소방서 신고', '불꽃 원인 해결', '테스트 및 시험', '기타 (직접입력)'];
//                   // Get.to(() => AlertTurnOff(field: 'fireReceiveCheck'));
//                 },
//                 child: Container(
//                   width: Get.width,
//                   height: 60,
//                   color: Color(0xff1955EE),
//                   padding: const EdgeInsets.symmetric(vertical: 16),
//                   child: Center(
//                       child: Text(
//                     '알림해제',
//                     style: f18w700WhiteSize(),
//                   )),
//                 ),
//               )
//             : SizedBox());
//   }
//
//   /// 알림 보낼 시간 업데이트
//   Future<void> updateSendTime() async {
//     final us = Get.put(UserState());
//     DateTime currentTime = DateTime.now();
//     DateTime oneHourLater = currentTime.add(Duration(hours: 1));
//     String formattedTime = DateFormat('yyyy-MM-dd HH:mm:ss').format(oneHourLater);
//     final url = '${config.apiUrl}/updateSendTime?mms=${us.userList[0]['mms']}&time=${formattedTime}';
//     final response = await http.get(Uri.parse(url));
//     if (response.statusCode != 200) {
//       print('에러에러');
//       throw Exception('Failed to send email');
//     }
//   }
//
//   Future<void> fetchData() async {
//     await MonitoringInfo();
//     alimCheck[0] = us.userMonitoring[0]['alim'] == '0' ? false : bool.parse('${us.userMonitoring[0]['alim']}');
//     alimCheck[1] = us.userMonitoring[0]['mainjong'] == '0' ? false : bool.parse('${us.userMonitoring[0]['mainjong']}');
//     alimCheck[2] = us.userMonitoring[0]['subjong'] == '0' ? false : bool.parse('${us.userMonitoring[0]['subjong']}');
//     alimCheck[3] = us.userMonitoring[0]['buzzer'] == '0' ? false : bool.parse('${us.userMonitoring[0]['buzzer']}');
//     alimCheck[4] = us.userMonitoring[0]['siren'] == '0' ? false : bool.parse('${us.userMonitoring[0]['siren']}');
//     _isLoading = false;
//     setState(() {});
//   }
// }
