import 'dart:async';
import 'dart:io';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:mms/components/dialogManager.dart';

import '../../base_config/config.dart';
import '../../components/color_radio.dart';
import '../../components/dialog.dart';
import '../../db/get_monitoring_info.dart';
import '../../db/user_table.dart';
import '../../provider/user_state.dart';
import '../../utils/font/font.dart';
import 'monitoring_setting_screen.dart';
import 'monitoring_tile_select.dart';

class MonitoringMainPage extends StatefulWidget {
  const MonitoringMainPage({Key? key}) : super(key: key);

  @override
  State<MonitoringMainPage> createState() => _MonitoringMainPageState();
}

class _MonitoringMainPageState extends State<MonitoringMainPage> with SingleTickerProviderStateMixin {
  DateTime now = DateTime.now();
  late Socket socket;

  /// ✅ 전역 상태
  final us = Get.put(UserState());
  final config = AppConfig();

  /// ✅ 캐러셀
  final CarouselSliderController _carouselController = CarouselSliderController();
  late AnimationController _animationController;

  /// ✅ mms 요소 loading
  bool _isLoading = true;

  /// ✅ 급수관 개폐 timer
  Timer? _timer;

  /// ✅ carousel 페이지 인덱스
  int pageIdx = 0;

  /// ✅ 테스트계정 email list
  List<String> emails = ['test-1@test.com', 'test-2@test.com', 'test-3@test.com', 'test-4@test.com'];

  /// 급수관 개폐 함수
  bool switchButton = false;
  bool switchClick = false;

  @override
  void initState() {
    _animationController = AnimationController(
      /// ✅ 캐러셀 슬라이드 애니메이션
      vsync: this,
      duration: Duration(seconds: 1),
    )..repeat(reverse: true);

    fetchInit();

    super.initState();
  }

  /// ✅ 모니터링 페이지 init 함수
  void fetchInit() async {
    if (us.userList.isEmpty) return;
    await getUserWithOutToken(us.userList[0]['email']);

    /// ✅ 유저정보 가져오기
    await getMmsList();

    /// ✅ mmsList 가져오기
    await us.loadDataForMms();
    await checkDuplicateLogin(context);

    ///  ✅ 중복체크

    if (us.userMmsList.isNotEmpty) {
      await pageMonitoringInfo(us.userMmsList[0]['mms']);
    }
    if (us.userMonitoring.isNotEmpty && us.userMonitoring[0]['data'] != '대기중') {
      switchButton = bool.parse('${us.userMonitoring[0]['data']}');
    }
    _isLoading = false;

    /// 애니메이션을 반복하여 깜빡이도록 설정
    _timer = Timer.periodic(Duration(seconds: 2), (timer) async {
      /// ✅ 미연결시 ! 아이콘 깜빡임 애니메이션
      if (!mounted) return;
      now = DateTime.now();
      if (us.userMmsList.isNotEmpty) {
        await pageMonitoringInfo(us.userMmsList[pageIdx]['mms']);
      }
      if (us.userMonitoring.isEmpty) {
        timer.cancel();
      } else if (us.userMonitoring[0]['data'] != '대기중') {
        switchButton = us.userMonitoring[0]['data'] == 'true';
      }
      _isLoading = false;
      setState(() {});
    });
    setState(() {});
  }

  /// ✅ 급수관 개폐 timer 시작함수
  void _startTimer() {
    _timer?.cancel(); // 기존 타이머가 있으면 취소
    _timer = Timer.periodic(Duration(seconds: 2), (timer) async {
      if (!mounted) return;
      now = DateTime.now();
      await pageMonitoringInfo(us.userMmsList[pageIdx]['mms']);
      if (us.userMonitoring.isEmpty) {
        timer.cancel();
      } else if (us.userMonitoring[0]['data'] != '대기중') {
        switchButton = us.userMonitoring[0]['data'] == 'true';
      }
      _isLoading = false;
      setState(() {});
    });
  }

