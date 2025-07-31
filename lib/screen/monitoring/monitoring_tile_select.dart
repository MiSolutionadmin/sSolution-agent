import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:mms/utils/input_formatter/meter_input_formatter.dart';
import '../../components/dialog.dart';
import '../../components/text_container.dart';
import '../../provider/user_state.dart';
import '../../utils/font/font.dart';

class MonitoringTilePage extends StatefulWidget {
  final int index;

  const MonitoringTilePage({Key? key, required this.index}) : super(key: key);

  @override
  State<MonitoringTilePage> createState() => _MonitoringTilePageState();
}

class _MonitoringTilePageState extends State<MonitoringTilePage> {
  final us = Get.find<UserState>();
  TextEditingController con = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchInit();
  }

  @override
  void dispose() {
    con.dispose();
    super.dispose();
  }
  
  /// ✅ 모니터링 항목수정 init함수
  void fetchInit() async {
    /// ✅ 계량기값 세팅
    if (us.userMmsList.isNotEmpty) {
      con.text = '${us.userMmsTileList[widget.index][6]['value']}';
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      child: Scaffold(
        backgroundColor: const Color(0xffF1F4F7),
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: AppBar(
            leading: GestureDetector(
                onTap: () async {
                  Get.back();
                },
                child: Icon(Icons.arrow_back_ios)),
            title: Text(
              '모니터링 항목 수정',
              style: f16w800Size(),
            ),
            centerTitle: true,
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 20),
                child: GestureDetector(
                    onTap: () {
                      /// ✅ 저장버튼 눌렀을때 함수
                      // 1. 계량기값 유효한 숫자인지 체크 (아닐시 0 처리)

                      print("더블 ? : ${double.tryParse(con.text)}");
                      us.userMmsTileList[widget.index][6]['value'] = double.tryParse(con.text) != null ? con.text : 0;

                      // 2. 데이터 저장
                      showConfirmTapDialog(context, '저장하시겠습니까?', () async {
                        await us.saveDataForMms('${us.userMmsList[widget.index]['mms']}', widget.index);
                        await us.loadDataForMms();
                        Get.back();
                        Get.back();
                      });
                    },
                    child: Text(
                      '저장',
                      style: f14w700BlueSize(),
                    )),
              )
            ],
          ),
        ),
        body: Obx(() => us.userMmsTileList.isEmpty
            ? SizedBox()
            : Padding(
                padding: const EdgeInsets.only(left: 10, right: 10, top: 20, bottom: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: ReorderableListView(
                        shrinkWrap: true,
                        proxyDecorator: (Widget child, int index, Animation<double> animation) {
                          return Material(
                            color: Colors.transparent,
                            child: child,
                          );
                        },
                        buildDefaultDragHandles: true,
                        children: [
                          for (int index = 0; index < 6; index += 1)

                            /// ✅ mms 요소 카드
                            Container(
                              key: Key('${index}'),
                              child: Padding(
                                padding: const EdgeInsets.only(left: 10, right: 10),
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 10, top: 10),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        /// ✅ ON/OFF 스위치
                                        child: SwitchContainer(
                                            onTap: () {
                                              /// ✅ us.userMmsTileList의 checked 상태에 따라 변경
                                              us.userMmsTileList[widget.index][index]['checked'] = !us.userMmsTileList[widget.index][index]['checked'];
                                              us.userMmsTileList.refresh();
                                            },
                                            value: us.userMmsTileList[widget.index][index]['checked'],
                                            name: '${us.userMmsTileList[widget.index][index]['title']}'),
                                      )
                                    ],
                                  ),
                                ),
                              ),
                            ),
                        ],
                        /// ✅ 꾹 눌러서 => 리스트 변경했을때
                        onReorder: (int oldIndex, int newIndex) async {
                          setState(() {
                            /// ✅ 리스트 순서변경 함수
                            if (oldIndex < newIndex) {
                              newIndex -= 1;
                            }
                            final item = us.userMmsTileList[widget.index].removeAt(oldIndex);
                            us.userMmsTileList[widget.index].insert(newIndex, item);
                            for (int i = 0; i < 6; i++) {
                              us.userMmsTileList[widget.index][i]['index'] = i;
                            }
                            us.userMmsTileList.refresh();
                          });
                        },
                      ),
                    ),
                    /// ✅ 계량기 세팅
                    Container(
                        width: Get.width,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '계량기 세팅 값을 입력해주세요',
                              style: f16w700Size(),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(
                              height: 10,
                            ),
                            TextFormField(
                              controller: con,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                LengthLimitingTextInputFormatter(20),
                                onlyAllowSignedDecimal(),
                              ],
                              decoration: InputDecoration(
                                hintText: '값 입력',
                                hintStyle: TextStyle(
                                  fontSize: 12,
                                  fontFamily: 'Pretendard',
                                  fontWeight: FontWeight.w400,
                                  color: const Color(0xffB5B5B5),
                                ),
                                contentPadding: EdgeInsets.fromLTRB(15, 18, 0, 18),
                                filled: true,
                                fillColor: const Color(0xFFF5F6F7),
                                enabledBorder: UnderlineInputBorder(
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: UnderlineInputBorder(
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                          ],
                        ))
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
