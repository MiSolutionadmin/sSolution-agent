import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../components/dialog.dart';
import '../../db/get_monitoring_info.dart';
import '../../provider/user_state.dart';
import '../../utils/color.dart';
import '../../utils/font/font.dart';

class MonitoringSetting extends StatefulWidget {
  final int index;

  const MonitoringSetting({Key? key, required this.index}) : super(key: key);

  @override
  State<MonitoringSetting> createState() => _MonitoringSettingState();
}

class _MonitoringSettingState extends State<MonitoringSetting> {
  final us = Get.find<UserState>();
  TextEditingController con = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    con.dispose();
    super.dispose();
  }

  /// ✅ 저장 눌렀을때 함수
  void pressedSettingSaved() async {
    showConfirmTapDialog(context, '저장하시겠습니까?', () async {
      final filteredList = us.userMmsList.where((item) => item['checked'] == true).toList();
      final firstCheckedIndex = us.userMmsList.indexWhere((item) => item['checked'] == true);
      if (filteredList.isNotEmpty) {
        await userMmsUpdate(filteredList[0]['mms']);
        us.userList[0]['mms'] = filteredList[0]['mms'];
        us.userMonitoring[0]['mmsName'] = filteredList[0]['mmsName'];
      }
      us.userList.refresh();
      List mmsList = us.userMmsList.map((item) {
        return {"mms": item['mms'], 'mmsName': item['mmsName']};
      }).toList();
      await us.loadDataForMms();
      await userMmsListUpdate(mmsList);
      await getMmsList();
      await pageMonitoringInfo(us.userMmsList[widget.index]['mms']);
      Get.back();
      Get.back(result: firstCheckedIndex == -1 ? widget.index : firstCheckedIndex);
    });
  }

  /// ✅ mms 이름 변경 모달
  void pressedMmsNameChanged(int index) async {
    if (us.userList[0]['head'] == 'true') {
      con.text = '${us.userMmsList[index]['mmsName'] == 'null' ? '' : us.userMmsList[index]['mmsName'] ?? ''}';
      showMmsNameChangeDialog(context, con, us.userMmsList[index]['mms'], () {
        if (con.text.trim().isEmpty) {
          showOnlyConfirmDialog(context, 'MMS 이름을 입력해주세요');
        } else {
          us.userMmsList[index]['mmsName'] = con.text;
          us.userMmsList.refresh();
          Get.back();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvoked: (bool) async {
        await getMmsList();
      },
      child: Scaffold(
        backgroundColor: const Color(0xffF1F4F7),
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: AppBar(
            leading: GestureDetector( /// ✅ 뒤로가기
                onTap: () async {
                  Get.back();
                  await getMmsList();
                },
                child: const Icon(Icons.arrow_back_ios)),
            title: Text(
              'MMS 이름/순서 설정',
              style: f16w800Size(),
            ),
            centerTitle: true,
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 20),
                child: GestureDetector(
                    onTap: () {
                      pressedSettingSaved(); /// ✅ 세팅저장 함수
                    },
                    child: Text(
                      '저장',
                      style: f14w700BlueSize(),
                    )),
              )
            ],
          ),
        ),
        body: Obx(() => Padding(
              padding: const EdgeInsets.only(left: 20, right: 20, top: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: ReorderableListView(
                      shrinkWrap: true,
                      buildDefaultDragHandles: true,
                      physics: const ClampingScrollPhysics(),
                      proxyDecorator: (Widget child, int index, Animation<double> animation) {
                        return Material(
                          color: Colors.transparent,
                          child: child,
                        );
                      },
                      children: [
                        for (int index = 0; index < us.userMmsList.length; index += 1)
                          Container( /// ✅ mms 카드
                            key: Key('${index}'),
                            height: 65,
                            margin: const EdgeInsets.only(bottom: 5, top: 10),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                            child: Padding(
                              padding: const EdgeInsets.only(left: 10, right: 10),
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () async {
                                  pressedMmsNameChanged(index); /// ✅ mms 이름변경 모달
                                },
                                child: Row(
                                  children: [
                                    /// ✅ mms Uid
                                    Container(width: 80, margin: EdgeInsets.only(bottom: 10, top: 10), child: Text('${hexToChar('${us.userMmsList[index]['mms']}')}', style: f16w700Size())),
                                    /// ✅ mms Name
                                    Expanded(
                                        child: Text('${us.userMmsList[index]['mmsName'] == 'null' ? '' : us.userMmsList[index]['mmsName'] ?? '${us.userMmsList[index]['mms']}'}', style: f16w700Size(),overflow: TextOverflow.ellipsis,maxLines: 1,)
                                    ),
                                    /// ✅ 체크박스
                                    Checkbox(
                                      side: BorderSide.none,
                                      fillColor: MaterialStateProperty.all(blueColor),
                                      value: us.userMmsList[index]['checked'],
                                      onChanged: (value) {
                                        /// ✅ 체크박스 선택 (의미불명)
                                        us.userMmsList.value = us.userMmsList.map((item) {
                                          item['checked'] = false;
                                          return item;
                                        }).toList();
                                        us.userMmsList[index]['checked'] = true;
                                        us.userMmsList.refresh();
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                      /// ✅ 꾹눌러서 => 순서바꿧을때
                      onReorder: (int oldIndex, int newIndex) async {
                        setState(() {
                          if (oldIndex < newIndex) {
                            newIndex -= 1;
                          }
                          final item = us.userMmsList.removeAt(oldIndex);
                          us.userMmsList.insert(newIndex, item);
                        });
                      },
                    ),
                  )
                ],
              ),
            )),
      ),
    );
  }

  /// 4c를 L로 바꿈(16진수를 문자열로)
  String hexToChar(String hex) {
    if (hex.length == 6) {
      String remainText = hex.substring(2);
      String sliceHex = String.fromCharCode(int.parse(hex.substring(0, 2), radix: 16)); // ex) L
      hex = sliceHex + remainText;
    }
    return hex;
  }
}
