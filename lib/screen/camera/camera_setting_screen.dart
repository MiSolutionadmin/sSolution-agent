import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:mms/components/dialogManager.dart';

import '../../base_config/config.dart';
import '../../components/dialog.dart';
import '../../provider/camera_state.dart';
import '../navigation/bottom_navigator_view.dart';
import '../../utils/font/font.dart';
import '../../utils/loading.dart';

class CameraSettingScreen extends StatefulWidget {
  const CameraSettingScreen({Key? key}) : super(key: key);

  @override
  State<CameraSettingScreen> createState() => _CameraSettingScreenState();
}

class _CameraSettingScreenState extends State<CameraSettingScreen> {
  final cs = Get.find<CameraState>();
  final config = AppConfig();
  bool _isLoading = true;
  int roundedPercentage = 0;

  @override
  void initState() {

    Future.delayed(Duration.zero, () async {
      await currentFirmware(); /// 현재 펌웨어 버전
      await _initializeData(); /// 메모리 용량
      _isLoading = false;
    });
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        automaticallyImplyLeading: true,
        title: Text(
          '시스템 설정',
          style: f16w700Size(),
        ),
        centerTitle: true,
      ),
      backgroundColor: Colors.white,
      body: _isLoading
          ? LoadingScreen()
          : Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            buildRow('카메라 이름', '${cs.cameraName.value == '' ? '없음' : cs.cameraName.value}'),
            const SizedBox(
              height: 8,
            ),
            Divider(
              color: Color(0xffF1F4F7),
            ),
            const SizedBox(
              height: 8,
            ),
            buildRow('UID', '${cs.cameraUID.value == '' ? '없음' : cs.cameraUID.value}'),
            const SizedBox(
              height: 8,
            ),
            Divider(
              color: Color(0xffF1F4F7),
            ),
            const SizedBox(
              height: 8,
            ),
            buildRow('IP주소', '${cs.ipList.length == 0 ? '없음' : cs.ipList[0].sourceData!['ip']}'),
            const SizedBox(
              height: 8,
            ),
            Divider(
              color: Color(0xffF1F4F7),
            ),
            const SizedBox(
              height: 8,
            ),
            buildRow('메모리용량', '남은 용량 $roundedPercentage%'),
            const SizedBox(
              height: 8,
            ),
            Divider(
              color: Color(0xffF1F4F7),
            ),
            const SizedBox(
              height: 8,
            ),
            buildRow('현재 펌웨어 버전', '${cs.cameraDetailList[0]['currentFirmware']}'),
            const SizedBox(
              height: 8,
            ),
            Divider(
              color: Color(0xffF1F4F7),
            ),
            const SizedBox(
              height: 8,
            ),

