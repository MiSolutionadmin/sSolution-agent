import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../base_config/config.dart';
import '../../../components/dialog.dart';
import '../../../components/switch.dart';
import '../../../provider/user_state.dart';
import '../../../utils/font/font.dart';
import 'package:http/http.dart' as http;
import '../../../utils/loading.dart';

class SettingNotificationScreen extends StatefulWidget {
  const SettingNotificationScreen({Key? key}) : super(key: key);

  @override
  State<SettingNotificationScreen> createState() => _FireSettingScreenState();
}

class _FireSettingScreenState extends State<SettingNotificationScreen> {
  final config = AppConfig();
  List item = ['모니터링 알림', '카메라 알림'];
  List field = ['monitoring', 'camera'];
  List alimCheck = [];
  List alimList = [];

  // late Socket socket;
  bool _isLoading = true;

  @override
  void initState() {
    checkNotificationPermission();
    Future.delayed(Duration.zero, () async {
      await GetUserNoti();
      alimCheck = List.generate(2, (index) => false);
      alimCheck[0] = bool.parse('${alimList[0]['monitoring']}');
      alimCheck[1] = bool.parse('${alimList[0]['camera']}');
      // print('?? ${alimList[0]['monitoring']}');
      _isLoading = false;
      setState(() {});
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(
            '알림 설정',
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
        body: _isLoading
            ? LoadingScreen()
            : ListView.builder(
                shrinkWrap: true,
                physics: const ClampingScrollPhysics(),
                itemCount: 2,
                itemBuilder: (_, index) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 26),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    margin:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${item[index]}',
                          style: f18w700Size(),
                        ),
                        SwitchButton(
                            onTap: () async {
                              alimCheck[index] = !alimCheck[index];
                              await updateNoti(field[index], alimCheck[index]);
                              setState(() {});
                            },
                            value: alimCheck[index])
                      ],
                    ),
                  );
                }));
  }

  /// 알림 정보 가져오기
  Future<void> GetUserNoti() async {
    final us = Get.put(UserState());
    final url =
        '${config.baseUrl}/getUserAlim?docId=${us.userList[0]['docId']}';
    final response = await http.get(Uri.parse(url));
    Map<String, dynamic> dataList = json.decode(response.body);
    alimList = [dataList];
    setState(() {});
    if (response.statusCode != 200) {
      print('에러에러');
      throw Exception('Failed to send email');
    }
  }

  /// 알림 업데이트
  Future<void> updateNoti(String field, bool value) async {
    final us = Get.put(UserState());
    final url =
        '${config.baseUrl}/updateNoti?docId=${alimList[0]['docId']}&field=${field}&value=${value}';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode != 200) {
      print('에러에러');
      throw Exception('Failed to send email');
    }
  }

  /// 알림 권한 확인 및 필요 시 설정 앱으로 이동
  Future<void> checkNotificationPermission() async {
    var status = await Permission.notification.request();
    print('현재상태 : $status');
    if (!status.isGranted) {
      print('퍼미션 : $status');
      showConfirmTapDialog(context, '앱에서 알림을 받으려면 알림 권한이 필요합니다' , () async {
        openAppSettings();
        Get.back();
      });
    } else {
      print('퍼미션상태 : $status');
    }
  }

}