  /// ✅ 급수관 개폐 timer 중지함수
  void _stopTimer() {
    _timer?.cancel();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  /// 4c를 L로 바꿈(16진수를 문자열로)
  String hexToChar(String hex) {
    if (hex.length == 6) {
      String remainText = hex.substring(2);
      String sliceHex = String.fromCharCode(int.parse(hex.substring(0, 2), radix: 16));
      hex = sliceHex + remainText;
    }
    return hex;
  }

  /// ✅ 급수관 여/닫기 함수
  void pressedPump(status) async {
    if (status == !switchButton) {
      /// ✅ switchButton 상태와 연동되게 (중복방지)
      if (us.userMonitoring.length == 0 || us.userMonitoring[0]['updateTime'] == null || now.difference(DateTime.parse('${us.userMonitoring[0]['updateTime']}')).inSeconds > 60) {
        showOnlyConfirmDialog(context, '잠시 후 다시 실행해주세요');
      } else {
        await showValveTapDialog(context, '급수관 밸브를 ${status ? "여" : "닫으"}시겠습니까?', () async {
          _timer?.cancel();
          us.userMonitoring[0]['data'] = '대기중';
          switchClick = true;
          Get.back();

          /// ✅ 소켓변수에 급수관 데이터 담기
          await changeSwitch((status ? true : false), '급수관', us.userMmsList[pageIdx]['mms']);

          /// ✅ 소켓 관련
          socket = await Socket.connect('${config.sockUrl}', config.sockPort);
          socket.add(us.userSocketData.value);
          socket.close();
          DialogManager.showLoading(context);
          /// ✅ 알림내역 추가
          await us.alimAdd('${us.userMmsList[pageIdx]['mms']}', '상수도유입밸브 변경', status ? '밸브 열림' : '밸브 닫힘', status ? 'noting' : '', status ? 'noting' : '', '10', status && us.userList.isNotEmpty ? '${us.userList[0]['name']}' : '',
              '${us.userMonitoring[0]['mmsName'] ?? ''}');

          Future.delayed(Duration(seconds: 13), () {
            DialogManager.hideLoading();
            //Get.back();
            _timer = Timer.periodic(Duration(seconds: 2), (timer) async {
              await pageMonitoringInfo(us.userMmsList[pageIdx]['mms']);

              /// ✅ 고정mms => 보고있는mms로 변경
              if (us.userMonitoring[0]['data'] != '대기중') {
                switchButton = bool.parse('${us.userMonitoring[0]['data']}');
                switchClick = false;
              }
              _isLoading = false;
              setState(() {});
            });
          });
          setState(() {});
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF1F4F7),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(52),
        child: AppBar(
          automaticallyImplyLeading: false,
          title: Obx(() => Row(
                children: [
                  /// ✅ 기관이름
                  Container(
                    width: Get.width * 0.5,
                    child: Text(
                      '${us.userList.isNotEmpty ? us.userList[0]['agency'] : ''}',
                      style: f20w700Size(),
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.left,
                    ),
                  ),
                  const Spacer(),

                  /// ✅ mms 활성화 상태 아이콘
                  buildMonitoringStatusIcon(),
                  const SizedBox(
                    width: 10,
                  ),

                  /// ✅ 모니터링 설정 버튼
                  buildMonitoringSettingButton(),
                  const SizedBox(
                    width: 10,
                  ),

                  /// ✅ 설정 버튼
                  GestureDetector(
                    onTap: () {
                      Get.to(() => MonitoringTilePage(
                            index: pageIdx,
                          ));
                    },
                    child: SvgPicture.asset(
                      'assets/icon/setting.svg',
                      width: 24,
                      height: 24,
                    ),
                  ),
                ],
              )),
        ),
      ),
      body: _isLoading
          ? Center(
              child: const CircularProgressIndicator(),
            )
          : (us.userList.isEmpty || us.userList[0]['mms'] == 'NULL') || us.userMonitoring.isEmpty
              ? Center(

                  /// ✅ mms 없을시
                  child: Text(
                  'ML100을 추가해주세요',
                  style: f18w700Size(),
                ))
              : Obx(() => Container(
                    color: const Color(0xffF1F4F7),
                    child: Column(
                      children: [
                        /// ✅ mms / mmsName
                        mmsFieldWidget(),
                        const SizedBox(
                          height: 12,
                        ),

                        us.userMmsTileList.isEmpty
                            ? const SizedBox()
                            : Expanded(
                                child: Container(
                                  child: NotificationListener<ScrollNotification>(
                                    onNotification: (notification) {
                                      if (notification.metrics.axis == Axis.horizontal) {
                                        if (notification is ScrollStartNotification) {
                                          _stopTimer(); // 스크롤 시작 시 타이머 중지
                                        } else if (notification is ScrollEndNotification) {
                                          _startTimer(); // 스크롤 종료 시 타이머 시작
                                        }
                                      }
                                      return true;
                                    },
                                    child: CarouselSlider.builder(
                                      carouselController: _carouselController,
                                      options: CarouselOptions(
                                        height: Get.height,
                                        viewportFraction: 1.0,
                                        enableInfiniteScroll: true,
                                        autoPlay: false,
                                        onPageChanged: (index, reason) async {
                                          /// ✅ 캐러셀 슬라이드 동작
                                          pageIdx = index;
                                          // 해당 mms 정보 가져오기
                                          await pageMonitoringInfo(us.userMmsList[pageIdx]['mms']);

                                          setState(() {});
                                        },
                                      ),
                                      itemCount: us.userMmsList.length,
                                      itemBuilder: (context, index, realIndex) {
                                        return Obx(
                                          () => us.userMmsTileList.isEmpty
                                              ? const SizedBox.shrink()
                                              : Padding(
                                                  padding: const EdgeInsets.only(left: 10, right: 10),
                                                  child: SingleChildScrollView(
                                                    child: ListView.builder(
                                                      shrinkWrap: true,
                                                      physics: const NeverScrollableScrollPhysics(),
                                                      itemCount: us.userMmsTileList[index].where((item) => item['checked'] == true).length,
                                                      itemBuilder: (context, indexs) {
                                                        final filteredList = us.userMmsTileList[index].where((item) => item['checked'] == true).toList();

                                                        /// ✅ mms 요소 카드
                                                        switch (filteredList[indexs]['title']) {
                                                          case '저수조 수위':
                                                            return buildWaterLevelWidget();
                                                          case '집수정':
                                                            return buildJibWidget();
                                                          case '상수도유입밸브':
                                                            return buildPumpWidget();
                                                          case '소방수신기 상태':
                                                            return buildFireWidget();
                                                          case '변압기 상태':
                                                            return buildTempWidget();
                                                          case '정화조 수위':
                                                            return buildCleanWidget();
                                                          default:
                                                            return const SizedBox.shrink(); // 기본 빈 컨테이너
                                                        }
                                                      },
                                                    ),
                                                  ),
                                                ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ),
                      ],
                    ),
                  )),
    );
  }

  /// ✅ 모니터링 오류 알림 아이콘
  Widget buildMonitoringStatusIcon() {
    if (us.userList.isEmpty || us.userList[0]['mms'] == 'NULL' || _isLoading || us.userMonitoring.isEmpty || us.userMonitoring.length == 0) {
      return const SizedBox();
    }

    final updateTime = us.userMonitoring[0]['updateTime'];

    if (updateTime == null) {
      /// ✅ 마지막 updateTime이 null일시
      return FadeTransition(
        opacity: _animationController,
        child: Container(
          width: 24,
          height: 24,
          child: Image.asset('assets/icon/error.png', fit: BoxFit.fill),
        ),
      );
    }

    if (now.difference(DateTime.parse('$updateTime')).inSeconds <= 60) {
      /// ✅ 최근까지 업데이트 됐을시
      return const SizedBox.shrink();
    }

    return FadeTransition(
      /// ✅ 그 외
      opacity: _animationController,
      child: Container(
        width: 24,
        height: 24,
        child: Image.asset('assets/icon/error.png', fit: BoxFit.fill),
      ),
    );
  }

  /// ✅ 모니터링 설정 버튼
  Widget buildMonitoringSettingButton() {
    if (us.userList.isNotEmpty && emails.contains(us.userList[0]['email'])) {
      return SizedBox.shrink();
    }

    return GestureDetector(
      onTap: () {
        Get.to(() => MonitoringSetting(index: pageIdx))?.then((v) {
          if (us.userMmsList.isNotEmpty && v != null) {
            pageIdx = int.parse('$v');
            _carouselController.jumpToPage(pageIdx);
            setState(() {});
          }
        });
      },
      child: const Icon(
        Icons.list,
        size: 38,
      ),
    );
  }

  /// ✅ mms / mmsName 위젯
  Widget mmsFieldWidget() {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.only(left: 10, right: 10),

        /// ✅ mms / mmsName
        child: Row(
          children: [
            Container(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Center(child: Text('${us.userMmsList.isEmpty ? '' : hexToChar('${us.userMmsList[pageIdx]['mms']}')}', style: f16w700Size())),
              ),
            ),
            Expanded(
              child: Container(
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(9),
                  child: Text('${us.userMonitoring[0]['mmsName'] ?? '${hexToChar('${us.userMonitoring[0]['mms']}')}'}', style: f16w700Size()),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 저수조 위젯
  Widget buildWaterLevelWidget() {
    return Column(
      children: [
        Stack(
          children: [
            Positioned(
              child: Container(
                width: Get.width,
                height: 135,
                child: SvgPicture.asset(
                  'assets/icon/water.svg',
                  fit: BoxFit.fill,
                ),
              ),
            ),
            Positioned.fill(
              top: 20,
              child: Align(
                alignment: Alignment.topCenter,
                child: Text(
                  '저수조 수위',
                  style: f18w700Size(),
                ),
              ),
            ),
            Positioned.fill(
              left: 20,
              right: 20,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(
                    height: 20,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            '디지털계량기',
                            style: f16w700Size(),
                          ),
                          digitalText(),
                        ],
                      ),
                      Column(
                        children: [
                          Text(
                            '오뚜기 센서',
                            style: f16w700Size(),
                          ),
                          Text(
                            us.userMonitoring[0]['ottogi'] == '0'
                                ? '정상'
                                : us.userMonitoring[0]['ottogi'] == '1'
                                    ? '저수위 경보'
                                    : us.userMonitoring[0]['ottogi'] == '2'
                                        ? '고수위 경보'
                                        : '센서없음',
                            style: us.userMonitoring[0]['ottogi'] == '1' || us.userMonitoring[0]['ottogi'] == '2'
                                ? f28w700RedSize()
                                : us.userMonitoring[0]['ottogi'] == '0'
                                    ? f28wBlue700Size()
                                    : f28w700Size(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(
          height: 14,
        )
      ],
    );
  }

  /// ✅ 디지털계량기 텍스트
  Widget digitalText() {
    /// ✅ value 관련
    final waterLevel = double.parse('${us.userMonitoring[0]['waterLevel']}');
    final value = double.parse('${us.userMmsTileList[pageIdx][6]['value']}');
    final adjustedValue = value == 0 ? 1 : value;
    final result = waterLevel * adjustedValue;

    /// ✅ 연결상태 관련
    final isDisconnected = result.round() < 2; // 2 미만일시 미연결로 표시
    final isWarning = result.floor() <= 20 || result.floor() >= 80;
    final displayText = isDisconnected
        ? '미연결'
        : (result % 1 == 0 ?
            result.toInt().toString() /// ✅ 정수일때
            :
            result.round().toString()) + '%'; /// ✅ 소숫점 1번째자리 까지만 반환

    final textStyle = isDisconnected
        ? f18w700Size() // 미연결
        : isWarning
          ? f28w700RedSize() // 위험상태
          : f28wBlue700Size(); // 일반상태

    return Text(
      displayText,
      style: textStyle,
    );
  }

  /// 집수정 위젯
  Widget buildJibWidget() {
    return Column(
      children: [
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
                const Spacer(),
                us.userMonitoring[0]['jibsu'] == null || us.userMonitoring[0]['jibsu'] == '2'
                    ? BlackRadio()
                    : us.userMonitoring[0]['jibsu'] == '0'
                        ? BlueRadio()
                        : RedRadio(),
                const SizedBox(
                  width: 6,
                ),
                jibsuText(),

                /// ✅ 집수정 텍스트
                const SizedBox(
                  width: 14,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(
          height: 14,
        )
      ],
    );
  }

  /// ✅ 집수정 텍스트
  Widget jibsuText() {
    switch (us.userMonitoring[0]['jibsu']) {
      case '0':
        return Text('정상', style: bluef18w700());
      case null || '2':
        return Text('센서없음', style: f18w700Size());
      default:
        return Text('고수위 경보', style: redf18w700());
    }
    // return Text(
    //             us.userMonitoring[0]['jibsu'] == null || us.userMonitoring[0]['jibsu'] == '2'
    //                 ? '센서없음'
    //                 : us.userMonitoring[0]['jibsu'] == '0'
    //                     ? '정상'
    //                     : '고수위 경보',
    //             style: us.userMonitoring[0]['jibsu'] == null || us.userMonitoring[0]['jibsu'] == '2'
    //                 ? f18w700Size()
    //                 : us.userMonitoring[0]['jibsu'] == '0'
    //                     ? bluef18w700()
    //                     : redf18w700(),
    //           );
  }

  /// 급수관 위젯
  Widget buildPumpWidget() {
    return Column(
      children: [
        Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), color: Colors.white),
            width: Get.width,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '상수도유입밸브',
                  style: f18w700Size(),
                ),
                const SizedBox(height: 10),
                switchClick || us.userMonitoring[0]['data'] == '대기중'
                    ? const Center(child: Text('급수 밸브가 바뀌고 있습니다 잠시만 기다려주세요'))
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                              onTap: () async {
                                pressedPump(true);
                              },
                              child: Text(
                                '열기',
                                style: !switchButton ? f16w700Size() : f16w600GreySize(),
                              )),
                          switchButton
                              ? SvgPicture.asset(
                                  'assets/icon/valve_open.svg',
                                  width: 140,
                                  height: 48,
                                )
                              : SvgPicture.asset(
                                  'assets/icon/valve_closed.svg',
                                  width: 140,
                                  height: 48,
                                ),
                          GestureDetector(
                              onTap: () async {
                                pressedPump(false);
                              },
                              child: Text(
                                '닫기',
                                style: switchButton ? f16w700Size() : f16w600GreySize(),
                              )),
                        ],
                      ),
                const SizedBox(height: 10),
                Center(
                  child: Text(
                    switchButton ? '열려있음' : '닫혀있음',
                    style: f16w700Size(),
                  ),
                ),
              ],
            )),
        const SizedBox(
          height: 14,
        )
      ],
    );
  }

  /// 소방수신기 위젯
  Widget buildFireWidget() {
    return Column(
      children: [
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
                  '소방수신기 상태',
                  style: f18w700Size(),
                ),
                const Spacer(),
                us.userMonitoring[0]['firestate'] == '2'
                    ? RedRadio()
                    : us.userMonitoring[0]['firestate'] == '0'
                        ? BlueRadio()
                        : BlackRadio(),
                const SizedBox(
                  width: 6,
                ),
                Text(
                  us.userMonitoring[0]['firestate'] == '2'
                      ? '화재 감지 경보'
                      : us.userMonitoring[0]['firestate'] == '0'
                          ? '정상'
                          : '미연결',
                  style: us.userMonitoring[0]['firestate'] == '2'
                      ? redf18w700()
                      : us.userMonitoring[0]['firestate'] == '0'
                          ? bluef18w700()
                          : f18w700Size(),
                ),

                /// 저수조2 소방수신기 상태 포함 p r 저수조2
                const SizedBox(
                  width: 14,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(
          height: 14,
        )
      ],
    );
  }

  /// 변압기 위젯
  Widget buildTempWidget() {
    return Column(
      children: [
        Container(
          width: Get.width,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), color: Colors.white),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              Container(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      '변압기 온도',
                      style: grf14w600(),
                    ),
                    Row(
                      children: [
                        Text(
                          int.parse('${us.userMonitoring[0]['tempMain']}') >= 140 || int.parse('${us.userMonitoring[0]['tempMain']}') == 0 ? '미연결' : '${us.userMonitoring[0]['tempMain']}',
                          style: f28w700Size(),
                        ),
                        const SizedBox(
                          width: 4,
                        ),
                        Text(
                          int.parse('${us.userMonitoring[0]['tempMain']}') >= 140 || int.parse('${us.userMonitoring[0]['tempMain']}') == 0 ? '' : '°C',
                          style: f18w400Size(),
                        )
                      ],
                    )
                  ],
                ),
              ),
              const Spacer(),
              Container(
                height: 38,
                child: VerticalDivider(
                  color: const Color(0xffC5C9CC),
                  thickness: 1,
                ),
              ),
              const Spacer(),
              Container(
                child: Column(
                  children: [
                    Text(
                      '변압기 주변 온도',
                      style: grf14w600(),
                    ),
                    int.parse('${us.userMonitoring[0]['tempside']}') >= 140 || int.parse('${us.userMonitoring[0]['tempside']}') == 0
                        ? const Text('미연결')
                        : Row(
                            children: [
                              Text(
                                '${us.userMonitoring[0]['tempside']}',
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
              const Spacer(),
            ],
          ),
        ),
        const SizedBox(
          height: 14,
        )
      ],
    );
  }

  /// 정화조수위 위젯
  Widget buildCleanWidget() {
    return Column(
      children: [
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
                  '정화조 수위',
                  style: f18w700Size(),
                ),
                const Spacer(),
                us.userMonitoring[0]['jibsu'] == null || us.userMonitoring[0]['cleanLevel'] == '2'
                    ? BlackRadio()
                    : us.userMonitoring[0]['cleanLevel'] == '1'
                        ? BlueRadio()
                        : RedRadio(),
                const SizedBox(
                  width: 6,
                ),
                Text(
                  us.userMonitoring[0]['jibsu'] == null || us.userMonitoring[0]['cleanLevel'] == '2'
                      ? '센서없음'
                      : us.userMonitoring[0]['cleanLevel'] == '1'
                          ? '정상'
                          : '오수 넘침 경보',
                  style: us.userMonitoring[0]['jibsu'] == null || us.userMonitoring[0]['cleanLevel'] == '2'
                      ? f18w700Size()
                      : us.userMonitoring[0]['cleanLevel'] == '1'
                          ? bluef18w700()
                          : redf18w700(),
                ),
                const SizedBox(
                  width: 14,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(
          height: 14,
        )
      ],
    );
  }
}