            /// 카메라 재부팅
            GestureDetector(
              onTap: () async {
                showConfirmTapDialog(context, '카메라를 재부팅하시겠습니까?', () async {
                  await cs.cameraDevice!.reboot();
                  Get.back();
                  Get.back();
                  Get.back();
                });
              },
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.grey,
                ),
                height: 50,
                child: Center(
                    child: Text(
                      '카메라 재부팅',
                      style: f16w400WhiteSize(),
                    )),
              ),
            ),
            Spacer(),
            /// 펌웨어 업그레이드
            changeLastNumber(us.versionList[0]['camera']) <= changeLastNumber(cs.cameraDetailList[0]['currentFirmware']) ?SizedBox():GestureDetector(
              onTap: () {
                if (cs.cameraDetailList[0]['currentFirmware'] != cs.cameraDetailList[0]['newFirmware']) {
                  showConfirmTapDialog(context, '새로운 버전이 있습니다 업그레이드 하시겠습니까?', () async {
                    Get.back();
                    DialogManager.showLoading(context);
                    bool result = await cs.cameraDevice!.writeCgi('auto_download_file.cgi?server=${config.baseUrl}&file=/updateFirmware&type=0&resevered1=&resevered2=&resevered3=&resevered4=&');
                    if (result) {
                      showOnlyConfirmTapDialog(context, '업그레이드가 완료되는데 약 3~5분이 소요됩니다', () async {
                        us.bottomIndex.value = 1;
                        Get.offAll(()=>BottomNavigatorView());
                      });
                    } else {
                      showOnlyConfirmTapDialog(context, '업그레이드를 실패했습니다', () async {
                        Get.back();
                      });
                    }
                    DialogManager.hideLoading();
                  });
                }
                else {
                  showOnlyConfirmTapDialog(context, '최신 버전 입니다', () async {
                    Get.back();
                    Get.back();
                  });
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Color(0xFF1955EE),
                ),
                height: 50,
                child: Center(
                    child: Text(
                      '펌웨어 업데이트',
                      style: f16w400WhiteSize(),
                    )),
              ),
            ),
            const SizedBox(
              height: 10,
            ),

            /// 카메라 비밀번호 변경
            // GestureDetector(
            //   onTap: () async {
            //     showConfirmTapDialog(context, '비밀번호를 변경 하시겠습니까?', () async {
            //       Get.back();
            //       showLoading(context);
            //       String newPassword = 'asdf1234!'; // 새 비밀번호
            //       bool result = await cs.cameraDevice!.writeCgi("set_users.cgi?pwd_change_realtime=1&users3=admin&pwd3=${newPassword}&appid=&loginuse=admin&loginpas=${cs.cameraPassword}");
            //       if (result) {
            //         showOnlyConfirmTapDialog(context, '비밀번호가 변경 되었습니다', () async {
            //           Get.back();
            //           // us.bottomIndex.value = 1;
            //            Get.offAll(()=>BottomNavigatorView());
            //         });
            //       } else {
            //         showOnlyConfirmTapDialog(context, '비밀번호 변경에 실패했습니다', () async {
            //           Get.back();
            //           Get.back();
            //         });
            //       }
            //     });
            //   },
            //   child: Container(
            //     decoration: BoxDecoration(
            //       borderRadius: BorderRadius.circular(10),
            //       color: Colors.black26,
            //     ),
            //     height: 50,
            //     child: Center(
            //         child: Text(
            //           '비밀번호 변경',
            //           style: f16w400WhiteSize(),
            //         )),
            //   ),
            // ),
            // const SizedBox(
            //   height: 10,
            // ),


            /// 메모리 초기화
            GestureDetector(
              onTap: () async {
                showConfirmTapDialog(context, '메모리를 초기화 하시겠습니까?', () async {
                  Get.back();
                  DialogManager.showLoading(context);
                  bool result = await cs.cameraDevice!.writeCgi("set_formatsd.cgi?");
                  if (result) {
                    showOnlyConfirmTapDialog(context, '메모리가 초기화 되었습니다', () async {

                      us.bottomIndex.value = 1;
                      Get.back();
                    });
                  } else {
                    showOnlyConfirmTapDialog(context, '메모리 초기화를 실패했습니다', () async {

                      Get.back();
                    });
                  }
                  DialogManager.hideLoading();
                });
              },
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.black26,
                ),
                height: 50,
                child: Center(
                    child: Text(
                      '메모리 초기화',
                      style: f16w400WhiteSize(),
                    )),
              ),
            ),
            const SizedBox(
              height: 10,
            ),

            /// 카메라 삭제
            GestureDetector(
              onTap: () {
                showConfirmTapDialog(context, '해당 기기아이디를 삭제하시겠습니까?', () async {
                  Get.back();
                  final url = '${config.baseUrl}/cameradelete?uid=${cs.cameraUID.value}&email=${us.userList[0]['email']}';
                  final response = await http.get(Uri.parse(url));
                  showOnlyConfirmTapDialog(context, '삭제됐습니다', () async {
                    us.bottomIndex.value = 1;
                    Get.offAll(() => BottomNavigatorView());
                  });
                });
              },
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.red,
                ),
                height: 50,
                child: Center(
                    child: Text(
                      '카메라 삭제',
                      style: f16w400WhiteSize(),
                    )),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildRow(String title, String body) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '${title}',
          style: f18w700Size(),
        ),
        Text(
          '$body',
          style: f18w500Size(),
        ),
      ],
    );
  }

  int changeLastNumber(String value){
    int lastNum = int.parse('${value.split('.').last}');
    return lastNum;
  }
  /// 현재 펌웨어
  Future<void> currentFirmware() async {
    try {
      final url = '${config.baseUrl}/currentFirmware?currentVersion=${cs.ptzList[0].sourceData!['sys_ver']}&uid=${cs.cameraUID.value}';
      await http.get(Uri.parse(url));
      cs.cameraDetailList[0]['currentFirmware'] = cs.ptzList[0].sourceData!['sys_ver'] == '' ? '없음' : cs.ptzList[0].sourceData!['sys_ver'];
    } catch (error) {
      print('에러 currentFirmware $error');
      print('에러 currentFirmware ${cs.cameraDetailList}');
      print('에러 currentFirmware ${cs.ptzList}');
    }
  }
  /// 메모리 용량 계산
  Future<void> _initializeData() async {
    if (cs.ptzList.isEmpty) {
      setState(() {
        roundedPercentage = 0;
      });
    } else {
      double sdTotal = double.parse(cs.ptzList[0].sourceData!['sdtotal']) == 0 ? 1 : double.parse(cs.ptzList[0].sourceData!['sdtotal']);
      double sdFree = double.parse(cs.ptzList[0].sourceData!['sdfree']);
      double percentage = (sdFree / sdTotal) * 100;
      String formattedPercentage = percentage.toStringAsFixed(2);
      setState(() {
        roundedPercentage = (double.parse(formattedPercentage) + 0.5).toInt();
      });
    }
  }
}
