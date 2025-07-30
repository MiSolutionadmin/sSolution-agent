import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

import 'package:store_redirect/store_redirect.dart';
import 'package:url_launcher/url_launcher.dart';

import '../db/camera_table.dart';
import '../db/user_table.dart';
import '../provider/camera_state.dart';
import 'monitoring_dialog.dart';
import '../utils/font/font.dart';
import '../vstarcam/main/main_logic.dart';

Future<void> updateVersionDialog(BuildContext context) {
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
            contentPadding: const EdgeInsets.only(top: 35, bottom: 35),
            content: Container(
              width: Get.width,
              height: Get.height * 0.3,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MMS 업데이트 안내',
                      style: f16w700Size(),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    Text(
                      '안정적인 사용을 위해 MMS의 최신 버전을',
                      style: f14w500Size(),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    Text(
                      '준비했습니다. 스토어로 이동하여 새로운',
                      style: f14w500Size(),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    Text(
                      '버전으로 업데이트하신 후 이용 부탁드립니다.',
                      style: f14w500Size(),
                    ),
                    const SizedBox(
                      height: 30,
                    ),
                    Text(
                      '스토어에서 [업데이트] 버튼이 표시되지 않는 경우',
                      style: redf12w700(),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    Text(
                      '방법1) 앱 삭제 후 재설치',
                      style: redf12w700(),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    Text(
                      '방법2) 핸드폰 설정 > 애플리케이션 > Google Play',
                      style: redf12w700(),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    Text(
                      '스토어 > 저장공간 > 캐시 삭제 > 다시 업데이트 실행',
                      style: redf12w700(),
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
                      onTap: () async {
                        await updateVersion('appVersionCheck');
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
                                '나중에',
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
                      onTap: () async {
                        StoreRedirect.redirect(androidAppId: "com.Ssolutions.sSolution", iOSAppId: "6739551145");
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
          ),
        );
      });
}

Future<void> forceUpdateVersionDialog(
    BuildContext context,
    ) {
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
          contentPadding: const EdgeInsets.only(top: 35, bottom: 35),
          content: Container(
            width: Get.width,
            height: Get.height * 0.3,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'MMS 업데이트 안내',
                    style: f16w700Size(),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Text('안정적인 사용을 위해 MMS의 최신 버전을', style: f14w500Size()),
                  const SizedBox(height: 10),
                  Text('준비했습니다. 스토어로 이동하여 새로운', style: f14w500Size()),
                  const SizedBox(height: 10),
                  Text('버전으로 업데이트하신 후 이용 부탁드립니다.', style: f14w500Size()),
                  const SizedBox(height: 30),
                  Text('스토어에서 [업데이트] 버튼이 표시되지 않는 경우', style: redf12w700()),
                  const SizedBox(height: 10),
                  Text('방법1) 앱 삭제 후 재설치', style: redf12w700()),
                  const SizedBox(height: 10),
                  Text('방법2) 핸드폰 설정 > 애플리케이션 > Google Play', style: redf12w700()),
                  const SizedBox(height: 10),
                  Text('스토어 > 저장공간 > 캐시 삭제 > 다시 업데이트 실행', style: redf12w700()),
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
                      StoreRedirect.redirect(androidAppId: "com.Ssolutions.sSolution", iOSAppId: "6739551145");
                    },
                    behavior: HitTestBehavior.opaque,
                    child: Center(
                      child: Container(
                        width: Get.width,
                        height: 42,
                        decoration: BoxDecoration(
                          color: Color(0xff1955EE),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            '확인',
                            style: f16w700WhiteSize(),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      );
    },
  );
}

updateCameraDialog(BuildContext contexts) {
  showDialog(
      context: contexts,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return PopScope(
          canPop: false,
          child: AlertDialog(
            surfaceTintColor: Colors.white,
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            contentPadding: const EdgeInsets.only(top: 35, bottom: 35),
            content: Container(
              width: Get.width,
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '카메라 업데이트 안내',
                      style: f16w700Size(),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    Text(
                      '카메라 기능 향상을 위한 최신 펌웨어가',
                      style: f14w500Size(),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    Text(
                      '준비됐습니다. 업데이트를 통해 향상된',
                      style: f14w500Size(),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    Text(
                      '기능이 적용된 카메라 이용 부탁드립니다.',
                      style: f14w500Size(),
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
                      onTap: () async {
                        await updateVersion('cameraVersionCheck');
                        us.userList[0]['cameraVersionCheck'] = 'false';
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
                                '나중에',
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
                      onTap: () async {
                        Get.back();
                        showCameraUpdateDialog(contexts);
                      },
                      behavior: HitTestBehavior.opaque,
                      child: Center(
                        child: Container(
                          width: Get.width,
                          height: 42,
                          decoration: BoxDecoration(color: Color(0xff1955EE), borderRadius: BorderRadius.circular(8)),
                          child: Center(
                              child: Text(
                                '업데이트',
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


/// 다이얼로그를 보여줄 함수
void showCameraUpdateDialog(BuildContext context) {
  showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return PopScope(
          canPop: false,
          child: AlertDialog(
            surfaceTintColor: Colors.white,
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            insetPadding: EdgeInsets.only(left: 10, right: 10),
            contentPadding: const EdgeInsets.only(top: 35, bottom: 35),
            content: Container(
              width: Get.width,
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Obx(() => Row(
                      children: [
                        Text(
                          '카메라 업데이트 목록',
                          style: f16w700Size(),
                          textAlign: TextAlign.center,
                        ),
                        Spacer(),
                        GestureDetector(
                          onTap: () async {
                            /// 하나라도 선택되어있으면 전체 선택
                            /// 전부다 선택되어있으면 전체 해제
                            /// 전부다 선택되어있지 않으면 전체 선택

                            if (cs.cameraAllCheck.value == false) {
                              //cs.cameraListClick.value = List<bool>.filled(cs.cameraListClick.length, true, growable: true);
                              // cs.cameraListClick.refresh();
                              // cs.cameraList.refresh();
                              cs.cameraAllCheck.value = true;
                              cs.cameraDetailSelectList.clear();
                              for (var item in cs.cameraList) {
                                cs.cameraDetailSelectList.add(item['cameraUid']);
                              }
                            } else {
                              //cs.cameraListClick.value = List<bool>.filled(cs.cameraListClick.length, false, growable: true);
                              // cs.cameraListClick.refresh();
                              // cs.cameraList.refresh();
                              cs.cameraAllCheck.value = false;
                              cs.cameraDetailSelectList.clear();
                            }
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: Colors.blue,
                            ),

                            child: !cs.cameraUpdateClick.value ?  Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                    cs.cameraAllCheck.value ? '전체 해제' : '전체 선택',
                                    style: f14Whitew700Size(),
                                  ),
                                )): SizedBox.shrink(),
                          ),
                        )
                      ],
                    )),
                    const SizedBox(
                      height: 20,
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(color: Color(0xff79D2A6), border: Border.all(color: Colors.black)),
                            child: Center(child: Text('카메라 목록')),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Color(0xff79D2A6),
                              border: Border(
                                top: BorderSide(color: Colors.black),
                                right: BorderSide(color: Colors.black),
                                bottom: BorderSide(color: Colors.black),
                                left: BorderSide.none,
                              ),
                            ),
                            child: Center(child: Text('펌웨어 버전')),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    Obx(() => Container(
                      height: cs.cameraList.length > 5 ? 300 : null,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.black),
                      ),
                      child: ListView.builder(
                        itemCount: cs.cameraList.length,
                        shrinkWrap: true,
                        physics: const ClampingScrollPhysics(),
                        itemBuilder: (_, index) {
                          String cameraUid = cs.cameraList[index]['cameraUid'];
                          return Column(
                            children: [
                              GestureDetector(
                                onTap: () {
                                  /// 하나라도 선택되어있으면 전체 선택
                                  /// 전부다 선택되어있으면 전체 해제
                                  /// 전부다 선택되어있지 않으면 전체 선택
                                  ///
                                  if(cs.cameraUpdateClick.value == false)
                                    {
                                      if (cs.cameraDetailSelectList.contains(cameraUid)) {
                                        cs.cameraDetailSelectList.remove(cameraUid);
                                      } else {
                                        cs.cameraDetailSelectList.add(cameraUid);
                                      }
                                    }
                                  print("업데이트 할 항목 ${cs.cameraDetailSelectList}");
                                  print("이거 선택 됬나? ${cs.cameraDetailSelectList.contains(cameraUid)}");
                                },
                          child: Obx(() =>  Container(
                                  decoration: BoxDecoration(
                                    color: cs.cameraDetailSelectList.contains(cameraUid) ? Color(0xff97A1AF) :  Color(0xffCED2DA),
                                    border: index == cs.cameraList.length - 1
                                        ? Border(
                                      bottom: BorderSide(style: BorderStyle.none),
                                    )
                                        : Border(
                                      bottom: BorderSide(color: Colors.black),
                                    ),
                                  ),
                                  width: Get.width,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Container(
                                            decoration: BoxDecoration(
                                              border: Border(
                                                right: BorderSide(
                                                  color: Colors.black,
                                                  width: 1.0,
                                                ),
                                              ),
                                            ),
                                            child: Padding(
                                              padding: const EdgeInsets.symmetric(vertical: 8),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    '${cs.cameraList[index]['ipcamId']}',
                                                    style: f12w700,
                                                    overflow: TextOverflow.ellipsis,
                                                    maxLines: 1,
                                                  ),
                                                  Text(
                                                    '(${cs.cameraList[index]['cameraUid']})',
                                                    style: f12w700,
                                                    overflow: TextOverflow.ellipsis,
                                                    maxLines: 1,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: Center(
                                            child: Text(
                                              '${cs.cameraDetailTotalList[index]['currentFirmware']}',
                                              style: f12w700,
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 2,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                          )
                              ),
                            ],
                          );
                        },
                      ),
                    )),
                    const SizedBox(
                      height: 10,
                    ),
                    Center(child: Text('최신 펌웨어 ${us.versionList[0]['camera']}', style: f14w700)),
                    Obx(() => cs.cameraUpdateClick.value
                        ? Column(
                      children: [
                        const SizedBox(
                          height: 10,
                        ),
                        Center(child: Text('카메라 펌웨어를 업데이트하고 있습니다.', style: f12w500)),
                        Center(child: Text('확인을 누르면 카메라 목록으로 이동합니다.', style: f12w500)),
                        Center(child: Text('3~5분 후 어플을 재실행하여 확인 바랍니다.', style: f12w500)),
                      ],
                    )
                        : Column(
                      children: [
                        const SizedBox(
                          height: 10,
                        ),
                        Center(child: Text('위 연결 상태의 카메라를 일괄 업데이트합니다.', style: f12w500)),
                        Center(child: Text('업데이트가 완료되는데 약 3~5분이 소요됩니다', style: f12w500)),
                      ],
                    ))
                  ],
                ),
              ),
            ),
            actions: [
              Obx(() => Row(
                children: [
                  cs.cameraUpdateClick.value
                      ? SizedBox()
                      : Expanded(
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
                            child: Text('취소', style: f16w700Size()),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 8,
                  ),
                  Obx(() => cs.cameraUpdateClick.value
                      ? Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        await updateVersion('cameraVersionCheck');
                        us.userList[0]['cameraVersionCheck'] = 'false';
                        cs.cameraList.clear();
                        // us.bottomIndex.value = 1;
                        Get.back();
                        // Get.offAll(()=>BottomNavigator());
                        Future.delayed(Duration(milliseconds: 300), () {
                          cs.cameraUpdateClick.refresh();
                          cs.cameraUpdateClick.value = false;
                        });
                      },
                      behavior: HitTestBehavior.opaque,
                      child: Center(
                        child: Container(
                          width: Get.width,
                          height: 42,
                          decoration: BoxDecoration(
                            color: Color(0xff1955EE),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text('확인', style: f16w700WhiteSize()),
                          ),
                        ),
                      ),
                    ),
                  )
                      : Expanded(
                    child: GestureDetector(
                      onTap: () async {

                        final mainLogic = Get.find<MainLogic>();

                        if (cs.cameraDetailSelectList.isEmpty) {
                          showOnlyConfirmDialog(context, '업데이트 하실 카메라를 선택해주세요');
                          return;
                        }

                        List<Future<void>> futures = [];

                        for (String cameraUid in cs.cameraDetailSelectList) {
                          futures.add(() async {
                            bool checked = await mainLogic.sendInit(cameraUid);
                            if (checked) {
                              await cameraDetailSwitch(
                                cameraUid,
                                'currentFirmware',
                                '${us.versionList[0]['camera']}',
                              );
                            }
                          }());
                        }

                        await Future.wait(futures);
                        cs.cameraUpdateClick.value = true;


                        // Future(() async {
                        //   await Future.delayed(Duration.zero, () async {
                        //     final mainLogic = Get.find<MainLogic>();
                        //
                        //     cs.cameraCopyList.value = jsonDecode(jsonEncode(cs.cameraList));
                        //
                        //     if (cs.cameraListClick.every((element) => !element)) {
                        //       showOnlyConfirmDialog(context, '업데이트 하실 카메라를 선택해주세요');
                        //     }
                        //
                        //     /// 체크한 리스트 목록
                        //     List<Future<void>> futures = [];
                        //     for (int i = 0; i < cs.cameraCopyList.length; i++) {
                        //       futures.add(() async {
                        //         if (cs.cameraListClick[i]) {
                        //           bool checked = await mainLogic.sendInit('${cs.cameraCopyList[i]['cameraUid']}');
                        //           if (checked) {
                        //             await cameraDetailSwitch(
                        //                 cs.cameraCopyList[i]['cameraUid'], 'currentFirmware', '${us.versionList[0]['camera']}');
                        //             cs.cameraUpdateClick.value = true;
                        //           }
                        //         }
                        //       }());
                        //     }
                        //     await Future.wait(futures);
                        //   });
                        // });
                      },
                      behavior: HitTestBehavior.opaque,
                      child: Center(
                        child: Container(
                          width: Get.width,
                          height: 42,
                          decoration: BoxDecoration(
                            color: Color(0xff1955EE),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text('확인', style: f16w700WhiteSize()),
                          ),
                        ),
                      ),
                    ),
                  ))
                ],
              ))
            ],
          ),
        );
      });
}



/// tf카드 다운로드 퍼센테이지 다이얼로그
Future<void> showTfCameraPercentageDialog(BuildContext context) async{
  final cs = Get.find<CameraState>();
  showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return PopScope(
          canPop: false,
          child: AlertDialog(
            surfaceTintColor: Colors.white,
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            insetPadding: EdgeInsets.only(left: 10, right: 10),
            contentPadding: const EdgeInsets.only(top: 35, bottom: 35),
            content: Container(
              width: 300,
              height: 150,
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Obx(()=>Center(
                      child: CircularPercentIndicator(
                        radius: 100.0,
                        lineWidth: 10.0,
                        percent: cs.cameraPercentage.value == ''
                            ? 0.0
                            : (double.parse(cs.cameraPercentage.value) > 100
                            ? 100
                            : double.parse(cs.cameraPercentage.value)) / 100,
                        center: Text(
                          cs.cameraPercentage.value == ''
                              ? "0.0%"
                              : (double.parse(cs.cameraPercentage.value) > 100
                              ? "100%"
                              : "${cs.cameraPercentage.value}%"),
                        ),
                        progressColor: Colors.blue,
                        backgroundColor: Colors.grey[200]!,
                      ),
                    )),
                    const SizedBox(height: 10,),
                    Obx(()=> cs.tfCameraChangeMp4.value?Text('메모리카드 영상을 변환중입니다.\n 잠시만 기다려주세요',
                      style: f14w700Black,
                      textAlign: TextAlign.center,):Text('메모리카드 영상을 다운로드 중입니다.\n 잠시만 기다려주세요',
                      style: f14w700Black,
                      textAlign: TextAlign.center,))
                  ],
                ),
              ),
            ),
          ),
        );
      });
}
